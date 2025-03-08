//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "Vector2.h"

namespace SGG {
#ifdef HADES2
struct GamePadHandler {
    uint8_t mControllerIndex;
    uint32_t Directions;
    uint32_t PrevDirections;
};
static_assert(sizeof(GamePadHandler) == 0xC, "Incorrect SGG::GamePadHandler size");
#else
struct GamePadHandler {
    bool bIsConnected;
    bool HasRecievedInput;
    uint8_t mControllerIndex;
    float DeadZoneIndex;
    uint32_t Directions;
    uint32_t PrevDirections;
    bool mStateOverrided;
};
static_assert(sizeof(GamePadHandler) == 0x14, "Incorrect SGG::GamePadHandler size");

#endif

class InputHandler {
  public:
    uint8_t GetGamepadId() const noexcept { return _gamePadHandler.mControllerIndex; };
    void SetGamepadId(uint8_t index) noexcept { _gamePadHandler.mControllerIndex = index; };

  private:
    Vectormath::Vector2 _prevSearchDirection;
    uint8_t _keyboardHandler; // sgg::KeyboardHandler
    uint8_t _mouseHandler;    // sgg::MouseHandler
    uint8_t pad[2];
    GamePadHandler _gamePadHandler;
    float _repeatDelay;

    uint8_t pad_end[0x64];
};
#ifdef HADES2
static_assert(sizeof(InputHandler) == 0x80, "Incorrect SGG::InputHandler size");
#else
static_assert(sizeof(InputHandler) == 0x88, "Incorrect SGG::InputHandler size");
#endif
} // namespace SGG