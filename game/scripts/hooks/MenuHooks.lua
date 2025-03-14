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
    local function hookUiScreen(funName)
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

    hookUiScreen("ShowWeaponUpgradeScreen")
    hookUiScreen("ShowAwardMenu")
    hookUiScreen("HandleLootPickup")
end

return MenuHooks