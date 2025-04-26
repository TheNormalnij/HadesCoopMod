//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#include "pch.h"
#include "LuaFunctionDefs.h"
#include "CoopContext.h"
#include "lua.hpp"
#include "interface/Gamepad.h"

#include <windows.h>

// bool CoopSetPlayerGamepad(number playerIndex, number controllerIndex)
static int CoopSetPlayerGamepad(lua_State *L) {
    if (!lua_isnumber(L, 1)) {
        return luaL_error(L, "Argument 1 must be a number");
    }

    if (!lua_isnumber(L, 2)) {
        return luaL_error(L, "Argument 2 must be a number");
    }

    size_t playerIndex = static_cast<size_t>(lua_tonumber(L, 1)) - 1;
    uint8_t controllerIndex = static_cast<uint8_t>(lua_tonumber(L, 2));

    bool result = CoopContext::GetInstance()->GetPlayerManager().AssignGamepad(playerIndex, controllerIndex);

    lua_pushboolean(L, result);
    return 1;
}

// number CoopGetPlayerGamepad(number playerIndex)
static int CoopGetPlayerGamepad(lua_State *L) {
    if (!lua_isnumber(L, 1)) {
        return luaL_error(L, "Argument 1 must be a number");
    }

    size_t playerIndex = static_cast<size_t>(lua_tonumber(L, 1)) - 1;
    size_t result = CoopContext::GetInstance()->GetPlayerManager().GetGamepad(playerIndex);

    lua_pushnumber(L, result);
    return 1;
}

// number CoopGetGamepadName(number controllerIndex)
static int CoopGetGamepadName(lua_State *L) {
    if (!lua_isnumber(L, 1)) {
        return luaL_error(L, "Argument 1 must be a number");
    }

    uint8_t index = static_cast<uint8_t>(lua_tonumber(L, 1));
    lua_pushstring(L, SGG::getGamePadNameForIndex(index));
    return 1;
}

// number CoopGetPlayersCount()
static int CoopGetPlayersCount(lua_State *L) {
    size_t playersCount = CoopContext::GetInstance()->GetPlayerManager().GetPlayersCount();

    lua_pushnumber(L, playersCount);
    return 1;
}

// number CoopCreatePlayer()
static int CoopCreatePlayer(lua_State *L) {
    size_t playerIndex = CoopContext::GetInstance()->CreatePlayer();

    if (playerIndex != -1)
        lua_pushnumber(L, playerIndex + 1);
    else
        lua_pushboolean(L, false);

    return 1;
}

// bool CoopCreatePlayer(number playerIndex)
static int CoopRemovePlayer(lua_State *L) {
    if (!lua_isnumber(L, 1)) {
        return luaL_error(L, "Argument 1 must be a number");
    }

    size_t playerIndex = static_cast<size_t>(lua_tonumber(L, 1)) - 1;

    bool result = CoopContext::GetInstance()->RemovePlayer(playerIndex);
    lua_pushboolean(L, result);

    return 1;
}

// bool CoopCreatePlayer()
static int CoopHasPlayer(lua_State *L) {
    if (!lua_isnumber(L, 1)) {
        return luaL_error(L, "Argument 1 must be a number");
    }

    size_t playerIndex = static_cast<size_t>(lua_tonumber(L, 1)) - 1;
    bool status = CoopContext::GetInstance()->GetPlayerManager().HasPlayer(playerIndex);

    lua_pushboolean(L, status);

    return 1;
}

// number/false CoopCreatePlayer(number playerIndex)
static int CoopCreatePlayerUnit(lua_State* L) {
    if (!lua_isnumber(L, 1)) {
        return luaL_error(L, "Argument 1 must be a number");
    }

    size_t playerIndex = static_cast<size_t>(lua_tonumber(L, 1)) - 1;

    size_t unitId = CoopContext::GetInstance()->CreatePlayerUnit(playerIndex);

    if (unitId != -1)
        lua_pushnumber(L, unitId);
    else
        lua_pushboolean(L, false);

    return 1;
}

// bool CoopCreatePlayer(number playerIndex)
static int CoopRemovePlayerUnit(lua_State *L) {
    if (!lua_isnumber(L, 1)) {
        return luaL_error(L, "Argument 1 must be a number");
    }

    size_t playerIndex = static_cast<size_t>(lua_tonumber(L, 1)) - 1;

    bool result = CoopContext::GetInstance()->RemovePlayerUnit(playerIndex);
    lua_pushboolean(L, result);

    return 1;
}

// bool CoopUseItem(number playerUnit, number lootUnit)
static int CoopUseItem(lua_State* L) {
    if (!lua_isnumber(L, 1)) {
        return luaL_error(L, "Argument 1 must be a number");
    }

    if (!lua_isnumber(L, 2)) {
        return luaL_error(L, "Argument 2 must be a number");
    }

    size_t playerUnit = static_cast<size_t>(lua_tonumber(L, 1));
    size_t thingUnit = static_cast<size_t>(lua_tonumber(L, 2));

    bool result = CoopContext::GetInstance()->UseItem(playerUnit, thingUnit);
    lua_pushboolean(L, result);

    return 1;
}

void LuaFunctionDefs::Load(lua_State* L) {
    #define REGISTER(fun) lua_register(L, #fun, fun)

    REGISTER(CoopSetPlayerGamepad);
    REGISTER(CoopGetPlayerGamepad);
    REGISTER(CoopGetGamepadName);

    REGISTER(CoopGetPlayersCount);
    REGISTER(CoopCreatePlayer);
    REGISTER(CoopRemovePlayer);
    REGISTER(CoopHasPlayer);

    REGISTER(CoopCreatePlayerUnit);
    REGISTER(CoopRemovePlayerUnit);
    REGISTER(CoopUseItem);

    #undef REGISTER
}
