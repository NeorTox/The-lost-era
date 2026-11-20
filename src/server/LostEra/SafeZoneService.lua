--!strict
-- Server-side safe-zone tracking and combat protection.
-- Safe-zone markers are BaseParts in Workspace/SafeZones named Generated_<LocationId>.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local SafeZoneService = {}
local initialized = false
local connections: {[Player]: {RBXScriptConnection}} = {}

local function isInsideZone(player: Player): boolean
	local locationId = player:GetAttribute("CurrentIsland")
	if typeof(locationId) ~= "string" then
		return false
	end

	local zones = Workspace:FindFirstChild("SafeZones")
	local marker = zones and zones:FindFirstChild("Generated_" .. locationId)
	if not marker or not marker:IsA("BasePart") then
		return false
	end

	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	if not root or not root:IsA("BasePart") then
		return false
	end

	local localPosition = marker.CFrame:PointToObjectSpace(root.Position)
	local halfSize = marker.Size * 0.5
	return math.abs(localPosition.X) <= halfSize.X
		and math.abs(localPosition.Z) <= halfSize.Z
		and math.abs(localPosition.Y) <= 14
end

function SafeZoneService.SyncPlayer(player: Player)
	local inSafeZone = isInsideZone(player)
	if player:GetAttribute("InSafeZone") ~= inSafeZone then
		player:SetAttribute("InSafeZone", inSafeZone)
	end
end

local function attachPlayer(player: Player)
	if connections[player] then return end
	connections[player] = {
		player:GetAttributeChangedSignal("CurrentIsland"):Connect(function()
			SafeZoneService.SyncPlayer(player)
		end),
		player.CharacterAdded:Connect(function()
			task.defer(SafeZoneService.SyncPlayer, player)
		end),
	}
	SafeZoneService.SyncPlayer(player)
end

function SafeZoneService.Init()
	if initialized then return end
	initialized = true

	for _, player in ipairs(Players:GetPlayers()) do
		attachPlayer(player)
	end
	Players.PlayerAdded:Connect(attachPlayer)
	Players.PlayerRemoving:Connect(function(player)
		local playerConnections = connections[player]
		if playerConnections then
			for _, connection in ipairs(playerConnections) do
				connection:Disconnect()
			end
		end
		connections[player] = nil
	end)

	task.spawn(function()
		while initialized do
			for _, player in ipairs(Players:GetPlayers()) do
				SafeZoneService.SyncPlayer(player)
			end
			task.wait(0.25)
		end
	end)
end

return SafeZoneService
