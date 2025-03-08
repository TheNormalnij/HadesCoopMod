//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "Entity.h"

namespace SGG {
class IRenderComponent {
  public:
    SGG::Entity GetEntity() const noexcept { return mEntity; };

private:
    uint8_t pad_base[10]; // sgg::Rtti
#ifndef HADES2
    uint8_t pad_mDrawGroup[8];
#endif
    uint64_t mSortScore;  // sgg::SortScore
    uint8_t mSortMode; // sgg::SortMode
    uint32_t mSecondarySortKey;
    bool mHasOutline;
    SGG::Entity mEntity;
    uint8_t booundsPad[0x18]; // sgg::Bounds
};
#ifdef HADES2
static_assert(sizeof(IRenderComponent) == 0x40, "Incorrect SGG::IRenderComponent size");
#else
static_assert(sizeof(IRenderComponent) == 0x48, "Incorrect SGG::IRenderComponent size");
#endif
} // namespace SGG
