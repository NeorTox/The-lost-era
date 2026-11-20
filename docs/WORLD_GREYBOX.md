# THE LOST ERA — Generated World Greybox

## What the world builder creates

`WorldBuilderService.Init()` runs at server startup before the portal and enemy-spawn services scan Workspace. It creates a versioned `Workspace/TheLostEraGeneratedWorld` folder containing:

- The Central Area portal hub, central spawn pad and 13 destination portals.
- Eleven main island greyboxes arranged around the hub.
- Echo Battle Arena and Memory Training Island as separate special-area greyboxes.
- A spawn pad and named destination spawn for every location.
- Quest and shop location signs, a designated safe-zone marker, a boss arena platform and a hidden-treasure placeholder for each main island.
- Three enemy spawn markers and one boss spawn marker for each main island. Sunset Bay's three enemy markers and its Tide Warden boss marker are enabled; enemy and boss markers on the other ten islands remain disabled.
- Static placeholder models for Mira and Toma on Sunset Bay, compatible with the current NPC proximity checks.

This is intentionally a structural blockout. It is not final terrain, a finished biome, a built boss encounter or a treasure collection system.

## Workspace service contracts

| Folder | Marker / attributes | Consumer |
|---|---|---|
| `IslandSpawns/<LocationId>/Spawn` | Destination BasePart | PortalService and WorldBuilderService player placement |
| `IslandPortals` | `DestinationIsland`, `DestinationSpawnName` | PortalService |
| `EnemySpawnPoints` | `TemplateName`, `Level`, `IslandId`, `RespawnSeconds`, `Enabled` | EnemySpawnService |
| `BossSpawnPoints` | `BossTemplateName`, `Level`, `IslandId`, `IsBoss`, `Enabled` | BossService reads enabled boss spawn markers |
| `BossSummonPoints` | `BossId`, `IslandId`, `Enabled`, ProximityPrompt | BossService starts a validated encounter from the arena pedestal |
| `NPCSpawnPoints` | `NpcId`, `IslandId` | Future NPC placement tooling |
| `NPCs` | Model `NpcId`, `IslandId`, `HumanoidRootPart` or PrimaryPart | NPCService |
| `QuestLocations` / `ShopLocations` | `IslandId`, `MarkerType` | Future quest/shop placement tooling |
| `SafeZones` | `IslandId`, `SafeZoneId` | SafeZoneService tracks player proximity and sets `InSafeZone` |
 
The portal destination IDs are:

- Main islands: `SunsetBay`, `PixelCity`, `ForgottenAcademy`, `ClockworkKingdom`, `TheLostEra`, `EmeraldJungle`, `FrozenKingdom`, `DragonVolcano`, `SkyRealm`, `AtlantisIsland`, `HauntedIsland`.
- Special areas: `EchoBattleArena`, `MemoryTrainingIsland`.
- Hub: `CentralArea`.

Special areas are world locations, not main progression islands. They do not change the 11-island level recommendation.

## Enabling enemy markers

Sunset Bay's three generated enemy markers are enabled for the starter roster. `EnemyTemplateService` creates fallback blockout rigs for `TrainingSlime`, `DriftwoodBandit` and `TideCrab` when matching art-authored models are not already present in `ServerStorage/EnemyTemplates`.

For an art-authored replacement:
1. Create a Model with a Humanoid and BasePart named `HumanoidRootPart` under `ServerStorage/EnemyTemplates`.
2. Use the exact template name referenced by the marker.
3. Check the marker's `IslandId` and whole-number `Level` against the central Config island enemy band.
4. Keep a marker disabled until its matching template is valid.

The fallback rigs are simple R6 blockout models and are not final character art or animation assets. The other ten islands retain disabled enemy markers with explicit TODO template names. Their markers should only be enabled after the corresponding island roster is authored. Sunset Bay's Tide Warden boss spawn and summon pedestal are enabled and connected to BossService. The other ten island boss markers and their summon prompts remain disabled until their boss definitions and encounters are authored.

## Rejoin and respawn placement

- New profiles start on Sunset Bay.
- Existing main-island and special-area locations are preserved when still valid for the saved level.
- Retired prototype locations fall back to the highest main island unlocked by the saved level.
- After a profile loads, the player is placed at its saved location.
- After later character respawns, the current `CurrentIsland` attribute is used to place the character back at that location.

The Central Area and special areas are valid world destinations, but not combat progression islands.

The Sunset Bay boss marker is positioned over the boss arena platform. Its visible summon pedestal is placed beyond the safe-zone boundary; the server also checks the player's actual position before it accepts a challenge. See [BOSS_SYSTEM.md](BOSS_SYSTEM.md) for the Tide Warden encounter, phase and reward rules.

Sunset Bay's starter enemy markers are positioned outside the generated safe zone and use levels 1, 12 and 24 for Training Slime, Driftwood Bandit and Tide Crab respectively. The starter roster and AI/drop behavior are documented in [ENEMY_SYSTEM.md](ENEMY_SYSTEM.md).

## Design boundary

The builder replaces only `Workspace/TheLostEraGeneratedWorld` each time it runs. Named service folders are reused, and generated service markers use the `Generated_` prefix. If custom Studio content is added under those same generated names, rename it before re-running the builder or the generated marker may be repositioned.

Safe-zone markers are active: the main-island safe area covers the spawn, quest and shop service points; players within it are protected from the implemented enemy AI, basic melee attacks and offensive skills. Enemy and boss spawn markers sit outside this area. Healing Pulse remains usable. This is not a full PvP protection system. Treasure placeholders remain non-collectible until the exploration system is built.


Safe-zone enforcement uses the marker bounds and currently governs the implemented PvE enemy AI, basic melee attacks and offensive skills. It does not imply future PvP protections.
