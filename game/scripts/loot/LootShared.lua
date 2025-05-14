--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"
---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HeroContextProxyStore
local HeroContextProxyStore = ModRequire "../HeroContextProxyStore.lua"

---@class LootShared : ILootDelivery
local LootShared = {}

---@private
LootShared.LootHeroCount = 1

---@param baseFun fun(run: table, room: table)
---@param run table
---@param room table
function LootShared.OnUnlockedRewardedRoom(baseFun, run, room)

    local playerIndex = LootShared.UseNextHeroForLoot()
    if playerIndex then
        room.CoopModPlayerId = playerIndex
        HeroContext.RunWithHeroContext(CoopPlayers.GetHero(playerIndex), baseFun, run, room)
    else
        baseFun(run, room)
    end
end

---@param baseFun fun(eventSource: table, args: table)
---@param eventSource table
---@param args table
function LootShared.SpawnRoomReward(baseFun, eventSource, args)
    local room = CurrentRun.CurrentRoom
    local roomRewardPredefinedPlayerId = room.CoopModPlayerId

    local hero = roomRewardPredefinedPlayerId and CoopPlayers.GetHero(roomRewardPredefinedPlayerId) or CurrentRun.Hero

    if hero.IsDead then
        local alternativePlayerIndex
        if roomRewardPredefinedPlayerId then
            alternativePlayerIndex = LootShared.UseNextHeroForLoot()

            if not alternativePlayerIndex then
                DebugPrint { Text = "Cannot spawn a loot for a player. Cannot choose alternative hero" }
                return baseFun(eventSource, args)
            end

            hero = CoopPlayers.GetHero(alternativePlayerIndex)
        else
            hero = CoopPlayers.GetAliveHeroes()[1]

            if not hero then
                DebugPrint { Text = "Cannot spawn a loot for a player. All players are dead" }
                return baseFun(eventSource, args)
            end
        end
    end

    HeroContext.RunWithHeroContextAwait(hero, baseFun, eventSource, args)
end

---@private
---@return number | nil
function LootShared.UseNextHeroForLoot()
    if LootShared.LootHeroCount <= 1 then
        return
    end

    local startPos = CurrentRun.CoopLootCounter
    local playerIndex = startPos + 1
    while true do
        if playerIndex > LootShared.LootHeroCount then
            playerIndex = 1
        end

        if playerIndex == startPos then
            return
        end

        local hero = CoopPlayers.GetHero(playerIndex)
        if not hero.IsDead then
            CurrentRun.CoopLootCounter = playerIndex
            return playerIndex
        end

        playerIndex = playerIndex + 1
    end
end

---@param heroesCount number
function LootShared.Reset(heroesCount)
    HeroContextProxyStore.GetOrCreate("LootTypeHistory"):Reset()

    LootShared.LootHeroCount = heroesCount
    CurrentRun.CoopLootCounter = CurrentRun.CoopLootCounter or RandomInt(1, heroesCount)
end

function LootShared.GiveBlindLoot(baseFun, hero, args)
    return HeroContext.RunWithHeroContextReturn(hero, baseFun, args)
end

function LootShared.GiveLoot(baseFun, args)
    return baseFun(args)
end

return LootShared
