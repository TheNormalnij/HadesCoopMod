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
end

---@private
function SaveHooks.SaveWrapper(baseFun)
    local mainHero = CoopPlayers.GetMainHero()
    if mainHero then
        CurrentRun.Hero = mainHero

        for name, instance in HeroContextProxyStore.Iterator() do
            instance:MovePlayerDataToProxy(1)
        end

        baseFun()

        for name, instance in HeroContextProxyStore.Iterator() do
            instance:CleanProxyTable()
        end

        CurrentRun.Hero = nil
    else
        baseFun()
    end
end

return SaveHooks
