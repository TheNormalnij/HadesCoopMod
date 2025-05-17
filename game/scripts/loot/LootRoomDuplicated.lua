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

---@class LootRoomDuplicated : ILootDelivery
local LootRoomDuplicated = {}

---@class SelectedPlayerReward
---@field rewardType string
---@field lootName string

---@private
---@type SelectedPlayerReward[]
LootRoomDuplicated.ChosenPlayerLoot = {}

---@private
---@type table
LootRoomDuplicated.CurrentHeroChooser = nil

---@private
---@type number?
LootRoomDuplicated.TagNextLootForPlayer = nil

function LootRoomDuplicated.InitHooks()
    HookUtils.wrap("CheckSpecialDoorRequirement", LootRoomDuplicated.CheckSpecialDoorRequirementWrap)
    HookUtils.wrap("CreateLoot", LootRoomDuplicated.CreateLootWrap)
end

---@param baseFun fun(run: table, room: table)
---@param run table
---@param room table
function LootRoomDuplicated.OnUnlockedRewardedRoom(baseFun, run, room)
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
    if eventSource.RewardStoreName == "MetaProgress" then
        return baseFun(eventSource, args)
    end

    local room = CurrentRun.CurrentRoom
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
function LootRoomDuplicated.CheckSpecialDoorRequirementWrap(baseFun, room)
    local currentBlocker = baseFun(room)
    if currentBlocker then
        return currentBlocker
    end

    if LootRoomDuplicated.CurrentHeroChooser == nil then
        return nil
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

return LootRoomDuplicated
