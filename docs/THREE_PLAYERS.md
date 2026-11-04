# Эксперимент: 3 игрока

Цель — проверить одну гипотезу: **может ли движок Hades работать с третьим `sgg::Player`**.
Если нет — дальше не идём. Если да — переделываем Lua (HUD, хуки) под N игроков.

Все шаги — на Windows.

## Что уже известно

- Движок сам создаёт список игроков `PlayerManager::m_palyers` (`eastl::vector<Player*>`) **на 2 места**.
  Мод не расширяет его, а занимает пустое второе место (`PlayerManagerExtension::CreatePlayer`:
  `// This struct has size 2 in the game`).
- `MAX_PLAYERS = 2` в `game/src/extensions/PlayerManagerExtension.h`.
- Новому игроку всегда назначается контроллер `1` (`PlayerManagerExtension::CreatePlayer`).
- Функции движка мод получает по имени через `GetSymbolAddress("sgg::...")` (`game/src/HookTable.cpp`),
  имена берутся из `Hades.pdb` / `EngineWin64s.pdb`, которые лежат в папке игры.
- `allocator_forge::allocate/deallocate` в моде только объявлены, но не реализованы:
  мод никогда не перевыделяет память под векторы движка. Для расширения вектора нужен аллокатор **самой игры**.
- Схема управления по умолчанию (`game/scripts/CoopControl.lua`): P1 — клавиатура, P2 — геймпад 0.
  Значит, для теста, скорее всего, хватит **клавиатуры + 2 геймпадов** (P3 — геймпад 1).
- Логика наград, смертей, выбора дверей и камеры в Lua уже написана циклами `for playerId = 2, GetPlayersCount()`.
  На двоих жёстко завязаны HUD (`SecondPlayerUI.lua`) и ~50 мест с `GetHero(2)` в `hooks/UIHooks.lua`.

## Шаг 1. Сборка (базовая линия)

1. Visual Studio 2022 с компонентом **Desktop development with C++** и **CMake tools**.
2. ```powershell
   cmake -A x64 . -B build_msvc
   cmake --build build_msvc --config Release
   ```
3. Положить `bin/HadesCoopGame.dll` вместо `Content/Mods/TN_CoopMod/HadesCoopGame.dll` из релиза.
4. **Проверить, что кооп на двоих работает с этой сборкой** так же, как с релизной DLL.
   Без этого потом не отличить «движок не тянет 3» от «я криво собрал».

## Шаг 2. Разведка движка (с символами)

Инструменты: x64dbg (+ плагин для PDB) или Ghidra / IDA Free — открыть `x64/EngineWin64s.dll` с `EngineWin64s.pdb`
(и `Hades.exe` с `Hades.pdb`).

Найти и записать ответы:

1. **Где создаётся `m_palyers` на 2 места** (конструктор `sgg::PlayerManager` / `Init`). Есть ли там константа `2`,
   которую проще поменять, чем расширять вектор потом.
   Зацепка: по анализу проекта [HadesPort](https://github.com/lukifer23/HadesPort) (`native/analysis/engine-identity.json`)
   `sgg::App::Initialize` при старте вызывает `PlayerManager::AddPlayer` / `AssignController`.
   Их RVA (`0x35a70`) — для другой сборки движка (sha256 `d98546ea…`), у Steam-версии от 2026-11-04 хеш другой,
   поэтому искать по имени через PDB, а не по адресу.
2. **Аллокатор игры** для eastl/forge: функция, которой игра выделяет память под свои векторы
   (что-то вроде `tf_memalign` / `tf_malloc` / `tf_free` или `eastl::allocator_forge::allocate`).
   Без неё расширять вектор нельзя — память освободит игра своим аллокатором и упадёт.
3. **`m_inputMethods`**: сколько в нём `InputHandler` и как он заполняется. Нужен ли отдельный `InputHandler`
   для P3, и если да — есть ли у него конструктор в символах.
4. **Кто перебирает игроков**: `sgg::PlayerManager::Update`, обработка ввода, камера, вибрация, `InputBlock` по `PlayerIndex`.
   Важно: цикл идёт по `size()` вектора или по константе `2`. Каждая константа `2` — место, где P3 будет игнорироваться или упадёт.
5. **`sgg::PlayerManager::AssignController(player, index)`** — что значит `index` (номер `InputHandler`?).

**Точка решения:** если в п. 4 много мест с жёсткой `2` или в п. 2–3 нет нужных функций — останавливаемся.

## Шаг 3. Правки в C++

- `MAX_PLAYERS = 3`.
- Перед `AddPlayer(2)` расширить `m_palyers` (и при необходимости `m_inputMethods`) до 3 элементов,
  выделяя память аллокатором игры из шага 2. Реализовать `allocator_forge::allocate/deallocate` через него.
- `CreatePlayer`: назначать контроллер по индексу игрока, а не всегда `1`.
- `CoopContext::CreatePlayer` ищет свободный слот циклом — менять не нужно.
- `CreatePlayerUnit`: id `40000 - playerIndex` для P3 даст `39998` — проверить, что не пересекается с другими объектами.

## Шаг 4. Минимум в Lua (только для теста)

- `CoopPlayers.InitCoopPlayer()` создаёт только игрока 2 — создать и игрока 3.
- `CoopControl.Schemas.Default`: добавить третью запись `{ Device = "Gamepad", ControllerId = 1 }`.
- Юнит P3 появится сам: `RunHooks.HandleGenericRoom` вызывает `InitCoopUnit` для `2..GetPlayersCount()`.
- HUD для P3 **не делать** — для теста важно только: появился ли третий Загрей и слушается ли он геймпада.

## Шаг 5. Тест

- Клавиатура + 2 геймпада (или 3 геймпада).
- Проверить: третий персонаж появляется, ходит, атакует, получает урон, переход между комнатами, смерть P3.
- При падении: `Documents/Saved Games/Hades/Hades.log` (перезаписывается при каждом запуске — сразу копировать)
  и адрес падения из диалога Windows / x64dbg. По символам будет видно, какая функция движка упала.

## Если заработало

Переделать Lua под N игроков:
- `SecondPlayerUI.lua` → HUD для любого номера игрока (позиция зависит от номера).
- Все `GetHero(2)` / `SecondPlayerUi` в `hooks/UIHooks.lua`, `hooks/DamageHooks.lua`, `hooks/RunHooks.lua` → циклы по игрокам.
- Меню выбора контроллеров (`ControllerSelectionMenuScreen.sjson`, `CoopMenu.lua`).
- Камера на троих, очередь выбора дверей в `loot/LootRoomDuplicated.lua`.
