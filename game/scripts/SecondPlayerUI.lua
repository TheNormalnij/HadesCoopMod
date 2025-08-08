-- This files has modifed Super Giant Games code
-- Not licensed

---@type CoopPlayers
local CoopPlayers = ModRequire "CoopPlayers.lua"
---@type HeroContext
local HeroContext = ModRequire "HeroContext.lua"

---@class SecondPlayerUi
local SecondPlayerUi = {}

local ScreenAnchorsSecondPlayer = {}

SecondPlayerUi.ScreenAnchors = ScreenAnchorsSecondPlayer

function SecondPlayerUi.Init()
    SecondPlayerUi.UpdateSuperUIComponentOriginal = UpdateSuperUIComponent
    SecondPlayerUi.UpdateSuperMeterUIRealOriginal = UpdateSuperMeterUIReal
    SecondPlayerUi.DestroySuperMeterOriginal = DestroySuperMeter
    SecondPlayerUi.HideSuperMeterOriginal = HideSuperMeter
    SecondPlayerUi.HideGunUIOriginal = HideGunUI
    SecondPlayerUi.DestroyHealthUIOriginal = DestroyHealthUI
    SecondPlayerUi.DestroyGunUIOriginal = DestroyGunUI
    SecondPlayerUi.DestroyAmmoUIOriginal = DestroyAmmoUI
    SecondPlayerUi.ShowSuperMeterOriginal = ShowSuperMeter
    SecondPlayerUi.StartAmmoReloadPresentationOriginal = StartAmmoReloadPresentation
    SecondPlayerUi.EndAmmoReloadPresentationOriginal = EndAmmoReloadPresentation
    SecondPlayerUi.ShowAmmoUIOriginal = ShowAmmoUI
    SecondPlayerUi.HideAmmoUIOriginal = HideAmmoUI
    SecondPlayerUi.UpdateHealthUIUIOriginal = UpdateHealthUI
end

--- NOT OK
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
    local hero = CoopPlayers.GetHero(2)
    if hero == nil then return; end

    HeroContext.RunWithHeroContext(hero, function()
        SecondPlayerUi.CallWithActorWrap(SecondPlayerUi.UpdateHealthUIUIOriginal)
    end)
end

--- NOT OK
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

--- NOT OK
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
    SecondPlayerUi.CallWithActorWrap(SecondPlayerUi.DestroyHealthUIOriginal)
end

--- NOT OK
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

--- NOT OK
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
    local CreateScreenObstacleOriginal = CreateScreenObstacle
    local actorsBefore = ScreenAnchors

    CreateScreenObstacle = function(params)
        params.X = ScreenWidth - 512 - 150
        return CreateScreenObstacleOriginal(params)
    end

    ScreenAnchors = ScreenAnchorsSecondPlayer
    SecondPlayerUi.ShowAmmoUIOriginal()
    ScreenAnchors = actorsBefore
    CreateScreenObstacle = CreateScreenObstacleOriginal
end

--- NOT OK
function SecondPlayerUi.UpdateAmmoUI()
    local hero = CoopPlayers.GetHero(2)

    if ScreenAnchorsSecondPlayer.AmmoIndicatorUI == nil or not hero then
        return
    end
    local ammoData =
    {
        Current = GetWeaponProperty{ Id = hero.ObjectId, WeaponName = "RangedWeapon", Property = "Ammo" },
        Maximum = GetWeaponMaxAmmo{ Id = hero.ObjectId, WeaponName = "RangedWeapon" }
    }

    if ammoData.Current == nil then
        -- The player wasn't initialized yet
        return
    end


    PulseText({ Id = ScreenAnchorsSecondPlayer.AmmoIndicatorUI, ScaleTarget = 1.04, ScaleDuration = 0.05, HoldDuration = 0.05, PulseBias = 0.02 })
    ModifyTextBox({ Id = ScreenAnchorsSecondPlayer.AmmoIndicatorUI, Text = "UI_AmmoText", OffsetY = -2, LuaKey = "TempTextData", LuaValue =
    ammoData, AutoSetDataProperties = false, })
end

function SecondPlayerUi.HideAmmoUI()
    if ScreenAnchorsSecondPlayer.AmmoIndicatorUI == nil then
        return
    end
    local actorsBefore = ScreenAnchors
    ScreenAnchors = ScreenAnchorsSecondPlayer

    local waitOrig = wait
    wait = function(...)
        ScreenAnchors = actorsBefore
        wait = waitOrig
        waitOrig(...)
    end
    SecondPlayerUi.HideAmmoUIOriginal()
end

function SecondPlayerUi.StartAmmoReloadPresentation(delay)
    local CreateScreenObstacleOriginal = CreateScreenObstacle
    CreateScreenObstacle = function(params)
        local poxX = ScreenWidth - 494 - 150
        params.X = params.X - 532 + poxX
        return CreateScreenObstacleOriginal(params)
    end

    local actorsBefore = ScreenAnchors
    ScreenAnchors = ScreenAnchorsSecondPlayer
    SecondPlayerUi.StartAmmoReloadPresentationOriginal(delay)
    ScreenAnchors = actorsBefore
    CreateScreenObstacle = CreateScreenObstacleOriginal
end

function SecondPlayerUi.EndAmmoReloadPresentation()
    local SpawnObstacleOriginal = SpawnObstacle
    SpawnObstacle = function(params)
        local poxX = ScreenWidth - 494 - 150
        params.OffsetX = params.OffsetX - 532 + poxX
        return SpawnObstacleOriginal(params)
    end

    local actorsBefore = ScreenAnchors
    ScreenAnchors = ScreenAnchorsSecondPlayer
    SecondPlayerUi.EndAmmoReloadPresentationOriginal()
    ScreenAnchors = actorsBefore
    SpawnObstacle = SpawnObstacleOriginal
end

function SecondPlayerUi.DestroyAmmoUI()
    if ScreenAnchorsSecondPlayer.AmmoIndicatorUI == nil then
        return
    end
    SecondPlayerUi.CallWithActorWrap(SecondPlayerUi.DestroyAmmoUIOriginal)
end

-- Gun

--- NOT OK
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

--- NOT OK
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
    local actorsBefore = ScreenAnchors
    ScreenAnchors = ScreenAnchorsSecondPlayer

    local waitOriginal = wait
    wait = function(...)
        ScreenAnchors = actorsBefore
        waitOriginal(...)
    end

    SecondPlayerUi.HideGunUIOriginal()
end

function SecondPlayerUi.DestroyGunUI()
    SecondPlayerUi.CallWithActorWrap(SecondPlayerUi.DestroyGunUIOriginal)
end

function SecondPlayerUi.ShowSuperMeter()
    local CreateScreenObstacleOriginal = CreateScreenObstacle

    local posX = ScreenWidth - 500 + 20
    local element = 0
    CreateScreenObstacle = function(params)
        element = element + 1
        if element <= 3 then
            params.X = posX - params.X
        else
            params.X  = posX + params.X + 20
        end

        return CreateScreenObstacleOriginal(params)
    end

    local actorsBefore = ScreenAnchors
    ScreenAnchors = ScreenAnchorsSecondPlayer
    SecondPlayerUi.ShowSuperMeterOriginal()
    ScreenAnchors = actorsBefore
    CreateScreenObstacle = CreateScreenObstacleOriginal
end

function SecondPlayerUi.HideSuperMeter()
    if ScreenAnchorsSecondPlayer.SuperMeterIcon == nil then
        return
    end
    local actorsBefore = ScreenAnchors
    ScreenAnchors = ScreenAnchorsSecondPlayer

    local waitOrig = wait
    wait = function(...)
        ScreenAnchors = actorsBefore
        wait = waitOrig
        waitOrig(...)
    end

    SecondPlayerUi.HideSuperMeterOriginal()
end

function SecondPlayerUi.DestroySuperMeter()
    SecondPlayerUi.CallWithActorWrap(SecondPlayerUi.DestroySuperMeterOriginal)
end

function SecondPlayerUi.UpdateSuperUIComponent(index, filled)
    if not CurrentRun.Hero.SuperCost then
        return
    end
    SecondPlayerUi.CallWithActorWrap(SecondPlayerUi.UpdateSuperUIComponentOriginal, index, filled)
end

function SecondPlayerUi.UpdateSuperMeterUIReal()
    if not CurrentRun.Hero.SuperCost then
        return
    end
    SecondPlayerUi.CallWithActorWrap(SecondPlayerUi.UpdateSuperMeterUIRealOriginal)
end

function SecondPlayerUi.Refresh()
    SecondPlayerUi.UpdateHealthUI()
    SecondPlayerUi.RecreateLifePips()
    SecondPlayerUi.UpdateAmmoUI()
end

---@private
function SecondPlayerUi.CallWithActorWrap(fun, ...)
    local actorsBefore = ScreenAnchors
    ScreenAnchors = ScreenAnchorsSecondPlayer
    fun(...)
    ScreenAnchors = actorsBefore
end


return SecondPlayerUi
