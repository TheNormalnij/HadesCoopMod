--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@class CoopModConfig
local Config = {
    Player1HasOutline = true;
    Player1Outline = {
        R = 0,
        G = 0,
        B = 200,
        Opacity = 0.6,
        Thickness = 2,
        Threshold = 0.6,
    };
    Player2HasOutline = true,
    Player2Outline = {
        R = 0,
        G = 200,
        B = 0,
        Opacity = 0.6,
        Thickness = 2,
        Threshold = 0.6,
    }
}

return Config
