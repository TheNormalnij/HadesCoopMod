-- This files has modifed Super Giant Games code
-- Not licensed

---@class GameModifed
local GameModifed = {}

function GameModifed.SetupAdditional(currentRun, applyLuaUpgrades, Hero, ObjectId)
    Hero.ObjectId = ObjectId

    AttachLua({ Id = Hero.ObjectId, Table = Hero })
    AddToGroup({ Id = Hero.ObjectId, Name = "HeroTeam" })

    GatherAndEquipWeapons(currentRun)

    -- Laurel Crown VFX
    if Hero.AttachedAnimationName ~= nil then
        CreateAnimation({ Name = Hero.AttachedAnimationName, DestinationId = Hero.ObjectId })
    end

    -- Hero Light
    if Hero.AttachedLightName ~= nil and not currentRun.CurrentRoom.BlockHeroLight then
        local heroGroup = GetGroupName({ Id = Hero.ObjectId, DrawGroup = true })
        local heroLightGroup = "HeroLight"
        local heroLightId = SpawnObstacle({ Name = Hero.AttachedLightName, DestinationId = Hero
        .ObjectId, Group = heroLightGroup })
        InsertGroupBehind({ Name = heroLightGroup, DestinationName = heroGroup })
        SetScale({ Id = heroLightId, Fraction = Hero.AttachedLightScale })
        SetColor({ Id = heroLightId, Color = Hero.AttachedLightColor })
        Attach({ Id = heroLightId, DestinationId = Hero.ObjectId })
        Hero.AttachedLightId = heroLightId
    end

    -- Clear per-room state dictionaries
    Hero.InvulnerableFlags = {}
    CurrentRun.InvulnerableFlags = {}
    CurrentRun.PhasingFlags = {}

    -- Easy mode Check
    if ConfigOptionCache.EasyMode then
        if not HeroHasTrait("GodModeTrait") then
            AddTraitToHero({ TraitName = "GodModeTrait", SkipUIUpdate = true })
        end
    else
        RemoveTrait(Hero, "GodModeTrait")
    end
    -- Build all upgrades.
    UpdateHeroTraitDictionary()
    ApplyMetaUpgrades(Hero, applyLuaUpgrades)
    ApplyTraitAutoRamp(Hero)
    ApplyTraitUpgrade(Hero, applyLuaUpgrades)
    ApplyTraitSetupFunctions(Hero)
    ApplyMetaModifierHeroUpgrades(Hero, applyLuaUpgrades)
    ApplyAllTraitWeapons(Hero)

    for k, trait in pairs(Hero.Traits) do
        if trait.RoomCooldown ~= nil then
            IncrementTraitCooldown(trait)
        end
        if trait.TimeCooldown ~= nil then
            IncrementTraitCooldown(trait, trait.TimeCooldown)
        end
    end
    -- Completes setup
    SetHeroProperties(currentRun)

    Hero.PlayingVoiceLines = false
    Hero.QueuedVoiceLines = {}
    Hero.LastKillTime = nil
    Hero.StatusAnimation = nil
    Hero.PrevStatusAnimation = nil
    Hero.BlockStatusAnimations = nil
    Hero.FreezeInputKeys = {}
    Hero.DisableCombatControlsKeys = {}
    Hero.ActiveEffects = {}
    Hero.Frozen = false
    Hero.Mute = false
    Hero.Reloading = false
    Hero.KillStealVictimId = nil
    Hero.KillStolenFromId = nil
    Hero.ComboCount = 0
    Hero.ComboReady = false
    Hero.VacuumRush = false
    Hero.WeaponSpawns = nil

    Hero.MaxHealth = Hero.MaxHealth + GetNumMetaUpgrades("HealthMetaUpgrade") * MetaUpgradeData.HealthMetaUpgrade.ChangeValue
    Hero.Health = Hero.MaxHealth

    -- Changes gamepad LED color. Check PS4 gamepad for references. Do we need that?
    --SetLightBarColor({ PlayerIndex = 2, Color = Hero.LightBarColor or HeroData.DefaultHero.LightBarColor });
end

return GameModifed
