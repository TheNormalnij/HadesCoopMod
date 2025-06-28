--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@class ILootDelivery
---@field InitHooks fun()
---@field OnUnlockedRewardedRoom fun(baseFun: fun(run: table, room: table), run: table, room: table)
---@field SpawnRoomReward fun(baseFun: fun(eventSource: table, args: table), eventSource: table, args: table)
---@field GiveBlindLoot fun(baseFun: fun(args: table), hero: table, args: table): table
---@field GiveLoot fun(baseFun: fun(args: table), args: table): table
---@field Reset fun(playersCount: number)
---@field CanUseHeroLoot fun(loot: table, hero: table): boolean

---@type CoopModConfig
local Config = ModRequire "../config.lua"

local DELIVERY_TYPE_TO_HANDLER = {
    Shared = "LootShared.lua";
    RoomDuplicated = "LootRoomDuplicated.lua"
}

return ModRequire( DELIVERY_TYPE_TO_HANDLER[Config.LootDelivery or "Shared"] or DELIVERY_TYPE_TO_HANDLER.Shared )
