--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@class TableUtils
local TableUtils = {}

---@param t table
---@param value any
---@return any
function TableUtils.find(t, value)
    for key, _v in pairs(t) do
        if _v == value then
            return key;
        end
    end
end

---@param dest table
---@param from table
---@return table
function TableUtils.copyTo(dest, from)
    for key, value in pairs(from) do
        dest[key] = value
    end
    return dest
end

---@param dest table
---@param from table
---@return table
function TableUtils.rawCopyTo(dest, from)
    for key, value in pairs(from) do
        rawset(dest, key, value)
    end
    return dest
end

---@param t table
function TableUtils.clean(t)
    local key = next(t)
    while key do
        t[key] = nil
        key = next(t)
    end
end

---@generic V
---@param t table<number, V>
---@return V?
function TableUtils.last(t)
    if t == nil or #t == 0 then
        return nil
    end
    return t[#t]
end

---@generic V
---@param t table<number, V>
---@return V?
function TableUtils.after(t, v)
    if t == nil then
        return nil
    end
    for i = 1, #t do
        if t[i] == v then
            return t[i + 1]
        end
    end
    return nil
end

return TableUtils
