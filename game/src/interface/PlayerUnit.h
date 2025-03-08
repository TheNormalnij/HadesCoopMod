//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "Entity.h"
#include "HookTable.h"
#include "MapThing.h"
#include "Unit.h"
#include "UnitData.h"

namespace SGG {
__declspec(align(16)) class PlayerUnit : public Unit {
  public:
    static void internal_constructor(void *pos, SGG::Entity entity, SGG::UnitData *data, SGG::MapThing *mapThing,
                                     Vectormath::Vector2 location) {
        ((void(__fastcall *)(void *, SGG::Entity, SGG::UnitData *, SGG::MapThing *,
                             Vectormath::Vector2))HookTable::Instance()
             .PlayerUnit_PlayerUnit)(pos, entity, data, mapThing, location);
    };

    uint8_t pad[0x10];
};
#ifdef HADES2
static_assert(sizeof(PlayerUnit) == 0x850, "Incorrect SGG::PlayerUnit size");
#else
static_assert(sizeof(PlayerUnit) == 0x570, "Incorrect SGG::PlayerUnit size");
#endif
} // namespace SGG
