# Enemy templates, spawn points, and combat setup

## Enemy templates

Create `ServerStorage/EnemyTemplates`. Add one Model per enemy type. Every model needs:
- A `Humanoid`
- A `HumanoidRootPart`
- Unanchored rig parts suitable for Humanoid movement

The model must be movable with `Model:PivotTo()`. Name the model to match the spawn marker's `TemplateName` attribute.

## Spawn points

Create `Workspace/EnemySpawnPoints`. Add anchored, invisible BaseParts as spawn markers. Set these Attributes on each marker:

| Attribute | Type | Example |
|---|---|---|
| TemplateName | String | `TrainingSlime` |
| Level | Number | `5` |
| IslandId | String | `SunsetBay` |
| RespawnSeconds | Number | `12` |

The server spawn controller reads these markers and spawns/re-spawns the configured enemy. A marker with missing attributes is ignored with a warning.

## Combat request

The client may request an attack by sending the enemy Model to the remote:

```lua
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local attackRequest = ReplicatedStorage
    :WaitForChild("TheLostEraRemotes")
    :WaitForChild("AttackRequest")

attackRequest:FireServer(enemyModel)
```

The client does not choose damage. The server validates enemy identity, same-island state, cooldown, distance, line of sight, and target health, then calculates damage.

## Current AI behavior

The first-pass enemy AI selects the nearest living player assigned to the same island, pursues with `Humanoid:MoveTo()`, and attacks within its configured range. This is deliberately a simple baseline. Obstacle-aware PathfindingService navigation, leash/return behavior, animation state machines, spawn budgets, elite variants, and boss phases are later improvements.

## Studio tests
- [ ] Add a rig named `TrainingSlime` to `ServerStorage/EnemyTemplates`.
- [ ] Add a spawn marker to `Workspace/EnemySpawnPoints` with the attributes above.
- [ ] Set the test player's `CurrentIsland` attribute to `SunsetBay` (profile loading sets this from saved data).
- [ ] Confirm the enemy spawns and pursues only players on the same island.
- [ ] Attack within range and confirm server-computed damage.
- [ ] Attack through a wall, across islands, and beyond range; each must be rejected.
- [ ] Defeat the enemy and confirm XP, coins, and starter quest objective progress.
- [ ] Confirm the enemy respawns after it is defeated and cleaned up.
