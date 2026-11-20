# THE LOST ERA — 29-Phase Development Status

This status file follows the current master checklist: **THE LOST ERA — Echoes of 2000**, Roblox mobile and PC, maximum level 300. "Implemented" describes source code only; a phase is not release-complete until its Roblox Studio tests pass.

| Phase | System | Current status | Remaining work |
|---:|---|---|---|
| 1 | Project Setup | Partial | Repository and Rojo mapping exist; import and project configuration still need Studio verification |
| 2 | Core Player System | Partial | Character lifecycle, baseline health/movement, energy, stamina, sprint and mobile/keyboard input are implemented; a basic live HUD now displays health, energy, stamina, XP, level, island and all four currency balances; animation assets and Studio lifecycle tests remain |
| 3 | Player Data and Saving | Implemented in source; runtime verification pending | Schema v4 profile with backward migration from v3, DataStore metadata session locks, serialized UpdateAsync saves, bounded retries, autosave and final shutdown/player-leave save are implemented; test multi-server contention, failure recovery and rejoin in a published private test place |
| 4 | Level and Progression | Implemented in source; runtime balancing pending | Canonical 11-island unlock/enemy/boss schedule is centralized in Config.lua; level-to-island helpers, recommended-island attributes and spawn-level validation are integrated; XP curve, boss gates and reward pacing still need Studio playtesting |
| 5 | Currency and Economy | Partial | Coins, Skill Points, Memory Crystals and Void Essence now have persistent schema-v4 balances and server-only add/spend APIs; existing enemy/quest rewards and shop/skill sinks are centralized in Config.Economy; Memory Crystal and Void Essence gameplay sources/sinks, new reward tables and economic playtesting remain |
| 6 | World and Island Construction | Greybox generated in source; art/content incomplete | Runtime world builder creates the Central Area, 11 themed greybox islands, Echo Battle Arena and Memory Training Island; portal, spawn, quest/shop, active safe-zone, boss and treasure markers exist; collectible interactions, complete NPC/enemy rosters, terrain art and Studio validation remain |
| 7 | Portal and Travel | Partial | Hub portals to all 11 islands and both special areas plus return portals are generated; saved-location placement and level checks are wired; portal UI feedback and Studio travel tests remain |
| 8 | Combat | Partial | Server-validated basic melee and skill attacks exist; combos, weapon feel, effects and full combat balancing remain |
| 9 | Enemy System | Partial | Three Sunset Bay enemy types, fallback R6 blockout templates, active spawn markers, leash-aware same-island AI, safe-zone checks, inventory material drops and post-defeat respawns are implemented in source; other island rosters, authored rigs, effects, balance and Studio runtime tests remain |
| 10 | Boss System | Not implemented | Boss AI, phases, attacks, rewards and arenas remain |
| 11 | Weapon System | Partial | Training Blade, Bronze Sword and Iron Blade plus server equip/stats exist; full weapon roster, skills, animations and drops remain |
| 12 | Armor and Equipment | Not implemented | Armor slots, stats, sets, equipment UI and persistence remain |
| 13 | Skill System | Partial | Four server-authoritative skills, unlock costs, loadout and energy regeneration exist; full skill roster, VFX and balancing remain |
| 14 | Item Rarity | Not implemented | Common through Eternal rarity rules, rolls, drops and UI remain |
| 15 | Inventory | Partial | Basic validated item stacks and starter weapons exist; complete categories, capacity, equipment interactions and UI remain |
| 16 | Quest System | Partial | Starter quest, persisted objective progress and claim protection exist; quest chains, variety, rewards and full UI remain |
| 17 | NPC and Shop | Partial | Two Sunset Bay NPC definitions and server-validated purchases exist; complete island NPCs, dialogue and shop interfaces remain |
| 18 | Dungeon | Not implemented | Dungeon maps, entry rules, waves, rewards and completion flow remain |
| 19 | Crafting | Not implemented | Recipes, materials, stations, validation and crafting UI remain |
| 20 | PvP | Not implemented | Arena rules, matchmaking/duels, combat restrictions and rewards remain |
| 21 | Memory Training | Not implemented | Training activities, progression, rewards and Memory Training Island remain |
| 22 | Special Collectibles and Exploration | Not implemented | Hidden treasures, collectibles, secrets and exploration rewards remain |
| 23 | UI | Partial | Skill menu/hotbar, sprint touch action and basic responsive player status HUD exist; inventory, quests, shops, NPC dialogue, settings and full visual polish remain |
| 24 | Audio, Animations and Effects | Not implemented | Asset selection, animation sets, soundscape, combat effects and optimization remain |
| 25 | Multiplayer | Partial | Server services and remotes are structured for multiplayer; concurrent-player, persistence contention and gameplay tests remain |
| 26 | Mobile Optimization | Partial | Touch skill controls and sprint action exist; device layout/performance, input testing and low-end device optimization remain |
| 27 | Security and Anti-Exploit | Partial | Critical progression, combat, NPC, shop and sprint decisions are server-validated; complete remote rate limits, movement validation and exploit review remain |
| 28 | Final Testing | Not started | Full regression, device, multiplayer, DataStore failure and performance testing remain |
| 29 | Publishing | Not started | Production place configuration, assets, monetization decisions, release checklist and publishing remain |

## Current implementation checkpoint

The current work focused on closing the most important early-game foundation gaps:

- Player profile data now acquires a per-player session lock in DataStore metadata.
- Save operations are serialized per player, use bounded exponential retries and verify lock ownership before writing.
- Player departure and server shutdown attempt a final save and release the lock only after a successful save.
- Character spawning and respawning apply baseline health and movement values.
- Sprint stamina is controlled by the server and exposed through keyboard and mobile touch input.
- Quest objective progress already lives in the profile and is included in save snapshots.
- Player data now migrates additively from schema v3 to schema v4 with persistent Memory Crystal and Void Essence balances defaulting to zero.
- The canonical 11-island progression schedule is centralized in Config.lua; old island IDs fall back to the highest island unlocked by the saved player level.
- Enemy spawn markers and enemy spawning now validate island IDs and whole-number level bands against the shared progression configuration.
- EnemyCatalog defines three distinct Sunset Bay enemies; EnemyTemplateService supplies simple fallback R6 blockout rigs only when art-authored templates are absent.
- The three Sunset Bay spawn markers are enabled and assigned to TrainingSlime (level 1), DriftwoodBandit (level 12) and TideCrab (level 24); spawn markers on the other ten islands remain disabled.
- Enemy AI targets only players on its island, excludes safe-zone players, checks protection again before damage, and returns to its home position when targets leave its chase leash.
- Enemy defeats award configured XP/Coins and have a chance to add Slime Gel, Driftwood Scrap or Tide Shell directly to the killer's inventory; respawn delay starts after the old model is removed.
- Existing enemy and quest reward values plus shop prices are centralized in Config.Economy and validated at server startup; Memory Crystal and Void Essence are reserved for future systems.
- WorldBuilderService now generates the hub, all 11 main island greyboxes and both special areas, together with the Workspace folders and markers used by portals, player placement, NPCs, enemies and future boss systems. Sunset Bay's three starter enemy markers are enabled against the generated fallback templates; the other ten islands' markers remain disabled until their rosters are authored.
- SafeZoneService tracks player proximity; enemies ignore protected players, and basic attacks/offensive skills are rejected from safe zones while healing remains available.

## Verification boundary

The repository files were fetched again after the commits. No CI status checks were reported for the latest commit, and no Roblox Studio runtime has been executed in this environment. Therefore, the source changes are committed and repository-verified, but Phases 2, 3 and 9 must remain runtime-unverified until the listed Studio tests pass. The Phase 9 Studio checklist is documented in ENEMY_SYSTEM.md.
