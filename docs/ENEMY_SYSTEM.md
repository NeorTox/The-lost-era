# THE LOST ERA — Sunset Bay Enemy System

## Scope

The first playable enemy slice is intentionally limited to **Sunset Bay**. Three enemy spawn markers are enabled there. The other ten islands keep their markers disabled until their own enemy templates and balancing have been authored.

## Starter roster

| Enemy | Spawn level | Health | Damage | Walk speed | Aggro range | Attack cooldown | Loot |
|---|---:|---:|---:|---:|---:|---:|---|
| Training Slime | 1 | 90 | 6 | 10 | 38 | 1.9 s | Slime Gel, 65% chance, 1–2 |
| Driftwood Bandit | 12 | 145 | 10 | 14 | 48 | 1.45 s | Driftwood Scrap, 40% chance, 1–2 |
| Tide Crab | 24 | 210 | 16 | 11 | 40 | 1.9 s | Tide Shell, 35% chance, 1 |

Stats, names, colors and drops live in `src/server/LostEra/EnemyCatalog.lua`. Enemy XP and coin rewards use the shared `Config.Economy.EnemyRewards` formula unless a server-side spawn explicitly overrides them. The three material IDs are allowlisted by DataService as well as InventoryService so they survive profile sanitization and saving.

## Template contract

- Templates live in `ServerStorage/EnemyTemplates`.
- Each template must be a Model with a Humanoid and a BasePart named `HumanoidRootPart`.
- The template name must exactly match the spawn marker's `TemplateName`.
- Art-authored templates take precedence and are never overwritten by the fallback generator.
- If a catalog template is missing, `EnemyTemplateService` creates a basic R6 blockout rig. These rigs are functional placeholders, not final enemy art or animation assets.

## Runtime behavior

- Enemies only acquire living players whose `CurrentIsland` matches their own `IslandId`.
- Players marked `InSafeZone` are excluded from targeting, and protection is checked again immediately before enemy damage.
- Enemies have a home position and a chase leash; they return to their spawn when a valid target cannot be found.
- Enemy attacks require line of sight to the target; the obstruction check is repeated immediately before applying damage.
- Generated fallback rigs include a visible health bar that changes color as health falls.
- Enemy damage, health, level, XP and coin values are assigned by the server.
- A valid final hit grants the configured XP and coins. A successful loot roll adds the material directly to the killer's inventory.
- Only Training Slime kills advance the "Welcome to Sunset Bay" quest, matching the objective text; Bandit and Crab kills do not count toward it.
- The respawn timer begins after the previous enemy model has been removed, rather than counting down while the enemy is still alive.
- Spawn levels must be whole numbers inside the island's configured normal-enemy band.

## Current boundaries

- This does not implement boss encounters; Phase 10 remains separate.
- The other ten island rosters are not authored or enabled.
- The blockout rigs have no final meshes, custom animations, sound, attack telegraphs or polished effects.
- Loot is awarded directly into inventory; there is not yet a physical loot pickup/drop model.
- Roblox Studio runtime, multiplayer, mobile and balance testing remain required. Source implementation alone is not proof of runtime correctness.

## Roblox Studio verification checklist (not yet run)

1. Start a private test server and confirm one Training Slime, one Driftwood Bandit and one Tide Crab spawn on Sunset Bay.
2. Confirm no enemy spawns in the Central Area or inside the Sunset Bay safe zone.
3. Enter each enemy's aggro range and verify it follows only players on Sunset Bay.
4. Move outside an enemy's chase leash and verify it returns to its own spawn marker.
5. Stand inside the safe-zone bounds and verify enemy attacks do not reduce player health, including when entering the zone during a chase.
6. Defeat each enemy and verify XP, Coins, the Sunset Bay quest objective and inventory material drops.
7. Confirm defeated enemies are removed, then respawn after the configured 18-second delay begins.
8. Disable a spawn marker during a live encounter and verify its enemy is removed without the marker restarting unexpectedly.
9. Test with multiple players, including one inside the safe zone and another fighting outside it.
10. Verify Bandit and Crab kills do not increment the Training Slime quest, while Training Slime kills do.
11. Verify enemy health bars decrease correctly and change color at the configured health thresholds.
12. Place a solid obstacle between an enemy and player; verify the enemy cannot damage through it.
