//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "HashGuid.h"

namespace SGG {
class GameData {
  public:
    HashGuid GetName() const noexcept { return mName; };

  private:
    void *vftable;
    HashGuid mName;
    HashGuid mOrganization;
    HashGuid mInheritFrom;
};
static_assert(sizeof(GameData) == 0x18, "Incorrect SGG::GameData size");
} // namespace SGG
