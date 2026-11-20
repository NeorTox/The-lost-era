--!strict
-- THE LOST ERA — central server configuration.

local Config = {}

Config.DataStoreName = "TheLostEra_PlayerData_v1"
Config.DataStoreKeyPrefix = "player_"
Config.AutoSaveInterval = 60
Config.MaxLevel = 300
Config.StartingLevel = 1
Config.StartingXP = 0
Config.StartingCoins = 0

Config.Islands = {
	{ Id = "SunsetBay", Name = "Sunset Bay", UnlockLevel = 1, EnemyLevelMin = 1, EnemyLevelMax = 35, BossLevel = 40 },
	{ Id = "PixelCity", Name = "Pixel City", UnlockLevel = 40, EnemyLevelMin = 40, EnemyLevelMax = 75, BossLevel = 80 },
	{ Id = "ClockworkKingdom", Name = "Clockwork Kingdom", UnlockLevel = 80, EnemyLevelMin = 80, EnemyLevelMax = 115, BossLevel = 120 },
	{ Id = "EmeraldJungle", Name = "Emerald Jungle", UnlockLevel = 120, EnemyLevelMin = 120, EnemyLevelMax = 155, BossLevel = 160 },
	{ Id = "DragonVolcano", Name = "Dragon Volcano", UnlockLevel = 160, EnemyLevelMin = 160, EnemyLevelMax = 205, BossLevel = 210 },
	{ Id = "SkyRealm", Name = "Sky Realm", UnlockLevel = 210, EnemyLevelMin = 210, EnemyLevelMax = 255, BossLevel = 260 },
	{ Id = "ForgottenKingdom", Name = "Forgotten Kingdom", UnlockLevel = 260, EnemyLevelMin = 260, EnemyLevelMax = 275, BossLevel = 280 },
	{ Id = "EternalAbyss", Name = "Eternal Abyss", UnlockLevel = 280, EnemyLevelMin = 280, EnemyLevelMax = 295, BossLevel = 300 },
}

function Config.GetXPToNextLevel(level: number): number
	local safeLevel = math.clamp(math.floor(level), 1, Config.MaxLevel)
	local offset = safeLevel - 1
	return math.floor(100 + offset * 35 + offset ^ 1.35 * 8)
end

function Config.GetIslandById(islandId: string)
	for _, island in ipairs(Config.Islands) do
		if island.Id == islandId then
			return island
		end
	end
	return nil
end

function Config.GetIslandForLevel(level: number)
	local selected = Config.Islands[1]
	for _, island in ipairs(Config.Islands) do
		if level >= island.UnlockLevel then
			selected = island
		else
			break
		end
	end
	return selected
end

return Config
