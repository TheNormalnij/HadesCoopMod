--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type fun(playerId: number, gamepadIndex: number): boolean
CoopSetPlayerGamepad = nil

---@type fun(): number
CoopGetPlayersCount = nil

---@type fun(): number
CoopCreatePlayer = nil

---@type fun(playerId: number): boolean
CoopRemovePlayer = nil

---@type fun(playerId: number): boolean
CoopHasPlayer = nil

---@type fun(playerId: number): number | false
CoopCreatePlayerUnit = nil

---@type fun(playerId: number): boolean
CoopRemovePlayerUnit = nil

---@type fun(unitId: number, thingId: number): boolean
CoopUseItem = nil
