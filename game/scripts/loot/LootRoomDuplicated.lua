--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"
---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"
---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HeroContextProxyStore
local HeroContextProxyStore = ModRequire "../HeroContextProxyStore.lua"
---@type LootQuery
local LootQuery = ModRequire "LootQuery.lua"
---@type TableUtils
local TableUtils = ModRequire "../TableUtils.lua"
---@type HeroEx
local HeroEx = ModRequire "../HeroEx.lua"

---@class LootRoomDuplicated : ILootDelivery
local LootRoomDuplicated = {}

---@class SelectedPlayerReward
---@field rewardType string
---@field lootName string

---@private
---@type SelectedPlayerReward[]
LootRoomDuplicated.ChosenPlayerLoot = {}

---@private
---@type table?
LootRoomDuplicated.CurrentHeroChooser = nil

---@private
---@type number?
LootRoomDuplicated.TagNextLootForPlayer = nil

---@private
---@type boolean?
LootRoomDuplicated.ShouldSkipLoadingNextMap = nil

---@private
---@type fun(run: table, room: table)
LootRoomDuplicated.UnlockRewardedRoomOrig = nil

---@private
LootRoomDuplicated.RewardChoiseInProgress = false

---@private
LootRoomDuplicated.DuplicatedRewards = {
    StackUpgrade = true;
    WeaponUpgrade = true;
    HermesUpgrade = true;
    Boon = true;
    TrialUpgrade = true;
    Health = true;
    Money = true;
}

function LootRoomDuplicated.InitHooks()
    HookUtils.wrap("CheckSpecialDoorRequirement", LootRoomDuplicated.CheckSpecialDoorRequirementWrap)
    HookUtils.wrap("CreateLoot", LootRoomDuplicated.CreateLootWrap)
    HookUtils.wrap("LeaveRoom", LootRoomDuplicated.LeaveRoomWrap)
    HookUtils.wrap("FullScreenFadeOutAnimation", LootRoomDuplicated.FullScreenFadeOutAnimationWrap)
    HookUtils.wrap("IsGameStateEligible", LootRoomDuplicated.IsGameStateEligibleWrap)
end

---@private
function LootRoomDuplicated.ResetRoomLootState()
    LootRoomDuplicated.ShouldSkipLoadingNextMap = CurrentRun.CurrentRoom.SkipLoadNextMap
end

---@param baseFun fun(run: table, room: table)
---@param run table
---@param room table
function LootRoomDuplicated.OnUnlockedRewardedRoom(baseFun, run, room)
    LootRoomDuplicated.UnlockRewardedRoomOrig = baseFun

    LootRoomDuplicated.ResetRoomLootState()

    local firstAliveHero = CoopPlayers.GetAliveHeroes()[1]
    if not firstAliveHero then
        -- Fallback. This case should not happen.
        return baseFun(run, room)
    end

    HeroContext.RunWithHeroContextAwait(firstAliveHero, baseFun, run, room)

    if run.NextRewardStoreName == "MetaProgress" then
        -- Do not duplicate meta progress
        LootRoomDuplicated.CurrentHeroChooser = nil
        return
    end

    LootRoomDuplicated.CurrentHeroChooser = firstAliveHero
end

---@param baseFun fun(eventSource: table, args: table)
---@param eventSource table
---@param args table
function LootRoomDuplicated.SpawnRoomReward(baseFun, eventSource, args)
    local room = CurrentRun.CurrentRoom
    local rewardType = room.ChangeReward or room.ChosenRewardType

    DebugPrint{ Text = "rewardType " .. tostring(rewardType) }

    if not LootRoomDuplicated.DuplicatedRewards[rewardType] then
        return baseFun(eventSource, args)
    end

    for playerId, hero in CoopPlayers.PlayersIterator() do
        local lootParams = LootRoomDuplicated.ChosenPlayerLoot[playerId] or {}
        if not hero.IsDead then
            room.ChangeReward = lootParams.rewardType
            room.ForceLootName = lootParams.lootName
            LootRoomDuplicated.TagNextLootForPlayer = playerId
            HeroContext.RunWithHeroContextAwait(hero, baseFun, eventSource, args)
        end
    end
end

---@param heroesCount number
function LootRoomDuplicated.Reset(heroesCount)
    HeroContextProxyStore.GetOrCreate("LootTypeHistory"):Reset()
    LootQuery.Reset(heroesCount)
end

---@param baseFun fun(args: table): table
---@param hero table
---@param args table
---@return table
function LootRoomDuplicated.GiveBlindLoot(baseFun, hero, args)
    return HeroContext.RunWithHeroContextReturn(hero, baseFun, args)
end

---@param baseFun fun(args: table): table
---@param args table
---@return table
function LootRoomDuplicated.GiveLoot(baseFun, args)
    return baseFun(args)
end

---@private
function LootRoomDuplicated.CheckSpecialDoorRequirementWrap(baseFun, door)
    local currentBlocker = baseFun(door)
    if currentBlocker then
        return currentBlocker
    end

    if LootRoomDuplicated.CurrentHeroChooser == nil then
        return nil
    end

    -- Special case for secret (chaos) door
    if LootRoomDuplicated.IsDoorSpecial(door) and not LootRoomDuplicated.IsSpecialDoorAllowed() then
        return "ExitNotActive"
    end

    if LootRoomDuplicated.CurrentHeroChooser ~= CurrentRun.Hero then
        return "ExitNotActive"
    end

    -- Ok, the player can use the exit door
    return nil
end

---@param baseFun fun(args: table): table
---@param args table
---@return table
function LootRoomDuplicated.CreateLootWrap(baseFun, args)
    if LootRoomDuplicated.TagNextLootForPlayer == nil then
        return baseFun(args)
    else
        local loot = baseFun(args)
        loot.CoopChoosenPlayer = LootRoomDuplicated.TagNextLootForPlayer
        LootRoomDuplicated.TagNextLootForPlayer = nil
        return loot
    end
end

---@param loot table
---@param hero table
---@return boolean
function LootRoomDuplicated.CanUseHeroLoot(loot, hero)
    if not loot.CoopChoosenPlayer then
        return true
    end
    return loot.CoopChoosenPlayer == CoopPlayers.GetPlayerByHero(hero)
end

---@return boolean
function LootRoomDuplicated.IsSpecialDoorAllowed()
    -- Any player can choose this door, if any doors wasn't used yet
    return CoopPlayers.GetAliveHeroes()[1] == LootRoomDuplicated.CurrentHeroChooser
end

---@return boolean
function LootRoomDuplicated.IsDoorSpecial(door)
    -- chaos door or challenge room
    return door.OnUsedPresentationFunctionName == "SecretDoorUsedPresentation" or
        door.OnUsedPresentationFunctionName == "ShrinePointDoorUsedPresentation"
end

---@private
function LootRoomDuplicated.LeaveRoomWrap(baseFun, currentRun, door)
    if LootRoomDuplicated.CurrentHeroChooser == nil
        or LootRoomDuplicated.IsDoorSpecial(door)
    then
        CurrentRun.CurrentRoom.SkipLoadNextMap = LootRoomDuplicated.ShouldSkipLoadingNextMap
        return baseFun(currentRun, door)
    end

    if not LootRoomDuplicated.RewardChoiseInProgress then
        LootRoomDuplicated.RewardChoiseInProgress = true
        LootRoomDuplicated.ChosenPlayerLoot = {}
        SetPlayerInvulnerable("LootRoomDuplicated")
    end

    local playerId = CoopPlayers.GetPlayerByHero(CurrentRun.Hero)
    local room = door.Room

    LootRoomDuplicated.ChosenPlayerLoot[playerId] = {
        rewardType = room.ChosenRewardType,
        lootName = room.ForceLootName
    }

    local aliveHeroes = CoopPlayers.GetAliveHeroes()

    local isLastChoiser = TableUtils.last(aliveHeroes) == LootRoomDuplicated.CurrentHeroChooser
    if isLastChoiser then
        CurrentRun.CurrentRoom.SkipLoadNextMap = LootRoomDuplicated.ShouldSkipLoadingNextMap
    else
        CurrentRun.CurrentRoom.SkipLoadNextMap = true
    end

    baseFun(currentRun, door)

    if isLastChoiser then
        LootRoomDuplicated.RewardChoiseInProgress = false
        LootRoomDuplicated.UnlockAllPlayers()
        SetPlayerVulnerable("LootRoomDuplicated")
    else
        AddInputBlock {
            PlayerIndex = playerId,
            Name = "LootRoomDuplicated"
        }

        LootRoomDuplicated.CurrentHeroChooser = TableUtils.after(aliveHeroes, CurrentRun.Hero)

        LootRoomDuplicated.UnvalidateDoorRewardsPresentation(currentRun, door)

        HeroContext.RunWithHeroContextAwait(LootRoomDuplicated.CurrentHeroChooser,
            LootRoomDuplicated.UnvalidateDoorRewards)
    end
end

---@private
function LootRoomDuplicated.UnvalidateDoorRewardsPresentation(run, door)
    if door.ExitFunctionName == "AsphodelLeaveRoomPresentation" then
        wait(1.0)

        FullScreenFadeOutAnimation()

        local hero = CurrentRun.Hero
        HeroEx.HideHero(hero)

        local heroExitPointId = GetClosest{ Id = door.ObjectId, DestinationIds = GetIdsByType{ Name = "HeroExit" }, Distance = 500 }
        Move { Id = door.ObjectId, DestinationId = heroExitPointId, Duration = 0.01 }

        FullScreenFadeInAnimation()
    end
end

---@private
function LootRoomDuplicated.UnvalidateDoorRewards()
    local currentRewards = {}
    for doorObjectId, door in pairs(OfferedExitDoors) do
        if door.IsDefaultDoor then
            if door.DoorIconId ~= nil then
                Destroy { Ids = { door.DoorIconBackingId, door.DoorIconId, door.DoorIconFront } }
                Destroy { Ids = door.AdditionalIcons }
                Destroy { Ids = door.AdditionalAttractIds }
            end

            local room = door.Room
            room.ForceLootName = nil
            room.RewardOverrides = nil
            SetupRoomReward(CurrentRun, room, currentRewards,
                { Door = door, IgnoreForceLootName = room.IgnoreForceLootName })
            CreateDoorRewardPreview(door)
            thread(ExitDoorUnlockedPresentation, door)
            door.ReadyToUse = true
        end
    end
end

---@private
function LootRoomDuplicated.UnlockAllPlayers()
    for playerId, hero in CoopPlayers.PlayersIterator() do
        if hero and not hero.IsDead then
            RemoveInputBlock{
                PlayerIndex = playerId,
                Name = "LootRoomDuplicated"
            }
        end
    end
end

---@private
function LootRoomDuplicated.FullScreenFadeOutAnimationWrap(baseFun, ...)
    if LootRoomDuplicated.CurrentHeroChooser == nil then
        return baseFun(...)
    end

    local isLastChoiser = TableUtils.last(CoopPlayers.GetAliveHeroes()) == LootRoomDuplicated.CurrentHeroChooser
    if isLastChoiser then
        baseFun(...)
    end
end

---@private
-- Disable this room temporarily
function LootRoomDuplicated.IsGameStateEligibleWrap(baseFun, currentRun, source, requirements, args)
    if source and source.Name == "Devotion" then
        return false
    end
    return baseFun(currentRun, source, requirements, args)
end

return LootRoomDuplicated
