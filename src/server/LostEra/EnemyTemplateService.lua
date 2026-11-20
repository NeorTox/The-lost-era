--!strict
-- Creates simple fallback R6 blockout rigs for catalog enemies when an
-- art-authored template with the same name is not already present.
-- Replace these fallback models with polished rigs without changing their IDs.

local ServerStorage = game:GetService("ServerStorage")
local EnemyCatalog = require(script.Parent.EnemyCatalog)

type EnemyDefinition = EnemyCatalog.EnemyDefinition

local EnemyTemplateService = {}
local initialized = false

local function createPart(
	parent: Instance,
	name: string,
	size: Vector3,
	cframe: CFrame,
	color: Color3,
	transparency: number?
): Part
	local part = Instance.new("Part")
	part.Name = name
	part.Size = size
	part.CFrame = cframe
	part.Color = color
	part.Material = Enum.Material.SmoothPlastic
	part.Transparency = transparency or 0
	part.Anchored = false
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = true
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.Parent = parent
	return part
end

local function addMotor(
	name: string,
	part0: BasePart,
	part1: BasePart,
	c0: CFrame,
	c1: CFrame
)
	local motor = Instance.new("Motor6D")
	motor.Name = name
	motor.Part0 = part0
	motor.Part1 = part1
	motor.C0 = c0
	motor.C1 = c1
	motor.Parent = part0
end

local function createGeneratedTemplate(folder: Folder, definition: EnemyDefinition)
	local model = Instance.new("Model")
	model.Name = definition.TemplateName
	model:SetAttribute("EnemyTemplateId", definition.TemplateName)
	model:SetAttribute("IsGeneratedBlockoutTemplate", true)

	local root = createPart(
		model,
		"HumanoidRootPart",
		Vector3.new(2, 2, 1),
		CFrame.new(0, 3, 0),
		definition.BodyColor,
		1
	)
	root.Massless = true

	local torso = createPart(
		model,
		"Torso",
		Vector3.new(2, 2, 1),
		CFrame.new(0, 3, 0),
		definition.BodyColor
	)
	torso.CanCollide = true

	local head = createPart(
		model,
		"Head",
		Vector3.new(2, 1, 1),
		CFrame.new(0, 4.5, 0),
		definition.AccentColor
	)
	if definition.TemplateName == "TrainingSlime" or definition.TemplateName == "TideCrab" then
		head.Shape = Enum.PartType.Ball
	end

	local leftArm = createPart(
		model,
		"Left Arm",
		Vector3.new(1, 2, 1),
		CFrame.new(-1.5, 3, 0),
		definition.BodyColor
	)
	local rightArm = createPart(
		model,
		"Right Arm",
		Vector3.new(1, 2, 1),
		CFrame.new(1.5, 3, 0),
		definition.BodyColor
	)
	local leftLeg = createPart(
		model,
		"Left Leg",
		Vector3.new(1, 2, 1),
		CFrame.new(-0.5, 1, 0),
		definition.BodyColor
	)
	local rightLeg = createPart(
		model,
		"Right Leg",
		Vector3.new(1, 2, 1),
		CFrame.new(0.5, 1, 0),
		definition.BodyColor
	)
	leftLeg.CanCollide = true
	rightLeg.CanCollide = true

	addMotor("RootJoint", root, torso, CFrame.new(), CFrame.new())
	addMotor("Neck", torso, head, CFrame.new(0, 1, 0), CFrame.new(0, -0.5, 0))
	addMotor("Left Shoulder", torso, leftArm, CFrame.new(-1, 0.5, 0), CFrame.new(0.5, 0.5, 0))
	addMotor("Right Shoulder", torso, rightArm, CFrame.new(1, 0.5, 0), CFrame.new(-0.5, 0.5, 0))
	addMotor("Left Hip", torso, leftLeg, CFrame.new(-1, -1, 0), CFrame.new(-0.5, 1, 0))
	addMotor("Right Hip", torso, rightLeg, CFrame.new(1, -1, 0), CFrame.new(0.5, 1, 0))

	local accentPlate = createPart(
		model,
		"ChestAccent",
		Vector3.new(1.15, 0.24, 0.12),
		CFrame.new(0, 3.25, -0.56),
		definition.AccentColor
	)
	local accentWeld = Instance.new("WeldConstraint")
	accentWeld.Part0 = torso
	accentWeld.Part1 = accentPlate
	accentWeld.Parent = accentPlate

	if definition.TemplateName == "TideCrab" then
		for _, side in ipairs({ -1, 1 }) do
			local claw = createPart(
				model,
				if side < 0 then "LeftClaw" else "RightClaw",
				Vector3.new(0.8, 0.8, 0.8),
				CFrame.new(side * 1.75, 2.65, -0.1),
				definition.AccentColor
			)
			claw.Shape = Enum.PartType.Ball
			local clawWeld = Instance.new("WeldConstraint")
			clawWeld.Part0 = torso
			clawWeld.Part1 = claw
			clawWeld.Parent = claw
		end
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.DisplayName = definition.DisplayName
	humanoid.MaxHealth = definition.MaxHealth
	humanoid.Health = definition.MaxHealth
	humanoid.WalkSpeed = definition.WalkSpeed
	humanoid.BreakJointsOnDeath = false
	humanoid.RequiresNeck = true
	humanoid.Parent = model

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "EnemyNameplate"
	billboard.Adornee = head
	local isBoss = definition.IsBoss == true
	billboard.Size = if isBoss then UDim2.fromOffset(200, 68) else UDim2.fromOffset(180, 48)
	billboard.StudsOffset = Vector3.new(0, 2.1, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 110
	billboard.Parent = head

	local label = Instance.new("TextLabel")
	label.Name = "Name"
	label.Position = UDim2.fromOffset(0, 0)
	label.Size = UDim2.new(1, 0, 0, 23)
	label.BackgroundColor3 = Color3.fromRGB(18, 25, 36)
	label.BackgroundTransparency = 0.12
	label.BorderSizePixel = 0
	label.Font = Enum.Font.GothamBold
	label.Text = definition.DisplayName
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextScaled = true
	label.Parent = billboard

	local labelCorner = Instance.new("UICorner")
	labelCorner.CornerRadius = UDim.new(0, 7)
	labelCorner.Parent = label

	if isBoss then
		local phaseLabel = Instance.new("TextLabel")
		phaseLabel.Name = "BossPhase"
		phaseLabel.Position = UDim2.fromOffset(0, 24)
		phaseLabel.Size = UDim2.new(1, 0, 0, 18)
		phaseLabel.BackgroundTransparency = 1
		phaseLabel.BorderSizePixel = 0
		phaseLabel.Font = Enum.Font.GothamMedium
		phaseLabel.Text = "PHASE I  •  AWAKENING"
		phaseLabel.TextColor3 = Color3.fromRGB(135, 228, 232)
		phaseLabel.TextScaled = true
		phaseLabel.Parent = billboard
	end

	local healthTrack = Instance.new("Frame")
	healthTrack.Name = "HealthTrack"
	healthTrack.Position = UDim2.fromOffset(10, if isBoss then 48 else 30)
	healthTrack.Size = UDim2.new(1, -20, 0, if isBoss then 12 else 10)
	healthTrack.BackgroundColor3 = Color3.fromRGB(48, 54, 64)
	healthTrack.BorderSizePixel = 0
	healthTrack.ClipsDescendants = true
	healthTrack.Parent = billboard

	local trackCorner = Instance.new("UICorner")
	trackCorner.CornerRadius = UDim.new(1, 0)
	trackCorner.Parent = healthTrack

	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(1, 1)
	fill.BackgroundColor3 = Color3.fromRGB(78, 205, 112)
	fill.BorderSizePixel = 0
	fill.Parent = healthTrack

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(1, 0)
	fillCorner.Parent = fill

	model.PrimaryPart = root
	model.Parent = folder
end

local function isUsableTemplate(instance: Instance): boolean
	if not instance:IsA("Model") then
		return false
	end
	local humanoid = instance:FindFirstChildOfClass("Humanoid")
	local root = instance:FindFirstChild("HumanoidRootPart")
	return humanoid ~= nil and root ~= nil and root:IsA("BasePart")
end

function EnemyTemplateService.Init()
	if initialized then return end
	initialized = true

	local existing = ServerStorage:FindFirstChild("EnemyTemplates")
	local folder: Folder
	if existing and existing:IsA("Folder") then
		folder = existing
	else
		if existing then existing:Destroy() end
		folder = Instance.new("Folder")
		folder.Name = "EnemyTemplates"
		folder.Parent = ServerStorage
	end

	for _, definition in ipairs(EnemyCatalog.GetAll()) do
		local template = folder:FindFirstChild(definition.TemplateName)
		if not template then
			createGeneratedTemplate(folder, definition)
		elseif not isUsableTemplate(template) then
			warn("[TheLostEra] Enemy template exists but is missing a Model, Humanoid, or HumanoidRootPart:", definition.TemplateName)
		end
	end

	print("[TheLostEra] Enemy fallback templates ready.")
end

return EnemyTemplateService
