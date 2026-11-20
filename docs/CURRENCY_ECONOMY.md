# THE LOST ERA — Currency and Economy

## Persistent currency model

The profile stores four balances:

| Currency | Profile field | Player attribute | Current gameplay role |
|---|---|---|---|
| Coins | `Coins` | `Coins` | General shop purchases |
| Skill Points (SP) | `SkillPoints` | `SkillPoints` | Skill unlocks; one point per level gained |
| Memory Crystals | `MemoryCrystals` | `MemoryCrystals` | Reserved for Memory Training and memory-related progression |
| Void Essence | `VoidEssence` | `VoidEssence` | Reserved for endgame progression and Haunted Island content |

## Implemented sources and sinks

All currently implemented reward values are defined in `Config.Economy`. This prevents separate systems from drifting apart.

| Source / sink | Reward or cost | Currency |
|---|---:|---|
| Normal enemy defeat | `5 + 2 × enemy level` | Coins |
| Normal enemy defeat | `15 + 5 × enemy level` | XP |
| Welcome to Sunset Bay quest | 75 XP + 25 Coins | XP, Coins |
| Each level gained | 1 point | Skill Points |
| Health Potion | 30 | Coins |
| Bronze Sword (level 10) | 250 | Coins |
| Iron Blade (level 30) | 900 | Coins |
| Whirlwind / Healing Pulse / Arcane Burst | 2 / 2 / 3 points | Skill Points |

Enemy rewards are assigned server-side at spawn and paid by the server's death handler to the player recorded as the last attacker. The current starter quest cannot be claimed twice because its completion ID is persisted. Shop purchases spend Coins before adding inventory; the price is refunded if the inventory addition fails.

## Unimplemented currency routes

Memory Crystals and Void Essence are persistent and have validated server-side grant/spend APIs, but **there are not yet any gameplay sources or sinks for them**. This is intentional:

- Memory Crystals should be earned through the Memory Training system and relevant memory challenges, not ordinary mob farming.
- Void Essence should be earned through endgame threats, bosses or Haunted Island activities, not starter enemies.
- Their prices, rates, caps per activity and reward cooldowns must be balanced when those gameplay systems are implemented.

Bosses and dungeons do not currently exist as complete gameplay systems. Their eventual reward tables must be authored with those systems and should call the server-side progression APIs after eligibility and completion are validated.

## Anti-abuse and validation rules

- Currency grants accept only finite non-negative whole numbers.
- Currency spending accepts only finite positive whole numbers and cannot create a negative balance.
- Coins, Memory Crystals and Void Essence are capped by `Config.MaxCurrencyBalance`; Skill Points are capped at the level cap.
- Clients cannot directly set or award currency attributes. Server services own the balances.
- NPC purchase remotes validate the NPC, island, distance, item, quantity and level before spending.
- Currency APIs are service functions, not RemoteEvents.
- `Config.ValidateEconomy()` checks reward and shop definitions at server startup.

## Profile migration

Player data is schema v4. Existing schema-v3 profiles migrate additively:
- Existing Coins and Skill Points remain intact.
- Missing Memory Crystal and Void Essence balances initialize to zero.
- Level, XP, inventory, quests, island and equipment remain in the same profile.
- The DataStore name, key prefix and session lock behavior are unchanged.

## Balancing caveat

These are the values already present in the first gameplay loop, now centralized—not a claim of completed economy balancing. The current enemy formulas scale linearly to level 300. Playtesting must measure coin income per minute, potion consumption, weapon affordability, skill unlock pace and progression time before additional island-specific currencies or large reward multipliers are introduced.
