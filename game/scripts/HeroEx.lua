--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type HeroContext
local HeroContext = ModRequire "HeroContext.lua"
---@type HookUtils
local HookUtils = ModRequire "HookUtils.lua"

---@class HeroEx
local HeroEx = {}

function HeroEx.Init()
    -- Save unhooked
    HeroEx.SetupHeroObject = SetupHeroObject
end

---@param hero table
---@return string
---@return string
function HeroEx.GetGiftAndAssist(hero)
    local currentGift, currentAssist
    for _, trait in pairs(hero.Traits) do
        if not trait.InheritFrom then
            goto continue
        end

        if trait.InheritFrom[1] == "AssistTrait" then
            currentAssist = trait.Name
        elseif trait.InheritFrom[1] == "GiftTrait" then
            currentGift = trait.Name
        end

        ::continue::
    end

    return currentGift, currentAssist
end

---@param hero table
---@return string?
function HeroEx.GetWeapon(hero)
    for _, name in pairs(WeaponSets.HeroMeleeWeapons) do
        if hero.Weapons[name] then
            return name
        end
    end
end

---@param hero table
---@return string?
---@return number?
function HeroEx.GetHeroWeaponFull(hero)
    local weaponName = HeroEx.GetWeapon(hero)

    if not weaponName then
        DebugPrint { Text = "The player has no weapon!!!!" }
        return
    end

    -- See #46
    -- Player 2 doesn't have a trait if weapon aspects aren't unlocked
    -- Use the first weapon aspect by default
    local weaponIndex = 1

    for index in pairs(WeaponUpgradeData[weaponName]) do
        local weaponData = WeaponUpgradeData[weaponName][index]
        local trait = hero.TraitDictionary[weaponData.TraitName or weaponData.RequiredInvestmentTraitName]
        if trait then
            ---@diagnostic disable-next-line: cast-local-type
            weaponIndex = index
            break
        end
    end

    return weaponName, weaponIndex
end


---@class ICreateFreshHeroArgs
---@field keepsake string
---@field assist string
---@field weaponName string
---@field weaponVariant number

---@param args ICreateFreshHeroArgs
function HeroEx.CreateFreshHero(args)
    local hero = CreateNewHero(nil, { WeaponName = args.weaponName })
    if args.weaponName then
        local secondaryWeapon = WeaponData[args.weaponName].SecondaryWeapon
        if secondaryWeapon then
            hero.Weapons[secondaryWeapon] = true
        end
    end

    HeroContext.RunWithHeroContext(hero, function()
        EquipKeepsake(hero, args.keepsake, { SkipNewTraitHighlight = true })
        EquipAssist(hero, args.assist, { SkipNewTraitHighlight = true })

        EquipWeaponUpgrade(hero, { SkipTraitHighlight = true })
        InitHeroLastStands(hero)

        hero.MaxHealth = hero.MaxHealth +
        GetNumMetaUpgrades("HealthMetaUpgrade") * MetaUpgradeData.HealthMetaUpgrade.ChangeValue
        hero.Health = hero.MaxHealth
    end)

    return hero
end

---@param hero table
---@param position number?
function HeroEx.ShowHero(hero, position)
    SetColor { Id = hero.ObjectId, Color = { 255, 255, 255, 255 } }
    if position ~= nil then
        Teleport { Id = hero.ObjectId, DestinationId = position }
    end
end

---@param hero table
function HeroEx.HideHero(hero)
    local weaponsToHide = { "RangedWeapon" }
    for _, weaponName in ipairs(WeaponSets.HeroMeleeWeapons) do
        if hero.Weapons[weaponName] then
            table.insert(weaponsToHide, weaponName)
        end
    end

    UnequipWeapon { DestinationId = hero.ObjectId, Names = weaponsToHide, UnloadPackages = false }
    SetColor { Id = hero.ObjectId, Color = { 255, 255, 255, 0 } }
    Teleport { Id = hero.ObjectId, DestinationId = hero.ObjectId, OffsetX = -10000 }
end

function HeroEx.SetupAdditional(currentRun, applyLuaUpgrades, hero, ObjectId)
    HookUtils.wrapOnce("GetIdsByType", function()
        return { ObjectId }
    end)
    HeroContext.RunWithHeroContext(hero, HeroEx.SetupHeroObject, currentRun, applyLuaUpgrades)
end

return HeroEx