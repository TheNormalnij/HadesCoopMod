//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "UnitDataDef.h"
#include "GameData.h"

namespace SGG {
class UnitData : public GameData {
  public:
    UnitDataDef *GetDef() noexcept { return &mDef; };

  private:
    UnitDataDef mDef;
};
#ifdef HADES2
static_assert(sizeof(UnitData) == 0xC8, "Incorrect SGG::UnitData size");
#else
static_assert(sizeof(UnitData) == 0x178, "Incorrect SGG::UnitData size");
#endif
} // namespace SGG