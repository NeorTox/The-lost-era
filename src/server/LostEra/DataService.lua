--!strict
-- Server-only persistence with per-player session locks and ordered saves.
-- Existing profile values remain unchanged; session-lock state is stored in DataStore metadata.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

local Config = require(script.Parent.Config)
local Store = DataStoreService:GetDataStore(Config.DataStoreName)

local DataService = {}
local profiles: {[number]: {[string]: any}} = {}
local sessionTokens: {[number]: string} = {}
local saving: {[number]: boolean} = {}
local loading: {[number]: boolean} = {}
local releasing: {[number]: boolean} = {}

local LOCK_EXPIRY_SECONDS = 180
local LOAD_LOCK_ATTEMPTS = 12
local LOCK_RETRY_INTERVAL = 2
local DATASTORE_RETRIES = 4
local RETRY_BASE_DELAY = 1
local RETRY_MAX_DELAY = 8
local MAX_CURRENCY_BALANCE = Config.MaxCurrencyBalance

local VALID_ITEMS = {
	HealthPotion = 99,
	SmallCoinPouch = 99,
	SlimeGel = 999,
	DriftwoodScrap = 999,
	TideShell = 999,
	TideWardenSigil = 1,
	TrainingBlade = 1,
	BronzeSword = 1,
	IronBlade = 1,
}
local VALID_BOSSES = {
	TideWarden = true,
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
		SchemaVersion = 4,
		Level = Config.StartingLevel,
		XP = Config.StartingXP,
		Coins = Config.StartingCoins,
		SkillPoints = 0,
		MemoryCrystals = 0,
		VoidEssence = 0,
		CurrentIsland = "SunsetBay",
		Inventory = { TrainingBlade = 1 },
		CompletedQuests = {},
		BossCompletions = {},
		QuestProgress = {},
		UnlockedSkills = { "PowerStrike" },
		EquippedSkills = { "PowerStrike" },
		EquippedWeapon = "TrainingBlade",
		CreatedAt = os.time(),
		LastSaveAt = 0,
	}
end

local function sanitizeCurrency(value: any): number
	local amount = tonumber(value)
	if not amount or amount ~= amount or amount == math.huge or amount == -math.huge then
		return 0
	end
	return math.clamp(math.floor(amount), 0, MAX_CURRENCY_BALANCE)
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
		if cap and amount and amount == amount and amount > 0 and amount < math.huge then
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
			if safeProgress and safeProgress == safeProgress and safeProgress < math.huge then
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
	local rawXP = tonumber(raw.XP) or 0
	profile.XP = if rawXP == rawXP and rawXP < math.huge then math.max(0, math.floor(rawXP)) else 0
	profile.Coins = sanitizeCurrency(raw.Coins)
	profile.MemoryCrystals = sanitizeCurrency(raw.MemoryCrystals)
	profile.VoidEssence = sanitizeCurrency(raw.VoidEssence)
	-- Preserve valid saved islands. Retired prototype IDs or islands above the
	-- player's current unlock level resolve to the highest island they can access.
	local savedLocation = if typeof(raw.CurrentIsland) == "string"
		then Config.GetWorldLocationById(raw.CurrentIsland)
		else nil
	if savedLocation and profile.Level >= savedLocation.UnlockLevel then
		profile.CurrentIsland = savedLocation.Id
	else
		profile.CurrentIsland = Config.GetIslandForLevel(profile.Level).Id
	end
	profile.Inventory = sanitizeInventory(raw.Inventory)
	profile.CompletedQuests = sanitizeStringArray(raw.CompletedQuests)
	profile.BossCompletions = sanitizeStringArray(raw.BossCompletions, VALID_BOSSES)
	profile.QuestProgress = sanitizeQuestProgress(raw.QuestProgress)
	local rawSkillPoints = if raw.SkillPoints == nil then math.max(0, profile.Level - 1) else raw.SkillPoints
	profile.SkillPoints = math.clamp(sanitizeCurrency(rawSkillPoints), 0, Config.MaxLevel)
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
	profile.SchemaVersion = 4

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
	snapshot.BossCompletions = table.clone(profile.BossCompletions)
	snapshot.QuestProgress = table.clone(profile.QuestProgress)
	snapshot.UnlockedSkills = table.clone(profile.UnlockedSkills)
	snapshot.EquippedSkills = table.clone(profile.EquippedSkills)
	return snapshot
end

local function copyMetadata(keyInfo: any): {[string]: any}
	local result: {[string]: any} = {}
	if keyInfo then
		local current = keyInfo:GetMetadata()
		if typeof(current) == "table" then
			for key, value in pairs(current) do
				result[key] = value
			end
		end
	end
	return result
end

local function getUserIds(keyInfo: any, userId: number): {number}
	local result: {number} = {}
	if keyInfo then
		for _, existingId in ipairs(keyInfo:GetUserIds()) do
			table.insert(result, existingId)
		end
	end
	if not table.find(result, userId) then
		table.insert(result, userId)
	end
	return result
end

-- All operations for a profile key are serialized by the caller. Retries are
-- performed in this same thread so an older failed write cannot overtake a newer one.
local function updateWithRetries(
	key: string,
	transform: (any, any) -> (any, {number}?, {[string]: any}?),
	userId: number,
	operationName: string
): (boolean, any, any)
	for attempt = 1, DATASTORE_RETRIES do
		local ok, value, keyInfo = pcall(function()
			return Store:UpdateAsync(key, transform)
		end)
		if ok then
			return true, value, keyInfo
		end

		warn(string.format(
			"[TheLostEra] %s attempt %d/%d failed for %d: %s",
			operationName,
			attempt,
			DATASTORE_RETRIES,
			userId,
			tostring(value)
		))
		if attempt < DATASTORE_RETRIES then
			local delaySeconds = math.min(RETRY_MAX_DELAY, RETRY_BASE_DELAY * (2 ^ (attempt - 1)))
			task.wait(delaySeconds + math.random() * math.min(1, delaySeconds * 0.25))
		end
	end
	return false, nil, nil
end

local function waitForSaveSlot(userId: number)
	while saving[userId] do
		task.wait(0.05)
	end
	saving[userId] = true
end

function DataService.LoadPlayer(player: Player)
	local userId = player.UserId
	while loading[userId] do
		if profiles[userId] then
			return profiles[userId]
		end
		if player.Parent ~= Players then
			return nil
		end
		task.wait(0.05)
	end
	if profiles[userId] then
		return profiles[userId]
	end

	loading[userId] = true
	local token = HttpService:GenerateGUID(false)
	local key = keyFor(userId)
	local loadedProfile: {[string]: any}? = nil
	local loadRefusalReason: string? = nil

	for lockAttempt = 1, LOAD_LOCK_ATTEMPTS do
		if player.Parent ~= Players then
			break
		end

		local ok, storedValue, keyInfo = updateWithRetries(
			key,
			function(oldValue, currentKeyInfo)
				if oldValue ~= nil and typeof(oldValue) ~= "table" then
					loadRefusalReason = "Stored profile has an unsupported data shape"
					return nil
				end
				if typeof(oldValue) == "table" then
					local storedSchemaVersion = tonumber(oldValue.SchemaVersion) or 1
					if storedSchemaVersion > 4 then
						loadRefusalReason = "Stored profile was written by a newer game schema"
						return nil
					end
				end

				local metadata = copyMetadata(currentKeyInfo)
				local existingToken = metadata.SessionLockId
				local lastRefresh = tonumber(metadata.SessionLockUpdatedAt)
				if typeof(existingToken) == "string" and existingToken ~= token then
					if not lastRefresh or os.time() - lastRefresh < LOCK_EXPIRY_SECONDS then
						return nil
					end
				end

				local newValue = if typeof(oldValue) == "table" then table.clone(oldValue) else defaultProfile()
				metadata.SessionLockId = token
				metadata.SessionLockUpdatedAt = tostring(os.time())
				return newValue, getUserIds(currentKeyInfo, userId), metadata
			end,
			userId,
			"Profile load/lock"
		)

		if not ok or loadRefusalReason then
			break
		end

		if typeof(storedValue) == "table" and keyInfo then
			local metadata = copyMetadata(keyInfo)
			if metadata.SessionLockId == token then
				loadedProfile = sanitizeProfile(storedValue)
				break
			end
		end

		if lockAttempt < LOAD_LOCK_ATTEMPTS then
			task.wait(LOCK_RETRY_INTERVAL + math.random() * 0.5)
		end
	end

	if loadedProfile then
		profiles[userId] = loadedProfile
		sessionTokens[userId] = token
		loading[userId] = nil
		if player.Parent ~= Players then
			DataService.ReleasePlayer(player)
			return nil
		end
		return loadedProfile
	end

	loading[userId] = nil
	if player.Parent == Players then
		warn("[TheLostEra] Profile load was not completed:", userId, loadRefusalReason or "An active session lock or DataStore error prevented access.")
		player:Kick("Your data could not be safely loaded. Please rejoin shortly.")
	end
	return nil
end

function DataService.GetProfile(player: Player)
	return profiles[player.UserId]
end

function DataService.SavePlayer(player: Player): boolean
	local userId = player.UserId
	waitForSaveSlot(userId)

	local profile = profiles[userId]
	local token = sessionTokens[userId]
	if not profile or not token then
		saving[userId] = nil
		return false
	end

	profile.LastSaveAt = os.time()
	local snapshot = cloneProfile(profile)
	local ok, savedValue, keyInfo = updateWithRetries(
		keyFor(userId),
		function(oldValue, currentKeyInfo)
			if typeof(oldValue) ~= "table" then
				return nil
			end
			local metadata = copyMetadata(currentKeyInfo)
			if metadata.SessionLockId ~= token then
				return nil
			end
			metadata.SessionLockUpdatedAt = tostring(os.time())
			return cloneProfile(snapshot), getUserIds(currentKeyInfo, userId), metadata
		end,
		userId,
		"Profile save"
	)
	saving[userId] = nil

	if not ok then
		warn("[TheLostEra] Profile save exhausted retries; lock will be left to expire:", userId)
		return false
	end
	if typeof(savedValue) ~= "table" or not keyInfo or copyMetadata(keyInfo).SessionLockId ~= token then
		warn("[TheLostEra] Profile save cancelled because this server no longer owns the session lock:", userId)
		return false
	end
	return true
end

local function releaseSessionLock(userId: number, token: string): boolean
	local ok, releasedValue = updateWithRetries(
		keyFor(userId),
		function(oldValue, currentKeyInfo)
			if typeof(oldValue) ~= "table" then
				return nil
			end
			local metadata = copyMetadata(currentKeyInfo)
			if metadata.SessionLockId ~= token then
				return nil
			end
			metadata.SessionLockId = nil
			metadata.SessionLockUpdatedAt = nil
			return oldValue, getUserIds(currentKeyInfo, userId), metadata
		end,
		userId,
		"Session unlock"
	)
	return ok and typeof(releasedValue) == "table"
end

function DataService.ReleasePlayer(player: Player)
	local userId = player.UserId
	while releasing[userId] do
		task.wait(0.05)
	end
	if not profiles[userId] then
		return
	end

	releasing[userId] = true
	local token = sessionTokens[userId]
	local saved = DataService.SavePlayer(player)
	if saved and token then
		if not releaseSessionLock(userId, token) then
			warn("[TheLostEra] Session lock could not be released; it will expire automatically:", userId)
		end
	else
		warn("[TheLostEra] Final save failed; session lock will be left in place until expiry:", userId)
	end

	profiles[userId] = nil
	sessionTokens[userId] = nil
	releasing[userId] = nil
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

function DataService.ReleaseAll()
	local pending = 0
	for _, player in ipairs(Players:GetPlayers()) do
		if profiles[player.UserId] then
			pending += 1
			task.spawn(function()
				DataService.ReleasePlayer(player)
				pending -= 1
			end)
		end
	end
	while pending > 0 do
		task.wait(0.05)
	end
end

return DataService
