--!strict
-- Server-authoritative island portal handling.
-- Portal parts live under Workspace/IslandPortals.
-- Required attributes on each BasePart:
--   DestinationIsland (string): canonical island, CentralArea or special-area Id.
-- Optional attributes:
--   DestinationSpawnName (string): spawn part name; defaults to "Spawn".
--
-- Destination spawn parts live at:
-- Workspace/IslandSpawns/<DestinationIsland>/<DestinationSpawnName>

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.Config)
local DataService = require(script.Parent.DataService)

local PortalService = {}

local PORTAL_FOLDER_NAME = "IslandPortals"
local SPAWN_FOLDER_NAME = "IslandSpawns"
local TOUCH_COOLDOWN = 2
local TELEPORT_OFFSET = Vector3.new(0, 4, 0)

local lastTeleportAt: {[number]: number} = {}
local connectedParts: {[Instance]: boolean} = {}

local function findDestinationSpawn(islandId: string, spawnName: string): BasePart?
	local islandsFolder = Workspace:FindFirstChild(SPAWN_FOLDER_NAME)
	if not islandsFolder then
		return nil
	end

	local islandFolder = islandsFolder:FindFirstChild(islandId)
	if not islandFolder then
		return nil
	end

	local spawnPart = islandFolder:FindFirstChild(spawnName)
	if spawnPart and spawnPart:IsA("BasePart") then
		return spawnPart
	end
	return nil
end

local function getPlayerFromHit(hit: BasePart): Player?
	local character = hit:FindFirstAncestorOfClass("Model")
	if not character then
		return nil
	end
	return Players:GetPlayerFromCharacter(character)
end

local function activatePortal(portal: BasePart, hit: BasePart)
	local player = getPlayerFromHit(hit)
	if not player or player.Parent ~= Players then
		return
	end

	local now = os.clock()
	local lastTime = lastTeleportAt[player.UserId] or 0
	if now - lastTime < TOUCH_COOLDOWN then
		return
	end

	local destinationIsland = portal:GetAttribute("DestinationIsland")
	if typeof(destinationIsland) ~= "string" then
		warn("[TheLostEra] Portal has no valid DestinationIsland attribute:", portal:GetFullName())
		return
	end

	local islandConfig = Config.GetWorldLocationById(destinationIsland)
	if not islandConfig then
		warn("[TheLostEra] Portal points to unknown island:", destinationIsland)
		return
	end

	local level = tonumber(player:GetAttribute("Level")) or 1
	if level < islandConfig.UnlockLevel then
		-- The server rejects locked destinations. A future UI can display this message.
		player:SetAttribute("PortalDeniedIsland", destinationIsland)
		return
	end

	local spawnName = portal:GetAttribute("DestinationSpawnName")
	if typeof(spawnName) ~= "string" or spawnName == "" then
		spawnName = "Spawn"
	end

	local destination = findDestinationSpawn(destinationIsland, spawnName)
	if not destination then
		warn(string.format(
			"[TheLostEra] Missing spawn: Workspace/%s/%s/%s",
			SPAWN_FOLDER_NAME,
			destinationIsland,
			spawnName
		))
		return
	end

	local character = player.Character
	local humanoid = if character then character:FindFirstChildOfClass("Humanoid") else nil
	if not character or not humanoid or humanoid.Health <= 0 then
		return
	end

	lastTeleportAt[player.UserId] = now
	character:PivotTo(destination.CFrame + TELEPORT_OFFSET)
	player:SetAttribute("CurrentIsland", destinationIsland)

	local profile = DataService.GetProfile(player)
	if profile then
		profile.CurrentIsland = destinationIsland
	end
	player:SetAttribute("PortalDeniedIsland", nil)
end

local function connectPortal(instance: Instance)
	if not instance:IsA("BasePart") or connectedParts[instance] then
		return
	end

	connectedParts[instance] = true
	instance.Touched:Connect(function(hit)
		activatePortal(instance, hit)
	end)

	instance.Destroying:Connect(function()
		connectedParts[instance] = nil
	end)
end

function PortalService.Init()
	local folder = Workspace:FindFirstChild(PORTAL_FOLDER_NAME)
	if not folder then
		warn("[TheLostEra] Workspace/IslandPortals is missing. Portal service is waiting for it.")
		folder = Workspace:WaitForChild(PORTAL_FOLDER_NAME, 30)
	end

	if not folder then
		warn("[TheLostEra] Portal service did not start: IslandPortals folder was not created.")
		return
	end

	for _, descendant in ipairs(folder:GetDescendants()) do
		connectPortal(descendant)
	end

	folder.DescendantAdded:Connect(connectPortal)
	print("[TheLostEra] Island portal service initialized.")
end

Players.PlayerRemoving:Connect(function(player)
	lastTeleportAt[player.UserId] = nil
end)

return PortalService
