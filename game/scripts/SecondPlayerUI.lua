-- This files has modifed Super Giant Games code
-- Not licensed

---@type CoopPlayers
local CoopPlayers = ModRequire "CoopPlayers.lua"

---@class SecondPlayerUi
local SecondPlayerUi = {}

local ScreenAnchorsSecondPlayer = {}

SecondPlayerUi.ScreenAnchors = ScreenAnchorsSecondPlayer

function SecondPlayerUi.ShowHealthUI()
    if not ConfigOptionCache.ShowUIAnimations then
        return
    end

    if ScreenAnchorsSecondPlayer.HealthBack ~= nil then
        return
    end

    local posX = ScreenWidth - 500

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
        X = posX - (10 - CombatUI.FadeDistance.Health),
        --X = ScreenWidth - 266,
        Y = ScreenHeight - 50
    })

    ScreenAnchorsSecondPlayer.HealthRally = CreateScreenObstacle({
        Name = "BlankObstacle",
        Group = "Combat_UI",
        X = posX - (10 - CombatUI.FadeDistance.Health),
        Y = ScreenHeight - 50
    })

    ScreenAnchorsSecondPlayer.HealthFill = CreateScreenObstacle({
        Name = "BlankObstacle",
        Group = "Combat_UI",
        X = posX - (10 - CombatUI.FadeDistance.Health),
        Y = ScreenHeight - 50
    })

    ScreenAnchorsSecondPlayer.HealthFlash = CreateScreenObstacle({
        Name = "BlankObstacle",
        Group = "Combat_UI",
        X = posX - (10 - CombatUI.FadeDistance.Health),
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

    SecondPlayerUi.UpdateHealthUI()

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
    if ScreenAnchorsSecondPlayer.LifePipIds then
        Destroy { Ids = ScreenAnchorsSecondPlayer.LifePipIds }
    end

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

function SecondPlayerUi.ShowSuperMeter()
    if not IsSuperValid() then
        return
    end

    if ScreenAnchorsSecondPlayer.SuperMeterIcon ~= nil then
        -- Already visible
        return
    end

    local posX = ScreenWidth - 500 + 20

    ScreenAnchorsSecondPlayer.SuperMeterIcon = CreateScreenObstacle{
        Name = "BlankObstacle",
        Group = "Combat_UI",
        X = posX - (10 - CombatUI.FadeDistance.Super),
        Y = ScreenHeight - 10
    }

    ScreenAnchorsSecondPlayer.SuperMeterCap = CreateScreenObstacle{
        Name = "BlankObstacle",
        Group = "Combat_Menu",
        X = posX - (10 - CombatUI.FadeDistance.Super),
        Y = ScreenHeight - 10
    }

    ScreenAnchorsSecondPlayer.SuperMeterHint = CreateScreenObstacle{
        Name = "BlankObstacle",
        X = posX - 10,
        Y = ScreenHeight - 10,
        Group = "Combat_Menu_Additive"
    }

    SetAnimation({ Name = "WrathBar", DestinationId = ScreenAnchorsSecondPlayer.SuperMeterIcon })

    if HasHeroTraitValue("SuperMeterCap") then
        SetAnimation({ Name = "WrathBarRegenCap", DestinationId = ScreenAnchorsSecondPlayer.SuperMeterCap })
    end

    local superMeterPoints = CurrentRun.Hero.SuperMeter
    if superMeterPoints == nil then
        superMeterPoints = 0
    end

    if CurrentRun.Hero.SuperMeter == CurrentRun.Hero.SuperMeterLimit and IsSuperAvailable(CurrentRun.Hero) and CanCommenceSuper() then
        SetAnimation({ Name = "WrathBarFullFx", DestinationId = ScreenAnchorsSecondPlayer.SuperMeterHint })
    end

    ScreenAnchorsSecondPlayer.SuperPipBackingIds = {}
    ScreenAnchorsSecondPlayer.SuperPipIds = {}
    local pipXSize = SuperUI.PipXWidth * CurrentRun.Hero.SuperCost / SuperUI.BaseMoveThreshold
    for i = 1, math.ceil(CurrentRun.Hero.SuperMeterLimit / CurrentRun.Hero.SuperCost) do
        table.insert(ScreenAnchorsSecondPlayer.SuperPipBackingIds,
            CreateScreenObstacle{
                Name = "BlankObstacle",
                Group = "Combat_UI",
                X = posX + SuperUI.PipXStart + (i - 1) * pipXSize - CombatUI.FadeDistance.Super + 20,
                Y = SuperUI.PipY }
        )
        table.insert(ScreenAnchorsSecondPlayer.SuperPipIds,
            CreateScreenObstacle{
                Name = "BlankObstacle",
                Group = "Combat_Menu_Additive",
                X = posX + SuperUI.PipXStart + (i - 1) * pipXSize - CombatUI.FadeDistance.Super + 20,
                Y = SuperUI.PipY
            }    
        )
        local fillPercent = 0
        if superMeterPoints > (i - 1) * CurrentRun.Hero.SuperCost then
            if CurrentRun.Hero.SuperMeterLimit < CurrentRun.Hero.SuperCost * i and i == math.ceil(CurrentRun.Hero.SuperMeterLimit / CurrentRun.Hero.SuperCost) then
                fillPercent = math.min(1,
                    (superMeterPoints - (i - 1) * CurrentRun.Hero.SuperCost) /
                    (CurrentRun.Hero.SuperMeterLimit % CurrentRun.Hero.SuperCost))
            else
                fillPercent = math.min(1,
                    (superMeterPoints - (i - 1) * CurrentRun.Hero.SuperCost) / CurrentRun.Hero.SuperCost)
            end
        end
        SecondPlayerUi.UpdateSuperUIComponent(i, fillPercent)
    end

    UpdateSuperMeterUI()

    FadeObstacleIn({ Id = ScreenAnchorsSecondPlayer.SuperMeterIcon, Duration = CombatUI.FadeInDuration, IncludeText = true, Distance =
    CombatUI.FadeDistance.Super, Direction = 0 })
    FadeObstacleIn({ Id = ScreenAnchorsSecondPlayer.SuperMeterCap, Duration = CombatUI.FadeInDuration, IncludeText = true, Distance =
    CombatUI.FadeDistance.Super, Direction = 0 })
    for i, pipId in pairs(ScreenAnchorsSecondPlayer.SuperPipIds) do
        FadeObstacleIn({ Id = pipId, Duration = CombatUI.FadeInDuration, IncludeText = false, Distance = CombatUI
        .FadeDistance.Super, Direction = 0 })
    end
    for i, pipId in pairs(ScreenAnchorsSecondPlayer.SuperPipBackingIds) do
        FadeObstacleIn({ Id = pipId, Duration = CombatUI.FadeInDuration, IncludeText = false, Distance = CombatUI
        .FadeDistance.Super, Direction = 0 })
    end
end

function SecondPlayerUi.HideSuperMeter()
    if ScreenAnchorsSecondPlayer.SuperMeterIcon == nil then
        -- Already hidden
        return
    end

    HideObstacle({ Id = ScreenAnchorsSecondPlayer.SuperMeterIcon, IncludeText = true, Distance = CombatUI.FadeDistance.Super, Angle = 180, Duration =
    CombatUI.FadeDuration, SmoothStep = true })
    HideObstacle({ Id = ScreenAnchorsSecondPlayer.SuperMeterCap, IncludeText = true, Distance = CombatUI.FadeDistance.Super, Angle = 180, Duration =
    CombatUI.FadeDuration, SmoothStep = true })

    for i, pipId in pairs(ScreenAnchorsSecondPlayer.SuperPipIds) do
        Move({ Id = pipId, Distance = CombatUI.FadeDistance.Super, Angle = 180, Duration = CombatUI.FadeDuration, SmoothStep = true })
        SetAlpha({ Id = pipId, Fraction = 0, Duration = CombatUI.FadeDuration })
    end

    for i, pipId in pairs(ScreenAnchorsSecondPlayer.SuperPipBackingIds) do
        Move({ Id = pipId, Distance = CombatUI.FadeDistance.Super, Angle = 180, Duration = CombatUI.FadeDuration, SmoothStep = true })
        SetAlpha({ Id = pipId, Fraction = 0, Duration = CombatUI.FadeDuration })
    end

    local ids = CombineTables(ScreenAnchorsSecondPlayer.SuperPipIds, ScreenAnchorsSecondPlayer.SuperPipBackingIds) or {}
    table.insert(ids, ScreenAnchorsSecondPlayer.SuperMeterIcon)
    table.insert(ids, ScreenAnchorsSecondPlayer.SuperMeterCap)
    table.insert(ids, ScreenAnchorsSecondPlayer.SuperMeterHint)


    ScreenAnchorsSecondPlayer.SuperMeterIcon = nil
    ScreenAnchorsSecondPlayer.SuperMeterCap = nil
    ScreenAnchorsSecondPlayer.SuperMeterHint = nil
    ScreenAnchorsSecondPlayer.SuperPipIds = nil
    ScreenAnchorsSecondPlayer.SuperPipBackingIds = nil

    wait(CombatUI.FadeDuration, RoomThreadName)

    Destroy({ Ids = ids })
end

function SecondPlayerUi.DestroySuperMeter()
    local ids = CombineTables(ScreenAnchorsSecondPlayer.SuperPipIds, ScreenAnchorsSecondPlayer.SuperPipBackingIds) or {}
    table.insert(ids, ScreenAnchorsSecondPlayer.SuperMeterIcon)
    table.insert(ids, ScreenAnchorsSecondPlayer.SuperMeterCap)
    table.insert(ids, ScreenAnchorsSecondPlayer.SuperMeterHint)
    if not IsEmpty(ids) then
        Destroy({ Ids = ids })
    end
    ScreenAnchorsSecondPlayer.SuperMeterIcon = nil
    ScreenAnchorsSecondPlayer.SuperMeterCap = nil
    ScreenAnchorsSecondPlayer.SuperMeterHint = nil
    ScreenAnchorsSecondPlayer.SuperPipIds = nil
    ScreenAnchorsSecondPlayer.SuperPipBackingIds = nil
end

function SecondPlayerUi.UpdateSuperUIComponent(index, filled)
    local animationName = "WrathPipEmpty"
    if filled >= 1 then
        animationName = "WrathPipFull"
    elseif filled > 0 then
        animationName = "WrathPipPartial"
    end

    SetAnimation({ Name = "WrathPipEmpty", DestinationId = ScreenAnchorsSecondPlayer.SuperPipBackingIds[index] })
    SetAnimation({ Name = animationName, DestinationId = ScreenAnchorsSecondPlayer.SuperPipIds[index] })
    local baseFraction = CurrentRun.Hero.SuperCost / SuperUI.BaseMoveThreshold * 1.0

    if CurrentRun.Hero.SuperMeterLimit < CurrentRun.Hero.SuperCost * index then
        baseFraction = (CurrentRun.Hero.SuperMeterLimit % CurrentRun.Hero.SuperCost) / SuperUI.BaseMoveThreshold * 1.0
    end
    SetScaleX({ Id = ScreenAnchorsSecondPlayer.SuperPipBackingIds[index], Fraction = baseFraction, Duration = 0 })
    SetScaleX({ Id = ScreenAnchorsSecondPlayer.SuperPipIds[index], Fraction = baseFraction * filled, Duration = 0 })
end

function SecondPlayerUi.UpdateSuperMeterUIReal()
    if ScreenAnchorsSecondPlayer.SuperMeterIcon == nil then
        return
    end

    local superMeterPoints = CurrentRun.Hero.SuperMeter
    if superMeterPoints == nil then
        superMeterPoints = 0
    end

    for i = 1, TableLength(ScreenAnchorsSecondPlayer.SuperPipBackingIds) do
        local fillPercent = 0
        if superMeterPoints > (i - 1) * CurrentRun.Hero.SuperCost then
            if CurrentRun.Hero.SuperMeterLimit < CurrentRun.Hero.SuperCost * i and i == math.ceil(CurrentRun.Hero.SuperMeterLimit / CurrentRun.Hero.SuperCost) then
                fillPercent = math.min(1,
                    (superMeterPoints - (i - 1) * CurrentRun.Hero.SuperCost) /
                    (CurrentRun.Hero.SuperMeterLimit % CurrentRun.Hero.SuperCost))
            else
                fillPercent = math.min(1,
                    (superMeterPoints - (i - 1) * CurrentRun.Hero.SuperCost) / CurrentRun.Hero.SuperCost)
            end
        end
        UpdateSuperUIComponent(i, fillPercent)
    end
    ModifyTextBox({ Id = ScreenAnchorsSecondPlayer.SuperMeterIcon, Text = "UI_SuperText", LuaKey = "TempTextData", LuaValue = { Current = math.floor(superMeterPoints), Maximum = CurrentRun.Hero.SuperMeterLimit } })

    UIScriptsDeferred.SuperMeterDirty = false
end

function SecondPlayerUi.Refresh()
    SecondPlayerUi.UpdateHealthUI()
    SecondPlayerUi.RecreateLifePips()
    SecondPlayerUi.UpdateAmmoUI()
end

return SecondPlayerUi
