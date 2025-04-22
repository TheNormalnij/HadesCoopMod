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
---@type CoopModConfig
local Config = ModRequire "config.lua"

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
    if hero.ObjectId then
        CoopPlayers.PlayerUnitIdToHero[hero.ObjectId] = hero
    end
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

---@return boolean
function CoopPlayers.HasAlivePlayers()
    for _, hero in CoopPlayers.PlayersIterator() do
        if hero and not hero.IsDead then
            return true
        end
    end

    return false
end

---@return table<table>
function CoopPlayers.GetAlivePlayers()
    local out = {}
    for _, hero in CoopPlayers.PlayersIterator() do
        if hero and not hero.IsDead then
            table.insert(out, hero)
        end
    end

    return out
end

function CoopPlayers.RestoreSavedHero(playerId)
    local hero = CurrentRun["Hero" .. playerId]
    DebugPrint { Text = "Restore player hero" .. tostring(playerId) .. " " .. tostring(hero) }
    if hero then
        CoopPlayers.CoopHeroes[playerId] = hero
        CoopPlayers.InitCoopUnit(playerId)
    end
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

    CurrentRun["Hero" .. playerId] = hero

    DebugPrint { Text = "Create hero for player " .. tostring(playerId) }

    CoopPlayers.PlayerUnitIdToHero[unit] = hero
    CoopPlayers.CoopHeroes[playerId] = hero

    if Config.Player2HasOutline then
        AddOutline(
            MergeTables(Config.Player2Outline, { Id = unit })
        )
    end
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

function CoopPlayers.CoopInit()
    CoopPlayers.InitCoopPlayer()

    CoopPlayers.CoopHeroes[1] = CurrentRun.Hero

    for playerId = 2, CoopPlayers.GetPlayersCount() do
        local hero = CurrentRun["Hero" .. playerId]
        if hero then
            CoopPlayers.CoopHeroes[playerId] = hero
        end
    end
end

return CoopPlayers
