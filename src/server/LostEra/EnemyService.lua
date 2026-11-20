--!strict
-- Enemy lifecycle and simple server-authoritative aggro AI.
-- Place NPC Models with a Humanoid and HumanoidRootPart in ServerStorage/EnemyTemplates.

local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)

local EnemyService = {}
local activeEnemies: {[Model]: boolean} = {}

local function getRoot(model: Model): BasePart?
	local root = model:FindFirstChild("HumanoidRootPart")
	if root and root:IsA("BasePart") then return root end
	return nil
end

local function findNearestPlayer(position: Vector3, islandId: string, maxDistance: number)
	local nearest: Player? = nil
	local nearestDistance = maxDistance
	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart")
			and player:GetAttribute("CurrentIsland") == islandId then
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

		local aggroRange = enemy:GetAttribute("AggroRange") or 55
		local attackRange = enemy:GetAttribute("AttackRange") or 5
		local attackDamage = enemy:GetAttribute("AttackDamage") or 8
		local attackCooldown = enemy:GetAttribute("AttackCooldown") or 1.5
		local nextAttackAt = 0

		while enemy.Parent and humanoid.Health > 0 do
			local islandId = enemy:GetAttribute("IslandId")
			if typeof(islandId) ~= "string" then break end
			local target, distance = findNearestPlayer(root.Position, islandId, aggroRange)
			if target and target.Character then
				local targetHumanoid = target.Character:FindFirstChildOfClass("Humanoid")
				local targetRoot = target.Character:FindFirstChild("HumanoidRootPart")
				if targetHumanoid and targetHumanoid.Health > 0 and targetRoot and targetRoot:IsA("BasePart") then
					if distance <= attackRange then
						humanoid:MoveTo(root.Position)
						if os.clock() >= nextAttackAt then
							nextAttackAt = os.clock() + attackCooldown
							targetHumanoid:TakeDamage(attackDamage)
						end
					else
						humanoid:MoveTo(targetRoot.Position)
					end
				end
			end
			task.wait(0.35)
		end
		activeEnemies[enemy] = nil
	end)
end

function EnemyService.Spawn(templateName: string, spawnCFrame: CFrame, level: number, islandId: string, options: {[string]: any}?)
	local templates = ServerStorage:FindFirstChild("EnemyTemplates")
	local template = templates and templates:FindFirstChild(templateName)
	if not template or not template:IsA("Model") then
		warn("[TheLostEra] Missing enemy template:", templateName)
		return nil
	end

	local enemy = template:Clone()
	local humanoid = enemy:FindFirstChildOfClass("Humanoid")
	if not humanoid or not getRoot(enemy) then
		warn("[TheLostEra] Enemy template needs a Humanoid and HumanoidRootPart:", templateName)
		enemy:Destroy()
		return nil
	end

	local safeLevel = math.clamp(math.floor(level), 1, 300)
	local settings = options or {}
	local maxHealth = math.max(50, math.floor(settings.MaxHealth or (100 + safeLevel * 24)))
	local damage = math.max(1, math.floor(settings.Damage or (5 + safeLevel * 1.4)))

	enemy:SetAttribute("IsLostEraEnemy", true)
	enemy:SetAttribute("EnemyLevel", safeLevel)
	enemy:SetAttribute("IslandId", islandId)
	enemy:SetAttribute("XPReward", math.max(1, math.floor(settings.XPReward or (15 + safeLevel * 5))))
	enemy:SetAttribute("CoinReward", math.max(0, math.floor(settings.CoinReward or (5 + safeLevel * 2))))
	enemy:SetAttribute("AggroRange", settings.AggroRange or 55)
	enemy:SetAttribute("AttackRange", settings.AttackRange or 5)
	enemy:SetAttribute("AttackDamage", damage)
	enemy:SetAttribute("AttackCooldown", settings.AttackCooldown or 1.5)

	humanoid.MaxHealth = maxHealth
	humanoid.Health = maxHealth
	enemy:PivotTo(spawnCFrame)
	enemy.Parent = Workspace
	activeEnemies[enemy] = true

	humanoid.Died:Connect(function()
		local userId = enemy:GetAttribute("LastHitUserId")
		local killer = if typeof(userId) == "number" then Players:GetPlayerByUserId(userId) else nil
		if killer then
			ProgressionService.AddXP(killer, enemy:GetAttribute("XPReward") or 0)
			ProgressionService.AddCoins(killer, enemy:GetAttribute("CoinReward") or 0)
			if enemy:GetAttribute("IslandId") == "SunsetBay" then
				QuestService.AddProgress(killer, "WelcomeToSunsetBay", 1)
			end
		end
		activeEnemies[enemy] = nil
		task.delay(3, function()
			if enemy.Parent then enemy:Destroy() end
		end)
	end)

	startAI(enemy)
	return enemy
end

function EnemyService.GetActiveCount(): number
	local count = 0
	for enemy in pairs(activeEnemies) do
		if enemy.Parent then count += 1 else activeEnemies[enemy] = nil end
	end
	return count
end

return EnemyService
