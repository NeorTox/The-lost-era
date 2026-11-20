--!strict
-- Server-authoritative weapon equipment and combat statistics.
local DataService = require(script.Parent.DataService)
local InventoryService = require(script.Parent.InventoryService)

local WeaponService = {}

local Definitions = {
	TrainingBlade = {
		Id = "TrainingBlade",
		DisplayName = "Training Blade",
		RequiredLevel = 1,
		DamageMultiplier = 1.0,
		AttackRange = 12,
	},
	BronzeSword = {
		Id = "BronzeSword",
		DisplayName = "Bronze Sword",
		RequiredLevel = 10,
		DamageMultiplier = 1.2,
		AttackRange = 12,
	},
	IronBlade = {
		Id = "IronBlade",
		DisplayName = "Iron Blade",
		RequiredLevel = 30,
		DamageMultiplier = 1.45,
		AttackRange = 13,
	},
}

function WeaponService.GetDefinitions()
	return Definitions
end

function WeaponService.GetEquippedId(player: Player): string
	local profile = DataService.GetProfile(player)
	if not profile then
		return "TrainingBlade"
	end
	local weaponId = profile.EquippedWeapon
	return if typeof(weaponId) == "string" and Definitions[weaponId] then weaponId else "TrainingBlade"
end

function WeaponService.GetStats(player: Player)
	local weaponId = WeaponService.GetEquippedId(player)
	return Definitions[weaponId] or Definitions.TrainingBlade
end

function WeaponService.SyncPlayer(player: Player)
	player:SetAttribute("EquippedWeapon", WeaponService.GetEquippedId(player))
end

function WeaponService.Equip(player: Player, weaponId: any): (boolean, string?)
	if typeof(weaponId) ~= "string" then
		return false, "InvalidWeapon"
	end
	local definition = Definitions[weaponId]
	if not definition then
		return false, "UnknownWeapon"
	end

	local profile = DataService.GetProfile(player)
	if not profile then
		return false, "ProfileUnavailable"
	end
	local level = math.max(1, math.floor(tonumber(profile.Level) or 1))
	if level < definition.RequiredLevel then
		return false, "LevelRequirement"
	end
	if InventoryService.GetCount(player, weaponId) < 1 then
		return false, "WeaponNotOwned"
	end

	profile.EquippedWeapon = weaponId
	player:SetAttribute("EquippedWeapon", weaponId)
	return true, nil
end

return WeaponService
