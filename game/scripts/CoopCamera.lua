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

function CoopCamera.InitHooks()
    CoopCamera.InitZoomHook()
    CoopCamera.AddCameraUpdater()

end

---@private
function CoopCamera.InitZoomHook()
    local _AdjustZoom = AdjustZoom
    AdjustZoom = function(args)
        local faction = args.Fraction or 1.0
        if faction < 1.5 then
            faction = faction * 0.60
        end
        args.Fraction = faction
        _AdjustZoom(args)
    end
end

---@private
function CoopCamera.AddCameraUpdater()
    HookUtils.onPostFunction("draw", function ()
        local secondPlayer = CoopPlayers.GetHero(2)
        if secondPlayer then
            local mainPlayer = CoopPlayers.GetMainHero()
            UnlockCamera()
            LockCamera { Ids = { mainPlayer.ObjectId, secondPlayer.ObjectId }, Duration = 0.0 }
        end
    end)
end

return CoopCamera
