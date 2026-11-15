--
-- Hides parts of a player's UI during boss fights, so the boss health bar
-- at the top of the screen is visible. Parts: "Hud" (health, ammo, wrath) and
-- "Tray" (boon tray). Players and parts are set in config.lua (HideUiDuringBoss).
--
-- While a part is hidden, all its updates are skipped
-- (SecondPlayerUI for "Hud", TraitTrays for "Tray").
--

---@class CoopUiVisibility
local CoopUiVisibility = {}

---@private
---@type table<string, boolean> "playerId:part" -> hidden
CoopUiVisibility.Hidden = {}

---@param playerId number
---@param part string "Hud" or "Tray"
---@return boolean
function CoopUiVisibility.IsHidden(playerId, part)
    return CoopUiVisibility.Hidden[playerId .. ":" .. part] == true
end

---@param playerId number
---@param part string "Hud" or "Tray"
---@param hidden boolean
function CoopUiVisibility.SetHidden(playerId, part, hidden)
    CoopUiVisibility.Hidden[playerId .. ":" .. part] = hidden or nil
end

return CoopUiVisibility
