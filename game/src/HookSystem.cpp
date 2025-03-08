//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#include "HookSystem.h"
#include <windows.h>
#include "HookTable.h"
#include <string>
#include "CoopContext.h"

void HookSystem::SetControllerHotswapEnabled(bool state) {
    auto &hookTable = HookTable::Instance();
    if (state) {
        if (!hotswapOriginal)
            return;
        MemCpyUnsafe((void *)hookTable.path_disable_hootwasp, hotswapOriginal.get()->data(), 11);
    } else {
        if (!hotswapOriginal) {
            hotswapOriginal = std::make_unique<std::array<uint8_t, 11>>();
            std::memcpy(hotswapOriginal.get()->data(), (void *)hookTable.path_disable_hootwasp, 11);
        }
        MemSetUnsafe((void *)hookTable.path_disable_hootwasp, 0x90, 11);
    }
}

void HookSystem::MemSetUnsafe(void *dest, int val, size_t size) {
    DWORD oldProtect;
    VirtualProtect(dest, 1024, PAGE_EXECUTE_READWRITE, &oldProtect);

    // Disable control hotswap
    std::memset(dest, val, size);

    DWORD restoredFrom;
    VirtualProtect(dest, 1024, oldProtect, &restoredFrom);
}

void HookSystem::MemCpyUnsafe(void *dest, void* src, size_t size) {
    DWORD oldProtect;
    VirtualProtect(dest, 1024, PAGE_EXECUTE_READWRITE, &oldProtect);

    // Disable control hotswap
    std::memcpy(dest, src, size);

    DWORD restoredFrom;
    VirtualProtect(dest, 1024, oldProtect, &restoredFrom);
}
