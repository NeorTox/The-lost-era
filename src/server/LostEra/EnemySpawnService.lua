--!strict
-- Reads designer-authored spawn markers from Workspace/EnemySpawnPoints.
-- Each marker is a BasePart with TemplateName, Level, IslandId and Enabled attributes.

local Workspace = game:GetService("Workspace")
local Config = require(script.Parent.Config)
local EnemyService = require(script.Parent.EnemyService)

local EnemySpawnService = {}
local started = false
local connectedPoints: {[BasePart]: RBXScriptConnection} = {}
local runningPoints: {[BasePart]: boolean} = {}
local spawnedForPoint: {[BasePart]: Model} = {}

local function runSpawnPoint(point: BasePart)
	if runningPoints[point] or point:GetAttribute("Enabled") == false then
		return
	end
	runningPoints[point] = true

	task.spawn(function()
		local templateName = point:GetAttribute("TemplateName")
		local level = point:GetAttribute("Level")
		local islandId = point:GetAttribute("IslandId")
		local respawnSeconds = point:GetAttribute("RespawnSeconds")

		if typeof(templateName) ~= "string" or typeof(islandId) ~= "string" then
			warn("[TheLostEra] Spawn marker missing TemplateName or IslandId:", point:GetFullName())
			runningPoints[point] = nil
			return
		end

		local island = Config.GetIslandById(islandId)
		if not island then
			warn("[TheLostEra] Spawn marker references an unknown island:", islandId, point:GetFullName())
			runningPoints[point] = nil
			return
		end

		local hasValidLevel = typeof(level) == "number"
			and level == level
			and level > -math.huge
			and level < math.huge
			and level == math.floor(level)
		local safeLevel = if hasValidLevel then level else island.EnemyLevelMin
		if not hasValidLevel and level ~= nil then
			warn("[TheLostEra] Spawn marker has a non-finite or non-integer Level attribute:", point:GetFullName())
			runningPoints[point] = nil
			return
		end
		if safeLevel < island.EnemyLevelMin or safeLevel > island.EnemyLevelMax then
			warn(string.format(
				"[TheLostEra] Spawn level %d is outside %s enemy band (%d-%d): %s",
				safeLevel,
				island.Name,
				island.EnemyLevelMin,
				island.EnemyLevelMax,
				point:GetFullName()
			))
			runningPoints[point] = nil
			return
		end
		local delaySeconds = if typeof(respawnSeconds) == "number"
			and respawnSeconds == respawnSeconds
			and respawnSeconds > -math.huge
			and respawnSeconds < math.huge
			then math.clamp(respawnSeconds, 3, 3600)
			else 18

		local currentEnemy: Model? = nil
		local hasSpawned = false
		while point.Parent and point:GetAttribute("Enabled") ~= false do
			if currentEnemy and not currentEnemy.Parent then
				currentEnemy = nil
				spawnedForPoint[point] = nil
				if hasSpawned then
					-- Respawn delay starts after the defeated/removed model is gone.
					task.wait(delaySeconds)
					if not point.Parent or point:GetAttribute("Enabled") == false then
						break
					end
				end
			end

			if not currentEnemy then
				currentEnemy = EnemyService.Spawn(templateName, point.CFrame, safeLevel, islandId)
				if currentEnemy then
					hasSpawned = true
					spawnedForPoint[point] = currentEnemy
				else
					-- Avoid warning/spawn churn if a template is missing or invalid.
					task.wait(delaySeconds)
				end
			end

			task.wait(0.5)
		end

		spawnedForPoint[point] = nil
		runningPoints[point] = nil
		-- If Enabled was toggled back on while this loop was winding down,
		-- restart after releasing the running guard.
		if point.Parent and point:GetAttribute("Enabled") ~= false then
			task.defer(runSpawnPoint, point)
		end
	end)
end

local function connectSpawnPoint(point: BasePart)
	if connectedPoints[point] then return end

	connectedPoints[point] = point:GetAttributeChangedSignal("Enabled"):Connect(function()
		if point:GetAttribute("Enabled") == false then
			local currentEnemy = spawnedForPoint[point]
			if currentEnemy and currentEnemy.Parent then
				currentEnemy:Destroy()
			end
		else
			runSpawnPoint(point)
		end
	end)
	point.Destroying:Connect(function()
		local connection = connectedPoints[point]
		if connection then connection:Disconnect() end
		connectedPoints[point] = nil
		local currentEnemy = spawnedForPoint[point]
		if currentEnemy and currentEnemy.Parent then currentEnemy:Destroy() end
		spawnedForPoint[point] = nil
	end)
	runSpawnPoint(point)
end

function EnemySpawnService.Init()
	if started then return end
	started = true

	local function connectFolder(folder: Instance)
		if not folder:IsA("Folder") then return end
		for _, descendant in ipairs(folder:GetDescendants()) do
			if descendant:IsA("BasePart") then connectSpawnPoint(descendant) end
		end
		folder.DescendantAdded:Connect(function(descendant)
			if descendant:IsA("BasePart") then connectSpawnPoint(descendant) end
		end)
	end

	local folder = Workspace:FindFirstChild("EnemySpawnPoints")
	if folder then
		connectFolder(folder)
	else
		warn("[TheLostEra] Workspace/EnemySpawnPoints not found. Waiting for the folder to be added.")
		Workspace.ChildAdded:Connect(function(child)
			if child.Name == "EnemySpawnPoints" then connectFolder(child) end
		end)
	end
end

return EnemySpawnService
