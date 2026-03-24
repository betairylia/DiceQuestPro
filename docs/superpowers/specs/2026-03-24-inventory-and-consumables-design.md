# Inventory System & Combat Consumables Design

## Overview

Add a unified item system with inventory UI, a team overview screen, and combat consumable mechanics. Players can view inventory from a team overview screen (accessible from worldmap) and consume items during combat at the cost of 1 reroll energy.

## 1. Item Data Model

### Base Item (`Source/Core/Structs/item.gd`)

A `Resource` base class for all items:

- `display_name: String`
- `description: String` (tooltip text)
- `item_type: ItemType` enum (`DiceFace`, `Consumable`)
- `is_consumable_in_combat: bool`
- `create_icon() -> Control` — virtual, each subclass returns its own visual representation
- `consume(ctx: CombatConsumeContext) -> void` — virtual, overridden by subclasses

No `Texture2D` icon field. Each subclass owns its visual via `create_icon()`:
- `DiceFaceItem` returns a mini die-face styled node (element symbol + digit)
- `HealthPotionItem` returns a `TextureRect` (swappable to animated later)

### CombatConsumeContext

A lightweight struct passed to `item.consume()`, containing references needed by consumable items:

- `player_results: Array[DiceResult]` — the current player dice result list (for appending virtual dice)
- `players: Array[Mob]` — all player Mob nodes (for healing/targeting)
- `combat_node: Node` — reference to the combat scene root (for adding visual nodes, re-matching spells)
- `dice_matcher: DiceMatcher` — for re-running spell matching after dice result changes

This avoids coupling Item to SpellContext or MatchedSpell.

### DiceFaceItem Refactor (`Source/Core/Structs/dice_face_item.gd`)

Refactored to extend `Item`:
- Keeps existing fields: `element`, `digit`, `sell_value`, `buy_value`
- `is_consumable_in_combat = true`
- `create_icon()` — renders element symbol + digit as a die face
- `consume(ctx)` — creates a `DiceResult` via `DiceResult.new(digit, element, false)`, then sets `.source = null` and `.node = null` (matching the existing `_init(digit, elem, isex)` 3-arg constructor), appends to `ctx.player_results`, triggers spell re-matching via `ctx.dice_matcher`

### HealthPotionItem (`Source/Core/Structs/health_potion_item.gd`)

Extends `Item`:
- `is_consumable_in_combat = true`
- `power: int = 30`
- `create_icon()` — returns a `TextureRect` with potion texture
- `consume(ctx)` — directly calls `ally_heal_all.Do()` with a manually constructed context, bypassing `SpellLogic.execute()` entirely. Constructs a `SpellContext` with `power=30`, `targets=alive players from ctx.players`, and a stub `MatchedSpell` whose `matched_dice` is an empty `Array[DiceResult]` (so that `digit_sum()` and similar methods return 0 safely rather than crashing). The `ally_heal_all.Do()` only accesses `ctx.power` and `ctx.targets`, so the stub is safe.

### GameState Inventory Change

`GameState.inventory` changes from `Array[DiceFaceItem]` to `Array[Item]`. Method signatures `add_item()` and `remove_item()` updated to accept `Item` type. Forge and shop code adds `is DiceFaceItem` type checks where dice-face-specific fields are needed.

Items do not stack. Each item occupies one inventory slot. No maximum inventory capacity for now — the grid wraps to multiple rows if needed.

## 2. Inventory Grid Component

### InventoryGrid (`Prototyping/HUD/InventoryGrid/inventory_grid.tscn` + `.gd`)

Reusable `GridContainer`-based component:
- Fixed cell size: ~24x24 per slot (fits 640x360 viewport)
- Reads from `GameState.inventory`
- Calls `item.create_icon()` for each cell
- Emits `item_clicked(item: Item)` signal
- `refresh()` method to rebuild when inventory changes
- Optional `filter: Callable` property for context-specific filtering (e.g., combat shows only `is_consumable_in_combat` items)
- **Hidden when inventory is empty** (visibility toggled in `refresh()`)

### Placement

- **Combat screen:** Bottom-right corner, compact grid (~4-6 slots wide). Connects `item_clicked` to consume confirmation flow.
- **Team Overview screen:** Larger grid in the right half, view-only.

Inventory grid does NOT appear on the WorldMap screen itself.

## 3. Team Overview Screen

### TeamOverview (`Prototyping/Screens/TeamOverview/team_overview.tscn` + `.gd`)

Full screen accessible via "Team" button on WorldMap. Uses `SceneTransition` for navigation (same pattern as other screens).

### Layout (640x360, left-right split)

**Left half (~320px):** Team members stacked vertically. Each row shows:
- Character sprite
- Name
- HP bar
- Die info (type, element faces, bonus)

**Right half (~320px):**
- Inventory grid (top)
- Gold display
- Run stats

**Back button:** Top-left, returns to WorldMap.

**Data source:** Reads from `GameState` (`team`, `inventory`, `gold`).

## 4. Combat Item Consumption Flow

### Trigger

Player clicks an item in the combat inventory grid during dice selection phase (before pressing Act).

### Flow

1. Player clicks item in grid
2. Confirmation popup appears near the item: "Use [item name]? Costs 1 reroll energy" with "Use" / "Cancel" buttons. Popup position is clamped to viewport bounds to prevent clipping offscreen.
3. On confirm:
   - Deduct 1 reroll energy
   - Remove item from `GameState.inventory`
   - Call `item.consume(combat_consume_context)`
   - Refresh inventory grid and energy display
4. On cancel: nothing happens

### Phase Gating

The inventory grid is **interactive only during `CombatExecPhase.Preparation`** (after dice are rolled, before Act is pressed — the same window where rerolls are allowed). During all other phases (`PlayerRegular`, `PlayerSpells`, `EnemyRegular`, `EnemySpells`), the grid is disabled (clicks ignored). The grid listens to the same phase signals that control the reroll button. When reroll energy is 0, the grid items appear grayed out / non-clickable (same as the reroll button being disabled when energy is 0).

### Constraints

- Only usable during player dice selection phase (before Act)
- Requires >= 1 reroll energy
- Uses the same energy pool as dice rerolls

### DiceFaceItem Consume Details

1. Create `DiceResult` via `DiceResult.new(digit, element, false)`, then set `.source = null`, `.node = null` (matching the existing 3-arg `_init` constructor)
2. Append to player dice result list via `ctx.player_results`
3. Re-run `DiceMatcher` to update matched spells
4. Refresh spell detail panels
5. Virtual die appears in dice area (see Visual Feedback)
6. Virtual die cleaned up in `_turn()` before `_roll_players()` rebuilds `_player_results` for the next turn. The virtual `DiceResult` nodes (visual) are freed, and since `_player_results` is rebuilt from scratch each turn, the virtual results naturally disappear from the data.

### HealthPotion Consume Details

1. Call `ally_heal_all.Do()` directly with power 30 on all alive player mobs (bypasses SpellLogic.execute, no MatchedSpell needed beyond a stub)
2. Healing numbers float above each healed ally (reuses existing `get_damage_heal` visual path)

## 5. Visual Feedback

### DiceFaceItem — Virtual Die in Dice Area

**Creation:** `DiceFaceItem.consume()` is responsible for creating the virtual die visual node (a simple `Control` or `Label` showing element symbol + digit). It adds the node as a child of the player dice row container in the combat scene (accessed via `ctx.combat_node`). The combat script maintains a `_virtual_dice_nodes: Array[Node]` list to track all virtual die nodes created during the current turn.

**Appearance:** Visually distinct via `modulate` (e.g., semi-transparent or tinted) — no shaders. Shows element symbol + digit value. Non-interactive (can't be selected for reroll).

**Cleanup:** In `_turn()`, before `_roll_players()`, the combat script iterates `_virtual_dice_nodes`, calls `queue_free()` on each, and clears the array. This ensures virtual dice are removed before the next turn's dice are rolled.

### DiceFaceItem — Announcement

- Floating label near center screen: "[Element Symbol] +[Digit]!" in element's color
- Fades out after ~1 second
- Reuses style of existing `SpellAnnotation` / `PhaseAnnotation` labels

### HealthPotion — Feedback

- Healing numbers via existing `get_damage_heal` path
- "Health Potion!" displayed in `SpellName` label area

### Confirmation Popup (`Prototyping/HUD/ItemConfirmPopup/item_confirm_popup.tscn` + `.gd`)

- Small `PanelContainer` with item name, cost text, Use/Cancel buttons
- Appears near the clicked inventory slot, clamped to viewport bounds
- Dismisses on Use, Cancel, or clicking outside

## 6. ally_heal_all Spell Logic

### New File: `Source/SpellLogics/ally_heal_all.gd`

Does NOT extend `PickAllAllies` (since that base returns all allies including dead). Instead, implements its own `PickTarget` that filters to alive allies only:

- `PickTarget(ctx)` — returns `ctx.allies.filter(func(m): return m.is_alive())`
- `Do(ctx)` — for each target: `mob.get_damage_heal(DamageInfo.new(ctx.power, Consts.DamageType.Healing))`

When called from HealthPotion's `consume()`, the caller sets `ctx.targets` to alive players directly (pre-filtered), so `PickTarget` is only relevant if this logic is reused by a spell in the future.

## 7. File Change Summary

### New Files

| File | Purpose |
|------|---------|
| `Source/Core/Structs/item.gd` | Base Item resource class with `CombatConsumeContext` |
| `Source/Core/Structs/health_potion_item.gd` | HealthPotion extending Item |
| `Source/SpellLogics/ally_heal_all.gd` | Heal all alive allies logic (own PickTarget, no PickAllAllies base) |
| `Prototyping/HUD/InventoryGrid/inventory_grid.tscn` + `.gd` | Reusable inventory grid (hidden when empty) |
| `Prototyping/Screens/TeamOverview/team_overview.tscn` + `.gd` | Team overview screen |
| `Prototyping/HUD/ItemConfirmPopup/item_confirm_popup.tscn` + `.gd` | Use confirmation popup |

### Modified Files

| File | Change |
|------|--------|
| `Source/Core/Structs/dice_face_item.gd` | Extend Item, add `create_icon()` and `consume()` |
| `Source/Core/game_state.gd` | Inventory typed as `Array[Item]`, `add_item`/`remove_item` signatures accept `Item` |
| `Prototyping/combat.gd` | Item consumption via `CombatConsumeContext`, virtual dice append/cleanup in `_turn()`, spell re-matching |
| `Prototyping/HUD/combat_hud.gd` | Add inventory grid, confirmation flow, energy update, phase gating |
| `Prototyping/Screens/Combat/CombatScreen.tscn` | Add InventoryGrid node at bottom-right |
| `Prototyping/Screens/WorldMap/world_map.gd` + `.tscn` | Add "Team" button |
| `Prototyping/Screens/Village/shop_panel.gd` | Add `is DiceFaceItem` checks |
| `Prototyping/Screens/Village/forge_panel.gd` | Add `is DiceFaceItem` checks |

### Unchanged

- `DiceMatcher` — receives dice results, agnostic to source
- Existing spell logics — untouched
- `RewardScreen` — still generates DiceFaceItems
