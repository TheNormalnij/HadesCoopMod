//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#include "pch.h"

#include "../include/HadesModApi.h"
#include "CoopContext.h"

HADES_MOD_API void _cdecl HadesModLuaCreated(lua_State *luaState) {CoopContext::GetInstance()->InitLua(luaState); };

HADES_MOD_API bool _cdecl HadesModInit(const IModApi *modApi) {
    if (modApi->version < MOD_API_VERSION)
        return false;

    if (modApi->gameVariant == eGameVariant::VULKAN)
        HookTable::Instance().ApplySteamVk();

    HookTable::Instance().ApplyOffset(modApi->GetGameDllOffset());

    return true;
};

HADES_MOD_API bool _cdecl HadesModStart() { return true; };

HADES_MOD_API bool _cdecl HadesModStop() { return true; };
