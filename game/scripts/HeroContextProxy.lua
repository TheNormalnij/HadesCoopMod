--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type HeroContext
local HeroContext = ModRequire "HeroContext.lua"
---@type CoopPlayers
local CoopPlayers = ModRequire "CoopPlayers.lua"
---@type TableUtils
local TableUtils = ModRequire "TableUtils.lua"

---@class HeroContextProxy
---@field private separatedData table[]
---@field private target table
local HeroContextProxy = {}

---@param owner table
---@param keyInOwner string
---@return HeroContextProxy
function HeroContextProxy.New(owner, keyInOwner)
    local target = owner[keyInOwner]

    local handler = {
        separatedData = {};
        target = target;
    }
    setmetatable(handler, { __index = HeroContextProxy })

    local separatedData = handler.separatedData

    for playerId = 1, CoopPlayers.GetPlayersCount() do
        local playerKey = keyInOwner .. "CoopPlayer" .. playerId
        local data = owner[playerKey]  or {}
        separatedData[playerId] = data
        owner[playerKey] = data
    end

    handler:MoveDataToContext(1)

    local function getTableForCurrentHero()
        local hero = HeroContext.GetCurrentHeroContext()
        local playerId = CoopPlayers.GetPlayerByHero(hero) or 1
        return separatedData[playerId]
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

    return handler
end

---@private
---@param playerId integer
function HeroContextProxy:MoveDataToContext(playerId)
    local dataInContext = self.separatedData[playerId]

    TableUtils.copyTo(dataInContext, self.target)
    TableUtils.clean(self.target)
end

---@param playerId number
function HeroContextProxy:MovePlayerDataToProxy(playerId)
    local dataFrom = self.separatedData[playerId]

    if not dataFrom then
        return
    end

    TableUtils.rawCopyTo(self.target, dataFrom)
end

---@param playerId integer
function HeroContextProxy:GetPlayerData(playerId)
    return self.separatedData[playerId]
end

function HeroContextProxy:CleanProxyTable()
    TableUtils.clean(self.target)
end

return HeroContextProxy
