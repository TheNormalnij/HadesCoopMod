--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@class HookUtils
local HookUtils = {}

---@param funcName string
---@param handler function
function HookUtils.onPostFunctionOnce(funcName, handler)
    local original = _G[funcName]

    if not original then
        return
    end

    _G[funcName] = function(...)
        _G[funcName] = original
        original(...)
        handler(...)
    end
end

---@param funcName string
---@param handler function
function HookUtils.onPreFunction(funcName, handler)
    local original = _G[funcName]

    if not original then
        return
    end

    _G[funcName] = function(...)
        handler(...)
        original(...)
    end
end

---@param funcName string
---@param handler function
function HookUtils.onPostFunction(funcName, handler)
    local original = _G[funcName]

    if not original then
        return
    end

    _G[funcName] = function(...)
        original(...)
        handler(...)
    end
end

---@param funcName string
---@param handler function
function HookUtils.onPreFunctionOnce(funcName, handler)
    local original = _G[funcName]

    if not original then
        return
    end

    _G[funcName] = function(...)
        _G[funcName] = original
        handler(...)
        original(...)
    end
end

---@param funcName string
---@param handler fun(basefun: function, ...): any
function HookUtils.wrap(funcName, handler)
    local original = _G[funcName]

    if not original then
        error("Cannot wrap function: " .. tostring(funcName))
    end

    _G[funcName] = function(...)
        return handler(original, ...)
    end
end

---@param funcName string
---@param handler fun(...): any
function HookUtils.replace(funcName, handler)
    _G[funcName] = handler
end

return HookUtils
