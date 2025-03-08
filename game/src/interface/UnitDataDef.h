//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

namespace SGG {
    #ifdef HADES2
class UnitDataDef {
    uint8_t pad[0xB0];
};
static_assert(sizeof(UnitDataDef) == 0xB0, "Incorrect SGG::UnitDataDef size");
#else
class UnitDataDef {
    uint8_t pad[0x160];
};
static_assert(sizeof(UnitDataDef) == 0x160, "Incorrect SGG::UnitDataDef size");

#endif
} // namespace SGG