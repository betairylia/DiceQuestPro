# Roguelike Progression System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a complete roguelike run loop — team selection, procedural world map, combat win/lose, rewards, village (shop/forge), and region progression — around the existing combat system.

**Architecture:** Scene-per-Screen with a `GameState` autoload singleton as the single source of truth. Each screen is a self-contained `.tscn` that reads/writes `GameState`. A `SceneTransition` autoload handles fade transitions between screens. Map generation is pure logic in `Source/Core/`.

**Tech Stack:** Godot 4.6, GDScript, GL Compatibility renderer, 640x360 viewport

**Spec:** `docs/superpowers/specs/2026-03-23-roguelike-progression-design.md`

---

## File Map

### New Files — Source/Core/ (pure logic, no scene dependency)

| File | Responsibility |
|------|---------------|
| `Source/Core/game_state.gd` | Autoload singleton: run state, inventory, gold, team management, reforge/upgrade |
| `Source/Core/map_generator.gd` | Procedural map generation: layers, edges, node types, enemy scaling |
| `Source/Core/scene_transition.gd` | Autoload: fade-to-black scene transitions |
| `Source/Core/Structs/dice_face_item.gd` | Resource: element + digit item for inventory/shop/reforge |
| `Source/Core/Structs/region_config.gd` | Resource: region rules (enemy pool, boss encounters, scaling) |
| `Source/Core/Structs/map_node.gd` | RefCounted: single world map node with type, edges, enemies |
| `Source/Core/Structs/region_map.gd` | RefCounted: full map container (nodes dict + start IDs) |
| `Source/Core/Structs/run_summary.gd` | RefCounted: end-of-run stats for game over screen |

### New Files — Prototyping/Screens/ (scenes + UI)

| File | Responsibility |
|------|---------------|
| `Prototyping/Screens/StartScreen/StartScreen.tscn` | Team selection scene |
| `Prototyping/Screens/StartScreen/start_screen.gd` | Load character list, handle selection, start run |
| `Prototyping/Screens/WorldMap/WorldMap.tscn` | World map scene |
| `Prototyping/Screens/WorldMap/world_map.gd` | Render map graph, handle node clicks, route to screens |
| `Prototyping/Screens/WorldMap/map_node_view.gd` | Visual representation of a single map node |
| `Prototyping/Screens/Combat/CombatScreen.tscn` | Combat wrapper scene |
| `Prototyping/Screens/Combat/combat_screen.gd` | Instantiate combat, wire signals, handle win/lose routing |
| `Prototyping/Screens/Reward/RewardScreen.tscn` | Reward screen scene |
| `Prototyping/Screens/Reward/reward_screen.gd` | Roll enemy dice, display items, handle pick |
| `Prototyping/Screens/Village/VillageScreen.tscn` | Village hub scene |
| `Prototyping/Screens/Village/village_screen.gd` | Tab switching between shop/forge/leave |
| `Prototyping/Screens/Village/shop_panel.gd` | Buy/sell UI and logic |
| `Prototyping/Screens/Village/forge_panel.gd` | Upgrade/reforge UI and logic |
| `Prototyping/Screens/GameOver/GameOverScreen.tscn` | Game over / victory scene |
| `Prototyping/Screens/GameOver/game_over_screen.gd` | Display run summary, restart button |
| `Prototyping/Screens/SceneTransition.tscn` | CanvasLayer + ColorRect for fade overlay |

### New Files — Data

| File | Responsibility |
|------|---------------|
| `Prototyping/Data/Regions/DarkForest.tres` | Region 1 config |
| `Prototyping/Data/Regions/FrozenPeaks.tres` | Region 2 config |

### Modified Files

| File | Changes |
|------|---------|
| `Source/Core/Structs/mob_data.gd` | Add `display_name: String` and `sprite: SpriteFrames` exports |
| `Prototyping/combat.gd` | Add `combat_won`/`combat_lost` signals, `init()` method, win/lose checks, remove `_ready()` auto-start |
| `project.godot` | Add `GameState` and `SceneTransition` autoloads, change main scene |

---

## Task 1: Data Structures

Create all new Resource/RefCounted data classes. These have no dependencies on other new code.

**Files:**
- Create: `Source/Core/Structs/dice_face_item.gd`
- Create: `Source/Core/Structs/region_config.gd`
- Create: `Source/Core/Structs/map_node.gd`
- Create: `Source/Core/Structs/region_map.gd`
- Create: `Source/Core/Structs/run_summary.gd`
- Modify: `Source/Core/Structs/mob_data.gd`

- [ ] **Step 1: Create DiceFaceItem resource**

```gdscript
# Source/Core/Structs/dice_face_item.gd
extends Resource
class_name DiceFaceItem

@export var element: Consts.Elements
@export var digit: int  ## Raw face position (1-indexed, ignoring bonus). digit-10 → face_index 9.

var sell_value: int:
	get: return digit
var buy_value: int:
	get: return digit * 3
```

- [ ] **Step 2: Create RegionConfig resource**

```gdscript
# Source/Core/Structs/region_config.gd
extends Resource
class_name RegionConfig

@export var region_name: String
@export var enemy_pool: Array[MobData]
@export var boss_encounters: Array  ## Each element is Array[MobData] (one encounter)
@export var min_enemies: int = 2
@export var max_enemies: int = 4
@export var enemy_health_scale: float = 1.0
@export var shop_exotic_chance: float = 0.2
@export var node_count: int = 12
```

- [ ] **Step 3: Create MapNode RefCounted**

```gdscript
# Source/Core/Structs/map_node.gd
extends RefCounted
class_name MapNode

enum NodeType { COMBAT, BOSS, TREASURE, VILLAGE }

var id: int
var type: NodeType
var position: Vector2  ## Normalized 0-1 coords for visual layout
var successors: Array[int] = []
var predecessors: Array[int] = []
var region_index: int
var enemies: Array[MobData] = []
var treasure_gold: int = 0
var treasure_items: Array[DiceFaceItem] = []
var visible: bool = false
var revealed_edges: bool = false
```

- [ ] **Step 4: Create RegionMap RefCounted**

```gdscript
# Source/Core/Structs/region_map.gd
extends RefCounted
class_name RegionMap

var regions: Array[RegionConfig] = []
var nodes: Dictionary = {}  ## {int: MapNode}
var start_node_ids: Array[int] = []

func get_node(id: int) -> MapNode:
	return nodes.get(id)
```

- [ ] **Step 5: Create RunSummary RefCounted**

```gdscript
# Source/Core/Structs/run_summary.gd
extends RefCounted
class_name RunSummary

var victory: bool = false
var nodes_cleared: int = 0
var regions_reached: int = 0
var gold_earned: int = 0
var items_collected: int = 0
```

- [ ] **Step 6: Add display_name and sprite to MobData**

Modify `Source/Core/Structs/mob_data.gd` — add two exports before existing fields:

```gdscript
extends Resource
class_name MobData

@export var display_name: String
@export var sprite: SpriteFrames
@export var max_health: int;
@export var dead: bool;
@export var alive_dice: Array[DiceData];
@export var dead_dice: Array[DiceData];
```

- [ ] **Step 7: Commit**

```bash
git add Source/Core/Structs/dice_face_item.gd Source/Core/Structs/region_config.gd Source/Core/Structs/map_node.gd Source/Core/Structs/region_map.gd Source/Core/Structs/run_summary.gd Source/Core/Structs/mob_data.gd
git commit -m "feat: add data structures for roguelike progression"
```

---

## Task 2: Scene Transition Autoload

Create the fade transition system. No dependency on other new code.

**Files:**
- Create: `Prototyping/Screens/SceneTransition.tscn`
- Create: `Source/Core/scene_transition.gd`

- [ ] **Step 1: Create SceneTransition scene**

`Prototyping/Screens/SceneTransition.tscn` — a CanvasLayer (layer 100) with a ColorRect child covering the full viewport:

```
SceneTransition (CanvasLayer)
  └── Overlay (ColorRect)
        color = Color(0, 0, 0, 0)
        anchors: full rect
        mouse_filter = MOUSE_FILTER_IGNORE
```

Attach script `Source/Core/scene_transition.gd`.

- [ ] **Step 2: Create scene_transition.gd**

```gdscript
# Source/Core/scene_transition.gd
extends CanvasLayer

const FADE_DURATION := 0.3

@onready var _overlay: ColorRect = $Overlay
var _transitioning := false


func change_scene(path: String) -> void:
	if _transitioning:
		return
	_transitioning = true

	# Fade to black
	var tween := create_tween()
	tween.tween_property(_overlay, "color:a", 1.0, FADE_DURATION)
	await tween.finished

	# Swap scene
	get_tree().change_scene_to_packed(load(path))

	# Wait one frame for new scene to initialize
	await get_tree().process_frame

	# Fade in
	var tween2 := create_tween()
	tween2.tween_property(_overlay, "color:a", 0.0, FADE_DURATION)
	await tween2.finished

	_transitioning = false
```

- [ ] **Step 3: Register autoload in project.godot**

Add to `[autoload]` section:

```ini
SceneTransition="*res://Prototyping/Screens/SceneTransition.tscn"
```

- [ ] **Step 4: Verify the scene loads**

Open Godot editor (or run `godot --headless --quit` if available) to verify no parse errors.

- [ ] **Step 5: Commit**

```bash
git add Prototyping/Screens/SceneTransition.tscn Source/Core/scene_transition.gd project.godot
git commit -m "feat: add SceneTransition autoload with fade effect"
```

---

## Task 3: Map Generator

Pure logic — generates the full map graph from an array of RegionConfigs. No scene dependency.

**Files:**
- Create: `Source/Core/map_generator.gd`

- [ ] **Step 1: Create map_generator.gd**

```gdscript
# Source/Core/map_generator.gd
extends RefCounted
class_name MapGenerator

## Generate a full RegionMap from an array of RegionConfigs.
static func generate(regions: Array[RegionConfig]) -> RegionMap:
	var map := RegionMap.new()
	map.regions = regions
	var next_id := 0
	var prev_region_end_ids: Array[int] = []

	for region_idx in regions.size():
		var config := regions[region_idx]
		var layers: Array[Array] = _generate_layers(config, region_idx, next_id)

		# Register all nodes
		for layer in layers:
			for node: MapNode in layer:
				map.nodes[node.id] = node
				next_id = max(next_id, node.id + 1)

		# Connect layers with edges
		_connect_layers(layers)

		# Add cross-layer edges for free-form feel
		_add_cross_edges(layers)

		# Assign node types
		_assign_types(layers, config, region_idx == regions.size() - 1)

		# Generate enemies for combat/boss nodes
		_populate_enemies(layers, config)

		# Connect to previous region
		if prev_region_end_ids.is_empty():
			# First region — start nodes
			for node: MapNode in layers[0]:
				map.start_node_ids.append(node.id)
				node.visible = true
				node.revealed_edges = true
		else:
			# Merge: previous region's end nodes → this region's first layer
			for prev_id in prev_region_end_ids:
				var prev_node: MapNode = map.nodes[prev_id]
				for node: MapNode in layers[0]:
					if prev_node.id not in node.predecessors:
						prev_node.successors.append(node.id)
						node.predecessors.append(prev_node.id)

		# Track end of this region (last layer)
		prev_region_end_ids.clear()
		for node: MapNode in layers[-1]:
			prev_region_end_ids.append(node.id)

	return map


static func _generate_layers(config: RegionConfig, region_idx: int, start_id: int) -> Array[Array]:
	var target := config.node_count
	# Determine layer count: aim for 3-5 layers
	var layer_count := clampi(target / 3, 3, 5)
	var layers: Array[Array] = []
	var id := start_id
	var nodes_placed := 0

	for layer_idx in layer_count:
		var remaining_layers := layer_count - layer_idx
		var remaining_nodes := target - nodes_placed
		# Distribute remaining nodes across remaining layers (2-4 per layer)
		var count := clampi(roundi(float(remaining_nodes) / remaining_layers), 2, 4)
		if layer_idx == layer_count - 1:
			count = clampi(remaining_nodes, 1, 4)

		var layer: Array = []
		for j in count:
			var node := MapNode.new()
			node.id = id
			id += 1
			node.region_index = region_idx
			# Position: x = layer progress (0-1), y = spread within layer
			var x_norm: float = float(layer_idx) / max(layer_count - 1, 1)
			var y_norm: float = float(j) / max(count - 1, 1) if count > 1 else 0.5
			node.position = Vector2(x_norm, y_norm)
			layer.append(node)

		layers.append(layer)
		nodes_placed += count

	return layers


static func _connect_layers(layers: Array[Array]) -> void:
	for i in range(layers.size() - 1):
		var current: Array = layers[i]
		var next_layer: Array = layers[i + 1]

		# Ensure every node in current connects to at least 1 in next
		for node: MapNode in current:
			var target: MapNode = next_layer[randi() % next_layer.size()]
			_add_edge(node, target)

		# Ensure every node in next has at least 1 predecessor
		for target: MapNode in next_layer:
			if target.predecessors.is_empty():
				var source: MapNode = current[randi() % current.size()]
				_add_edge(source, target)

		# Add 0-2 extra edges for branching
		var extra := randi_range(0, 2)
		for _e in extra:
			var source: MapNode = current[randi() % current.size()]
			var target: MapNode = next_layer[randi() % next_layer.size()]
			_add_edge(source, target)


static func _add_cross_edges(layers: Array[Array]) -> void:
	# Skip-layer edges (layer i → layer i+2) — sparse
	for i in range(layers.size() - 2):
		if randf() < 0.3:
			var source: MapNode = layers[i][randi() % layers[i].size()]
			var target: MapNode = layers[i + 2][randi() % layers[i + 2].size()]
			_add_edge(source, target)


static func _add_edge(from: MapNode, to: MapNode) -> void:
	if to.id not in from.successors:
		from.successors.append(to.id)
	if from.id not in to.predecessors:
		to.predecessors.append(from.id)


static func _assign_types(layers: Array[Array], config: RegionConfig, is_last_region: bool) -> void:
	# Default all to COMBAT
	for layer in layers:
		for node: MapNode in layer:
			node.type = MapNode.NodeType.COMBAT

	# Last layer = BOSS (pick one node if multiple)
	var last_layer: Array = layers[-1]
	last_layer[0].type = MapNode.NodeType.BOSS

	# Village: middle layer, pick one node
	if layers.size() >= 3:
		var mid := layers.size() / 2
		var village_layer: Array = layers[mid]
		village_layer[randi() % village_layer.size()].type = MapNode.NodeType.VILLAGE

	# Treasure: pick a node from an early-mid layer that isn't already special
	if layers.size() >= 3:
		var treasure_layer_idx := randi_range(1, max(layers.size() - 2, 1))
		var candidates: Array = layers[treasure_layer_idx].filter(
			func(n: MapNode): return n.type == MapNode.NodeType.COMBAT
		)
		if not candidates.is_empty():
			candidates[randi() % candidates.size()].type = MapNode.NodeType.TREASURE


static func _populate_enemies(layers: Array[Array], config: RegionConfig) -> void:
	var total_layers := layers.size()
	for layer_idx in total_layers:
		var progress: float = float(layer_idx) / max(total_layers - 1, 1)
		var enemy_count := roundi(lerpf(config.min_enemies, config.max_enemies, progress))

		for node: MapNode in layers[layer_idx]:
			match node.type:
				MapNode.NodeType.COMBAT:
					node.enemies = _pick_enemies(config, enemy_count)
				MapNode.NodeType.BOSS:
					if config.boss_encounters.size() > 0:
						var encounter: Array = config.boss_encounters[randi() % config.boss_encounters.size()]
						node.enemies = _duplicate_mob_array(encounter, config.enemy_health_scale)
					else:
						node.enemies = _pick_enemies(config, config.max_enemies)
				MapNode.NodeType.TREASURE:
					# Generate 1-3 treasure items + some gold
					node.treasure_gold = randi_range(5, 15)
					for _i in randi_range(1, 3):
						node.treasure_items.append(_random_item_from_pool(config.enemy_pool))
				MapNode.NodeType.VILLAGE:
					pass  # No enemies


static func _pick_enemies(config: RegionConfig, count: int) -> Array[MobData]:
	var result: Array[MobData] = []
	for _i in count:
		var template: MobData = config.enemy_pool[randi() % config.enemy_pool.size()]
		var dup: MobData = template.duplicate(true)
		dup.max_health = roundi(dup.max_health * config.enemy_health_scale)
		result.append(dup)
	return result


static func _duplicate_mob_array(arr: Array, health_scale: float) -> Array[MobData]:
	var result: Array[MobData] = []
	for mob: MobData in arr:
		var dup: MobData = mob.duplicate(true)
		dup.max_health = roundi(dup.max_health * health_scale)
		result.append(dup)
	return result


static func _random_item_from_pool(pool: Array[MobData]) -> DiceFaceItem:
	var mob: MobData = pool[randi() % pool.size()]
	if mob.alive_dice.is_empty():
		var item := DiceFaceItem.new()
		item.element = Consts.Elements.Sword
		item.digit = 1
		return item
	var dice: DiceData = mob.alive_dice[randi() % mob.alive_dice.size()]
	var face_idx := randi() % dice.face_count()
	var item := DiceFaceItem.new()
	item.element = dice.elements[face_idx] if face_idx < dice.elements.size() else Consts.Elements.Idle
	item.digit = face_idx + 1  # Raw face position, 1-indexed
	return item
```

- [ ] **Step 2: Commit**

```bash
git add Source/Core/map_generator.gd
git commit -m "feat: add procedural map generator with layers, edges, and enemy scaling"
```

---

## Task 4: GameState Autoload

The central singleton that manages the entire run. Depends on Task 1 (data structures) and Task 3 (map generator).

**Files:**
- Create: `Source/Core/game_state.gd`
- Modify: `project.godot`

- [ ] **Step 1: Create game_state.gd**

```gdscript
# Source/Core/game_state.gd
extends Node

const STARTING_GOLD := 0
const REFORGE_COST := 1
const UPGRADE_BASE_COST := 5
const BUY_PRICE_MULTIPLIER := 3
const RETRY_COST := 0

var team: Array[MobData] = []
var inventory: Array[DiceFaceItem] = []
var gold: int = 0
var map: RegionMap
var current_node_id: int = -1
var visited_nodes: Array[int] = []
var current_region_index: int = 0
var run_active: bool = false
var pre_combat_snapshot: Array[MobData] = []
var total_gold_earned: int = 0
var total_items_collected: int = 0

var all_spells: Array[Spell] = []
var env_die: DiceData
var region_configs: Array[RegionConfig] = []


func _ready() -> void:
	_load_spells()
	_load_env_die()
	_load_regions()


func _load_spells() -> void:
	var dir := DirAccess.open("res://Prototyping/Data/Spells/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var spell = load("res://Prototyping/Data/Spells/" + file_name)
			if spell is Spell:
				all_spells.append(spell)
		file_name = dir.get_next()


func _load_env_die() -> void:
	# Standard D6 environment die: Idle, Fire, Idle, Nature, Idle, Forest
	env_die = DiceData.new()
	env_die.type = Consts.DiceType.D6
	env_die.elements = [
		Consts.Elements.Idle, Consts.Elements.Fire, Consts.Elements.Idle,
		Consts.Elements.Nature, Consts.Elements.Idle, Consts.Elements.Forest
	]


func _load_regions() -> void:
	var dir := DirAccess.open("res://Prototyping/Data/Regions/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var config = load("res://Prototyping/Data/Regions/" + file_name)
			if config is RegionConfig:
				region_configs.append(config)
		file_name = dir.get_next()


func start_run(selected_team: Array[MobData]) -> void:
	# Deep copy team
	team.clear()
	for mob_data in selected_team:
		team.append(mob_data.duplicate(true))

	inventory.clear()
	gold = STARTING_GOLD
	visited_nodes.clear()
	current_node_id = -1
	current_region_index = 0
	total_gold_earned = 0
	total_items_collected = 0
	run_active = true

	# Generate map
	map = MapGenerator.generate(region_configs)


func get_current_node() -> MapNode:
	if map and map.nodes.has(current_node_id):
		return map.nodes[current_node_id]
	return null


func complete_node(node_id: int) -> void:
	if node_id not in visited_nodes:
		visited_nodes.append(node_id)

	var node := map.get_node(node_id)
	if not node:
		return

	# Reveal successors and edges
	node.revealed_edges = true
	for succ_id in node.successors:
		var succ := map.get_node(succ_id)
		if succ:
			succ.visible = true


func is_run_complete() -> bool:
	## True if current node has no successors (final boss cleared)
	var node := get_current_node()
	return node != null and node.successors.is_empty()


func add_item(item: DiceFaceItem) -> void:
	inventory.append(item)
	total_items_collected += 1


func remove_item(item: DiceFaceItem) -> void:
	var idx := inventory.find(item)
	if idx >= 0:
		inventory.remove_at(idx)


func add_gold(amount: int) -> void:
	gold += amount
	total_gold_earned += amount


func spend_gold(amount: int) -> bool:
	if gold >= amount:
		gold -= amount
		return true
	return false


func heal_team() -> void:
	for mob_data in team:
		mob_data.dead = false


func get_upgrade_cost(player: MobData) -> int:
	if player.alive_dice.is_empty():
		return 0
	return UPGRADE_BASE_COST * (player.alive_dice[0].bonus + 1)


func apply_upgrade(player: MobData) -> int:
	var cost := get_upgrade_cost(player)
	if not spend_gold(cost):
		return -1
	player.alive_dice[0].bonus += 1
	# Copy [0] to [1] to maintain invariant
	if player.alive_dice.size() > 1:
		player.alive_dice[1] = player.alive_dice[0].duplicate(true)
	return get_upgrade_cost(player)


func apply_reforge(player: MobData, face_index: int, item: DiceFaceItem) -> void:
	if not spend_gold(REFORGE_COST):
		return
	player.alive_dice[0].elements[face_index] = item.element
	# Copy [0] to [1] to maintain invariant
	if player.alive_dice.size() > 1:
		player.alive_dice[1] = player.alive_dice[0].duplicate(true)
	remove_item(item)


func save_pre_combat_snapshot() -> void:
	pre_combat_snapshot.clear()
	for mob_data in team:
		pre_combat_snapshot.append(mob_data.duplicate(true))


func restore_pre_combat_snapshot() -> void:
	team.clear()
	for mob_data in pre_combat_snapshot:
		team.append(mob_data.duplicate(true))


func end_run(victory: bool = false) -> RunSummary:
	run_active = false
	var summary := RunSummary.new()
	summary.victory = victory
	summary.nodes_cleared = visited_nodes.size()
	summary.gold_earned = total_gold_earned
	summary.items_collected = total_items_collected
	# Count distinct regions reached
	var region_set := {}
	for node_id in visited_nodes:
		var node := map.get_node(node_id)
		if node:
			region_set[node.region_index] = true
	summary.regions_reached = region_set.size()
	return summary
```

- [ ] **Step 2: Register GameState autoload in project.godot**

Add to `[autoload]` section (after Tooltip):

```ini
GameState="*res://Source/Core/game_state.gd"
```

Note: `GameState` is a plain `.gd` autoload (extends Node), not a scene. `SceneTransition` is a `.tscn` autoload.

- [ ] **Step 3: Commit**

```bash
git add Source/Core/game_state.gd project.godot
git commit -m "feat: add GameState autoload with run management, inventory, and reforge"
```

---

## Task 5: Modify Combat for Win/Lose Detection

Add win/lose signals and the `init()` method to the existing combat system. Depends on Task 4.

**Files:**
- Modify: `Prototyping/combat.gd`

- [ ] **Step 1: Add signals and init() method to combat.gd**

Add new signals after existing ones (line ~18):

```gdscript
signal combat_won
signal combat_lost
```

Add a `_combat_ended` flag:

```gdscript
var _combat_ended: bool = false
```

Replace `_ready()` (lines 54-62) with:

```gdscript
func _ready() -> void:
	# Don't auto-start — wait for init() call from wrapper
	pass


func init(players_data: Array[MobData], enemies_data: Array[MobData], spells_data: Array[Spell], env_die_data: DiceData) -> void:
	playersData = players_data
	enemiesData = enemies_data
	spells = spells_data
	envDie = env_die_data

	env_die.setup(envDie)
	env_die.SetState(RollableDice.DiceCombatState.Determined)

	_spawn_mobs(playersData, PLAYER_MOB_SCENE, players, true)
	_spawn_mobs(enemiesData, ENEMY_MOB_SCENE, enemies, false)

	_combat_ended = false
	_turn()
```

- [ ] **Step 2: Add win/lose check methods**

```gdscript
func _check_combat_end() -> bool:
	if _combat_ended:
		return true
	if enemies.all(func(e): return not e.is_alive()):
		_combat_ended = true
		combat_won.emit()
		return true
	if players.all(func(e): return not e.is_alive()):
		_combat_ended = true
		combat_lost.emit()
		return true
	return false
```

- [ ] **Step 3: Insert checks into the action flow**

Modify `_on_combat_hud_act()` to check after each phase. Replace the method (lines 180-198):

```gdscript
func _on_combat_hud_act() -> void:
	for die in _player_dice:
		die.SetState(RollableDice.DiceCombatState.Determined)

	_enter_phase(CombatExecPhase.PlayerRegular)
	await _regular_attack(players, enemies, _player_results)
	if _check_combat_end():
		return

	_enter_phase(CombatExecPhase.PlayerSpells)
	await _resolve_spells(players, enemies, _player_matched_spells)
	if _check_combat_end():
		return

	_refresh_enemy_spells()
	_enter_phase(CombatExecPhase.EnemyRegular)
	await _regular_attack(enemies, players, _enemy_results)
	if _check_combat_end():
		return

	_enter_phase(CombatExecPhase.EnemySpells)
	await _resolve_spells(enemies, players, _enemy_matched_spells)
	if _check_combat_end():
		return

	_turn()
```

- [ ] **Step 4: Commit**

```bash
git add Prototyping/combat.gd
git commit -m "feat: add combat win/lose detection with init() method"
```

---

## Task 6: Start Screen

The first screen the player sees. Shows character selection grid. Depends on Task 4.

**Files:**
- Create: `Prototyping/Screens/StartScreen/StartScreen.tscn`
- Create: `Prototyping/Screens/StartScreen/start_screen.gd`
- Modify: `project.godot` (change main scene)

- [ ] **Step 1: Create start_screen.gd**

```gdscript
# Prototyping/Screens/StartScreen/start_screen.gd
extends Control

const MAX_TEAM_SIZE := 3

var _available: Array[MobData] = []
var _selected: Array[MobData] = []


func _ready() -> void:
	_load_characters()
	_build_grid()
	_update_depart_button()


func _load_characters() -> void:
	var dir := DirAccess.open("res://Prototyping/Data/Players/")
	if not dir:
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			var mob = load("res://Prototyping/Data/Players/" + file_name)
			if mob is MobData:
				_available.append(mob)
		file_name = dir.get_next()


func _build_grid() -> void:
	var grid: GridContainer = $MarginContainer/VBoxContainer/ScrollContainer/Grid
	for child in grid.get_children():
		child.queue_free()

	for mob_data in _available:
		var card := _create_card(mob_data)
		grid.add_child(card)


func _create_card(mob_data: MobData) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(120, 80)

	var vbox := VBoxContainer.new()
	panel.add_child(vbox)

	var name_label := Label.new()
	var display := mob_data.display_name if mob_data.display_name != "" else "???"
	name_label.text = display
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	var hp_label := Label.new()
	hp_label.text = "HP: %d" % mob_data.max_health
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hp_label)

	var dice_label := RichTextLabel.new()
	dice_label.bbcode_enabled = true
	dice_label.fit_content = true
	dice_label.scroll_active = false
	if not mob_data.alive_dice.is_empty():
		dice_label.text = Consts.dice_face_preview(mob_data.alive_dice[0])
	vbox.add_child(dice_label)

	panel.gui_input.connect(_on_card_input.bind(mob_data, panel))
	return panel


func _on_card_input(event: InputEvent, mob_data: MobData, panel: PanelContainer) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if mob_data in _selected:
			_selected.erase(mob_data)
			_style_card(panel, false)
		elif _selected.size() < MAX_TEAM_SIZE:
			_selected.append(mob_data)
			_style_card(panel, true)
		_update_depart_button()
		_update_team_preview()


func _style_card(panel: PanelContainer, selected: bool) -> void:
	if selected:
		panel.modulate = Color(0.7, 1.0, 0.7)
	else:
		panel.modulate = Color.WHITE


func _update_depart_button() -> void:
	var btn: Button = $MarginContainer/VBoxContainer/DepartButton
	btn.disabled = _selected.is_empty()
	btn.text = "出发 (%d/%d)" % [_selected.size(), MAX_TEAM_SIZE]


func _update_team_preview() -> void:
	var preview: HBoxContainer = $MarginContainer/VBoxContainer/TeamPreview
	for child in preview.get_children():
		child.queue_free()
	for mob_data in _selected:
		var label := Label.new()
		label.text = mob_data.display_name if mob_data.display_name != "" else "???"
		preview.add_child(label)


func _on_depart_button_pressed() -> void:
	if _selected.is_empty():
		return
	GameState.start_run(_selected)
	SceneTransition.change_scene("res://Prototyping/Screens/WorldMap/WorldMap.tscn")
```

- [ ] **Step 2: Create StartScreen.tscn**

Build the scene tree programmatically or in editor. Structure:

```
StartScreen (Control) — script: start_screen.gd
  └── MarginContainer (anchors: full rect, margins: 10)
       └── VBoxContainer
            ├── TitleLabel (Label) — text: "DiceQuestPro", h_align: center, font_size: 24
            ├── ScrollContainer (size_flags_vertical: EXPAND_FILL)
            │    └── Grid (GridContainer) — columns: 4
            ├── TeamPreview (HBoxContainer) — alignment: center, min_height: 30
            └── DepartButton (Button) — text: "出发 (0/3)", disabled: true
```

All anchors on root Control: full rect. Connect `DepartButton.pressed` to `_on_depart_button_pressed`.

- [ ] **Step 3: Update project.godot main scene**

Change `run/main_scene` to point to StartScreen:

```ini
run/main_scene="res://Prototyping/Screens/StartScreen/StartScreen.tscn"
```

Note: Godot 4.6 uses UIDs for main_scene. You may need to find the UID or use the path directly. If the engine expects a UID, open in editor to set it, or use the file path format.

- [ ] **Step 4: Commit**

```bash
git add Prototyping/Screens/StartScreen/ project.godot
git commit -m "feat: add StartScreen for team selection"
```

---

## Task 7: World Map Screen

Renders the procedural map and handles node selection. Depends on Tasks 4, 5.

**Files:**
- Create: `Prototyping/Screens/WorldMap/WorldMap.tscn`
- Create: `Prototyping/Screens/WorldMap/world_map.gd`
- Create: `Prototyping/Screens/WorldMap/map_node_view.gd`

- [ ] **Step 1: Create map_node_view.gd**

```gdscript
# Prototyping/Screens/WorldMap/map_node_view.gd
extends Control
class_name MapNodeView

signal node_clicked(node_id: int)

const TYPE_LABELS := {
	MapNode.NodeType.COMBAT:   "Combat",
	MapNode.NodeType.BOSS:     "BOSS",
	MapNode.NodeType.TREASURE: "Treasure",
	MapNode.NodeType.VILLAGE:  "Village",
}

const TYPE_COLORS := {
	MapNode.NodeType.COMBAT:   Color(0.8, 0.3, 0.3),
	MapNode.NodeType.BOSS:     Color(0.9, 0.1, 0.1),
	MapNode.NodeType.TREASURE: Color(0.9, 0.8, 0.2),
	MapNode.NodeType.VILLAGE:  Color(0.3, 0.8, 0.3),
}

var map_node: MapNode
var reachable: bool = false
var visited: bool = false

@onready var _label: Label = $Label
@onready var _bg: ColorRect = $Background


func setup(node: MapNode, is_reachable: bool, is_visited: bool) -> void:
	map_node = node
	reachable = is_reachable
	visited = is_visited
	_update_visuals()


func _update_visuals() -> void:
	if not map_node:
		return

	_label.text = TYPE_LABELS.get(map_node.type, "?")

	var base_color: Color = TYPE_COLORS.get(map_node.type, Color.GRAY)

	if visited:
		_bg.color = base_color.darkened(0.6)
		_label.modulate = Color(1, 1, 1, 0.4)
	elif reachable:
		_bg.color = base_color
		_label.modulate = Color.WHITE
	else:
		_bg.color = Color(0.3, 0.3, 0.3)
		_label.modulate = Color(1, 1, 1, 0.6)


func _gui_input(event: InputEvent) -> void:
	if reachable and not visited:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			node_clicked.emit(map_node.id)
```

- [ ] **Step 2: Create world_map.gd**

```gdscript
# Prototyping/Screens/WorldMap/world_map.gd
extends Control

const MAP_NODE_VIEW_SCENE = preload("res://Prototyping/Screens/WorldMap/MapNodeView.tscn")

# Map display area within 640x360 viewport
const MAP_MARGIN := Vector2(40, 50)
const MAP_SIZE := Vector2(560, 260)

var _node_views: Dictionary = {}  ## {int: MapNodeView}


func _ready() -> void:
	_build_map()


func _build_map() -> void:
	var map := GameState.map
	if not map:
		return

	# Update region label
	$RegionLabel.text = _get_current_region_name()

	# Gold display
	$GoldLabel.text = "Gold: %d" % GameState.gold

	# Create node views
	for node_id in map.nodes:
		var node: MapNode = map.nodes[node_id]
		if not node.visible:
			continue

		var is_reachable := _is_reachable(node)
		var is_visited := node_id in GameState.visited_nodes

		var view: MapNodeView = MAP_NODE_VIEW_SCENE.instantiate()
		view.position = MAP_MARGIN + node.position * MAP_SIZE
		$Nodes.add_child(view)
		view.setup(node, is_reachable, is_visited)
		view.node_clicked.connect(_on_node_clicked)
		_node_views[node_id] = view

	# Draw edges
	$Edges.queue_redraw()


func _get_current_region_name() -> String:
	if GameState.map and not GameState.map.regions.is_empty():
		var idx := clampi(GameState.current_region_index, 0, GameState.map.regions.size() - 1)
		return GameState.map.regions[idx].region_name
	return ""


func _is_reachable(node: MapNode) -> bool:
	if node.id in GameState.visited_nodes:
		return false
	# Start nodes: reachable if no start node visited yet
	if node.id in GameState.map.start_node_ids:
		for sid in GameState.map.start_node_ids:
			if sid in GameState.visited_nodes:
				return false
		return true
	# Regular: reachable if any predecessor visited
	for pred_id in node.predecessors:
		if pred_id in GameState.visited_nodes:
			return true
	return false


func _on_node_clicked(node_id: int) -> void:
	GameState.current_node_id = node_id
	var node: MapNode = GameState.map.get_node(node_id)
	if not node:
		return

	# Update region index
	GameState.current_region_index = node.region_index

	match node.type:
		MapNode.NodeType.COMBAT, MapNode.NodeType.BOSS:
			GameState.save_pre_combat_snapshot()
			SceneTransition.change_scene("res://Prototyping/Screens/Combat/CombatScreen.tscn")
		MapNode.NodeType.VILLAGE:
			GameState.complete_node(node_id)
			GameState.heal_team()
			SceneTransition.change_scene("res://Prototyping/Screens/Village/VillageScreen.tscn")
		MapNode.NodeType.TREASURE:
			_collect_treasure(node)


func _collect_treasure(node: MapNode) -> void:
	GameState.add_gold(node.treasure_gold)
	for item in node.treasure_items:
		GameState.add_item(item)
	GameState.complete_node(node.id)
	# Refresh map
	_clear_map()
	_build_map()


func _clear_map() -> void:
	for child in $Nodes.get_children():
		child.queue_free()
	_node_views.clear()


func _draw_edges() -> void:
	# Called by Edges node's _draw
	pass
```

- [ ] **Step 3: Create WorldMap.tscn**

Scene structure:

```
WorldMap (Control) — script: world_map.gd, anchors: full rect
  ├── Background (ColorRect) — color: dark gray, anchors: full rect
  ├── RegionLabel (Label) — position: top center, text: ""
  ├── GoldLabel (Label) — position: top right
  ├── Edges (Node2D) — for drawing connection lines
  └── Nodes (Control) — container for MapNodeView instances
```

- [ ] **Step 4: Create MapNodeView.tscn**

Scene structure:

```
MapNodeView (Control) — script: map_node_view.gd, size: 50x30
  ├── Background (ColorRect) — anchors: full rect
  └── Label — anchors: full rect, h_align: center, v_align: center, font_size: 8
```

Set `mouse_filter = MOUSE_FILTER_STOP` on root Control so `_gui_input` fires.

- [ ] **Step 5: Add edge drawing**

In `world_map.gd`, add a method that draws lines between connected visible nodes. Use the `Edges` Node2D's `_draw()` by subclassing or connecting. Simpler approach: override `_draw()` on the WorldMap Control itself using `_node_views` positions.

Add to `world_map.gd`:

```gdscript
func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var map := GameState.map
	if not map:
		return
	for node_id in _node_views:
		var node: MapNode = map.nodes[node_id]
		if not node.revealed_edges:
			continue
		var from_view: MapNodeView = _node_views[node_id]
		var from_pos: Vector2 = from_view.position + from_view.size / 2
		for succ_id in node.successors:
			if succ_id in _node_views:
				var to_view: MapNodeView = _node_views[succ_id]
				var to_pos: Vector2 = to_view.position + to_view.size / 2
				draw_line(from_pos, to_pos, Color(0.5, 0.5, 0.5, 0.7), 1.5)
```

- [ ] **Step 6: Commit**

```bash
git add Prototyping/Screens/WorldMap/
git commit -m "feat: add WorldMap screen with node rendering and navigation"
```

---

## Task 8: Combat Screen Wrapper

Thin wrapper that loads the existing combat scene with data from GameState and handles routing on win/lose.

**Files:**
- Create: `Prototyping/Screens/Combat/CombatScreen.tscn`
- Create: `Prototyping/Screens/Combat/combat_screen.gd`

- [ ] **Step 1: Create combat_screen.gd**

```gdscript
# Prototyping/Screens/Combat/combat_screen.gd
extends Control

const COMBAT_SCENE = preload("res://Prototyping/Prototype.tscn")

var _combat: Combat
var _defeat_overlay: PanelContainer


func _ready() -> void:
	_combat = COMBAT_SCENE.instantiate()
	add_child(_combat)

	# Wire signals
	_combat.combat_won.connect(_on_combat_won)
	_combat.combat_lost.connect(_on_combat_lost)

	# Get data from GameState
	var node: MapNode = GameState.get_current_node()
	if not node:
		return

	_combat.init(
		GameState.team,
		node.enemies,
		GameState.all_spells,
		GameState.env_die
	)


func _on_combat_won() -> void:
	GameState.complete_node(GameState.current_node_id)
	# Short delay before transition
	await get_tree().create_timer(1.0).timeout

	if GameState.is_run_complete():
		# Victory — still show reward first, then game over
		SceneTransition.change_scene("res://Prototyping/Screens/Reward/RewardScreen.tscn")
	else:
		SceneTransition.change_scene("res://Prototyping/Screens/Reward/RewardScreen.tscn")


func _on_combat_lost() -> void:
	await get_tree().create_timer(1.0).timeout
	_show_defeat_overlay()


func _show_defeat_overlay() -> void:
	_defeat_overlay = PanelContainer.new()
	_defeat_overlay.anchor_left = 0.25
	_defeat_overlay.anchor_right = 0.75
	_defeat_overlay.anchor_top = 0.3
	_defeat_overlay.anchor_bottom = 0.7

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	_defeat_overlay.add_child(vbox)

	var title := Label.new()
	title.text = "战败"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var retry_btn := Button.new()
	retry_btn.text = "重试"
	retry_btn.pressed.connect(_on_retry)
	vbox.add_child(retry_btn)

	var quit_btn := Button.new()
	quit_btn.text = "放弃"
	quit_btn.pressed.connect(_on_give_up)
	vbox.add_child(quit_btn)

	add_child(_defeat_overlay)


func _on_retry() -> void:
	GameState.restore_pre_combat_snapshot()
	SceneTransition.change_scene("res://Prototyping/Screens/Combat/CombatScreen.tscn")


func _on_give_up() -> void:
	var _summary := GameState.end_run(false)
	SceneTransition.change_scene("res://Prototyping/Screens/GameOver/GameOverScreen.tscn")
```

- [ ] **Step 2: Create CombatScreen.tscn**

Minimal scene — just a Control node with `combat_screen.gd` attached, anchors full rect.

```
CombatScreen (Control) — script: combat_screen.gd, anchors: full rect
```

The script instantiates the actual combat scene as a child in `_ready()`.

- [ ] **Step 3: Commit**

```bash
git add Prototyping/Screens/Combat/
git commit -m "feat: add CombatScreen wrapper with win/lose routing"
```

---

## Task 9: Reward Screen

Shows rolled enemy dice as items, lets player pick one. Depends on Tasks 4, 5.

**Files:**
- Create: `Prototyping/Screens/Reward/RewardScreen.tscn`
- Create: `Prototyping/Screens/Reward/reward_screen.gd`

- [ ] **Step 1: Create reward_screen.gd**

```gdscript
# Prototyping/Screens/Reward/reward_screen.gd
extends Control

var _items: Array[DiceFaceItem] = []
var _item_buttons: Array[Button] = []


func _ready() -> void:
	_generate_items()
	_display_items()


func _generate_items() -> void:
	var node: MapNode = GameState.get_current_node()
	if not node:
		return

	for enemy_data: MobData in node.enemies:
		for dice: DiceData in enemy_data.alive_dice:
			# Roll once: random face
			var face_idx := randi() % dice.face_count()
			var element: Consts.Elements = Consts.Elements.Idle
			if face_idx < dice.elements.size():
				element = dice.elements[face_idx]

			var item := DiceFaceItem.new()
			item.element = element
			item.digit = face_idx + 1  # 1-indexed raw face position
			_items.append(item)


func _display_items() -> void:
	var grid: GridContainer = $MarginContainer/VBoxContainer/ItemGrid
	for child in grid.get_children():
		child.queue_free()
	_item_buttons.clear()

	for i in _items.size():
		var item := _items[i]
		var btn := Button.new()
		var symbol: String = Consts.SYMBOLS.get(item.element, "?")
		btn.text = "%s %d" % [symbol, item.digit]
		btn.custom_minimum_size = Vector2(80, 40)
		btn.pressed.connect(_on_item_picked.bind(i))
		grid.add_child(btn)
		_item_buttons.append(btn)


func _on_item_picked(index: int) -> void:
	GameState.add_item(_items[index])
	_go_next()


func _on_skip_pressed() -> void:
	_go_next()


func _go_next() -> void:
	if GameState.is_run_complete():
		var _summary := GameState.end_run(true)
		SceneTransition.change_scene("res://Prototyping/Screens/GameOver/GameOverScreen.tscn")
	else:
		SceneTransition.change_scene("res://Prototyping/Screens/WorldMap/WorldMap.tscn")
```

- [ ] **Step 2: Create RewardScreen.tscn**

```
RewardScreen (Control) — script: reward_screen.gd, anchors: full rect
  └── MarginContainer (anchors: full rect, margins: 20)
       └── VBoxContainer
            ├── TitleLabel (Label) — text: "战利品", h_align: center, font_size: 16
            ├── Subtitle (Label) — text: "选择一件物品", h_align: center
            ├── ItemGrid (GridContainer) — columns: 4, size_flags_v: EXPAND_FILL
            └── SkipButton (Button) — text: "跳过"
```

Connect `SkipButton.pressed` → `_on_skip_pressed`.

- [ ] **Step 3: Commit**

```bash
git add Prototyping/Screens/Reward/
git commit -m "feat: add RewardScreen with enemy dice rolling and item selection"
```

---

## Task 10: Village Screen (Shop + Forge)

The village hub with shop and forge panels. Depends on Task 4.

**Files:**
- Create: `Prototyping/Screens/Village/VillageScreen.tscn`
- Create: `Prototyping/Screens/Village/village_screen.gd`
- Create: `Prototyping/Screens/Village/shop_panel.gd`
- Create: `Prototyping/Screens/Village/forge_panel.gd`

- [ ] **Step 1: Create village_screen.gd**

```gdscript
# Prototyping/Screens/Village/village_screen.gd
extends Control

@onready var _shop_panel: Control = $Panels/ShopPanel
@onready var _forge_panel: Control = $Panels/ForgePanel


func _ready() -> void:
	_show_shop()


func _on_shop_button_pressed() -> void:
	_show_shop()


func _on_forge_button_pressed() -> void:
	_show_forge()


func _on_leave_button_pressed() -> void:
	SceneTransition.change_scene("res://Prototyping/Screens/WorldMap/WorldMap.tscn")


func _show_shop() -> void:
	_shop_panel.visible = true
	_forge_panel.visible = false
	_shop_panel.refresh()


func _show_forge() -> void:
	_shop_panel.visible = false
	_forge_panel.visible = true
	_forge_panel.refresh()
```

- [ ] **Step 2: Create shop_panel.gd**

```gdscript
# Prototyping/Screens/Village/shop_panel.gd
extends Control

const SHOP_ITEM_COUNT_MIN := 3
const SHOP_ITEM_COUNT_MAX := 5

var _shop_items: Array[DiceFaceItem] = []


func _ready() -> void:
	_generate_shop_items()


func refresh() -> void:
	_update_gold_label()
	_update_sell_list()
	_update_buy_list()


func _generate_shop_items() -> void:
	_shop_items.clear()
	var count := randi_range(SHOP_ITEM_COUNT_MIN, SHOP_ITEM_COUNT_MAX)
	var region_idx := GameState.current_region_index
	var current_config: RegionConfig = null
	if region_idx < GameState.region_configs.size():
		current_config = GameState.region_configs[region_idx]

	for _i in count:
		var use_exotic := current_config and randf() < current_config.shop_exotic_chance
		var pool: Array[MobData]

		if use_exotic and GameState.region_configs.size() > 1:
			# Pick from a different region
			var other_idx := randi() % GameState.region_configs.size()
			while other_idx == region_idx and GameState.region_configs.size() > 1:
				other_idx = randi() % GameState.region_configs.size()
			pool = GameState.region_configs[other_idx].enemy_pool
		elif current_config:
			pool = current_config.enemy_pool
		else:
			continue

		_shop_items.append(MapGenerator._random_item_from_pool(pool))


func _update_gold_label() -> void:
	$GoldLabel.text = "金币: %d" % GameState.gold


func _update_sell_list() -> void:
	var container: VBoxContainer = $SellList
	for child in container.get_children():
		child.queue_free()

	for item in GameState.inventory:
		var btn := Button.new()
		var symbol: String = Consts.SYMBOLS.get(item.element, "?")
		btn.text = "%s %d  [卖 %d金]" % [symbol, item.digit, item.sell_value]
		btn.pressed.connect(_on_sell.bind(item))
		container.add_child(btn)

	if GameState.inventory.is_empty():
		var label := Label.new()
		label.text = "(空)"
		container.add_child(label)


func _update_buy_list() -> void:
	var container: VBoxContainer = $BuyList
	for child in container.get_children():
		child.queue_free()

	for item in _shop_items:
		var btn := Button.new()
		var symbol: String = Consts.SYMBOLS.get(item.element, "?")
		btn.text = "%s %d  [买 %d金]" % [symbol, item.digit, item.buy_value]
		btn.disabled = GameState.gold < item.buy_value
		btn.pressed.connect(_on_buy.bind(item))
		container.add_child(btn)


func _on_sell(item: DiceFaceItem) -> void:
	GameState.add_gold(item.sell_value)
	GameState.remove_item(item)
	refresh()


func _on_buy(item: DiceFaceItem) -> void:
	if GameState.spend_gold(item.buy_value):
		GameState.add_item(item)
		_shop_items.erase(item)
		refresh()
```

- [ ] **Step 3: Create forge_panel.gd**

```gdscript
# Prototyping/Screens/Village/forge_panel.gd
extends Control

var _selected_player: MobData
var _selected_item: DiceFaceItem


func _ready() -> void:
	pass


func refresh() -> void:
	_selected_item = null
	_build_player_selector()
	if not _selected_player and not GameState.team.is_empty():
		_selected_player = GameState.team[0]
	_update_dice_display()
	_update_upgrade_button()
	_update_inventory_list()
	_update_gold_label()


func _update_gold_label() -> void:
	$GoldLabel.text = "金币: %d" % GameState.gold


func _build_player_selector() -> void:
	var container: HBoxContainer = $PlayerSelector
	for child in container.get_children():
		child.queue_free()

	for mob_data in GameState.team:
		var btn := Button.new()
		btn.text = mob_data.display_name if mob_data.display_name != "" else "???"
		btn.pressed.connect(_on_player_selected.bind(mob_data))
		if mob_data == _selected_player:
			btn.modulate = Color(0.7, 1.0, 0.7)
		container.add_child(btn)


func _on_player_selected(mob_data: MobData) -> void:
	_selected_player = mob_data
	_selected_item = null
	refresh()


func _update_dice_display() -> void:
	var container: GridContainer = $DiceFaces
	for child in container.get_children():
		child.queue_free()

	if not _selected_player or _selected_player.alive_dice.is_empty():
		return

	var dice: DiceData = _selected_player.alive_dice[0]
	for face_idx in dice.face_count():
		var btn := Button.new()
		var element: Consts.Elements = Consts.Elements.Idle
		if face_idx < dice.elements.size():
			element = dice.elements[face_idx]
		var symbol: String = Consts.SYMBOLS.get(element, "?")
		btn.text = "%s %d" % [symbol, face_idx + 1]
		btn.custom_minimum_size = Vector2(50, 30)

		# Highlight valid reforge targets
		if _selected_item and _selected_item.digit == face_idx + 1:
			btn.modulate = Color(1.0, 1.0, 0.5)
			btn.pressed.connect(_on_face_clicked.bind(face_idx))
		else:
			btn.disabled = _selected_item != null

		container.add_child(btn)


func _update_upgrade_button() -> void:
	var btn: Button = $UpgradeButton
	if not _selected_player:
		btn.disabled = true
		btn.text = "强化"
		return
	var cost := GameState.get_upgrade_cost(_selected_player)
	btn.text = "强化 (%d金)" % cost
	btn.disabled = GameState.gold < cost


func _update_inventory_list() -> void:
	var container: VBoxContainer = $ReforgeItems
	for child in container.get_children():
		child.queue_free()

	var header := Label.new()
	header.text = "重铸 (选择物品, 费用: %d金)" % GameState.REFORGE_COST
	container.add_child(header)

	for item in GameState.inventory:
		var btn := Button.new()
		var symbol: String = Consts.SYMBOLS.get(item.element, "?")
		btn.text = "%s %d" % [symbol, item.digit]
		btn.disabled = GameState.gold < GameState.REFORGE_COST
		if item == _selected_item:
			btn.modulate = Color(1.0, 1.0, 0.5)
		btn.pressed.connect(_on_item_selected.bind(item))
		container.add_child(btn)


func _on_item_selected(item: DiceFaceItem) -> void:
	if _selected_item == item:
		_selected_item = null  # Deselect
	else:
		_selected_item = item
	_update_dice_display()
	_update_inventory_list()


func _on_face_clicked(face_index: int) -> void:
	if not _selected_item or not _selected_player:
		return
	GameState.apply_reforge(_selected_player, face_index, _selected_item)
	_selected_item = null
	refresh()


func _on_upgrade_button_pressed() -> void:
	if not _selected_player:
		return
	GameState.apply_upgrade(_selected_player)
	refresh()
```

- [ ] **Step 4: Create VillageScreen.tscn**

```
VillageScreen (Control) — script: village_screen.gd, anchors: full rect
  ├── HBoxContainer (top bar)
  │    ├── ShopButton (Button) — text: "商店"
  │    ├── ForgeButton (Button) — text: "锻造"
  │    └── LeaveButton (Button) — text: "离开"
  └── Panels (Control) — anchors: rest of screen
       ├── ShopPanel (Control) — script: shop_panel.gd
       │    ├── GoldLabel (Label)
       │    ├── HSplitContainer
       │    │    ├── SellList (VBoxContainer) — sell items
       │    │    └── BuyList (VBoxContainer) — buy items
       └── ForgePanel (Control) — script: forge_panel.gd, visible: false
            ├── GoldLabel (Label)
            ├── PlayerSelector (HBoxContainer)
            ├── DiceFaces (GridContainer) — columns: 6
            ├── UpgradeButton (Button) — text: "强化"
            └── ReforgeItems (VBoxContainer)
```

Connect button signals:
- `ShopButton.pressed` → `_on_shop_button_pressed`
- `ForgeButton.pressed` → `_on_forge_button_pressed`
- `LeaveButton.pressed` → `_on_leave_button_pressed`
- `UpgradeButton.pressed` → `forge_panel._on_upgrade_button_pressed`

- [ ] **Step 5: Commit**

```bash
git add Prototyping/Screens/Village/
git commit -m "feat: add VillageScreen with shop (buy/sell) and forge (upgrade/reforge)"
```

---

## Task 11: Game Over Screen

Shows run summary for both defeat and victory. Depends on Task 4.

**Files:**
- Create: `Prototyping/Screens/GameOver/GameOverScreen.tscn`
- Create: `Prototyping/Screens/GameOver/game_over_screen.gd`

- [ ] **Step 1: Create game_over_screen.gd**

```gdscript
# Prototyping/Screens/GameOver/game_over_screen.gd
extends Control

# RunSummary is passed via GameState — read the last summary
var _summary: RunSummary


func _ready() -> void:
	_summary = GameState.end_run(GameState.is_run_complete()) if GameState.run_active else null
	_update_display()


func _update_display() -> void:
	var title: Label = $MarginContainer/VBoxContainer/TitleLabel

	if _summary and _summary.victory:
		title.text = "胜利!"
	else:
		title.text = "游戏结束"

	var stats: Label = $MarginContainer/VBoxContainer/StatsLabel
	if _summary:
		stats.text = "节点通过: %d\n到达区域: %d\n获得金币: %d\n收集物品: %d" % [
			_summary.nodes_cleared,
			_summary.regions_reached,
			_summary.gold_earned,
			_summary.items_collected
		]
	else:
		stats.text = ""


func _on_retry_button_pressed() -> void:
	SceneTransition.change_scene("res://Prototyping/Screens/StartScreen/StartScreen.tscn")
```

- [ ] **Step 2: Create GameOverScreen.tscn**

```
GameOverScreen (Control) — script: game_over_screen.gd, anchors: full rect
  └── MarginContainer (anchors: full rect, margins: 40)
       └── VBoxContainer (alignment: center)
            ├── TitleLabel (Label) — text: "游戏结束", h_align: center, font_size: 20
            ├── StatsLabel (Label) — h_align: center
            └── RetryButton (Button) — text: "再来一次"
```

Connect `RetryButton.pressed` → `_on_retry_button_pressed`.

- [ ] **Step 3: Commit**

```bash
git add Prototyping/Screens/GameOver/
git commit -m "feat: add GameOverScreen with run summary and victory/defeat states"
```

---

## Task 12: Region Data Files

Create the two demo region `.tres` resources. Depends on Task 1.

**Files:**
- Create: `Prototyping/Data/Regions/DarkForest.tres`
- Create: `Prototyping/Data/Regions/FrozenPeaks.tres`

- [ ] **Step 1: Create region data directory and files**

These `.tres` files reference existing enemy MobData resources. They must be created in the Godot editor (since they reference other `.tres` by UID) or via script.

Simpler approach: create a one-time editor script or create them manually in the editor. For the plan, provide the specification:

**DarkForest.tres:**
```
region_name = "黑暗森林"
enemy_pool = [GoblinBerserker, DarkCultist, PoisonToad, SkeletonArcher]
boss_encounters = [[StoneGolem, DarkCultist, DarkCultist]]
min_enemies = 2
max_enemies = 4
enemy_health_scale = 1.0
shop_exotic_chance = 0.2
node_count = 12
```

**FrozenPeaks.tres:**
```
region_name = "冰霜山脉"
enemy_pool = [FrostWraith, ThunderHawk, SkeletonArcher, StoneGolem]
boss_encounters = [[FrostWraith, FrostWraith, ThunderHawk, ThunderHawk]]
min_enemies = 3
max_enemies = 5
enemy_health_scale = 1.3
shop_exotic_chance = 0.2
node_count = 12
```

Create these via a GDScript tool script that runs in the editor, or create them by hand in the inspector.

- [ ] **Step 2: Add display_name to existing MobData .tres files**

All player and enemy `.tres` files need `display_name` set. For each file, add the property matching the filename (e.g., `Fighter.tres` → `display_name = "Fighter"`). This is best done in the editor or via a batch script:

Players: Fighter, Berserker, Cleric, Paladin, FireMage, IceSorcerer, ElfArcher, Druid, Enchanter, PaladinD10 (and any D6/D8/D12 variants)

Enemies: GoblinBerserker, DarkCultist, FrostWraith, PoisonToad, SkeletonArcher, StoneGolem, ThunderHawk

- [ ] **Step 3: Commit**

```bash
git add Prototyping/Data/Regions/ Prototyping/Data/Players/ Prototyping/Data/Enemies/
git commit -m "feat: add region configs and display_name to all MobData"
```

---

## Task 13: Integration & Polish

Wire everything together, verify the full game loop works end-to-end.

**Files:**
- Modify: `project.godot` (verify autoloads and main scene)
- Possibly fix: any scene wiring issues

- [ ] **Step 1: Verify project.godot has all autoloads**

```ini
[autoload]
Tooltip="*res://Prototyping/HUD/Tooltip/tooltip.tscn"
GameState="*res://Source/Core/game_state.gd"
SceneTransition="*res://Prototyping/Screens/SceneTransition.tscn"
```

And main scene points to StartScreen.

- [ ] **Step 2: Run the game and test the full loop**

1. Start → see character grid → select 1-3 characters → press Depart
2. World map → see start nodes → click a combat node
3. Combat → fight → win → see reward screen → pick item
4. Back to world map → more nodes visible → continue
5. Village node → shop buy/sell → forge upgrade/reforge → leave
6. Boss node → fight → win → next region or victory screen
7. Lose → retry or give up → game over screen → restart

- [ ] **Step 3: Fix any issues found during testing**

Address bugs from the end-to-end test.

- [ ] **Step 4: Final commit**

```bash
git add -A
git commit -m "feat: integrate roguelike progression - full game loop complete"
```
