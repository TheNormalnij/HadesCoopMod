--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type GameModifed
local GameModifed = ModRequire "GameModifed.lua"
---@type HeroContext
local HeroContext = ModRequire "HeroContext.lua"
---@type CoopControl
local CoopControl = ModRequire "CoopControl.lua"

---@class CoopPlayers
local CoopPlayers = {}

---@private
---@type table<number, table>
CoopPlayers.PlayerUnitIdToHero = {}
---@private
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

---@return number
function CoopPlayers.GetPlayersCount()
    return CoopGetPlayersCount()
end

---@param unitId integer
---@return boolean
function CoopPlayers.IsPlayerUnit(unitId)
    return CoopPlayers.PlayerUnitIdToHero[unitId] and true
end

function CoopPlayers.SetMainHero(hero)
    DebugPrint{Text = "Set main hero: " .. tostring(hero) }
    CoopPlayers.CoopHeroes[1] = hero
end

function CoopPlayers.GetHero(playerId)
    return CoopPlayers.CoopHeroes[playerId]
end

function CoopPlayers.PlayersIterator()
    return ipairs(CoopPlayers.CoopHeroes)
end

---@param hero table
function CoopPlayers.GetPlayerByHero(hero)
    for playerId = 1, #CoopPlayers.CoopHeroes do
        if CoopPlayers.CoopHeroes[playerId] == hero then
            return playerId
        end
    end
end

function CoopPlayers.GetHeroByUnit(unitId)
    return CoopPlayers.PlayerUnitIdToHero[unitId]
end

---@return table<number>
function CoopPlayers.GetUnits()
    local out = {}
    for unit in pairs(CoopPlayers.PlayerUnitIdToHero) do
        table.insert(out, unit)
    end
    return out
end

function CoopPlayers.InitCoopPlayer()
    local playerId = 2

    if not CoopHasPlayer(playerId) then
        playerId = CoopCreatePlayer()
        CoopControl.InitControlSchemas()
    end

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
            EquipWeaponUpgrade(hero, { SkipTraitHighlight = true })
            InitHeroLastStands(hero)

            hero.MaxHealth = hero.MaxHealth + GetNumMetaUpgrades("HealthMetaUpgrade") * MetaUpgradeData.HealthMetaUpgrade.ChangeValue
            hero.Health = hero.MaxHealth
        end)
    end

    DebugPrint { Text = "Create hero for player " .. tostring(playerId) }

    CoopPlayers.PlayerUnitIdToHero[unit] = hero
    CoopPlayers.CoopHeroes[playerId] = hero

    AddOutline { Id = unit,
        R = 0,
        G = 200,
        B = 0,
        Opacity = 0.6,
        Thickness = 2,
        Threshold = 0.6,
    }
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
    CoopPlayers.InitCoopPlayer()
end

return CoopPlayers
