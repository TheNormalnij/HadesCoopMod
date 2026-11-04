--
-- Boon tray (the column of boon icons) for every player.
--
-- Player 1 uses the vanilla tray on the left side of the screen.
-- Additional players get the same tray mirrored on the right side:
-- player 2 at the screen edge, player 3 next to it.
--
-- Vanilla tray functions are reused. While they run for an additional player:
--  * tray related ScreenAnchors point to the player's own tray
--  * X coordinates of created/moved obstacles are mirrored to the right side
--  * fade directions are mirrored
-- Only functions that never wait are run this way, because the globals are
-- swapped while they run.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "CoopPlayers.lua"
---@type HeroContext
local HeroContext = ModRequire "HeroContext.lua"
---@type HookUtils
local HookUtils = ModRequire "HookUtils.lua"
---@type RunEx
local RunEx = ModRequire "RunEx.lua"

---@class TraitTrays
local TraitTrays = {}

-- Distance from the right screen edge, per player
local TrayShiftX = {
    [2] = 0,
    [3] = 200,
}

local TrayAnchorKeys = { "TraitAnchorIds", "TraitBacking", "TraitPlaceholderIcons", "TraitPlaceholderFrames", "AdditionalTraitHint" }

---@private
---@type table<number, table> playerId -> anchors
TraitTrays.Anchors = {}

-- Hero whose tray is currently swapped in, nil for player 1
local activeHero = nil

---@param playerId number
local function GetTrayAnchors(playerId)
    TraitTrays.Anchors[playerId] = TraitTrays.Anchors[playerId] or {}
    return TraitTrays.Anchors[playerId]
end

--- Player id of an additional player hero.
--- false for unknown non-main heroes (fresh heroes not registered yet), nil for the main hero.
---@return number|false|nil
local function GetAdditionalPlayerId(hero)
    if hero == nil or hero == CoopPlayers.GetMainHero() then
        return nil
    end
    local playerId = CoopPlayers.GetPlayerByHero(hero)
    if playerId and playerId > 1 then
        return playerId
    end
    return false
end

--- Runs a vanilla tray function for the tray of the given hero
function TraitTrays.RunForHero(hero, fun, ...)
    local playerId = GetAdditionalPlayerId(hero)
    if playerId == nil or hero == activeHero then
        return fun(...)
    end
    if playerId == false then
        -- The hero is being created, its tray is created on the next refresh
        return
    end

    local shiftX = TrayShiftX[playerId] or (playerId - 2) * 200
    local function mirrorX(x)
        return ScreenWidth - x - shiftX
    end

    local tray = GetTrayAnchors(playerId)
    local backup = {}
    for _, key in ipairs(TrayAnchorKeys) do
        backup[key] = ScreenAnchors[key]
        ScreenAnchors[key] = tray[key]
    end

    local prevActiveHero = activeHero
    local _CreateScreenObstacle = CreateScreenObstacle
    local _SpawnObstacle = SpawnObstacle
    local _Teleport = Teleport
    local _FadeObstacleIn = FadeObstacleIn
    local _HideObstacle = HideObstacle

    activeHero = hero
    CreateScreenObstacle = function(args)
        if args.X then
            args.X = mirrorX(args.X)
        end
        return _CreateScreenObstacle(args)
    end
    SpawnObstacle = function(args)
        local isBacking = args.Group == "Combat_UI_Backing" and args.OffsetY == TraitUI.StartY
        if args.OffsetX and not args.DestinationId then
            args.OffsetX = mirrorX(args.OffsetX)
        end
        local id = _SpawnObstacle(args)
        if isBacking and id then
            -- The tray backing is drawn for the left screen edge
            SetScaleX({ Id = id, Fraction = -1 })
        end
        return id
    end
    Teleport = function(args)
        if args.OffsetX and not args.DestinationId then
            args.OffsetX = mirrorX(args.OffsetX)
        end
        return _Teleport(args)
    end
    FadeObstacleIn = function(args)
        if args.Direction then
            args.Direction = 180 - args.Direction
        end
        return _FadeObstacleIn(args)
    end
    HideObstacle = function(args)
        if args.Angle then
            args.Angle = 180 - args.Angle
        end
        return _HideObstacle(args)
    end

    local result = { pcall(fun, ...) }

    CreateScreenObstacle = _CreateScreenObstacle
    SpawnObstacle = _SpawnObstacle
    Teleport = _Teleport
    FadeObstacleIn = _FadeObstacleIn
    HideObstacle = _HideObstacle
    activeHero = prevActiveHero

    for _, key in ipairs(TrayAnchorKeys) do
        tray[key] = ScreenAnchors[key]
        ScreenAnchors[key] = backup[key]
    end

    if not result[1] then
        error(result[2], 0)
    end
    return (table.unpack or unpack)(result, 2)
end

local function IsTrayVisibleFor(hero)
    return hero ~= nil and (RunEx.IsRunEnded() or not hero.IsDead)
end

--- Calls fun(playerId, hero) in the hero context of every additional player
local function ForEachAdditionalHero(fun)
    for playerId = 2, CoopPlayers.GetPlayersCount() do
        local hero = CoopPlayers.GetHero(playerId)
        if hero then
            HeroContext.RunWithHeroContext(hero, fun, playerId, hero)
        end
    end
end

--- Mirrored copy of vanilla HideTraitUI for an additional player tray (it waits, so it can't swap globals)
local function HideAdditionalTray(playerId, hero)
    local tray = GetTrayAnchors(playerId)
    if tray.TraitBacking == nil then
        return
    end

    local ids = {}
    for _, trait in pairs(hero.Traits or {}) do
        if trait.AnchorId ~= nil then
            HideObstacle({ Id = trait.AnchorId, IncludeText = true, Distance = CombatUI.FadeDistance.Trait, Angle = 0, Duration = CombatUI.TraitFadeDuration, SmoothStep = true })
        end
        if trait.TraitIconOverlay ~= nil then
            SetAlpha({ Id = trait.TraitIconOverlay, Fraction = 0, Duration = CombatUI.TraitFadeDuration })
            table.insert(ids, trait.TraitIconOverlay)
        end
        if trait.TraitActiveOverlay ~= nil then
            table.insert(ids, trait.TraitActiveOverlay)
        end
        if trait.TraitInfoCardId ~= nil then
            HideObstacle({ Id = trait.TraitInfoCardId, IncludeText = true, Distance = CombatUI.FadeDistance.Trait, Angle = 0, Duration = CombatUI.TraitFadeDuration, SmoothStep = true })
            table.insert(ids, trait.TraitInfoCardId)
        end
        trait.AnchorId = nil
        trait.TraitIconOverlay = nil
        trait.TraitActiveOverlay = nil
        trait.TraitInfoCardId = nil
    end

    for _, id in ipairs(tray.TraitAnchorIds or {}) do
        table.insert(ids, id)
    end
    local backingIds = { tray.TraitBacking, tray.AdditionalTraitHint }
    for _, id in ipairs(tray.TraitPlaceholderIcons or {}) do
        table.insert(backingIds, id)
    end
    for _, id in ipairs(tray.TraitPlaceholderFrames or {}) do
        table.insert(backingIds, id)
    end
    for _, id in pairs(backingIds) do
        HideObstacle({ Id = id, IncludeText = true, Distance = CombatUI.FadeDistance.Trait, Angle = 0, Duration = CombatUI.TraitFadeDuration, SmoothStep = true })
        table.insert(ids, id)
    end

    for _, key in ipairs(TrayAnchorKeys) do
        tray[key] = nil
    end

    wait(CombatUI.TraitFadeDuration, RoomThreadName)
    Destroy({ Ids = ids })
end

--- Shows trays of additional players that are not visible yet (e.g. after a player unit was created)
function TraitTrays.Refresh()
    if not ShowingCombatUI or not ScreenAnchors.TraitBacking then
        -- The main tray is hidden, so all trays are hidden
        return
    end
    ForEachAdditionalHero(function(playerId, hero)
        if IsTrayVisibleFor(hero) and not GetTrayAnchors(playerId).TraitBacking then
            TraitTrays.RunForHero(hero, ShowTraitUI)
        end
    end)
end

-- Hero that opened the boon list screen
---@private
TraitTrays.ScreenHero = nil

---@private
TraitTrays.HiddenMainTraitIds = nil

local function SetMainTrayAlpha(fraction)
    local mainHero = CoopPlayers.GetMainHero()
    if not mainHero then
        return
    end
    for _, trait in pairs(mainHero.Traits or {}) do
        for _, key in ipairs({ "AnchorId", "TraitIconOverlay", "TraitActiveOverlay", "TraitInfoCardId" }) do
            if trait[key] then
                SetAlpha({ Id = trait[key], Fraction = fraction, Duration = 0.1 })
            end
        end
    end
end

function TraitTrays.GetScreenHero()
    return TraitTrays.ScreenHero
end

function TraitTrays.InitHooks()
    -- Shown / hidden / destroyed together with the main tray
    HookUtils.wrap("ShowTraitUI", function(baseFun, ...)
        HeroContext.RunWithHeroContext(CoopPlayers.GetMainHero(), baseFun, ...)
        ForEachAdditionalHero(function(playerId, hero)
            if IsTrayVisibleFor(hero) then
                TraitTrays.RunForHero(hero, baseFun)
            end
        end)
    end)

    HookUtils.wrap("HideTraitUI", function(baseFun, ...)
        if CombatUI.ShowingTraitDescription then
            return baseFun(...)
        end
        for playerId = 2, CoopPlayers.GetPlayersCount() do
            local hero = CoopPlayers.GetHero(playerId)
            if hero then
                thread(HideAdditionalTray, playerId, hero)
            end
        end
        local mainHero = CoopPlayers.GetMainHero()
        if mainHero and HeroContext.GetCurrentHeroContext() ~= mainHero then
            local args = { ... }
            return HeroContext.RunWithHeroContext(mainHero, baseFun, (table.unpack or unpack)(args))
        end
        return baseFun(...)
    end)

    HookUtils.wrap("DestroyTraitUI", function(baseFun, ...)
        HeroContext.RunWithHeroContext(CoopPlayers.GetMainHero(), baseFun, ...)
        ForEachAdditionalHero(function(playerId, hero)
            TraitTrays.RunForHero(hero, baseFun)
        end)
    end)

    -- Functions that use the tray anchors or positions go to the tray of the current hero
    local routedFunctions = {
        "TraitUIAdd",
        "TraitUICreateComponent",
        "TraitUIRemove",
        "UpdateAdditionalTraitHint",
        "SortPriorityTraits",
        "PriorityTrayTraitAdd",
        "PriorityTrayTraitRemove",
        "CleanRecentTraitsRecord",
    }
    for _, funcName in ipairs(routedFunctions) do
        if _G[funcName] then
            HookUtils.wrap(funcName, function(baseFun, ...)
                if CombatUI.ShowingTraitDescription then
                    -- The boon list screen is drawn on the left side for the hero that opened it
                    return baseFun(...)
                end
                return TraitTrays.RunForHero(CurrentRun and CurrentRun.Hero, baseFun, ...)
            end)
        end
    end

    -- Active trait highlights (low health, perfect clear...) are updated for the current hero only
    HookUtils.wrap("TraitUIActivateTraits", function(baseFun, ...)
        baseFun(...)
        if CurrentRun and CurrentRun.Hero == CoopPlayers.GetMainHero() then
            ForEachAdditionalHero(function()
                baseFun()
            end)
        end
    end)

    -- Boon list screen: shows the boons of the player that opened it on the left side
    HookUtils.wrap("ShowAdvancedTooltip", function(baseFun, ...)
        local hero = CurrentRun and CurrentRun.Hero
        local isAdditional = GetAdditionalPlayerId(hero)
        if not CombatUI.ShowingTraitDescription then
            TraitTrays.ScreenHero = hero
            if isAdditional then
                SetMainTrayAlpha(0)
            end
        end
        return baseFun(...)
    end)

    HookUtils.onPostFunction("CloseAdvancedTooltipScreen", function()
        if CombatUI.ShowingTraitDescription then
            -- The screen can't be closed yet
            return
        end
        if GetAdditionalPlayerId(TraitTrays.ScreenHero) then
            SetMainTrayAlpha(1)
        end
        TraitTrays.ScreenHero = nil
    end)
end

return TraitTrays
