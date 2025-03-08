//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "HashGuid.h"

namespace SGG {
class MapThingDef {
  public:
    HashGuid GetName() const { return mName; };
    void SetId(uint32_t id) { mId = id; };

  private:
    uint8_t mDataType;
    uint8_t pad1[3];
    HashGuid mName;
    Vectormath::Vector2 mLocation;
    uint32_t mId;
#ifdef HADES2
    uint8_t pad[196];
#else
    uint8_t pad[196 + 32];
#endif
};
#ifdef HADES2
static_assert(sizeof(MapThingDef) == 0xD8, "Incorrect SGG::MapThingDef size");
#else
static_assert(sizeof(MapThingDef) == 0xF8, "Incorrect SGG::MapThingDef size");
#endif
} // namespace SGG