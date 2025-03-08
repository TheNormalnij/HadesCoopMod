//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

namespace SGG {
class HashGuid {
  public:
    uint32_t GetId() const noexcept { return mId; };

  private:
    uint32_t mId;
};
static_assert(sizeof(HashGuid) == 0x4, "Incorrect SGG::HashGuid size");
} // namespace SGG