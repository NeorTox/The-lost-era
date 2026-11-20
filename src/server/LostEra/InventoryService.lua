--!strict
-- Inventory mutations are server-only. Item definitions are intentionally centralized.

local DataService = require(script.Parent.DataService)

local InventoryService = {}
local MAX_STACK = 999

local ItemDefinitions = {
	HealthPotion = { DisplayName = "Health Potion", Stackable = true, MaxStack = 99 },
	SmallCoinPouch = { DisplayName = "Small Coin Pouch", Stackable = true, MaxStack = 99 },
}

local function getInventory(player: Player)
	local profile = DataService.GetProfile(player)
	if not profile then
		return nil
	end
	if typeof(profile.Inventory) ~= "table" then
		profile.Inventory = {}
	end
	return profile.Inventory
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
	local inventory = getInventory(player)
	if not inventory then
		return false, "ProfileUnavailable"
	end

	local safeAmount = math.clamp(math.floor(amount), 1, MAX_STACK)
	local current = math.max(0, math.floor(tonumber(inventory[itemId]) or 0))
	local cap = if definition.Stackable then definition.MaxStack else 1
	if current + safeAmount > cap then
		return false, "StackLimit"
	end

	inventory[itemId] = current + safeAmount
	return true, nil
end

function InventoryService.RemoveItem(player: Player, itemId: string, amount: number): (boolean, string?)
	if not ItemDefinitions[itemId] then
		return false, "UnknownItem"
	end
	local inventory = getInventory(player)
	if not inventory then
		return false, "ProfileUnavailable"
	end

	local safeAmount = math.clamp(math.floor(amount), 1, MAX_STACK)
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
