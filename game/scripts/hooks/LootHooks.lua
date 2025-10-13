--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"
---@type HeroContextProxy
local HeroContextProxy = ModRequire "../HeroContextProxy.lua"
---@type HeroContextProxyStore
local HeroContextProxyStore = ModRequire "../HeroContextProxyStore.lua"

---@type ILootDelivery
local LootDelivery = ModRequire "../loot/LootInterface.lua"

---@class LootHooks
local LootHooks = {}

---@private
---@type table | nil
LootHooks.BlindLootHero = nil

function LootHooks.InitHooks()
    -- Select hero for blind loot
    HookUtils.onPreFunction("UnwrapRandomLoot", function()
        LootHooks.BlindLootHero = CurrentRun.Hero
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

    LootHooks.InitRunHooks()
end

function LootHooks.InitRunHooks()
    if CurrentRun then
        LootHooks.InitLootHistoryProxy()
    end
end

---@private
function LootHooks.InitLootHistoryProxy()
    local proxyHandler = HeroContextProxy.New(CurrentRun, "LootTypeHistory")
    HeroContextProxyStore.Set("LootTypeHistory", proxyHandler)
end

---@private
function LootHooks.GiveLootHook(baseFun, args)
    local hero = LootHooks.UseBlindLootHero()
    if hero then
        return LootDelivery.GiveBlindLoot(baseFun, hero, args)
    else
        return LootDelivery.GiveLoot(baseFun, args)
    end
end

---@private
function LootHooks.UseBlindLootHero()
    if LootHooks.BlindLootHero then
        local hero = LootHooks.BlindLootHero
        LootHooks.BlindLootHero = nil
        return hero
    end
end

---@private
function LootHooks.DoUnlockRoomExitsHook(baseFun, run, room)
    local isRewarderd = LootHooks.CreateRoomsForDoors(run)
    if not isRewarderd then
        return baseFun(run, room)
    end

    LootDelivery.OnUnlockedRewardedRoom(baseFun, run, room)
end

---@private
function LootHooks.SpawnRoomRewardHook(baseFun, ...)
    -- Fix #16
    CurrentRun.CurrentRoom.DisableRewardMagnetisim = true

    LootDelivery.SpawnRoomReward(baseFun, ...)
end

---@private
---@param run table
function LootHooks.CreateRoomsForDoors(run)
    RandomSynchronize()

    local allRoomsHaveNoReward = true
    local allRoomsNoRecoil = true

    -- Create rooms here to avoid 
    for i, door in ipairs(CollapseTableOrdered(OfferedExitDoors)) do
        if not door.Room then
            local roomData = door.ForceRoomName and RoomData[door.ForceRoomName] or ChooseNextRoomData(run)

            if not roomData then
                return false
            end

            if not roomData.NoReward then
                allRoomsHaveNoReward = false
            end
            if not roomData.NoReroll then
                allRoomsNoRecoil = false
            end

            local roomForDoor = CreateRoom(roomData, { SkipChooseReward = true, SkipChooseEncounter = true, })
            roomForDoor.NeedsReward = true
            door.Room = roomForDoor
        end
    end

    if allRoomsHaveNoReward and allRoomsNoRecoil then
        return false
    end

    return true
end

return LootHooks
