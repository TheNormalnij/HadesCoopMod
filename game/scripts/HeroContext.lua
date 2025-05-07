--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@class HeroContext
local HeroContext = {}

local CorontinueToHero = setmetatable({}, { __mode ="k" })

local defaultHero

local RunMT = {
    __index = function(self, key)
        if key == "Hero" then
            return HeroContext.GetCurrentHeroContext()
        end

        return rawget(self, key)
    end;
}

local coroutine_create = coroutine.create
coroutine.create = function(...)
    local hero = HeroContext.GetCurrentHeroContext()

    local co = coroutine_create(...)
    CorontinueToHero[co] = hero

    return co
end

function HeroContext.InitRunHook()
    if not CurrentRun.Hero then
        error("Current run has no hero")
    end

    defaultHero = CurrentRun.Hero
    CurrentRun.Hero = nil
    setmetatable(CurrentRun, RunMT)
end

function HeroContext.GetCurrentHeroContext()
    local thread, isMain = coroutine.running()
    if not isMain then
        return CorontinueToHero[thread] or defaultHero
    end

    return defaultHero
end

function HeroContext.IsHeroContextExplicit()
    local thread, isMain = coroutine.running()
    if not isMain then
        return CorontinueToHero[thread] and true
    end
    return false
end

function HeroContext.SetDefaultHero(hero)
    defaultHero = hero
end

function HeroContext.GetDefaultHero()
    return defaultHero
end

---@param hero table Hero info
---@param fun function
---@param ... unknown params
function HeroContext.RunWithHeroContext(hero, fun, ...)
    local args = {...}
    local co = coroutine_create(function()
        fun(table.unpack(args))
    end)
    CorontinueToHero[co] = hero
    --coroutine.resume(co, ...)
    resume(co, _threads)
end

---@param hero table Hero info
---@param fun function
---@param ... unknown params
---@return unknown
function HeroContext.RunWithHeroContextReturn(hero, fun, ...)
    local out = {}
    HeroContext.RunWithHeroContext(hero, function(...)
        out = { fun(...) }
    end, ...)

    return table.unpack(out)
end

local awaitableThreadId = 0

---@param hero table Hero info
---@param fun function
---@param ... unknown params
function HeroContext.RunWithHeroContextAwait(hero, fun, ...)
    awaitableThreadId = awaitableThreadId + 1
    local notifyName = "RunWithHeroContextAwait" .. awaitableThreadId

    local args = { ... }
    local co = coroutine_create(function()
        fun(table.unpack(args))
        notifyExistingWaiters(notifyName)
    end)
    CorontinueToHero[co] = hero

    if resume(co, _threads) ~= "done" then
        waitUntil(notifyName)
    end
end

return HeroContext
