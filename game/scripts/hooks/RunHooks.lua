--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"
---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"
---@type CoopCamera
local CoopCamera = ModRequire "../CoopCamera.lua"
---@type EnemyAiHooks
local EnemyAiHooks = ModRequire "EnemyAiHooks.lua"
---@type LootHooks
local LootHooks = ModRequire "LootHooks.lua"

---@class RunHooks
local RunHooks = {}

function RunHooks.InitHooks()
    RunHooks.InitRunHooks()
    RunHooks.InitStartRoomHooks()
    RunHooks.CreateRoomHooks()
    HookUtils.onPreFunction("LeaveRoom", RunHooks.LeaveRoomHook)
    HookUtils.wrap("KillHero", RunHooks["KillHeroHook"])
    HookUtils.wrap("CheckRoomExitsReady", RunHooks.CheckRoomExitsReadyHook)
    HookUtils.onPostFunction("StartNewGame", RunHooks.StartNewGameHook)
end

---@private
function RunHooks.InitStartRoomHooks()
    local _StartRoom = StartRoom

    function StartRoom(run, currentRoom)
        local playersCount = CoopGetPlayersCount()

        DebugPrint { Text = "StartRoom with players " .. playersCount }
        if playersCount <= 1 then
            _StartRoom(run, currentRoom)
            return
        end

        local prevRoom = GetPreviousRoom(CurrentRun)
        local roomEntranceFunctionName = currentRoom.EntranceFunctionName or "RoomEntranceStandard"
        if prevRoom ~= nil and prevRoom.NextRoomEntranceFunctionName ~= nil then
            roomEntranceFunctionName = prevRoom.NextRoomEntranceFunctionName
        end
        local args = currentRoom.EntranceFunctionArgs

        HookUtils.onPostFunctionOnce(roomEntranceFunctionName, function()
            local entranceFunction = _G[roomEntranceFunctionName]
            --entranceFunction(currentRun, currentRoom, args)
            -- TODO ADD ENTER Animation
            for playerId = 2, CoopPlayers.GetPlayersCount() do
                local hero = CoopPlayers.InitCoopUnit(playerId)
                if hero and not hero.IsDead then
                    CoopPlayers.UpdateMainHero()
                    CoopCamera.ForceFocus(true)
                end
            end

            local mainHero = CoopPlayers.GetMainHero()
            if mainHero and mainHero.IsDead then
                RunHooks.HideMainPlayer(mainHero)
            end

            if currentRoom.HeroEndPoint then
                for playerId = 2, CoopPlayers.GetPlayersCount() do
                    local hero = CoopPlayers.GetHero(playerId)
                    if not hero.IsDead then
                        Teleport({ Id = hero.ObjectId, DestinationId = currentRoom.HeroEndPoint })
                    end
                end
            end
        end)

        _StartRoom(run, currentRoom)
    end
end

---@private
function RunHooks.InitRunHooks()
    local _StartNewRun = StartNewRun
    StartNewRun = function(prevRun, args)
        local newRun = _StartNewRun(prevRun, args)
        HeroContext.InitRunHook()
        LootHooks.Reset(CoopPlayers.GetPlayersCount())
        CoopPlayers.SetMainHero(HeroContext.GetDefaultHero())

        return newRun
    end
end

---@private
function RunHooks.CreateRoomHooks()
    _CreateRoom = CreateRoom
    CreateRoom = function(...)
        local room = _CreateRoom(...)
        if not room.ZoomFraction then
            room.ZoomFraction = 0.6
        elseif room.ZoomFraction > 0.5 then
            room.ZoomFraction = room.ZoomFraction * 0.6
        end

        return room
    end
end

--- Bypass IsAlive check with this hook
---@private
function RunHooks.CheckRoomExitsReadyHook(baseFun, ...)
    local aliveHero = CoopPlayers.GetAlivePlayers()[1]
    if aliveHero then
        local result = false
        HeroContext.RunWithHeroContext(aliveHero, function(...)
            result = baseFun(...)
        end, ...)

        return result
    else
        return baseFun(...)
    end
end

function RunHooks.KillHeroHook(baseFun, ...)
    CurrentRun.Hero.IsDead = true
    if not CoopPlayers.HasAlivePlayers() then
        baseFun(...)
        HeroContext.SetDefaultHero(CoopPlayers.GetMainHero())
        for _, hero in CoopPlayers.PlayersIterator() do
            hero.Health = hero.MaxHealth or 50
        end
        return
    end
    if CurrentRun.Hero == CoopPlayers.GetMainHero() then
        RunHooks.HideMainPlayer(CurrentRun.Hero)

        local heroToChange = CoopPlayers.GetAlivePlayers()[1]
        HeroContext.SetDefaultHero(heroToChange)
    else
        local playerId = CoopPlayers.GetPlayerByHero(CurrentRun.Hero)
        if playerId then
            CoopRemovePlayerUnit(playerId)
        end
    end
    -- Unstuck AI
    EnemyAiHooks.RefreshAI()
end

-- Disables an extit door after use
---@private
function RunHooks.LeaveRoomHook(currentRun, door)
    door.ReadyToUse = false
end

---@private
---@param hero table
function RunHooks.HideMainPlayer(hero)
    local weaponsToHide = { "RangedWeapon" }
    for _, weaponName in ipairs(WeaponSets.HeroMeleeWeapons) do
        if hero.Weapons[weaponName] then
            table.insert(weaponsToHide, weaponName)
        end
    end

    UnequipWeapon{ DestinationId = hero.ObjectId, Names = weaponsToHide }
    SetColor{ Id = hero.ObjectId, Color = { 255, 255, 255, 0 } }
    Teleport{ Id = hero.ObjectId, DestinationId = hero.ObjectId, OffsetX = -10000 }
end

---@private
function RunHooks.StartNewGameHook()
    if not HeroContext.GetDefaultHero() then
        HeroContext.InitRunHook()
    end
    CoopPlayers.SetMainHero(HeroContext.GetDefaultHero())
end

return RunHooks
