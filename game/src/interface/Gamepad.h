//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "HookTable.h"

namespace SGG {

// This function is not in SGG namespace
static const char *getGamePadNameForIndex(uint8_t index) {
    return reinterpret_cast<const char *(_fastcall *)(uint8_t)>(HookTable::Instance().getGamePadNameForIndex)(index);
}

} // namespace SGG