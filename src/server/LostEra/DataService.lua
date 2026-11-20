--!strict
-- Server-only persistence. DataStore calls must never be exposed to clients.

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Config = require(script.Parent.Config)
local Store = DataStoreService:GetDataStore(Config.DataStoreName)

local DataService = {}
local profiles: {[number]: {[string]: any}} = {}
local saving: {[number]: boolean} = {}

local function defaultProfile()
	return {
		SchemaVersion = 1,
		Level = Config.StartingLevel,
		XP = Config.StartingXP,
		Coins = Config.StartingCoins,
		CurrentIsland = "SunsetBay",
		Inventory = {},
		CompletedQuests = {},
		CreatedAt = os.time(),
		LastSaveAt = 0,
	}
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
	profile.Inventory = if typeof(raw.Inventory) == "table" then raw.Inventory else {}
	profile.CompletedQuests = if typeof(raw.CompletedQuests) == "table" then raw.CompletedQuests else {}
	profile.CreatedAt = tonumber(raw.CreatedAt) or os.time()
	profile.LastSaveAt = tonumber(raw.LastSaveAt) or 0

	if profile.Level >= Config.MaxLevel then
		profile.Level = Config.MaxLevel
		profile.XP = 0
	end
	return profile
end

local function keyFor(userId: number): string
	return Config.DataStoreKeyPrefix .. tostring(userId)
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
	local profile = profiles[userId]
	if not profile or saving[userId] then
		return false
	end

	saving[userId] = true
	profile.LastSaveAt = os.time()
	-- This profile currently contains only scalar fields and owned tables.
	-- Clone nested tables so writes cannot observe mutations during the request.
	local snapshot = table.clone(profile)
	snapshot.Inventory = table.clone(profile.Inventory)
	snapshot.CompletedQuests = table.clone(profile.CompletedQuests)

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
	DataService.SavePlayer(player)
	profiles[player.UserId] = nil
	saving[player.UserId] = nil
end

function DataService.SaveAll()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(DataService.SavePlayer, player)
	end
end

return DataService
