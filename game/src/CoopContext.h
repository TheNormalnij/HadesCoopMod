//
// Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
// Licensed under the MIT license. See LICENSE file in the project root for details.
//

#include "extensions/PlayerManagerExtension.h"
#include <memory>
#include <vector>

#include "interface/MapThing.h"

constexpr size_t INVALID_PLAYER_INDEX = -1;
constexpr size_t INVALID_UNIT_INDEX = -1;

class lua_State;

class CoopContext {
  public:
    CoopContext();
    ~CoopContext() = default;

    PlayerManagerExtension &GetPlayerManager() noexcept { return playerManager; };

    static CoopContext *GetInstance() {
        if (instance)
            return instance.get();
        instance = std::make_unique<CoopContext>();
        return instance.get();
    }

    void InitLua(lua_State *luaState);

    size_t CreatePlayer();
    size_t CreatePlayerUnit(size_t playerIndex);
    size_t GetPlayerUnitId(size_t playerIndex);

    bool RemovePlayer(size_t playerIndex);
    bool RemovePlayerUnit(size_t playerIndex);

    bool UseItem(size_t playerUnit, size_t useUnit);

  private:
    PlayerManagerExtension playerManager;
    static std::unique_ptr<CoopContext> instance;
};
