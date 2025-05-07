--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopModConfig
local Config = ModRequire "config.lua"

---@class PlayerVisibilityHelper
local PlayerVisibilityHelper = {}

---@param playerId number
---@param unit number
function PlayerVisibilityHelper.AddPlayerMarkers(playerId, unit)
    if Config["Player" .. playerId .. "HasOutline"] then
        AddOutline(
            MergeTables(Config["Player" .. playerId .. "Outline"], { Id = unit })
        )
    end
    if Config.TextAbovePlayersEnabled then
        CreateTextBox(
            MergeTables(Config.TextAbovePlayersParams,
            {
                Id = unit,
                Text = "P" .. playerId,
            })
        )
    end
end

return PlayerVisibilityHelper
