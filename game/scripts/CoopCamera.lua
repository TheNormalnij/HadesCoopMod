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

---@private
CoopCamera.IgnoreHeroes = {}

function CoopCamera.InitHooks()
    HookUtils.wrap("CreateRoom", CoopCamera.CreateRoomWrapHook)
    HookUtils.onPostFunction("draw", CoopCamera.Update)
    HookUtils.onPostFunction("ExitNPCPresentation", CoopCamera.OnExitNPCPresentation)
    HookUtils.onPostFunction("PanCamera", CoopCamera.PanCameraPostHook)
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
        CoopCamera.ForceFocus(true)
        CoopCamera.Update()
    else
        CoopCamera.ForceFocus(false)
        CoopCamera.LockCameraOrig(args)
    end
end

---@private
function CoopCamera.OnExitNPCPresentation()
    -- Fixes wrong camera focus after some  NPC dialoges.
    -- E.g. after feeding the dog in the styx temple hub
    CoopCamera.LockCameraHook({ Id = CoopPlayers.GetMainHero().ObjectId })
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
        if hero and (wasRunFinished or not hero.IsDead) and not CoopCamera.IgnoreHeroes[hero] then
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

---@private
function CoopCamera.PanCameraPostHook(args)
    local id = args.Id or args.Ids
    if id then
        CoopCamera.ForceFocus(CoopPlayers.IsPlayerUnit(id))
    end
end

---@public
function CoopCamera.SetHeroIgnored(hero, state)
    if state then
        CoopCamera.IgnoreHeroes[hero] = state
    else
        CoopCamera.IgnoreHeroes[hero] = nil
    end
end

---@public
function CoopCamera.ResetIgnore()
    CoopCamera.IgnoreHeroes = {}
end

return CoopCamera
