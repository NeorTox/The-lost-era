# Skills, Weapons and Combat

## Starting equipment and progression

New players receive a Training Blade and the free Power Strike ability. Every level gained grants one skill point. Existing save files are migrated to profile schema version 3; if a legacy profile has no recorded skill-point balance, the migration grants one point per level already earned.

Skill points are spent to unlock abilities. Skill unlocks, equipped ability slots, skill points, inventory and equipped weapon are saved in the player profile.

## Weapons

| Weapon | Level requirement | Damage multiplier | Basic attack range | Price |
|---|---:|---:|---:|---:|
| Training Blade | 1 | 1.00x | 12 studs | Starter |
| Bronze Sword | 10 | 1.20x | 12 studs | 250 coins |
| Iron Blade | 30 | 1.45x | 13 studs | 900 coins |

Toma at Sunset Bay sells Health Potions, Bronze Swords and Iron Blades. Weapon inventory is non-stackable. Players can equip only weapons they own and meet the level requirement for. An equipped weapon cannot be removed through InventoryService.

## Abilities

| Ability | Unlock level | Skill points | Energy | Cooldown | Effect |
|---|---:|---:|---:|---:|---|
| Power Strike | 1 | Free | 20 | 5s | 2.0x damage, 10-stud radius |
| Whirlwind | 12 | 2 | 30 | 9s | 1.1x damage, 14-stud radius |
| Healing Pulse | 20 | 2 | 40 | 18s | Heals 35% of maximum health |
| Arcane Burst | 35 | 3 | 45 | 12s | 2.0x damage, 18-stud radius |

Players have 100 energy and regenerate 8 energy per second while connected. Three ability slots are available. Power Strike is unlocked and equipped in slot 1 for new players.

## Player interface

Rojo maps `src/client/SkillController.client.lua` into `StarterPlayer/StarterPlayerScripts/LostEraClient`. It creates a touch-friendly three-slot hotbar and an **SKILLS** panel. Players tap a hotbar slot on touch devices or press keyboard keys 1, 2 and 3 on desktop. The management panel shows skill requirements and points, allows eligible abilities to be unlocked, and assigns unlocked abilities to slots. Slot assignments are filled in order; an occupied slot can be replaced by choosing that slot for another ability.

## Client remotes

All events are created under `ReplicatedStorage/TheLostEraRemotes`:

- `SkillStateRequest` / `SkillStateResult`
- `SkillUnlockRequest` / `SkillUnlockResult`
- `SkillEquipRequest` / `SkillEquipResult`
- `SkillUseRequest` / `SkillUseResult`
- `WeaponEquipRequest` / `WeaponEquipResult`

The client submits skill/weapon IDs and a skill slot only. The server checks profile ownership, unlock level, skill points, equipped status, cooldown, energy, character health, island and nearby enemy models. Damage and healing are always calculated on the server.

## Studio checklist

1. Test in a published private experience with DataStore access enabled.
2. Confirm a new player receives the starter weapon and ability.
3. Award XP across one and multiple level thresholds; verify skill points increase.
4. Unlock Whirlwind at level 12, Healing Pulse at level 20 and Arcane Burst at level 35.
5. Equip abilities into slots 1–3 and attempt invalid slots, duplicates, locked abilities and spoofed IDs.
6. Use attack abilities near enemies on the same island, behind walls, outside the radius, and on another island.
7. Use Healing Pulse at low health, full health and with insufficient energy.
8. Buy and equip weapons; test level gates, insufficient funds and duplicate purchases.
9. Rejoin and verify skill points, unlocked/equipped skills, weapon ownership and equipped weapon persist.

The touch hotbar and skill unlock/equip panel are included at `StarterPlayerScripts/LostEraClient/SkillController.client.lua`. Weapon models, ability animations, visual effects and actual Roblox Studio runtime tests are not yet included.
