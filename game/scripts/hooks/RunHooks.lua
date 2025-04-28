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
---@type CoopModConfig
local Config = ModRequire "../config.lua"
---@type SecondPlayerUi
local SecondPlayerUi = ModRequire "../SecondPlayerUI.lua"

---@class RunHooks
local RunHooks = {}

function RunHooks.InitHooks()
    RunHooks.InitRunHooks()
    RunHooks.CreateRoomHooks()
    HookUtils.onPreFunction("LeaveRoom", RunHooks.LeaveRoomHook)
    HookUtils.wrap("StartRoom", RunHooks.StartRoomWrapHook)
    HookUtils.wrap("KillHero", RunHooks.KillHeroHook)
    HookUtils.wrap("CheckRoomExitsReady", RunHooks.CheckRoomExitsReadyHook)
    HookUtils.wrap("SetupHeroObject", RunHooks.SetupHeroObjectHook)
    HookUtils.wrap("CheckDistanceTrigger", RunHooks.CheckDistanceTriggerWrapHook)
    HookUtils.onPostFunction("StartNewGame", RunHooks.StartNewGameHook)
    HookUtils.onPostFunction("CheckForAllEnemiesDead", RunHooks.CheckForAllEnemiesDeadPostHook)
    HookUtils.onPostFunction("RestoreUnlockRoomExits", RunHooks.RestoreUnlockRoomExitsHook)
end

---@private
function RunHooks.CheckDistanceTriggerWrapHook(CheckDistanceTriggerFun, ...)
    HeroContext.RunWithHeroContext(CoopPlayers.GetMainHero(), CheckDistanceTriggerFun, ...)
end

---@private
function RunHooks.SetupHeroObjectHook(SetupHeroObjectFun, ...)
    HeroContext.RunWithHeroContext(CoopPlayers.GetMainHero(), SetupHeroObjectFun, ...)
    -- Fix unit -> hero table here
    CoopPlayers.UpdateMainHero()
end

---@private
function RunHooks.StartRoomWrapHook(StartRoomFun, run, currentRoom)
    -- Initialization after save loading when encounter is active
    if not HeroContext.GetDefaultHero() then
        HeroContext.InitRunHook()
        CoopPlayers.SetMainHero(HeroContext.GetDefaultHero())
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
            local hero = CoopPlayers.GetHero(playerId)
            if hero and not hero.IsDead then
                CoopCamera.ForceFocus(true)
                CoopPlayers.InitCoopUnit(playerId)
            end
        end
        CoopPlayers.UpdateMainHero()

        local mainHero = CoopPlayers.GetMainHero()
        local isMainPlayerDead = mainHero and mainHero.IsDead
        if isMainPlayerDead then
            RunHooks.HideMainPlayer(mainHero)
        else
            if Config.Player1HasOutline then
                AddOutline(
                    MergeTables(Config.Player1Outline, { Id = mainHero.ObjectId })
                )
            end
        end

        if currentRoom.HeroEndPoint then
            for playerId = 2, CoopPlayers.GetPlayersCount() do
                local hero = CoopPlayers.GetHero(playerId)
                if not hero.IsDead then
                    Teleport({ Id = hero.ObjectId, DestinationId = currentRoom.HeroEndPoint })
                    if isMainPlayerDead then
                        RemoveInputBlock({ PlayerIndex = playerId,  Name = "MoveHeroToRoomPosition" })
                    end
                end
            end
        end
    end)

    HookUtils.onPostFunctionOnce("SwitchActiveUnit", function()
        SwitchActiveUnit { PlayerIndex = 1, Id = CoopPlayers.GetMainHero().ObjectId }
    end)

    local hero = CoopPlayers.GetAliveHeroes()[1] or CoopPlayers.GetMainHero()
    HeroContext.RunWithHeroContext(hero, StartRoomFun, run, currentRoom)
end

---@private
function RunHooks.InitRunHooks()
    local _StartNewRun = StartNewRun
    StartNewRun = function(prevRun, args)
        local newRun = _StartNewRun(prevRun, args)
        HeroContext.InitRunHook()
        LootHooks.Reset(CoopPlayers.GetPlayersCount())
        CoopPlayers.SetMainHero(HeroContext.GetDefaultHero())
        CoopPlayers.RecreateAllAdditionalPlayers()

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
    local aliveHero = CoopPlayers.GetAliveHeroes()[1]
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
        CoopPlayers.OnAllPlayersDead()
        return
    end
    if CurrentRun.Hero == CoopPlayers.GetMainHero() then
        RunHooks.HideMainPlayer(CurrentRun.Hero)

        local heroToChange = CoopPlayers.GetAliveHeroes()[1]
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

---@private
function RunHooks.LeaveRoomHook(currentRun, door)
    -- Disables an extit door after use
    door.ReadyToUse = false

    -- Updates traits and health
    local nextRoom = door.Room
    local currentHero = CurrentRun.Hero
    for _, hero in CoopPlayers.PlayersIterator() do
        if hero ~= currentHero and not hero.IsDead then
            ClearEffect({ Id = hero.ObjectId, All = true, BlockAll = true, })
            StopCurrentStatusAnimation(hero)
            hero.BlockStatusAnimations = true

            if not nextRoom.BlockDoorHealFromPrevious then
                HeroContext.RunWithHeroContext(hero, CheckDoorHealTrait, currentRun)
            end

            local removedTraits = {}
            for _, trait in pairs(hero.Traits) do
                if trait.RemainingUses ~= nil and trait.UsesAsRooms ~= nil and trait.UsesAsRooms then
                    UseTraitData(hero, trait)
                    if trait.RemainingUses ~= nil and trait.RemainingUses <= 0 then
                        table.insert(removedTraits, trait)
                    end
                end
            end
            for _, trait in pairs(removedTraits) do
                RemoveTraitData(hero, trait)
            end
        end
    end
end

-- Clrears poison effects
---@private
function RunHooks.CheckForAllEnemiesDeadPostHook()
    for playerID = 2, CoopPlayers.GetPlayersCount() do
        local hero = CoopPlayers.GetHero(playerID)
        if hero and not hero.IsDead and hero.ObjectId then
            ClearEffect({ Id = hero.ObjectId, Name = "StyxPoison" })
            ClearEffect({ Id = hero.ObjectId, Name = "DamageOverTime" })
        end
    end
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
    --Teleport{ Id = hero.ObjectId, DestinationId = hero.ObjectId, OffsetX = -10000 }
end

---@private
function RunHooks.StartNewGameHook()
    if not HeroContext.GetDefaultHero() then
        HeroContext.InitRunHook()
    end
    CoopPlayers.SetMainHero(HeroContext.GetDefaultHero())
end

---@private
function RunHooks.RestoreUnlockRoomExitsHook()
    if not HeroContext.GetDefaultHero() then
        HeroContext.InitRunHook()
    end
    CoopPlayers.SetMainHero(HeroContext.GetDefaultHero())

    for playerId = 2, CoopPlayers.GetPlayersCount() do
        CoopPlayers.RestoreSavedHero(playerId)
    end

    SecondPlayerUi.UpdateHealthUI()
    SecondPlayerUi.RecreateLifePips()
end

return RunHooks
