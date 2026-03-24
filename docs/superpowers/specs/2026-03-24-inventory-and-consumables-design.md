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
- `consume(combat_context) -> void` — virtual, overridden by subclasses

No `Texture2D` icon field. Each subclass owns its visual via `create_icon()`:
- `DiceFaceItem` returns a mini die-face styled node (element symbol + digit)
- `HealthPotionItem` returns a `TextureRect` (swappable to animated later)

### DiceFaceItem Refactor (`Source/Core/Structs/dice_face_item.gd`)

Refactored to extend `Item`:
- Keeps existing fields: `element`, `digit`, `sell_value`, `buy_value`
- `is_consumable_in_combat = true`
- `create_icon()` — renders element symbol + digit as a die face
- `consume()` — creates a `DiceResult(digit, element, is_extreme=false, source=null, node=null)`, appends to player dice results, triggers spell re-matching

### HealthPotionItem (`Source/Core/Structs/health_potion_item.gd`)

Extends `Item`:
- `is_consumable_in_combat = true`
- `power: int = 30`
- `create_icon()` — returns a `TextureRect` with potion texture
- `consume()` — runs `ally_heal_all` spell logic with power 30 on all alive player mobs

### GameState Inventory Change

`GameState.inventory` changes from `Array[DiceFaceItem]` to `Array[Item]`. Forge and shop code adds `is DiceFaceItem` type checks where dice-face-specific fields are needed.

## 2. Inventory Grid Component

### InventoryGrid (`Prototyping/HUD/InventoryGrid/inventory_grid.tscn` + `.gd`)

Reusable `GridContainer`-based component:
- Fixed cell size: ~24x24 per slot (fits 640x360 viewport)
- Reads from `GameState.inventory`
- Calls `item.create_icon()` for each cell
- Emits `item_clicked(item: Item)` signal
- `refresh()` method to rebuild when inventory changes
- Optional `filter: Callable` property for context-specific filtering (e.g., combat shows only `is_consumable_in_combat` items)

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
2. Confirmation popup appears near the item: "Use [item name]? Costs 1 reroll energy" with "Use" / "Cancel" buttons
3. On confirm:
   - Deduct 1 reroll energy
   - Remove item from `GameState.inventory`
   - Call `item.consume(combat_context)`
   - Refresh inventory grid and energy display
4. On cancel: nothing happens

### Constraints

- Only usable during player dice selection phase (before Act)
- Requires >= 1 reroll energy
- Uses the same energy pool as dice rerolls

### DiceFaceItem Consume Details

1. Create `DiceResult` with item's element/digit, `source = null` (same as env die), `is_extreme = false`
2. Append to player dice result list
3. Re-run `DiceMatcher` to update matched spells
4. Refresh spell detail panels
5. Virtual die appears in dice area (see Visual Feedback)
6. Virtual die removed at end of turn

### HealthPotion Consume Details

1. Run `ally_heal_all` logic with power 30 on all alive player mobs
2. Healing numbers float above each healed ally (reuses existing `get_damage_heal` visual path)

## 5. Visual Feedback

### DiceFaceItem — Virtual Die in Dice Area

- A static die-face node appears in the player dice row
- Visually distinct via `modulate` (e.g., semi-transparent or tinted) — no shaders
- Shows element symbol + digit value
- Non-interactive (can't be selected for reroll)
- Removed at end of turn

### DiceFaceItem — Announcement

- Floating label near center screen: "[Element Symbol] +[Digit]!" in element's color
- Fades out after ~1 second
- Reuses style of existing `SpellAnnotation` / `PhaseAnnotation` labels

### HealthPotion — Feedback

- Healing numbers via existing `get_damage_heal` path
- "Health Potion!" displayed in `SpellName` label area

### Confirmation Popup (`Prototyping/HUD/ItemConfirmPopup/item_confirm_popup.tscn` + `.gd`)

- Small `PanelContainer` with item name, cost text, Use/Cancel buttons
- Appears near the clicked inventory slot
- Dismisses on Use, Cancel, or clicking outside

## 6. ally_heal_all Spell Logic

### New File: `Source/SpellLogics/ally_heal_all.gd`

Extends `PickAllAllies` base:
- `PickTarget(ctx)` — returns all alive allies (filters dead from `ctx.allies`)
- `Do(ctx)` — for each target: `mob.get_damage_heal(DamageInfo.new(ctx.power, Consts.DamageType.Healing))`

Nearly identical to `caster_heal.gd` but targets all alive allies instead of just casters.

Used by HealthPotion's `consume()` which creates a `SpellContext` with `power=30`, `allies=all player mobs`.

## 7. File Change Summary

### New Files

| File | Purpose |
|------|---------|
| `Source/Core/Structs/item.gd` | Base Item resource class |
| `Source/Core/Structs/health_potion_item.gd` | HealthPotion extending Item |
| `Source/SpellLogics/ally_heal_all.gd` | Heal all alive allies logic |
| `Prototyping/HUD/InventoryGrid/inventory_grid.tscn` + `.gd` | Reusable inventory grid |
| `Prototyping/Screens/TeamOverview/team_overview.tscn` + `.gd` | Team overview screen |
| `Prototyping/HUD/ItemConfirmPopup/item_confirm_popup.tscn` + `.gd` | Use confirmation popup |

### Modified Files

| File | Change |
|------|--------|
| `Source/Core/Structs/dice_face_item.gd` | Extend Item, add `create_icon()` and `consume()` |
| `Source/Core/game_state.gd` | Inventory typed as `Array[Item]` |
| `Prototyping/combat.gd` | Item consumption, virtual dice append/cleanup, spell re-matching |
| `Prototyping/HUD/combat_hud.gd` | Add inventory grid, confirmation flow, energy update |
| `Prototyping/Screens/Combat/CombatScreen.tscn` | Add InventoryGrid node at bottom-right |
| `Prototyping/Screens/WorldMap/world_map.gd` + `.tscn` | Add "Team" button |
| `Prototyping/Screens/Village/shop_panel.gd` | Add `is DiceFaceItem` checks |
| `Prototyping/Screens/Village/forge_panel.gd` | Add `is DiceFaceItem` checks |

### Unchanged

- `DiceMatcher` — receives dice results, agnostic to source
- Existing spell logics — untouched
- `RewardScreen` — still generates DiceFaceItems
