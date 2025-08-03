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
---@type TableUtils
local TableUtils = ModRequire "../TableUtils.lua"
---@type HeroEx
local HeroEx = ModRequire "../HeroEx.lua"
---@type RunEx
local RunEx = ModRequire "../RunEx.lua"
---@type CoopCamera
local CoopCamera = ModRequire "../CoopCamera.lua"

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
    -- For styx temple
    RoomRewardMoneyDrop = true;
    RoomRewardMaxHealthDrop = true;
}

---@private
LootRoomDuplicated.CanBeUsedByAnyPlayer = {
    RoomRewardMoneyDrop = true,
    Money = true,
}

function LootRoomDuplicated.InitHooks()
    HookUtils.wrap("CheckSpecialDoorRequirement", LootRoomDuplicated.CheckSpecialDoorRequirementWrap)
    HookUtils.wrap("CreateLoot", LootRoomDuplicated.CreateRewardWrap)
    HookUtils.wrap("CreateConsumableItem", LootRoomDuplicated.CreateRewardWrap)
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
    LootRoomDuplicated.ResetRoomLootState()

    local firstAliveHero = CoopPlayers.GetAliveHeroes()[1]
    if not firstAliveHero then
        -- Fallback. This case should not happen.
        return baseFun(run, room)
    end

    if RunEx.IsStyxTempleHubRoom(room) then
        -- Styx room
        if CurrentRun.StyxLoot then
            LootRoomDuplicated.RestoreGeneratedStyxRewards(baseFun, run, room)
        else
            LootRoomDuplicated.HandleStyxRewardsFirstTime(baseFun, run, room)
        end
    elseif CurrentRun.StyxChoosenDoor then
        LootRoomDuplicated.CurrentHeroChooser = nil
        HeroContext.RunWithHeroContextAwait(firstAliveHero, baseFun, run, room)
    elseif run.NextRewardStoreName == "MetaProgress" then
        HeroContext.RunWithHeroContextAwait(firstAliveHero, baseFun, run, room)
        if RunEx.IsDefaultDoorsLeadToRunProgress() then
            --- NextRewardStoreName can be overrided
            LootRoomDuplicated.CurrentHeroChooser = firstAliveHero
        else
            -- Do not duplicate meta progress
            LootRoomDuplicated.CurrentHeroChooser = nil
        end
    else
        HeroContext.RunWithHeroContextAwait(firstAliveHero, baseFun, run, room)
        LootRoomDuplicated.CurrentHeroChooser = firstAliveHero
    end
end

---@private
function LootRoomDuplicated.HandleStyxRewardsFirstTime(baseFun, run, room)
    CurrentRun.StyxLoot = {}

    local handledFirstPlayer = false

    for playerId, hero in CoopPlayers.PlayersIterator() do
        local playerLoot = {}
        CurrentRun.StyxLoot[playerId] = playerLoot
        if not hero.IsDead then
            if handledFirstPlayer then
                HeroContext.RunWithHeroContextAwait(hero, LootRoomDuplicated.RecreateDoorRewards)
            else
                HeroContext.RunWithHeroContextAwait(hero, baseFun, run, room)
                handledFirstPlayer = true
            end
            for doorObjectId, door in pairs(OfferedExitDoors) do
                if door.IsDefaultDoor then
                    local doorRoom = door.Room
                    local lootName = doorRoom.ForceLootName or doorRoom.ChosenRewardType
                    playerLoot[doorObjectId] = {
                        RewardType = doorRoom.ChosenRewardType,
                        LootName = lootName
                    }

                    RunEx.RemoveDoorReward(door)
                end
            end
        end
    end

    local firstAliveHero = CoopPlayers.GetAliveHeroes()[1]
    LootRoomDuplicated.ShowStyxRoomsFormPlayer(firstAliveHero)
    LootRoomDuplicated.CurrentHeroChooser = firstAliveHero
end

---@private
function LootRoomDuplicated.RestoreGeneratedStyxRewards(baseFun, run, room)
    DebugPrint { Text = "LootRoomDuplicated: RestoreGeneratedStyxRewards called." }
    local firstAliveHero = CoopPlayers.GetAliveHeroes()[1]

    -- Enable to restore miniboss rooms
    room.PersistentExitDoorRewards = true
    HeroContext.RunWithHeroContextAwait(firstAliveHero, baseFun, run, room)
    -- If not disabled, this shit restores wrong loot in SetupRoomReward
    room.PersistentExitDoorRewards = false

    RunEx.RemoveRewardFromAllDefaultDoors()
    LootRoomDuplicated.ShowStyxRoomsFormPlayer(firstAliveHero)
    LootRoomDuplicated.CurrentHeroChooser = firstAliveHero
    CurrentRun.StyxChoosenDoor = nil
end

---@private
function LootRoomDuplicated.ShowStyxRoomsFormPlayer(hero)
    local playerId = CoopPlayers.GetPlayerByHero(hero)
    if not CurrentRun.StyxLoot or not CurrentRun.StyxLoot[playerId] then
        return
    end

    local playerLoot = CurrentRun.StyxLoot[playerId]
    for doorObjectId, loot in pairs(playerLoot) do
        local door = OfferedExitDoors[doorObjectId]
        if door then
            local room = door.Room
            room.ForceLootName = loot.LootName
            room.ChosenRewardType = loot.RewardType
            SetupRoomReward(CurrentRun, room, {}, { Door = door, IgnoreForceLootName = true })
            CreateDoorRewardPreview(door)
        end
    end
end

---@param baseFun fun(eventSource: table, args: table)
---@param eventSource table
---@param args table
function LootRoomDuplicated.SpawnRoomReward(baseFun, eventSource, args)
    local room = CurrentRun.CurrentRoom
    local rewardType = room.ChangeReward or room.ChosenRewardType
    DebugPrint{ Text = "LootRoomDuplicated: SpawnRoomReward called with rewardType: " .. tostring(rewardType) }

    if not LootRoomDuplicated.DuplicatedRewards[rewardType] then
        return baseFun(eventSource, args)
    end

    for playerId, hero in CoopPlayers.PlayersIterator() do
        local lootParams = LootRoomDuplicated.ChosenPlayerLoot[playerId] or {}
        if not hero.IsDead then
            room.ChangeReward = lootParams.rewardType
            room.ForceLootName = lootParams.lootName
            LootRoomDuplicated.TagNextLootForPlayer = not LootRoomDuplicated.CanBeUsedByAnyPlayer[rewardType] and playerId or nil
            HeroContext.RunWithHeroContextAwait(hero, baseFun, eventSource, args)
        end
    end
end

---@param heroesCount number
function LootRoomDuplicated.Reset(heroesCount)
    HeroContextProxyStore.GetOrCreate("LootTypeHistory"):Reset()
    CurrentRun.StyxLoot = nil
    local room = CurrentRun.CurrentRoom
    if room and room.ChosenRewardType == "Boon" and room.ForceLootName then
        LootRoomDuplicated.ChosenPlayerLoot = {{
            rewardType = room.ChosenRewardType,
            lootName = room.ForceLootName
        }}
        for playerId, hero in CoopPlayers.AdditionalHeroesIterator() do
            local keepsake = HeroEx.GetGiftAndAssist(hero)

            local trait = keepsake and TraitData[keepsake]
            if trait and trait.ForceBoonName then
                LootRoomDuplicated.ChosenPlayerLoot[playerId] = {
                    rewardType = room.ChosenRewardType,
                    lootName = trait.ForceBoonName
                }
            end
        end
    end

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

    if RunEx.IsFinalBossDoor(door) then
        return nil
    end

    -- Special case for secret (chaos) door
    if RunEx.IsDoorSpecial(door) and not LootRoomDuplicated.IsSpecialDoorAllowed() then
        return "ExitNotActive"
    end

    if LootRoomDuplicated.CurrentHeroChooser ~= CurrentRun.Hero then
        return "ExitNotActive"
    end

    if CurrentRun.StyxChoosenDoor and CurrentRun.StyxChoosenDoor ~= door.ObjectId then
        return "ExitNotActive"
    end

    -- Ok, the player can use the exit door
    return nil
end

---@param baseFun fun(...): table
---@param ... any
---@return table
function LootRoomDuplicated.CreateRewardWrap(baseFun, ...)
    if LootRoomDuplicated.TagNextLootForPlayer == nil then
        return baseFun(...)
    else
        local loot = baseFun(...)
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

---@private
function LootRoomDuplicated.LeaveRoomWrap(baseFun, currentRun, door)
    if CurrentRun.StyxLoot then
        if not CurrentRun.StyxChoosenDoor then
            CurrentRun.StyxChoosenDoor = door.ObjectId
        end

        if not LootRoomDuplicated.CurrentHeroChooser then
            return baseFun(currentRun, door)
        end
    end

    if LootRoomDuplicated.CurrentHeroChooser == nil
        or RunEx.IsDoorSpecial(door)
        or RunEx.IsFinalBossDoor(door)
    then
        CurrentRun.CurrentRoom.SkipLoadNextMap = LootRoomDuplicated.ShouldSkipLoadingNextMap
        return baseFun(currentRun, door)
    end

    -- TODO Remove this shit here
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

    -- Only the first player can create shop
    local isFinishedChoceLoop = isLastChoiser or room.ChosenRewardType == "Shop"
    if isFinishedChoceLoop then
        CurrentRun.CurrentRoom.SkipLoadNextMap = LootRoomDuplicated.ShouldSkipLoadingNextMap
    else
        CurrentRun.CurrentRoom.SkipLoadNextMap = true
    end

    baseFun(currentRun, door)

    if isFinishedChoceLoop then
        CoopCamera.ResetIgnore()
        LootRoomDuplicated.CurrentHeroChooser = nil
        LootRoomDuplicated.RewardChoiseInProgress = false
        LootRoomDuplicated.UnlockAllPlayers()
        SetPlayerVulnerable("LootRoomDuplicated")
    else
        CoopCamera.SetHeroIgnored(CurrentRun.Hero, true)
        CoopCamera.ForceFocus(true)

        AddInputBlock {
            PlayerIndex = playerId,
            Name = "LootRoomDuplicated"
        }

        LootRoomDuplicated.CurrentHeroChooser = TableUtils.after(aliveHeroes, CurrentRun.Hero)

        LootRoomDuplicated.UnvalidateDoorRewardsPresentation(currentRun, door)

        if CurrentRun.StyxLoot then
            RunEx.RemoveRewardFromAllDefaultDoors()
            LootRoomDuplicated.ShowStyxRoomsFormPlayer(LootRoomDuplicated.CurrentHeroChooser)
            door.ReadyToUse = true
        else
            if CurrentRun.Hero == aliveHeroes[1] then
                -- Only the first player can create shop or story rooms
                LootRoomDuplicated.RecreateSpecialRooms()
            end

            HeroContext.RunWithHeroContextAwait(LootRoomDuplicated.CurrentHeroChooser,
                LootRoomDuplicated.RecreateDoorRewards)
        end

    end
end

---@private
function LootRoomDuplicated.UnvalidateDoorRewardsPresentation(run, door)
    if door.ExitFunctionName == "AsphodelLeaveRoomPresentation" then
        -- Asphodel should have some sort of animation to hide boat teleportation
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
--- Call this function with right hero context
function LootRoomDuplicated.RecreateDoorRewards()
    -- This table doesn't allow using the same boon twice
    local currentRewards = {}
    for doorObjectId, door in pairs(OfferedExitDoors) do
        if door.IsDefaultDoor then
            RunEx.RemoveDoorReward(door)

            local room = door.Room
            SetupRoomReward(CurrentRun, room, currentRewards,
                { Door = door, IgnoreForceLootName = room.IgnoreForceLootName })
            CreateDoorRewardPreview(door)

            table.insert(currentRewards,
                { RewardType = room.ChosenRewardType, ForceLootName = room.ForceLootName })
            thread(ExitDoorUnlockedPresentation, door)
            door.ReadyToUse = true
        end
    end
end

---@private
function LootRoomDuplicated.RecreateSpecialRooms()
    for doorObjectId, door in pairs(OfferedExitDoors) do
        local room = door.Room
        if RunEx.IsShopRoomName(room.Name) or RunEx.IsStoryRoomName(room.Name) or (RunEx.IsPrebossRoomName(room.Name) and room.ChosenRewardType == "Shop")  then
            door.Room = CreateRoom( ChooseNextRoomData( CurrentRun ), { SkipChooseReward = true, SkipChooseEncounter = true, })
            AssignRoomToExitDoor(door, door.Room)
            -- Huh, can be done better
            door.Room.ChosenRewardType = "Boon"
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
function LootRoomDuplicated.IsGameStateEligibleWrap(baseFun, currentRun, source, requirements, args)
    if source then
        local name = source.Name
        if name == "Devotion" then
            -- Devotion is disabled in this mode
            return false
        end
        if RunEx.IsShopRoomName(name) or RunEx.IsStoryRoomName(name) then
            -- Shop room and story is not allowed for the second player
            if LootRoomDuplicated.CurrentHeroChooser and LootRoomDuplicated.CurrentHeroChooser ~= CoopPlayers.GetFirstAliveHero() then
                return false
            end
        end
    end

    return baseFun(currentRun, source, requirements, args)
end

return LootRoomDuplicated
