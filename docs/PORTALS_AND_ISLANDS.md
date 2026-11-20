# Island Portals and World Setup

This milestone adds server-authoritative island travel.

## Required Workspace layout

Create these folders in Roblox Studio:

```text
Workspace
├── IslandPortals
│   ├── SunsetBayToPixelCity (Part)
│   ├── PixelCityToSunsetBay (Part)
│   └── ... (one or more portal trigger parts per connection)
└── IslandSpawns
    ├── SunsetBay
    │   └── Spawn (Part)
    ├── PixelCity
    │   └── Spawn (Part)
    ├── ClockworkKingdom
    │   └── Spawn (Part)
    ├── EmeraldJungle
    │   └── Spawn (Part)
    ├── DragonVolcano
    │   └── Spawn (Part)
    ├── SkyRealm
    │   └── Spawn (Part)
    ├── ForgottenKingdom
    │   └── Spawn (Part)
    └── EternalAbyss
        └── Spawn (Part)
```

Each portal trigger must be a BasePart inside `Workspace/IslandPortals`. Set:

| Attribute | Type | Required | Meaning |
|---|---|---:|---|
| `DestinationIsland` | String | Yes | Exact Config island ID |
| `DestinationSpawnName` | String | No | Spawn part name; defaults to `Spawn` |

Use these exact island IDs:

- `SunsetBay`
- `PixelCity`
- `ClockworkKingdom`
- `EmeraldJungle`
- `DragonVolcano`
- `SkyRealm`
- `ForgottenKingdom`
- `EternalAbyss`

Spawn parts should be anchored, positioned safely above the ground, and named exactly as referenced by the portal. Portal trigger parts should have `CanTouch = true`; make them visible or invisible according to your map design.

## Security and behavior

- The server reads the destination from the portal's server-side attributes.
- The destination must exist in the central island configuration.
- The player's server-synced Level attribute must meet the island's UnlockLevel.
- The destination spawn must exist before a teleport is allowed.
- The server moves the character and updates both the CurrentIsland attribute and the loaded profile.
- A short per-player cooldown prevents repeated touch events from chaining teleports.
- Locked portal attempts set `PortalDeniedIsland` on the player so a future client UI can show a level requirement message.

No client RemoteEvent is used for portal travel. This avoids trusting client-supplied destination names or CFrames.

## Studio test checklist

1. Create both Workspace folders and the spawn parts shown above.
2. Add a portal BasePart and set `DestinationIsland = PixelCity`.
3. Keep the test account below level 40; touching the portal must not teleport it.
4. Set the test profile/account to level 40 or higher; touching it should teleport to Pixel City's Spawn.
5. Confirm `CurrentIsland` changes to `PixelCity`.
6. Add a reverse portal with `DestinationIsland = SunsetBay`; verify return travel.
7. Remove a destination spawn temporarily; the portal should warn and safely refuse travel.
8. Test while dead and while respawning; the portal should not move a dead character.

## Current limitation

The service handles portal triggers and destination validation, but it does not generate island terrain, build portal visuals, or create spawn parts automatically. Those are Studio world-building tasks. The server will warn if required folders or destinations are missing.
