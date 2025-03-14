--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"

---@class FreezeHooks
local FreezeHooks = {}

function FreezeHooks.InitHooks()
    local _FreezePlayerUnit = FreezePlayerUnit
    local _UnfreezePlayerUnit = UnfreezePlayerUnit

    function FreezePlayerUnit(...)
        for _, hero in pairs(CoopPlayers.CoopHeroes) do
            HeroContext.RunWithHeroContext(hero, _FreezePlayerUnit, ...)
        end
    end

    function UnfreezePlayerUnit(...)
        for _, hero in pairs(CoopPlayers.CoopHeroes) do
            HeroContext.RunWithHeroContext(hero, _UnfreezePlayerUnit, ...)
        end
    end
end

return FreezeHooks
