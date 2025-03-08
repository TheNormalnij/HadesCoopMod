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

std::unique_ptr<CoopContext> CoopContext::instance = nullptr;

CoopContext::CoopContext() { m_cretedThings.resize(2); }

CoopContext::~CoopContext() {
    for (SGG::MapThing* mapThing : m_cretedThings) {
        //if (mapThing)
        //    delete mapThing;
    }
}

void CoopContext::InitLua(lua_State *luaState) {
    // Init coop engine lua functions
    LuaFunctionDefs::Load(luaState);
}

size_t CoopContext::CreatePlayer() {
    size_t playerIndex = -1;
    for (size_t i = 0; i < 2; i++) {
        if (!playerManager.HasPlayer(i)) {
            playerIndex = i;
        }
    }

    if (playerIndex == -1)
        return -1;

    playerManager.CreatePlayer(playerIndex);

    hoohSystem.SetControllerHotswapEnabled(false);

    return playerIndex;
}

size_t CoopContext::CreatePlayerUnit(size_t playerIndex) {
    auto *basePlayer = playerManager.GetPlayer(0);
    auto *newPlayer = playerManager.GetPlayer(playerIndex);

    if (!basePlayer || !newPlayer)
        return -1;

    auto *baseUnit = basePlayer->GetUnit();
    auto *currentUnit = newPlayer->GetUnit();

    if (!baseUnit || currentUnit)
        return -1;

    SGG::MapThing *mapThingBase = baseUnit->GetMapThing();

    auto *mapThing = (SGG::MapThing *)_aligned_malloc(sizeof(SGG::MapThing), std::alignment_of<SGG::MapThing>::value);
    std::memcpy(mapThing, mapThingBase, sizeof(SGG::MapThing));

    //if (m_cretedThings[playerIndex])
        //delete m_cretedThings[playerIndex];

    m_cretedThings[playerIndex] = mapThing;

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
        return -1;

    auto *unit = player->GetUnit();
    if (!unit)
        return -1;

    return unit->GetId();
}

bool CoopContext::RemovePlayer(size_t playerIndex) {
    if (!playerManager.HasPlayer(playerIndex))
        return false;

    playerManager.RemovePlayer(playerIndex);
    RemovePlayerUnit(playerIndex);
    
    if (playerManager.GetPlayersCount() == 1)
        hoohSystem.SetControllerHotswapEnabled(true);

    return true;
}

bool CoopContext::RemovePlayerUnit(size_t playerIndex) {    
    //if (m_cretedThings[playerIndex])
      //  delete m_cretedThings[playerIndex];

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
