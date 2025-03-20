//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#pragma once

struct HookTable {
    void ApplySteamVk();
	void ApplyOffset(size_t offset);
    static HookTable& Instance();

	size_t PlayerManager_Instance;
    size_t PlayerManager_AddPlayer;
    size_t PlayerManager_AssignController;

    size_t Player_Player;

    size_t PlayerUnit_PlayerUnit;

    size_t UnitManager_ENTITY_MANAGER;
    size_t UnitManager_Add;
    size_t UnitManager_CreatePlayerUnit;

    size_t Unit_Delete;

    size_t GameDataManager_GetUnitData;
};
