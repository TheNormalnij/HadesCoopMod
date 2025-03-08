//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

namespace SGG {
class Entity {
  public:
    Entity(): mId{0} {}
    explicit Entity(uint32_t id) : mId{id} {};

    uint32_t GetId() const noexcept { return mId; };

  private:
    uint32_t mId;
};
static_assert(sizeof(Entity) == 0x4, "Incorrect SGG::Entity size");
} // namespace SGG