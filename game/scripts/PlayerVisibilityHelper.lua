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

-- Text color of the "P1/P2/P3" label, made from the player outline color
---@param playerId number
function PlayerVisibilityHelper.GetPlayerTextColor(playerId)
    local outline = Config["Player" .. playerId .. "Outline"]
    if not outline then
        return { 255, 255, 255, 255 }
    end
    local function channel(value)
        return (value or 0) > 0 and 255 or 90
    end
    return { channel(outline.R), channel(outline.G), channel(outline.B), 255 }
end

--- Marks a reward that only one player can take: player outline color + "P2" label above it
---@param playerId number
---@param objectId number
function PlayerVisibilityHelper.AddLootMarker(playerId, objectId)
    if not objectId then
        return
    end
    if Config["Player" .. playerId .. "HasOutline"] then
        AddOutline(MergeTables(Config["Player" .. playerId .. "Outline"], { Id = objectId }))
    end
    CreateTextBox({
        Id = objectId,
        Text = "P" .. playerId,
        OffsetY = -110,
        FontSize = 30,
        Color = PlayerVisibilityHelper.GetPlayerTextColor(playerId),
        ShadowColor = { 0, 0, 0, 240 },
        ShadowOffset = { 0, 2 },
        ShadowBlur = 0,
        OutlineThickness = 3,
        OutlineColor = { 0, 0, 0, 1 },
        Font = "AlegreyaSansSCBold",
        Justification = "Center",
    })
end

--- "P1/P2/P3" label above a door reward icon
---@param playerId number
---@param iconId number
function PlayerVisibilityHelper.AddDoorIconLabel(playerId, iconId)
    CreateTextBox({
        Id = iconId,
        Text = "P" .. playerId,
        OffsetY = -75,
        FontSize = 24,
        Color = PlayerVisibilityHelper.GetPlayerTextColor(playerId),
        ShadowColor = { 0, 0, 0, 240 },
        ShadowOffset = { 0, 2 },
        ShadowBlur = 0,
        OutlineThickness = 3,
        OutlineColor = { 0, 0, 0, 1 },
        Font = "AlegreyaSansSCBold",
        Justification = "Center",
    })
end

return PlayerVisibilityHelper
