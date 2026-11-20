--!strict
-- Quest progress and rewards are validated on the server.

local DataService = require(script.Parent.DataService)
local ProgressionService = require(script.Parent.ProgressionService)

local QuestService = {}

local Quests = {
	WelcomeToSunsetBay = {
		Id = "WelcomeToSunsetBay",
		Name = "Welcome to Sunset Bay",
		Description = "Defeat 3 training slimes.",
		Target = 3,
		XPReward = 75,
		CoinReward = 25,
	},
}

local progressByUser: {[number]: {[string]: number}} = {}

function QuestService.GetDefinitions()
	return Quests
end

function QuestService.GetProgress(player: Player, questId: string): number
	local userProgress = progressByUser[player.UserId]
	return if userProgress then userProgress[questId] or 0 else 0
end

function QuestService.AddProgress(player: Player, questId: string, amount: number): boolean
	local quest = Quests[questId]
	if not quest or amount <= 0 then
		return false
	end
	local profile = DataService.GetProfile(player)
	if not profile then
		return false
	end
	if table.find(profile.CompletedQuests, questId) then
		return false
	end

	local userProgress = progressByUser[player.UserId]
	if not userProgress then
		userProgress = {}
		progressByUser[player.UserId] = userProgress
	end
	userProgress[questId] = math.clamp((userProgress[questId] or 0) + math.floor(amount), 0, quest.Target)
	return true
end

function QuestService.ClaimReward(player: Player, questId: string): (boolean, string?)
	local quest = Quests[questId]
	local profile = DataService.GetProfile(player)
	if not quest or not profile then
		return false, "QuestUnavailable"
	end
	if table.find(profile.CompletedQuests, questId) then
		return false, "AlreadyClaimed"
	end
	if QuestService.GetProgress(player, questId) < quest.Target then
		return false, "ObjectivesIncomplete"
	end

	-- Mark completed before granting rewards so repeated calls cannot double-claim.
	table.insert(profile.CompletedQuests, questId)
	ProgressionService.AddXP(player, quest.XPReward)
	ProgressionService.AddCoins(player, quest.CoinReward)
	return true, nil
end

function QuestService.ReleasePlayer(player: Player)
	progressByUser[player.UserId] = nil
end

return QuestService
