--!strict
-- XP, levels and currency are server-authoritative.

local Config = require(script.Parent.Config)
local DataService = require(script.Parent.DataService)

local ProgressionService = {}

local function sync(player: Player, profile)
	player:SetAttribute("Level", profile.Level)
	player:SetAttribute("XP", profile.XP)
	player:SetAttribute("XPToNextLevel", if profile.Level >= Config.MaxLevel then 0 else Config.GetXPToNextLevel(profile.Level))
	player:SetAttribute("Coins", profile.Coins)
	player:SetAttribute("SkillPoints", profile.SkillPoints or 0)
	player:SetAttribute("MemoryCrystals", profile.MemoryCrystals or 0)
	player:SetAttribute("VoidEssence", profile.VoidEssence or 0)
	local island = Config.GetIslandForLevel(profile.Level)
	player:SetAttribute("RecommendedIsland", island.Id)
	player:SetAttribute("RecommendedIslandName", island.Name)
	player:SetAttribute("RecommendedIslandUnlockLevel", island.UnlockLevel)
	player:SetAttribute("RecommendedEnemyLevelMin", island.EnemyLevelMin)
	player:SetAttribute("RecommendedEnemyLevelMax", island.EnemyLevelMax)
	player:SetAttribute("RecommendedBossLevel", island.BossLevel)
end

function ProgressionService.SyncPlayer(player: Player)
	local profile = DataService.GetProfile(player)
	if profile then
		sync(player, profile)
	end
end

function ProgressionService.AddXP(player: Player, amount: number): (boolean, number)
	local profile = DataService.GetProfile(player)
	if not profile then
		return false, 0
	end

	if typeof(amount) ~= "number" or amount ~= amount or amount == math.huge or amount == -math.huge or amount < 0 then
		return false, 0
	end
	local safeAmount = math.min(Config.MaxCurrencyBalance, math.floor(amount))
	if safeAmount == 0 or profile.Level >= Config.MaxLevel then
		return true, 0
	end

	profile.XP += safeAmount
	local levelsGained = 0
	while profile.Level < Config.MaxLevel do
		local required = Config.GetXPToNextLevel(profile.Level)
		if profile.XP < required then
			break
		end
		profile.XP -= required
		profile.Level += 1
		levelsGained += 1
	end

	if profile.Level >= Config.MaxLevel then
		profile.Level = Config.MaxLevel
		profile.XP = 0
	end
	profile.SkillPoints = math.min(Config.MaxLevel, (profile.SkillPoints or 0) + levelsGained)

	sync(player, profile)
	return true, levelsGained
end

local function isValidNonNegativeAmount(amount: any): boolean
	return typeof(amount) == "number"
		and amount == amount
		and amount ~= math.huge
		and amount ~= -math.huge
		and amount >= 0
		and amount == math.floor(amount)
end

local function addBalance(player: Player, field: string, attribute: string, amount: any, maximum: number): boolean
	local profile = DataService.GetProfile(player)
	if not profile or not isValidNonNegativeAmount(amount) then
		return false
	end
	local safeAmount = amount
	if safeAmount == 0 then
		return true
	end
	profile[field] = math.min(maximum, (tonumber(profile[field]) or 0) + safeAmount)
	player:SetAttribute(attribute, profile[field])
	return true
end

local function spendBalance(player: Player, field: string, attribute: string, amount: any): (boolean, string?)
	local profile = DataService.GetProfile(player)
	if not profile then
		return false, "ProfileUnavailable"
	end
	if not isValidNonNegativeAmount(amount) or amount ~= math.floor(amount) or amount <= 0 then
		return false, "InvalidAmount"
	end
	local balance = tonumber(profile[field]) or 0
	if balance < amount then
		return false, "InsufficientFunds"
	end
	profile[field] = balance - amount
	player:SetAttribute(attribute, profile[field])
	return true, nil
end

function ProgressionService.AddCoins(player: Player, amount: number): boolean
	return addBalance(player, "Coins", "Coins", amount, Config.MaxCurrencyBalance)
end

function ProgressionService.SpendCoins(player: Player, amount: number): (boolean, string?)
	return spendBalance(player, "Coins", "Coins", amount)
end

function ProgressionService.AddSkillPoints(player: Player, amount: number): boolean
	return addBalance(player, "SkillPoints", "SkillPoints", amount, Config.MaxLevel)
end

function ProgressionService.SpendSkillPoints(player: Player, amount: number): (boolean, string?)
	return spendBalance(player, "SkillPoints", "SkillPoints", amount)
end

function ProgressionService.AddMemoryCrystals(player: Player, amount: number): boolean
	return addBalance(player, "MemoryCrystals", "MemoryCrystals", amount, Config.MaxCurrencyBalance)
end

function ProgressionService.SpendMemoryCrystals(player: Player, amount: number): (boolean, string?)
	return spendBalance(player, "MemoryCrystals", "MemoryCrystals", amount)
end

function ProgressionService.AddVoidEssence(player: Player, amount: number): boolean
	return addBalance(player, "VoidEssence", "VoidEssence", amount, Config.MaxCurrencyBalance)
end

function ProgressionService.SpendVoidEssence(player: Player, amount: number): (boolean, string?)
	return spendBalance(player, "VoidEssence", "VoidEssence", amount)
end

function ProgressionService.CanAccessIsland(player: Player, islandId: string): boolean
	local profile = DataService.GetProfile(player)
	local island = Config.GetIslandById(islandId)
	return profile ~= nil and island ~= nil and profile.Level >= island.UnlockLevel
end

return ProgressionService
