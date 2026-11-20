--!strict
-- Server-owned NPC interactions, quest claims and shop transactions.
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)
local InventoryService = require(script.Parent.InventoryService)
local QuestService = require(script.Parent.QuestService)

local NPCService = {}
local RANGE = 14
local COOLDOWN = 0.5
local lastRequest: {[number]: number} = {}

local DEFINITIONS = {
	SunsetGuide = {
		IslandId = "SunsetBay",
		DisplayName = "Mira, the Island Guide",
		Dialogue = "Welcome to Sunset Bay, adventurer. Defeat three training slimes to prove yourself.",
		QuestId = "WelcomeToSunsetBay",
	},
	SunsetMerchant = {
		IslandId = "SunsetBay",
		DisplayName = "Toma, the Supply Merchant",
		Dialogue = "Need supplies? I have essentials for the road.",
		Shop = {
			HealthPotion = { Price = 30, Stock = 99, RequiredLevel = 1 },
			BronzeSword = { Price = 250, Stock = 1, RequiredLevel = 10 },
			IronBlade = { Price = 900, Stock = 1, RequiredLevel = 30 },
		},
	},
}

local function findNpc(npcId: string): Model?
	local folder = Workspace:FindFirstChild("NPCs")
	if not folder then return nil end
	for _, item in ipairs(folder:GetDescendants()) do
		if item:IsA("Model") and item:GetAttribute("NpcId") == npcId then
			return item
		end
	end
	return nil
end

local function validateNear(player: Player, npcId: string): boolean
	local def = DEFINITIONS[npcId]
	local npc = findNpc(npcId)
	if not def or not npc or npc:GetAttribute("IslandId") ~= def.IslandId then return false end
	if player:GetAttribute("CurrentIsland") ~= def.IslandId then return false end
	local character = player.Character
	local playerRoot = if character then character:FindFirstChild("HumanoidRootPart") else nil
	local npcRoot = npc:FindFirstChild("HumanoidRootPart") or npc.PrimaryPart
	if not playerRoot or not playerRoot:IsA("BasePart") or not npcRoot or not npcRoot:IsA("BasePart") then return false end
	return (playerRoot.Position - npcRoot.Position).Magnitude <= RANGE
end

local function rateAllowed(player: Player): boolean
	local now = os.clock()
	if now - (lastRequest[player.UserId] or 0) < COOLDOWN then return false end
	lastRequest[player.UserId] = now
	return true
end

function NPCService.Interact(player: Player, npcId: any)
	if typeof(npcId) ~= "string" or #npcId > 64 then return false, "InvalidNPC", nil end
	if not rateAllowed(player) then return false, "TooFast", nil end
	local def = DEFINITIONS[npcId]
	if not def then return false, "UnknownNPC", nil end
	if not DataService.GetProfile(player) then return false, "ProfileUnavailable", nil end
	if not validateNear(player, npcId) then return false, "TooFarOrWrongIsland", nil end
	local response: {[string]: any} = {
		NpcId = npcId,
		DisplayName = def.DisplayName,
		Dialogue = def.Dialogue,
	}
	if def.QuestId then
		response.QuestId = def.QuestId
		response.QuestProgress = QuestService.GetProgress(player, def.QuestId)
		response.QuestDefinition = QuestService.GetDefinitions()[def.QuestId]
	end
	if def.Shop then
		response.Shop = {}
		for itemId, item in pairs(def.Shop) do
			table.insert(response.Shop, {
				ItemId = itemId,
				Price = item.Price,
				Stock = item.Stock,
				RequiredLevel = item.RequiredLevel,
			})
		end
	end
	return true, "InteractionReady", response
end

function NPCService.ClaimQuest(player: Player, npcId: any, questId: any)
	if typeof(npcId) ~= "string" or typeof(questId) ~= "string" then return false, "InvalidRequest" end
	if not rateAllowed(player) then return false, "TooFast" end
	local def = DEFINITIONS[npcId]
	if not def or def.QuestId ~= questId then return false, "QuestNotOfferedHere" end
	if not validateNear(player, npcId) then return false, "TooFarOrWrongIsland" end
	return QuestService.ClaimReward(player, questId)
end

function NPCService.Purchase(player: Player, npcId: any, itemId: any, quantity: any)
	if typeof(npcId) ~= "string" or typeof(itemId) ~= "string" or typeof(quantity) ~= "number" then return false, "InvalidRequest" end
	if quantity ~= quantity or quantity == math.huge or quantity ~= math.floor(quantity) or quantity < 1 or quantity > 10 then
		return false, "InvalidAmount"
	end
	if not rateAllowed(player) then return false, "TooFast" end
	local def = DEFINITIONS[npcId]
	local item = if def and def.Shop then def.Shop[itemId] else nil
	if not item then return false, "ItemNotSoldHere" end
	if not validateNear(player, npcId) then return false, "TooFarOrWrongIsland" end
	if quantity > item.Stock then return false, "OutOfStock" end
	local level = math.max(1, math.floor(tonumber(player:GetAttribute("Level")) or 1))
	if level < item.RequiredLevel then return false, "LevelRequirement" end

	local totalPrice = item.Price * quantity
	local spent, spendError = ProgressionService.SpendCoins(player, totalPrice)
	if not spent then return false, spendError end
	local added, addError = InventoryService.AddItem(player, itemId, quantity)
	if not added then
		ProgressionService.AddCoins(player, totalPrice)
		return false, addError
	end
	return true, "PurchaseComplete"
end

Players.PlayerRemoving:Connect(function(player) lastRequest[player.UserId] = nil end)
return NPCService
