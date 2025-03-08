//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "Thing.h"
#include "helpers.h"

namespace SGG {
class UnitData;
class Player;

__declspec(align(16)) class Unit : public Thing {

public:
    void Delete() {
      ((void(__fastcall *)(void *))HookTable::Instance().Unit_Delete)(this);
    }

    UnitData *GetData() const noexcept { return *SGG_OFFSET_TO(UnitData*, 0x390); };

    void SetPlayer(Player *player) { SGG_OFFSET_TO_SET(0x380, player); };

private:
#ifdef HADES2
  uint8_t pad[480];
#else
  uint8_t pad[0x560 - 0x380];
#endif // HADES2

};
#ifdef HADES2
static_assert(sizeof(Unit) == 0x840, "Incorrect SGG::Unit size");
#else
static_assert(sizeof(Unit) == 0x560, "Incorrect SGG::Unit size");
#endif
} // namespace SGG