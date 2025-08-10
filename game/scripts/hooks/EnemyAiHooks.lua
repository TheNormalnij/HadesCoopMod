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
---@type HeroContextProxyStore
local HeroContextProxyStore = ModRequire "../HeroContextProxyStore.lua"
---@type TableUtils
local TableUtils = ModRequire "../TableUtils.lua"

---@class EnemyAiHooks
local EnemyAiHooks = {}

function EnemyAiHooks.InitHooks()
    HookUtils.wrap("NotifyWithinDistance", EnemyAiHooks.NotifyWithinDistanceHook)
    HookUtils.wrap("GetTargetId", EnemyAiHooks.GetTargetIdHook)
    HookUtils.wrap("IsAIActive", EnemyAiHooks.IsAIActiveHook)
    HookUtils.onPreFunction("Harpy3MapTransition", EnemyAiHooks.Harpy3MapTransitionPreHook)
    HookUtils.replace("SelectTheseusGod", EnemyAiHooks.SelectTheseusGodHook)
end

---@private
---@param unitId integer
function EnemyAiHooks.getNearestHero(unitId)
    local nearest
    local distance = 99999

    for playerId = 1, CoopPlayers.GetPlayersCount() do
        local hero = CoopPlayers.GetHero(playerId)
        if hero.IsDead then
            goto continue
        end
        local thisDistance = GetDistance { Id = hero.ObjectId, DestinationId = unitId }
        if thisDistance <= distance then
            nearest = hero
            distance = thisDistance
        end
        ::continue::
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
    return HeroContext.RunWithHeroContextReturn(hero, baseFun, enemy, weaponAiData)
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
        params.DestinationId = nil
        params.DestinationIds = CoopPlayers.GetUnits()
        params.Ids = params.Ids or { params.Id }
        params.Id = nil
        NotifyWithinDistanceAny(params)
    else
        baseFun(params)
    end
end

function EnemyAiHooks.RefreshAI()
    for _, enemy in pairs(ActiveEnemies) do
        if not enemy.IsDead then
            killTaggedThreads(enemy.AIThreadName)
            killWaitUntilThreads(enemy.AINotifyName)
            Stop({ Id = enemy.ObjectId })
            StopAnimation({ DestinationId = enemy.ObjectId })

            enemy.TargetId = nil
            thread(function()
                if enemy.AIStages ~= nil then
                    thread(StagedAI, enemy, CurrentRun)
                else
                    local aiBehavior = enemy.AIBehavior
                    if aiBehavior ~= nil then
                        thread(SetAI, aiBehavior, enemy, CurrentRun)
                    end
                end
            end)

        end
    end
end

function EnemyAiHooks.IsAIActiveHook(baseFun, ...)
    local alivePlayer = CoopPlayers.GetAliveHeroes()[1]
    if alivePlayer then
        return HeroContext.RunWithHeroContextReturn(alivePlayer, baseFun, ...)
    else
        return baseFun(...)
    end
end

function EnemyAiHooks.SelectTheseusGodHook(enemy)
    local allUsedGods

    local LootTypeHistoryProxy = HeroContextProxyStore.Get("LootTypeHistory")
    if LootTypeHistoryProxy then
        allUsedGods = {}
        for playerId = 1, CoopPlayers.GetPlayersCount() do
            TableUtils.copyTo(allUsedGods, LootTypeHistoryProxy:GetPlayerData(playerId))
        end
    else
        allUsedGods = CurrentRun.LootTypeHistory
    end

    local unusedGods = {}
    for name, lootData in pairs(LootData) do
        if lootData.GodLoot and not lootData.DebugOnly and not allUsedGods[name] and IsGameStateEligible(CurrentRun, lootData) then
            table.insert(unusedGods, name)
        end
    end

    local godName = GetRandomValue(unusedGods) or "ArtemisUpgrade"

    enemy.TheseusGodName = godName
	LoadPackages{ Names = godName }
end

-- Teleport all players to the center to prevent softlocks
function EnemyAiHooks.Harpy3MapTransitionPreHook()
    if CurrentRun.CurrentRoom.Name ~= "A_Boss03" then
        return
    end

    local mainHero = HeroContext.GetCurrentHeroContext()

    HookUtils.wrap("Teleport", function(baseFun, args)
        baseFun(args)
        if args.DestinationId == 40012 and args.Id == mainHero.ObjectId then
            Teleport = baseFun
            for _, hero in CoopPlayers.PlayersIterator() do
                if hero and not hero.IsDead and hero ~= mainHero then
                    Teleport { Id = hero.ObjectId, DestinationId = args.DestinationId }
                end
            end
        end
    end)
end

return EnemyAiHooks
