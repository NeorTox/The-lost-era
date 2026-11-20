--!strict
-- Creates remotes and routes requests through server-side validation.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CombatService = require(script.Parent.CombatService)
local NPCService = require(script.Parent.NPCService)
local SkillService = require(script.Parent.SkillService)
local WeaponService = require(script.Parent.WeaponService)

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
	getRemote(folder, "AttackRequest").OnServerEvent:Connect(function(player: Player, target: Instance)
		CombatService.TryAttack(player, target)
	end)

	local interactResult = getRemote(folder, "NPCInteractResult")
	getRemote(folder, "NPCInteractRequest").OnServerEvent:Connect(function(player: Player, npcId: any)
		local ok, status, payload = NPCService.Interact(player, npcId)
		interactResult:FireClient(player, ok, status, payload)
	end)

	local claimResult = getRemote(folder, "QuestClaimResult")
	getRemote(folder, "QuestClaimRequest").OnServerEvent:Connect(function(player: Player, npcId: any, questId: any)
		local ok, status = NPCService.ClaimQuest(player, npcId, questId)
		claimResult:FireClient(player, ok, status)
	end)

	local purchaseResult = getRemote(folder, "ShopPurchaseResult")
	getRemote(folder, "ShopPurchaseRequest").OnServerEvent:Connect(function(player: Player, npcId: any, itemId: any, quantity: any)
		local ok, status = NPCService.Purchase(player, npcId, itemId, quantity)
		purchaseResult:FireClient(player, ok, status)
	end)

	local skillStateResult = getRemote(folder, "SkillStateResult")
	getRemote(folder, "SkillStateRequest").OnServerEvent:Connect(function(player: Player)
		skillStateResult:FireClient(player, SkillService.GetState(player))
	end)

	local skillUnlockResult = getRemote(folder, "SkillUnlockResult")
	getRemote(folder, "SkillUnlockRequest").OnServerEvent:Connect(function(player: Player, skillId: any)
		local ok, status = SkillService.Unlock(player, skillId)
		skillUnlockResult:FireClient(player, ok, status, SkillService.GetState(player))
	end)

	local skillEquipResult = getRemote(folder, "SkillEquipResult")
	getRemote(folder, "SkillEquipRequest").OnServerEvent:Connect(function(player: Player, skillId: any, slot: any)
		local ok, status = SkillService.Equip(player, skillId, slot)
		skillEquipResult:FireClient(player, ok, status, SkillService.GetState(player))
	end)

	local skillUseResult = getRemote(folder, "SkillUseResult")
	getRemote(folder, "SkillUseRequest").OnServerEvent:Connect(function(player: Player, skillId: any)
		local ok, status, payload = SkillService.Use(player, skillId)
		skillUseResult:FireClient(player, ok, status, payload)
	end)

	local weaponEquipResult = getRemote(folder, "WeaponEquipResult")
	getRemote(folder, "WeaponEquipRequest").OnServerEvent:Connect(function(player: Player, weaponId: any)
		local ok, status = WeaponService.Equip(player, weaponId)
		weaponEquipResult:FireClient(player, ok, status, WeaponService.GetEquippedId(player))
	end)
end

return RemoteService
