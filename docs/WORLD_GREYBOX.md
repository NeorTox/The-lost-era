# THE LOST ERA — Generated World Greybox

## What the world builder creates

`WorldBuilderService.Init()` runs at server startup before the portal and enemy-spawn services scan Workspace. It creates a versioned `Workspace/TheLostEraGeneratedWorld` folder containing:

- The Central Area portal hub, central spawn pad and 13 destination portals.
- Eleven main island greyboxes arranged around the hub.
- Echo Battle Arena and Memory Training Island as separate special-area greyboxes.
- A spawn pad and named destination spawn for every location.
- Quest and shop location signs, a designated safe-zone marker, a boss arena platform and a hidden-treasure placeholder for each main island.
- Three disabled enemy spawn markers and one disabled boss spawn marker for each main island.
- Static placeholder models for Mira and Toma on Sunset Bay, compatible with the current NPC proximity checks.

This is intentionally a structural blockout. It is not final terrain, a finished biome, a built boss encounter, a safe-zone damage system or a treasure collection system.

## Workspace service contracts

| Folder | Marker / attributes | Consumer |
|---|---|---|
| `IslandSpawns/<LocationId>/Spawn` | Destination BasePart | PortalService and WorldBuilderService player placement |
| `IslandPortals` | `DestinationIsland`, `DestinationSpawnName` | PortalService |
| `EnemySpawnPoints` | `TemplateName`, `Level`, `IslandId`, `RespawnSeconds`, `Enabled` | EnemySpawnService |
| `BossSpawnPoints` | `BossTemplateName`, `Level`, `IslandId`, `IsBoss`, `Enabled` | Future BossService |
| `NPCSpawnPoints` | `NpcId`, `IslandId` | Future NPC placement tooling |
| `NPCs` | Model `NpcId`, `IslandId`, `HumanoidRootPart` or PrimaryPart | NPCService |
| `QuestLocations` / `ShopLocations` | `IslandId`, `MarkerType` | Future quest/shop placement tooling |
| `SafeZones` | `IslandId`, `SafeZoneId` | Future safe-zone enforcement |
 
The portal destination IDs are:

- Main islands: `SunsetBay`, `PixelCity`, `ForgottenAcademy`, `ClockworkKingdom`, `TheLostEra`, `EmeraldJungle`, `FrozenKingdom`, `DragonVolcano`, `SkyRealm`, `AtlantisIsland`, `HauntedIsland`.
- Special areas: `EchoBattleArena`, `MemoryTrainingIsland`.
- Hub: `CentralArea`.

Special areas are world locations, not main progression islands. They do not change the 11-island level recommendation.

## Enabling enemy markers

Generated enemy markers start with `Enabled = false` so a new server does not repeatedly attempt to spawn a rig that has not been authored yet.

For each marker:
1. Create a Model with a Humanoid and HumanoidRootPart under `ServerStorage/EnemyTemplates`.
2. Set the marker's `TemplateName` to the exact Model name.
3. Check its `IslandId` and `Level` against the central Config island enemy band.
4. Set `Enabled = true` only after the template is ready.

Sunset Bay uses `TrainingSlime` as the intended first template name. Other generated template names are explicit TODO placeholders. The boss markers are not consumed until BossService is implemented.

## Rejoin and respawn placement

- New profiles start on Sunset Bay.
- Existing main-island and special-area locations are preserved when still valid for the saved level.
- Retired prototype locations fall back to the highest main island unlocked by the saved level.
- After a profile loads, the player is placed at its saved location.
- After later character respawns, the current `CurrentIsland` attribute is used to place the character back at that location.

The Central Area and special areas are valid world destinations, but not combat progression islands.

## Design boundary

The builder replaces only `Workspace/TheLostEraGeneratedWorld` each time it runs. Named service folders are reused, and generated service markers use the `Generated_` prefix. If custom Studio content is added under those same generated names, rename it before re-running the builder or the generated marker may be repositioned.

Safe-zone markers and treasure placeholders are map metadata only; neither currently grants protection or rewards.


Safe-zone enforcement uses the marker bounds and currently governs the implemented PvE enemy AI, basic melee attacks and offensive skills. It does not imply future PvP protections.
