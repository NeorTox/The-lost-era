--!strict
-- Canonical enemy definitions. Stats here are server-only and are shared by
-- the fallback template builder and the runtime EnemyService.

export type EnemyDefinition = {
	TemplateName: string,
	DisplayName: string,
	BodyColor: Color3,
	AccentColor: Color3,
	MaxHealth: number,
	Damage: number,
	WalkSpeed: number,
	AggroRange: number,
	AttackRange: number,
	AttackCooldown: number,
	ChaseLeash: number,
	DropItemId: string,
	DropChance: number,
	DropMin: number,
	DropMax: number,
}

local definitions: {[string]: EnemyDefinition} = {
	TrainingSlime = {
		TemplateName = "TrainingSlime",
		DisplayName = "Training Slime",
		BodyColor = Color3.fromRGB(92, 205, 132),
		AccentColor = Color3.fromRGB(210, 255, 220),
		MaxHealth = 90,
		Damage = 6,
		WalkSpeed = 10,
		AggroRange = 38,
		AttackRange = 5,
		AttackCooldown = 1.9,
		ChaseLeash = 90,
		DropItemId = "SlimeGel",
		DropChance = 0.65,
		DropMin = 1,
		DropMax = 2,
	},
	DriftwoodBandit = {
		TemplateName = "DriftwoodBandit",
		DisplayName = "Driftwood Bandit",
		BodyColor = Color3.fromRGB(157, 111, 75),
		AccentColor = Color3.fromRGB(225, 190, 128),
		MaxHealth = 145,
		Damage = 10,
		WalkSpeed = 14,
		AggroRange = 48,
		AttackRange = 6,
		AttackCooldown = 1.45,
		ChaseLeash = 105,
		DropItemId = "DriftwoodScrap",
		DropChance = 0.4,
		DropMin = 1,
		DropMax = 2,
	},
	TideCrab = {
		TemplateName = "TideCrab",
		DisplayName = "Tide Crab",
		BodyColor = Color3.fromRGB(47, 133, 151),
		AccentColor = Color3.fromRGB(244, 139, 91),
		MaxHealth = 210,
		Damage = 16,
		WalkSpeed = 11,
		AggroRange = 40,
		AttackRange = 5.5,
		AttackCooldown = 1.9,
		ChaseLeash = 100,
		DropItemId = "TideShell",
		DropChance = 0.35,
		DropMin = 1,
		DropMax = 1,
	},
}

local EnemyCatalog = {}

function EnemyCatalog.Get(templateName: string): EnemyDefinition?
	return definitions[templateName]
end

function EnemyCatalog.GetAll(): {EnemyDefinition}
	local result: {EnemyDefinition} = {}
	for _, definition in pairs(definitions) do
		table.insert(result, definition)
	end
	table.sort(result, function(a, b)
		return a.TemplateName < b.TemplateName
	end)
	return result
end

return EnemyCatalog
