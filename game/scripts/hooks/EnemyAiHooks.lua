--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"
---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"

---@class EnemyAiHooks
local EnemyAiHooks = {}

function EnemyAiHooks.InitHooks()
    HookUtils.wrap("NotifyWithinDistance", EnemyAiHooks.NotifyWithinDistanceHook)
    HookUtils.wrap("GetTargetId", EnemyAiHooks.GetTargetIdHook)
end

---@private
---@param unitId integer
function EnemyAiHooks.getNearestHero(unitId)
    local nearest
    local distance = 99999

    for playerId = 1, CoopPlayers.GetPlayersCount() do
        local hero = CoopPlayers.GetHero(playerId)
        local thisDistance = GetDistance { Id = hero.ObjectId, DestinationId = unitId }
        if thisDistance <= distance then
            nearest = hero
            distance = thisDistance
        end
    end

    return nearest or HeroContext.GetDefaultHero()
end

---@private
---@param baseFun function
---@param enemy table
---@param weaponAiData table?
---@return integer
function EnemyAiHooks.GetTargetIdHook(baseFun, enemy, weaponAiData)
    local hero = EnemyAiHooks.getNearestHero(enemy.ObjectId)
    local targetId
    HeroContext.RunWithHeroContext(hero, function() targetId = baseFun(enemy, weaponAiData) end)
    return targetId
end

---@private
---@param baseFun function
---@param params table
function EnemyAiHooks.NotifyWithinDistanceHook(baseFun, params)
    if params.Notify == "ContractOpen" then
        -- Skip pact door
        baseFun(params)
        return
    end

    if CoopPlayers.IsPlayerUnit(params.DestinationId) then
        for playerId = 1, CoopPlayers.GetPlayersCount() do
            local hero = CoopPlayers.GetHero(playerId)
            if hero and hero.ObjectId then
                params.DestinationId = hero.ObjectId
                baseFun(params)
            end
        end
    else
        baseFun(params)
    end
end

return EnemyAiHooks
