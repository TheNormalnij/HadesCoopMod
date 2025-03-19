--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "CoopPlayers.lua"
---@type HookUtils
local HookUtils = ModRequire "HookUtils.lua"
---@type HeroContext
local HeroContext = ModRequire "HeroContext.lua"

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
    if args.Id == 40000 then
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

    local secondPlayer = CoopPlayers.GetHero(2)
    if secondPlayer then
        local mainPlayer = CoopPlayers.GetMainHero()
        UnlockCamera()
        CoopCamera.LockCameraOrig { Ids = { mainPlayer.ObjectId, secondPlayer.ObjectId }, Duration = 0.0 }
    end
end

return CoopCamera
