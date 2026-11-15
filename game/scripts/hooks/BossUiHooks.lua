--
-- Hides the UI of some players (config.lua: HideUiDuringBoss) while a boss health bar is shown.
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
function BossUiHooks.ShowPlayerUi(playerId)
    local hero = CoopPlayers.GetHero(playerId)
    local ui = SecondPlayerUi.Get(playerId)
    if not hero or hero.IsDead or not ui or not ShowingCombatUI then
        -- Created by the next ShowCombatUI
        return
    end
    HeroContext.RunWithHeroContext(hero, function()
        ui.ShowHealthUI()
        ui.ShowAmmoUI()
        ui.ShowGunUI()
        ui.ShowSuperMeter()
        ui.Refresh()
    end)
    TraitTrays.Refresh()
end

function BossUiHooks.Update()
    local bossFight = BossUiHooks.IsBossFight()
    for playerId, enabled in pairs(Config.HideUiDuringBoss or {}) do
        if enabled and playerId > 1 then
            local hidden = CoopUiVisibility.IsHidden(playerId)
            if bossFight and not hidden then
                SecondPlayerUi.DestroyPlayerHud(playerId)
                TraitTrays.DestroyTray(playerId)
                CoopUiVisibility.SetHidden(playerId, true)
            elseif not bossFight and hidden then
                CoopUiVisibility.SetHidden(playerId, false)
                BossUiHooks.ShowPlayerUi(playerId)
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
