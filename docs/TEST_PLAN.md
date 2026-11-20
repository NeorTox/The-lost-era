# THE LOST ERA — Test Plan

These checks are intended for Roblox Studio. Static repository inspection does not prove runtime correctness.

## Studio setup

- [ ] Open the project with Rojo and confirm `ServerScriptService/LostEra` contains the server modules.
- [ ] Confirm client scripts appear under `StarterPlayer/StarterPlayerScripts/LostEraClient`.
- [ ] Publish a private test experience.
- [ ] Enable Studio API access only for that test experience when testing DataStores.
- [ ] Start a local server with at least two test clients.

## Player data and persistence

- [ ] A first-time player receives Level 1, 0 XP, 0 Coins, a Training Blade and Power Strike.
- [ ] Rejoining restores level, XP, coins, island, inventory, completed quest IDs, quest progress, skill points, unlocked/equipped skills and equipped weapon.
- [ ] Temporarily disable API access and confirm a load failure does not overwrite existing cloud data.
- [ ] Leave and rejoin during autosave; check Output for DataStore errors.
- [ ] Test server shutdown with multiple players connected.
- [ ] Confirm existing schema-v3 profiles migrate to schema v4 without loss of current fields; missing Memory Crystals and Void Essence balances initialize to zero.
- [ ] Confirm a profile with a newer schema version is refused without being downgraded.
- [ ] Confirm an unexpected non-table stored value is not overwritten with a default profile.
- [ ] Start two servers with the same test account; confirm the second cannot acquire the unexpired session lock.
- [ ] Simulate a stale lock and confirm a new server can acquire it only after expiry.
- [ ] Confirm a server that has lost lock ownership cannot save its stale in-memory snapshot.
- [ ] Confirm failed final saves leave the lock in place until expiry.

## Progression

- [ ] Award XP and verify level-up at the configured threshold.
- [ ] Award enough XP to cross multiple levels in one grant.
- [ ] Verify each gained level grants one skill point.
- [ ] Verify the level cap is 300 and XP resets at cap.
- [ ] Verify recommended-island changes at every configured unlock boundary in `docs/PROGRESSION_DESIGN.md`.
- [ ] Verify each island ID, enemy band and boss level matches the central Config table.
- [ ] Verify levels 25, 52, 79, 106, 133, 160, 187, 214, 241, 268 and 300 map to the expected boss challenge.
- [ ] Verify normal enemy markers outside their island's configured level band are rejected.
- [ ] Verify boss spawns require the configured boss level and an explicit IsBoss option.
- [ ] Verify old profile island IDs migrate according to saved level without changing saved level, XP or other profile fields.
- [ ] Server startup refuses to run if the central 11-island progression table fails its consistency validator.
- [ ] Invalid, NaN, infinite or out-of-band enemy spawn marker levels are rejected; respawn delays remain within 3–3600 seconds.

## Player lifecycle and movement

- [ ] A loaded player receives MaxHealth 100, MaxEnergy 100, MaxStamina 100, WalkSpeed 16 and JumpPower 50.
- [ ] The current character receives baseline values after profile load; newly spawned and respawned characters receive the same values.
- [ ] Character death stops sprinting; respawn restores full health and stamina.
- [ ] Sprint starts only for a loaded player with a living character and positive stamina.
- [ ] Sprint speed is 24; stamina drains at the configured rate only while the character is moving.
- [ ] Stamina regenerates while not sprinting and cannot exceed MaxStamina.
- [ ] Sprint automatically stops at zero stamina and can be released with Left Shift or the mobile touch button.
- [ ] Repeated player initialization does not create duplicate stamina loops or CharacterAdded connections.

## Player HUD

- [ ] HUD displays level, island, coins, health, energy, stamina and XP.
- [ ] Health bar follows Humanoid HealthChanged and MaxHealth updates.
- [ ] Energy and stamina bars update when server attributes change.
- [ ] XP bar handles normal progression and maximum level without division by zero.
- [ ] HUD survives character respawn without duplicate health listeners.
- [ ] HUD remains legible on narrow mobile screens and does not overlap the skill hotbar or sprint action.

## Inventory, weapons and shops

- [ ] Add and remove known items; verify counts.
- [ ] Reject zero, negative, fractional, NaN, infinite and over-limit inventory amounts.
- [ ] Reject unknown items and additions beyond stack limits.
- [ ] Reject removal when the player does not own enough items.
- [ ] Confirm an equipped weapon cannot be removed.
- [ ] Buy Bronze Sword at level 10 and Iron Blade at level 30; verify prices and level checks.
- [ ] Equip only owned weapons and verify attributes update.
- [ ] Confirm weapon damage multiplier and range affect basic attacks.

## Quests and NPCs

- [ ] Quest progress cannot exceed its target and persists across rejoin.
- [ ] Incomplete quests cannot be claimed.
- [ ] Completed quests cannot be claimed twice.
- [ ] NPC interactions require the correct island and a distance of at most 14 studs.
- [ ] Verify quest XP and coin rewards update player attributes.

## Currency and economy

- [ ] New profiles start with 0 Coins, 0 Skill Points, 0 Memory Crystals and 0 Void Essence.
- [ ] Existing schema-v3 profiles keep their Coins and Skill Points and receive zero Memory Crystals and Void Essence during migration to schema v4.
- [ ] Add/spend APIs for Coins, Skill Points, Memory Crystals and Void Essence accept only finite non-negative whole-number grants and positive whole-number spending.
- [ ] Reject negative, fractional, NaN and infinite currency grants/spending.
- [ ] Spending cannot reduce a balance below zero; insufficient funds return a failure result.
- [ ] Currency balances are capped at the configured safe integer maximum and persist across rejoin.
- [ ] HUD displays Coins, Skill Points, Memory Crystals and Void Essence and updates immediately when server attributes change.
- [ ] No client remote can directly award or set currency balances.
- [ ] Verify normal enemy XP/Coins follow Config.Economy formulas for low-, mid- and high-level bands.
- [ ] Verify enemy XP/Coins are awarded only once per enemy death and only to the server-recorded last attacker.
- [ ] Verify Welcome to Sunset Bay grants 75 XP and 25 Coins once; replaying the claim does not award again.
- [ ] Verify Health Potion, Bronze Sword and Iron Blade prices/level gates match Config.Economy.Shop.
- [ ] Force inventory stack-limit failure during purchase and verify the exact Coin price is refunded.
- [ ] Verify Config.ValidateEconomy rejects fractional, negative, infinite or malformed reward and shop values.

## Skills and abilities

- [ ] Unlock Whirlwind at level 12, Healing Pulse at level 20 and Arcane Burst at level 35, respecting skill-point costs.
- [ ] A new profile has Power Strike unlocked and equipped, with 100 energy.
- [ ] Only unlocked skills can be equipped; only equipped skills can be used.
- [ ] No more than three skills can be equipped.
- [ ] Skill cooldown and energy costs are enforced by the server.
- [ ] Damage skills affect only nearby enemies on the current island.
- [ ] Healing Pulse restores health but cannot exceed MaxHealth.
- [ ] Skill unlocks, loadout and points survive rejoining.
- [ ] Use the mobile SKILLS panel to unlock an eligible skill and assign it to a slot.
- [ ] Tap each mobile hotbar slot; on desktop, verify keys 1, 2 and 3 activate equipped skills.
- [ ] Repeated remote calls cannot bypass cooldowns, level requirements, energy or ownership checks.

## Generated world and island construction

- [ ] Start a fresh server and confirm Workspace/TheLostEraGeneratedWorld contains the Central Area, all 11 canonical islands, Echo Battle Arena and Memory Training Island.
- [ ] Confirm Workspace/IslandSpawns contains a Spawn part for CentralArea, each main island and each special area.
- [ ] Confirm the player initially spawns on Sunset Bay after profile load and returns to their saved location after rejoining.
- [ ] Confirm island spawn markers are placed just above the top surface of their platform, not floating above or embedded in the platform.
- [ ] Confirm a respawn returns the player to their current island or special area, not always to the hub.
- [ ] Confirm the hub has a portal for every main island and both special areas.
- [ ] Confirm the hub spawn pad is unobstructed by the hub landmark and the player can walk directly from spawn to all portal triggers.
- [ ] Confirm every main island and special area has a return portal to CentralArea.
- [ ] Confirm level-locked hub portals reject travel and unlocked portals update the player location.
- [ ] Confirm each main island has three disabled enemy spawn markers with levels inside its configured enemy band; enabling a marker starts its spawn loop only after a matching template exists.
- [ ] Confirm each main island has a boss spawn marker at its configured boss level; BossService is not implemented yet.
- [ ] Confirm the Sunset Bay Mira and Toma placeholder NPC models are found by NPCService and pass proximity checks.
- [ ] Confirm quest, shop, safe-zone, boss-arena and treasure placeholders are positioned within their island boundaries.
- [ ] Confirm special area IDs persist through profile saves and loads.

## Portals and world

- [ ] Locked island portals refuse travel.
- [ ] Eligible players are moved to the configured spawn and CurrentIsland is updated.
- [ ] Missing portal destinations safely refuse travel.

## Known implementation boundary

The generated world is a greybox, not final terrain/art. Enemy templates, BossService, safe-zone enforcement, treasure collection interactions, full island NPC/quest/shop rosters, the complete inventory/quest/shop UI, animation assets and in-Studio multiplayer tests still need to be created/performed. The existing skill menu/hotbar, player HUD and sprint touch action are only the currently implemented portion of the interface. This plan is a test checklist, not a claim that those tests have passed.
