
---@type CoopPlayers
local CoopPlayers = ModRequire "CoopPlayers.lua"

---@type HookUtils
local HookUtils = ModRequire "HookUtils.lua"

---@type HeroContext
local HeroContext = ModRequire "HeroContext.lua"

---@class SecondPlayerUi
local SecondPlayerUi = {}

local ScreenAnchorsSecondPlayer = {}

function SecondPlayerUi.ShowHealthUI()
    if not ConfigOptionCache.ShowUIAnimations then
        return
    end

    if ScreenAnchorsSecondPlayer.HealthBack ~= nil then
        return
    end

    local poxX = ScreenWidth - 500

    if ScreenAnchorsSecondPlayer.Shadow == nil then
        ScreenAnchorsSecondPlayer.Shadow = CreateScreenObstacle({
            Name = "BlankObstacle",
            Group = "Combat_UI_Backing",
            X = ScreenWidth,
            Y = ScreenHeight
        })
        SetAnimation({ Name = "BarShadow", DestinationId = ScreenAnchorsSecondPlayer.Shadow })
        SetScaleX({ Ids = { ScreenAnchorsSecondPlayer.Shadow }, Fraction = -1 })
    end

    ScreenAnchorsSecondPlayer.HealthBack = CreateScreenObstacle({
        Name = "BlankObstacle",
        Group = "Combat_UI",
        X = poxX - (10 - CombatUI.FadeDistance.Health),
        --X = ScreenWidth - 266,
        Y = ScreenHeight - 50
    })

    ScreenAnchorsSecondPlayer.HealthRally = CreateScreenObstacle({
        Name = "BlankObstacle",
        Group = "Combat_UI",
        X = poxX - (10 - CombatUI.FadeDistance.Health),
        Y = ScreenHeight - 50
    })

    ScreenAnchorsSecondPlayer.HealthFill = CreateScreenObstacle({
        Name = "BlankObstacle",
        Group = "Combat_UI",
        X = poxX - (10 - CombatUI.FadeDistance.Health),
        Y = ScreenHeight - 50
    })

    ScreenAnchorsSecondPlayer.HealthFlash = CreateScreenObstacle({
        Name = "BlankObstacle",
        Group = "Combat_UI",
        X = poxX - (10 - CombatUI.FadeDistance.Health),
        Y = ScreenHeight - 50
    })

    ScreenAnchorsSecondPlayer.StoredAmmo = ScreenAnchorsSecondPlayer.StoredAmmo or {}
    ScreenAnchorsSecondPlayer.SelfStoredAmmo = ScreenAnchorsSecondPlayer.SelfStoredAmmo or {}

    SecondPlayerUi.RecreateLifePips()

    CreateTextBox(MergeTables({
        Id = ScreenAnchorsSecondPlayer.HealthBack,
        OffsetX = -90,
        OffsetY = -13,
        Font = "AlegreyaSansSCBold",
        FontSize = 24,
        ShadowRed = 0.1,
        ShadowBlue = 0.1,
        ShadowGreen = 0.1,
        OutlineColor = { 0.113, 0.113, 0.113, 1 },
        OutlineThickness = 1,
        ShadowAlpha = 1.0,
        ShadowBlur = 0,
        ShadowOffsetY = 2,
        ShadowOffsetX = 0,
        Justification = "Left",
    }, LocalizationData.UIScripts.HealthUI))

    SetAnimation({ Name = "HealthBar", DestinationId = ScreenAnchorsSecondPlayer.HealthBack })

    local frameTarget = 1 - (CurrentRun.Hero.Health / CurrentRun.Hero.MaxHealth)
    SetAnimation({ Name = "HealthBarFill", DestinationId = ScreenAnchorsSecondPlayer.HealthFill, FrameTarget = frameTarget, Instant = true, Color =
    Color.Black })
    SetAnimation({ Name = "HealthBarFillWhite", DestinationId = ScreenAnchorsSecondPlayer.HealthRally, FrameTarget = frameTarget, Instant = true, Color =
    Color.RallyHealth })

    if CurrentRun.CurrentRoom.LoadedAmmo then
        for i = 1, CurrentRun.CurrentRoom.LoadedAmmo do
            local offsetX = 600 + 380 -- Some random shit
            local offsetY = -50
            offsetX = offsetX + (#ScreenAnchorsSecondPlayer.SelfStoredAmmo * 22)
            local screenId = CreateScreenObstacle({ Name = "BlankObstacle", Group = "Combat_UI", DestinationId =
            ScreenAnchorsSecondPlayer.HealthBack, X = 10 + offsetX, Y = ScreenHeight - 50 + offsetY })
            SetThingProperty({ Property = "SortMode", Value = "Id", DestinationId = screenId })
            table.insert(ScreenAnchorsSecondPlayer.SelfStoredAmmo, screenId)
            SetAnimation({ Name = "AmmoEmbeddedInEnemyIcon", DestinationId = screenId })
        end
    end

    FadeObstacleIn({ Id = ScreenAnchorsSecondPlayer.HealthBack, Duration = CombatUI.FadeInDuration, IncludeText = true, Distance =
    CombatUI.FadeDistance.Health, Direction = 0 })
    FadeObstacleIn({ Id = ScreenAnchorsSecondPlayer.HealthRally, Duration = CombatUI.FadeInDuration, IncludeText = false, Distance =
    CombatUI.FadeDistance.Health, Direction = 0 })
    FadeObstacleIn({ Id = ScreenAnchorsSecondPlayer.HealthFill, Duration = CombatUI.FadeInDuration, IncludeText = false, Distance =
    CombatUI.FadeDistance.Health, Direction = 0 })
    FadeObstacleIn({ Id = ScreenAnchorsSecondPlayer.HealthFlash, Duration = CombatUI.FadeInDuration, IncludeText = false, Distance =
    CombatUI.FadeDistance.Health, Direction = 0 })
    if ScreenAnchorsSecondPlayer.BadgeId ~= nil then
        FadeObstacleIn({ Id = ScreenAnchorsSecondPlayer.BadgeId, Duration = CombatUI.FadeInDuration, IncludeText = false, Distance =
        CombatUI.FadeDistance.Health, Direction = 0 })
    end
end

function SecondPlayerUi.UpdateHealthUI()
    local unit = CoopPlayers.GetHero(2)
    if unit == nil then return; end

    local currentHealth = unit.Health
    local maxHealth = unit.MaxHealth

    if currentHealth == nil or maxHealth == nil then
        return
    end

    local rallyHealth = unit.RallyHealth.Store
    if ScreenAnchorsSecondPlayer.HealthBack ~= nil then
        ModifyTextBox({ Id = ScreenAnchorsSecondPlayer.HealthBack, Text = "UI_PlayerHealth", LuaKey = "TempTextData", LuaValue = { Current = math.ceil(currentHealth), Maximum = math.ceil(maxHealth) }, AutoSetDataProperties = false })
    end

    if ScreenAnchorsSecondPlayer.HealthFill ~= nil then
        SetAnimationFrameTarget({ Name = "HealthBarFill", Fraction = 1 - (currentHealth) / maxHealth, DestinationId =
        ScreenAnchorsSecondPlayer.HealthFill })
    end
    SetAnimationFrameTarget({ Name = "HealthBarFillWhite", Fraction = 1 - (currentHealth + rallyHealth) / maxHealth, DestinationId =
    ScreenAnchorsSecondPlayer.HealthRally })
    unit.RallyHealth.Cache =
    {
        CurrentHealth = currentHealth,
        MaxHealth = maxHealth
    }
end

function SecondPlayerUi.UpdateRallyHealthUI()
    local unit = CoopPlayers.GetHero(2)
    if unit == nil then return; end

    local rallyHealth = unit.RallyHealth.Store
    local currentHealth = unit.Health
    local maxHealth = unit.MaxHealth
    if unit.RallyHealth.Cache ~= nil then
        currentHealth = unit.RallyHealth.Cache.CurrentHealth
        maxHealth = unit.RallyHealth.Cache.MaxHealth
    end

    SetAnimationFrameTarget({
        Name = "HealthBarFillWhite",
        Fraction = 1 - (currentHealth + rallyHealth) / maxHealth,
        DestinationId = ScreenAnchorsSecondPlayer.HealthRally
    })
end

function SecondPlayerUi.HideHealthUI()
    if ScreenAnchorsSecondPlayer.HealthBack == nil then
        return
    end
    local healthIds = { "HealthBack", "HealthFill", "HealthFlash", "HealthRally", "BadgeId" }
    local healthAnchorIds = {}
    for i, id in pairs(healthIds) do
        table.insert(healthAnchorIds, ScreenAnchorsSecondPlayer[id])
    end
    for i, id in pairs(ScreenAnchorsSecondPlayer.LifePipIds) do
        table.insert(healthAnchorIds, id)
    end

    for i, id in pairs(ScreenAnchorsSecondPlayer.SelfStoredAmmo) do
        table.insert(healthAnchorIds, id)
    end

    ScreenAnchorsSecondPlayer.HealthBack = nil
    ScreenAnchorsSecondPlayer.HealthFill = nil
    ScreenAnchorsSecondPlayer.HealthFlash = nil
    ScreenAnchorsSecondPlayer.HealthRally = nil
    ScreenAnchorsSecondPlayer.LifePipIds = nil
    ScreenAnchorsSecondPlayer.SelfStoredAmmo = nil
    ScreenAnchorsSecondPlayer.BadgeId = nil

    HideObstacle({ Ids = healthAnchorIds, IncludeText = true, FadeTarget = 0, Duration = CombatUI.FadeDuration, Angle = 180, Distance =
    CombatUI.FadeDistance.Health })

    wait(CombatUI.FadeDuration, RoomThreadName)

    Destroy({ Ids = healthAnchorIds })
end

function SecondPlayerUi.DestroyHealthUI()
    local ids = CombineTables({
        ScreenAnchorsSecondPlayer.HealthBack,
        ScreenAnchorsSecondPlayer.HealthFill,
        ScreenAnchorsSecondPlayer.HealthFlash 
        },
        ScreenAnchorsSecondPlayer.LifePipIds
        )

    if not IsEmpty(ids) then
        Destroy({ Ids = ids })
    end
    ScreenAnchorsSecondPlayer.HealthBack = nil
    ScreenAnchorsSecondPlayer.HealthFill = nil
    ScreenAnchorsSecondPlayer.HealthFlash = nil
    ScreenAnchorsSecondPlayer.HealthRally = nil
    ScreenAnchorsSecondPlayer.LifePipIds = nil
    ScreenAnchorsSecondPlayer.BadgeId = nil
end

function SecondPlayerUi.UpdateLifePips()
    local unit = CoopPlayers.GetHero(2)
    if not unit or not ScreenAnchorsSecondPlayer.LifePipIds or not unit.LastStands then
        return
    end

    for i, lifePipId in pairs(ScreenAnchorsSecondPlayer.LifePipIds) do
        local lastStandData = unit.LastStands[i]
        if lastStandData then
            SetAnimation({ Name = lastStandData.Icon, DestinationId = ScreenAnchorsSecondPlayer.LifePipIds[i] })
        else
            if unit.IsDead then
                if IsMetaUpgradeActive("ExtraChanceReplenishMetaUpgrade") then
                    SetAnimation({ Name = "ExtraLifeReplenish", DestinationId = ScreenAnchorsSecondPlayer.LifePipIds[i] })
                else
                    SetAnimation({ Name = "ExtraLifeZag", DestinationId = ScreenAnchorsSecondPlayer.LifePipIds[i] })
                end
            else
                SetAnimation({ Name = "ExtraLifeEmpty", DestinationId = ScreenAnchorsSecondPlayer.LifePipIds[i] })
            end
        end
    end
end

function SecondPlayerUi.RecreateLifePips()
    ScreenAnchorsSecondPlayer.LifePipIds = {}

    local unit = CoopPlayers.GetHero(2)
    if unit == nil then return; end

    local numLastStands = 0
    if unit.IsDead then
        numLastStands = TableLength(unit.LastStands) + GetNumMetaUpgradeLastStands()
    elseif unit.MaxLastStands then
        numLastStands = unit.MaxLastStands
    end

    local poxX = ScreenWidth - 80
    for i = 1, numLastStands do
        local obstacleId = CreateScreenObstacle({ Name = "BlankObstacle", Group = "Combat_UI", X = poxX - i * 32, Y =
        ScreenHeight - 95 })
        SetAnimation({ Name = "ExtraLifeEmpty", DestinationId = obstacleId })
        table.insert(ScreenAnchorsSecondPlayer.LifePipIds, obstacleId)
    end
    SecondPlayerUi.UpdateLifePips()
end

-- Ammo
function SecondPlayerUi.ShowAmmoUI()
    if ScreenAnchorsSecondPlayer.AmmoIndicatorUI ~= nil then
        return
    end
    local poxX = ScreenWidth - 512 - 150
    ScreenAnchorsSecondPlayer.AmmoIndicatorUI = CreateScreenObstacle({ Name = "BlankObstacle", Group = "Combat_UI", X = poxX, Y =
    ScreenHeight - 62 })
    SetAnimation({ Name = "AmmoIndicatorIcon", DestinationId = ScreenAnchorsSecondPlayer.AmmoIndicatorUI })
    CreateTextBox(MergeTables({
        Id = ScreenAnchorsSecondPlayer.AmmoIndicatorUI,
        OffsetX = 24,
        OffsetY = -2,
        Font = "AlegreyaSansSCBold",
        FontSize = 24,
        ShadowRed = 0.1,
        ShadowBlue = 0.1,
        ShadowGreen = 0.1,
        OutlineColor = { 0.113, 0.113, 0.113, 1 },
        OutlineThickness = 1,
        ShadowAlpha = 1.0,
        ShadowBlur = 0,
        ShadowOffsetY = 2,
        ShadowOffsetX = 0,
        Justification = "Left",
    }, LocalizationData.UIScripts.AmmoUI))
    thread(SecondPlayerUi.UpdateAmmoUI)

    FadeObstacleIn({ Id = ScreenAnchorsSecondPlayer.AmmoIndicatorUI, Duration = CombatUI.FadeInDuration, IncludeText = true, Distance =
    CombatUI.FadeDistance.Ammo, Direction = 0 })
end

function SecondPlayerUi.UpdateAmmoUI()
    local hero = CoopPlayers.GetHero(2)

    if ScreenAnchorsSecondPlayer.AmmoIndicatorUI == nil or not hero then
        return
    end
    local ammoData =
    {
        Current = GetWeaponProperty({ Id = hero.ObjectId, WeaponName = "RangedWeapon", Property = "Ammo" }),
        Maximum = GetWeaponMaxAmmo({ Id = hero.ObjectId, WeaponName = "RangedWeapon" })
    }
    PulseText({ Id = ScreenAnchorsSecondPlayer.AmmoIndicatorUI, ScaleTarget = 1.04, ScaleDuration = 0.05, HoldDuration = 0.05, PulseBias = 0.02 })
    ModifyTextBox({ Id = ScreenAnchorsSecondPlayer.AmmoIndicatorUI, Text = "UI_AmmoText", OffsetY = -2, LuaKey = "TempTextData", LuaValue =
    ammoData, AutoSetDataProperties = false, })
end

function SecondPlayerUi.HideAmmoUI()
    if ScreenAnchorsSecondPlayer.AmmoIndicatorUI == nil then
        return
    end
    ScreenAnchorsSecondPlayer.AmmoIndicatorUIReloads = ScreenAnchorsSecondPlayer.AmmoIndicatorUIReloads or {}

    local ids = CombineTables({ ScreenAnchorsSecondPlayer.AmmoIndicatorUI }, ScreenAnchorsSecondPlayer.AmmoIndicatorUIReloads)

    for i, reloadId in pairs(ids) do
        HideObstacle({ Id = reloadId, IncludeText = true, Distance = CombatUI.FadeDistance.Ammo, Angle = 180, Duration =
        CombatUI.FadeDuration, SmoothStep = true })
    end
    ScreenAnchorsSecondPlayer.AmmoIndicatorUI = nil
    ScreenAnchorsSecondPlayer.AmmoIndicatorUIReloads = nil

    wait(CombatUI.FadeDuration, RoomThreadName)

    Destroy({ Ids = ids })
end

function SecondPlayerUi.DestroyAmmoUI()
    if ScreenAnchorsSecondPlayer.AmmoIndicatorUI == nil then
        return
    end
    Destroy({ Id = ScreenAnchorsSecondPlayer.AmmoIndicatorUI })
    Destroy({ Ids = ScreenAnchorsSecondPlayer.AmmoIndicatorUIReloads })
    ScreenAnchorsSecondPlayer.AmmoIndicatorUI = nil
end

-- Gun

function SecondPlayerUi.ShowGunUI(gunData)
    if not CurrentRun.Hero.Weapons.GunWeapon then
        return
    end
    if ScreenAnchorsSecondPlayer.GunUI ~= nil then
        return
    end

    if ScreenAnchorsSecondPlayer.Shadow ~= nil then
        SetScaleX({ Id = ScreenAnchorsSecondPlayer.Shadow, Fraction = -1.3 })
    end

    ScreenAnchorsSecondPlayer.GunUI = CreateScreenObstacle({
        Name = "BlankObstacle",
        Group = "Combat_UI",
        X = ScreenWidth - GunUI.StartX - 64 - 100,
        Y = GunUI
            .StartY
    })


    if HeroHasTrait("GunLoadedGrenadeTrait") then
        SetAnimation({ Name = "GunLaserIndicatorIcon", DestinationId = ScreenAnchorsSecondPlayer.GunUI })
    else
        SetAnimation({ Name = "GunAmmoIndicatorIcon", DestinationId = ScreenAnchorsSecondPlayer.GunUI })
    end

    local offsetX = 20
    CreateTextBox(MergeTables({
            Id = ScreenAnchorsSecondPlayer.GunUI,
            OffsetX = offsetX,
            OffsetY = -2,
            Font = "AlegreyaSansSCBold",
            FontSize = 24,
            ShadowRed = 0.1,
            ShadowBlue = 0.1,
            ShadowGreen = 0.1,
            OutlineColor = { 0.113, 0.113, 0.113, 1 },
            OutlineThickness = 1,
            ShadowAlpha = 1.0,
            ShadowBlur = 0,
            ShadowOffsetY = 2,
            ShadowOffsetX = 0,
            Justification = "Left",
        },
        LocalizationData.UIScripts.GunUI))
    thread(SecondPlayerUi.UpdateGunUI)

    FadeObstacleIn({
        Id = ScreenAnchorsSecondPlayer.GunUI,
        Duration = CombatUI.FadeInDuration,
        IncludeText = true,
        Distance =
            CombatUI.FadeDistance.Ammo,
        Direction = 0
    })
end

function SecondPlayerUi.UpdateGunUI(triggerArgs)
    triggerArgs = triggerArgs or {}
    local ammoData =
    {
        Current = triggerArgs.Ammo or
            GetWeaponProperty({ Id = CurrentRun.Hero.ObjectId, WeaponName = "GunWeapon", Property = "Ammo" }),
        Maximum = triggerArgs.MaxAmmo or GetWeaponMaxAmmo({ Id = CurrentRun.Hero.ObjectId, WeaponName = "GunWeapon" })
    }

    if ammoData.Current == nil then
        -- No longer carrying gun
        return
    end

    PulseText({ Id = ScreenAnchorsSecondPlayer.GunUI, ScaleTarget = 1.04, ScaleDuration = 0.05, HoldDuration = 0.05, PulseBias = 0.02 })
    if ammoData.Current > 0 then
        ModifyTextBox({ Id = ScreenAnchorsSecondPlayer.GunUI, Text = "UI_GunText", Color = Color.White, ColorDuration = 0.04 })
    else
        ModifyTextBox({ Id = ScreenAnchorsSecondPlayer.GunUI, Text = "UI_GunText", Color = Color.Red, ColorDuration = 0.04 })
    end

    ModifyTextBox({ Id = ScreenAnchorsSecondPlayer.GunUI, Text = "UI_GunText", FadeTarget = 1 })
    if HeroHasTrait("GunInfiniteAmmoTrait") or HeroHasTrait("GunLoadedGrenadeInfiniteAmmoTrait") then
        ModifyTextBox({
            Id = ScreenAnchorsSecondPlayer.GunUI,
            Text = "UI_Gun_Text_Infinity",
            OffsetY = -2,
            LuaKey = "TempTextData",
            LuaValue =
                ammoData,
            AutoSetDataProperties = false,
        })
    else
        ModifyTextBox({
            Id = ScreenAnchorsSecondPlayer.GunUI,
            Text = "UI_GunText",
            OffsetY = -2,
            LuaKey = "TempTextData",
            LuaValue =
                ammoData,
            AutoSetDataProperties = false,
        })
    end
    if HeroHasTrait("GunLoadedGrenadeTrait") then
        SetAnimation({ Name = "GunLaserIndicatorIcon", DestinationId = ScreenAnchorsSecondPlayer.GunUI })
    else
        SetAnimation({ Name = "GunAmmoIndicatorIcon", DestinationId = ScreenAnchorsSecondPlayer.GunUI })
    end
end

function SecondPlayerUi.HideGunUI()
    if ScreenAnchorsSecondPlayer.GunUI == nil then
        return
    end

    local id = ScreenAnchorsSecondPlayer.GunUI
    HideObstacle({
        Id = id,
        IncludeText = true,
        Distance = CombatUI.FadeDistance.Ammo,
        Angle = 180,
        Duration = CombatUI
            .FadeDuration,
        SmoothStep = true
    })


    ScreenAnchorsSecondPlayer.GunUI = nil

    wait(CombatUI.FadeDuration, RoomThreadName)
    Destroy({ Id = id })
    ModifyTextBox({ Id = id, FadeTarget = 0, FadeDuration = 0, AutoSetDataProperties = false, })
end

function SecondPlayerUi.DestroyGunUI()
    if ScreenAnchorsSecondPlayer.GunUI == nil then
        return
    end
    Destroy({ Id = ScreenAnchorsSecondPlayer.GunUI })
    ScreenAnchorsSecondPlayer.GunUI = nil
end

function SecondPlayerUi.InitHooks()
    -- Health
    HookUtils.onPostFunction("ShowHealthUI", SecondPlayerUi.ShowHealthUI)

    local _UpdateHealthUI = UpdateHealthUI
    function UpdateHealthUI()
        local mainHero = CoopPlayers.GetMainHero()
        HeroContext.RunWithHeroContext(mainHero, function()
            _UpdateHealthUI()
            SecondPlayerUi.UpdateHealthUI()
        end)
    end

    HookUtils.onPostFunction("UpdateHealthUI", SecondPlayerUi.UpdateHealthUI)
    HookUtils.onPostFunction("DestroyHealthUI", SecondPlayerUi.DestroyHealthUI)
    HookUtils.onPostFunction("HideHealthUI", SecondPlayerUi.HideHealthUI)
    HookUtils.onPostFunction("UpdateRallyHealthUI", SecondPlayerUi.UpdateRallyHealthUI)

    -- LifePipIds
    local _UpdateLifePips = UpdateLifePips
    UpdateLifePips = function()
        local mainHero = CoopPlayers.GetMainHero()
        _UpdateLifePips(mainHero)
        SecondPlayerUi.UpdateLifePips()
    end

    HookUtils.onPostFunction("RecreateLifePips", SecondPlayerUi.RecreateLifePips)

    -- Ammo / red crystrals
    HookUtils.onPostFunction("ShowAmmoUI", SecondPlayerUi.ShowAmmoUI)
    HookUtils.onPostFunction("HideAmmoUI", SecondPlayerUi.HideAmmoUI)
    HookUtils.onPostFunction("DestroyAmmoUI", SecondPlayerUi.DestroyAmmoUI)

    local _UpdateAmmoUI = UpdateAmmoUI
    UpdateAmmoUI = function()
        local mainHero = CoopPlayers.GetMainHero()
        HeroContext.RunWithHeroContext(mainHero, function()
            _UpdateAmmoUI()
            SecondPlayerUi.UpdateAmmoUI()
        end)
    end

    -- Gun
    local _ShowGunUI = ShowGunUI
    ShowGunUI = function()
        local mainHero = CoopPlayers.GetMainHero() or CurrentRun.Hero
        HeroContext.RunWithHeroContext(mainHero, _ShowGunUI)
        local secondHero = CoopPlayers.GetHero(2)
        if secondHero then
            HeroContext.RunWithHeroContext(secondHero, SecondPlayerUi.ShowGunUI)
        end
    end

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

    EquipPlayerWeaponPresentation = function (weaponData, args)
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
        local execFun = hasHeroWeaponWithIcon(hero) and _ShowGunUI or _HideGunUI
        thread(function()
            HeroContext.RunWithHeroContext(hero, execFun)
        end )

        hero = CoopPlayers.GetHero(2)
        if hero then
            execFun = hasHeroWeaponWithIcon(hero) and SecondPlayerUi.ShowGunUI or SecondPlayerUi.HideGunUI
            thread(function()
                HeroContext.RunWithHeroContext(hero, execFun)
            end)
        end
    end

    HookUtils.onPostFunction("DestroyGunUI", SecondPlayerUi.DestroyGunUI)


    local _PulseText = PulseText
    PulseText = function(args)
        if args.ScreenAnchorReference and HeroContext.GetCurrentHeroContext() == CoopPlayers.GetHero(2) then
            local idOnSecond = ScreenAnchorsSecondPlayer[args.ScreenAnchorReference]
            if idOnSecond then
                args.Id = idOnSecond
            end
        end

        _PulseText(args)
    end
end

--ShowSuperMeter()
--ShowTraitUI()

return SecondPlayerUi
