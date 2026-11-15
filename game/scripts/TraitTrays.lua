--
-- Boon tray (the column of boon icons) for every player.
--
-- Player 1 uses the vanilla tray on the left side of the screen.
-- Player 2 gets the same tray mirrored on the right side.
-- Player 3 gets the tray turned by 90 degrees along the top edge
-- (slots go from left to right, recent boons are the row below).
--
-- Vanilla tray functions are reused. While they run for an additional player:
--  * tray related ScreenAnchors point to the player's own tray
--  * positions of created/moved obstacles are transformed to the player's layout
--  * fade directions are transformed the same way
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

-- Tray layout per player
--  Mirror: vanilla tray mirrored to the right screen edge, ShiftX from the edge
--  Top: vanilla tray turned by 90 degrees, the first slot column starts at X, the slot row at Y
local TrayLayouts = {
    [2] = { Kind = "Mirror", ShiftX = 0 },
    -- Below the boss health bar (Y ~ 40..100)
    [3] = { Kind = "Top", X = 560, Y = 180 },
}

local function GetLayout(playerId)
    return TrayLayouts[playerId] or { Kind = "Mirror", ShiftX = (playerId - 2) * 200 }
end

--- Screen position of a vanilla (left side) tray position in the player's layout
local function MapPoint(layout, x, y)
    if layout.Kind == "Top" then
        -- Vanilla Y (slot index) becomes X, vanilla X (slot / recent column) becomes Y
        return layout.X + ((y or TraitUI.IconStartY) - TraitUI.IconStartY), layout.Y + (x - CombatUI.TraitUIStart)
    end
    return ScreenWidth - x - layout.ShiftX, y
end

--- Movement angle in the player's layout. Angles: 0 right, 90 up, 180 left, 270 down.
local function MapAngle(layout, angle)
    if layout.Kind == "Top" then
        return (270 - angle) % 360
    end
    return (180 - angle) % 360
end

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

local function Log(text)
    if CoopLog then
        CoopLog("trays: " .. text)
    end
end

--- Player id of an additional player hero, nil for player 1 and unknown heroes
---@return number|nil
local function GetAdditionalPlayerId(hero)
    if hero == nil or hero == CoopPlayers.GetMainHero() then
        return nil
    end
    local playerId = CoopPlayers.GetPlayerByHero(hero)
    if playerId and playerId > 1 then
        return playerId
    end
    return nil
end

local function DescribeHero(hero)
    if hero == nil then
        return "nil"
    end
    if hero == CoopPlayers.GetMainHero() then
        return "P1"
    end
    local playerId = CoopPlayers.GetPlayerByHero(hero)
    return playerId and ("P" .. playerId) or ("unknown " .. tostring(hero))
end

local function CountShownTraits(hero)
    local count = 0
    for _, trait in pairs(hero and hero.Traits or {}) do
        if trait.AnchorId then
            count = count + 1
        end
    end
    return count
end

--- Icons left from a tray that no longer exists (e.g. drawn before the hero was registered).
--- Vanilla skips traits with AnchorId, so they must be cleared before the tray is created.
local function ClearStaleTraitAnchors(hero)
    local ids = {}
    for _, trait in pairs(hero.Traits or {}) do
        for _, key in ipairs({ "AnchorId", "TraitIconOverlay", "TraitActiveOverlay", "TraitInfoCardId" }) do
            if trait[key] then
                table.insert(ids, trait[key])
                trait[key] = nil
            end
        end
    end
    if #ids > 0 then
        Log("cleared " .. #ids .. " stale icons of " .. DescribeHero(hero))
        Destroy({ Ids = ids })
    end
end

--- Runs a vanilla tray function for the tray of the given hero
function TraitTrays.RunForHero(hero, fun, ...)
    local playerId = GetAdditionalPlayerId(hero)
    if playerId == nil or hero == activeHero then
        return fun(...)
    end

    local layout = GetLayout(playerId)

    local tray = GetTrayAnchors(playerId)
    local backup = {}
    for _, key in ipairs(TrayAnchorKeys) do
        backup[key] = ScreenAnchors[key]
        ScreenAnchors[key] = tray[key]
    end

    local prevActiveHero = activeHero
    -- CreateScreenObstacle is a Lua function that calls SpawnObstacle with OffsetX = X,
    -- so only SpawnObstacle is mirrored (mirroring both moves icons back to the left side)
    local _SpawnObstacle = SpawnObstacle
    local _Teleport = Teleport
    local _FadeObstacleIn = FadeObstacleIn
    local _HideObstacle = HideObstacle

    activeHero = hero
    SpawnObstacle = function(args)
        local isBacking = args.Group == "Combat_UI_Backing" and args.OffsetY == TraitUI.StartY
        if args.OffsetX and not args.DestinationId then
            args.OffsetX, args.OffsetY = MapPoint(layout, args.OffsetX, args.OffsetY)
        end
        if isBacking and layout.Kind == "Top" then
            -- The vertical backing image doesn't fit a horizontal tray
            args.Name = "BlankObstacle"
        end
        local id = _SpawnObstacle(args)
        if isBacking and id and layout.Kind == "Mirror" then
            -- The tray backing is drawn for the left screen edge
            SetScaleX({ Id = id, Fraction = -1 })
        end
        return id
    end
    Teleport = function(args)
        if args.OffsetX and not args.DestinationId then
            args.OffsetX, args.OffsetY = MapPoint(layout, args.OffsetX, args.OffsetY)
        end
        return _Teleport(args)
    end
    FadeObstacleIn = function(args)
        if args.Direction then
            args.Direction = MapAngle(layout, args.Direction)
        end
        return _FadeObstacleIn(args)
    end
    HideObstacle = function(args)
        if args.Angle then
            args.Angle = MapAngle(layout, args.Angle)
        end
        return _HideObstacle(args)
    end

    local result = { pcall(fun, ...) }

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
    local hideAngle = MapAngle(GetLayout(playerId), 180)

    local ids = {}
    for _, trait in pairs(hero.Traits or {}) do
        if trait.AnchorId ~= nil then
            HideObstacle({ Id = trait.AnchorId, IncludeText = true, Distance = CombatUI.FadeDistance.Trait, Angle = hideAngle, Duration = CombatUI.TraitFadeDuration, SmoothStep = true })
        end
        if trait.TraitIconOverlay ~= nil then
            SetAlpha({ Id = trait.TraitIconOverlay, Fraction = 0, Duration = CombatUI.TraitFadeDuration })
            table.insert(ids, trait.TraitIconOverlay)
        end
        if trait.TraitActiveOverlay ~= nil then
            table.insert(ids, trait.TraitActiveOverlay)
        end
        if trait.TraitInfoCardId ~= nil then
            HideObstacle({ Id = trait.TraitInfoCardId, IncludeText = true, Distance = CombatUI.FadeDistance.Trait, Angle = hideAngle, Duration = CombatUI.TraitFadeDuration, SmoothStep = true })
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
        HideObstacle({ Id = id, IncludeText = true, Distance = CombatUI.FadeDistance.Trait, Angle = hideAngle, Duration = CombatUI.TraitFadeDuration, SmoothStep = true })
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
            ClearStaleTraitAnchors(hero)
            TraitTrays.RunForHero(hero, ShowTraitUI)
            Log("refresh P" .. playerId .. ": icons=" .. CountShownTraits(hero))
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
        local mainHero = CoopPlayers.GetMainHero()
        local current = HeroContext.GetCurrentHeroContext()
        if GetAdditionalPlayerId(current) and mainHero then
            HeroContext.RunWithHeroContext(mainHero, baseFun, ...)
        else
            baseFun(...)
        end
        Log(string.format("show: context=%s main icons=%d traits=%d showing=%s hiding=%s hide=%s decision=%s",
            DescribeHero(current), CountShownTraits(mainHero), TableLength(mainHero and mainHero.Traits or {}),
            tostring(ShowingCombatUI), tostring(CombatUI.Hiding), tostring(not IsEmpty(CombatUI.Hide)),
            tostring(CombatUI.ShowUIForDecision)))

        ForEachAdditionalHero(function(playerId, hero)
            if IsTrayVisibleFor(hero) then
                if not GetTrayAnchors(playerId).TraitBacking then
                    ClearStaleTraitAnchors(hero)
                end
                TraitTrays.RunForHero(hero, baseFun)
                Log(string.format("show P%d: backing=%s icons=%d traits=%d", playerId,
                    tostring(GetTrayAnchors(playerId).TraitBacking), CountShownTraits(hero), TableLength(hero.Traits or {})))
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
        if mainHero and GetAdditionalPlayerId(HeroContext.GetCurrentHeroContext()) then
            local args = { ... }
            return HeroContext.RunWithHeroContext(mainHero, baseFun, (table.unpack or unpack)(args))
        end
        return baseFun(...)
    end)

    HookUtils.wrap("DestroyTraitUI", function(baseFun, ...)
        local mainHero = CoopPlayers.GetMainHero()
        if GetAdditionalPlayerId(HeroContext.GetCurrentHeroContext()) and mainHero then
            HeroContext.RunWithHeroContext(mainHero, baseFun, ...)
        else
            baseFun(...)
        end
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
                local hero = CurrentRun and CurrentRun.Hero
                if hero ~= activeHero and GetAdditionalPlayerId(hero) then
                    Log(funcName .. " for " .. DescribeHero(hero))
                end
                return TraitTrays.RunForHero(hero, baseFun, ...)
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
