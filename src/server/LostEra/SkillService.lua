--!strict
-- Persistent skill unlocks and server-authoritative active abilities.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local DataService = require(script.Parent.DataService)
local WeaponService = require(script.Parent.WeaponService)
local EnemyService = require(script.Parent.EnemyService)

local SkillService = {}

local MAX_EQUIPPED_SKILLS = 3
local ENERGY_REGEN_PER_SECOND = 8
local cooldowns: {[number]: {[string]: number}} = {}
local regenStarted: {[number]: boolean} = {}

local SkillList = {
	{
		Id = "PowerStrike", Name = "Power Strike",
		Description = "A focused melee shockwave that damages nearby enemies.",
		RequiredLevel = 1, PointCost = 0, Cooldown = 5, EnergyCost = 20,
		Radius = 10, DamageMultiplier = 2.0,
	},
	{
		Id = "Whirlwind", Name = "Whirlwind",
		Description = "A sweeping attack that hits every nearby enemy.",
		RequiredLevel = 12, PointCost = 2, Cooldown = 9, EnergyCost = 30,
		Radius = 14, DamageMultiplier = 1.1,
	},
	{
		Id = "HealingPulse", Name = "Healing Pulse",
		Description = "Restore a portion of your maximum health.",
		RequiredLevel = 20, PointCost = 2, Cooldown = 18, EnergyCost = 40,
		HealPercent = 0.35,
	},
	{
		Id = "ArcaneBurst", Name = "Arcane Burst",
		Description = "Release a powerful energy blast against nearby enemies.",
		RequiredLevel = 35, PointCost = 3, Cooldown = 12, EnergyCost = 45,
		Radius = 18, DamageMultiplier = 2.0,
	},
}

local Definitions: {[string]: any} = {}
for _, definition in ipairs(SkillList) do
	Definitions[definition.Id] = definition
end

local function contains(values: {string}, value: string): boolean
	return table.find(values, value) ~= nil
end

local function getProfile(player: Player)
	return DataService.GetProfile(player)
end

function SkillService.GetDefinitions()
	return SkillList
end

function SkillService.SyncPlayer(player: Player)
	local profile = getProfile(player)
	if not profile then
		return
	end
	player:SetAttribute("SkillPoints", profile.SkillPoints or 0)
	player:SetAttribute("MaxEnergy", 100)
	if typeof(player:GetAttribute("Energy")) ~= "number" then
		player:SetAttribute("Energy", 100)
	end
end

function SkillService.GetState(player: Player)
	local profile = getProfile(player)
	if not profile then
		return nil
	end

	local skills = {}
	for _, definition in ipairs(SkillList) do
		local slot = table.find(profile.EquippedSkills, definition.Id)
		table.insert(skills, {
			Id = definition.Id,
			Name = definition.Name,
			Description = definition.Description,
			RequiredLevel = definition.RequiredLevel,
			PointCost = definition.PointCost,
			Cooldown = definition.Cooldown,
			EnergyCost = definition.EnergyCost,
			Unlocked = contains(profile.UnlockedSkills, definition.Id),
			Equipped = slot ~= nil,
			EquippedSlot = slot,
		})
	end

	return {
		SkillPoints = profile.SkillPoints or 0,
		Energy = player:GetAttribute("Energy") or 0,
		MaxEnergy = player:GetAttribute("MaxEnergy") or 100,
		EquippedSkills = table.clone(profile.EquippedSkills),
		Skills = skills,
	}
end

function SkillService.Unlock(player: Player, skillId: any): (boolean, string?)
	if typeof(skillId) ~= "string" then
		return false, "InvalidSkill"
	end
	local definition = Definitions[skillId]
	if not definition then
		return false, "UnknownSkill"
	end

	local profile = getProfile(player)
	if not profile then
		return false, "ProfileUnavailable"
	end
	if contains(profile.UnlockedSkills, skillId) then
		return false, "AlreadyUnlocked"
	end

	local level = math.max(1, math.floor(tonumber(profile.Level) or 1))
	if level < definition.RequiredLevel then
		return false, "LevelRequirement"
	end
	local cost = definition.PointCost
	if (profile.SkillPoints or 0) < cost then
		return false, "InsufficientSkillPoints"
	end

	profile.SkillPoints -= cost
	table.insert(profile.UnlockedSkills, skillId)
	player:SetAttribute("SkillPoints", profile.SkillPoints)
	return true, nil
end

function SkillService.Equip(player: Player, skillId: any, slot: any): (boolean, string?)
	if typeof(skillId) ~= "string" or typeof(slot) ~= "number" or slot ~= math.floor(slot) then
		return false, "InvalidRequest"
	end
	if slot < 1 or slot > MAX_EQUIPPED_SKILLS then
		return false, "InvalidSlot"
	end

	local definition = Definitions[skillId]
	local profile = getProfile(player)
	if not definition or not profile then
		return false, "UnknownSkill"
	end
	if not contains(profile.UnlockedSkills, skillId) then
		return false, "SkillLocked"
	end

	local existingSlot = table.find(profile.EquippedSkills, skillId)
	if existingSlot and existingSlot ~= slot then
		return false, "AlreadyEquipped"
	end

	profile.EquippedSkills[slot] = skillId
	return true, nil
end

local function hasLineOfSight(character: Model, enemy: Model, origin: Vector3, target: Vector3): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, enemy }
	params.IgnoreWater = true
	return Workspace:Raycast(origin, target - origin, params) == nil
end

function SkillService.Use(player: Player, skillId: any): (boolean, string, any?)
	if typeof(skillId) ~= "string" then
		return false, "InvalidSkill", nil
	end
	local definition = Definitions[skillId]
	if not definition then
		return false, "UnknownSkill", nil
	end

	local profile = getProfile(player)
	if not profile then
		return false, "ProfileUnavailable", nil
	end
	if not contains(profile.UnlockedSkills, skillId) then
		return false, "SkillLocked", nil
	end
	if not contains(profile.EquippedSkills, skillId) then
		return false, "SkillNotEquipped", nil
	end

	local now = os.clock()
	local userCooldowns = cooldowns[player.UserId]
	if not userCooldowns then
		userCooldowns = {}
		cooldowns[player.UserId] = userCooldowns
	end
	if now < (userCooldowns[skillId] or 0) then
		return false, "Cooldown", { ReadyAt = userCooldowns[skillId] }
	end

	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	local root = if character then character:FindFirstChild("HumanoidRootPart") else nil
	if not character or not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return false, "CharacterUnavailable", nil
	end

	local energy = tonumber(player:GetAttribute("Energy")) or 0
	if energy < definition.EnergyCost then
		return false, "InsufficientEnergy", { Energy = energy, Required = definition.EnergyCost }
	end

	if definition.HealPercent then
		if humanoid.Health >= humanoid.MaxHealth then
			return false, "HealthFull", nil
		end
		local healing = math.max(1, math.floor(humanoid.MaxHealth * definition.HealPercent))
		humanoid.Health = math.min(humanoid.MaxHealth, humanoid.Health + healing)
		player:SetAttribute("Energy", energy - definition.EnergyCost)
		userCooldowns[skillId] = now + definition.Cooldown
		player:SetAttribute("SkillReadyAt_" .. skillId, userCooldowns[skillId])
		return true, "SkillUsed", { Healing = healing, ReadyAt = userCooldowns[skillId] }
	end

	local level = math.max(1, math.floor(tonumber(profile.Level) or 1))
	local weapon = WeaponService.GetStats(player)
	local baseDamage = math.floor((12 + level * 1.6) * weapon.DamageMultiplier * definition.DamageMultiplier)
	local overlap = OverlapParams.new()
	overlap.FilterType = Enum.RaycastFilterType.Exclude
	overlap.FilterDescendantsInstances = { character }

	local parts = Workspace:GetPartBoundsInRadius(root.Position, definition.Radius, overlap)
	local hitEnemies: {[Model]: boolean} = {}
	local hitCount = 0
	local totalDamage = 0

	for _, part in ipairs(parts) do
		local enemy = part:FindFirstAncestorOfClass("Model")
		if enemy and not hitEnemies[enemy] and EnemyService.IsEnemyModel(enemy)
			and enemy:GetAttribute("IslandId") == player:GetAttribute("CurrentIsland")
			and enemy:IsDescendantOf(Workspace) then
			local enemyHumanoid = enemy:FindFirstChildOfClass("Humanoid")
			local enemyRoot = enemy:FindFirstChild("HumanoidRootPart")
			if enemyHumanoid and enemyHumanoid.Health > 0 and enemyRoot and enemyRoot:IsA("BasePart")
				and hasLineOfSight(character, enemy, root.Position, enemyRoot.Position) then
				hitEnemies[enemy] = true
				enemy:SetAttribute("LastHitUserId", player.UserId)
				enemyHumanoid:TakeDamage(baseDamage)
				hitCount += 1
				totalDamage += baseDamage
			end
		end
	end

	if hitCount == 0 then
		return false, "NoTargets", nil
	end

	player:SetAttribute("Energy", energy - definition.EnergyCost)
	userCooldowns[skillId] = now + definition.Cooldown
	player:SetAttribute("SkillReadyAt_" .. skillId, userCooldowns[skillId])
	return true, "SkillUsed", {
		HitCount = hitCount,
		TotalDamage = totalDamage,
		ReadyAt = userCooldowns[skillId],
	}
end

function SkillService.StartEnergyRegeneration(player: Player)
	if regenStarted[player.UserId] then
		return
	end
	regenStarted[player.UserId] = true
	task.spawn(function()
		while player.Parent == Players and regenStarted[player.UserId] do
			task.wait(1)
			local energy = tonumber(player:GetAttribute("Energy")) or 0
			local maximum = tonumber(player:GetAttribute("MaxEnergy")) or 100
			if energy < maximum then
				player:SetAttribute("Energy", math.min(maximum, energy + ENERGY_REGEN_PER_SECOND))
			end
		end
	end)
end

function SkillService.ReleasePlayer(player: Player)
	regenStarted[player.UserId] = nil
	cooldowns[player.UserId] = nil
end

return SkillService
