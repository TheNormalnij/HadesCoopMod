--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"
---@type ILootDelivery
local LootDelivery = ModRequire "../loot/LootInterface.lua"

local _OnUsed = OnUsed
OnUsed = function(args)
    if type(args[1]) == "function" then
        _OnUsed { function(triggerArgs)
            local hero = CoopPlayers.GetHeroByUnit(triggerArgs.UserId)
            local mainHero = HeroContext.GetDefaultHero()

            local functionName = triggerArgs.AttachedTable and triggerArgs.AttachedTable.OnUsedFunctionName
            if functionName == "UseEscapeDoor" and hero ~= mainHero then
                -- Pact door
                -- Disable control for a second player
                -- A second player in context resets weapon choice for a first player
                return;
            else
                HeroContext.RunWithHeroContext(
                    CoopPlayers.GetHeroByUnit(triggerArgs.UserId),
                    args[1],
                    triggerArgs
                )
            end
        end
        }
    elseif args[1] == "ConsumableItems" then
        _OnUsed {
            args[1],
            function(triggerArgs)
                local hero = CoopPlayers.GetHeroByUnit(triggerArgs.UserId)
                local item = triggerArgs.AttachedTable

                if not LootDelivery.CanUseHeroLoot(item, hero) then
                    return
                end

                if item.AddAmmo then
                    -- Do not let a player get the red crystal
                    -- when the player has full ammo
                    local current = GetWeaponProperty {
                        Id = triggerArgs.UserId,
                        WeaponName = "RangedWeapon",
                        Property = "Ammo"
                    } or 0
                    local max = GetWeaponMaxAmmo {
                        Id = triggerArgs.UserId,
                        WeaponName = "RangedWeapon"
                    } or 0

                    if current >= max then
                        if not item.coopDisableMagneto then
                            SetObstacleProperty({
                                Property = "Magnetism",
                                Value = 0,
                                DestinationId =
                                    item.ObjectId
                            })
                            item.coopDisableMagneto = true
                            thread(function()
                                wait(1.0)
                                SetObstacleProperty({
                                    Property = "Magnetism",
                                    Value = 3000,
                                    DestinationId = item.ObjectId
                                })
                                item.coopDisableMagneto = false
                            end)
                        end
                        return
                    end
                end

                HeroContext.RunWithHeroContext(
                    hero,
                    args[2],
                    triggerArgs
                )
            end
        }
    elseif args[1] == "Loot"  then
        _OnUsed({
            args[1],
            function(triggerArgs)
                local hero = CoopPlayers.GetHeroByUnit(triggerArgs.UserId)
                if not LootDelivery.CanUseHeroLoot(triggerArgs.AttachedTable, hero) then
                    return
                end

                -- Regenerate traits in loot
                -- Pregenerated loot can contains unsupported loot
                -- for a second hero
                triggerArgs.AttachedTable.UpgradeOptions = nil

                HeroContext.RunWithHeroContext(
                    hero,
                    args[2],
                    triggerArgs
                )
            end
        })
    else
        _OnUsed({
            args[1],
            function(triggerArgs)
                HeroContext.RunWithHeroContext(
                    CoopPlayers.GetHeroByUnit(triggerArgs.UserId),
                    args[2],
                    triggerArgs
                )
            end
        })
    end
end

local _OnActiveUseTarget = OnActiveUseTarget
OnActiveUseTarget = function(args)
    if type(args[1]) == "function" then
        _OnActiveUseTarget{
            function (triggerArgs)
                local hero = CoopPlayers.GetHeroByUnit(triggerArgs.UserId)
                local mainHero = HeroContext.GetDefaultHero()
                local functionName = triggerArgs.AttachedTable and triggerArgs.AttachedTable.OnUsedFunctionName
                if functionName == "UseEscapeDoor" and hero ~= mainHero then
                    return;
                end

                HeroContext.RunWithHeroContext(
                    hero,
                    args[1],
                    triggerArgs
                )
            end
        }
    else
        _OnActiveUseTarget(args)
    end
end

local _OnActiveUseTargetLost = OnActiveUseTargetLost
OnActiveUseTargetLost = function(args)
    if type(args[1]) == "function" then
        _OnActiveUseTargetLost {
            function(triggerArgs)
                local hero = CoopPlayers.GetHeroByUnit(triggerArgs.UserId)
                local mainHero = HeroContext.GetDefaultHero()
                local functionName = triggerArgs.AttachedTable and triggerArgs.AttachedTable.OnUsedFunctionName
                if functionName == "UseEscapeDoor" and hero ~= mainHero then
                    return;
                end

                HeroContext.RunWithHeroContext(
                    hero,
                    args[1],
                    triggerArgs
                )
            end
        }
    else
        _OnActiveUseTargetLost(args)
    end
end
