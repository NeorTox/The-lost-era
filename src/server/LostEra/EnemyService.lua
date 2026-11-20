--!strict
-- Enemy lifecycle and server-authoritative aggro AI.
-- Art-authored Models may live in ServerStorage/EnemyTemplates. Missing starter
-- templates are supplied by EnemyTemplateService using simple R6 blockout rigs.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)
local EnemyCatalog = require(script.Parent.EnemyCatalog)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local InventoryService = require(script.Parent.InventoryService)
local SafeZoneService = require(script.Parent.SafeZoneService)

local EnemyService = {}
local activeEnemies: {[Model]: boolean} = {}
local rewardRandom = Random.new()

local function getRoot(model: Model): BasePart?
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then return root end
	return nil
end

local function isFiniteNumber(value: any): boolean
	return typeof(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function boundedNumber(value: any, fallback: number, minimum: number, maximum: number): number
	local selected = if isFiniteNumber(value) then value else fallback
	return math.clamp(selected, minimum, maximum)
end

local function boundedInteger(value: any, fallback: number, minimum: number, maximum: number): number
	return math.floor(boundedNumber(value, fallback, minimum, maximum))
end

local function findNearestPlayer(
	position: Vector3,
	islandId: string,
	maxDistance: number,
	homePosition: Vector3,
	chaseLeash: number
): (Player?, number)
	local nearest: Player? = nil
	local nearestDistance = maxDistance
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart")
			and player:GetAttribute("CurrentIsland") == islandId
			and player:GetAttribute("InSafeZone") ~= true
			and not SafeZoneService.IsPlayerInSafeZone(player)
			and (root.Position - homePosition).Magnitude <= chaseLeash then
			local distance = (root.Position - position).Magnitude
			if distance < nearestDistance then
				nearest = player
				nearestDistance = distance
			end
		end
	end
	return nearest, nearestDistance
end

function EnemyService.IsEnemyModel(model: Instance): boolean
	return model:IsA("Model") and model:GetAttribute("IsLostEraEnemy") == true
end

local function startAI(enemy: Model)
	task.spawn(function()
		local humanoid = enemy:FindFirstChildOfClass("Humanoid")
		local root = getRoot(enemy)
		if not humanoid or not root then return end

		local aggroRange = boundedNumber(enemy:GetAttribute("AggroRange"), 55, 5, 250)
		local attackRange = boundedNumber(enemy:GetAttribute("AttackRange"), 5, 2, 20)
		local attackDamage = boundedInteger(enemy:GetAttribute("AttackDamage"), 8, 1, 1000000)
		local attackCooldown = boundedNumber(enemy:GetAttribute("AttackCooldown"), 1.5, 0.25, 30)
		local chaseLeash = boundedNumber(enemy:GetAttribute("ChaseLeash"), 100, 20, 500)
		local homeValue = enemy:GetAttribute("HomePosition")
		local homePosition = if typeof(homeValue) == "Vector3" then homeValue else root.Position
		local nextAttackAt = 0

		while enemy.Parent and humanoid.Health > 0 do
			local islandId = enemy:GetAttribute("IslandId")
			if typeof(islandId) ~= "string" then break end

			local target, distance = findNearestPlayer(
				root.Position,
				islandId,
				aggroRange,
				homePosition,
				chaseLeash
			)

			if target and target.Character then
				local targetCharacter = target.Character
				local targetHumanoid = targetCharacter:FindFirstChildOfClass("Humanoid")
				local targetRoot = targetCharacter:FindFirstChild("HumanoidRootPart")
				if targetHumanoid and targetHumanoid.Health > 0 and targetRoot and targetRoot:IsA("BasePart")
					and target:GetAttribute("CurrentIsland") == islandId
					and target:GetAttribute("InSafeZone") ~= true
					and not SafeZoneService.IsPlayerInSafeZone(target) then
					if distance <= attackRange then
						humanoid:MoveTo(root.Position)
						if os.clock() >= nextAttackAt then
							nextAttackAt = os.clock() + attackCooldown
							-- Recheck protection immediately before damage is applied.
							if target:GetAttribute("CurrentIsland") == islandId
								and target:GetAttribute("InSafeZone") ~= true
								and not SafeZoneService.IsPlayerInSafeZone(target)
								and target.Character == targetCharacter
								and targetHumanoid.Health > 0
								and (targetRoot.Position - root.Position).Magnitude <= attackRange + 1 then
								targetHumanoid:TakeDamage(attackDamage)
							end
						end
					else
						humanoid:MoveTo(targetRoot.Position)
					end
				else
					humanoid:MoveTo(homePosition)
				end
			elseif (root.Position - homePosition).Magnitude > 3 then
				humanoid:MoveTo(homePosition)
			else
				humanoid:MoveTo(root.Position)
			end

			task.wait(0.35)
		end
		activeEnemies[enemy] = nil
	end)
end

function EnemyService.Spawn(
	templateName: string,
	spawnCFrame: CFrame,
	level: number,
	islandId: string,
	options: {[string]: any}?
): Model?
	local templates = ServerStorage:FindFirstChild("EnemyTemplates")
	local template = templates and templates:FindFirstChild(templateName)
	if not template or not template:IsA("Model") then
		warn("[TheLostEra] Missing enemy template:", templateName)
		return nil
	end

	local enemy = template:Clone()
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	local root = getRoot(enemy)
	if not humanoid or not root then
		warn("[TheLostEra] Enemy template needs a Humanoid and HumanoidRootPart:", templateName)
		enemy:Destroy()
		return nil
	end

	local island = Config.GetIslandById(islandId)
	if not island then
		warn("[TheLostEra] Cannot spawn enemy for unknown island:", islandId)
		enemy:Destroy()
		return nil
	end
	if not isFiniteNumber(level) or level ~= math.floor(level) then
		warn("[TheLostEra] Enemy level must be a finite whole number:", templateName, level)
		enemy:Destroy()
		return nil
	end

	local safeLevel = math.clamp(level, 1, Config.MaxLevel)
	local settings = options or {}
	local definition = EnemyCatalog.Get(templateName)
	local isBoss = settings.IsBoss == true
	if isBoss then
		if safeLevel ~= island.BossLevel then
			warn("[TheLostEra] Boss level does not match configured island boss level:", islandId, safeLevel)
			enemy:Destroy()
			return nil
		end
	elseif safeLevel < island.EnemyLevelMin or safeLevel > island.EnemyLevelMax then
		warn("[TheLostEra] Enemy level is outside configured island band:", islandId, safeLevel)
		enemy:Destroy()
		return nil
	end

	local defaultMaxHealth = if definition then definition.MaxHealth else 100 + safeLevel * 24
	local defaultDamage = if definition then definition.Damage else 5 + safeLevel * 1.4
	local defaultAggroRange = if definition then definition.AggroRange else 55
	local defaultAttackRange = if definition then definition.AttackRange else 5
	local defaultAttackCooldown = if definition then definition.AttackCooldown else 1.5
	local defaultWalkSpeed = if definition then definition.WalkSpeed else 12
	local defaultChaseLeash = if definition then definition.ChaseLeash else 100

	local rewardConfig = Config.Economy.EnemyRewards
	local defaultXPReward = rewardConfig.XPBase + safeLevel * rewardConfig.XPPerLevel
	local defaultCoinReward = rewardConfig.CoinBase + safeLevel * rewardConfig.CoinPerLevel
	local xpReward = boundedInteger(settings.XPReward, defaultXPReward, 1, Config.MaxCurrencyBalance)
	local coinReward = boundedInteger(settings.CoinReward, defaultCoinReward, 0, Config.MaxCurrencyBalance)
	local maxHealth = boundedInteger(settings.MaxHealth, defaultMaxHealth, 50, 5000000)
	local damage = boundedInteger(settings.Damage, defaultDamage, 1, 1000000)
	local aggroRange = boundedNumber(settings.AggroRange, defaultAggroRange, 5, 250)
	local attackRange = boundedNumber(settings.AttackRange, defaultAttackRange, 2, 20)
	local attackCooldown = boundedNumber(settings.AttackCooldown, defaultAttackCooldown, 0.25, 30)
	local walkSpeed = boundedNumber(settings.WalkSpeed, defaultWalkSpeed, 6, 32)
	local chaseLeash = boundedNumber(settings.ChaseLeash, defaultChaseLeash, 20, 500)

	local dropItemId = if typeof(settings.DropItemId) == "string"
		then settings.DropItemId
		elseif definition then definition.DropItemId
		else nil
	local itemDefinitions = InventoryService.GetDefinitions()
	if typeof(dropItemId) ~= "string" or not itemDefinitions[dropItemId] then
		dropItemId = nil
	end
	local defaultDropChance = if definition then definition.DropChance else 0
	local defaultDropMin = if definition then definition.DropMin else 1
	local defaultDropMax = if definition then definition.DropMax else 1
	local dropChance = boundedNumber(settings.DropChance, defaultDropChance, 0, 1)
	local dropMin = boundedInteger(settings.DropMin, defaultDropMin, 1, 99)
	local dropMax = boundedInteger(settings.DropMax, defaultDropMax, dropMin, 99)

	enemy:SetAttribute("IsLostEraEnemy", true)
	enemy:SetAttribute("EnemyLevel", safeLevel)
	enemy:SetAttribute("EnemyTemplateName", templateName)
	enemy:SetAttribute("IslandId", islandId)
	enemy:SetAttribute("IsBoss", isBoss)
	enemy:SetAttribute("XPReward", xpReward)
	enemy:SetAttribute("CoinReward", coinReward)
	enemy:SetAttribute("AggroRange", aggroRange)
	enemy:SetAttribute("AttackRange", attackRange)
	enemy:SetAttribute("AttackDamage", damage)
	enemy:SetAttribute("AttackCooldown", attackCooldown)
	enemy:SetAttribute("ChaseLeash", chaseLeash)
	enemy:SetAttribute("HomePosition", spawnCFrame.Position)
	enemy:SetAttribute("DropItemId", dropItemId)
	enemy:SetAttribute("DropChance", dropChance)
	enemy:SetAttribute("DropMin", dropMin)
	enemy:SetAttribute("DropMax", dropMax)

	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth
	humanoid.WalkSpeed = walkSpeed
	if enemy.PrimaryPart == nil then enemy.PrimaryPart = root end
	enemy.Parent = Workspace
	enemy:PivotTo(spawnCFrame)
	if not root.Anchored then
		root:SetNetworkOwner(nil)
	end
	activeEnemies[enemy] = true

	humanoid.Died:Connect(function()
		if enemy:GetAttribute("RewardGranted") == true then return end
		enemy:SetAttribute("RewardGranted", true)

		local userId = enemy:GetAttribute("LastHitUserId")
		local killer = if isFiniteNumber(userId) and userId == math.floor(userId)
			then Players:GetPlayerByUserId(userId)
			else nil
		if killer then
			ProgressionService.AddXP(killer, enemy:GetAttribute("XPReward") or 0)
			ProgressionService.AddCoins(killer, enemy:GetAttribute("CoinReward") or 0)
			if enemy:GetAttribute("IslandId") == "SunsetBay"
				and enemy:GetAttribute("EnemyTemplateName") == "TrainingSlime" then
				QuestService.AddProgress(killer, "WelcomeToSunsetBay", 1)
			end

			local itemId = enemy:GetAttribute("DropItemId")
			local chance = boundedNumber(enemy:GetAttribute("DropChance"), 0, 0, 1)
			local minimum = boundedInteger(enemy:GetAttribute("DropMin"), 1, 1, 99)
			local maximum = boundedInteger(enemy:GetAttribute("DropMax"), minimum, minimum, 99)
			if typeof(itemId) == "string" and chance > 0 and rewardRandom:NextNumber() < chance then
				local amount = rewardRandom:NextInteger(minimum, maximum)
				local added, reason = InventoryService.AddItem(killer, itemId, amount)
				if not added then
					warn("[TheLostEra] Enemy drop could not be added to inventory:", itemId, reason)
				end
			end
		end

		activeEnemies[enemy] = nil
		task.delay(3, function()
			if enemy.Parent then enemy:Destroy() end
		end)
	end)

	enemy.Destroying:Connect(function()
		activeEnemies[enemy] = nil
	end)

	startAI(enemy)
	return enemy
end

function EnemyService.GetActiveCount(): number
	local count = 0
	for enemy in pairs(activeEnemies) do
		if enemy.Parent then
			count += 1
		else
			activeEnemies[enemy] = nil
		end
	end
	return count
end

return EnemyService
