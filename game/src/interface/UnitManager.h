//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "Unit.h"

namespace SGG {
class UnitManager {
  public:
    static void Add(Unit *unit, bool needsInitialization) {
        ((void(__fastcall *)(Unit *, bool))HookTable::Instance().UnitManager_Add)(unit, needsInitialization);
    }

    static Unit* Get(int id) { return ((Unit * (__fastcall *)(int)) HookTable::Instance().UnitManager_Get)(id); }

    static Unit *CreatePlayerUnit(UnitData *unitData, Vectormath::Vector2 position, MapThing *mapThing,
                                  bool needsInitialization) {
        return ((Unit * (__fastcall *)(UnitData *, Vectormath::Vector2, MapThing *, bool)) HookTable::Instance()
             .UnitManager_CreatePlayerUnit)(unitData, position, mapThing, needsInitialization);
    }
};
} // namespace SGG