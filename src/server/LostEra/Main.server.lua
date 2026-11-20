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
local PortalService = require(script.Parent.PortalService)
local SkillService = require(script.Parent.SkillService)
local WeaponService = require(script.Parent.WeaponService)
local CharacterService = require(script.Parent.CharacterService)

local function loadPlayer(player: Player)
	local profile = DataService.LoadPlayer(player)
	if not profile then
		return
	end
	if player.Parent ~= Players then
		DataService.ReleasePlayer(player)
		return
	end

	ProgressionService.SyncPlayer(player)
	SkillService.SyncPlayer(player)
	SkillService.StartEnergyRegeneration(player)
	WeaponService.SyncPlayer(player)
	CharacterService.InitPlayer(player)
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
	SkillService.ReleasePlayer(player)
	CharacterService.ReleasePlayer(player)
	DataService.ReleasePlayer(player)
end)

task.spawn(function()
	while true do
		task.wait(Config.AutoSaveInterval)
		DataService.SaveAll()
	end
end)

game:BindToClose(function()
	-- ReleaseAll performs a final serialized save, then unlocks each successfully saved profile.
	-- Do not use a fixed sleep: let the operations finish or exhaust their bounded retries.
	DataService.ReleaseAll()
end)

RemoteService.Init()
EnemySpawnService.Init()
PortalService.Init()

print("[TheLostEra] Core server initialized.")
