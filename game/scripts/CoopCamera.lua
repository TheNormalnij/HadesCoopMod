--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "CoopPlayers.lua"
---@type HookUtils
local HookUtils = ModRequire "HookUtils.lua"
---@type RunEx
local RunEx = ModRequire "RunEx.lua"

---@class CoopCamera
local CoopCamera = {}

---@private
CoopCamera.isFocusEnabled = true

function CoopCamera.InitHooks()
    HookUtils.wrap("CreateRoom", CoopCamera.CreateRoomWrapHook)
    HookUtils.onPostFunction("draw", CoopCamera.Update)
    CoopCamera.LockCameraOrig = LockCamera
    LockCamera = CoopCamera.LockCameraHook
end

---@param state boolean
function CoopCamera.ForceFocus(state)
    CoopCamera.isFocusEnabled = state
end

function CoopCamera.LockCameraHook(args)
    local mainPlayerId  = CoopPlayers.GetMainHero().ObjectId
    if mainPlayerId and args.Id == mainPlayerId then
        CoopCamera.isFocusEnabled = true
        CoopCamera.Update()
    else
        CoopCamera.isFocusEnabled = false
        CoopCamera.LockCameraOrig(args)
    end
end

---@private
function CoopCamera.Update()
    if not CoopCamera.isFocusEnabled then
        return
    end

    local units = {}

    -- It's bad
    -- Players are dead in prerun room
    local wasRunFinished = RunEx.IsRunEnded()

    for _, hero in CoopPlayers.PlayersIterator() do
        if hero and (wasRunFinished or not hero.IsDead) then
            table.insert(units, hero.ObjectId)
        end
    end

    if #units == 0 then
        return
    end

    UnlockCamera()
    CoopCamera.LockCameraOrig { Ids = units, Duration = 0.0 }
end

---@private
function CoopCamera.CreateRoomWrapHook(baseFunc, ...)
    local room = baseFunc(...)
    if not room.ZoomFraction then
        room.ZoomFraction = 0.6
    elseif room.ZoomFraction > 0.5 then
        room.ZoomFraction = room.ZoomFraction * 0.6
    end
    return room
end

return CoopCamera
