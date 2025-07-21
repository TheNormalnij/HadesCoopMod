--
-- Copyright (c) Uladzislau Nikalayevich <thenormalnij@gmail.com>. All rights reserved.
-- Licensed under the MIT license. See LICENSE file in the project root for details.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"
---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"

local _OnControlPressed = OnControlPressed
OnControlPressed = function(args)
    if args[1] == "AdvancedTooltip" then
        -- Nasty hack here
        local originalHandler = args[2]
        args[2] = function()
            local IsEmptyOriginal = IsEmpty
            IsEmpty = function(param)
                local hero = CurrentRun and CurrentRun.Hero
                if hero and param == hero.Traits then
                    IsEmpty = IsEmptyOriginal
                    return false
                else
                    return IsEmptyOriginal(param)
                end
            end

            originalHandler()
            IsEmpty = IsEmptyOriginal
        end
    end
    _OnControlPressed {
        args[1],
        function(triggerArgs)
            local hero = CoopPlayers.GetHero(triggerArgs.mPlayerIndex)
            if hero then
                HeroContext.RunWithHeroContext(hero, args[2], triggerArgs)
            end
        end
    }
end

HookUtils.wrap("AddInputBlock", function(baseFun, argumenst)
    if argumenst.PlayerIndex then
        baseFun(argumenst)
    else
        for playerId = 1, CoopPlayers.GetPlayersCount() do
            argumenst.PlayerIndex = playerId
            baseFun(argumenst)
        end
    end
end)

HookUtils.wrap("RemoveInputBlock", function(baseFun, argumenst)
    if argumenst.PlayerIndex then
        baseFun(argumenst)
    else
        for playerId = 1, CoopPlayers.GetPlayersCount() do
            argumenst.PlayerIndex = playerId
            baseFun(argumenst)
        end
    end
end)

HookUtils.wrap("NotifyOnControlPressed", function(baseFun, argumenst)
    if argumenst.PlayerIndex then
        baseFun(argumenst)
    elseif argumenst.Notify == "FishingInput" then
        local playerId = CoopPlayers.GetPlayerByHero(CurrentRun.Hero) or 1
        argumenst.PlayerIndex = playerId
        baseFun(argumenst)
    else
        baseFun(argumenst)
    end
end)
