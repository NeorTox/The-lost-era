--!strict
-- Reads designer-authored spawn markers from Workspace/EnemySpawnPoints.
-- Each marker is a BasePart with TemplateName, Level, and IslandId attributes.

local Workspace = game:GetService("Workspace")
local Config = require(script.Parent.Config)
local EnemyService = require(script.Parent.EnemyService)

local EnemySpawnService = {}
local started = false
local connectedPoints: {[BasePart]: boolean} = {}

local function runSpawnPoint(point: BasePart)
	if connectedPoints[point] then
		return
	end
	connectedPoints[point] = true
	point.Destroying:Connect(function()
		connectedPoints[point] = nil
	end)

	task.spawn(function()
		local templateName = point:GetAttribute("TemplateName")
		local level = point:GetAttribute("Level")
		local islandId = point:GetAttribute("IslandId")
		local respawnSeconds = point:GetAttribute("RespawnSeconds")

		if typeof(templateName) ~= "string" or typeof(islandId) ~= "string" then
			warn("[TheLostEra] Spawn marker missing TemplateName or IslandId:", point:GetFullName())
			return
		end

		local island = Config.GetIslandById(islandId)
		if not island then
			warn("[TheLostEra] Spawn marker references an unknown island:", islandId, point:GetFullName())
			return
		end

		local safeLevel = if typeof(level) == "number" then math.floor(level) else island.EnemyLevelMin
		if safeLevel < island.EnemyLevelMin or safeLevel > island.EnemyLevelMax then
			warn(string.format(
				"[TheLostEra] Spawn level %d is outside %s enemy band (%d-%d): %s",
				safeLevel,
				island.Name,
				island.EnemyLevelMin,
				island.EnemyLevelMax,
				point:GetFullName()
			))
			return
		end
		local delaySeconds = if typeof(respawnSeconds) == "number" and respawnSeconds == respawnSeconds
			then math.max(3, respawnSeconds)
			else 12
		local currentEnemy: Model? = nil

		while point.Parent do
			if not currentEnemy or not currentEnemy.Parent then
				currentEnemy = EnemyService.Spawn(templateName, point.CFrame, safeLevel, islandId)
			end
			task.wait(delaySeconds)
		end
	end)
end

function EnemySpawnService.Init()
	if started then return end
	started = true

	local function connectFolder(folder: Instance)
		if not folder:IsA("Folder") then
			return
		end
		for _, descendant in ipairs(folder:GetDescendants()) do
			if descendant:IsA("BasePart") then
				runSpawnPoint(descendant)
			end
		end
		folder.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("BasePart") then
				runSpawnPoint(descendant)
			end
		end)
	end

	local folder = Workspace:FindFirstChild("EnemySpawnPoints")
	if folder then
		connectFolder(folder)
	else
		warn("[TheLostEra] Workspace/EnemySpawnPoints not found. Waiting for the folder to be added.")
		Workspace.ChildAdded:Connect(function(child)
			if child.Name == "EnemySpawnPoints" then
				connectFolder(child)
			end
		end)
	end
end

return EnemySpawnService
