--!strict
-- Procedural greybox foundation for THE LOST ERA.
-- Creates the hub, 11 main islands, two special areas and the marker folders
-- consumed by PortalService, EnemySpawnService and NPCService.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)

local WorldBuilderService = {}

local WORLD_FOLDER_NAME = "TheLostEraGeneratedWorld"
local ISLAND_RING_RADIUS = 1050
local ISLAND_PLATFORM_SIZE = 260

local THEMES: {[string]: Color3} = {
	SunsetBay = Color3.fromRGB(232, 157, 91),
	PixelCity = Color3.fromRGB(65, 143, 224),
	ForgottenAcademy = Color3.fromRGB(147, 126, 190),
	ClockworkKingdom = Color3.fromRGB(190, 145, 72),
	TheLostEra = Color3.fromRGB(66, 173, 157),
	EmeraldJungle = Color3.fromRGB(67, 156, 96),
	FrozenKingdom = Color3.fromRGB(132, 190, 226),
	DragonVolcano = Color3.fromRGB(212, 82, 56),
	SkyRealm = Color3.fromRGB(130, 164, 224),
	AtlantisIsland = Color3.fromRGB(57, 163, 183),
	HauntedIsland = Color3.fromRGB(130, 83, 153),
	EchoBattleArena = Color3.fromRGB(204, 75, 91),
	MemoryTrainingIsland = Color3.fromRGB(93, 164, 177),
	CentralArea = Color3.fromRGB(90, 117, 153),
}

local function ensureFolder(parent: Instance, name: string): Folder
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA("Folder") then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function createPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	material: Enum.Material?,
	transparency: number?,
	canCollide: boolean?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = material or Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Anchored = true
	part.CanCollide = if canCollide == nil then true else canCollide
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function createBillboard(adornee: BasePart, text: string, color: Color3)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "WorldLabel"
	billboard.Adornee = adornee
	billboard.Size = UDim2.fromOffset(230, 44)
	billboard.StudsOffset = Vector3.new(0, 5, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 250
	billboard.Parent = adornee

	local label = Instance.new("TextLabel")
	label.Name = "Text"
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundColor3 = Color3.fromRGB(17, 23, 35)
	label.BackgroundTransparency = 0.16
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.Text = text
	label.TextColor3 = color
	label.TextScaled = true
	label.TextWrapped = true
	label.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = label
end

local function ensureMarker(
	folder: Folder,
	name: string,
	position: Vector3,
	attributes: {[string]: any},
	size: Vector3?
): BasePart
	local existing = folder:FindFirstChild(name)
	local marker: BasePart
	if existing and existing:IsA("BasePart") then
		marker = existing
	else
		if existing then existing:Destroy() end
		marker = Instance.new("Part")
		marker.Name = name
		marker.Size = size or Vector3.new(2, 1, 2)
		marker.Anchored = true
		marker.Transparency = 1
		marker.CanCollide = false
		marker.CanTouch = false
		marker.CanQuery = false
		marker.Parent = folder
	end
	marker.Position = position
	for key, value in pairs(attributes) do
		marker:SetAttribute(key, value)
	end
	return marker
end

local function ensureSpawnFolder(root: Folder, locationId: string, position: Vector3)
	local locationFolder = ensureFolder(root, locationId)
	local spawn = locationFolder:FindFirstChild("Spawn")
	if spawn and spawn:IsA("BasePart") then
		return spawn
	end
	if spawn then spawn:Destroy() end
	local marker = Instance.new("Part")
	marker.Name = "Spawn"
	marker.Size = Vector3.new(2, 1, 2)
	marker.CFrame = CFrame.new(position)
	marker.Transparency = 1
	marker.Anchored = true
	marker.CanCollide = false
	marker.CanTouch = false
	marker.CanQuery = false
	marker.Parent = locationFolder
	return marker
end

local function createPortalTrigger(folder: Folder, name: string, position: Vector3, target: Vector3, destinationId: string, color: Color3)
	local existing = folder:FindFirstChild(name)
	if existing and existing:IsA("BasePart") then
		existing:Destroy()
	elseif existing then
		existing:Destroy()
	end

	local trigger = Instance.new("Part")
	trigger.Name = name
	trigger.Size = Vector3.new(11, 14, 3)
	trigger.CFrame = CFrame.lookAt(position, target)
	trigger.Color = color
	trigger.Material = Enum.Material.Neon
	trigger.Transparency = 0.24
	trigger.Anchored = true
	trigger.CanCollide = false
	trigger.CanTouch = true
	trigger.CanQuery = false
	trigger:SetAttribute("DestinationIsland", destinationId)
	trigger:SetAttribute("DestinationSpawnName", "Spawn")
	trigger.Parent = folder
	return trigger
end

local function createSign(parent: Instance, name: string, position: Vector3, text: string, color: Color3)
	local post = createPart(
		parent,
		name,
		Vector3.new(2, 7, 2),
		CFrame.new(position + Vector3.new(0, 3.5, 0)),
		Color3.fromRGB(52, 58, 70),
		Enum.Material.Metal
	)
	createPart(
		parent,
		name .. "Board",
		Vector3.new(13, 6, 1),
		CFrame.new(position + Vector3.new(0, 7.5, 0)),
		Color3.fromRGB(22, 29, 42),
		Enum.Material.SmoothPlastic
	)
	createBillboard(post, text, color)
	return post
end

local function createNPC(npcFolder: Folder, npcId: string, modelName: string, displayName: string, islandId: string, position: Vector3, theme: Color3)
	for _, descendant in ipairs(npcFolder:GetDescendants()) do
		if descendant:IsA("Model") and descendant:GetAttribute("NpcId") == npcId then
			return
		end
	end

	local model = Instance.new("Model")
	model.Name = modelName
	model:SetAttribute("NpcId", npcId)
	model:SetAttribute("IslandId", islandId)
	model.Parent = npcFolder

	local root = createPart(
		model,
		"HumanoidRootPart",
		Vector3.new(3, 4, 2),
		CFrame.new(position + Vector3.new(0, 2, 0)),
		theme,
		Enum.Material.SmoothPlastic,
		0,
		false
	)
	root.CanTouch = false
	local head = createPart(
		model,
		"Head",
		Vector3.new(2.2, 2.2, 2.2),
		CFrame.new(position + Vector3.new(0, 5.1, 0)),
		Color3.fromRGB(226, 190, 157),
		Enum.Material.SmoothPlastic,
		0,
		false
	)
	head.Shape = Enum.PartType.Ball
	head.CanTouch = false
	createPart(
		model,
		"LeftArm",
		Vector3.new(1, 3.5, 1),
		CFrame.new(position + Vector3.new(-2.1, 2.1, 0)),
		theme,
		Enum.Material.SmoothPlastic,
		0,
		false
	).CanTouch = false
	createPart(
		model,
		"RightArm",
		Vector3.new(1, 3.5, 1),
		CFrame.new(position + Vector3.new(2.1, 2.1, 0)),
		theme,
		Enum.Material.SmoothPlastic,
		0,
		false
	).CanTouch = false
	model.PrimaryPart = root
	createBillboard(head, displayName, Color3.fromRGB(255, 255, 255))
end

local function buildArea(
	world: Folder,
	spawnFolders: Folder,
	portalFolder: Folder,
	islandCenter: Vector3,
	locationId: string,
	displayName: string,
	unlockLevel: number,
	theme: Color3,
	isMainIsland: boolean,
	index: number?
)
	local areaModel = Instance.new("Model")
	areaModel.Name = locationId
	areaModel:SetAttribute("LocationId", locationId)
	areaModel:SetAttribute("DisplayName", displayName)
	areaModel:SetAttribute("UnlockLevel", unlockLevel)
	areaModel.Parent = world

	createPart(
		areaModel,
		"Foundation",
		Vector3.new(ISLAND_PLATFORM_SIZE + 28, 16, ISLAND_PLATFORM_SIZE + 28),
		CFrame.new(islandCenter + Vector3.new(0, 8, 0)),
		Color3.fromRGB(42, 49, 62),
		Enum.Material.Slate
	)
	createPart(
		areaModel,
		"Ground",
		Vector3.new(ISLAND_PLATFORM_SIZE, 10, ISLAND_PLATFORM_SIZE),
		CFrame.new(islandCenter + Vector3.new(0, 21, 0)),
		theme:Lerp(Color3.fromRGB(46, 53, 63), 0.35),
		Enum.Material.SmoothPlastic
	)
	local surfaceY = 26

	local spawnPosition = islandCenter + Vector3.new(0, surfaceY + 2, 0)
	local spawn = ensureSpawnFolder(spawnFolders, locationId, spawnPosition)
	spawn.CFrame = CFrame.new(spawnPosition)

	local pad = createPart(
		areaModel,
		"MainSpawnPad",
		Vector3.new(34, 1, 34),
		CFrame.new(islandCenter + Vector3.new(0, surfaceY + 0.5, 0)),
		theme,
		Enum.Material.Neon,
		0.16
	)
	createBillboard(pad, displayName, Color3.fromRGB(255, 255, 255))
	local safeLabel = createPart(
		areaModel,
		"SafeZoneLabelAnchor",
		Vector3.new(1, 1, 1),
		CFrame.new(islandCenter + Vector3.new(0, surfaceY + 7, 24)),
		theme,
		Enum.Material.SmoothPlastic,
		1,
		false
	)
	createBillboard(safeLabel, "SAFE ZONE", Color3.fromRGB(137, 235, 183))

	local safeMarker = ensureMarker(
		ensureFolder(Workspace, "SafeZones"),
		"Generated_" .. locationId,
		islandCenter + Vector3.new(0, surfaceY + 1, 0),
		{ IslandId = locationId, SafeZoneId = locationId, MarkerType = "SafeZone" },
		Vector3.new(132, 1, 112)
	)
	safeMarker.Transparency = 1
	safeMarker.CanTouch = false

	local questPosition = islandCenter + Vector3.new(-62, surfaceY, -28)
	local shopPosition = islandCenter + Vector3.new(62, surfaceY, -28)
	createSign(areaModel, "QuestLocation", questPosition, if isMainIsland then "QUESTS" else displayName, theme)
	createSign(areaModel, "ShopLocation", shopPosition, if isMainIsland then "SUPPLIES" else "SPECIAL AREA", theme)

	ensureMarker(
		ensureFolder(Workspace, "QuestLocations"),
		"Generated_" .. locationId,
		questPosition,
		{ IslandId = locationId, MarkerType = "QuestLocation" }
	)
	ensureMarker(
		ensureFolder(Workspace, "ShopLocations"),
		"Generated_" .. locationId,
		shopPosition,
		{ IslandId = locationId, MarkerType = "ShopLocation" }
	)

	local bossCenter = islandCenter + Vector3.new(0, surfaceY + 4, 74)
	local bossPlatform = createPart(
		areaModel,
		"BossArenaPlatform",
		Vector3.new(92, 8, 92),
		CFrame.new(bossCenter),
		theme,
		Enum.Material.Metal
	)
	bossPlatform:SetAttribute("IsBossArena", true)
	bossPlatform:SetAttribute("IslandId", locationId)
	local bossTopY = bossCenter.Y + 4
	if isMainIsland and index then
		local island = Config.Islands[index]
		ensureMarker(
			ensureFolder(Workspace, "BossSpawnPoints"),
			"Generated_" .. locationId,
			Vector3.new(bossCenter.X, bossTopY + 2, bossCenter.Z),
			{
				IslandId = locationId,
				BossTemplateName = "TODO_" .. locationId .. "_Boss",
				Level = island.BossLevel,
				IsBoss = true,
				Enabled = false,
				MarkerType = "BossSpawn",
			}
		)
	end

	local treasurePosition = islandCenter + Vector3.new(-92, surfaceY + 2, 88)
	local chest = createPart(
		areaModel,
		"HiddenTreasurePlaceholder",
		Vector3.new(6, 4, 4),
		CFrame.new(treasurePosition),
		Color3.fromRGB(196, 145, 48),
		Enum.Material.Metal
	)
	chest:SetAttribute("TreasureId", "Treasure_" .. locationId)
	chest:SetAttribute("IslandId", locationId)
	chest:SetAttribute("IsCollectible", false)
	createPart(
		areaModel,
		"TreasureLid",
		Vector3.new(6.2, 1, 4.2),
		CFrame.new(treasurePosition + Vector3.new(0, 2.3, 0)),
		Color3.fromRGB(223, 180, 76),
		Enum.Material.Metal
	)

	local portalPosition = islandCenter + Vector3.new(112, surfaceY + 7, 0)
	local returnPortal = createPortalTrigger(
		portalFolder,
		"Generated_Return_" .. locationId,
		portalPosition,
		Vector3.new(0, portalPosition.Y, 0),
		Config.CentralArea.Id,
		theme
	)
	returnPortal:SetAttribute("PortalRole", "ReturnToCentralArea")

	if isMainIsland and index then
		local island = Config.Islands[index]
		local enemyFolder = ensureFolder(Workspace, "EnemySpawnPoints")
		local offsets = {
			Vector3.new(-72, surfaceY + 2, 62),
			Vector3.new(72, surfaceY + 2, 62),
			Vector3.new(0, surfaceY + 2, -88),
		}
		for spawnIndex, offset in ipairs(offsets) do
			local level = island.EnemyLevelMin
				+ math.floor((island.EnemyLevelMax - island.EnemyLevelMin) * ((spawnIndex - 1) / 2))
			local templateName = if locationId == "SunsetBay"
				then "TrainingSlime"
				else "TODO_" .. locationId .. "_Enemy_" .. tostring(spawnIndex)
			ensureMarker(
				enemyFolder,
				"Generated_" .. locationId .. "_Enemy_" .. tostring(spawnIndex),
				islandCenter + offset,
				{
					TemplateName = templateName,
					Level = level,
					IslandId = locationId,
					RespawnSeconds = 18,
					Enabled = false,
					MarkerType = "EnemySpawn",
				}
			)
		end
	end

	if isMainIsland and locationId == "SunsetBay" then
		local npcFolder = ensureFolder(Workspace, "NPCs")
		local guidePosition = islandCenter + Vector3.new(-48, surfaceY, -44)
		local merchantPosition = islandCenter + Vector3.new(48, surfaceY, -44)
		ensureMarker(
			ensureFolder(Workspace, "NPCSpawnPoints"),
			"Generated_SunsetGuide",
			guidePosition,
			{ NpcId = "SunsetGuide", IslandId = locationId, MarkerType = "NPCSpawn" }
		)
		ensureMarker(
			ensureFolder(Workspace, "NPCSpawnPoints"),
			"Generated_SunsetMerchant",
			merchantPosition,
			{ NpcId = "SunsetMerchant", IslandId = locationId, MarkerType = "NPCSpawn" }
		)
		createNPC(npcFolder, "SunsetGuide", "Generated_MiraIslandGuide", "Mira • Island Guide", locationId, guidePosition, theme)
		createNPC(npcFolder, "SunsetMerchant", "Generated_TomaMerchant", "Toma • Supply Merchant", locationId, merchantPosition, theme)
	end

	local label = createPart(
		areaModel,
		"LocationSign",
		Vector3.new(3, 3, 3),
		CFrame.new(islandCenter + Vector3.new(0, surfaceY + 3, -112)),
		theme,
		Enum.Material.Neon,
		0.2,
		false
	)
	createBillboard(label, displayName, Color3.fromRGB(255, 255, 255))
end

local function buildCentralArea(world: Folder, spawnFolders: Folder, portalFolder: Folder)
	local center = Vector3.new(0, 0, 0)
	local hub = Instance.new("Model")
	hub.Name = "CentralArea"
	hub:SetAttribute("LocationId", Config.CentralArea.Id)
	hub.Parent = world

	createPart(
		hub,
		"HubFoundation",
		Vector3.new(390, 24, 390),
		CFrame.new(center + Vector3.new(0, 12, 0)),
		Color3.fromRGB(38, 48, 67),
		Enum.Material.Slate
	)
	createPart(
		hub,
		"HubFloor",
		Vector3.new(350, 4, 350),
		CFrame.new(center + Vector3.new(0, 26, 0)),
		Color3.fromRGB(68, 85, 111),
		Enum.Material.SmoothPlastic
	)
	local spawnPosition = center + Vector3.new(0, 29, 0)
	local spawn = ensureSpawnFolder(spawnFolders, Config.CentralArea.Id, spawnPosition)
	spawn.CFrame = CFrame.new(spawnPosition)

	local spawnLocation = Instance.new("SpawnLocation")
	spawnLocation.Name = "DefaultHubSpawn"
	spawnLocation.Size = Vector3.new(14, 1, 14)
	spawnLocation.CFrame = CFrame.new(center + Vector3.new(0, 28.5, 0))
	spawnLocation.Anchored = true
	spawnLocation.Neutral = true
	spawnLocation.AllowTeamChangeOnTouch = false
	spawnLocation.Duration = 0
	spawnLocation.Transparency = 1
	spawnLocation.CanCollide = false
	spawnLocation.CanTouch = false
	spawnLocation.CanQuery = false
	spawnLocation.Parent = hub

	local hubSpawnPad = createPart(
		hub,
		"HubSpawnPad",
		Vector3.new(28, 1, 28),
		CFrame.new(center + Vector3.new(0, 28.5, 0)),
		Color3.fromRGB(116, 190, 216),
		Enum.Material.Neon,
		0.12,
		false
	)
	hubSpawnPad.CanTouch = false
	hubSpawnPad.CanQuery = false
	createBillboard(hubSpawnPad, "THE LOST ERA • PORTAL HUB", Color3.fromRGB(255, 255, 255))

	-- Keep the landmark clear of the actual spawn position.
	local centerPillar = createPart(
		hub,
		"HubCore",
		Vector3.new(16, 32, 16),
		CFrame.new(center + Vector3.new(0, 44, -62)),
		Color3.fromRGB(116, 190, 216),
		Enum.Material.Neon,
		0.12
	)
	createBillboard(centerPillar, "PORTAL HUB", Color3.fromRGB(255, 255, 255))

	local destinations = {}
	for _, island in ipairs(Config.Islands) do table.insert(destinations, island) end
	for _, area in ipairs(Config.SpecialAreas) do table.insert(destinations, area) end

	local hubPortals = ensureFolder(portalFolder, "HubPortals")
	for index, destination in ipairs(destinations) do
		local angle = (2 * math.pi * (index - 1)) / #destinations
		local position = center + Vector3.new(math.cos(angle) * 154, 35, math.sin(angle) * 154)
		local theme = THEMES[destination.Id] or THEMES.CentralArea
		local portal = createPortalTrigger(
			hubPortals,
			"Generated_Hub_" .. destination.Id,
			position,
			center + Vector3.new(0, position.Y, 0),
			destination.Id,
			theme
		)
		portal:SetAttribute("PortalRole", "FromCentralArea")
		createSign(hub, "PortalSign_" .. destination.Id, position + Vector3.new(0, -12, 8), destination.Name, theme)
	end

	local safeMarker = ensureMarker(
		ensureFolder(Workspace, "SafeZones"),
		"Generated_CentralArea",
		center + Vector3.new(0, 29, 0),
		{ IslandId = Config.CentralArea.Id, SafeZoneId = Config.CentralArea.Id, MarkerType = "SafeZone" },
		Vector3.new(130, 1, 130)
	)
	safeMarker.CanTouch = false
end

local function attachPlayer(player: Player)
	player.CharacterAdded:Connect(function(character)
		task.defer(function()
			local locationId = player:GetAttribute("CurrentIsland")
			if typeof(locationId) ~= "string" then return end
			local spawnRoot = Workspace:FindFirstChild("IslandSpawns")
			local locationFolder = spawnRoot and spawnRoot:FindFirstChild(locationId)
			local spawn = locationFolder and locationFolder:FindFirstChild("Spawn")
			if spawn and spawn:IsA("BasePart") and character.Parent then
				character:PivotTo(spawn.CFrame + Vector3.new(0, 5, 0))
			end
		end)
	end)
end

function WorldBuilderService.PlacePlayerAtLocation(player: Player, locationId: string)
	local spawnRoot = Workspace:FindFirstChild("IslandSpawns")
	local locationFolder = spawnRoot and spawnRoot:FindFirstChild(locationId)
	local spawn = locationFolder and locationFolder:FindFirstChild("Spawn")
	if not spawn or not spawn:IsA("BasePart") then
		warn("[TheLostEra] No generated spawn exists for location:", locationId)
		return false
	end

	local character = player.Character
	for _ = 1, 50 do
		if character and character.Parent then break end
		task.wait(0.1)
		character = player.Character
	end
	if not character or not character.Parent then
		warn("[TheLostEra] Character was not ready for saved-location placement:", player.UserId)
		return false
	end

	character:PivotTo(spawn.CFrame + Vector3.new(0, 5, 0))
	return true
end

function WorldBuilderService.Init()
	local oldWorld = Workspace:FindFirstChild(WORLD_FOLDER_NAME)
	if oldWorld then oldWorld:Destroy() end
	local world = Instance.new("Folder")
	world.Name = WORLD_FOLDER_NAME
	world:SetAttribute("WorldBuilderVersion", 1)
	world.Parent = Workspace

	local spawnFolders = ensureFolder(Workspace, "IslandSpawns")
	local portalFolder = ensureFolder(Workspace, "IslandPortals")
	ensureFolder(Workspace, "EnemySpawnPoints")
	ensureFolder(Workspace, "BossSpawnPoints")
	ensureFolder(Workspace, "NPCSpawnPoints")
	ensureFolder(Workspace, "NPCs")
	ensureFolder(Workspace, "QuestLocations")
	ensureFolder(Workspace, "ShopLocations")
	ensureFolder(Workspace, "SafeZones")

	buildCentralArea(world, spawnFolders, portalFolder)

	for index, island in ipairs(Config.Islands) do
		local angle = (2 * math.pi * (index - 1)) / #Config.Islands
		local center = Vector3.new(
			math.cos(angle) * ISLAND_RING_RADIUS,
			34 + math.sin(angle * 2) * 14,
			math.sin(angle) * ISLAND_RING_RADIUS
		)
		buildArea(
			world,
			spawnFolders,
			portalFolder,
			center,
			island.Id,
			island.Name,
			island.UnlockLevel,
			THEMES[island.Id] or THEMES.CentralArea,
			true,
			index
		)
	end

	local specialPositions = {
		EchoBattleArena = Vector3.new(-520, 52, 1450),
		MemoryTrainingIsland = Vector3.new(520, 52, 1450),
	}
	for _, area in ipairs(Config.SpecialAreas) do
		buildArea(
			world,
			spawnFolders,
			portalFolder,
			specialPositions[area.Id] or Vector3.new(0, 52, 1450),
			area.Id,
			area.Name,
			area.UnlockLevel,
			THEMES[area.Id] or THEMES.CentralArea,
			false,
			nil
		)
	end

	for _, player in ipairs(Players:GetPlayers()) do
		attachPlayer(player)
	end
	Players.PlayerAdded:Connect(attachPlayer)

	print(string.format(
		"[TheLostEra] Generated central hub, %d main islands and %d special areas.",
		#Config.Islands,
		#Config.SpecialAreas
	))
end

return WorldBuilderService
