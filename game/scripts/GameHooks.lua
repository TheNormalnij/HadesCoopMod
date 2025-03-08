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

ModRequire "hooks/DamageHooks.lua"
ModRequire "hooks/UseHooks.lua"

local _OnControlPressed = OnControlPressed
OnControlPressed = function(args)
    _OnControlPressed{
        args[1],
        function(triggerArgs)
            local hero = CoopPlayers.GetHero(triggerArgs.mPlayerIndex)
            if hero then
                HeroContext.RunWithHeroContext(hero, args[2], triggerArgs)
            end
        end
    }
end

local function InitStartRoomHooks()
    local _StartRoom = StartRoom

    function StartRoom(run, currentRoom)
        local playersCount = CoopGetPlayersCount()

        DebugPrint{Text = "StartRoom with players " .. playersCount}
        if playersCount <= 1 then
            _StartRoom(run, currentRoom)
            return
        end

        local prevRoom = GetPreviousRoom(CurrentRun)
        local roomEntranceFunctionName = currentRoom.EntranceFunctionName or "RoomEntranceStandard"
        if prevRoom ~= nil and prevRoom.NextRoomEntranceFunctionName ~= nil then
            roomEntranceFunctionName = prevRoom.NextRoomEntranceFunctionName
        end
        local args = currentRoom.EntranceFunctionArgs

        HookUtils.onPostFunctionOnce(roomEntranceFunctionName, function()
            local entranceFunction = _G[roomEntranceFunctionName]
            --entranceFunction(currentRun, currentRoom, args)
            -- TODO ADD ENTER Animation
            CoopPlayers.InitCoopUnit(2)
            --SecondPlayerUi.UpdateHealthUI()

            if currentRoom.HeroEndPoint then
                Teleport({ Id = CoopPlayers.CoopHeroes[2].ObjectId, DestinationId = currentRoom.HeroEndPoint })
            end
        end)

        _StartRoom(run, currentRoom)
    end
end

local function InitRunHooks()
    local _StartNewRun = StartNewRun
    StartNewRun = function(prevRun, args)
        local newRun = _StartNewRun(prevRun, args)
        HeroContext.InitRunHook()
        CoopPlayers.SetMainHero(HeroContext.GetDefaultHero())

        return newRun
    end
end

local function table_find(t, value)
    for key, _v in pairs(t) do
        if _v == value then
            return key;
        end
    end
end

local function InitFreezeHooks()
    local _FreezePlayerUnit = FreezePlayerUnit
    local _UnfreezePlayerUnit = UnfreezePlayerUnit

    function FreezePlayerUnit(...)
        for _, hero in pairs(CoopPlayers.CoopHeroes) do
            HeroContext.RunWithHeroContext(hero, _FreezePlayerUnit, ...)
        end
    end

    function UnfreezePlayerUnit(...)
        for _, hero in pairs(CoopPlayers.CoopHeroes) do
            HeroContext.RunWithHeroContext(hero, _UnfreezePlayerUnit, ...)
        end
    end
end

local function InitMenuHooks()
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
                local playerId = table_find(CoopPlayers.CoopHeroes, currentHero)
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


                InitFreezeHooks()
                InitStartRoomHooks()
                InitMenuHooks()
                InitRunHooks()

                SecondPlayerUi.InitHooks()
                CoopPlayers.CoopInit()
            end
        end
    end
}
