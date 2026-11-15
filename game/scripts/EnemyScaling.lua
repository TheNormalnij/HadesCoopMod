--
-- Enemy scaling by the number of players (like Seamless Coop in Elden Ring).
--
-- Every additional alive player adds a percentage to the enemy health (and armor)
-- and, optionally, to the damage enemies deal to players. Values are in config.lua.
--

---@type CoopPlayers
local CoopPlayers = ModRequire "CoopPlayers.lua"
---@type HookUtils
local HookUtils = ModRequire "HookUtils.lua"
---@type CoopModConfig
local Config = ModRequire "config.lua"

---@class EnemyScaling
local EnemyScaling = {}

---@private
function EnemyScaling.GetSettings()
    return Config.EnemyScaling or {}
end

--- Number of additional alive players (0 for single player)
function EnemyScaling.GetExtraPlayers()
    local alive = #CoopPlayers.GetAliveHeroes()
    return math.max(0, alive - 1)
end

---@param enemy table
---@param regularKey string
---@param bossKey string
local function GetMultiplier(enemy, regularKey, bossKey)
    local settings = EnemyScaling.GetSettings()
    if not settings.Enabled then
        return 1
    end
    local perPlayer = (enemy and enemy.IsBoss) and settings[bossKey] or settings[regularKey]
    return 1 + (perPlayer or 0) * EnemyScaling.GetExtraPlayers()
end

---@param enemy table
function EnemyScaling.GetHealthMultiplier(enemy)
    return GetMultiplier(enemy, "HealthPerPlayer", "BossHealthPerPlayer")
end

---@param enemy table attacker
function EnemyScaling.GetDamageMultiplier(enemy)
    return GetMultiplier(enemy, "DamagePerPlayer", "BossDamagePerPlayer")
end

---@private
function EnemyScaling.SetupEnemyObjectWrap(baseFun, newEnemy, currentRun, args)
    if newEnemy and not newEnemy.CoopScaled then
        -- Vanilla multiplies MaxHealth and HealthBuffer (armor) by HealthMultiplier
        local multiplier = EnemyScaling.GetHealthMultiplier(newEnemy)
        if multiplier ~= 1 then
            newEnemy.HealthMultiplier = (newEnemy.HealthMultiplier or 1) * multiplier
        end
        newEnemy.CoopScaled = true
    end
    return baseFun(newEnemy, currentRun, args)
end

--- Scales the damage of an enemy hit on a player
---@param triggerArgs table OnHit arguments
---@param attacker table?
function EnemyScaling.ScaleDamageToPlayer(triggerArgs, attacker)
    if not attacker or not triggerArgs.DamageAmount then
        return
    end
    local multiplier = EnemyScaling.GetDamageMultiplier(attacker)
    if multiplier ~= 1 then
        triggerArgs.DamageAmount = triggerArgs.DamageAmount * multiplier
    end
end

function EnemyScaling.InitHooks()
    HookUtils.wrap("SetupEnemyObject", EnemyScaling.SetupEnemyObjectWrap)
end

return EnemyScaling
