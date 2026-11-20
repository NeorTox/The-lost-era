--!strict
-- Server-authoritative boss encounters, phase changes, telegraphed attacks
-- and contribution-based first-clear/repeat rewards.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)
local DataService = require(script.Parent.DataService)
local EnemyCatalog = require(script.Parent.EnemyCatalog)
local EnemyService = require(script.Parent.EnemyService)
local InventoryService = require(script.Parent.InventoryService)
local ProgressionService = require(script.Parent.ProgressionService)
local SafeZoneService = require(script.Parent.SafeZoneService)

type BossEncounter = {
	BossId: string,
	IslandId: string,
	Model: Model,
	Arena: BasePart,
	Marker: BasePart,
	Prompt: ProximityPrompt,
	Contributions: {[number]: number},
	Settled: boolean,
}

local BossService = {}
local initialized = false
local busyByIsland: {[string]: boolean} = {}
local activeByIsland: {[string]: Model} = {}
local encountersByModel: {[Model]: BossEncounter} = {}
local nextAvailableAt: {[string]: number} = {}

local BOSS_RESPAWN_SECONDS = 180
local PARTICIPATION_DAMAGE_FRACTION = 0.02
local SPECIAL_TELEGRAPH_SECONDS = 1.2

local function isFiniteNumber(value: any): boolean
	return typeof(value) == "number"
		and value == value
		and value ~= math.huge
		and value ~= -math.huge
end

local function getPhase(healthRatio: number)
	if healthRatio > 0.6 then
		return {
			Index = 1,
			Name = "Tidal Awakening",
			AttackDamage = 12,
			AttackCooldown = 2.8,
			WalkSpeed = 12,
			SpecialDamage = 14,
			SpecialRadius = 12,
			SpecialCooldown = 9,
		}
	elseif healthRatio > 0.25 then
		return {
			Index = 2,
			Name = "Rising Current",
			AttackDamage = 16,
			AttackCooldown = 2.2,
			WalkSpeed = 14,
			SpecialDamage = 18,
			SpecialRadius = 15,
			SpecialCooldown = 7,
		}
	end

	return {
		Index = 3,
		Name = "Tempest Core",
		AttackDamage = 20,
		AttackCooldown = 1.6,
		WalkSpeed = 16,
		SpecialDamage = 24,
		SpecialRadius = 18,
		SpecialCooldown = 5.5,
	}
end

local function updatePhaseNameplate(boss: Model, phaseName: string, phaseIndex: number)
	boss:SetAttribute("BossPhase", phaseIndex)
	boss:SetAttribute("BossPhaseName", phaseName)

	local head = boss:FindFirstChild("Head")
	local nameplate = head and head:FindFirstChild("EnemyNameplate")
	local phaseLabel = nameplate and nameplate:FindFirstChild("BossPhase")
	if phaseLabel and phaseLabel:IsA("TextLabel") then
		local roman = if phaseIndex == 1 then "I" elseif phaseIndex == 2 then "II" else "III"
		phaseLabel.Text = "PHASE " .. roman .. "  •  " .. string.upper(phaseName)
	end
end

local function applyPhase(boss: Model, humanoid: Humanoid)
	if humanoid.MaxHealth <= 0 then return end
	local ratio = math.clamp(humanoid.Health / humanoid.MaxHealth, 0, 1)
	local phase = getPhase(ratio)
	if boss:GetAttribute("BossPhase") == phase.Index then return end

	boss:SetAttribute("AttackDamage", phase.AttackDamage)
	boss:SetAttribute("AttackCooldown", phase.AttackCooldown)
	boss:SetAttribute("WalkSpeed", phase.WalkSpeed)
	humanoid.WalkSpeed = phase.WalkSpeed
	boss:SetAttribute("SpecialDamage", phase.SpecialDamage)
	boss:SetAttribute("SpecialRadius", phase.SpecialRadius)
	boss:SetAttribute("SpecialCooldown", phase.SpecialCooldown)
	updatePhaseNameplate(boss, phase.Name, phase.Index)
end

local function isInsideArena(position: Vector3, arena: BasePart): boolean
	local localPosition = arena.CFrame:PointToObjectSpace(position)
	local halfSize = arena.Size * 0.5
	return math.abs(localPosition.X) <= halfSize.X
		and math.abs(localPosition.Z) <= halfSize.Z
end

local function findNearestTarget(
	boss: Model,
	islandId: string,
	arena: BasePart,
	maxDistance: number
): (Player?, BasePart?, number)
	local bossRoot = boss:FindFirstChild("HumanoidRootPart")
	if not bossRoot or not bossRoot:IsA("BasePart") then
		return nil, nil, math.huge
	end

	local nearestPlayer: Player? = nil
	local nearestRoot: BasePart? = nil
	local nearestDistance = maxDistance
	local home = boss:GetAttribute("HomePosition")
	local homePosition = if typeof(home) == "Vector3" then home else bossRoot.Position
	local leash = tonumber(boss:GetAttribute("ChaseLeash")) or 180

	for _, player in ipairs(Players:GetPlayers()) do
		local character = player.Character
		local humanoid = character and character:FindFirstChildOfClass("Humanoid")
		local root = character and character:FindFirstChild("HumanoidRootPart")
		if humanoid and humanoid.Health > 0 and root and root:IsA("BasePart")
			and player:GetAttribute("CurrentIsland") == islandId
			and player:GetAttribute("InSafeZone") ~= true
			and not SafeZoneService.IsPlayerInSafeZone(player)
			and isInsideArena(root.Position, arena)
			and (root.Position - homePosition).Magnitude <= leash then
			local distance = (root.Position - bossRoot.Position).Magnitude
			if distance < nearestDistance then
				nearestPlayer = player
				nearestRoot = root
				nearestDistance = distance
			end
		end
	end

	return nearestPlayer, nearestRoot, nearestDistance
end

local function createTelegraph(position: Vector3, radius: number): BasePart
	local telegraph = Instance.new("Part")
	telegraph.Name = "BossAttackTelegraph"
	telegraph.Shape = Enum.PartType.Cylinder
	telegraph.Size = Vector3.new(0.55, radius * 2, radius * 2)
	telegraph.CFrame = CFrame.new(position) * CFrame.Angles(0, 0, math.rad(90))
	telegraph.Anchored = true
	telegraph.CanCollide = false
	telegraph.CanTouch = false
	telegraph.CanQuery = false
	telegraph.Material = Enum.Material.Neon
	telegraph.Color = Color3.fromRGB(255, 92, 63)
	telegraph.Transparency = 0.45
	telegraph.Parent = Workspace
	return telegraph
end

local function runSpecialAttacks(encounter: BossEncounter)
	task.spawn(function()
		local boss = encounter.Model
		local humanoid = boss:FindFirstChildOfClass("Humanoid")
		if not humanoid then return end

		local nextAttackAt = os.clock() + 4
		while boss.Parent and humanoid.Health > 0 and not encounter.Settled do
			local target, targetRoot = findNearestTarget(boss, encounter.IslandId, encounter.Arena, 110)
			if target and targetRoot and os.clock() >= nextAttackAt then
				local radius = math.clamp(tonumber(boss:GetAttribute("SpecialRadius")) or 12, 6, 30)
				local damage = math.clamp(math.floor(tonumber(boss:GetAttribute("SpecialDamage")) or 14), 1, 1000)
				local cooldown = math.clamp(tonumber(boss:GetAttribute("SpecialCooldown")) or 9, 3, 30)
				local targetPosition = targetRoot.Position
				local warningPosition = Vector3.new(targetPosition.X, targetPosition.Y - 3, targetPosition.Z)
				local telegraph = createTelegraph(warningPosition, radius)

				task.wait(SPECIAL_TELEGRAPH_SECONDS)
				if telegraph.Parent then telegraph:Destroy() end

				if boss.Parent and humanoid.Health > 0 and not encounter.Settled then
					for _, player in ipairs(Players:GetPlayers()) do
						local character = player.Character
						local playerHumanoid = character and character:FindFirstChildOfClass("Humanoid")
						local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
						if playerHumanoid and playerHumanoid.Health > 0 and playerRoot and playerRoot:IsA("BasePart")
							and player:GetAttribute("CurrentIsland") == encounter.IslandId
							and player:GetAttribute("InSafeZone") ~= true
							and not SafeZoneService.IsPlayerInSafeZone(player)
							and isInsideArena(playerRoot.Position, encounter.Arena) then
							local horizontalOffset = Vector3.new(
								playerRoot.Position.X - targetPosition.X,
								0,
								playerRoot.Position.Z - targetPosition.Z
							)
							if horizontalOffset.Magnitude <= radius
								and math.abs(playerRoot.Position.Y - targetPosition.Y) <= 10 then
								playerHumanoid:TakeDamage(damage)
							end
						end
					end
				end

				nextAttackAt = os.clock() + cooldown
			else
				task.wait(0.25)
			end
		end
	end)
end

local function setPromptState(prompt: ProximityPrompt, actionText: string, enabled: boolean)
	if prompt.Parent then
		prompt.ActionText = actionText
		prompt.Enabled = enabled
	end
end

local function beginCooldown(encounter: BossEncounter, actionText: string)
	local islandId = encounter.IslandId
	activeByIsland[islandId] = nil
	busyByIsland[islandId] = true
	setPromptState(encounter.Prompt, actionText, false)

	local availableAt = os.clock() + BOSS_RESPAWN_SECONDS
	nextAvailableAt[islandId] = availableAt
	task.delay(BOSS_RESPAWN_SECONDS, function()
		if nextAvailableAt[islandId] ~= availableAt then return end
		busyByIsland[islandId] = nil
		nextAvailableAt[islandId] = nil
		if encounter.Marker.Parent and encounter.Marker:GetAttribute("Enabled") == true then
			setPromptState(encounter.Prompt, "Challenge Again", true)
		end
	end)
end

local function awardParticipants(encounter: BossEncounter)
	local rewardConfig = Config.Economy.BossRewards[encounter.BossId]
	if not rewardConfig then
		warn("[TheLostEra] Missing boss reward configuration:", encounter.BossId)
		return
	end

	local humanoid = encounter.Model:FindFirstChildOfClass("Humanoid")
	local minimumDamage = (if humanoid then humanoid.MaxHealth else 1) * PARTICIPATION_DAMAGE_FRACTION

	for userId, damage in pairs(encounter.Contributions) do
		if damage >= minimumDamage then
			local player = Players:GetPlayerByUserId(userId)
			local profile = if player then DataService.GetProfile(player) else nil
			if player and profile then
				if typeof(profile.BossCompletions) ~= "table" then
					profile.BossCompletions = {}
				end
				local firstClear = table.find(profile.BossCompletions, encounter.BossId) == nil
				local payout = if firstClear then rewardConfig.FirstClear else rewardConfig.Repeat

				ProgressionService.AddXP(player, payout.XP)
				ProgressionService.AddCoins(player, payout.Coins)
				ProgressionService.AddMemoryCrystals(player, payout.MemoryCrystals)

				if firstClear then
					table.insert(profile.BossCompletions, encounter.BossId)
					local itemId = rewardConfig.FirstClear.ItemId
					if typeof(itemId) == "string" and InventoryService.GetCount(player, itemId) < 1 then
						local added, reason = InventoryService.AddItem(player, itemId, 1)
						if not added then
							warn("[TheLostEra] Could not grant boss first-clear item:", itemId, reason)
						end
					end
				end
			end
		end
	end
end

local function settleEncounter(encounter: BossEncounter, defeated: boolean)
	if encounter.Settled then return end
	encounter.Settled = true

	if defeated then
		awardParticipants(encounter)
	end

	beginCooldown(encounter, if defeated then "Boss Defeated" else "Encounter Reset")
	encountersByModel[encounter.Model] = nil
end

local function startEncounter(player: Player, marker: BasePart, prompt: ProximityPrompt)
	local islandId = marker:GetAttribute("IslandId")
	local bossId = marker:GetAttribute("BossId")
	if typeof(islandId) ~= "string" or typeof(bossId) ~= "string" then return end
	if marker:GetAttribute("Enabled") ~= true or not marker:IsDescendantOf(Workspace) then return end
	if prompt.Parent ~= marker or not prompt.Enabled then return end
	if busyByIsland[islandId] then return end
	if player:GetAttribute("CurrentIsland") ~= islandId then return end

	-- Treat ProximityPrompt as input, not authorization: validate the living
	-- character and interaction distance again on the server.
	local character = player.Character
	local playerHumanoid = character and character:FindFirstChildOfClass("Humanoid")
	local playerRoot = character and character:FindFirstChild("HumanoidRootPart")
	if not playerHumanoid or playerHumanoid.Health <= 0 or not playerRoot or not playerRoot:IsA("BasePart") then
		return
	end
	if (playerRoot.Position - marker.Position).Magnitude > 14 then
		return
	end

	-- Use the actual marker bounds rather than trusting a potentially stale
	-- replicated/cached InSafeZone attribute.
	if SafeZoneService.IsPlayerInSafeZone(player) then return end

	local profile = DataService.GetProfile(player)
	local island = Config.GetIslandById(islandId)
	local definition = EnemyCatalog.Get(bossId)
	local spawnFolder = Workspace:FindFirstChild("BossSpawnPoints")
	local spawnMarker = spawnFolder and spawnFolder:FindFirstChild("Generated_" .. islandId)
	local generatedWorld = Workspace:FindFirstChild("TheLostEraGeneratedWorld")
	local islandModel = generatedWorld and generatedWorld:FindFirstChild(islandId)
	local arenaInstance = islandModel and islandModel:FindFirstChild("BossArenaPlatform")
	if not profile or not island or not definition or definition.IsBoss ~= true
		or not spawnMarker or not spawnMarker:IsA("BasePart")
		or not arenaInstance or not arenaInstance:IsA("BasePart") then
		return
	end
	local arena: BasePart = arenaInstance
	if player:GetAttribute("Level") == nil or profile.Level < island.EnemyLevelMax then
		return
	end
	if spawnMarker:GetAttribute("Enabled") ~= true
		or spawnMarker:GetAttribute("BossTemplateName") ~= bossId
		or spawnMarker:GetAttribute("Level") ~= island.BossLevel then
		warn("[TheLostEra] Boss marker failed configuration validation:", islandId)
		return
	end

	busyByIsland[islandId] = true
	setPromptState(prompt, "Summoning...", false)

	local boss = EnemyService.Spawn(
		bossId,
		CFrame.new(spawnMarker.Position),
		island.BossLevel,
		islandId,
		{
			IsBoss = true,
			XPReward = 1,
			CoinReward = 0,
			DropChance = 0,
			ArenaCenter = arena.Position,
			ArenaSize = arena.Size,
		}
	)
	if not boss then
		busyByIsland[islandId] = nil
		setPromptState(prompt, "Challenge", true)
		return
	end

	boss:SetAttribute("BossId", bossId)
	boss:SetAttribute("BossIslandId", islandId)
	local encounter: BossEncounter = {
		BossId = bossId,
		IslandId = islandId,
		Model = boss,
		Arena = arena,
		Marker = marker,
		Prompt = prompt,
		Contributions = {},
		Settled = false,
	}
	encountersByModel[boss] = encounter
	activeByIsland[islandId] = boss
	setPromptState(prompt, "Boss Active", false)

	local humanoid = boss:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		settleEncounter(encounter, false)
		return
	end

	applyPhase(boss, humanoid)
	humanoid.HealthChanged:Connect(function()
		if boss.Parent and not encounter.Settled then
			applyPhase(boss, humanoid)
		end
	end)
	humanoid.Died:Connect(function()
		settleEncounter(encounter, true)
	end)
	boss.Destroying:Connect(function()
		if not encounter.Settled then
			settleEncounter(encounter, false)
		end
	end)

	runSpecialAttacks(encounter)
end

function BossService.RecordDamage(player: Player, enemy: Model, amount: number)
	local encounter = encountersByModel[enemy]
	if not encounter or encounter.Settled or player.Parent ~= Players then return end
	if not isFiniteNumber(amount) or amount <= 0 then return end
	if player:GetAttribute("CurrentIsland") ~= encounter.IslandId then return end
	encounter.Contributions[player.UserId] = (encounter.Contributions[player.UserId] or 0) + amount
end

function BossService.Init()
	if initialized then return end
	initialized = true

	local summonFolder = Workspace:FindFirstChild("BossSummonPoints")
	local spawnFolder = Workspace:FindFirstChild("BossSpawnPoints")
	if not summonFolder or not spawnFolder then
		warn("[TheLostEra] Boss summon or spawn folders are missing.")
		return
	end

	for _, marker in ipairs(summonFolder:GetChildren()) do
		if marker:IsA("BasePart") and marker:GetAttribute("Enabled") == true then
			local islandId = marker:GetAttribute("IslandId")
			local promptInstance = marker:FindFirstChild("BossChallengePrompt")
			local spawnMarker = if typeof(islandId) == "string"
				then spawnFolder:FindFirstChild("Generated_" .. islandId)
				else nil
			if promptInstance and promptInstance:IsA("ProximityPrompt")
				and spawnMarker and spawnMarker:IsA("BasePart") then
				local prompt: ProximityPrompt = promptInstance
				prompt.Triggered:Connect(function(player)
					startEncounter(player, marker, prompt)
				end)
			else
				warn("[TheLostEra] Enabled boss summon point is missing its prompt or spawn marker:", marker:GetFullName())
			end
		end
	end

	print("[TheLostEra] Boss encounter service initialized.")
end

return BossService
