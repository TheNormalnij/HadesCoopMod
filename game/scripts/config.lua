--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@class CoopModConfig
local Config = {
    -- Choose loot delivery type here
    -- Possible values: "Shared", "RoomDuplicated"
    --
    -- Shared - rooms generate one reward. Only one player can pick it up.
    -- The game has a query that select a player context for a reward.
    -- E.g. Player 1 boon room, meta progress room, Player 2 boon room, Player 1 boon room...
    --
    -- RoomDuplicated - rooms generate two reward for each player.
    LootDelivery = "RoomDuplicated",

    -- This config is used for the "RoomDuplicated" loot delivery option
    RoomDuplicatedDelivery = {
        -- Enables duplication of the Chaos boons.
        DuplicateChaosBoon = false;
        -- true: every door shows the rewards of all players (with P1/P2/P3 labels),
        -- any player can enter a door and everybody goes there with their own reward.
        -- false: players choose doors one by one.
        SharedDoorChoice = true;
    },
    -- Enemy scaling by the number of players (like Seamless Coop).
    -- Values are added for every additional alive player: 0.35 = +35%.
    -- With 3 players: regular enemies 1 + 2 * 0.35 = 1.7x health, bosses 1 + 2 * 0.5 = 2x.
    -- Health scaling also scales enemy armor.
    EnemyScaling = {
        Enabled = true,
        HealthPerPlayer = 0.35,
        BossHealthPerPlayer = 0.5,
        -- Damage enemies deal to players
        DamagePerPlayer = 0,
        BossDamagePerPlayer = 0,
    },
    -- Players whose UI (HUD and boon tray) is hidden while a boss health bar is shown.
    -- The player 3 UI is at the top of the screen and covers the boss health bar.
    HideUiDuringBoss = {
        [3] = true,
    },
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
    };
    Player3HasOutline = true,
    Player3Outline = {
        R = 200,
        G = 0,
        B = 0,
        Opacity = 0.6,
        Thickness = 2,
        Threshold = 0.6,
    };
    -- "P1/P2/P3" above players, colored like the player outline
    TextAbovePlayersEnabled = true;
    TextAbovePlayersParams = {
        -- CreateTextBox params
        OffsetX = 0,
        OffsetY = -175,
        FontSize = 48,
        Color = { 255, 255, 255, 255 },
        ShadowColor = { 0, 0, 0, 240 },
        ShadowOffset = { 0, 2 },
        ShadowBlur = 0,
        OutlineThickness = 3,
        OutlineColor = { 0, 0, 0, 1 },
        Font = "AlegreyaSansSCRegular",
        Justification = "Center"
    },
    Debug = {
        OneHit = false,
        P1GodMode = false,
        P2GodMode = false,
    }
}

return Config
