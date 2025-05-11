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
---@type HeroContextWrapper
local HeroContextWrapper = ModRequire "../HeroContextWrapper.lua"

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
        end
    end }
end

local _OnProjectileDeath = OnProjectileDeath
function OnProjectileDeath(args)
    local originalHandler = args[1]

    _OnProjectileDeath { function(triggerArgs)
        local attacker = triggerArgs.AttackerTable
        local isAttackerPlayer = attacker and CoopPlayers.IsPlayerHero(attacker)
        local victim = triggerArgs.TriggeredByTable
        local isVictimPlayer = victim and CoopPlayers.IsPlayerHero(victim)

        if triggerArgs.name == "RangedWeapon" then
            -- This hack disables PvP for red crystals
            if isAttackerPlayer and isVictimPlayer then
                triggerArgs.TriggeredByTable = nil
            end
        end

        if isAttackerPlayer then
            HeroContext.RunWithHeroContext(attacker, originalHandler, triggerArgs)
        elseif isVictimPlayer then
            HeroContext.RunWithHeroContext(victim, originalHandler, triggerArgs)
        else
            originalHandler(triggerArgs)
        end
    end }
end

HeroContextWrapper.WrapTriggerHero("OnWeaponFired", "OwnerTable")
HeroContextWrapper.WrapTriggerHero("OnWeaponTriggerRelease", "OwnerTable")
HeroContextWrapper.WrapTriggerHero("OnWeaponFailedToFire", "TriggeredByTable")
HeroContextWrapper.WrapTriggerHero("OnWeaponCharging", "OwnerTable")
HeroContextWrapper.WrapTriggerHero("OnWeaponChargeCanceled", "OwnerTable")
HeroContextWrapper.WrapTriggerHero("OnPerfectChargeWindowEntered", "OwnerTable")
