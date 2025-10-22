--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"
---@type HeroContextProxyStore
local HeroContextProxyStore = ModRequire "../HeroContextProxyStore.lua"

---@class SaveHooks
local SaveHooks = {}

function SaveHooks.InitHooks()
    HookUtils.wrap("Save", SaveHooks.SaveWrapper)
    HookUtils.onPreFunction("DoPatches", SaveHooks.DoPatchesPreHook)
end

---@private
function SaveHooks.SaveWrapper(baseFun)
    local mainHero = CoopPlayers.GetMainHero()
    if mainHero then
        CurrentRun.Hero = mainHero
        SaveHooks.ApplyMainHeroDeathWorkaround()

        for name, instance in HeroContextProxyStore.Iterator() do
            instance:MovePlayerDataToProxy(1)
        end

        baseFun()

        for name, instance in HeroContextProxyStore.Iterator() do
            instance:CleanProxyTable()
        end

        SaveHooks.RemoveMainHeroDeathWorkaround()

        CurrentRun.Hero = nil
    else
        baseFun()
    end
end

---@private
function SaveHooks.DoPatchesPreHook()
    local hero = CurrentRun and CurrentRun.CoopWorkaroundMainHero
    if hero then
        CurrentRun.Hero = hero
        SaveHooks.RemoveMainHeroDeathWorkaround()
    end
end

---@private
function SaveHooks.ApplyMainHeroDeathWorkaround()
    local hero = CurrentRun and CurrentRun.Hero
    if hero.IsDead then
        CurrentRun.CoopWorkaroundMainHero = hero
        local safeHero = CoopPlayers.GetFirstAliveHero() or hero
        CurrentRun.Hero = safeHero

        local location = GetLocation{ Id = safeHero.ObjectId }
        RecordObjectState(CurrentRun.CurrentRoom, hero.ObjectId, "Location", location)
    end
end

---@private
function SaveHooks.RemoveMainHeroDeathWorkaround()
    CurrentRun.CoopWorkaroundMainHero = nil
end

return SaveHooks
