--!strict
-- Inventory mutations are server-only. Item definitions are intentionally centralized.

local DataService = require(script.Parent.DataService)

local InventoryService = {}
local MAX_STACK = 999

local ItemDefinitions = {
	HealthPotion = { DisplayName = "Health Potion", Stackable = true, MaxStack = 99 },
	SmallCoinPouch = { DisplayName = "Small Coin Pouch", Stackable = true, MaxStack = 99 },
	SlimeGel = { DisplayName = "Slime Gel", Stackable = true, MaxStack = 999 },
	DriftwoodScrap = { DisplayName = "Driftwood Scrap", Stackable = true, MaxStack = 999 },
	TideShell = { DisplayName = "Tide Shell", Stackable = true, MaxStack = 999 },
	TideWardenSigil = { DisplayName = "Tide Warden Sigil", Stackable = false, MaxStack = 1 },
	TrainingBlade = { DisplayName = "Training Blade", Stackable = false, MaxStack = 1, IsWeapon = true },
	BronzeSword = { DisplayName = "Bronze Sword", Stackable = false, MaxStack = 1, IsWeapon = true },
	IronBlade = { DisplayName = "Iron Blade", Stackable = false, MaxStack = 1, IsWeapon = true },
}

local function getInventory(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return nil, nil
	end
	if typeof(profile.Inventory) ~= "table" then
		profile.Inventory = {}
	end
	return profile.Inventory, profile
end

local function validateAmount(amount: number): (boolean, number)
	if typeof(amount) ~= "number" or amount ~= amount or amount == math.huge or amount == -math.huge
		or amount ~= math.floor(amount) or amount < 1 or amount > MAX_STACK then
		return false, 0
	end
	return true, amount
end

function InventoryService.GetDefinitions()
	return ItemDefinitions
end

function InventoryService.GetCount(player: Player, itemId: string): number
	local inventory = getInventory(player)
	if not inventory then
		return 0
	end
	return math.max(0, math.floor(tonumber(inventory[itemId]) or 0))
end

function InventoryService.AddItem(player: Player, itemId: string, amount: number): (boolean, string?)
	local definition = ItemDefinitions[itemId]
	if not definition then
		return false, "UnknownItem"
	end
	local validAmount, safeAmount = validateAmount(amount)
	if not validAmount then
		return false, "InvalidAmount"
	end
	local inventory = getInventory(player)
	if not inventory then
		return false, "ProfileUnavailable"
	end

	local current = math.max(0, math.floor(tonumber(inventory[itemId]) or 0))
	local cap = if definition.Stackable then definition.MaxStack else 1
	if current + safeAmount > cap then
		return false, "StackLimit"
	end

	inventory[itemId] = current + safeAmount
	return true, nil
end

function InventoryService.RemoveItem(player: Player, itemId: string, amount: number): (boolean, string?)
	local definition = ItemDefinitions[itemId]
	if not definition then
		return false, "UnknownItem"
	end
	local validAmount, safeAmount = validateAmount(amount)
	if not validAmount then
		return false, "InvalidAmount"
	end
	local inventory, profile = getInventory(player)
	if not inventory or not profile then
		return false, "ProfileUnavailable"
	end
	if definition.IsWeapon and profile.EquippedWeapon == itemId then
		return false, "WeaponEquipped"
	end

	local current = math.max(0, math.floor(tonumber(inventory[itemId]) or 0))
	if current < safeAmount then
		return false, "InsufficientItems"
	end

	local remaining = current - safeAmount
	if remaining == 0 then
		inventory[itemId] = nil
	else
		inventory[itemId] = remaining
	end
	return true, nil
end

return InventoryService
