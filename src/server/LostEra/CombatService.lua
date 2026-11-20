--!strict
-- Client requests only identify a target. The server validates and computes damage.

local Workspace = game:GetService("Workspace")
local EnemyService = require(script.Parent.EnemyService)

local CombatService = {}
local lastAttackAt: {[number]: number} = {}

local ATTACK_COOLDOWN = 0.65
local ATTACK_RANGE = 12
local BASE_DAMAGE = 12
local DAMAGE_PER_LEVEL = 1.6

local function getLivingCharacter(player: Player)
	local character = player.Character
	if not character then return nil, nil, nil end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local root = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
		return nil, nil, nil
	end
	return character, humanoid, root
end

local function hasLineOfSight(character: Model, origin: Vector3, target: Model, destination: Vector3): boolean
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	params.FilterDescendantsInstances = { character, target }
	params.IgnoreWater = true
	return Workspace:Raycast(origin, destination - origin, params) == nil
end

function CombatService.TryAttack(player: Player, targetInstance: Instance): (boolean, string?)
	if not targetInstance:IsA("Model") or not EnemyService.IsEnemyModel(targetInstance)
		or not targetInstance:IsDescendantOf(Workspace) then
		return false, "InvalidTarget"
	end

	local now = os.clock()
	if now - (lastAttackAt[player.UserId] or 0) < ATTACK_COOLDOWN then
		return false, "Cooldown"
	end

	local character, _playerHumanoid, playerRoot = getLivingCharacter(player)
	local enemyHumanoid = targetInstance:FindFirstChildOfClass("Humanoid")
	local enemyRoot = targetInstance:FindFirstChild("HumanoidRootPart")
	if not character or not playerRoot or not enemyHumanoid or enemyHumanoid.Health <= 0
		or not enemyRoot or not enemyRoot:IsA("BasePart") then
		return false, "TargetUnavailable"
	end

	if player:GetAttribute("CurrentIsland") ~= targetInstance:GetAttribute("IslandId") then
		return false, "WrongIsland"
	end
	if (enemyRoot.Position - playerRoot.Position).Magnitude > ATTACK_RANGE then
		return false, "OutOfRange"
	end
	if not hasLineOfSight(character, playerRoot.Position, targetInstance, enemyRoot.Position) then
		return false, "Blocked"
	end

	lastAttackAt[player.UserId] = now
	local level = math.max(1, math.floor(player:GetAttribute("Level") or 1))
	local damage = math.floor(BASE_DAMAGE + level * DAMAGE_PER_LEVEL)
	targetInstance:SetAttribute("LastHitUserId", player.UserId)
	enemyHumanoid:TakeDamage(damage)
	return true, nil
end

function CombatService.ReleasePlayer(player: Player)
	lastAttackAt[player.UserId] = nil
end

return CombatService
