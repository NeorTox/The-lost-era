# THE LOST ERA — Currency and Economy Foundation

## Persistent balances

The player profile stores four progression currencies:

| Currency | Profile field | Player attribute | Current role |
|---|---|---|---|
| Coins | `Coins` | `Coins` | General purchases and services |
| Skill Points (SP) | `SkillPoints` | `SkillPoints` | Unlocking abilities |
| Memory Crystals | `MemoryCrystals` | `MemoryCrystals` | Reserved for memory-related progression and services |
| Void Essence | `VoidEssence` | `VoidEssence` | Reserved for high-tier progression and services |

## Server API

`ProgressionService` exposes server-only functions:

- `AddCoins` / `SpendCoins`
- `AddSkillPoints` / `SpendSkillPoints`
- `AddMemoryCrystals` / `SpendMemoryCrystals`
- `AddVoidEssence` / `SpendVoidEssence`

All grant functions reject negative, fractional, NaN and infinite inputs. Spending requires a positive whole number and cannot make a balance negative. Currency balances are capped at the configured safe integer maximum; Skill Points are capped at the level cap.

No client remote directly modifies these balances. Enemy, quest, boss, dungeon, crafting and shop systems should call the server API after validating the relevant gameplay event.

## Save migration

The profile schema is now version 4. Existing schema-v3 profiles are loaded through the same DataStore key and migrated additively in memory:

- Existing Coins, Skill Points, level, XP, items, quests and loadout are preserved.
- Memory Crystals and Void Essence default to zero when absent.
- The profile is saved as schema v4 on its next successful save.
- The DataStore name, key prefix and session-lock metadata remain unchanged.

## Economy work still required

No acquisition values or shop prices are being invented in this foundation pass. The next economy design pass must define repeatable and one-time sources, sinks, progression pacing, anti-farming rules and balancing targets for each currency before rewards are granted from bosses, dungeons, collectibles, memory training or premium systems.
