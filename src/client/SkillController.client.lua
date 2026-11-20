--!strict
-- Touch-friendly skill hotbar with keyboard shortcuts 1, 2 and 3.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("TheLostEraRemotes")
local stateRequest = remotes:WaitForChild("SkillStateRequest") :: RemoteEvent
local stateResult = remotes:WaitForChild("SkillStateResult") :: RemoteEvent
local useRequest = remotes:WaitForChild("SkillUseRequest") :: RemoteEvent
local useResult = remotes:WaitForChild("SkillUseResult") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "LostEraSkillHotbar"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 20
gui.Parent = player:WaitForChild("PlayerGui")

local hotbar = Instance.new("Frame")
hotbar.Name = "Hotbar"
hotbar.AnchorPoint = Vector2.new(0.5, 1)
hotbar.Position = UDim2.new(0.5, 0, 0.985, 0)
hotbar.Size = UDim2.new(0.92, 0, 0, 76)
hotbar.BackgroundColor3 = Color3.fromRGB(17, 22, 34)
hotbar.BackgroundTransparency = 0.08
hotbar.BorderSizePixel = 0
hotbar.Parent = gui

local maxWidth = Instance.new("UISizeConstraint")
maxWidth.MaxSize = Vector2.new(460, 76)
maxWidth.MinSize = Vector2.new(250, 76)
maxWidth.Parent = hotbar

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 14)
corner.Parent = hotbar

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(91, 116, 158)
stroke.Transparency = 0.35
stroke.Thickness = 1
stroke.Parent = hotbar

local padding = Instance.new("UIPadding")
padding.PaddingLeft = UDim.new(0, 7)
padding.PaddingRight = UDim.new(0, 7)
padding.PaddingTop = UDim.new(0, 7)
padding.PaddingBottom = UDim.new(0, 7)
padding.Parent = hotbar

local layout = Instance.new("UIListLayout")
layout.FillDirection = Enum.FillDirection.Horizontal
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.VerticalAlignment = Enum.VerticalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Padding = UDim.new(0, 7)
layout.Parent = hotbar

local status = Instance.new("TextLabel")
status.Name = "SkillStatus"
status.AnchorPoint = Vector2.new(0.5, 1)
status.Position = UDim2.new(0.5, 0, 0.985, -82)
status.Size = UDim2.new(0.8, 0, 0, 26)
status.BackgroundColor3 = Color3.fromRGB(17, 22, 34)
status.BackgroundTransparency = 0.15
status.BorderSizePixel = 0
status.Font = Enum.Font.GothamMedium
status.TextColor3 = Color3.fromRGB(235, 241, 255)
status.TextSize = 13
status.Visible = false
status.Parent = gui

local statusCorner = Instance.new("UICorner")
statusCorner.CornerRadius = UDim.new(0, 8)
statusCorner.Parent = status

local buttons: {TextButton} = {}
local slotSkills: {[number]: string} = {}
local slotEnergyCosts: {[number]: number} = {}
local energy = 100
local statusVersion = 0

local function showStatus(message: string)
	statusVersion += 1
	local version = statusVersion
	status.Text = message
	status.Visible = true
	task.delay(2.2, function()
		if statusVersion == version then
			status.Visible = false
		end
	end)
end

local function createSlot(slot: number)
	local button = Instance.new("TextButton")
	button.Name = "SkillSlot" .. tostring(slot)
	button.LayoutOrder = slot
	button.Size = UDim2.new(1 / 3, -7, 1, 0)
	button.BackgroundColor3 = Color3.fromRGB(43, 57, 81)
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.Text = tostring(slot) .. "\nEMPTY"
	button.TextColor3 = Color3.fromRGB(226, 234, 248)
	button.TextSize = 12
	button.TextWrapped = true
	button.Parent = hotbar

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 10)
	buttonCorner.Parent = button

	button.Activated:Connect(function()
		local skillId = slotSkills[slot]
		if skillId then
			useRequest:FireServer(skillId)
		end
	end)

	buttons[slot] = button
end

for slot = 1, 3 do
	createSlot(slot)
end

local function renderState(state: any)
	if typeof(state) ~= "table" then
		return
	end
	energy = tonumber(state.Energy) or energy
	slotSkills = {}

	for slot, skillId in ipairs(state.EquippedSkills or {}) do
		if slot <= 3 and typeof(skillId) == "string" then
			slotSkills[slot] = skillId
		end
	end

	local definitions: {[string]: any} = {}
	for _, definition in ipairs(state.Skills or {}) do
		if typeof(definition) == "table" then
			definitions[definition.Id] = definition
		end
	end

	for slot = 1, 3 do
		local skillId = slotSkills[slot]
		local definition = if skillId then definitions[skillId] else nil
		local button = buttons[slot]
		if definition then
			slotEnergyCosts[slot] = definition.EnergyCost
			button.Text = string.format("%d  %s\n%d ENERGY", slot, string.upper(definition.Name), definition.EnergyCost)
			button.BackgroundColor3 = if energy >= definition.EnergyCost
				then Color3.fromRGB(42, 91, 105)
				else Color3.fromRGB(67, 65, 75)
		else
			button.Text = tostring(slot) .. "\nEMPTY"
			button.BackgroundColor3 = Color3.fromRGB(43, 57, 81)
		end
	end
end

stateResult.OnClientEvent:Connect(renderState)

useResult.OnClientEvent:Connect(function(ok: boolean, resultCode: string, payload: any)
	if ok then
		if payload and payload.HitCount then
			showStatus(string.format("%s hit %d target(s) for %d damage", resultCode, payload.HitCount, payload.TotalDamage))
		elseif payload and payload.Healing then
			showStatus(string.format("Healing Pulse restored %d health", payload.Healing))
		else
			showStatus("Ability used")
		end
	else
		local messages: {[string]: string} = {
			Cooldown = "That ability is still cooling down",
			InsufficientEnergy = "Not enough energy",
			NoTargets = "No enemies in range",
			HealthFull = "Health is already full",
			SkillNotEquipped = "Equip this ability first",
			SkillLocked = "This ability is locked",
		}
		showStatus(messages[resultCode] or resultCode)
	end
	stateRequest:FireServer()
end)

player:GetAttributeChangedSignal("Energy"):Connect(function()
	energy = tonumber(player:GetAttribute("Energy")) or energy
	for slot = 1, 3 do
		if slotSkills[slot] then
			buttons[slot].BackgroundColor3 = if energy >= (slotEnergyCosts[slot] or math.huge)
				then Color3.fromRGB(42, 91, 105)
				else Color3.fromRGB(67, 65, 75)
		end
	end
end)

local keyToSlot = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
}
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
	local slot = keyToSlot[input.KeyCode]
	local skillId = if slot then slotSkills[slot] else nil
	if skillId then
		useRequest:FireServer(skillId)
	end
end)

player.CharacterAdded:Connect(function()
	task.wait(1)
	stateRequest:FireServer()
end)

stateRequest:FireServer()
