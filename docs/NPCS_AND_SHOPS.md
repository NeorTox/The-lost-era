# NPCs, Dialogue, Quests and Shops

Create `Workspace/NPCs` and place NPC character Models inside it. Each model needs a `Humanoid`, `HumanoidRootPart` (or PrimaryPart), and attributes `NpcId` and `IslandId`.

Configured starter NPCs:
- `SunsetGuide` — Mira, Island Guide; offers `WelcomeToSunsetBay`.
- `SunsetMerchant` — Toma, Supply Merchant; sells HealthPotion for 30 coins.

Both currently belong to `SunsetBay`. Model attributes must match these IDs exactly.

The server creates these RemoteEvents under `ReplicatedStorage/TheLostEraRemotes`:
- `NPCInteractRequest` / `NPCInteractResult`
- `QuestClaimRequest` / `QuestClaimResult`
- `ShopPurchaseRequest` / `ShopPurchaseResult`

The client sends IDs and quantity only. It never supplies prices, rewards, or destination data. Server validation requires a loaded profile, correct island, matching NPC model and distance of at most 14 studs. Requests are rate-limited. Quest claims must use the configured quest giver. Purchases validate item, stock and quantity (1–10), deduct server-owned coins, then add the item; a failed inventory grant refunds the coins.

## Studio test
1. Create both NPC models in `Workspace/NPCs` with the required attributes.
2. Send interaction requests while within 14 studs; inspect result events.
3. Try interacting from far away and from another island; requests should fail.
4. Complete Mira's quest, claim once, then verify a second claim is rejected.
5. Buy HealthPotion from Toma; verify 30 coins are deducted and inventory increases by one.
6. Test insufficient coins, unknown items, quantity 0/11, and remote spam.

This is the server framework only. Character models, animation, dialogue/shop UI and client prompts must still be built in Studio.
