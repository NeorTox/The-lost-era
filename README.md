# THE LOST ERA — Echoes of 2000

A Roblox anime adventure RPG built with **Luau** for Roblox Studio, targeting mobile and PC.

## Project status

This repository is the source of truth for the game's code. Development is built in incremental milestones. The current source includes session-locked player persistence, level progression, four persistent currencies, Config-driven starter enemy/quest rewards and shop prices, basic inventory and quests, server-validated combat and skills, basic enemy AI and spawn markers, portal handling, a procedural Central Area/11-island/special-area greybox builder, character lifecycle defaults, stamina-based sprinting, and a live player HUD.

Roblox Studio runtime tests are still required before systems can be considered release-ready.

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
│       ├── WorldBuilderService.lua
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
    ├── PlayerHUD.client.lua
    └── SprintController.client.lua

default.project.json
```

## Phase tracking

See [docs/PHASE_STATUS.md](docs/PHASE_STATUS.md) for current implementation status across the 29-phase master checklist and [docs/CURRENCY_ECONOMY.md](docs/CURRENCY_ECONOMY.md) for the persistent currency model and implemented economy sources/sinks.

## Setup

1. Install Roblox Studio.
2. Install Rojo if you want to sync from this repository.
3. From the project root, run `rojo serve`.
4. Connect Roblox Studio using the Rojo plugin.
5. In Studio, enable **Game Settings → Security → Enable Studio Access to API Services** only for a test experience when testing DataStores.
6. Publish the experience before expecting production DataStore persistence.

## Canonical world roster

The server now generates a navigable greybox containing the Central Area, the 11 main islands below, Echo Battle Arena and Memory Training Island. These are structural blockouts; final terrain, art, combat-safe logic and collectible interactions remain future work.

The 11 main islands are:

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

The 11-island roster supersedes the earlier eight-island prototype map. Its initial level unlocks, normal enemy bands and boss challenge levels are documented in [docs/PROGRESSION_DESIGN.md](docs/PROGRESSION_DESIGN.md) and centralized in Config.lua.

Maximum level: **300**.

## Important notes

- Never put DataStore or other privileged server logic in a LocalScript.
- Client requests must be validated by the server before rewards or progression are granted.
- DataStore behavior must be tested in a published private test experience; static repository inspection is not a substitute for live Roblox testing.
- Do not commit secrets, private keys, or personal account data.

## Current player interface

- `PlayerHUD.client.lua` displays level, island, health, energy, stamina, XP, Coins, Skill Points, Memory Crystals and Void Essence.
- `SkillController.client.lua` provides a mobile/touch skill hotbar and skill-management panel, plus desktop keys 1, 2 and 3.
- `SprintController.client.lua` binds sprint to Left Shift on desktop and a ContextActionService touch button on mobile.
- Health, energy, stamina and progression values are driven by the character and server-synced player attributes.

## Player movement and stamina

The server configures baseline health, walk speed and jump power on spawned characters. Sprint requests are validated by the server; stamina drains while the character is moving and regenerates when sprinting is inactive. Respawning restores the character's baseline values.

## Roadmap

The full 29-phase master checklist is tracked in [docs/PHASE_STATUS.md](docs/PHASE_STATUS.md). Immediate priorities are private Roblox Studio validation of player lifecycle and persistence, then Roblox Studio validation and the staged construction of the 11-island world.
