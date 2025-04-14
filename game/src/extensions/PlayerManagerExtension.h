//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "interface/Player.h"
#include "interface/InputHandler.h"

class PlayerManagerExtension {
  public:
    PlayerManagerExtension() = default;
    ~PlayerManagerExtension() = default;


    bool AssignGamepad(size_t playerIndex, uint8_t gamepad);
    uint8_t GetGamepad(size_t playerIndex);

    bool AssignController(SGG::Player *player, uint8_t controler);

    bool HasPlayer(size_t index);
    void RemovePlayer(size_t index);

    SGG::Player *CreatePlayer(size_t index);
    SGG::Player *GetPlayer(size_t index);

    SGG::InputHandler *GetInput(size_t index);

    size_t GetPlayersCount() const noexcept;
};
