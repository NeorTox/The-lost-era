# THE LOST ERA — Boss System

## First encounter: Tide Warden

The first boss encounter is deliberately limited to **Sunset Bay**. It provides the reference implementation for the remaining ten island bosses.

| Field | Value |
|---|---|
| Boss ID / template | `TideWarden` |
| Display name | Tide Warden |
| Challenge level | 25 |
| Player entry requirement | Level 24 or higher |
| Maximum health | 1,400 |
| Starting melee damage | 12 |
| Starting movement speed | 12 |
| Aggro range | 82 studs |
| Chase leash | 180 studs |
| Encounter respawn delay | 180 seconds |
| Trigger | Hold the ProximityPrompt at the Sunset Bay arena pedestal |

Only one Tide Warden encounter can be active on Sunset Bay at a time. The summon pedestal is placed outside the generated safe-zone bounds. The server checks the player's actual position, current island and profile level before starting an encounter.

## Combat phases

The boss uses the ordinary server-authoritative enemy movement and melee loop, with its combat attributes changed by health thresholds.

| Phase | Health threshold | Name | Melee damage | Melee cooldown | Walk speed |
|---:|---:|---|---:|---:|---:|
| I | Above 60% | Tidal Awakening | 12 | 2.8 s | 12 |
| II | 25–60% | Rising Current | 16 | 2.2 s | 14 |
| III | 25% or lower | Tempest Core | 20 | 1.6 s | 16 |

The nameplate displays the current phase. The enemy health bar remains visible and synchronized with Humanoid health.

## Special attack: Tide Slam

The boss periodically targets a nearby player on Sunset Bay. A visible red ground telegraph appears at the target's position for 1.2 seconds. Players can move out of the marked radius before impact.

| Phase | Radius | Damage | Special cooldown |
|---:|---:|---:|---:|
| I | 12 studs | 14 | 9 s |
| II | 15 studs | 18 | 7 s |
| III | 18 studs | 24 | 5.5 s |

At impact, the server checks current island, living character, safe-zone geometry and distance before applying damage. The attack can hit multiple eligible players standing inside the marked area.

## Rewards and participation

Boss damage contribution is recorded by validated server melee attacks and server skill hits. A player qualifies for the encounter payout by contributing at least 2% of the boss's maximum health in damage.

Qualifying participants must still be connected and have a loaded profile when the boss is defeated.

**First clear per player**
- 250 XP
- 500 Coins
- 10 Memory Crystals
- One Tide Warden Sigil

**Repeat clear per player**
- 100 XP
- 180 Coins
- No additional Memory Crystals
- No duplicate Sigil

The completion ID is stored in `BossCompletions` on the player profile. Existing schema-v4 profiles receive an empty completion list when sanitized; the data schema version and existing player fields are unchanged. Inventory sanitization now explicitly allows the three Sunset Bay enemy materials and the Tide Warden Sigil, so these items can survive saving and rejoining.

## World and server integration

- `BossSpawnPoints/Generated_SunsetBay` identifies the boss template, island and level 25 spawn position.
- `BossSummonPoints/Generated_SunsetBay` contains the visible pedestal and ProximityPrompt.
- `EnemyTemplateService` generates the fallback R6 Tide Warden template only when no art-authored template with that exact name exists.
- `BossService` validates the challenge, tracks contributions, changes phases, runs telegraphed attacks, grants rewards and applies the respawn cooldown.
- `CombatService` and `SkillService` report validated boss damage to `BossService`.
- `EnemyService` skips ordinary enemy kill rewards for bosses; boss rewards are distributed by the encounter service.

## Current boundaries

- The fallback Tide Warden is a recolored R6 blockout rig, not final boss art.
- The fight has no custom animation, audio, camera sequence, arena lockdown, cutscene or dedicated mobile boss bar yet.
- Boss health is currently fixed rather than scaled by party size.
- The encounter is globally shared per island; it is not instanced per party.
- The other ten boss markers remain disabled and do not have authored boss definitions.
- Boss completion is recorded for players who qualify for rewards; disconnected players do not receive an offline payout.
- Phase 10 is partial until Studio runtime, multiplayer and mobile tests pass.

## Roblox Studio verification checklist (not yet run)

1. Start the private test place and confirm the Tide Warden fallback template is created under `ServerStorage/EnemyTemplates`.
2. Confirm only the Sunset Bay boss marker and summon prompt are enabled.
3. Verify a level 23 player cannot start the encounter and a level 24 player can.
4. Verify a player inside the actual safe-zone bounds cannot start the fight.
5. Activate the ProximityPrompt on PC and mobile.
6. Confirm only one boss can spawn even if multiple players activate the prompt together.
7. Confirm the Tide Warden appears on the boss platform and targets only living players on Sunset Bay outside the safe zone.
8. Damage the boss through melee and each damaging skill; verify phase changes above 60%, below 60%, and below 25%.
9. Confirm the nameplate phase label and health bar update correctly.
10. Stand inside the red Tide Slam telegraph and verify damage; move outside before impact and verify the attack can be dodged.
11. Verify Tide Slam does not damage players in the safe zone or on a different island.
12. Defeat the boss with one player and verify first-clear XP, Coins, Memory Crystals, Sigil and saved completion.
13. Defeat it with multiple contributors and verify each eligible participant receives the correct first-clear or repeat payout.
14. Rejoin and confirm the Tide Warden Sigil and BossCompletions survive DataStore save/load.
15. Defeat the boss again and verify repeat rewards do not duplicate the first-clear Sigil or completion.
16. Confirm the summon prompt remains disabled during the 180-second cooldown and becomes available afterward.
17. Destroy an active boss model during a test and verify the encounter resets without leaving the island permanently locked.
18. Run a multiplayer test with one safe-zone player, one arena player and one player on another island.
