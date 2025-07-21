--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type HookUtils
local HookUtils = ModRequire "HookUtils.lua"
---@type HeroEx
local HeroEx = ModRequire "HeroEx.lua"
---@type CoopPlayers
local CoopPlayers = ModRequire "CoopPlayers.lua"
---@type SecondPlayerUi
local SecondPlayerUi = ModRequire "SecondPlayerUI.lua"
---@type HeroContext
local HeroContext = ModRequire "HeroContext.lua"
---@type CoopCamera
local CoopCamera = ModRequire "CoopCamera.lua"
---@type PactDoorFix
local PactDoorFix = ModRequire "hooks/PactDoorFix.lua"
---@type FreezeHooks
local FreezeHooks = ModRequire "hooks/FreezeHooks.lua"
---@type RunHooks
local RunHooks = ModRequire "hooks/RunHooks.lua"
---@type MenuHooks
local MenuHooks = ModRequire "hooks/MenuHooks.lua"
---@type SaveHooks
local SaveHooks = ModRequire "hooks/SaveHooks.lua"
---@type EnemyAiHooks
local EnemyAiHooks = ModRequire "hooks/EnemyAiHooks.lua"
---@type LootHooks
local LootHooks = ModRequire "hooks/LootHooks.lua"
---@type UIHooks
local UIHooks = ModRequire "hooks/UIHooks.lua"
---@type VulnerabilityHooks
local VulnerabilityHooks = ModRequire "hooks/VulnerabilityHooks.lua"
---@type ResourceLoadingHooks
local ResourceLoadingHooks = ModRequire "hooks/ResourceLoadingHooks.lua"
---@type ILootDelivery
local LootDelivery = ModRequire "loot/LootInterface.lua"

ModRequire "hooks/DamageHooks.lua"
ModRequire "hooks/UseHooks.lua"
ModRequire "hooks/ControlHooks.lua"
ModRequire "hooks/WeaponHooks.lua"

local hooksInited = false
local function TryInstalBasicHooks()
    if hooksInited then
        return
    end

    hooksInited = true

    -- Fixes crash on loading when the game truing add last stand to a second player
    ScreenAnchors = {}

    HeroEx.Init()
    EnemyAiHooks.InitHooks()
    SaveHooks.InitHooks()
    CoopCamera.InitHooks()
    FreezeHooks.InitHooks()
    RunHooks.InitHooks()
    MenuHooks.InitHooks()
    --PactDoorFix.InitHooks()
    UIHooks.InitHooks()
    CoopPlayers.CoopInit()
    LootHooks.InitHooks()
    VulnerabilityHooks.InitHooks()
    ResourceLoadingHooks.InitHooks()
    LootDelivery.InitHooks()
end

OnPreThingCreation
{
    TryInstalBasicHooks
}

OnAnyLoad {
    function(triggerArgs)
        local mapName = triggerArgs.name

        if mapName == "RoomPreRun" then
            HookUtils.onPostFunctionOnce("DeathAreaRoomTransition", function()
                if not HeroContext.GetDefaultHero() then
                    HeroContext.InitRunHook()
                end
                CoopPlayers.SetMainHero(HeroContext.GetDefaultHero())
                CoopPlayers.UpdateMainHero()
                CoopPlayers.InitCoopUnit(2)
                SecondPlayerUi.Refresh()
            end)
        end
    end
}

OnMenuOpened {
    "MainMenuScreen",
    function(triggerArgs)
        SetConfigOption { Name = "AllowControlHotSwap", Value = true }
    end
}
