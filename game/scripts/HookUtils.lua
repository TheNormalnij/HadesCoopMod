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
        original(...)
        handler(...)
        _G[funcName] = original
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
        handler(...)
        _G[funcName] = original
        original(...)
    end
end

return HookUtils
