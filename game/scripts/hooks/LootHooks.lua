--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"

---@class LootHooks
local LootHooks = {}

function LootHooks.InitHooks()
    -- Select hero for blind loot
    HookUtils.onPostFunction("UnwrapRandomLoot", function()
        for lootId, lootData in pairs(LootObjects) do
            if not lootData.Cost then
                CoopUseItem(CurrentRun.Hero.ObjectId, lootId)
                return
            end
        end
    end)
end

return LootHooks
