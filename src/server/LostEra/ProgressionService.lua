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
	local island = Config.GetIslandForLevel(profile.Level)
	player:SetAttribute("RecommendedIsland", island.Id)
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

	local safeAmount = math.max(0, math.floor(amount))
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

	sync(player, profile)
	return true, levelsGained
end

function ProgressionService.AddCoins(player: Player, amount: number): boolean
	local profile = DataService.GetProfile(player)
	if not profile then
		return false
	end

	local safeAmount = math.max(0, math.floor(amount))
	if safeAmount == 0 then
		return true
	end

	profile.Coins += safeAmount
	player:SetAttribute("Coins", profile.Coins)
	return true
end

function ProgressionService.CanAccessIsland(player: Player, islandId: string): boolean
	local profile = DataService.GetProfile(player)
	local island = Config.GetIslandById(islandId)
	return profile ~= nil and island ~= nil and profile.Level >= island.UnlockLevel
end

return ProgressionService
