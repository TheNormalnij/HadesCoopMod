//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

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

    SGG::Player *GetPlayer(uint64_t index) const noexcept { return m_palyers[index]; }

    // Grows the players vector. Memory must come from the game allocator (ucrt _aligned_malloc),
    // because the game frees it with _aligned_free.
    bool ResizePlayers(uint64_t size) {
        if (m_palyers.size() >= size)
            return true;

        auto resize = HookTable::Instance().PlayerVector_Resize;
        if (resize) {
            ((void(__fastcall *)(void *, uint64_t))resize)(&m_palyers, size);
            return m_palyers.size() >= size;
        }

        // Fallback: grow it manually with the same ucrt functions the game imports
        using AlignedMalloc_t = void *(__cdecl *)(size_t, size_t);
        using AlignedFree_t = void(__cdecl *)(void *);
        HMODULE ucrt = GetModuleHandleW(L"ucrtbase.dll");
        if (!ucrt)
            return false;
        auto alignedMalloc = (AlignedMalloc_t)GetProcAddress(ucrt, "_aligned_malloc");
        auto alignedFree = (AlignedFree_t)GetProcAddress(ucrt, "_aligned_free");
        if (!alignedMalloc || !alignedFree)
            return false;

        auto **raw = reinterpret_cast<SGG::Player ***>(&m_palyers); // begin, end, capacity
        SGG::Player **oldBegin = raw[0];
        size_t oldSize = m_palyers.size();

        auto **newBegin = (SGG::Player **)alignedMalloc(size * sizeof(SGG::Player *), 16);
        if (!newBegin)
            return false;
        for (size_t i = 0; i < size; i++)
            newBegin[i] = i < oldSize ? oldBegin[i] : nullptr;

        raw[0] = newBegin;
        raw[1] = newBegin + size;
        raw[2] = newBegin + size;
        if (oldBegin)
            alignedFree(oldBegin);

        return true;
    }
  private:
    eastl::vector<SGG::InputHandler*, eastl::allocator_forge> m_inputMethods;
    eastl::vector<SGG::Player *, eastl::allocator_forge> m_palyers;
};
static_assert(sizeof(PlayerManager) == 0x30, "Incorrect PlayerManager size");

} // namespace SGG
