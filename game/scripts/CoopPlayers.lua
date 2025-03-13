--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type GameModifed
local GameModifed = ModRequire "GameModifed.lua"
---@type HeroContext
local HeroContext = ModRequire "HeroContext.lua"

---@class CoopPlayers
local CoopPlayers = {}

---@private
---@type table<number, table>
CoopPlayers.PlayerUnitIdToHero = {}
---@type table<number, number>
CoopPlayers.PlayerIdToController = {}
---@type table[]
CoopPlayers.CoopHeroes = {}

function CoopPlayers.IsPlayerHero(t)
    for i = 1, #CoopPlayers.CoopHeroes do
        if CoopPlayers.CoopHeroes[i] == t then
            return true
        end
    end
    return false
end

function CoopPlayers.GetMainHero()
    return CoopPlayers.CoopHeroes[1]
end

function CoopPlayers.SetMainHero(hero)
    DebugPrint{Text = "Set main hero: " .. tostring(hero) }
    CoopPlayers.CoopHeroes[1] = hero
end

function CoopPlayers.GetHero(playerId)
    return CoopPlayers.CoopHeroes[playerId]
end

function CoopPlayers.GetHeroByUnit(unitId)
    return CoopPlayers.PlayerUnitIdToHero[unitId]
end

function CoopPlayers.InitCoopPlayer()
    local playerId = 2

    if not CoopHasPlayer(playerId) then
        playerId = CoopCreatePlayer()
    end

    CoopSetPlayerGamepad(1, 1)
    CoopSetPlayerGamepad(playerId, 0)

    CoopPlayers.PlayerIdToController[1] = 1
    CoopPlayers.PlayerIdToController[playerId] = 0
    return playerId
end

function CoopPlayers.InitCoopUnit(playerId)
    local unit = CoopCreatePlayerUnit(playerId)

    if not unit then
        return false
    end

    local hero = CoopPlayers.CoopHeroes[playerId]
    if not hero then
        hero = CreateNewHero(nil, { WeaponName = WeaponSets.HeroMeleeWeapons[1] })

        HeroContext.RunWithHeroContext(hero, function()
            EquipKeepsake(hero, GameState.LastAwardTrait, { SkipNewTraitHighlight = true })
            EquipAssist(hero, GameState.LastAssistTrait, { SkipNewTraitHighlight = true })
            InitHeroLastStands(hero)

            -- Equip weaon trait
            local currentWeaponInSlot = GetEquippedWeapon()
            AddTraitToHero{
                SkipNewTraitHighlight = true,
                TraitName = GetWeaponUpgradeTrait(currentWeaponInSlot, 1),
                Rarity = GetRarityKey(
                    GetWeaponUpgradeLevel(currentWeaponInSlot, GetEquippedWeaponTraitIndex(currentWeaponInSlot)))
            }
        end)
    end

    DebugPrint { Text = "Create hero for player " .. tostring(playerId) }

    CoopPlayers.PlayerUnitIdToHero[unit] = hero
    CoopPlayers.CoopHeroes[playerId] = hero

    HeroContext.RunWithHeroContext(hero, GameModifed.SetupAdditional, CurrentRun, nil, hero, unit)

    SetUntargetable { Id = hero.ObjectId }
    -- Disables bow arrow bounces
    SetUnitProperty { DestinationId = unit, Property = "FriendlyToPlayer", Value = true }

    return hero
end

function CoopPlayers.UpdateMainHero()
    local hero = CoopPlayers.GetMainHero()
    CoopPlayers.PlayerUnitIdToHero[hero.ObjectId] = hero
    SetUntargetable { Id = hero.ObjectId }
end

function CoopPlayers.OnPlayerDead(hero)
    if CoopPlayers.CoopHeroes[1] == hero then
        -- Handle to prevent crashes
    else
        for playerId = 2, #CoopPlayers.CoopHeroes do
            --SwitchActiveUnit { PlayerIndex = playerId }
            if CoopPlayers.CoopHeroes[playerId] == hero then
                CoopRemovePlayerUnit(playerId)
            end
        end
    end
end

function CoopPlayers.CoopInit()
    CoopPlayers.PlayerIdToController[1] = 0

    local playerId = CoopPlayers.InitCoopPlayer()
    --CoopPlayers.InitCoopUnit(playerId)
end

return CoopPlayers
