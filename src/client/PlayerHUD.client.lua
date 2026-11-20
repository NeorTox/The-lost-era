--!strict
-- Compact player HUD for health, energy, stamina, XP, level, island and coins.

local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local oldGui = playerGui:FindFirstChild("LostEraPlayerHUD")
if oldGui then
	oldGui:Destroy()
end

local gui = Instance.new("ScreenGui")
gui.Name = "LostEraPlayerHUD"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = false
gui.DisplayOrder = 10
gui.Parent = playerGui

local panel = Instance.new("Frame")
panel.Name = "StatusPanel"
panel.Position = UDim2.fromOffset(12, 12)
panel.Size = UDim2.fromOffset(306, 184)
panel.BackgroundColor3 = Color3.fromRGB(15, 20, 31)
panel.BackgroundTransparency = 0.12
panel.BorderSizePixel = 0
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 12)
panelCorner.Parent = panel

local panelStroke = Instance.new("UIStroke")
panelStroke.Color = Color3.fromRGB(79, 101, 137)
panelStroke.Transparency = 0.42
panelStroke.Thickness = 1
panelStroke.Parent = panel

local panelPadding = Instance.new("UIPadding")
panelPadding.PaddingLeft = UDim.new(0, 10)
panelPadding.PaddingRight = UDim.new(0, 10)
panelPadding.PaddingTop = UDim.new(0, 8)
panelPadding.PaddingBottom = UDim.new(0, 8)
panelPadding.Parent = panel

local header = Instance.new("Frame")
header.Name = "Header"
header.Size = UDim2.new(1, 0, 0, 27)
header.BackgroundTransparency = 1
header.Parent = panel

local levelLabel = Instance.new("TextLabel")
levelLabel.Name = "Level"
levelLabel.Position = UDim2.fromOffset(0, 0)
levelLabel.Size = UDim2.fromOffset(76, 24)
levelLabel.BackgroundTransparency = 1
levelLabel.Font = Enum.Font.GothamBold
levelLabel.Text = "LVL 1"
levelLabel.TextColor3 = Color3.fromRGB(240, 245, 255)
levelLabel.TextSize = 15
levelLabel.TextXAlignment = Enum.TextXAlignment.Left
levelLabel.Parent = header

local islandLabel = Instance.new("TextLabel")
islandLabel.Name = "Island"
islandLabel.Position = UDim2.fromOffset(77, 1)
islandLabel.Size = UDim2.new(1, -164, 0, 22)
islandLabel.BackgroundTransparency = 1
islandLabel.Font = Enum.Font.GothamMedium
islandLabel.Text = "SUNSET BAY"
islandLabel.TextColor3 = Color3.fromRGB(159, 183, 220)
islandLabel.TextSize = 10
islandLabel.TextTruncate = Enum.TextTruncate.AtEnd
islandLabel.TextXAlignment = Enum.TextXAlignment.Left
islandLabel.Parent = header

local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "Coins"
coinLabel.AnchorPoint = Vector2.new(1, 0)
coinLabel.Position = UDim2.new(1, 0, 0, 1)
coinLabel.Size = UDim2.fromOffset(84, 22)
coinLabel.BackgroundTransparency = 1
coinLabel.Font = Enum.Font.GothamBold
coinLabel.Text = "0 COINS"
coinLabel.TextColor3 = Color3.fromRGB(255, 213, 117)
coinLabel.TextSize = 10
coinLabel.TextXAlignment = Enum.TextXAlignment.Right
coinLabel.Parent = header

local function makeBar(name: string, title: string, y: number, fillColor: Color3)
	local label = Instance.new("TextLabel")
	label.Name = name .. "Label"
	label.Position = UDim2.fromOffset(0, y)
	label.Size = UDim2.fromOffset(58, 20)
	label.BackgroundTransparency = 1
	label.Font = Enum.Font.GothamBold
	label.Text = title
	label.TextColor3 = Color3.fromRGB(208, 218, 236)
	label.TextSize = 10
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = panel

	local track = Instance.new("Frame")
	track.Name = name .. "Track"
	track.Position = UDim2.fromOffset(58, y + 4)
	track.Size = UDim2.new(1, -139, 0, 11)
	track.BackgroundColor3 = Color3.fromRGB(43, 51, 68)
	track.BorderSizePixel = 0
	track.ClipsDescendants = true
	track.Parent = panel

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = track

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = fillColor
	fill.BorderSizePixel = 0
	fill.Parent = track

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	local value = Instance.new("TextLabel")
	value.Name = name .. "Value"
	value.AnchorPoint = Vector2.new(1, 0)
	value.Position = UDim2.new(1, 0, 0, y)
	value.Size = UDim2.fromOffset(76, 20)
	value.BackgroundTransparency = 1
	value.Font = Enum.Font.GothamMedium
	value.Text = "100 / 100"
	value.TextColor3 = Color3.fromRGB(219, 227, 241)
	value.TextSize = 9
	value.TextXAlignment = Enum.TextXAlignment.Right
	value.Parent = panel

	return fill, value
end

local healthFill, healthValue = makeBar("Health", "HEALTH", 36, Color3.fromRGB(225, 83, 92))
local energyFill, energyValue = makeBar("Energy", "ENERGY", 64, Color3.fromRGB(82, 159, 237))
local staminaFill, staminaValue = makeBar("Stamina", "STAMINA", 92, Color3.fromRGB(75, 194, 139))

local xpLabel = Instance.new("TextLabel")
xpLabel.Name = "XPLabel"
xpLabel.Position = UDim2.fromOffset(0, 122)
xpLabel.Size = UDim2.fromOffset(24, 18)
xpLabel.BackgroundTransparency = 1
xpLabel.Font = Enum.Font.GothamBold
xpLabel.Text = "XP"
xpLabel.TextColor3 = Color3.fromRGB(208, 218, 236)
xpLabel.TextSize = 10
xpLabel.TextXAlignment = Enum.TextXAlignment.Left
xpLabel.Parent = panel

local xpTrack = Instance.new("Frame")
xpTrack.Name = "XPTrack"
xpTrack.Position = UDim2.fromOffset(25, 126)
xpTrack.Size = UDim2.new(1, -25, 0, 10)
xpTrack.BackgroundColor3 = Color3.fromRGB(43, 51, 68)
xpTrack.BorderSizePixel = 0
xpTrack.ClipsDescendants = true
xpTrack.Parent = panel

local xpTrackCorner = Instance.new("UICorner")
xpTrackCorner.CornerRadius = UDim.new(1, 0)
xpTrackCorner.Parent = xpTrack

local xpFill = Instance.new("Frame")
xpFill.Name = "Fill"
xpFill.Size = UDim2.fromScale(0, 1)
xpFill.BackgroundColor3 = Color3.fromRGB(169, 119, 245)
xpFill.BorderSizePixel = 0
xpFill.Parent = xpTrack

local xpFillCorner = Instance.new("UICorner")
xpFillCorner.CornerRadius = UDim.new(1, 0)
xpFillCorner.Parent = xpFill

local xpValue = Instance.new("TextLabel")
xpValue.Name = "XPValue"
xpValue.Position = UDim2.fromOffset(0, 141)
xpValue.Size = UDim2.new(1, 0, 0, 15)
xpValue.BackgroundTransparency = 1
xpValue.Font = Enum.Font.Gotham
xpValue.Text = "0 / 100 XP"
xpValue.TextColor3 = Color3.fromRGB(163, 174, 196)
xpValue.TextSize = 9
xpValue.TextXAlignment = Enum.TextXAlignment.Right
xpValue.Parent = panel

local function safeNumber(value: any, fallback: number): number
	local number = tonumber(value)
	if not number or number ~= number or number == math.huge or number == -math.huge then
		return fallback
	end
	return math.max(0, number)
end

local function updateBar(fill: Frame, valueLabel: TextLabel, current: number, maximum: number)
	local maxValue = math.max(1, maximum)
	local currentValue = math.clamp(current, 0, maxValue)
	fill.Size = UDim2.fromScale(currentValue / maxValue, 1)
	valueLabel.Text = string.format("%d / %d", math.floor(currentValue), math.floor(maxValue))
end

local function updateProgress()
	local level = math.max(1, math.floor(safeNumber(player:GetAttribute("Level"), 1)))
	local xp = safeNumber(player:GetAttribute("XP"), 0)
	local xpNeeded = safeNumber(player:GetAttribute("XPToNextLevel"), 0)
	local coins = safeNumber(player:GetAttribute("Coins"), 0)

	levelLabel.Text = "LVL " .. tostring(level)
	coinLabel.Text = string.format("%s COINS", tostring(math.floor(coins)))
	islandLabel.Text = string.upper(tostring(player:GetAttribute("CurrentIsland") or "CENTRAL AREA"))

	if xpNeeded > 0 then
		local safeXP = math.min(xp, xpNeeded)
		xpFill.Size = UDim2.fromScale(safeXP / xpNeeded, 1)
		xpValue.Text = string.format("%d / %d XP", math.floor(safeXP), math.floor(xpNeeded))
	else
		xpFill.Size = UDim2.fromScale(1, 1)
		xpValue.Text = "MAX LEVEL"
	end
end

local function updateEnergy()
	updateBar(
		energyFill,
		energyValue,
		safeNumber(player:GetAttribute("Energy"), 0),
		safeNumber(player:GetAttribute("MaxEnergy"), 100)
	)
end

local function updateStamina()
	updateBar(
		staminaFill,
		staminaValue,
		safeNumber(player:GetAttribute("Stamina"), 0),
		safeNumber(player:GetAttribute("MaxStamina"), 100)
	)
end

local healthConnection: RBXScriptConnection? = nil
local maxHealthConnection: RBXScriptConnection? = nil

local function bindCharacter(character: Model)
	if healthConnection then
		healthConnection:Disconnect()
		healthConnection = nil
	end
	if maxHealthConnection then
		maxHealthConnection:Disconnect()
		maxHealthConnection = nil
	end

	local humanoid = character:WaitForChild("Humanoid", 10)
	if not humanoid or not humanoid:IsA("Humanoid") or player.Character ~= character then
		return
	end

	local function updateHealth()
		updateBar(healthFill, healthValue, humanoid.Health, humanoid.MaxHealth)
	end
	healthConnection = humanoid.HealthChanged:Connect(updateHealth)
	maxHealthConnection = humanoid:GetPropertyChangedSignal("MaxHealth"):Connect(updateHealth)
	updateHealth()
end

local attributes = {
	"Level",
	"XP",
	"XPToNextLevel",
	"Coins",
	"CurrentIsland",
}
for _, attribute in ipairs(attributes) do
	player:GetAttributeChangedSignal(attribute):Connect(updateProgress)
end

player:GetAttributeChangedSignal("Energy"):Connect(updateEnergy)
player:GetAttributeChangedSignal("MaxEnergy"):Connect(updateEnergy)
player:GetAttributeChangedSignal("Stamina"):Connect(updateStamina)
player:GetAttributeChangedSignal("MaxStamina"):Connect(updateStamina)

player.CharacterAdded:Connect(bindCharacter)
if player.Character then
	task.spawn(bindCharacter, player.Character)
else
	updateBar(healthFill, healthValue, 0, 100)
end

updateProgress()
updateEnergy()
updateStamina()
