--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"
---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"
---@type CoopControl
local CoopControl = ModRequire "../CoopControl.lua"
---@type HeroEx
local HeroEx = ModRequire "../HeroEx.lua"

---@class MenuHooks
local MenuHooks = {}

function MenuHooks.InitHooks()
    MenuHooks.HookUiControl("ShowWeaponUpgradeScreen")
    MenuHooks.HookUiControl("ShowAwardMenu")
    MenuHooks.HookUiControl("PlayTextLines")
    MenuHooks.HookUiControl("OpenUpgradeChoiceMenu")
    MenuHooks.HookUiControl("ShowAdvancedTooltip")
    MenuHooks.HookUiControl("ShowStoreScreen")
    MenuHooks.HookUiControl("OpenSellTraitMenu")

    HookUtils.onPreFunction("ShowAwardMenu", function()
        local currentGift, currentAssist = HeroEx.GetGiftAndAssist(CurrentRun.Hero)

        GameState.LastAwardTrait = currentGift
        GameState.LastAssistTrait = currentAssist
    end)

    HookUtils.wrap("OpenSellTraitMenu", function(base)
        local playerId = CoopPlayers.GetPlayerByHero(HeroContext.GetCurrentHeroContext()) or 1

        local currentRoom = CurrentRun.CurrentRoom
        local backup
        if playerId > 1 then
            backup = currentRoom.SellOptions
            currentRoom.SellOptions = currentRoom["SellOptions" .. playerId]
        end

        base()

        if playerId > 1 then
            currentRoom["SellOptions" .. playerId] = currentRoom.SellOptions
            currentRoom.SellOptions = backup
        end
    end)
end

---@private
---@param funName string
function MenuHooks.HookUiControl(funName)
    local originalFun = _G[funName]
    _G[funName] = function(...)
        local currentHero = HeroContext.GetCurrentHeroContext()
        local playerId = CoopPlayers.GetPlayerByHero(currentHero)
        CoopControl.SwitchControlForMenu(playerId)

        HookUtils.onPreFunctionOnce("UnfreezePlayerUnit", function()
            CoopControl.ResetAllPlayers()
        end)

        originalFun(...)
    end
end

return MenuHooks