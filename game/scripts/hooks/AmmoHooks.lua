--
-- Cast ammo (red crystals) belongs to the player that fired it:
--  * it has the outline color of the owner
--  * only the owner can pick it up while the owner is alive
--  * it flies to the owner when the owner has free ammo slots
--

---@type CoopPlayers
local CoopPlayers = ModRequire "../CoopPlayers.lua"
---@type HeroContext
local HeroContext = ModRequire "../HeroContext.lua"
---@type HookUtils
local HookUtils = ModRequire "../HookUtils.lua"
---@type CoopModConfig
local Config = ModRequire "../config.lua"

---@class AmmoHooks
local AmmoHooks = {}

-- Owner of the ammo that CheckAmmoDrop is creating right now
local pendingOwnerId = nil

-- Time for the crystal to fall on the ground before it flies to the owner
local LANDING_DELAY = 0.8
local FLY_DURATION = 0.35
local CHECK_INTERVAL = 0.5

---@param hero table
local function HasFreeAmmoSlot(hero)
    if not hero or not hero.ObjectId then
        return false
    end
    local current = GetWeaponProperty({ Id = hero.ObjectId, WeaponName = "RangedWeapon", Property = "Ammo" }) or 0
    local max = GetWeaponMaxAmmo({ Id = hero.ObjectId, WeaponName = "RangedWeapon" }) or 0
    return current < max
end

--- The owner of an ammo crystal, nil if anybody can take it
---@param item table consumable item
---@return table?
function AmmoHooks.GetAliveOwner(item)
    if not item or not item.CoopAmmoOwner then
        return nil
    end
    local owner = CoopPlayers.GetHero(item.CoopAmmoOwner)
    if owner and not owner.IsDead and owner.ObjectId then
        return owner
    end
    return nil
end

--- Can the hero pick up this consumable item?
---@param item table
---@param hero table
function AmmoHooks.CanPickUp(item, hero)
    if item.CoopAmmoPickedUp then
        return false
    end
    local owner = AmmoHooks.GetAliveOwner(item)
    return owner == nil or owner == hero
end

---@private
function AmmoHooks.MarkOwner(item, playerId)
    item.CoopAmmoOwner = playerId
    local outline = Config["Player" .. playerId .. "Outline"]
    if outline then
        AddOutline(MergeTables(outline, { Id = item.ObjectId }))
    end
end

---@private
function AmmoHooks.FlyToOwnerThread(item)
    wait(LANDING_DELAY, RoomThreadName)
    while item.ObjectId and IdExists({ Id = item.ObjectId }) and not item.CoopAmmoPickedUp do
        local owner = AmmoHooks.GetAliveOwner(item)
        if not owner then
            -- The owner is dead, anybody can take it
            return
        end
        if HasFreeAmmoSlot(owner) and not owner.HandlingDeath then
            Move({ Id = item.ObjectId, DestinationId = owner.ObjectId, Duration = FLY_DURATION })
            wait(FLY_DURATION, RoomThreadName)
            if item.CoopAmmoPickedUp or not IdExists({ Id = item.ObjectId }) then
                return
            end
            owner = AmmoHooks.GetAliveOwner(item)
            if owner and HasFreeAmmoSlot(owner) then
                item.CoopAmmoPickedUp = true
                HeroContext.RunWithHeroContext(owner, PurchaseConsumableItem, CurrentRun, item,
                    { triggeredById = owner.ObjectId, UserId = owner.ObjectId, AttachedTable = item })
                return
            end
        end
        wait(CHECK_INTERVAL, RoomThreadName)
    end
end

function AmmoHooks.InitHooks()
    HookUtils.wrap("CheckAmmoDrop", function(baseFun, currentRun, targetId, ammoDropData, numDrops)
        local owner = ammoDropData and ammoDropData.AttackerId and CoopPlayers.GetHeroByUnit(ammoDropData.AttackerId)
        pendingOwnerId = owner and CoopPlayers.GetPlayerByHero(owner) or nil
        local ok, err = pcall(baseFun, currentRun, targetId, ammoDropData, numDrops)
        pendingOwnerId = nil
        if not ok then
            error(err, 0)
        end
    end)

    HookUtils.wrap("CreateConsumableItem", function(baseFun, consumableId, consumableName, ...)
        local item = baseFun(consumableId, consumableName, ...)
        if item and pendingOwnerId and consumableName == "AmmoPack" and CoopPlayers.GetPlayersCount() > 1 then
            AmmoHooks.MarkOwner(item, pendingOwnerId)
            thread(AmmoHooks.FlyToOwnerThread, item)
        end
        return item
    end)
end

return AmmoHooks
