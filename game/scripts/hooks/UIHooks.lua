--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type SecondPlayerUi
local SecondPlayerUi = ModRequire "../SecondPlayerUI.lua"
---@type TraitTrays
local TraitTrays = ModRequire "../TraitTrays.lua"
---@type PlayerVisibilityHelper
local PlayerVisibilityHelper = ModRequire "../PlayerVisibilityHelper.lua"
---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"
---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"
---@type RunEx
local RunEx = ModRequire "../RunEx.lua"

---@class UIHooks
local UIHooks = {}

---@private
---@param hero table?
function UIHooks.ShouldBeUiVisibleFor(hero)
    return hero and (RunEx.IsRunEnded() or not hero.IsDead)
end

---@private
---@param funcName string
function UIHooks.CreateSimpleHook(funcName)
    local orig = _G[funcName]
    _G[funcName] = function(...)
        local mainHero = CoopPlayers.GetMainHero()
        HeroContext.RunWithHeroContext(mainHero, orig, ...)
        local args = { ... }
        local argsCount = select("#", ...)
        SecondPlayerUi.ForEach(function(_, hero, ui)
            if hero then
                HeroContext.RunWithHeroContext(hero, ui[funcName], (table.unpack or unpack)(args, 1, argsCount))
            end
        end)
    end
end

---@private
---@param funcName string
function UIHooks.SimpleHookWithVisibilityCheck(funcName)
    local orig = _G[funcName]
    _G[funcName] = function(...)
        local mainHero = CoopPlayers.GetMainHero()
        if UIHooks.ShouldBeUiVisibleFor(mainHero) then
            HeroContext.RunWithHeroContext(mainHero, orig, ...)
        end
        local args = { ... }
        local argsCount = select("#", ...)
        SecondPlayerUi.ForEach(function(_, hero, ui)
            if UIHooks.ShouldBeUiVisibleFor(hero) then
                HeroContext.RunWithHeroContext(hero, ui[funcName], (table.unpack or unpack)(args, 1, argsCount))
            end
        end)
    end
end

---@private
function UIHooks.SimpleCurrentTraitWrapper(funcName)
    HookUtils.wrap(funcName, function(baseFun, ...)
        HeroContext.RunWithHeroContext(TraitTrays.GetScreenHero() or CoopPlayers.GetMainHero(), baseFun, ...)
    end)
end

local HealthAnchorKeys = { "HealthBack", "HealthFill", "HealthFlash", "HealthRally", "LifePipIds" }

---@private
---@return boolean
function UIHooks.IsSecondPlayerContext()
    local mainHero = CoopPlayers.GetMainHero()
    local current = HeroContext.GetCurrentHeroContext()
    return mainHero ~= nil and current ~= nil and current ~= mainHero
end

--- Runs a vanilla presentation function with ScreenAnchors health ids pointing to the P2 HUD.
--- Vanilla code always draws damage flashes / last stand pips on ScreenAnchors (P1 HUD).
--- The function is run in a separate coroutine, so anchors are restored even if it yields.
---@private
function UIHooks.RunWithSecondPlayerAnchors(fun, ...)
    local ui = SecondPlayerUi.ForHero(HeroContext.GetCurrentHeroContext())
    if not ui then
        return fun(...)
    end

    local backup = {}
    for _, key in ipairs(HealthAnchorKeys) do
        backup[key] = ScreenAnchors[key]
        ScreenAnchors[key] = ui.ScreenAnchors[key]
    end

    HeroContext.RunWithHeroContext(HeroContext.GetCurrentHeroContext(), fun, ...)

    for _, key in ipairs(HealthAnchorKeys) do
        ScreenAnchors[key] = backup[key]
    end
end

---@private
---@param funcName string
function UIHooks.RedirectAnchorsForSecondPlayer(funcName)
    if not _G[funcName] then
        return
    end
    HookUtils.wrap(funcName, function(baseFun, ...)
        if UIHooks.IsSecondPlayerContext() then
            UIHooks.RunWithSecondPlayerAnchors(baseFun, ...)
        else
            return baseFun(...)
        end
    end)
end

function UIHooks.InitHooks()
    -- Damage / heal / last stand presentation must target the HUD of the right player (#92)
    UIHooks.RedirectAnchorsForSecondPlayer("HeroDamagePresentation")
    UIHooks.RedirectAnchorsForSecondPlayer("HeroMajorDamagePresentationThread")
    UIHooks.RedirectAnchorsForSecondPlayer("DisplayPlayerHealingText")
    UIHooks.RedirectAnchorsForSecondPlayer("GainLastStandPresentation")
    UIHooks.RedirectAnchorsForSecondPlayer("LostLastStandPresentation")

    if PlayerLastStandHealingText then
        -- Yields before touching HealthFlash, so redirect only the drawing part
        PlayerLastStandHealingText = function(args)
            waitScreenTime(0.2)
            PlaySound({ Name = "/Leftovers/SFX/StaminaSkillProc", Id = CurrentRun.Hero.ObjectId })
            OnPlayerHealed({ ActualHealAmount = CurrentRun.Hero.Health })
            local flashId = ScreenAnchors.HealthFlash
            local ui = SecondPlayerUi.ForHero(HeroContext.GetCurrentHeroContext())
            if UIHooks.IsSecondPlayerContext() and ui then
                flashId = ui.ScreenAnchors.HealthFlash
            end
            if flashId ~= nil then
                CreateAnimation({ Name = "LastStandHealthBarRefillFlare", DestinationId = flashId, Group = "Combat_Menu_Additive", OffsetY = -12, OffsetX = 40 })
            end
        end
    end

    if HeroLowHealthBarPulseThread then
        -- The loop waits and reads ScreenAnchors.HealthBack (P1) every iteration,
        -- and the shared GameState flag blocks the pulse for P1. Skip it for P2.
        HookUtils.wrap("HeroLowHealthBarPulseThread", function(baseFun, ...)
            if UIHooks.IsSecondPlayerContext() then
                return
            end
            return baseFun(...)
        end)
    end

    -- Health
    HookUtils.wrap("ShowHealthUI", function(baseFun, ...)
        local healthBack = ScreenAnchors.HealthBack
        baseFun(...)
        if ScreenAnchors.HealthBack and ScreenAnchors.HealthBack ~= healthBack then
            PlayerVisibilityHelper.AddHealthBarLabel(1, ScreenAnchors.HealthBack, 25)
        end
    end)
    UIHooks.SimpleHookWithVisibilityCheck("ShowHealthUI")

    UIHooks.CreateSimpleHook("UpdateHealthUI")
    HookUtils.onPostFunction("DestroyHealthUI", SecondPlayerUi.DestroyHealthUI)
    HookUtils.onPreFunction("HideHealthUI", function()
        thread(SecondPlayerUi.HideHealthUI)
    end)
    HookUtils.onPostFunction("UpdateRallyHealthUI", SecondPlayerUi.UpdateRallyHealthUI)

    -- LifePipIds
    UIHooks.CreateSimpleHook("RecreateLifePips")

    HookUtils.wrap("UpdateLifePips", function(basefun, unit)
        local mainHero = CoopPlayers.GetMainHero()
        if not mainHero or not unit or mainHero == unit then
            basefun(mainHero)
        end
        SecondPlayerUi.UpdateLifePips()
    end)

    local _AddLastStand = AddLastStand
    AddLastStand = function(args)
        local targetHero = args.Unit or HeroContext.GetCurrentHeroContext()
        local mainHero = CoopPlayers.GetMainHero()
        -- Fresh P2 heroes are not registered in CoopHeroes yet, so compare with the main hero
        local isSecondPlayer = mainHero ~= nil and targetHero ~= nil and targetHero ~= mainHero
        local pipsBackup = ScreenAnchors.LifePipIds
        local _CreateScreenObstacle = CreateScreenObstacle
        -- nil for fresh heroes: their pips are rebuilt by RecreateLifePips on refresh
        local ui = isSecondPlayer and SecondPlayerUi.ForHero(targetHero) or nil
        local throwawayPips = nil
        if isSecondPlayer then
            if ui then
                ui.ScreenAnchors.LifePipIds = ui.ScreenAnchors.LifePipIds or {}
                ScreenAnchors.LifePipIds = ui.ScreenAnchors.LifePipIds
            else
                throwawayPips = {}
                ScreenAnchors.LifePipIds = throwawayPips
            end
            local offsetX = ui and ui.OffsetX or 0
            local offsetY = ui and ui.OffsetY or 0
            -- Mirror the pip to the right side of the screen.
            -- Must call the original and return the obstacle id, otherwise P2 pips are never created
            CreateScreenObstacle = function(obstacleArgs)
                obstacleArgs.X = (ScreenWidth - 80) - (obstacleArgs.X - 70) + offsetX
                if obstacleArgs.Y then
                    obstacleArgs.Y = obstacleArgs.Y + offsetY
                end
                return _CreateScreenObstacle(obstacleArgs)
            end
        end

        local ok, err = pcall(_AddLastStand, args)

        if isSecondPlayer then
            ScreenAnchors.LifePipIds = pipsBackup
            CreateScreenObstacle = _CreateScreenObstacle
            if throwawayPips and not IsEmpty(throwawayPips) then
                Destroy({ Ids = throwawayPips })
            end
        end

        if not ok then
            error(err, 0)
        end
    end

    -- Ammo (red crystrals)
    UIHooks.SimpleHookWithVisibilityCheck("ShowAmmoUI")
    HookUtils.onPreFunction("HideAmmoUI", function() thread(SecondPlayerUi.HideAmmoUI) end)
    HookUtils.onPreFunction("DestroyAmmoUI", SecondPlayerUi.DestroyAmmoUI)

    HookUtils.wrap("StartAmmoReloadPresentation", function(baseFun, delay)
        local ui = SecondPlayerUi.ForHero(HeroContext.GetCurrentHeroContext())
        if ui then
            ui.StartAmmoReloadPresentation(delay)
        else
            baseFun(delay)
        end
    end)

    HookUtils.wrap("EndAmmoReloadPresentation", function(baseFun)
        local ui = SecondPlayerUi.ForHero(HeroContext.GetCurrentHeroContext())
        if ui then
            ui.EndAmmoReloadPresentation()
        else
            baseFun()
        end
    end)

    local _UpdateAmmoUI = UpdateAmmoUI
    UpdateAmmoUI = function()
        local mainHero = CoopPlayers.GetMainHero()
        if HeroContext.IsHeroContextExplicit() then
            local ui = SecondPlayerUi.ForHero(HeroContext.GetCurrentHeroContext())
            if ui then
                ui.UpdateAmmoUI()
            else
                _UpdateAmmoUI()
            end
        else
            HeroContext.RunWithHeroContext(mainHero, _UpdateAmmoUI)
            SecondPlayerUi.UpdateAmmoUI()
        end
    end

    HookUtils.wrap("AddAmmoPresentation", function(baseFun, ...)
        local ui = SecondPlayerUi.ForHero(CurrentRun.Hero)
        if ui then
            thread(ui.UpdateAmmoUI)

            CreateAnimation({ Name = "QuickFlashRedSmall", DestinationId = CurrentRun.Hero.ObjectId, OffsetZ = -90 })

            if ui.ScreenAnchors.AmmoIndicatorUI ~= nil then
                ModifyTextBox({ Id = ui.ScreenAnchors.AmmoIndicatorUI, ColorTarget = Color.White, ColorDuration = 0.5, AutoSetDataProperties = false, })
                thread(PulseText,
                    { ScreenAnchorReference = "AmmoIndicatorUI", ScaleTarget = 1.3, ScaleDuration = 0.125, HoldDuration = 0.1, PulseBias = 0.2 })
            end
        else
            baseFun(...);
        end
    end)

    -- Gun
    UIHooks.SimpleHookWithVisibilityCheck("ShowGunUI")

    local _HideGunUI = HideGunUI
    HideGunUI = function()
        local mainHero = CoopPlayers.GetMainHero()
        HeroContext.RunWithHeroContext(mainHero, _HideGunUI)
        SecondPlayerUi.ForEach(function(_, hero, ui)
            if hero then
                HeroContext.RunWithHeroContext(hero, ui.HideGunUI)
            end
        end)
    end

    local _UpdateGunUI = UpdateGunUI
    UpdateGunUI = function()
        local mainHero = CoopPlayers.GetMainHero()

        if HeroContext.IsHeroContextExplicit() then
            local currentHero = HeroContext.GetCurrentHeroContext()
            local ui = SecondPlayerUi.ForHero(currentHero)
            if mainHero == currentHero then
                HeroContext.RunWithHeroContext(mainHero, _UpdateGunUI)
            elseif ui then
                HeroContext.RunWithHeroContext(currentHero, ui.UpdateGunUI)
            end
        else
            HeroContext.RunWithHeroContext(mainHero, _UpdateGunUI)
            SecondPlayerUi.ForEach(function(_, hero, ui)
                if hero then
                    HeroContext.RunWithHeroContext(hero, ui.UpdateGunUI)
                end
            end)
        end
    end

    EquipPlayerWeaponPresentation = function(weaponData, args)
        wait(0.02)
        -- TODO: Fix hero here, maybe
        PlaySound({ Name = "/SFX/Menu Sounds/WeaponEquipChunk", Id = CurrentRun.Hero.ObjectId })
        if not args.SkipEquipLines then
            thread(PlayVoiceLines, weaponData.EquipVoiceLines, false)
        end

        local function hasHeroWeaponWithIcon(hero)
            for weaponName in pairs(hero.Weapons) do
                if WeaponData[weaponName].ActiveReloadTime then
                    return true
                end
            end
            return false
        end

        local hero = CoopPlayers.GetMainHero()
        local execFun = hasHeroWeaponWithIcon(hero) and ShowGunUI or _HideGunUI
        thread(function()
            HeroContext.RunWithHeroContext(hero, execFun)
        end)

        SecondPlayerUi.ForEach(function(_, otherHero, ui)
            if otherHero then
                local otherFun = hasHeroWeaponWithIcon(otherHero) and ui.ShowGunUI or ui.HideGunUI
                thread(function()
                    HeroContext.RunWithHeroContext(otherHero, otherFun)
                end)
            end
        end)
    end

    HookUtils.onPostFunction("DestroyGunUI", SecondPlayerUi.DestroyGunUI)

    -- Super meter (God aid)
    UIHooks.SimpleHookWithVisibilityCheck("ShowSuperMeter")
    UIHooks.SimpleHookWithVisibilityCheck("UpdateSuperMeterUIReal")
    UIHooks.CreateSimpleHook("DestroySuperMeter")
    UIHooks.CreateSimpleHook("HideSuperMeter")

    local _UpdateSuperUIComponent = UpdateSuperUIComponent
    UpdateSuperUIComponent = function(...)
        local mainHero = CoopPlayers.GetMainHero()
        if ScreenAnchors.SuperPipBackingIds then
            HeroContext.RunWithHeroContext(mainHero, _UpdateSuperUIComponent, ...)
        end
        local args = { ... }
        local argsCount = select("#", ...)
        SecondPlayerUi.ForEach(function(_, hero, ui)
            if hero and ui.ScreenAnchors.SuperPipBackingIds then
                HeroContext.RunWithHeroContext(hero, ui.UpdateSuperUIComponent, (table.unpack or unpack)(args, 1, argsCount))
            end
        end)
    end

    -- Traits: per player trays are handled in TraitTrays.lua
    UIHooks.SimpleCurrentTraitWrapper("CloseAdvancedTooltipScreen")
    UIHooks.SimpleCurrentTraitWrapper("PinTraitDetails")

    -- Etc
    local _PulseText = PulseText
    PulseText = function(args)
        local ui = args.ScreenAnchorReference and SecondPlayerUi.ForHero(HeroContext.GetCurrentHeroContext())
        if ui then
            local idOnSecond = ui.ScreenAnchors[args.ScreenAnchorReference]
            if idOnSecond then
                args.Id = idOnSecond
            end
        end

        _PulseText(args)
    end

    HookUtils.onPostFunction("ShowUseButton", function(objectId, useTarget)
        if HeroContext.GetDefaultHero() ~= HeroContext.GetCurrentHeroContext() then
            Move({ Id = ScreenAnchors.UsePrompts[objectId], DestinationId = ScreenAnchors.UsePrompts[objectId], OffsetY = -50 })
        end
    end)
end

return UIHooks