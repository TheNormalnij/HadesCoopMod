//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#include "HookTable.h"

static HookTable g_HookTable{};

HookTable& HookTable::Instance() {
    return g_HookTable; }

void HookTable::Init(IModApi::GetSymbolAddress_t GetSymbolAddress) {
    PlayerManager_Instance = GetSymbolAddress("sgg::PlayerManager::Instance");
    PlayerManager_AddPlayer = GetSymbolAddress("sgg::PlayerManager::AddPlayer");
    PlayerManager_AssignController = GetSymbolAddress("sgg::PlayerManager::AssignController");
    Player_Player = GetSymbolAddress("sgg::Player::Player");
    PlayerUnit_PlayerUnit = GetSymbolAddress("sgg::PlayerUnit::PlayerUnit");

    UnitManager_ENTITY_MANAGER = GetSymbolAddress("sgg::UnitManager::ENTITY_MANAGER");
    UnitManager_Add = GetSymbolAddress("sgg::UnitManager::Add");
    UnitManager_Get = GetSymbolAddress("sgg::UnitManager::Get");
    UnitManager_CreatePlayerUnit = GetSymbolAddress("sgg::UnitManager::CreatePlayerUnit");

    Unit_Delete = GetSymbolAddress("sgg::Unit::Delete");
    Interact_Use = GetSymbolAddress("sgg::Interact::Use");

    World_Instance = GetSymbolAddress("sgg::World::Instance");
    World_GetActiveThing = GetSymbolAddress("sgg::World::GetActiveThing");

    GameDataManager_GetUnitData = GetSymbolAddress("sgg::GameDataManager::GetUnitData");
}
