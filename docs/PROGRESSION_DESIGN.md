# THE LOST ERA — Level Progression Design

Status: **Implemented as the initial balancing schedule.** Values are centralized in `src/server/LostEra/Config.lua`; tune them from playtesting rather than creating separate per-system copies.

## Level and XP rules

- Maximum level: **300**.
- Starting level: **1**.
- XP needed to advance from level (L):

  `floor(100 + (L - 1) × 35 + 8 × (L - 1)^1.35)`

- Each level gained awards one Skill Point, up to the current level cap.
- At level 300, XP is clamped to zero and further XP grants do not increase the level.
- `RecommendedIsland` represents the highest island whose `UnlockLevel` is at or below the player's level. It is a recommendation/access-level indicator, not a boss-defeat flag.

## Canonical island schedule

| Route | Island | Unlock level | Normal enemy levels | Boss level |
|---:|---|---:|---:|---:|
| 1 | Sunset Bay | 1 | 1–24 | 25 |
| 2 | Pixel City | 28 | 28–51 | 52 |
| 3 | Forgotten Academy | 55 | 55–78 | 79 |
| 4 | Clockwork Kingdom | 82 | 82–105 | 106 |
| 5 | The Lost Era | 109 | 109–132 | 133 |
| 6 | Emerald Jungle | 136 | 136–159 | 160 |
| 7 | Frozen Kingdom | 163 | 163–186 | 187 |
| 8 | Dragon Volcano | 190 | 190–213 | 214 |
| 9 | Sky Realm | 217 | 217–240 | 241 |
| 10 | Atlantis Island | 244 | 244–267 | 268 |
| 11 | Haunted Island | 271 | 271–299 | 300 |

Each boss is three levels beyond the island's normal enemy band. The next island unlocks three levels after that boss challenge. This leaves a small progression buffer for quest rewards and repeatable encounters; early playtesting may change those margins.

## Canonical IDs

`SunsetBay`, `PixelCity`, `ForgottenAcademy`, `ClockworkKingdom`, `TheLostEra`, `EmeraldJungle`, `FrozenKingdom`, `DragonVolcano`, `SkyRealm`, `AtlantisIsland`, `HauntedIsland`.

These IDs are the shared contract for profile current-island values, portal attributes, enemy spawn markers and future world folders. Use the ID, not the display name.

## Save compatibility

The DataStore name, player key prefix and profile schema version remain unchanged. Existing profiles retain level, XP, coins, items, quests and skills. If a saved current-island ID is no longer in the canonical route (for example, the retired prototype names `ForgottenKingdom` or `EternalAbyss`), the player is placed on the highest canonical island unlocked by their saved level. A valid current island is preserved when the player's level still meets its unlock requirement.

## Integration rules

- Portal destinations must use one of the canonical IDs and must satisfy its `UnlockLevel`.
- Normal enemy spawn markers must use an island ID and a level inside that island's `EnemyLevelMin`–`EnemyLevelMax` band.
- Boss spawns must set `IsBoss = true` and use exactly the island's configured `BossLevel`.
- The level recommendation, enemy validation and portal validation all read the same `Config.Islands` table.
- Boss defeat is not yet an island unlock requirement. A separate boss-completion gate belongs to the Boss System phase and must be designed with boss rewards and save data.
