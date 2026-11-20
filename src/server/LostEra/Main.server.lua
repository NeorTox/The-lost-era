--!strict
-- Main server entry point.

local Players = game:GetService("Players")

local Config = require(script.Parent.Config)
local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)
local QuestService = require(script.Parent.QuestService)
local CombatService = require(script.Parent.CombatService)
local RemoteService = require(script.Parent.RemoteService)
local EnemySpawnService = require(script.Parent.EnemySpawnService)

local function loadPlayer(player: Player)
	local profile = DataService.LoadPlayer(player)
	if not profile or player.Parent ~= Players then
		return
	end

	ProgressionService.SyncPlayer(player)
	player:SetAttribute("CurrentIsland", profile.CurrentIsland)
	print(string.format("[TheLostEra] Profile ready: %s (Level %d)", player.Name, profile.Level))
end

Players.PlayerAdded:Connect(function(player)
	task.spawn(loadPlayer, player)
end)

for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(loadPlayer, player)
end

Players.PlayerRemoving:Connect(function(player)
	QuestService.ReleasePlayer(player)
	CombatService.ReleasePlayer(player)
	DataService.ReleasePlayer(player)
end)

task.spawn(function()
	while true do
		task.wait(Config.AutoSaveInterval)
		DataService.SaveAll()
	end
end)

game:BindToClose(function()
	DataService.SaveAll()
	task.wait(3)
end)

RemoteService.Init()
EnemySpawnService.Init()

print("[TheLostEra] Core server initialized.")
