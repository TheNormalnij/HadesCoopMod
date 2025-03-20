//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include <memory>
#include <array>

class HookSystem {
  private:
    void MemSetUnsafe(void *dest, int val, size_t size);
    void MemCpyUnsafe(void *dest, void* src, size_t size);
};
