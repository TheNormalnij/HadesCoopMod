--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"
---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"
---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HeroContextProxyStore
local HeroContextProxyStore = ModRequire "../HeroContextProxyStore.lua"

---@class ResourceLoadingHooks
local ResourceLoadingHooks = {}

function ResourceLoadingHooks.InitHooks()
    HookUtils.wrap("LoadSpawnPackages", function(baseFun, encounter)
        for playerId, hero in CoopPlayers.PlayersIterator() do
            HeroContext.RunWithHeroContext(hero, baseFun, encounter)
        end
    end)

    HookUtils.onPostFunction("DoPatches", function()
        local lootHistory = HeroContextProxyStore.Get("LootTypeHistory")

        if not lootHistory then
            return
        end

        for playerId = 1, CoopPlayers.GetPlayersCount() do
            for lootName, i in pairs(lootHistory:GetPlayerData(playerId)) do
                if not GameData.MissingPackages[lootName] then
                    LoadPackages{ Name = lootName }
                end
            end
        end
    end )
end

return ResourceLoadingHooks
