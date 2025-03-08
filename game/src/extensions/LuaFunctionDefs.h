//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "PlayerManagerExtension.h"

class lua_State;

class LuaFunctionDefs {
  public:
    static void Load(lua_State *L);
};
