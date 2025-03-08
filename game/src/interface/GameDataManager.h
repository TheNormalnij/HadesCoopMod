//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

#include "HashGuid.h"
#include "HookTable.h"
#include "UnitData.h"

namespace SGG {

class GameDataManager {

  public:
    static UnitData *GetUnitData(HashGuid name) {
        return ((UnitData * (__fastcall *)(HashGuid)) HookTable::Instance().GameDataManager_GetUnitData)(name);
    };

};
} // namespace SGG