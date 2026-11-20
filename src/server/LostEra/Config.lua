--!strict
-- THE LOST ERA — central server configuration and canonical level progression.

local Config = {}

Config.DataStoreName = "TheLostEra_PlayerData_v1"
Config.DataStoreKeyPrefix = "player_"
Config.AutoSaveInterval = 60
Config.MaxLevel = 300
Config.MaxCurrencyBalance = 9007199254740991
Config.StartingLevel = 1
Config.StartingXP = 0
Config.StartingCoins = 0

-- Baseline character values; keep these centralized for balancing.
Config.BaseMaxHealth = 100
Config.BaseMaxEnergy = 100
Config.BaseMaxStamina = 100
Config.BaseWalkSpeed = 16
Config.SprintWalkSpeed = 24
Config.BaseJumpPower = 50
Config.StaminaDrainPerSecond = 20
Config.StaminaRegenPerSecond = 15

-- XP required to advance from the current level to the next level.
-- Formula: base + linear growth + power growth.
Config.XPBase = 100
Config.XPLinearPerLevel = 35
Config.XPPowerScale = 8
Config.XPPowerExponent = 1.35


-- Reward sources and sinks already present in the first playable loop.
-- Future systems should add new entries here rather than hard-coding payouts.
Config.Economy = {
	EnemyRewards = {
		XPBase = 15,
		XPPerLevel = 5,
		CoinBase = 5,
		CoinPerLevel = 2,
	},
	QuestRewards = {
		WelcomeToSunsetBay = { XP = 75, Coins = 25 },
	},
	Shop = {
		HealthPotion = { Price = 30, Stock = 99, RequiredLevel = 1 },
		BronzeSword = { Price = 250, Stock = 1, RequiredLevel = 10 },
		IronBlade = { Price = 900, Stock = 1, RequiredLevel = 30 },
	},
}

-- Canonical 11-island route.
-- Each island has a normal-enemy level band and a boss challenge level.
-- The next island opens three levels after the previous island's boss level.
Config.CentralArea = { Id = "CentralArea", Name = "Central Area", UnlockLevel = 1 }
Config.SpecialAreas = {
	{ Id = "EchoBattleArena", Name = "Echo Battle Arena", UnlockLevel = 1 },
	{ Id = "MemoryTrainingIsland", Name = "Memory Training Island", UnlockLevel = 1 },
}

Config.Islands = {
	{ Id = "SunsetBay", Name = "Sunset Bay", UnlockLevel = 1, EnemyLevelMin = 1, EnemyLevelMax = 24, BossLevel = 25 },
	{ Id = "PixelCity", Name = "Pixel City", UnlockLevel = 28, EnemyLevelMin = 28, EnemyLevelMax = 51, BossLevel = 52 },
	{ Id = "ForgottenAcademy", Name = "Forgotten Academy", UnlockLevel = 55, EnemyLevelMin = 55, EnemyLevelMax = 78, BossLevel = 79 },
	{ Id = "ClockworkKingdom", Name = "Clockwork Kingdom", UnlockLevel = 82, EnemyLevelMin = 82, EnemyLevelMax = 105, BossLevel = 106 },
	{ Id = "TheLostEra", Name = "The Lost Era", UnlockLevel = 109, EnemyLevelMin = 109, EnemyLevelMax = 132, BossLevel = 133 },
	{ Id = "EmeraldJungle", Name = "Emerald Jungle", UnlockLevel = 136, EnemyLevelMin = 136, EnemyLevelMax = 159, BossLevel = 160 },
	{ Id = "FrozenKingdom", Name = "Frozen Kingdom", UnlockLevel = 163, EnemyLevelMin = 163, EnemyLevelMax = 186, BossLevel = 187 },
	{ Id = "DragonVolcano", Name = "Dragon Volcano", UnlockLevel = 190, EnemyLevelMin = 190, EnemyLevelMax = 213, BossLevel = 214 },
	{ Id = "SkyRealm", Name = "Sky Realm", UnlockLevel = 217, EnemyLevelMin = 217, EnemyLevelMax = 240, BossLevel = 241 },
	{ Id = "AtlantisIsland", Name = "Atlantis Island", UnlockLevel = 244, EnemyLevelMin = 244, EnemyLevelMax = 267, BossLevel = 268 },
	{ Id = "HauntedIsland", Name = "Haunted Island", UnlockLevel = 271, EnemyLevelMin = 271, EnemyLevelMax = 299, BossLevel = 300 },
}

function Config.GetXPToNextLevel(level: number): number
	local safeLevel = math.clamp(math.floor(level), 1, Config.MaxLevel)
	local offset = safeLevel - 1
	local required = Config.XPBase
		+ offset * Config.XPLinearPerLevel
		+ offset ^ Config.XPPowerExponent * Config.XPPowerScale
	return math.max(1, math.floor(required))
end

function Config.GetIslandById(islandId: string)
	for _, island in ipairs(Config.Islands) do
		if island.Id == islandId then
			return island
		end
	end
	return nil
end

function Config.GetWorldLocationById(locationId: string)
	if locationId == Config.CentralArea.Id then
		return Config.CentralArea
	end
	for _, area in ipairs(Config.SpecialAreas) do
		if area.Id == locationId then
			return area
		end
	end
	return Config.GetIslandById(locationId)
end

function Config.GetIslandIndex(islandId: string): number?
	for index, island in ipairs(Config.Islands) do
		if island.Id == islandId then
			return index
		end
	end
	return nil
end

function Config.GetNextIsland(islandId: string)
	local index = Config.GetIslandIndex(islandId)
	if not index then
		return nil
	end
	return Config.Islands[index + 1]
end

function Config.GetIslandForLevel(level: number)
	local safeLevel = math.clamp(math.floor(level), 1, Config.MaxLevel)
	local selected = Config.Islands[1]
	for _, island in ipairs(Config.Islands) do
		if safeLevel >= island.UnlockLevel then
			selected = island
		else
			break
		end
	end
	return selected
end

function Config.ValidateIslandProgression(): (boolean, string?)
	if #Config.Islands ~= 11 then
		return false, "Expected exactly 11 canonical islands"
	end
	if Config.Islands[1].UnlockLevel ~= 1 then
		return false, "The first island must unlock at level 1"
	end

	local previousBossLevel = 0
	local seenIds: {[string]: boolean} = {}
	for index, island in ipairs(Config.Islands) do
		if seenIds[island.Id] then
			return false, "Duplicate island ID: " .. island.Id
		end
		seenIds[island.Id] = true

		if island.UnlockLevel < 1 or island.UnlockLevel > Config.MaxLevel then
			return false, "Invalid unlock level for " .. island.Id
		end
		if island.EnemyLevelMin < island.UnlockLevel or island.EnemyLevelMax < island.EnemyLevelMin then
			return false, "Invalid enemy level band for " .. island.Id
		end
		if island.BossLevel <= island.EnemyLevelMax or island.BossLevel > Config.MaxLevel then
			return false, "Invalid boss level for " .. island.Id
		end
		if index > 1 and island.UnlockLevel <= previousBossLevel then
			return false, "Next island must unlock after previous boss level: " .. island.Id
		end
		previousBossLevel = island.BossLevel
	end

	if Config.Islands[#Config.Islands].BossLevel ~= Config.MaxLevel then
		return false, "Final island boss must be level 300"
	end
	return true, nil
end


function Config.ValidateEconomy(): (boolean, string?)
	local function isWholeNumber(value: any, allowZero: boolean): boolean
		return typeof(value) == "number"
			and value == value
			and value ~= math.huge
			and value ~= -math.huge
			and value == math.floor(value)
			and (if allowZero then value >= 0 else value > 0)
	end

	local enemy = Config.Economy.EnemyRewards
	for _, key in ipairs({ "XPBase", "XPPerLevel", "CoinBase", "CoinPerLevel" }) do
		if not isWholeNumber(enemy[key], true) then
			return false, "Invalid enemy reward setting: " .. key
		end
	end

	for questId, reward in pairs(Config.Economy.QuestRewards) do
		if typeof(questId) ~= "string" or typeof(reward) ~= "table"
			or not isWholeNumber(reward.XP, true)
			or not isWholeNumber(reward.Coins, true) then
			return false, "Invalid quest currency reward: " .. tostring(questId)
		end
	end

	for itemId, item in pairs(Config.Economy.Shop) do
		if typeof(itemId) ~= "string" or typeof(item) ~= "table"
			or not isWholeNumber(item.Price, false)
			or not isWholeNumber(item.Stock, false)
			or not isWholeNumber(item.RequiredLevel, false)
			or item.RequiredLevel > Config.MaxLevel then
			return false, "Invalid shop definition: " .. tostring(itemId)
		end
	end

	return true, nil
end

return Config
