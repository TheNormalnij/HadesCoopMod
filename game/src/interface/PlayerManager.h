//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "../HookSystem.h"
#include "../HookTable.h"
#include "Player.h"
#include "InputHandler.h"
#include "allocator.h"
#include "../../libs/EASTL-forge1.51/vector.h"

namespace SGG {

class PlayerManager {
    friend class PlayerManagerExtension;

  public:
    static PlayerManager *Instance() {
        return ((PlayerManager * (__fastcall *)()) HookTable::Instance().PlayerManager_Instance)();
    }

    SGG::Player *AddPlayer(uint64_t index) {
        return ((SGG::Player * (__fastcall *)(void *, uint64_t)) HookTable::Instance().PlayerManager_AddPlayer)(this,
                                                                                                                index);
    }

    void AssignController(SGG::Player *player, uint32_t index) {
        ((void(__fastcall *)(void *, SGG::Player *, uint32_t))HookTable::Instance().PlayerManager_AssignController)(
            this, player, index);
    }

  private:
    eastl::vector<SGG::InputHandler*, eastl::allocator_forge> m_inputMethods;
    eastl::vector<SGG::Player *, eastl::allocator_forge> m_palyers;
};
static_assert(sizeof(PlayerManager) == 0x30, "Incorrect PlayerManager size");

} // namespace SGG
