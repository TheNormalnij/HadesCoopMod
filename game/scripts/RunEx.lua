--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@class RunEx
local RunEx = {}

---@return boolean
function RunEx.IsRunEnded()
    -- The game sets EndingMoney in state after death
    -- So we can use this value to check if the run was finished
    return CurrentRun.EndingMoney and true
end

---@return boolean
function RunEx.WasTheFirstRunStarted()
    return not GameState or (not CurrentRun and IsEmpty(GameState.RunHistory))
end

---@return boolean
function RunEx.IsStyxTempleHubRoom(room)
    return room.Name == "D_Hub"
end

---@return boolean
function RunEx.IsShopRoomName(name)
    return name == "A_Shop01" or name == "B_Shop01" or name == "C_Shop01"
end

---@return boolean
function RunEx.IsStoryRoomName(name)
    return name == "A_Story01" or name == "B_Story01" or name == "C_Story01"
end

---@return boolean
function RunEx.IsFinalBossDoor(door)
    return door.ForceRoomName == "D_Boss01"
end

function RunEx.RemoveDoorReward(door)
    if door.DoorIconId ~= nil then
        Destroy { Id = door.DoorIconBackingId }
        Destroy { Id = door.DoorIconId }
        Destroy { Id = door.DoorIconFront }
        Destroy { Ids = door.AdditionalIcons }
        Destroy { Ids = door.AdditionalAttractIds }

        door.DoorIconBackingId = nil
        door.DoorIconId = nil
        door.DoorIconFront = nil
        door.AdditionalIcons = {}
        door.AdditionalAttractIds = {}
    end

    local room = door.Room
    room.ForceLootName = nil
    room.RewardOverrides = nil
end

function RunEx.RemoveRewardFromAllDefaultDoors()
    for _, door in pairs(OfferedExitDoors) do
        if door.IsDefaultDoor then
            RunEx.RemoveDoorReward(door)
        end
    end
end

return RunEx
