--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"

-- Fixes crashes when the game unload weapons that is currently equipped by another player
HookUtils.wrap("UnequipWeapon", function (baseFunc, args)
    if args.UnloadPackages == false then
        return baseFunc(args)
    end

    local toRemove = args.Names or { args.Name }

    local unit = args.DestinationId
    local hasAnotherPlayerThisWeapon = false

    for playerId, hero in CoopPlayers.PlayersIterator() do
        if hero.ObjectId == unit then
            goto continue
        end

        for _, name in ipairs(toRemove) do
            if hero.Weapons[name] then
                hasAnotherPlayerThisWeapon = true
                break
            end
        end

        ::continue::
    end

    args.UnloadPackages = not hasAnotherPlayerThisWeapon
    args.UnloadPackages = false

    return baseFunc(args)
end)

HookUtils.wrap("PreLoadBinks", function(baseFun, args)
    if args.Cache == "WeaponCache" then
        return baseFun {
            Names = args.Names
            -- Do not reset
        }
    else
        return baseFun(args)
    end
end)
