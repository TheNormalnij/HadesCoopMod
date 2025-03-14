--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"

local _NotifyWithinDistance = NotifyWithinDistance
NotifyWithinDistance = function(params)
    if CoopPlayers.IsPlayerUnit(params.DestinationId) then
        for playerId = 1, CoopPlayers.GetPlayersCount() do
            local hero = CoopPlayers.GetHero(playerId)
            if hero and hero.ObjectId then
                params.DestinationId = hero.ObjectId
                DebugPrint { Text = "Add with" }
                _NotifyWithinDistance(params)
            end
        end
    else
        DebugPrint { Text = "Add without" }
        _NotifyWithinDistance(params)
    end
end
