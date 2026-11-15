--
-- Hides the UI (HUD and boon tray) of some players during boss fights,
-- so the boss health bar at the top of the screen is visible.
-- Players are set in config.lua (HideUiDuringBoss).
--
-- While a player's UI is hidden, all updates of it are skipped
-- (SecondPlayerUI functions and TraitTrays do nothing for this player).
--

---@class CoopUiVisibility
local CoopUiVisibility = {}

---@private
---@type table<number, boolean>
CoopUiVisibility.Hidden = {}

---@param playerId number
---@return boolean
function CoopUiVisibility.IsHidden(playerId)
    return CoopUiVisibility.Hidden[playerId] == true
end

---@param playerId number
---@param hidden boolean
function CoopUiVisibility.SetHidden(playerId, hidden)
    CoopUiVisibility.Hidden[playerId] = hidden or nil
end

return CoopUiVisibility
