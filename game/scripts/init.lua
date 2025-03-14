--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type HookUtils
local HookUtils = ModRequire "HookUtils.lua"
---@type CoopPlayers
local CoopPlayers = ModRequire "CoopPlayers.lua"
---@type SecondPlayerUi
local SecondPlayerUi = ModRequire "SecondPlayerUI.lua"
---@type HeroContext
local HeroContext = ModRequire "HeroContext.lua"
---@type PactDoorFix
local PactDoorFix = ModRequire "hooks/PactDoorFix.lua"
---@type FreezeHooks
local FreezeHooks = ModRequire "hooks/FreezeHooks.lua"
---@type RunHooks
local RunHooks = ModRequire "hooks/RunHooks.lua"
---@type MenuHooks
local MenuHooks = ModRequire "hooks/MenuHooks.lua"

ModRequire "hooks/DamageHooks.lua"
ModRequire "hooks/UseHooks.lua"
ModRequire "hooks/ControlHooks.lua"

local hooksInited = false
OnAnyLoad {
    function(triggerArgs)
        local mapName = triggerArgs.name

        if mapName == "RoomPreRun" then
            if not hooksInited then
                hooksInited = true

                HookUtils.onPostFunctionOnce("DeathAreaRoomTransition", function()
                    HeroContext.InitRunHook()
                    CoopPlayers.SetMainHero(HeroContext.GetDefaultHero())
                    CoopPlayers.UpdateMainHero()
                    CoopPlayers.InitCoopUnit(2)
                    SecondPlayerUi.UpdateHealthUI()
                    SecondPlayerUi.RecreateLifePips()
                    UpdateHealthUI()
                end)

                FreezeHooks.InitHooks()
                RunHooks.InitHooks()
                MenuHooks.InitHooks()
                --PactDoorFix.InitHooks()
                SecondPlayerUi.InitHooks()
                CoopPlayers.CoopInit()
            end
        end
    end
}
