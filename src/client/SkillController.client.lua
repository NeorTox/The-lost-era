--!strict
-- Touch-friendly skill hotbar, skill management panel and keyboard shortcuts 1/2/3.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("TheLostEraRemotes")

local stateRequest = remotes:WaitForChild("SkillStateRequest") :: RemoteEvent
local stateResult = remotes:WaitForChild("SkillStateResult") :: RemoteEvent
local useRequest = remotes:WaitForChild("SkillUseRequest") :: RemoteEvent
local useResult = remotes:WaitForChild("SkillUseResult") :: RemoteEvent
local unlockRequest = remotes:WaitForChild("SkillUnlockRequest") :: RemoteEvent
local unlockResult = remotes:WaitForChild("SkillUnlockResult") :: RemoteEvent
local equipRequest = remotes:WaitForChild("SkillEquipRequest") :: RemoteEvent
local equipResult = remotes:WaitForChild("SkillEquipResult") :: RemoteEvent

local gui = Instance.new("ScreenGui")
gui.Name = "LostEraSkillUI"
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

local hotbarConstraint = Instance.new("UISizeConstraint")
hotbarConstraint.MaxSize = Vector2.new(460, 76)
hotbarConstraint.MinSize = Vector2.new(250, 76)
hotbarConstraint.Parent = hotbar

local hotbarCorner = Instance.new("UICorner")
hotbarCorner.CornerRadius = UDim.new(0, 14)
hotbarCorner.Parent = hotbar

local hotbarStroke = Instance.new("UIStroke")
hotbarStroke.Color = Color3.fromRGB(91, 116, 158)
hotbarStroke.Transparency = 0.35
hotbarStroke.Thickness = 1
hotbarStroke.Parent = hotbar

local hotbarPadding = Instance.new("UIPadding")
hotbarPadding.PaddingLeft = UDim.new(0, 7)
hotbarPadding.PaddingRight = UDim.new(0, 7)
hotbarPadding.PaddingTop = UDim.new(0, 7)
hotbarPadding.PaddingBottom = UDim.new(0, 7)
hotbarPadding.Parent = hotbar

local hotbarLayout = Instance.new("UIListLayout")
hotbarLayout.FillDirection = Enum.FillDirection.Horizontal
hotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
hotbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
hotbarLayout.SortOrder = Enum.SortOrder.LayoutOrder
hotbarLayout.Padding = UDim.new(0, 7)
hotbarLayout.Parent = hotbar

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

local menuToggle = Instance.new("TextButton")
menuToggle.Name = "SkillMenuToggle"
menuToggle.AnchorPoint = Vector2.new(1, 1)
menuToggle.Position = UDim2.new(1, -6, 0, -5)
menuToggle.Size = UDim2.fromOffset(86, 27)
menuToggle.BackgroundColor3 = Color3.fromRGB(67, 89, 128)
menuToggle.BorderSizePixel = 0
menuToggle.Font = Enum.Font.GothamBold
menuToggle.Text = "SKILLS"
menuToggle.TextColor3 = Color3.fromRGB(245, 248, 255)
menuToggle.TextSize = 11
menuToggle.Parent = hotbar
local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 7)
toggleCorner.Parent = menuToggle

local menu = Instance.new("Frame")
menu.Name = "SkillMenu"
menu.AnchorPoint = Vector2.new(0.5, 1)
menu.Position = UDim2.new(0.5, 0, 0.985, -86)
menu.Size = UDim2.new(0.92, 0, 0, 300)
menu.BackgroundColor3 = Color3.fromRGB(17, 22, 34)
menu.BorderSizePixel = 0
menu.Visible = false
menu.Parent = gui

local menuConstraint = Instance.new("UISizeConstraint")
menuConstraint.MaxSize = Vector2.new(460, 300)
menuConstraint.MinSize = Vector2.new(250, 300)
menuConstraint.Parent = menu
local menuCorner = Instance.new("UICorner")
menuCorner.CornerRadius = UDim.new(0, 14)
menuCorner.Parent = menu
local menuStroke = Instance.new("UIStroke")
menuStroke.Color = Color3.fromRGB(91, 116, 158)
menuStroke.Transparency = 0.25
menuStroke.Parent = menu

local menuTitle = Instance.new("TextLabel")
menuTitle.BackgroundTransparency = 1
menuTitle.Position = UDim2.fromOffset(12, 7)
menuTitle.Size = UDim2.new(0.55, 0, 0, 25)
menuTitle.Font = Enum.Font.GothamBold
menuTitle.Text = "ABILITIES"
menuTitle.TextColor3 = Color3.fromRGB(239, 244, 255)
menuTitle.TextSize = 15
menuTitle.TextXAlignment = Enum.TextXAlignment.Left
menuTitle.Parent = menu

local pointsLabel = Instance.new("TextLabel")
pointsLabel.BackgroundTransparency = 1
pointsLabel.AnchorPoint = Vector2.new(1, 0)
pointsLabel.Position = UDim2.new(1, -42, 0, 8)
pointsLabel.Size = UDim2.fromOffset(110, 23)
pointsLabel.Font = Enum.Font.GothamMedium
pointsLabel.Text = "0 SKILL POINTS"
pointsLabel.TextColor3 = Color3.fromRGB(151, 210, 255)
pointsLabel.TextSize = 10
pointsLabel.TextXAlignment = Enum.TextXAlignment.Right
pointsLabel.Parent = menu

local closeButton = Instance.new("TextButton")
closeButton.AnchorPoint = Vector2.new(1, 0)
closeButton.Position = UDim2.new(1, -8, 0, 6)
closeButton.Size = UDim2.fromOffset(27, 25)
closeButton.BackgroundColor3 = Color3.fromRGB(55, 65, 84)
closeButton.BorderSizePixel = 0
closeButton.Font = Enum.Font.GothamBold
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(245, 248, 255)
closeButton.TextSize = 11
closeButton.Parent = menu
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 6)
closeCorner.Parent = closeButton

local scroll = Instance.new("ScrollingFrame")
scroll.Name = "SkillList"
scroll.Position = UDim2.fromOffset(8, 38)
scroll.Size = UDim2.new(1, -16, 1, -46)
scroll.BackgroundTransparency = 1
scroll.BorderSizePixel = 0
scroll.ScrollBarThickness = 4
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = menu

local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scroll

listLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
	scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 8)
end)

local buttons: {TextButton} = {}
local slotSkills: {[number]: string} = {}
local slotEnergyCosts: {[number]: number} = {}
local energy = 100
local latestState: any = nil
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

local function makeButton(parent: Instance, text: string, size: UDim2): TextButton
	local button = Instance.new("TextButton")
	button.Size = size
	button.BackgroundColor3 = Color3.fromRGB(52, 72, 103)
	button.BorderSizePixel = 0
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.Text = text
	button.TextColor3 = Color3.fromRGB(240, 245, 255)
	button.TextSize = 10
	button.TextWrapped = true
	button.Parent = parent
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 7)
	corner.Parent = button
	return button
end

local function createSlot(slot: number)
	local button = makeButton(hotbar, tostring(slot) .. "\nEMPTY", UDim2.new(1 / 3, -7, 1, 0))
	button.Name = "SkillSlot" .. tostring(slot)
	button.LayoutOrder = slot
	button.TextSize = 11
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

local function clearSkillRows()
	for _, child in ipairs(scroll:GetChildren()) do
		if child:IsA("Frame") and child.Name == "SkillRow" then
			child:Destroy()
		end
	end
end

local function renderSkillMenu(state: any)
	if typeof(state) ~= "table" then
		return
	end
	pointsLabel.Text = tostring(state.SkillPoints or 0) .. " SKILL POINTS"
	clearSkillRows()

	local level = tonumber(player:GetAttribute("Level")) or 1
	local equipped = state.EquippedSkills or {}
	local skills = state.Skills or {}

	for index, skill in ipairs(skills) do
		local row = Instance.new("Frame")
		row.Name = "SkillRow"
		row.LayoutOrder = index
		row.Size = UDim2.new(1, -6, 0, 58)
		row.BackgroundColor3 = Color3.fromRGB(29, 38, 56)
		row.BorderSizePixel = 0
		row.Parent = scroll
		local rowCorner = Instance.new("UICorner")
		rowCorner.CornerRadius = UDim.new(0, 8)
		rowCorner.Parent = row

		local nameLabel = Instance.new("TextLabel")
		nameLabel.BackgroundTransparency = 1
		nameLabel.Position = UDim2.fromOffset(9, 5)
		nameLabel.Size = UDim2.new(0.40, 0, 1, -10)
		nameLabel.Font = Enum.Font.GothamBold
		nameLabel.Text = skill.Name .. "\nLVL " .. tostring(skill.RequiredLevel) .. "  •  " .. tostring(skill.PointCost) .. " SP"
		nameLabel.TextColor3 = Color3.fromRGB(229, 237, 252)
		nameLabel.TextSize = 10
		nameLabel.TextWrapped = true
		nameLabel.TextXAlignment = Enum.TextXAlignment.Left
		nameLabel.Parent = row

		if not skill.Unlocked then
			local canUnlock = level >= skill.RequiredLevel and (state.SkillPoints or 0) >= skill.PointCost
			local unlockButton = makeButton(row, "UNLOCK", UDim2.new(0.46, 0, 0, 34))
			unlockButton.AnchorPoint = Vector2.new(1, 0.5)
			unlockButton.Position = UDim2.new(1, -8, 0.5, 0)
			unlockButton.BackgroundColor3 = if canUnlock
				then Color3.fromRGB(39, 112, 94)
				else Color3.fromRGB(66, 69, 81)
			unlockButton.Active = canUnlock
			unlockButton.AutoButtonColor = canUnlock
			if not canUnlock then
				unlockButton.Text = if level < skill.RequiredLevel
					then "REQUIRES LVL " .. tostring(skill.RequiredLevel)
					else "NEED MORE SP"
			end
			unlockButton.Activated:Connect(function()
				if canUnlock then
					unlockRequest:FireServer(skill.Id)
				end
			end)
		else
			local alreadyEquipped = table.find(equipped, skill.Id)
			for slot = 1, 3 do
				local slotButton = makeButton(row, "S" .. tostring(slot), UDim2.fromOffset(38, 34))
				slotButton.AnchorPoint = Vector2.new(1, 0.5)
				slotButton.Position = UDim2.new(1, -8 - ((3 - slot) * 43), 0.5, 0)
				local slotIsCurrent = alreadyEquipped == slot
				local canFillSlot = slot <= #equipped + 1
				if slotIsCurrent then
					slotButton.Text = "✓" .. tostring(slot)
					slotButton.BackgroundColor3 = Color3.fromRGB(39, 112, 94)
					slotButton.Active = false
					slotButton.AutoButtonColor = false
				elseif not canFillSlot then
					slotButton.BackgroundColor3 = Color3.fromRGB(66, 69, 81)
					slotButton.Active = false
					slotButton.AutoButtonColor = false
				else
					slotButton.Activated:Connect(function()
						equipRequest:FireServer(skill.Id, slot)
					end)
				end
			end
		end
	end
end

local function renderState(state: any)
	if typeof(state) ~= "table" then
		return
	end
	latestState = state
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
			slotEnergyCosts[slot] = nil
			button.Text = tostring(slot) .. "\nEMPTY"
			button.BackgroundColor3 = Color3.fromRGB(43, 57, 81)
		end
	end

	renderSkillMenu(state)
end

local function handleActionResult(ok: boolean, resultCode: string, state: any)
	if ok then
		showStatus(if resultCode == "PurchaseComplete" then "Purchase complete" else "Loadout updated")
	else
		local messages: {[string]: string} = {
			AlreadyUnlocked = "That ability is already unlocked",
			InsufficientSkillPoints = "Not enough skill points",
			LevelRequirement = "Your level is too low",
			SkillLocked = "Unlock that ability first",
			AlreadyEquipped = "That ability is already in another slot",
			FillSlotsInOrder = "Fill the previous skill slot first",
		}
		showStatus(messages[resultCode] or resultCode)
	end
	if state then
		renderState(state)
	else
		stateRequest:FireServer()
	end
end

stateResult.OnClientEvent:Connect(renderState)
unlockResult.OnClientEvent:Connect(handleActionResult)
equipResult.OnClientEvent:Connect(handleActionResult)

useResult.OnClientEvent:Connect(function(ok: boolean, resultCode: string, payload: any)
	if ok then
		if payload and payload.HitCount then
			showStatus(string.format("Hit %d target(s) for %d damage", payload.HitCount, payload.TotalDamage))
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

player:GetAttributeChangedSignal("SkillPoints"):Connect(function()
	stateRequest:FireServer()
end)
player:GetAttributeChangedSignal("Level"):Connect(function()
	stateRequest:FireServer()
end)

menuToggle.Activated:Connect(function()
	menu.Visible = not menu.Visible
	if menu.Visible then
		stateRequest:FireServer()
	end
end)
closeButton.Activated:Connect(function()
	menu.Visible = false
end)

local keyToSlot = {
	[Enum.KeyCode.One] = 1,
	[Enum.KeyCode.Two] = 2,
	[Enum.KeyCode.Three] = 3,
}
UserInputService.InputBegan:Connect(function(input, processed)
	if processed or input.UserInputType ~= Enum.UserInputType.Keyboard then
		return
	end
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
