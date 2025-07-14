//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#include "pch.h"

#include "CoopContext.h"

#include "extensions/LuaFunctionDefs.h"
#include "interface/PlayerManager.h"
#include "interface/PlayerUnit.h"
#include "interface/UnitManager.h"
#include "interface/GameDataManager.h"
#include "interface/World.h"

std::unique_ptr<CoopContext> CoopContext::instance = nullptr;

CoopContext::CoopContext() {}

void CoopContext::InitLua(lua_State *luaState) {
    // Init coop engine lua functions
    LuaFunctionDefs::Load(luaState);
}

size_t CoopContext::CreatePlayer() {
    size_t playerIndex = INVALID_PLAYER_INDEX;
    for (size_t i = 0; i < MAX_PLAYERS; i++) {
        if (!playerManager.HasPlayer(i)) {
            playerIndex = i;
        }
    }

    if (playerIndex == INVALID_PLAYER_INDEX)
        return INVALID_PLAYER_INDEX;

    playerManager.CreatePlayer(playerIndex);

    return playerIndex;
}

size_t CoopContext::CreatePlayerUnit(size_t playerIndex) {
    auto *basePlayer = playerManager.GetPlayer(0);
    auto *newPlayer = playerManager.GetPlayer(playerIndex);

    if (!basePlayer || !newPlayer)
        return INVALID_UNIT_INDEX;

    auto *baseUnit = basePlayer->GetUnit();
    auto *currentUnit = newPlayer->GetUnit();

    if (!baseUnit || currentUnit)
        return INVALID_UNIT_INDEX;

    SGG::MapThing *mapThingBase = baseUnit->GetMapThing();

    auto *mapThing = (SGG::MapThing *)_aligned_malloc(sizeof(SGG::MapThing), std::alignment_of<SGG::MapThing>::value);
    std::memcpy(mapThing, mapThingBase, sizeof(SGG::MapThing));

    mapThing->GetDef()->SetId(40000 - playerIndex);

    SGG::UnitData *unitData = SGG::GameDataManager::GetUnitData(mapThing->GetDef()->GetName());

    Vectormath::Vector2 location = baseUnit->GetLocation();

    SGG::PlayerUnit *playerUnit =
        static_cast<SGG::PlayerUnit *>(SGG::UnitManager::CreatePlayerUnit(unitData, location, mapThing, true));

    playerUnit->SetPlayer(newPlayer);
    newPlayer->SetUnit(playerUnit);

    return playerUnit->GetId();
}

size_t CoopContext::GetPlayerUnitId(size_t playerIndex) { 
    auto *player = playerManager.GetPlayer(playerIndex);
    if (!player)
        return INVALID_UNIT_INDEX;

    auto *unit = player->GetUnit();
    if (!unit)
        return INVALID_UNIT_INDEX;

    return unit->GetId();
}

bool CoopContext::RemovePlayer(size_t playerIndex) {
    if (!playerManager.HasPlayer(playerIndex))
        return false;

    playerManager.RemovePlayer(playerIndex);
    RemovePlayerUnit(playerIndex);

    return true;
}

bool CoopContext::RemovePlayerUnit(size_t playerIndex) {
    auto *player = playerManager.GetPlayer(playerIndex);
    if (!player)
        return false;

    auto *unit = player->GetUnit();
    if (!unit)
        return false;

    unit->Delete();

    player->SetUnit(nullptr);

    return true;
}

bool CoopContext::UseItem(size_t playerUnitIndex, size_t useUnitIndex) {
    auto *playerUnit = SGG::UnitManager::Get(playerUnitIndex);
    auto *useThing = SGG::World::Instance()->GetActiveThing(useUnitIndex);

    if (!playerUnit || !useThing)
        return false;

    useThing->GetIteract()->Use(playerUnit, true, true);

    return true;
}
