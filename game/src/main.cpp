//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#include "pch.h"

#include "../include/HadesModApi.h"
#include "CoopContext.h"
#include "CoopLog.h"

HADES_MOD_API void _cdecl HadesModLuaCreated(lua_State *luaState) {CoopContext::GetInstance()->InitLua(luaState); };

HADES_MOD_API bool _cdecl HadesModInit(const IModApi *modApi) {
    if (modApi->version < MOD_API_VERSION)
        return false;

    CoopLog::Init();
    HookTable::Instance().Init(modApi->GetSymbolAddress);
    CoopLog::Write("symbols: AddPlayer=%llx AssignController=%llx PlayerVector_Resize=%llx",
                   (unsigned long long)HookTable::Instance().PlayerManager_AddPlayer,
                   (unsigned long long)HookTable::Instance().PlayerManager_AssignController,
                   (unsigned long long)HookTable::Instance().PlayerVector_Resize);

    return true;
};

HADES_MOD_API bool _cdecl HadesModStart() { return true; };

HADES_MOD_API bool _cdecl HadesModStop() { return true; };
