--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type fun(number, number): boolean
CoopSetPlayerGamepad = nil

---@type fun(): number
CoopGetPlayersCount = nil

---@type fun(): number
CoopCreatePlayer = nil

---@type fun(number): boolean
CoopRemovePlayer = nil

---@type fun(number): boolean
CoopHasPlayer = nil

---@type fun(number): number | false
CoopCreatePlayerUnit = nil

---@type fun(number): boolean
CoopRemovePlayerUnit = nil
