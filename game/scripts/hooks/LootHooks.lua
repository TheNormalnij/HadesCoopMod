--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"
---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"
---@type HeroContextProxy
local HeroContextProxy = ModRequire "../HeroContextProxy.lua"
---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"

---@class LootHooks
local LootHooks = {}

---@private
---@type table | nil
LootHooks.ForceNextLootHero = nil

---@private
LootHooks.LootHeroCount = 1

---@private
LootHooks.LootCounter = 1

function LootHooks.InitHooks()
    -- Select hero for blind loot
    HookUtils.onPreFunction("UnwrapRandomLoot", function()
        LootHooks.ForceNextLootHero = CurrentRun.Hero
    end)

    HookUtils.onPostFunction("UnwrapRandomLoot", function()
        for lootId, lootData in pairs(LootObjects) do
            if not lootData.Cost then
                CoopUseItem(CurrentRun.Hero.ObjectId, lootId)
                return
            end
        end
    end)

    HookUtils.wrap("GiveLoot", LootHooks.GiveLootHook)

    -- Select a player for room reward
    HookUtils.wrap("DoUnlockRoomExits", LootHooks.DoUnlockRoomExitsHook)

    -- Spawns room reward for a player selected by room
    HookUtils.wrap("SpawnRoomReward", LootHooks.SpawnRoomRewardHook)
end

---@param heroesCount number
function LootHooks.Reset(heroesCount)
    HeroContextProxy.Make(CurrentRun.LootTypeHistory)
    LootHooks.LootHeroCount = heroesCount
    LootHooks.LootCounter = RandomInt(1, heroesCount)
end

---@private
function LootHooks.GiveLootHook(baseFun, args)
    local hero = LootHooks.UseForcedLootHero()
    if hero then
        return HeroContext.RunWithHeroContextReturn(hero, baseFun, args)
    else
        return baseFun(args)
    end
end

---@private
function LootHooks.UseForcedLootHero()
    if LootHooks.ForceNextLootHero then
        local hero = LootHooks.ForceNextLootHero
        LootHooks.ForceNextLootHero = nil
        return hero
    end
end

---@private
---@return number | nil
function LootHooks.UseNextHeroForLoot()
    if LootHooks.LootHeroCount <= 1 then
        return
    end

    local startPos = LootHooks.LootCounter
    local playerIndex = startPos + 1
    while true do
        if playerIndex > LootHooks.LootHeroCount then
            playerIndex = 1
        end

        if playerIndex == startPos then
            return
        end

        local hero = CoopPlayers.GetHero(playerIndex)
        if not hero.IsDead then
            LootHooks.LootCounter = playerIndex
            return playerIndex
        end

        playerIndex = playerIndex + 1
    end
end

---@private
function LootHooks.DoUnlockRoomExitsHook(baseFun, run, room)
    if not LootHooks.NeedsCurrentRoomExitRewards() then
        return baseFun(run, room)
    end

    local playerIndex = LootHooks.UseNextHeroForLoot()
    if playerIndex then
        room.CoopModPlayerId = playerIndex
        HeroContext.RunWithHeroContext(CoopPlayers.GetHero(playerIndex), baseFun, run, room)
    else
        baseFun(run, room)
    end
end

---@private
function LootHooks.SpawnRoomRewardHook(baseFun, ...)
    local room = CurrentRun.CurrentRoom
    local roomRewardPredefinedPlayerId = room.CoopModPlayerId

    local hero = roomRewardPredefinedPlayerId and CoopPlayers.GetHero(roomRewardPredefinedPlayerId) or CurrentRun.Hero

    if hero.IsDead then
        local alternativePlayerIndex
        if roomRewardPredefinedPlayerId then
            alternativePlayerIndex = LootHooks.UseNextHeroForLoot()

            if not alternativePlayerIndex then
                DebugPrint { Text = "Cannot spawn a loot for a player. Cannot choose alternative hero" }
                return baseFun(...)
            end

            hero = CoopPlayers.GetHero(alternativePlayerIndex)
        else
            hero = CoopPlayers.GetAliveHeroes()[1]

            if not hero then
                DebugPrint { Text = "Cannot spawn a loot for a player. All players are dead" }
                return baseFun(...)
            end
        end
    end

    HeroContext.RunWithHeroContext(hero, baseFun, ...)
end

---@private
function LootHooks.NeedsCurrentRoomExitRewards()
    for _, door in pairs(OfferedExitDoors) do
        if door.NeedsReward then
            return true
        end
    end
    return false
end

return LootHooks
