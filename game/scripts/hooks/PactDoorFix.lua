--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"

---@class PactDoorFix
local PactDoorFix = {}

---@param units number[]
---@param elementId number
---@param distance number
---@return number[]
local function FilterUnitsNear(units, elementId, distance)
    local out = {}
    for _, unit in pairs(units) do
        if GetDistance{ Id = unit, DestinationId = elementId } <= distance then
            table.insert(out, unit)
        end
    end
    return out
end

function PactDoorFix.SetupPactDoor(room, entranceId, contractId)
    local openDistance = 600 - 30
    local closeDistance = 600 + 30

    local units = CoopPlayers.GetUnits()

    while CurrentDeathAreaRoom and CurrentDeathAreaRoom.Name == room.Name do
        NotifyWithinDistanceAny{
            Ids = { entranceId },
            DestinationIds = units,
            Distance = openDistance,
            Notify = "ContractOpen"
        }

        local who = NotifyResultsTable.ContractOpen

        waitUntil("ContractOpen")

        SetAnimation({ Name = "HouseContractOpen", DestinationId = contractId })

        local playersInside = { who }

        while #playersInside > 0 do
            NotifyOutsideDistance{
                Id = entranceId,
                DestinationId = playersInside[1],
                Distance = closeDistance,
                Notify = "ContractClose"
            }

            waitUntil("ContractClose")

            playersInside = FilterUnitsNear(units, entranceId, closeDistance)
        end

        SetAnimation({ Name = "HouseContractClose", DestinationId = contractId })
        wait(0.01)
    end

end

function PactDoorFix.InitHooks()
    SetupPactDoor = PactDoorFix.SetupPactDoor
end

return PactDoorFix