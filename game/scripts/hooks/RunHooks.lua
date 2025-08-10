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
---@type ILootDelivery
local LootDelivery = ModRequire "../loot/LootInterface.lua"
---@type SecondPlayerUi
local SecondPlayerUi = ModRequire "../SecondPlayerUI.lua"
---@type RunEx
local RunEx = ModRequire "../RunEx.lua"
---@type PlayerVisibilityHelper
local PlayerVisibilityHelper = ModRequire "../PlayerVisibilityHelper.lua"
---@type HeroEx
local HeroEx = ModRequire "../HeroEx.lua"
---@type CoopControl
local CoopControl = ModRequire "../CoopControl.lua"
---@type GameFlags
local GameFlags = ModRequire "../GameFlags.lua"

---@class RunHooks
local RunHooks = {}

function RunHooks.InitHooks()
    HookUtils.onPreFunction("LeaveRoom", RunHooks.LeaveRoomHook)
    HookUtils.onPreFunction("DeathAreaRoomTransition", RunHooks.DeathAreaRoomTransitionPreHook)
    HookUtils.wrap("EndEarlyAccessPresentation", RunHooks.EndEarlyAccessPresentationWrapHook)
    HookUtils.wrap("StartNewRun", RunHooks.StartNewRunWrapHook)
    HookUtils.wrap("StartRoom", RunHooks.StartRoomWrapHook)
    HookUtils.wrap("KillHero", RunHooks.KillHeroHook)
    HookUtils.wrap("CheckRoomExitsReady", RunHooks.CheckRoomExitsReadyHook)
    HookUtils.wrap("SetupHeroObject", RunHooks.SetupHeroObjectHook)
    HookUtils.wrap("CheckDistanceTrigger", RunHooks.CheckDistanceTriggerWrapHook)
    HookUtils.wrap("EndEncounterEffects", RunHooks.EndEncounterEffectsWrapHook)
    HookUtils.wrap("StartEncounterEffects", RunHooks.StartEncounterEffectsWrapHook)
    HookUtils.onPostFunction("StartNewGame", RunHooks.StartNewGameHook)
    HookUtils.onPostFunction("CheckForAllEnemiesDead", RunHooks.CheckForAllEnemiesDeadPostHook)
    HookUtils.onPostFunction("RestoreUnlockRoomExits", RunHooks.RestoreUnlockRoomExitsHook)
end

---@private
function RunHooks.DeathAreaRoomTransitionPreHook()
    if not HeroContext.GetDefaultHero() then
        HeroContext.InitRunHook()
    end
end

---@private
function RunHooks.CheckDistanceTriggerWrapHook(CheckDistanceTriggerFun, ...)
    -- TODO
    -- This hack fixes crashes like #21 when the player 1 is dead.
    -- The crash is caused by invalid reference to the second player.
    -- The game cannot find a player unit and triggers NotifyWithinDistance instantly without result
    HeroContext.RunWithHeroContext(CoopPlayers.GetMainHero(), CheckDistanceTriggerFun, ...)
end

---@private
function RunHooks.SetupHeroObjectHook(SetupHeroObjectFun, ...)
    local mainHero = CoopPlayers.GetMainHero()

    HeroContext.RunWithHeroContext(mainHero, SetupHeroObjectFun, ...)
    -- Fix unit -> hero table here
    CoopPlayers.UpdateMainHero()

    PlayerVisibilityHelper.AddPlayerMarkers(1, mainHero.ObjectId)

    if mainHero.IsDead and not RunEx.IsRunEnded() then
        HeroEx.HideHero(mainHero)
    end
end

---@private
function RunHooks.StartRoomWrapHook(StartRoomFun, run, currentRoom)
    -- Fixes mouse disappearing after level transiction
    CoopControl.ResetAllPlayers("Current")

    -- Initialization after save loading when encounter is active
    if not HeroContext.GetDefaultHero() then
        HeroContext.InitRunHook()
        CoopPlayers.SetMainHero(HeroContext.GetDefaultHero())
    end

    if currentRoom.RoomSetName == "Surface" then
        RunHooks.HandleSurfaceRoom(StartRoomFun, run, currentRoom)
    else
        RunHooks.HandleGenericRoom(StartRoomFun, run, currentRoom)
    end
end

---@private
function RunHooks.HandleGenericRoom(StartRoomFun, run, currentRoom)
    local overrides = currentRoom.EncounterSpecificDataOverwrites and
    currentRoom.EncounterSpecificDataOverwrites[currentRoom.Encounter.Name]

    local prevRoom = GetPreviousRoom(CurrentRun)
    local roomEntranceFunctionName = (overrides and overrides.EntranceFunctionName)
        or currentRoom.EntranceFunctionName
        or "RoomEntranceStandard"

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
            if not hero or (hero and not hero.IsDead) then
                CoopCamera.ForceFocus(true)
                CoopPlayers.InitCoopUnit(playerId)
            end
        end
        SecondPlayerUi.Refresh()

        CoopPlayers.UpdateMainHero()

        local mainHero = CoopPlayers.GetMainHero()
        local isMainPlayerDead = mainHero and mainHero.IsDead
        if not isMainPlayerDead then
            -- For some strange reason RoomEntrancePortal keeps the main player invisible
            SetAlpha{ Id = mainHero.ObjectId, Fraction = 1.0, Duration = 1.0 }
        end

        if currentRoom.HeroEndPoint then
            for playerId = 2, CoopPlayers.GetPlayersCount() do
                local hero = CoopPlayers.GetHero(playerId)
                if not hero.IsDead then
                    Teleport({ Id = hero.ObjectId, DestinationId = currentRoom.HeroEndPoint })
                    if isMainPlayerDead then
                        RemoveInputBlock{ PlayerIndex = playerId, Name = "MoveHeroToRoomPosition" }
                    end
                end
            end
        end
    end)

    HookUtils.onPostFunctionOnce("SwitchActiveUnit", function()
        SwitchActiveUnit { PlayerIndex = 1, Id = CoopPlayers.GetMainHero().ObjectId }
    end)

    if RunEx.IsRunEnded() then
        HeroContext.RunWithHeroContext(CoopPlayers.GetMainHero(), StartRoomFun, run, currentRoom)
    else
        local hero = CoopPlayers.GetAliveHeroes()[1] or CoopPlayers.GetMainHero()
        HeroContext.RunWithHeroContext(hero, StartRoomFun, run, currentRoom)
    end
end

---@private
function RunHooks.HandleSurfaceRoom(StartRoomFun, run, currentRoom)
    local mainHero = CoopPlayers.GetMainHero()
    mainHero.IsDead = false
    HeroContext.SetDefaultHero(mainHero)

    if mainHero.Health == 0 then
        mainHero.Health = mainHero.MaxHealth
    end

    for playerId, hero in CoopPlayers.AdditionalHeroesIterator() do
        hero.IsDead = true
    end

    HeroContext.RunWithHeroContext(mainHero, StartRoomFun, run, currentRoom)
end

---@private
function RunHooks.StartNewRunWrapHook(StartNewRunFun, prevRun, args)
    local isNewGame = RunEx.WasTheFirstRunStarted()
    local newRun = StartNewRunFun(prevRun, args)
    HeroContext.InitRunHook()
    LootHooks.InitRunHooks()
    LootDelivery.Reset(CoopPlayers.GetPlayersCount())
    CoopPlayers.SetMainHero(HeroContext.GetDefaultHero())

    if not isNewGame then
        CoopPlayers.RecreateAllAdditionalPlayers()
    end

    return newRun
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

---@private
function RunHooks.EndEarlyAccessPresentationWrapHook(baseFun)
    local mainHero = CoopPlayers.GetMainHero()
    mainHero.IsDead = false
    for playerId, hero in CoopPlayers.AdditionalHeroesIterator() do
        hero.IsDead = true
    end
    HeroContext.RunWithHeroContext(mainHero, baseFun)
end

---@private
function RunHooks.KillHeroHook(baseFun, ...)
    CurrentRun.Hero.IsDead = true
    if not CoopPlayers.HasAlivePlayers() then
        -- Handle death for player 1 only
        local mainHero = CoopPlayers.GetMainHero()
        HeroEx.ShowHero(mainHero, CurrentRun.Hero.ObjectId)
        RemoveOutline({ Id = mainHero.ObjectId })
        HeroContext.RunWithHeroContext(mainHero, baseFun, ...)
        CoopPlayers.OnAllPlayersDead()
        return
    end
    local aliveHero = CoopPlayers.GetAliveHeroes()[1]

    if CurrentRun.Hero == CoopPlayers.GetMainHero() then
        HeroEx.HideHero(CurrentRun.Hero)

        HeroContext.SetDefaultHero(aliveHero)
    else
        local playerId = CoopPlayers.GetPlayerByHero(CurrentRun.Hero)
        if playerId then
            CoopRemovePlayerUnit(playerId)
        end
    end
    -- Unstuck AI
    HeroContext.RunWithHeroContext(aliveHero, EnemyAiHooks.RefreshAI)
end

---@private
function RunHooks.LeaveRoomHook(currentRun, door)
    -- Disables an extit door after use
    door.ReadyToUse = false

    if not GameFlags.LeaveRoomHandlesOnce then
        return
    end

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

    local spawnPoint = CurrentRun.CurrentRoom.HeroEndPoint or CoopPlayers.GetMainHero().ObjectId
    for playerId = 2, CoopPlayers.GetPlayersCount() do
        CoopPlayers.RestoreSavedHero(playerId)
        local hero = CoopPlayers.GetHero(playerId)
        if hero and not hero.IsDead then
            Teleport { Id = hero.ObjectId, DestinationId = spawnPoint }
        end
    end

    SecondPlayerUi.Refresh()
end

---@private
function RunHooks.EndEncounterEffectsWrapHook(baseFun, currentRun, currentRoom, currentEncounter)
    for _, hero in ipairs(CoopPlayers.GetAliveHeroes()) do
        HeroContext.RunWithHeroContextAwait(hero, baseFun, currentRun, currentRoom, currentEncounter)
        currentRoom.CodexUpdates = nil
        currentRoom.PendingCodexUpdate = nil
    end
end

---@private
function RunHooks.StartEncounterEffectsWrapHook(baseFun, run)
    for _, hero in ipairs(CoopPlayers.GetAliveHeroes()) do
        HeroContext.RunWithHeroContextAwait(hero, baseFun, run)
    end
end

return RunHooks
