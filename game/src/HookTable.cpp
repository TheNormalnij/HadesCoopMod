//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#include "HookTable.h"

static HookTable g_HookTable{};

void HookTable::ApplySteamVk() {
    PlayerManager_Instance = 0x307A0;
    PlayerManager_AddPlayer = 0x2102A0;
    PlayerManager_AssignController = 0x210320;
    Player_Player = 0x20A520;
    PlayerUnit_PlayerUnit = 0x2E3260;

    UnitManager_ENTITY_MANAGER = 0x1A57028;
    UnitManager_Add = 0x2EF700;
    UnitManager_Get = 0x2F0AC0;
    UnitManager_CreatePlayerUnit = 0x2F0800;

    Unit_Delete = 0x2EA330;
    Iteract_Use = 0x2B8540;

    World_Instance = 0x3069E0;
    World_GetActiveThings = 0x30A360;

    GameDataManager_GetUnitData = 0xB1D40;
}

void HookTable::ApplyOffset(size_t offset) {
    auto asArray = reinterpret_cast<size_t*>(this);
    for (size_t i = 0; i < sizeof(HookTable) / sizeof(size_t); i++) {
        asArray[i] += offset;
    }
}

HookTable& HookTable::Instance() {
    return g_HookTable;
}
