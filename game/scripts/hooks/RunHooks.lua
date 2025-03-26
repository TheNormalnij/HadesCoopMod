--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"
---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"
---@type CoopCamera
local CoopCamera = ModRequire "../CoopCamera.lua"

---@class RunHooks
local RunHooks = {}

function RunHooks.InitHooks()
    RunHooks.InitRunHooks()
    RunHooks.InitStartRoomHooks()
    RunHooks.CreateRoomHooks()
    HookUtils.onPreFunction("LeaveRoom", RunHooks.LeaveRoomHook)
end

---@private
function RunHooks.InitStartRoomHooks()
    local _StartRoom = StartRoom

    function StartRoom(run, currentRoom)
        local playersCount = CoopGetPlayersCount()

        DebugPrint { Text = "StartRoom with players " .. playersCount }
        if playersCount <= 1 then
            _StartRoom(run, currentRoom)
            return
        end

        local prevRoom = GetPreviousRoom(CurrentRun)
        local roomEntranceFunctionName = currentRoom.EntranceFunctionName or "RoomEntranceStandard"
        if prevRoom ~= nil and prevRoom.NextRoomEntranceFunctionName ~= nil then
            roomEntranceFunctionName = prevRoom.NextRoomEntranceFunctionName
        end
        local args = currentRoom.EntranceFunctionArgs

        HookUtils.onPostFunctionOnce(roomEntranceFunctionName, function()
            local entranceFunction = _G[roomEntranceFunctionName]
            --entranceFunction(currentRun, currentRoom, args)
            -- TODO ADD ENTER Animation
            CoopPlayers.InitCoopUnit(2)
            CoopPlayers.UpdateMainHero()
            CoopCamera.ForceFocus(true)

            if currentRoom.HeroEndPoint then
                for playerId = 2, CoopPlayers.GetPlayersCount() do
                    Teleport({ Id = CoopPlayers.GetHero(playerId).ObjectId, DestinationId = currentRoom.HeroEndPoint })
                end
            end
        end)

        _StartRoom(run, currentRoom)
    end
end

---@private
function RunHooks.InitRunHooks()
    local _StartNewRun = StartNewRun
    StartNewRun = function(prevRun, args)
        local newRun = _StartNewRun(prevRun, args)
        HeroContext.InitRunHook()
        CoopPlayers.SetMainHero(HeroContext.GetDefaultHero())

        return newRun
    end
end

---@private
function RunHooks.CreateRoomHooks()
    _CreateRoom = CreateRoom
    CreateRoom = function(...)
        local room = _CreateRoom(...)
        if not room.ZoomFraction then
            room.ZoomFraction = 0.6
        elseif room.ZoomFraction > 0.5 then
            room.ZoomFraction = room.ZoomFraction * 0.6
        end

        return room
    end
end

-- Disables an extit door after use
---@private
function RunHooks.LeaveRoomHook(currentRun, door)
    door.ReadyToUse = false
end

return RunHooks
