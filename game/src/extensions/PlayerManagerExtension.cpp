//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#include "PlayerManagerExtension.h"
#include "../interface/PlayerManager.h"
#include "../CoopLog.h"

bool PlayerManagerExtension::AssignGamepad(size_t playerIndex, uint8_t gamepadIndex) {
    if (GetPlayersCount() < playerIndex + 1)
        return false;

    auto *player = SGG::PlayerManager::Instance()->GetPlayer(playerIndex);

    if (!player)
        return false;

    auto *input = GetInput(player->GetControllerIndex());

    if (!input)
        return false;

    input->SetGamepadId(gamepadIndex);

    return true;
}

uint8_t PlayerManagerExtension::GetGamepad(size_t playerIndex) {
    if (GetPlayersCount() < playerIndex + 1)
        return -1;

    auto *player = SGG::PlayerManager::Instance()->GetPlayer(playerIndex);

    if (!player)
        return -1;

    auto *input = GetInput(player->GetControllerIndex());

    if (!input)
        return -1;

    return input->GetGamepadId();
}

bool PlayerManagerExtension::AssignController(SGG::Player *player, uint8_t ccontroler) {
    SGG::PlayerManager::Instance()->AssignController(player, ccontroler);
    return false;
}

bool PlayerManagerExtension::HasPlayer(size_t index) {
    auto *instance = SGG::PlayerManager::Instance();
    if (instance->m_palyers.size() <= index)
        return false;

    return instance->m_palyers[index];
}

// TODO use RemovePlayer from the game
void PlayerManagerExtension::RemovePlayer(size_t index) {
    auto *instance = SGG::PlayerManager::Instance();
    if (instance->m_palyers.size() <= index)
        return;

    auto *player = instance->m_palyers[index];

    if (player) {
        delete player;
        instance->m_palyers[index] = nullptr;
    }
}

SGG::Player *PlayerManagerExtension::CreatePlayer(size_t index) {
    auto *instance = SGG::PlayerManager::Instance();

    CoopLog::Write("CreatePlayer(%zu): players vector size=%zu", index, (size_t)instance->m_palyers.size());

    if (index >= MAX_PLAYERS)
        return nullptr;

    // The game creates this vector with size 2. All engine loops over players use size(),
    // so growing it is enough for the engine to update the extra player.
    if (instance->m_palyers.size() <= index) {
        bool resized = instance->ResizePlayers(index + 1);
        CoopLog::Write("CreatePlayer(%zu): resize -> %d, size=%zu", index, resized,
                       (size_t)instance->m_palyers.size());
        if (!resized)
            return nullptr;
    }

    if (instance->m_palyers[index] != nullptr) {
        CoopLog::Write("CreatePlayer(%zu): slot is busy", index);
        return nullptr;
    }

    // m_inputMethods has 5 slots: 0-3 are gamepad handlers, 4 is keyboard (player 1 default).
    // Each player needs its own InputHandler, so use the player index.
    uint8_t controller = static_cast<uint8_t>(index);

    auto player = instance->AddPlayer(index);

    CoopLog::Write("CreatePlayer(%zu): AddPlayer -> %p", index, (void *)player);
    if (!player)
        return nullptr;

    AssignController(player, controller);
    CoopLog::Write("CreatePlayer(%zu): controller %u assigned, players count=%zu", index, controller,
                   GetPlayersCount());

    return player;
}

SGG::Player *PlayerManagerExtension::GetPlayer(size_t index) {
    auto *instance = SGG::PlayerManager::Instance();
    if (index >= instance->m_palyers.size())
        return nullptr;
    return instance->m_palyers[index];
}
SGG::InputHandler *PlayerManagerExtension::GetInput(size_t index) {
    auto *instance = SGG::PlayerManager::Instance();
    if (index >= instance->m_inputMethods.size())
        return nullptr;
    return instance->m_inputMethods[index];
};

size_t PlayerManagerExtension::GetPlayersCount() const noexcept {
    size_t size = 0;
    for (auto *player : SGG::PlayerManager::Instance()->m_palyers)
        if (player)
            size++;

    return size;
}
