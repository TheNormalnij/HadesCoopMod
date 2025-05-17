--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"

---@class LootQuery
local LootQuery = {}

LootQuery.PlayersCount = 1

---@param heroesCount number
function LootQuery.Reset(heroesCount)
    LootQuery.LootHeroCount = heroesCount
    CurrentRun.CoopLootCounter = CurrentRun.CoopLootCounter or RandomInt(1, heroesCount)
end

---@return number | nil
function LootQuery.UseNextHeroForLoot()
    if LootQuery.LootHeroCount <= 1 then
        return
    end

    local startPos = CurrentRun.CoopLootCounter
    local playerIndex = startPos + 1
    while true do
        if playerIndex > LootQuery.LootHeroCount then
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

return LootQuery
