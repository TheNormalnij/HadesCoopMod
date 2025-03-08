--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"
---@type SecondPlayerUi
local SecondPlayerUi = ModRequire "../SecondPlayerUI.lua"

local _OnHit = OnHit
function OnHit(args)
    -- Only one usage
    local fun = args[1]
    _OnHit { function(triggerArgs)
        local attacker = triggerArgs.AttackerTable
        local victim = triggerArgs.TriggeredByTable

        local isAttackerPlayer = attacker and CoopPlayers.IsPlayerHero(attacker)
        local isVictimPlayer = CoopPlayers.IsPlayerHero(victim)

        -- Disable PvP
        if isAttackerPlayer and isVictimPlayer then
            return
        end

        if isAttackerPlayer then
            HeroContext.RunWithHeroContext(attacker, fun, triggerArgs)
        elseif isVictimPlayer then
            HeroContext.RunWithHeroContext(victim, fun, triggerArgs)
        else
            fun(triggerArgs)
        end

        if isVictimPlayer then
            if victim == CoopPlayers.GetMainHero() then
                UpdateHealthUI()
            elseif victim == CoopPlayers.GetHero(2) then
                SecondPlayerUi.UpdateHealthUI()
            end
            if victim.Health <= 0 then
                CoopPlayers.OnPlayerDead(victim)
            end
        end
    end }
end

local _OnProjectileDeath = OnProjectileDeath
function OnProjectileDeath(args)
    local originalHandler = args[1]
    _OnProjectileDeath { function(triggerArgs)
        local attacker = triggerArgs.AttackerTable
        local isAttackerPlayer = attacker and CoopPlayers.IsPlayerHero(attacker)

        if triggerArgs.name == "RangedWeapon" then
            -- This hack disables PvP for red crystals
            local victim = triggerArgs.TriggeredByTable
            local isVictimPlayer = victim and CoopPlayers.IsPlayerHero(victim)

            if isAttackerPlayer and isVictimPlayer then
                triggerArgs.TriggeredByTable = nil
            end
        end

        if isAttackerPlayer then
            HeroContext.RunWithHeroContext(attacker, originalHandler, triggerArgs)
        else
            originalHandler(triggerArgs)
        end
    end }
end

local _OnWeaponFired = OnWeaponFired
function OnWeaponFired(args)
    local names, fun
    if type(args[1]) == "function" then
        fun = args[1]
    else
        names = args[1]
        fun = args[2]
    end

    local hook = function(triggerArgs)
        local attacker = triggerArgs.OwnerTable

        if CoopPlayers.IsPlayerHero(attacker) then
            HeroContext.RunWithHeroContext(attacker, fun, triggerArgs)
        else
            fun(triggerArgs)
        end
    end

    if names then
        _OnWeaponFired{names, hook}
    else
        _OnWeaponFired { hook }
    end
end
