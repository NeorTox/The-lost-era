# THE LOST ERA — Echoes of 2000

A Roblox RPG built with **Luau** for Roblox Studio.

## Project status

This repository is the source of truth for the game. Development is being built in incremental milestones; runtime completion is only claimed after Roblox Studio testing. The current source includes server-validated gameplay systems, session-locked player persistence, level progression, inventory, starter quests, melee combat, basic enemy AI, configurable enemy spawn markers, character lifecycle defaults, and stamina-based sprinting. Roblox Studio runtime tests are still required before a release-ready status can be claimed.

## Development environment

- Roblox Studio
- Luau (Roblox's Lua-derived language)
- [Rojo](https://rojo.space/) for syncing this source tree into Studio (optional but recommended)

## Project layout

```text
src/
├── server/
│   └── LostEra/
│       ├── Config.lua
│       ├── CharacterService.lua
│       ├── DataService.lua
│       ├── ProgressionService.lua
│       ├── InventoryService.lua
│       ├── QuestService.lua
│       ├── EnemyService.lua
│       ├── EnemySpawnService.lua
│       ├── CombatService.lua
│       ├── PortalService.lua
│       ├── WeaponService.lua
│       ├── SkillService.lua
│       ├── NPCService.lua
│       ├── RemoteService.lua
│       └── Main.server.lua
└── client/
    ├── SkillController.client.lua
    └── SprintController.client.lua

default.project.json
```

## Phase tracking

See [docs/PHASE_STATUS.md](docs/PHASE_STATUS.md) for the current 29-phase implementation status and remaining release work.

## Setup

1. Install Roblox Studio.
2. Install Rojo if you want to sync from this repository.
3. From the project root, run `rojo serve`.
4. Connect Roblox Studio using the Rojo plugin.
5. In Studio, enable **Game Settings → Security → Enable Studio Access to API Services** only for a test experience when testing DataStores.
6. Publish the experience to Roblox before expecting production DataStore persistence.

## Canonical world roster

The current world specification contains 11 main islands, in this order:

1. Sunset Bay
2. Pixel City
3. Forgotten Academy
4. Clockwork Kingdom
5. The Lost Era
6. Emerald Jungle
7. Frozen Kingdom
8. Dragon Volcano
9. Sky Realm
10. Atlantis Island
11. Haunted Island

Additional areas: Echo Battle Arena and Memory Training Island.

The 11-island roster supersedes the earlier eight-island prototype map. New unlock levels and enemy/boss ranges are intentionally not assigned in the code until the revised level progression is approved.

Maximum level: **300**.

## Important notes

- Never put DataStore or other privileged server logic in a LocalScript.
- Client requests must be validated by the server before rewards or progression are granted.
- DataStore behavior must be tested in a published test experience; local static checks are not a substitute for live Roblox testing.
- Do not commit secrets, private keys, or personal account data.

## Roadmap

The 29-phase master checklist is tracked in [docs/PHASE_STATUS.md](docs/PHASE_STATUS.md). The immediate priority is to validate the new player lifecycle and session-locked persistence in a private Roblox test place before expanding the world and progression systems.


## Player movement and stamina

The server configures baseline health, walk speed and jump power for spawned characters. Sprinting is requested by the client but validated and simulated on the server; stamina drains only while moving and regenerates when sprinting is inactive. `src/client/SprintController.client.lua` uses Left Shift on keyboard and a ContextActionService touch button on supported mobile devices.

## Client controls

Rojo maps `src/client` to `StarterPlayer/StarterPlayerScripts/LostEraClient`. The skill interface includes a mobile/touch hotbar and a panel for unlocking and equipping abilities; desktop controls also support keyboard keys 1, 2 and 3. All skill effects and combat decisions remain server-authoritative.
