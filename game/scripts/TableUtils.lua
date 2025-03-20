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

return TableUtils
