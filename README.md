
# Hades coop mod

Play Hades with a friend!
This mod adds local cooperative multiplayer to Hades, allowing two players to fight through the Underworld together on the same PC.

For online play: Use a streaming tool like [Parsec](https://parsec.app/) to share your game session with a remote friend.

The mod supports the **Steam** and **Epic Games Store** versions of the gamme

**Warning**

You need a gameplay to play this mod.

# Linux / Steam Deck (Proton)

Set the game launch options in Steam (Hades -> Properties -> Launch Options):

```
WINEDLLOVERRIDES="xinput9_1_0=n,b;dbghelp=n,b;dbgcore=n,b" %command%
```

- `xinput9_1_0=n,b` loads the mod loader (`Xinput9_1_0.dll`) instead of the Wine builtin.
- `dbghelp=n,b` is required: with the Wine builtin dbghelp, `HadesMainMenuApiLib.dll` crashes on startup
  with `EXCEPTION_ACCESS_VIOLATION` before the engine starts (no `Hades.log` is written).

# Fork TODO (priority order)

Fixes from commit `5e6e133` (P2 HUD, last stands, Stubborn Defiance) are syntax-checked
but **not play-tested in a real co-op run yet**.

## 1. Verify first
- [ ] Play-test `5e6e133` in co-op: P2 death defiance icons, Stubborn Defiance for P2 in every room,
      damage / heal / death defiance flashes on the P2 health bar, no duplicated icons after a run (#59, #76, #91, #92).

## 2. Possible crashes
- [ ] `hooks/UIHooks.lua` `AddLastStand`: replaces global `CreateScreenObstacle` and `ScreenAnchors.LifePipIds`
      without protection. If vanilla `AddLastStand` errors or yields, they stay replaced (P1 HUD breaks for the rest of the session).
- [ ] `hooks/UIHooks.lua` `EquipPlayerWeaponPresentation`: `WeaponData[weaponName].ActiveReloadTime` has no nil check.
- [ ] `hooks/RunHooks.lua` `HandleGenericRoom`: `onPostFunctionOnce` on the room entrance function stays installed
      if that function is not called in the room, and fires in the next room at the wrong time.

## 3. Gameplay bugs
- [ ] #84 Centaur Heart sometimes doesn't heal. Not reproduced. Suspects:
      `GetHeroByUnit` returns nil -> context falls back to the default hero (P1 gets the heal);
      or two tagged hearts lie close and the player uses the other player's heart (silently ignored in `UseHooks.lua`).
- [ ] `hooks/DamageHooks.lua` `OnEffectApply`: `CoopLastAttackerId` is never cleared, environment effects
      on an enemy are attributed to the last player who hit it.
- [ ] #54 Boiling Blood icon is always shown on the P1 HUD.
- [ ] Low health bar pulse is disabled for P2 (it pulsed the P1 bar). Needs a P2 version for `SecondPlayerUI`.
- [ ] P2 HUD presentation redirect (`UIHooks.RunWithSecondPlayerAnchors`) only covers code before the first `wait`.

## 4. Cleanup
- [ ] `CoopPlayers.PlayerUnitIdToHero` keeps entries of removed P2 units after death.
- [ ] `HookUtils.onPreFunction` / `onPostFunction` drop return values of the original function
      (no hooked function returns a value today, but it's a trap).
- [ ] #18 gamepad doesn't work after a crash.
- [ ] #71 Vulkan crash on startup: check whether it's the same dbghelp issue on Wine/Proton.

# Build

## Using CMake for Windows x64

```powershell
cmake -A x64 . -B build_msvc
cmake --build build_msvc --config Release
```

Binary files are located in the `bin` folder.

## Using [Visual Studio](https://visualstudio.microsoft.com/) GUI

You need to install cmake in the Visual Studio Installer to build the project.
Open the project in VS and click Build -> Build All in the top menu.
Check `bin` folder for `HadesCoopGame.dll`.

# How to load the mod from the repository folder

Follow these steps if you want to develop the mod and save changes in git:

1. Create the folder `Hades/Hades/Content/ModModules/TN_CoopMod/`
2. Copy the repository into `Hades/Hades/Content/ModModules/TN_CoopMod/dev`
3. Create `Hades/Hades/Content/ModModules/TN_CoopMod/init.lua` with the following content:
```lua
ModRequire "dev/game/scripts/init.lua"
```
4. Create `Hades/Hades/Content/ModModules/TN_CoopMod/meta.sjson` with the following content:
```sjson
{
	Name = "Coop mod"
	Library = "dev/bin/HadesCoopGame.dll"
	Author = "Uladzislau 'TheNormalnij' Nikalayevich"
}
```
5. Now you can make changes directly in the repository and load them in the game.

# Suppoort

You can support development using crypto. See [my page](https://thenormalnij.de/donate) for details
