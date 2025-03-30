--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type HeroContext
local HeroContext = ModRequire "HeroContext.lua"

---@class HeroContextProxy
local HeroContextProxy = {}

---@param target table
function HeroContextProxy.Make(target)
    local separatedData = {}

    local function getTableForCurrentHero()
        local hero = HeroContext.GetCurrentHeroContext()
        local t = separatedData[hero]
        if t then
            return t
        else
            t = {}
            separatedData[hero] = t
            return t
        end
    end

    local contextMt = {
        __index = function(self, key)
            return getTableForCurrentHero()[key]
        end,
        __newindex = function(self, key, value)
            getTableForCurrentHero()[key] = value
        end,

        __pairs = function()
            return pairs(getTableForCurrentHero())
        end,

        __ipairs = function()
            return ipairs(getTableForCurrentHero())
        end,

        __len = function()
            return #getTableForCurrentHero()
        end
    }

    setmetatable(target, contextMt)
end

return HeroContextProxy
