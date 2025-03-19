--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"
---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"

---@class SaveHooks
local SaveHooks = {}

function SaveHooks.InitHooks()
    HookUtils.wrap("Save", function(baseFun)
        local mainHero = HeroContext.GetDefaultHero()
        if mainHero then
            CurrentRun.Hero = mainHero
            baseFun()
            CurrentRun.Hero = nil
        else
            baseFun()
        end
    end)
end

return SaveHooks
