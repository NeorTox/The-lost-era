--!strict
-- Creates client/server remotes and connects server-side validation.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatService = require(script.Parent.CombatService)

local RemoteService = {}

local function getFolder(parent: Instance, name: string): Folder
	local found = parent:FindFirstChild(name)
	if found and found:IsA("Folder") then return found end
	if found then found:Destroy() end
	local folder = Instance.new("Folder")
	folder.Name = name
	folder.Parent = parent
	return folder
end

local function getRemote(parent: Instance, name: string): RemoteEvent
	local found = parent:FindFirstChild(name)
	if found and found:IsA("RemoteEvent") then return found end
	if found then found:Destroy() end
	local remote = Instance.new("RemoteEvent")
	remote.Name = name
	remote.Parent = parent
	return remote
end

function RemoteService.Init()
	local folder = getFolder(ReplicatedStorage, "TheLostEraRemotes")
	local attackRequest = getRemote(folder, "AttackRequest")
	attackRequest.OnServerEvent:Connect(function(player: Player, target: Instance)
		CombatService.TryAttack(player, target)
	end)
end

return RemoteService
