--
-- A healing fountain heals every alive player, not only the one that used it.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"
---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"

---@class FountainHooks
local FountainHooks = {}

--- Fountain heal of another player: the same heal fraction and the player's own
--- fountain damage bonus traits (vanilla updates them only for the user)
---@private
function FountainHooks.HealOtherPlayer(hero, healArgs)
    Heal(hero, {
        HealFraction = healArgs.HealFraction,
        SourceName = healArgs.SourceName,
        CoopFountainShared = true,
    })

    local hasDamageBonus = false
    for _, traitData in pairs(hero.Traits or {}) do
        if traitData.FountainDamageBonus then
            hasDamageBonus = true
            traitData.AccumulatedFountainDamageBonus = (traitData.AccumulatedFountainDamageBonus or 0) + (traitData.FountainDamageBonus - 1)
            ExtractValues(hero, traitData, traitData)
        end
    end
    if hasDamageBonus then
        FountainDamagePresentation()
    end
end

function FountainHooks.InitHooks()
    HookUtils.wrap("Heal", function(baseFun, victim, triggerArgs)
        local result = baseFun(victim, triggerArgs)

        if triggerArgs and triggerArgs.SourceName == "HealthFountain" and not triggerArgs.CoopFountainShared
            and CoopPlayers.IsPlayerHero(victim) then
            for _, hero in CoopPlayers.PlayersIterator() do
                if hero ~= victim and hero and not hero.IsDead then
                    HeroContext.RunWithHeroContext(hero, FountainHooks.HealOtherPlayer, hero, triggerArgs)
                end
            end
            thread(UpdateHealthUI)
        end

        return result
    end)
end

return FountainHooks
