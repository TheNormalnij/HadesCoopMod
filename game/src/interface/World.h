//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "Thing.h"
#include "../HookTable.h"

namespace SGG {
class Thing;

class World {
  public:
    Thing *GetActiveThing(size_t id) {
        return ((Thing * (__fastcall *)(void *, int)) HookTable::Instance().World_GetActiveThings)(
            this, id);
    }

    static World* Instance() {
        return ((World * (__fastcall *)()) HookTable::Instance().World_Instance)();
    }

};
} // namespace SGG