--!strict
-- Server-only persistence. DataStore calls must never be exposed to clients.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(script.Parent.Config)
local Store = DataStoreService:GetDataStore(Config.DataStoreName)

local DataService = {}
local profiles: {[number]: {[string]: any}} = {}
local saving: {[number]: boolean} = {}

local VALID_ITEMS = {
	HealthPotion = 99,
	SmallCoinPouch = 99,
	TrainingBlade = 1,
	BronzeSword = 1,
	IronBlade = 1,
}
local VALID_SKILLS = {
	PowerStrike = true,
	Whirlwind = true,
	HealingPulse = true,
	ArcaneBurst = true,
}
local VALID_WEAPONS = {
	TrainingBlade = true,
	BronzeSword = true,
	IronBlade = true,
}

local function defaultProfile()
	return {
		SchemaVersion = 3,
		Level = Config.StartingLevel,
		XP = Config.StartingXP,
		Coins = Config.StartingCoins,
		CurrentIsland = "SunsetBay",
		Inventory = { TrainingBlade = 1 },
		CompletedQuests = {},
		QuestProgress = {},
		SkillPoints = 0,
		UnlockedSkills = { "PowerStrike" },
		EquippedSkills = { "PowerStrike" },
		EquippedWeapon = "TrainingBlade",
		CreatedAt = os.time(),
		LastSaveAt = 0,
	}
end

local function sanitizeStringArray(value: any, allowed: {[string]: boolean}?): {string}
	local result = {}
	local seen = {}
	if typeof(value) ~= "table" then
		return result
	end
	for _, entry in ipairs(value) do
		if typeof(entry) == "string" and #entry <= 100
			and (not allowed or allowed[entry]) and not seen[entry] then
			seen[entry] = true
			table.insert(result, entry)
		end
	end
	return result
end

local function sanitizeInventory(value: any): {[string]: number}
	local result: {[string]: number} = {}
	if typeof(value) ~= "table" then
		return result
	end
	for itemId, rawAmount in pairs(value) do
		local cap = if typeof(itemId) == "string" then VALID_ITEMS[itemId] else nil
		local amount = tonumber(rawAmount)
		if cap and amount and amount == amount and amount > 0 then
			result[itemId] = math.clamp(math.floor(amount), 0, cap)
			if result[itemId] == 0 then
				result[itemId] = nil
			end
		end
	end
	return result
end

local function sanitizeQuestProgress(value: any): {[string]: number}
	local result: {[string]: number} = {}
	if typeof(value) ~= "table" then
		return result
	end
	for questId, progress in pairs(value) do
		if typeof(questId) == "string" and #questId <= 100 then
			local safeProgress = tonumber(progress)
			if safeProgress and safeProgress == safeProgress then
				result[questId] = math.clamp(math.floor(safeProgress), 0, 1000000)
			end
		end
	end
	return result
end

local function sanitizeProfile(raw: any)
	local profile = defaultProfile()
	if typeof(raw) ~= "table" then
		return profile
	end

	profile.Level = math.clamp(math.floor(tonumber(raw.Level) or 1), 1, Config.MaxLevel)
	profile.XP = math.max(0, math.floor(tonumber(raw.XP) or 0))
	profile.Coins = math.max(0, math.floor(tonumber(raw.Coins) or 0))
	profile.CurrentIsland = if typeof(raw.CurrentIsland) == "string" and Config.GetIslandById(raw.CurrentIsland) then raw.CurrentIsland else "SunsetBay"
	profile.Inventory = sanitizeInventory(raw.Inventory)
	profile.CompletedQuests = sanitizeStringArray(raw.CompletedQuests)
	profile.QuestProgress = sanitizeQuestProgress(raw.QuestProgress)
	profile.SkillPoints = math.clamp(
		math.floor(tonumber(raw.SkillPoints) or math.max(0, profile.Level - 1)),
		0,
		Config.MaxLevel
	)
	profile.UnlockedSkills = sanitizeStringArray(raw.UnlockedSkills, VALID_SKILLS)
	if not table.find(profile.UnlockedSkills, "PowerStrike") then
		table.insert(profile.UnlockedSkills, "PowerStrike")
	end
	profile.EquippedSkills = sanitizeStringArray(raw.EquippedSkills, VALID_SKILLS)
	local validEquipped = {}
	for _, skillId in ipairs(profile.EquippedSkills) do
		if table.find(profile.UnlockedSkills, skillId) and #validEquipped < 3 then
			table.insert(validEquipped, skillId)
		end
	end
	profile.EquippedSkills = validEquipped
	if #profile.EquippedSkills == 0 then
		profile.EquippedSkills = { "PowerStrike" }
	end

	if not profile.Inventory.TrainingBlade and not profile.Inventory.BronzeSword and not profile.Inventory.IronBlade then
		profile.Inventory.TrainingBlade = 1
	end
	local equippedWeapon = raw.EquippedWeapon
	if typeof(equippedWeapon) == "string" and VALID_WEAPONS[equippedWeapon]
		and (profile.Inventory[equippedWeapon] or 0) > 0 then
		profile.EquippedWeapon = equippedWeapon
	else
		profile.EquippedWeapon = "TrainingBlade"
	end
	if (profile.Inventory[profile.EquippedWeapon] or 0) < 1 then
		profile.Inventory.TrainingBlade = 1
		profile.EquippedWeapon = "TrainingBlade"
	end

	profile.CreatedAt = tonumber(raw.CreatedAt) or os.time()
	profile.LastSaveAt = tonumber(raw.LastSaveAt) or 0
	profile.SchemaVersion = 3

	if profile.Level >= Config.MaxLevel then
		profile.Level = Config.MaxLevel
		profile.XP = 0
	end
	return profile
end

local function keyFor(userId: number): string
	return Config.DataStoreKeyPrefix .. tostring(userId)
end

local function cloneProfile(profile: {[string]: any})
	local snapshot = table.clone(profile)
	snapshot.Inventory = table.clone(profile.Inventory)
	snapshot.CompletedQuests = table.clone(profile.CompletedQuests)
	snapshot.QuestProgress = table.clone(profile.QuestProgress)
	snapshot.UnlockedSkills = table.clone(profile.UnlockedSkills)
	snapshot.EquippedSkills = table.clone(profile.EquippedSkills)
	return snapshot
end

function DataService.LoadPlayer(player: Player)
	local ok, result = pcall(function()
		return Store:GetAsync(keyFor(player.UserId))
	end)

	if not ok then
		warn("[TheLostEra] Failed to load profile:", player.UserId, result)
		player:Kick("Your data could not be loaded. Please rejoin shortly.")
		return nil
	end

	local profile = sanitizeProfile(result)
	profiles[player.UserId] = profile
	return profile
end

function DataService.GetProfile(player: Player)
	return profiles[player.UserId]
end

function DataService.SavePlayer(player: Player): boolean
	local userId = player.UserId
	while saving[userId] do
		task.wait(0.05)
	end

	local profile = profiles[userId]
	if not profile then
		return false
	end

	saving[userId] = true
	profile.LastSaveAt = os.time()
	local snapshot = cloneProfile(profile)

	local ok, err = pcall(function()
		Store:UpdateAsync(keyFor(userId), function(_oldValue)
			return snapshot
		end)
	end)
	saving[userId] = nil

	if not ok then
		warn("[TheLostEra] Failed to save profile:", userId, err)
		return false
	end
	return true
end

function DataService.ReleasePlayer(player: Player)
	local userId = player.UserId
	DataService.SavePlayer(player)
	while saving[userId] do
		task.wait(0.05)
	end
	profiles[userId] = nil
end

function DataService.SaveAll()
	local pending = 0
	for _, player in ipairs(Players:GetPlayers()) do
		pending += 1
		task.spawn(function()
			DataService.SavePlayer(player)
			pending -= 1
		end)
	end

	while pending > 0 do
		task.wait(0.05)
	end
end

return DataService
