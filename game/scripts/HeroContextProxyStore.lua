--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@class HeroContextProxyStore
local HeroContextProxyStore = {}

---@type table<string, HeroContextProxy>
local store = {}

---@param key string
---@param instance HeroContextProxy
function HeroContextProxyStore.Set(key, instance)
    store[key] = instance
end

---@param key string
---@return HeroContextProxy | nil
function HeroContextProxyStore.Get(key)
    return store[key]
end

---@return fun(store: table<string, HeroContextProxy>, index?: string): string, HeroContextProxy
---@return table<string, HeroContextProxy>
function HeroContextProxyStore.Iterator()
    return pairs(store)
end

return HeroContextProxyStore
