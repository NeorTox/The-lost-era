# Enemy templates and combat setup

The server expects enemy rigs in `ServerStorage/EnemyTemplates`.

For each enemy template:
1. Create a Model under `ServerStorage/EnemyTemplates`.
2. Add a rig with a `Humanoid` and `HumanoidRootPart`.
3. Ensure the model can be moved with `Model:PivotTo()`.
4. Keep rig parts unanchored.
5. Spawn from a server script with `EnemyService.Spawn(templateName, spawnCFrame, level, islandId)`.

The enemy service assigns health, damage, aggro range, attack range, island identity, and rewards. Its first-pass AI uses nearest-player aggro and direct Humanoid:MoveTo pursuit. Pathfinding, leash behavior, animation state machines, spawn budgets, and boss phases remain future improvements.

## Client attack request

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local attackRequest = ReplicatedStorage
    :WaitForChild("TheLostEraRemotes")
    :WaitForChild("AttackRequest")

attackRequest:FireServer(enemyModel)
```

The client does not choose damage. The server checks target identity, same-island state, cooldown, distance, line of sight, and target health.

## Studio tests
- [ ] Create a rig in ServerStorage/EnemyTemplates named `TrainingSlime`.
- [ ] Set the test player's `CurrentIsland` attribute to `SunsetBay`.
- [ ] Spawn a slime from a temporary server test script.
- [ ] Confirm it pursues only players assigned to the same island.
- [ ] Attack within range and confirm server-computed damage.
- [ ] Attack through a wall, across islands, and beyond range; each must be rejected.
- [ ] Defeat the enemy and confirm XP, coins, and quest objective progress.
