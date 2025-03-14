--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"

local _SaveCheckpoint = SaveCheckpoint

SaveCheckpoint = function(args)
    local mainHero = CoopPlayers.GetMainHero()
    if mainHero then
        CurrentRun.Hero = mainHero
        _SaveCheckpoint(args)
        CurrentRun.Hero = nil
    else
        _SaveCheckpoint(args)
    end
end
