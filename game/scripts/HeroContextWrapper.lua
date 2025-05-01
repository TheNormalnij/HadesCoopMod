--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "CoopPlayers.lua"
---@type HeroContext
local HeroContext = ModRequire "HeroContext.lua"

---@class HeroContextWrapper
local HeroContextWrapper = {}

function HeroContextWrapper.WrapTriggerHero(name, argField)
    local original = _G[name]
    _G[name] = function(args)
        local names, fun
        if type(args[1]) == "function" then
            fun = args[1]
        else
            names = args[1]
            fun = args[2]
        end

        local hook = function(triggerArgs)
            local hero = triggerArgs[argField]

            if CoopPlayers.IsPlayerHero(hero) then
                HeroContext.RunWithHeroContext(hero, fun, triggerArgs)
            else
                fun(triggerArgs)
            end
        end

        if names then
            original { names, hook }
        else
            original { hook }
        end
    end
end

return HeroContextWrapper
