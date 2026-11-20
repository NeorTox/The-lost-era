--!strict
-- Reads designer-authored spawn markers from Workspace/EnemySpawnPoints.
-- Each marker is a BasePart with TemplateName, Level, and IslandId attributes.

local Workspace = game:GetService("Workspace")
local EnemyService = require(script.Parent.EnemyService)

local EnemySpawnService = {}
local started = false

local function runSpawnPoint(point: BasePart)
	task.spawn(function()
		local templateName = point:GetAttribute("TemplateName")
		local level = point:GetAttribute("Level")
		local islandId = point:GetAttribute("IslandId")
		local respawnSeconds = point:GetAttribute("RespawnSeconds")

		if typeof(templateName) ~= "string" or typeof(islandId) ~= "string" then
			warn("[TheLostEra] Spawn marker missing TemplateName or IslandId:", point:GetFullName())
			return
		end

		local safeLevel = if typeof(level) == "number" then math.clamp(math.floor(level), 1, 300) else 1
		local delaySeconds = if typeof(respawnSeconds) == "number" then math.max(3, respawnSeconds) else 12
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

	local folder = Workspace:FindFirstChild("EnemySpawnPoints")
	if not folder then
		warn("[TheLostEra] Workspace/EnemySpawnPoints not found. Enemy spawning is idle until markers are added.")
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

return EnemySpawnService
