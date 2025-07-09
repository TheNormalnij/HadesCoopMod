--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

local SelectedGuiControl = {}

local function GetCurrentControl()
    local isMouseVisible = GetConfigOptionValue { Name = "UseMouse" } or
        not GetConfigOptionValue { Name = "UseGamepadGlyphs" }

    if isMouseVisible then
        return
        {
            Device = "Keyboard",
            ControllerId = -1,
        }
    else
        return
        {
            Device = "Gamepad",
            ControllerId = CoopGetPlayerGamepad(1),
        }
    end
end

local function TostringPlayerConfiguration(playerId)
    if SelectedGuiControl[playerId].Device == "Keyboard" then
        return GetDisplayName { Text = "CoopMenu_KbAndMouse" }
    else
        local index = SelectedGuiControl[playerId].ControllerId
        --return "Gamepad " .. index .. " - " .. CoopGetGamepadName(index)
        return GetDisplayName { Text = "CoopMenu_Gamepad", Param =  index }
    end
end

local MENU_STATE = {
    START = 0;
    PLAYER_ONE_SELECTED = 1,
    PLAYER_TWO_SELECTED = 2,
    INVALID_STATE_SECOND_KEYBOARD = 3,
    INVALID_STATE_SAME_DEVICE = 4,
}

local CURRENT_MENU_STATE

local START_BUTTON_MESSAGES = {
    "Let's play",
    "Go, go, go",
    "Start",
    "Let the Carnage Begin!",
    "Next",
    "Let's Roll!",
    "Game On!",
    "Adventure Awaits",
    "Initiate Chaos!",
    "Begin the Hunt!",
    "It's Time to Kick Gum and Chew Ass",
    "Fus Ro Dah!",
    "Let's Cause Trouble",
    "Press Start to Change Everything"
}

MainMenuAPIAddGamemode("Coop", function(name)
    SelectedGuiControl = {}

    local menu = CreateMenuScreen()
    menu:CreateBack(0.8)
    menu:CreateBackground("")
    menu:CreateTitleText()
    menu:SetLowerInputBlock(true)

    menu:CreateCancelButton(function()
        SetTempRuntimeData("Gamemode", nil)
        menu:ExitScreen()
    end)

    local message = CreateGUIComponentTextBox(menu)

    menu:AddReflection("mMessageText", message)

    local btn = CreateGUIComponentButton(menu)

    local function SetStage(state)
        CURRENT_MENU_STATE = state

        if state == MENU_STATE.START then
            message:SetTextLocalizationKey("CoopMenu_StartMessage")
            btn:SetTextLocalizationKey("CoopMenu_P1Press")
        elseif state == MENU_STATE.PLAYER_ONE_SELECTED then
            local template = GetDisplayName { Text = "CoopMenu_PlayerController" }
            local text = string.gsub(template, "%$(%w+)", { PlayerIndex = 1, Controller = TostringPlayerConfiguration(1) })

            message:SetText(text)
            btn:SetTextLocalizationKey("CoopMenu_P2Press")
        elseif state == MENU_STATE.PLAYER_TWO_SELECTED then
            local template = GetDisplayName { Text = "CoopMenu_PlayerController" }
            local text = string.gsub(template, "%$(%w+)", { PlayerIndex = 1, Controller = TostringPlayerConfiguration(1) })
            local text2 = string.gsub(template, "%$(%w+)", { PlayerIndex = 2, Controller = TostringPlayerConfiguration(2) })

            message:SetText(text .. "\n" .. text2)
            btn:SetText(START_BUTTON_MESSAGES[math.random(1, #START_BUTTON_MESSAGES)])
        elseif state == MENU_STATE.INVALID_STATE_SECOND_KEYBOARD then
            message:SetTextLocalizationKey("CoopMenu_ErrP1KBOnly")
            btn:SetTextLocalizationKey("CoopMenu_Again")
        elseif state == MENU_STATE.INVALID_STATE_SAME_DEVICE then
            message:SetTextLocalizationKey("CoopMenu_ErrDeviceCollision")
            btn:SetTextLocalizationKey("CoopMenu_Again")
        else
            message:SetText("Error description is missing :D")
            btn:SetTextLocalizationKey("CoopMenu_Again")
        end
    end

    SetStage(MENU_STATE.START)

    btn:AddActivationHandler(function()
        if CURRENT_MENU_STATE == MENU_STATE.START then
            SelectedGuiControl[1] = GetCurrentControl()
            SetStage(MENU_STATE.PLAYER_ONE_SELECTED)
        elseif CURRENT_MENU_STATE == MENU_STATE.PLAYER_ONE_SELECTED then
            SelectedGuiControl[2] = GetCurrentControl()

            if SelectedGuiControl[2].Device == "Keyboard" then
                SetStage(MENU_STATE.INVALID_STATE_SECOND_KEYBOARD)
            elseif SelectedGuiControl[1].Device == "Gamepad" and SelectedGuiControl[1].ControllerId == SelectedGuiControl[2].ControllerId then
                SetStage(MENU_STATE.INVALID_STATE_SAME_DEVICE)
            else
                SetStage(MENU_STATE.PLAYER_TWO_SELECTED)
            end
        elseif CURRENT_MENU_STATE == MENU_STATE.PLAYER_TWO_SELECTED then
            SetTempRuntimeData("Gamemode", name)
            SetTempRuntimeData("TN_Coop:control", SelectedGuiControl)
            MainMenuOpenProfiles()
        else
            SetStage(MENU_STATE.START)
        end
    end)

    menu:AddReflection("mControllerPress", btn)

    menu:LoadDefenitions("../Mods/TN_CoopMod/ControllerSelectionMenuScreen.sjson")
end)
