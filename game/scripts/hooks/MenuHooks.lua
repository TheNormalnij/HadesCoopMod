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
        local currentGift, currentAssist
        for _, trait in pairs(CurrentRun.Hero.Traits) do
            if not trait.InheritFrom then
                goto continue
            end

            if trait.InheritFrom[1] == "AssistTrait" then
                currentAssist = trait.Name
            elseif trait.InheritFrom[1] == "GiftTrait" then
                currentGift = trait.Name
            end

            ::continue::
        end

        GameState.LastAwardTrait = currentGift
        GameState.LastAssistTrait = currentAssist
    end)

    HookUtils.wrap("OpenSellTraitMenu", function(base)
        local playerId = CoopPlayers.GetPlayerByHero(HeroContext.GetCurrentHeroContext()) or 1

        local backup
        if playerId > 1 then
            backup = CurrentRoom.SellOptions
            CurrentRoom.SellOptions = CurrentRoom["SellOptions" .. playerId]
        end

        base()

        if playerId > 1 then
            CurrentRoom["SellOptions" .. playerId] = CurrentRoom.SellOptions
            CurrentRoom.SellOptions = backup
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