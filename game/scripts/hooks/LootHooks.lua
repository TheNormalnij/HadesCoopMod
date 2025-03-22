--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type GameModifed
local GameModifed = ModRequire "../GameModifed.lua"

local LootHooks = {}

function LootHooks.InitHooks()
    -- The game has autouse for a blind loot in shop
    -- We disable it here
    -- TODO add autouse, but select current player
    UnwrapRandomLoot = GameModifed.UnwrapRandomLoot
end

return LootHooks
