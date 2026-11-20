--!strict
-- Responsive boss health HUD. Boss state is replicated through model attributes
-- and Humanoid health; all combat and rewards remain server-authoritative.

local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("LostEraBossHUD")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "LostEraBossHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 11
gui.Enabled = true
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "BossPanel"
panel.AnchorPoint = Vector2.new(0.5, 0)
panel.Position = UDim2.new(0.5, 0, 0, 12)
panel.Size = UDim2.new(0.9, 0, 0, 74)
panel.BackgroundColor3 = Color3.fromRGB(15, 20, 31)
panel.BackgroundTransparency = 0.1
panel.BorderSizePixel = 0
panel.Visible = false
panel.Parent = gui

local constraint = Instance.new("UISizeConstraint")
constraint.MinSize = Vector2.new(260, 74)
constraint.MaxSize = Vector2.new(500, 74)
constraint.Parent = panel

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 12)
corner.Parent = panel

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 167, 181)
stroke.Transparency = 0.22
stroke.Thickness = 1.2
stroke.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "BossName"
title.Position = UDim2.fromOffset(12, 7)
title.Size = UDim2.new(0.58, -12, 0, 22)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBold
title.Text = "BOSS"
title.TextColor3 = Color3.fromRGB(242, 249, 255)
title.TextSize = 14
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextTruncate = Enum.TextTruncate.AtEnd
title.Parent = panel

local phase = Instance.new("TextLabel")
phase.Name = "BossPhase"
phase.Position = UDim2.new(0.58, 0, 0, 8)
phase.Size = UDim2.new(0.42, -12, 0, 20)
phase.BackgroundTransparency = 1
phase.Font = Enum.Font.GothamBold
phase.Text = "ENCOUNTER"
phase.TextColor3 = Color3.fromRGB(125, 220, 225)
phase.TextSize = 10
phase.TextXAlignment = Enum.TextXAlignment.Right
phase.TextTruncate = Enum.TextTruncate.AtEnd
phase.Parent = panel

local track = Instance.new("Frame")
track.Name = "HealthTrack"
track.Position = UDim2.fromOffset(12, 38)
track.Size = UDim2.new(1, -24, 0, 14)
track.BackgroundColor3 = Color3.fromRGB(48, 54, 66)
track.BorderSizePixel = 0
track.ClipsDescendants = true
track.Parent = panel

local trackCorner = Instance.new("UICorner")
trackCorner.CornerRadius = UDim.new(1, 0)
trackCorner.Parent = track

local fill = Instance.new("Frame")
fill.Name = "HealthFill"
fill.Size = UDim2.fromScale(1, 1)
fill.BackgroundColor3 = Color3.fromRGB(64, 190, 170)
fill.BorderSizePixel = 0
fill.Parent = track

local fillCorner = Instance.new("UICorner")
fillCorner.CornerRadius = UDim.new(1, 0)
fillCorner.Parent = fill

local healthText = Instance.new("TextLabel")
healthText.Name = "HealthValue"
healthText.AnchorPoint = Vector2.new(1, 0)
healthText.Position = UDim2.new(1, -13, 0, 55)
healthText.Size = UDim2.fromOffset(110, 13)
healthText.BackgroundTransparency = 1
healthText.Font = Enum.Font.GothamMedium
healthText.Text = ""
healthText.TextColor3 = Color3.fromRGB(187, 202, 224)
healthText.TextSize = 9
healthText.TextXAlignment = Enum.TextXAlignment.Right
healthText.Parent = panel

local activeBoss: Model? = nil
local activeHumanoid: Humanoid? = nil
local activeConnections: {RBXScriptConnection} = {}
local observedBosses: {[Model]: {RBXScriptConnection}} = {}

local function disconnectActive()
	for _, connection in ipairs(activeConnections) do
		connection:Disconnect()
	end
	table.clear(activeConnections)
	activeBoss = nil
	activeHumanoid = nil
	panel.Visible = false
end

local function updatePanel()
	local boss = activeBoss
	local humanoid = activeHumanoid
	if not boss or not humanoid or not boss:IsDescendantOf(Workspace) then
		panel.Visible = false
		return
	end

	local bossId = boss:GetAttribute("BossId")
	local bossLevel = tonumber(boss:GetAttribute("EnemyLevel")) or 1
	local displayName = if bossId == "TideWarden" then "TIDE WARDEN" else string.upper(tostring(bossId or "BOSS"))
	title.Text = displayName .. "  •  LVL " .. tostring(bossLevel)

	local phaseName = boss:GetAttribute("BossPhaseName")
	phase.Text = string.upper(if typeof(phaseName) == "string" then phaseName else "ENCOUNTER")

	local maximum = math.max(1, humanoid.MaxHealth)
	local current = math.clamp(humanoid.Health, 0, maximum)
	local ratio = current / maximum
	fill.Size = UDim2.fromScale(ratio, 1)
	fill.BackgroundColor3 = if ratio > 0.5
		then Color3.fromRGB(64, 190, 170)
		elseif ratio > 0.25 then Color3.fromRGB(232, 170, 74)
		else Color3.fromRGB(224, 83, 82)
	healthText.Text = string.format("%d / %d HP", math.floor(current), math.floor(maximum))
	panel.Visible = true
end

local function selectBoss(model: Model)
	if activeBoss == model then
		updatePanel()
		return
	end

	disconnectActive()
	activeBoss = model
	activeHumanoid = model:FindFirstChildOfClass("Humanoid")

	if activeHumanoid then
		table.insert(activeConnections, activeHumanoid.HealthChanged:Connect(updatePanel))
	end
	table.insert(activeConnections, model:GetAttributeChangedSignal("BossPhaseName"):Connect(updatePanel))
	table.insert(activeConnections, model:GetAttributeChangedSignal("EnemyLevel"):Connect(updatePanel))
	table.insert(activeConnections, model.AncestryChanged:Connect(function(_, parent)
		if parent == nil and activeBoss == model then
			disconnectActive()
		end
	end))
	updatePanel()
end

local function refreshBoss(model: Model)
	local bossId = model:GetAttribute("BossId")
	local bossIsland = model:GetAttribute("BossIslandId")
	local currentIsland = player:GetAttribute("CurrentIsland")
	if model:IsDescendantOf(Workspace)
		and typeof(bossId) == "string"
		and typeof(bossIsland) == "string"
		and bossIsland == currentIsland then
		selectBoss(model)
	elseif activeBoss == model then
		disconnectActive()
	end
end

local function observeBoss(model: Instance)
	if not model:IsA("Model") or model:GetAttribute("IsBoss") ~= true then
		return
	end
	if observedBosses[model] then return end

	local connections: {RBXScriptConnection} = {}
	observedBosses[model] = connections
	table.insert(connections, model:GetAttributeChangedSignal("BossId"):Connect(function()
		refreshBoss(model)
	end))
	table.insert(connections, model:GetAttributeChangedSignal("BossIslandId"):Connect(function()
		refreshBoss(model)
	end))
	table.insert(connections, model.Destroying:Connect(function()
		if activeBoss == model then
			disconnectActive()
		end
		for _, connection in ipairs(connections) do
			connection:Disconnect()
		end
		observedBosses[model] = nil
	end))
	refreshBoss(model)
end

for _, child in ipairs(Workspace:GetChildren()) do
	observeBoss(child)
end

Workspace.ChildAdded:Connect(observeBoss)
player:GetAttributeChangedSignal("CurrentIsland"):Connect(function()
	for model in pairs(observedBosses) do
		refreshBoss(model)
	end
end)
