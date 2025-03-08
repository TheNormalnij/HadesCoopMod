//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "HookTable.h"
#include "Vector2.h"

namespace SGG {
class PlayerUnit;

class Player {
  public:
      static void internal_constructor(void* self, uint64_t index, uint8_t *controllerIndex) {
        ((void(__fastcall *)(void *, uint64_t, uint8_t *))HookTable::Instance().Player_Player)(self, index,
                                                                                               controllerIndex);
    }

    uint8_t GetControllerIndex() const noexcept { return mControllerIndex; };
    void SetControllerIndex(uint8_t index) noexcept { mControllerIndex = index; };

    PlayerUnit *GetUnit() { return pActiveUnit; };
    void SetUnit(PlayerUnit *unit) { pActiveUnit = unit; };

  private:
    bool mWasAnyInputGiven;
    bool mAllowInput;
    bool mIsConnected;
    bool mPauseRequested;
    uint8_t mControllerIndex;
    uint8_t pad1[3];

    uint64_t mIndex;

    Vectormath::Vector2 mCursorLocation;
    PlayerUnit *pActiveUnit; // sgg::PlayerUnit
    void *pAI;                    // sgg::PlayerAI

    uint8_t mUseTarget[0x10];
    uint64_t mPrevUseTargetId;

    uint8_t pad2[4];

    uint8_t mInputBlocks[0x30]; // eastl::hashset
    float mLeftRumbleFraction;
    float mRightRumbleFraction;
    float mRumbleEndTime;

    uint8_t mAsString[0x18];

    uint8_t mRumbleRequestsToDelete;
    uint8_t mRumbleRequests;
    uint8_t mTriggerRequests[2];
#ifdef HADES2
    uint8_t pad3[56]; // im lazy
#else
    uint8_t pad3[48]; // im lazy
#endif
};
#ifdef HADES2
static_assert(sizeof(Player) == 0xD8, "Incorrect Player size");
#else
static_assert(sizeof(Player) == 0xD0, "Incorrect Player size");
#endif

} // namespace SGG