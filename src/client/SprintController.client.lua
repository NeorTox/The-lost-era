--!strict
-- Keyboard and mobile touch controls for server-validated sprinting.

local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("TheLostEraRemotes")
local sprintRequest = remotes:WaitForChild("SprintRequest") :: RemoteEvent

local ACTION_NAME = "TheLostEraSprint"
local requestActive = false

local function requestSprint(shouldSprint: boolean)
	if requestActive == shouldSprint then
		return
	end
	requestActive = shouldSprint
	sprintRequest:FireServer(shouldSprint)
end

local function handleSprintAction(_actionName: string, inputState: Enum.UserInputState)
	if inputState == Enum.UserInputState.Begin then
		requestSprint(true)
	elseif inputState == Enum.UserInputState.End or inputState == Enum.UserInputState.Cancel then
		requestSprint(false)
	end
	return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction(ACTION_NAME, handleSprintAction, true, Enum.KeyCode.LeftShift)
ContextActionService:SetTitle(ACTION_NAME, "SPRINT")
ContextActionService:SetPosition(ACTION_NAME, UDim2.new(0.82, 0, 0.68, 0))

local function watchCharacter(character: Model)
	requestActive = false
	local humanoid = character:WaitForChild("Humanoid", 10)
	if humanoid and humanoid:IsA("Humanoid") then
		humanoid.Died:Connect(function()
			requestSprint(false)
		end)
	end
end

player.CharacterAdded:Connect(watchCharacter)
if player.Character then
	task.spawn(watchCharacter, player.Character)
end
