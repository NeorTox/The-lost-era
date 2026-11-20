# THE LOST ERA — Test Plan

These checks are intended for Roblox Studio. Static repository inspection does not prove runtime correctness.

## Studio setup
- [ ] Open the project with Rojo and confirm `ServerScriptService/LostEra` contains the server modules.
- [ ] Publish a private test experience.
- [ ] Enable Studio API access only for that test experience when testing DataStores.
- [ ] Start a local server with at least two test clients.

## Player data
- [ ] A first-time player receives Level 1, 0 XP, 0 Coins, a Training Blade and Power Strike.
- [ ] Rejoining restores level, XP, coins, island, inventory, completed quest IDs, quest progress, skill points, unlocked/equipped skills and equipped weapon.
- [ ] Temporarily disable API access and confirm a load failure does not overwrite existing cloud data.
- [ ] Leave and rejoin during autosave; check Output for DataStore errors.
- [ ] Test server shutdown with multiple players connected.
- [ ] Confirm old schema profiles migrate to schema version 3 and receive a valid starter weapon/skill loadout.

## Progression
- [ ] Award XP and verify level-up at the configured threshold.
- [ ] Award enough XP to cross multiple levels in one grant.
- [ ] Verify each gained level grants one skill point.
- [ ] Verify the level cap is 300 and XP resets at cap.
- [ ] Verify recommended island changes at levels 1, 40, 80, 120, 160, 210, 260, and 280.

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

## Skills and abilities
- [ ] Unlock Whirlwind at level 12, Healing Pulse at level 20 and Arcane Burst at level 35, respecting skill-point costs.
- [ ] A new profile has Power Strike unlocked and equipped, with 100 energy.
- [ ] Each level gained grants one skill point; unlock costs and level requirements are enforced.
- [ ] Only unlocked skills can be equipped; only equipped skills can be used.
- [ ] No more than three skills can be equipped.
- [ ] Skill cooldown and energy costs are enforced by the server.
- [ ] Power Strike, Whirlwind and Arcane Burst damage only nearby enemies on the current island.
- [ ] Healing Pulse restores health but cannot exceed MaxHealth.
- [ ] Skill unlocks, loadout and points survive rejoining.
- [ ] Use the mobile SKILLS panel to unlock an eligible skill and assign it to an open/replacement slot.
- [ ] Tap each mobile hotbar slot; on desktop, verify keyboard keys 1, 2 and 3 activate the corresponding equipped skills.
- [ ] Repeated remote calls cannot bypass cooldowns, level requirements, energy or ownership checks.

## Portals and world
- [ ] Locked island portals refuse travel.
- [ ] Eligible players are moved to the configured spawn and CurrentIsland is updated.
- [ ] Missing portal destinations safely refuse travel.

## Known implementation boundary
NPC models, portal parts, enemy rigs, spawn points, client UI, animations and in-Studio multiplayer tests still need to be created/performed. This plan is a test checklist, not a claim that those tests have passed.
