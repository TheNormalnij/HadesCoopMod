--
-- Hides parts of the UI of some players (config.lua: HideUiDuringBoss) while a boss health bar is shown.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"
---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"
---@type CoopModConfig
local Config = ModRequire "../config.lua"
---@type CoopUiVisibility
local CoopUiVisibility = ModRequire "../CoopUiVisibility.lua"
---@type SecondPlayerUi
local SecondPlayerUi = ModRequire "../SecondPlayerUI.lua"
---@type TraitTrays
local TraitTrays = ModRequire "../TraitTrays.lua"

---@class BossUiHooks
local BossUiHooks = {}

---@private
function BossUiHooks.IsBossFight()
    return GetNumBossHealthBars() > 0
end

---@private
function BossUiHooks.ShowPart(playerId, part)
    local hero = CoopPlayers.GetHero(playerId)
    if not hero or hero.IsDead or not ShowingCombatUI then
        -- Created by the next ShowCombatUI
        return
    end
    if part == "Tray" then
        TraitTrays.Refresh()
        return
    end
    local ui = SecondPlayerUi.Get(playerId)
    HeroContext.RunWithHeroContext(hero, function()
        ui.ShowHealthUI()
        ui.ShowAmmoUI()
        ui.ShowGunUI()
        ui.ShowSuperMeter()
        ui.Refresh()
    end)
end

---@private
function BossUiHooks.HidePart(playerId, part)
    if part == "Tray" then
        TraitTrays.DestroyTray(playerId)
    else
        SecondPlayerUi.DestroyPlayerHud(playerId)
    end
end

function BossUiHooks.Update()
    local bossFight = BossUiHooks.IsBossFight()
    for playerId, parts in pairs(Config.HideUiDuringBoss or {}) do
        if playerId > 1 and type(parts) == "table" then
            for _, part in ipairs({ "Hud", "Tray" }) do
                local hidden = CoopUiVisibility.IsHidden(playerId, part)
                if parts[part] and bossFight and not hidden then
                    BossUiHooks.HidePart(playerId, part)
                    CoopUiVisibility.SetHidden(playerId, part, true)
                elseif hidden and (not bossFight or not parts[part]) then
                    CoopUiVisibility.SetHidden(playerId, part, false)
                    BossUiHooks.ShowPart(playerId, part)
                end
            end
        end
    end
end

function BossUiHooks.InitHooks()
    HookUtils.onPostFunction("CreateBossHealthBar", BossUiHooks.Update)
    -- The boss is removed from ActiveEnemies after RemoveEnemyUI
    HookUtils.onPostFunction("RemoveEnemyUI", function()
        thread(function()
            wait(0.5, RoomThreadName)
            BossUiHooks.Update()
        end)
    end)
    -- Fallback: a new room never starts with a boss health bar
    HookUtils.onPreFunction("StartRoom", BossUiHooks.Update)
end

return BossUiHooks
