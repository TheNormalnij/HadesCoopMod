//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "MapThingDef.h"

namespace SGG {
class MapThing {
  public:
    MapThingDef *GetDef() noexcept { return &mDef; };

  private:
    MapThingDef mDef;
};
#ifdef HADES2
static_assert(sizeof(MapThing) == 0xD8, "Incorrect SGG::MapThing size");
#else
static_assert(sizeof(MapThing) == 0xF8, "Incorrect SGG::MapThing size");
#endif
} // namespace SGG