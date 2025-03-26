//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "Vector2.h"
#include "MapThing.h"
#include "Interact.h"
#include "IRenderComponent.h"
#include "helpers.h"

namespace SGG {
__declspec(align(8)) class Thing : public IRenderComponent {
  public:
#ifdef HADES2
    Vectormath::Vector2 GetLocation() const noexcept { return mLocation; };
    uint32_t GetId() const noexcept { return mId; };
    HashGuid GetName() const noexcept { return mName; };
    MapThing *GetMapThing() const noexcept { return *SGG_OFFSET_TO(MapThing *, 0x510); };

  private:
    uint8_t __pad_to_finish[1480];
#else
    Vectormath::Vector2 GetLocation() const noexcept { return *SGG_OFFSET_TO(Vectormath::Vector2, 0x70); };
    uint32_t GetId() const noexcept { return *SGG_OFFSET_TO(uint32_t, 0x54); };
    HashGuid GetName() const noexcept { return *SGG_OFFSET_TO(HashGuid, 0x378); };
    MapThing *GetMapThing() const noexcept { return *SGG_OFFSET_TO(MapThing *, 0x220); };
    Interact *GetIteract() const noexcept { return *SGG_OFFSET_TO(Interact *, 0x110); };

  private:
    uint8_t __pad_to_finish[0x380 - 0x48];
#endif
};
#ifdef HADES2
static_assert(sizeof(Thing) == 0x640, "Incorrect SGG::Thing size");
#else
static_assert(sizeof(Thing) == 0x380, "Incorrect SGG::Thing size");
#endif
} // namespace SGG
