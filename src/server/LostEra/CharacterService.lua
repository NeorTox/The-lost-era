--!strict
-- Character lifecycle, baseline movement stats, and server-authoritative sprint stamina.

local Players = game:GetService("Players")

local Config = require(script.Parent.Config)

local CharacterService = {}

local initialized: {[number]: boolean} = {}
local sprintRequested: {[number]: boolean} = {}
local loopGeneration: {[number]: number} = {}
local characterConnections: {[number]: RBXScriptConnection} = {}

local STEP_SECONDS = 0.2

local function getLivingHumanoid(player: Player): Humanoid?
	local character = player.Character
	if not character then
		return nil
	end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid and humanoid.Health > 0 then
		return humanoid
	end
	return nil
end

local function stopSprint(player: Player)
	local userId = player.UserId
	sprintRequested[userId] = nil
	player:SetAttribute("IsSprinting", false)
	local humanoid = getLivingHumanoid(player)
	if humanoid then
		humanoid.WalkSpeed = Config.BaseWalkSpeed
	end
end

local function configureCharacter(player: Player, character: Model)
	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") then
		warn("[TheLostEra] Character spawned without a Humanoid:", player.UserId)
		return
	end
	if player.Character ~= character or player.Parent ~= Players then
		return
	end

	sprintRequested[player.UserId] = nil
	player:SetAttribute("IsSprinting", false)
	player:SetAttribute("MaxHealth", Config.BaseMaxHealth)
	humanoid.MaxHealth = Config.BaseMaxHealth
	humanoid.Health = Config.BaseMaxHealth
	humanoid.WalkSpeed = Config.BaseWalkSpeed
	humanoid.UseJumpPower = true
	humanoid.JumpPower = Config.BaseJumpPower
	humanoid.AutoRotate = true

	player:SetAttribute("MaxStamina", Config.BaseMaxStamina)
	player:SetAttribute("Stamina", Config.BaseMaxStamina)

	humanoid.Died:Connect(function()
		sprintRequested[player.UserId] = nil
		player:SetAttribute("IsSprinting", false)
	end)
end

local function startStaminaLoop(player: Player)
	local userId = player.UserId
	local generation = (loopGeneration[userId] or 0) + 1
	loopGeneration[userId] = generation

	task.spawn(function()
		while player.Parent == Players and initialized[userId] and loopGeneration[userId] == generation do
			task.wait(STEP_SECONDS)

			local humanoid = getLivingHumanoid(player)
			local stamina = tonumber(player:GetAttribute("Stamina")) or 0
			local maximum = tonumber(player:GetAttribute("MaxStamina")) or Config.BaseMaxStamina

			if sprintRequested[userId] then
				if not humanoid then
					stopSprint(player)
				elseif humanoid.MoveDirection.Magnitude > 0.05 then
					stamina = math.max(0, stamina - Config.StaminaDrainPerSecond * STEP_SECONDS)
					player:SetAttribute("Stamina", stamina)
					if stamina <= 0 then
						stopSprint(player)
					end
				else
					stamina = math.min(maximum, stamina + Config.StaminaRegenPerSecond * STEP_SECONDS)
					player:SetAttribute("Stamina", stamina)
				end
			else
				if stamina < maximum then
					player:SetAttribute("Stamina", math.min(maximum, stamina + Config.StaminaRegenPerSecond * STEP_SECONDS))
				end
			end
		end
	end)
end

function CharacterService.InitPlayer(player: Player)
	local userId = player.UserId
	if initialized[userId] then
		return
	end
	initialized[userId] = true
	sprintRequested[userId] = nil
	player:SetAttribute("MaxHealth", Config.BaseMaxHealth)
	player:SetAttribute("MaxStamina", Config.BaseMaxStamina)
	player:SetAttribute("Stamina", Config.BaseMaxStamina)
	player:SetAttribute("IsSprinting", false)

	characterConnections[userId] = player.CharacterAdded:Connect(function(character)
		task.spawn(configureCharacter, player, character)
	end)

	if player.Character then
		task.spawn(configureCharacter, player, player.Character)
	end
	startStaminaLoop(player)
end

function CharacterService.SetSprinting(player: Player, shouldSprint: any): (boolean, string?)
	if typeof(shouldSprint) ~= "boolean" then
		return false, "InvalidRequest"
	end
	if not initialized[player.UserId] then
		return false, "PlayerNotReady"
	end
	if not shouldSprint then
		stopSprint(player)
		return true, nil
	end

	local humanoid = getLivingHumanoid(player)
	if not humanoid then
		stopSprint(player)
		return false, "CharacterUnavailable"
	end
	local stamina = tonumber(player:GetAttribute("Stamina")) or 0
	if stamina <= 0 then
		stopSprint(player)
		return false, "InsufficientStamina"
	end

	sprintRequested[player.UserId] = true
	player:SetAttribute("IsSprinting", true)
	humanoid.WalkSpeed = Config.SprintWalkSpeed
	return true, nil
end

function CharacterService.ReleasePlayer(player: Player)
	local userId = player.UserId
	initialized[userId] = nil
	sprintRequested[userId] = nil
	loopGeneration[userId] = (loopGeneration[userId] or 0) + 1
	player:SetAttribute("IsSprinting", false)

	local connection = characterConnections[userId]
	if connection then
		connection:Disconnect()
		characterConnections[userId] = nil
	end
end

return CharacterService
