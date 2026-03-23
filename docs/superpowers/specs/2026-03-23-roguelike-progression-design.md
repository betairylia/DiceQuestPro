# DiceQuestPro — Roguelike Progression System Design

## Overview

Add a full roguelike run loop around the existing combat system: team selection → procedural world map → combat encounters → rewards → village stops → boss fights → region progression. Single-run (no meta-progression). Two demo regions.

## Architecture

**Approach:** Scene-per-Screen with a `GameState` autoload singleton as the single source of truth for run state. Each screen reads/writes `GameState`. Transitions via a `SceneTransition` autoload (fade overlay).

---

## 1. GameState Autoload

**File:** `Source/Core/game_state.gd` (autoload singleton)

**State:**
- `team: Array[MobData]` — 1-3 player characters (deep copies, mutated during run)
- `inventory: Array[DiceFaceItem]` — collected dice face items
- `gold: int` — current gold (starts 0, configurable via `STARTING_GOLD` const)
- `map: RegionMap` — the generated map
- `current_node_id: int` — player's current position
- `visited_nodes: Array[int]` — completed nodes
- `current_region_index: int` — which region the player is in
- `run_active: bool` — is a run in progress
- `pre_combat_snapshot: Array[MobData]` — deep copy of team before each combat (for retry)

**Methods:**
- `start_run(team: Array[MobData])` — deep-copy team, generate map, set initial state
- `complete_node(node_id: int)` — mark visited, reveal successors + edges
- `add_item(item: DiceFaceItem)` / `remove_item(item: DiceFaceItem)`
- `add_gold(amount: int)` / `spend_gold(amount: int) -> bool`
- `heal_team()` — restore all team members to max HP
- `apply_reforge(player: MobData, face_index: int, item: DiceFaceItem)` — replace face on both alive_dice, consume item, deduct 1 gold
- `apply_upgrade(player: MobData) -> int` — increment bonus on both alive_dice, deduct gold, return new cost
- `save_pre_combat_snapshot()` / `restore_pre_combat_snapshot()`
- `end_run() -> RunSummary`

---

## 2. New Data Structures

### DiceFaceItem (`Source/Core/Structs/dice_face_item.gd`)

A Resource representing a single dice face that can be stored in inventory, bought, sold, or used to reforge.

- `element: Consts.Elements` — e.g., Dark
- `digit: int` — e.g., 10 (determines which face index it can replace and which dice it fits on)
- `sell_value: int` — equals `digit`
- `buy_value: int` — equals `digit * 3`

### RegionConfig (`Source/Core/Structs/region_config.gd`)

A Resource defining a region's rules. Created as `.tres` files in `Prototyping/Data/Regions/`.

- `region_name: String` — display name (e.g., "黑暗森林")
- `enemy_pool: Array[MobData]` — enemies that can spawn
- `boss_encounters: Array[Array[MobData]]` — pre-defined boss fight groups (each inner array is one encounter)
- `min_enemies: int` — enemy count for early nodes
- `max_enemies: int` — enemy count for late nodes
- `enemy_health_scale: float` — multiplier on enemy HP (1.0 for region 1)
- `shop_exotic_chance: float` — chance a shop item comes from outside this region (e.g., 0.2)
- `node_count: int` — target number of nodes (10-15)

### MapNode (`Source/Core/Structs/map_node.gd`)

A single node on the world map (plain Object or RefCounted, not a Resource — runtime only).

- `id: int`
- `type: NodeType` — enum: COMBAT, BOSS, TREASURE, VILLAGE
- `position: Vector2` — normalized coords for visual layout (0-1 range)
- `successors: Array[int]` — node IDs this connects to
- `predecessors: Array[int]` — node IDs that connect here
- `region_index: int`
- `enemies: Array[MobData]` — pre-generated (for COMBAT/BOSS)
- `treasure_gold: int` — for TREASURE nodes
- `treasure_items: Array[DiceFaceItem]` — for TREASURE nodes
- `visible: bool` — can the player see this node
- `revealed_edges: bool` — can the player see connections from this node

### RegionMap (`Source/Core/Structs/region_map.gd`)

Container for the full map.

- `regions: Array[RegionConfig]`
- `nodes: Dictionary` — `{int: MapNode}`, all nodes keyed by ID
- `start_node_ids: Array[int]` — entry points

### RunSummary (`Source/Core/Structs/run_summary.gd`)

For game over screen.

- `nodes_cleared: int`
- `regions_reached: int`
- `gold_earned: int`
- `items_collected: int`

---

## 3. Map Generation

**File:** `Source/Core/map_generator.gd` — pure logic, no scene dependency.

**Algorithm:**

1. **Layer placement:** Divide region into ~3-5 layers (depth from start). Each layer has 2-4 nodes. Total target = `RegionConfig.node_count`.

2. **Edge generation:** Each node connects to 1-3 nodes in the next layer. Ensure no orphan nodes (every node has at least 1 predecessor and 1 successor, except start/end nodes).

3. **Cross-layer edges:** Add some edges that skip a layer or connect within the same layer for a free-form feel. These create the branching/intersecting paths.

4. **Region merging:** Region 2's early-layer nodes appear as successors to Region 1's late-layer nodes. No explicit boundary — seamless transition.

5. **Node type assignment:**
   - Start nodes: COMBAT (easy, `min_enemies`)
   - Last node(s) before region boundary: BOSS (uses `boss_encounters`)
   - ~1 VILLAGE per region (middle layers)
   - ~1 TREASURE per region (side paths / branch dead-ends)
   - Everything else: COMBAT

6. **Enemy scaling within region:** Enemy count interpolated from `min_enemies` (early layers) to `max_enemies` (late layers). Enemies randomly drawn from `enemy_pool`. Health scaled by `enemy_health_scale`.

7. **Visibility rules:**
   - Start nodes: visible with revealed edges
   - Other nodes: visible = false, revealed_edges = false
   - When a node is completed: all successors become visible, current node's edges become revealed
   - Node types are visible once the node is visible (per design decision C — partial reveal)

---

## 4. Screen Flow

```
StartScreen → WorldMap → Combat → RewardScreen → WorldMap → ...
                 ↓                                    ↑
              Village → Shop/Forge → WorldMap          │
                                                       │
             CombatLose → Retry (same node) ───────────┘
                       → GameOverScreen → StartScreen
```

---

## 5. Screens

### 5.1 StartScreen (`Prototyping/Screens/StartScreen/`)

- Title at top
- Scrollable grid of character cards (name, sprite placeholder, dice preview, HP)
- All available characters loaded from `Prototyping/Data/Players/*.tres`
- Click to toggle selection (max 3, no duplicates). Selected cards highlighted.
- Team preview bar at bottom showing selected characters
- "出发" (Depart) button, enabled when `team.size() >= 1`
- On depart: `GameState.start_run(team)` → transition to WorldMap

### 5.2 WorldMap (`Prototyping/Screens/WorldMap/`)

- Nodes drawn as icons by type: ⚔️=combat, 💀=boss, 📦=treasure, 🏠=village, ❓=unrevealed
- Lines connecting nodes where edges are revealed
- Selectable (reachable) nodes glow/highlight — a node is reachable if any of its predecessors is in `visited_nodes` (or it's a start node)
- Visited nodes dimmed
- Current region name at top
- Click reachable node → `GameState.current_node_id = node.id` → transition to appropriate screen based on node type

### 5.3 Combat (modified `Prototyping/Prototype.tscn`)

**Modifications to `combat.gd`:**
- Add `signal combat_won` and `signal combat_lost`
- After each phase completes: if all enemies dead → emit `combat_won`, stop turn loop
- After enemy phases: if all players dead → emit `combat_lost`, stop turn loop
- Read `playersData` and `enemiesData` from `GameState` instead of inspector exports

**Wrapper logic (in the scene or a parent script):**
- On `combat_won`: `GameState.complete_node(current_node_id)` → transition to RewardScreen
- On `combat_lost`: show defeat overlay with "重试" (Retry) and "放弃" (Give Up)
- Retry: `GameState.restore_pre_combat_snapshot()` → reload combat scene (costs nothing for now)
- Give up: `GameState.end_run()` → transition to GameOverScreen

### 5.4 RewardScreen (`Prototyping/Screens/Reward/`)

1. Display defeated enemies
2. Roll all enemies' `alive_dice` once each (reuse `RollableDice` for visual roll animation)
3. Each roll → `DiceFaceItem(element, digit)`
4. Display items as clickable cards: element icon + name + digit (e.g., "🌑 暗-10")
5. Player clicks one → `GameState.add_item(item)` → transition to WorldMap
6. "跳过" (Skip) button to take nothing → transition to WorldMap

### 5.5 VillageScreen (`Prototyping/Screens/Village/`)

Three tabs: "商店" (Shop), "锻造" (Forge), "离开" (Leave)

**Shop (`shop_panel.gd`):**
- Sell panel (left): player inventory list, each shows element icon + digit + sell price. Click → confirm → `GameState.add_gold(sell_value)`, `GameState.remove_item(item)`.
- Buy panel (right): 3-5 randomly generated `DiceFaceItem`s. ~80% from current region's enemy dice pool, ~20% from other regions. Each shows element icon + digit + buy price (digit × 3). Click → if affordable → `GameState.spend_gold(buy_value)`, `GameState.add_item(item)`.
- Gold display at top.

**Forge (`forge_panel.gd`):**
- Top: select team member (clickable portraits)
- Middle: visualize selected character's die faces (show each face slot with element icon)
- **Upgrade (强化):** Shows current bonus, cost = `5 * (current_bonus + 1)`. Button: "强化 (X金)". Applies to both `alive_dice[0]` and `alive_dice[1]`.
- **Reforge (重铸):** Select a `DiceFaceItem` from inventory → valid face slots highlight (only the face where `face_index + 1 == item.digit`, and only on dice with enough faces). Cost: 1 gold. On confirm: replace element on both `alive_dice[0]` and `alive_dice[1]`, copy `[0]` to `[1]`, consume item.

### 5.6 GameOverScreen (`Prototyping/Screens/GameOver/`)

- "游戏结束" (Game Over) title
- `RunSummary` stats: nodes cleared, regions reached, gold earned, items collected
- "再来一次" (Try Again) button → StartScreen

---

## 6. Scene Transition

**File:** `Source/Core/scene_transition.gd` + `Prototyping/Screens/SceneTransition.tscn`

Autoload with a `ColorRect` overlay. `change_scene(path: String)`:
1. Tween alpha 0 → 1 (fade to black, ~0.3s)
2. `get_tree().change_scene_to_packed(load(path))`
3. Tween alpha 1 → 0 (fade in, ~0.3s)

---

## 7. Combat Win/Lose Detection

Added to `combat.gd`:

```
func _check_win() -> bool:
    return enemies.all(func(e): return not e.is_alive())

func _check_lose() -> bool:
    return players.all(func(e): return not e.is_alive())
```

Called after each phase execution in the action flow. If either triggers, the turn loop stops and the appropriate signal is emitted.

---

## 8. Modifications to Existing Code

- **`combat.gd`**: Add `combat_won`/`combat_lost` signals, win/lose checks, read data from `GameState`
- **`project.godot`**: Register `GameState` and `SceneTransition` autoloads, change main scene to `StartScreen.tscn`
- **No changes** to `mob.gd`, `dice_matcher.gd`, `spell_logic.gd`, or any spell/data resources

---

## 9. Demo Content (2 Regions)

### Region 1: 黑暗森林 (Dark Forest)
- `enemy_pool`: GoblinBerserker, DarkCultist, PoisonToad, SkeletonArcher
- `boss_encounters`: [[StoneGolem, DarkCultist, DarkCultist]]
- `min_enemies`: 2, `max_enemies`: 4
- `enemy_health_scale`: 1.0
- `node_count`: 12

### Region 2: 冰霜山脉 (Frozen Peaks)
- `enemy_pool`: FrostWraith, ThunderHawk, SkeletonArcher, StoneGolem
- `boss_encounters`: [[FrostWraith, FrostWraith, ThunderHawk, ThunderHawk]]
- `min_enemies`: 3, `max_enemies`: 5
- `enemy_health_scale`: 1.3
- `node_count`: 12

---

## 10. File Organization

```
Source/Core/
├── game_state.gd
├── map_generator.gd
├── scene_transition.gd
├── Structs/
│   ├── dice_face_item.gd
│   ├── region_config.gd
│   ├── map_node.gd
│   ├── region_map.gd
│   └── run_summary.gd

Prototyping/
├── Screens/
│   ├── StartScreen/
│   │   ├── StartScreen.tscn
│   │   └── start_screen.gd
│   ├── WorldMap/
│   │   ├── WorldMap.tscn
│   │   ├── world_map.gd
│   │   └── map_node_view.gd
│   ├── Reward/
│   │   ├── RewardScreen.tscn
│   │   └── reward_screen.gd
│   ├── Village/
│   │   ├── VillageScreen.tscn
│   │   ├── village_screen.gd
│   │   ├── shop_panel.gd
│   │   └── forge_panel.gd
│   ├── GameOver/
│   │   ├── GameOverScreen.tscn
│   │   └── game_over_screen.gd
│   └── SceneTransition.tscn
├── Data/
│   └── Regions/
│       ├── DarkForest.tres
│       └── FrozenPeaks.tres
```

---

## 11. Configurable Constants

All tuning values as constants (in `GameState` or relevant scripts):

| Constant | Default | Location |
|----------|---------|----------|
| `STARTING_GOLD` | 0 | GameState |
| `REFORGE_COST` | 1 | GameState |
| `UPGRADE_BASE_COST` | 5 | GameState |
| `BUY_PRICE_MULTIPLIER` | 3 | GameState |
| `SHOP_ITEM_COUNT_MIN` | 3 | shop_panel.gd |
| `SHOP_ITEM_COUNT_MAX` | 5 | shop_panel.gd |
| `MAX_TEAM_SIZE` | 3 | StartScreen |
| `RETRY_COST` | 0 | GameState |
