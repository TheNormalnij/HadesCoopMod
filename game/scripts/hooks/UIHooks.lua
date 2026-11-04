--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type SecondPlayerUi
local SecondPlayerUi = ModRequire "../SecondPlayerUI.lua"
---@type CombinedTraitsUI
local CombinedTraitsUI = ModRequire "../CombinedTraitsUI.lua"
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
        local secondHero = CoopPlayers.GetHero(2)
        HeroContext.RunWithHeroContext(mainHero, orig, ...)
        if secondHero then
            HeroContext.RunWithHeroContext(secondHero, SecondPlayerUi[funcName], ...)
        end
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
        local secondHero = CoopPlayers.GetHero(2)
        if UIHooks.ShouldBeUiVisibleFor(secondHero) then
            HeroContext.RunWithHeroContext(secondHero, SecondPlayerUi[funcName], ...)
        end
    end
end

---@private
function UIHooks.SimpleCurrentTraitWrapper(funcName)
    HookUtils.wrap(funcName, function(baseFun, ...)
        HeroContext.RunWithHeroContext(CombinedTraitsUI.GetCurrentTraitHero(), baseFun, ...)
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
    local backup = {}
    for _, key in ipairs(HealthAnchorKeys) do
        backup[key] = ScreenAnchors[key]
        ScreenAnchors[key] = SecondPlayerUi.ScreenAnchors[key]
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
            if UIHooks.IsSecondPlayerContext() then
                flashId = SecondPlayerUi.ScreenAnchors.HealthFlash
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
        if isSecondPlayer then
            ScreenAnchors.LifePipIds = SecondPlayerUi.ScreenAnchors.LifePipIds
            -- Mirror the pip to the right side of the screen.
            -- Must call the original and return the obstacle id, otherwise P2 pips are never created
            CreateScreenObstacle = function(obstacleArgs)
                obstacleArgs.X = (ScreenWidth - 80) - (obstacleArgs.X - 70)
                return _CreateScreenObstacle(obstacleArgs)
            end
        end

        _AddLastStand(args)

        if isSecondPlayer then
            ScreenAnchors.LifePipIds = pipsBackup
            CreateScreenObstacle = _CreateScreenObstacle
        end
    end

    -- Ammo (red crystrals)
    UIHooks.SimpleHookWithVisibilityCheck("ShowAmmoUI")
    HookUtils.onPreFunction("HideAmmoUI", function() thread(SecondPlayerUi.HideAmmoUI) end)
    HookUtils.onPreFunction("DestroyAmmoUI", SecondPlayerUi.DestroyAmmoUI)

    HookUtils.wrap("StartAmmoReloadPresentation", function(baseFun, delay)
        if CoopPlayers.GetMainHero() == HeroContext.GetCurrentHeroContext() then
            baseFun(delay)
        else
            SecondPlayerUi.StartAmmoReloadPresentation(delay)
        end
    end)

    HookUtils.wrap("EndAmmoReloadPresentation", function(baseFun)
        if CoopPlayers.GetMainHero() == HeroContext.GetCurrentHeroContext() then
            baseFun()
        else
            SecondPlayerUi.EndAmmoReloadPresentation()
        end
    end)

    local _UpdateAmmoUI = UpdateAmmoUI
    UpdateAmmoUI = function()
        local mainHero = CoopPlayers.GetMainHero()
        if HeroContext.IsHeroContextExplicit() then
            if HeroContext.GetCurrentHeroContext() == mainHero then
                _UpdateAmmoUI()
            else
                SecondPlayerUi.UpdateAmmoUI()
            end
        else
            HeroContext.RunWithHeroContext(mainHero, function()
                _UpdateAmmoUI()
                SecondPlayerUi.UpdateAmmoUI()
            end)
        end
    end

    HookUtils.wrap("AddAmmoPresentation", function(baseFun, ...)
        if CurrentRun.Hero == CoopPlayers.GetHero(2) then
            thread(SecondPlayerUi.UpdateAmmoUI)

            CreateAnimation({ Name = "QuickFlashRedSmall", DestinationId = CurrentRun.Hero.ObjectId, OffsetZ = -90 })

            if SecondPlayerUi.ScreenAnchors.AmmoIndicatorUI ~= nil then
                ModifyTextBox({ Id = SecondPlayerUi.ScreenAnchors.AmmoIndicatorUI, ColorTarget = Color.White, ColorDuration = 0.5, AutoSetDataProperties = false, })
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
        local secondHero = CoopPlayers.GetHero(2)
        if secondHero then
            HeroContext.RunWithHeroContext(secondHero, SecondPlayerUi.HideGunUI)
        end
    end

    local _UpdateGunUI = UpdateGunUI
    UpdateGunUI = function()
        local mainHero = CoopPlayers.GetMainHero()
        local secondHero = CoopPlayers.GetHero(2)

        if HeroContext.IsHeroContextExplicit() then
            local currentHero = HeroContext.GetCurrentHeroContext()
            if mainHero == currentHero then
                HeroContext.RunWithHeroContext(mainHero, _UpdateGunUI)
            elseif currentHero == secondHero then
                HeroContext.RunWithHeroContext(currentHero, SecondPlayerUi.UpdateGunUI)
            end
        else
            HeroContext.RunWithHeroContext(mainHero, _UpdateGunUI)
            if secondHero then
                HeroContext.RunWithHeroContext(secondHero, SecondPlayerUi.UpdateGunUI)
            end
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

        hero = CoopPlayers.GetHero(2)
        if hero then
            execFun = hasHeroWeaponWithIcon(hero) and SecondPlayerUi.ShowGunUI or SecondPlayerUi.HideGunUI
            thread(function()
                HeroContext.RunWithHeroContext(hero, execFun)
            end)
        end
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
        local secondHero = CoopPlayers.GetHero(2)
        if ScreenAnchors.SuperPipBackingIds then
            HeroContext.RunWithHeroContext(mainHero, _UpdateSuperUIComponent, ...)
        end
        if secondHero and SecondPlayerUi.ScreenAnchors.SuperPipBackingIds then
            HeroContext.RunWithHeroContext(secondHero, SecondPlayerUi.UpdateSuperUIComponent, ...)
        end
    end

    -- Traits
    HookUtils.onPreFunction("ShowAdvancedTooltip", CombinedTraitsUI.ChangeHeroInTraitsMenu)
    HookUtils.onPreFunction("TraitUIActivateTrait", CombinedTraitsUI.ChangeHeroInTraitsMenu)
    HookUtils.onPreFunction("TraitUIDeactivateTrait", CombinedTraitsUI.ChangeHeroInTraitsMenu)
    HookUtils.onPreFunction("TraitUICreateComponent", CombinedTraitsUI.ChangeHeroInTraitsMenu)
    HookUtils.onPreFunction("TraitUIUpdateText", CombinedTraitsUI.ChangeHeroInTraitsMenu)
    HookUtils.onPreFunction("TraitUIRemove", CombinedTraitsUI.ChangeHeroInTraitsMenu)
    HookUtils.onPreFunction("TraitUICreateText", CombinedTraitsUI.ChangeHeroInTraitsMenu)
    HookUtils.onPreFunction("UpdateTraitNumber", CombinedTraitsUI.ChangeHeroInTraitsMenu)
    HookUtils.onPreFunction("UpdateAdditionalTraitHint", CombinedTraitsUI.ChangeHeroInTraitsMenu)
    HookUtils.onPreFunction("TraitUIActivateTraits", CombinedTraitsUI.ChangeHeroInTraitsMenu)

    UIHooks.SimpleCurrentTraitWrapper("CloseAdvancedTooltipScreen")
    UIHooks.SimpleCurrentTraitWrapper("PinTraitDetails")

    -- Etc
    local _PulseText = PulseText
    PulseText = function(args)
        if args.ScreenAnchorReference and HeroContext.GetCurrentHeroContext() == CoopPlayers.GetHero(2) then
            local idOnSecond = SecondPlayerUi.ScreenAnchors[args.ScreenAnchorReference]
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