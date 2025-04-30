--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@class CoopControl
local CoopControl = {}

---@alias ControlSchema "Current" | "Default" | "UserDefined"
-- Default - mod default values
-- UserDefined - User values
-- Current - user values updated in runtime
---@private
CoopControl.Schemas = {
    Default = {
        {
            Device = "Keyboard",
            ControllerId = -1,
        };
        {
            Device = "Gamepad",
            ControllerId = 0,
        };
    };
    UserDefined = {};
    Current = {};
}

function CoopControl.InitControlSchemas()
    CoopControl.Schemas.UserDefined = eat_true(GetTempRuntimeData("TN_Coop:control"))
    CoopControl.Schemas.Current = DeepCopyTable(CoopControl.Schemas.UserDefined)

    SetConfigOption { Name = "AllowControlHotSwap", Value = false }
    CoopControl.ResetAllPlayers("UserDefined")
end

---@private
---@param playerId integer
---@param shemaName ControlSchema
function CoopControl.SetPlayerControlSchema(playerId, shemaName)
    local shema = CoopControl.Schemas[shemaName][playerId]

    if playerId == 1 then
        local withMouse = shema.Device == "Keyboard"
        SetConfigOption { Name = "UseMouse", Value = withMouse }
    end
    CoopSetPlayerGamepad(playerId, shema.ControllerId)
end

-- We need first change player 1 controller to requested player controller
-- So the player 2 will control the menu
---@param playerId number
function CoopControl.SwitchControlForMenu(playerId)
    local controllerId = CoopControl.Schemas.Current[playerId].ControllerId

    CoopSetPlayerGamepad(1, controllerId)
    for playerId = 2, #CoopControl.Schemas.Current do
        CoopSetPlayerGamepad(playerId, -1)
    end
end

---@param schema ControlSchema?
function CoopControl.ResetAllPlayers(schema)
    schema = schema or "Current"
    for playerId in pairs(CoopControl.Schemas.Current) do
        CoopControl.SetPlayerControlSchema(playerId, "Current")
    end
end

function CoopControl.Reset(playerId)
    CoopControl.SetPlayerControlSchema(playerId, "Current")
end

return CoopControl
