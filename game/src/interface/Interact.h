//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

namespace SGG {
class Unit;

class Interact {
  public:
    void Use(Unit *user, bool unk1, bool unk2) noexcept {
        ((void(__fastcall *)(void *, Unit *, bool, bool))HookTable::Instance().Interact_Use)(this, user, unk1,
                                                                                                  unk2);
    };

  private:
    uint8_t pad[0x38];
};
static_assert(sizeof(Interact) == 0x38, "Incorrect SGG::Iteract size");
} // namespace SGG