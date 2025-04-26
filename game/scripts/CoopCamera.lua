--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "CoopPlayers.lua"
---@type HookUtils
local HookUtils = ModRequire "HookUtils.lua"

---@class CoopCamera
local CoopCamera = {}

---@private
CoopCamera.isFocusEnabled = true

function CoopCamera.InitHooks()
    HookUtils.onPostFunction("draw", CoopCamera.Update)
    CoopCamera.LockCameraOrig = LockCamera
    LockCamera = CoopCamera.LockCamaraHook
end

---@param state boolean
function CoopCamera.ForceFocus(state)
    CoopCamera.isFocusEnabled = state
end

function CoopCamera.LockCamaraHook(args)
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
    -- the game sets EndingMoney in state after death
    -- So we can use this value to check if the run was finished
    local wasRunFinished = CurrentRun.EndingMoney and true

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

return CoopCamera
