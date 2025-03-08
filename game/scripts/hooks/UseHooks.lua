---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"

local ON_USED_SELECT_HERO = {
    WeaponKit01 = true, -- Weapon selector in hub room
    WeaponShop = true,  -- Charon well
    Loot = true,        -- Hammer/Boons
}

local _OnUsed = OnUsed
OnUsed = function(args)
    if type(args[1]) == "function" then
        -- Hack fot OnUsed in Interactables.lua
        return _OnUsed(args)
    end

    if ON_USED_SELECT_HERO[args[1]] then
        _OnUsed({
            args[1],
            function(triggerArgs)
                DebugPrint { Text = "on used ON_USED_SELECT_HERO: " .. tostring(args[1]) }

                HeroContext.RunWithHeroContext(
                    CoopPlayers.PlayerUnitIdToHero[triggerArgs.UserId] or HeroContext.GetDefaultHero(),
                    args[2],
                    triggerArgs
                )
            end
        })
        return
    end

    if args[1] == "ConsumableItems" then
        _OnUsed {
            args[1],
            function(triggerArgs)
                local hero = CoopPlayers.PlayerUnitIdToHero[triggerArgs.UserId] or HeroContext.GetDefaultHero()
                local item = triggerArgs.AttachedTable

                if item.AddAmmo then
                    -- Do not let a player get the red crystal
                    -- when the player has full ammo
                    local current = GetWeaponProperty {
                        Id = triggerArgs.UserId,
                        WeaponName = "RangedWeapon",
                        Property = "Ammo"
                    }
                    local max = GetWeaponMaxAmmo {
                        Id = triggerArgs.UserId,
                        WeaponName = "RangedWeapon"
                    }

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
        return
    end

    _OnUsed { args[1], function(triggerArgs)
        DebugPrint { Text = "OnUsed: " .. args[1] }
        args[2](triggerArgs)
    end }
end
