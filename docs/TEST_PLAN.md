# THE LOST ERA — Test Plan

These checks are intended for Roblox Studio. Static repository inspection does not prove runtime correctness.

## Studio setup
- [ ] Open the project with Rojo and confirm `ServerScriptService/LostEra` contains the server modules.
- [ ] Publish a private test experience.
- [ ] Enable Studio API access only for that test experience when testing DataStores.
- [ ] Start a local server with at least two test clients.

## Player data
- [ ] A first-time player receives Level 1, 0 XP, and 0 Coins.
- [ ] Rejoining restores saved Level, XP, Coins, island, inventory, and completed quest IDs.
- [ ] Temporarily disable API access and confirm a load failure does not overwrite existing cloud data.
- [ ] Leave and rejoin during autosave; check Output for DataStore errors.
- [ ] Test server shutdown with multiple players connected.

## Progression
- [ ] Award XP and verify level-up at the configured threshold.
- [ ] Award enough XP to cross multiple levels in one grant.
- [ ] Verify the level cap is 300 and XP resets at cap.
- [ ] Verify recommended island changes at levels 1, 40, 80, 120, 160, 210, 260, and 280.

## Inventory and quests
- [ ] Add a known item and verify the count.
- [ ] Reject unknown items, negative amounts, and additions beyond stack limits.
- [ ] Reject removal when the player does not own enough items.
- [ ] Quest progress cannot exceed its target.
- [ ] Incomplete quests cannot be claimed.
- [ ] Completed quests cannot be claimed twice.
- [ ] Verify quest XP and coin rewards update player attributes.

## Known implementation boundary
Quest objective progress is currently held in server memory and is not persisted between sessions. Completed quest IDs are persisted. Persisted quest objective progress will be added with the quest data migration milestone.
