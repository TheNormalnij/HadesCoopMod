--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type TableUtils
local TableUtils = ModRequire "../TableUtils.lua"
---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"
---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"

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
end

---@private
---@param funName string
function MenuHooks.HookUiControl(funName)
    local originalFun = _G[funName]
    _G[funName] = function(...)
        local currentHero = HeroContext.GetCurrentHeroContext()
        if currentHero == CoopPlayers.GetMainHero() then
            return originalFun(...)
        else
            local prevState = ShallowCopyTable(CoopPlayers.PlayerIdToController)

            -- We need first change player 0 controller to requested plater controller
            -- So the player 1 will control the menu
            local playerId = TableUtils.find(CoopPlayers.CoopHeroes, currentHero)
            local controller = CoopPlayers.PlayerIdToController[playerId]

            for playerId, _ in pairs(CoopPlayers.PlayerIdToController) do
                if playerId == 1 then
                    CoopSetPlayerGamepad(playerId, controller)
                else
                    CoopSetPlayerGamepad(playerId, -1)
                end
            end

            HookUtils.onPreFunctionOnce("UnfreezePlayerUnit", function()
                for playerId, gamepadId in pairs(prevState) do
                    CoopSetPlayerGamepad(playerId, gamepadId)
                end
            end)

            originalFun(...)
        end
    end
end

return MenuHooks