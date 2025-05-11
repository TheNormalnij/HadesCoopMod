--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "CoopPlayers.lua"

---@class CombinedTraitsUI
local CombinedTraitsUI = {}

---@private
CombinedTraitsUI.isTraitsContextSwithInFrogress = false

---@private
CombinedTraitsUI.currentTraitsHero = nil

---@public
function CombinedTraitsUI.ChangeHeroInTraitsMenu()
    if CombinedTraitsUI.isTraitsContextSwithInFrogress then
        return
    end

    local currentHeroInMenu = CombinedTraitsUI.GetCurrentTraitHero()
    if CurrentRun.Hero == currentHeroInMenu then
        return
    end

    CombinedTraitsUI.isTraitsContextSwithInFrogress = true

    CombinedTraitsUI.RemoveHeroTrait(currentHeroInMenu)

    CombinedTraitsUI.currentTraitsHero = CurrentRun.Hero
    CombinedTraitsUI.AddHeroTraits(CombinedTraitsUI.currentTraitsHero)

    if CurrentRun and CurrentRun.CurrentRoom then
        TraitUIActivateTraits()
    end

    CombinedTraitsUI.isTraitsContextSwithInFrogress = false
end

---@private
---@param hero table
function CombinedTraitsUI.RemoveHeroTrait(hero)
    for _, trait in pairs(hero.Traits) do
        TraitUIRemove(trait)
    end
    UpdateNumHiddenTraits()
end

---@private
---@param hero table
function CombinedTraitsUI.AddHeroTraits(hero)
    local showingTraits = {}

    for _, traitData in pairs(hero.Traits) do
        if showingTraits[traitData.Name] == nil or not AreTraitsIdentical(traitData, showingTraits[traitData.Name]) or (AreTraitsIdentical(traitData, showingTraits[traitData.Name]) and GetRarityValue(showingTraits[traitData.Name].Rarity) < GetRarityValue(traitData.Rarity)) then
            if not showingTraits[traitData.Name] then
                showingTraits[traitData.Name] = {}
            end
            table.insert(showingTraits[traitData.Name], traitData)
        end
    end

    for traitName, traitDatas in pairs(showingTraits) do
        for i, traitData in pairs(traitDatas) do
            TraitUIAdd(traitData, true)
        end
    end

    if CurrentRun.EnemyUpgrades then
        for k, upgradeName in pairs(CurrentRun.EnemyUpgrades) do
            local upgradeData = EnemyUpgradeData[upgradeName]
            TraitUIAdd(upgradeData, true)
        end
    end

    local numHidden = GetNumHiddenTraits()
    if numHidden > 0 then
        UpdateAdditionalTraitHint(numHidden)
        FadeObstacleIn {
            Id = ScreenAnchors.AdditionalTraitHint,
            IncludeText = true,
            Duration = CombatUI.FadeInDuration,
            Distance =
                CombatUI.FadeDistance.Trait,
            Direction = 0
        }
    else
        HideObstacle {
            Id = ScreenAnchors.AdditionalTraitHint,
            IncludeText = true,
            Distance = CombatUI.FadeDistance.Trait,
            Angle = 180,
            Duration = CombatUI.TraitFadeDuration,
            SmoothStep = true
        }
    end
end

function CombinedTraitsUI.GetCurrentTraitHero()
    return CombinedTraitsUI.currentTraitsHero or CoopPlayers.GetMainHero()
end

return CombinedTraitsUI
