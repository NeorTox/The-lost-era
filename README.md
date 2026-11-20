# THE LOST ERA — Echoes of 2000

A Roblox RPG built with **Luau** for Roblox Studio.

## Project status

This repository is the source of truth for the game. Development is being built in tested milestones. The initial foundation includes island configuration, player profile persistence, progression, and server startup.

## Development environment

- Roblox Studio
- Luau (Roblox's Lua-derived language)
- [Rojo](https://rojo.space/) for syncing this source tree into Studio (optional but recommended)

## Project layout

```text
src/
└── server/
    └── LostEra/
        ├── Config.lua
        ├── DataService.lua
        ├── ProgressionService.lua
        └── Main.server.lua
default.project.json
```

## Setup

1. Install Roblox Studio.
2. Install Rojo if you want to sync from this repository.
3. From the project root, run `rojo serve`.
4. Connect Roblox Studio using the Rojo plugin.
5. In Studio, enable **Game Settings → Security → Enable Studio Access to API Services** only for a test experience when testing DataStores.
6. Publish the experience to Roblox before expecting production DataStore persistence.

## Initial progression map

| Island | Unlock level | Enemy levels | Boss level |
|---|---:|---:|---:|
| Sunset Bay | 1 | 1–35 | 40 |
| Pixel City | 40 | 40–75 | 80 |
| Clockwork Kingdom | 80 | 80–115 | 120 |
| Emerald Jungle | 120 | 120–155 | 160 |
| Dragon Volcano | 160 | 160–205 | 210 |
| Sky Realm | 210 | 210–255 | 260 |
| Forgotten Kingdom | 260 | 260–275 | 280 |
| Eternal Abyss | 280 | 280–295 | 300 |

Maximum level: **300**.

## Important notes

- Never put DataStore or other privileged server logic in a LocalScript.
- Client requests must be validated by the server before rewards or progression are granted.
- DataStore behavior must be tested in a published test experience; local static checks are not a substitute for live Roblox testing.
- Do not commit secrets, private keys, or personal account data.

## Roadmap

1. Core server foundation and player persistence.
2. XP, levels, island unlocks, and stat replication.
3. Combat validation and enemy lifecycle.
4. Quests, rewards, and inventory.
5. Portals, world generation, and NPC content.
6. Client UI, effects, and end-to-end playtesting.
