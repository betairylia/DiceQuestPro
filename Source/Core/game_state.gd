extends Node

const STARTING_GOLD := 0
const REFORGE_COST := 1
const UPGRADE_BASE_COST := 5
const BUY_PRICE_MULTIPLIER := 3
const RETRY_COST := 0

var team: Array[MobData] = []
var inventory: Array[Item] = []
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
var last_run_summary: RunSummary


func _ready() -> void:
	_load_spells()
	_load_env_die()
	_load_regions()


func start_run(selected_team: Array[MobData]) -> void:
	reset_run_state()

	team.clear()
	for mob_data in selected_team:
		var duplicate := mob_data.clone()
		_prepare_player(duplicate)
		team.append(duplicate)

	gold = STARTING_GOLD
	map = MapGenerator.generate(region_configs)
	run_active = true


func set_current_node(node_id: int) -> void:
	current_node_id = node_id
	var node := get_current_node()
	if node != null:
		current_region_index = node.region_index


func get_current_node() -> MapNode:
	if map == null:
		return null
	return map.get_node(current_node_id)


func get_region_config(region_index: int) -> RegionConfig:
	if region_index < 0 or region_index >= region_configs.size():
		return null
	return region_configs[region_index]


func get_current_region() -> RegionConfig:
	return get_region_config(current_region_index)


func complete_node(node_id: int) -> void:
	if node_id not in visited_nodes:
		visited_nodes.append(node_id)

	var node := map.get_node(node_id)
	if node == null:
		return

	current_region_index = node.region_index
	node.revealed_edges = true
	for successor_id in node.successors:
		var successor := map.get_node(successor_id)
		if successor != null:
			successor.visible = true


func is_node_reachable(node_id: int) -> bool:
	if map == null:
		return false

	var node := map.get_node(node_id)
	if node == null or not node.visible or node_id in visited_nodes:
		return false

	if visited_nodes.is_empty():
		return node_id in map.start_node_ids

	for predecessor_id in node.predecessors:
		if predecessor_id in visited_nodes:
			return true
	return false


func is_run_complete() -> bool:
	var node := get_current_node()
	return node != null and node.successors.is_empty()


func add_item(item: Item) -> void:
	inventory.append(item)
	total_items_collected += 1


func remove_item(item: Item) -> void:
	var index := inventory.find(item)
	if index >= 0:
		inventory.remove_at(index)


func add_gold(amount: int) -> void:
	gold += amount
	total_gold_earned += amount


func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	return true


func heal_team() -> void:
	for player in team:
		player.dead = false
		player.current_health = player.max_health


func get_upgrade_cost(player: MobData) -> int:
	if player.alive_dice.is_empty():
		return 0
	return UPGRADE_BASE_COST * (player.alive_dice[0].bonus + 1)


func apply_reforge(player: MobData, face_index: int, item: DiceFaceItem) -> void:
	if player.alive_dice.is_empty():
		return
	if item == null or item not in inventory:
		return
	if face_index < 0 or face_index >= player.alive_dice[0].elements.size():
		return
	if item.digit != face_index + 1:
		return
	if not spend_gold(REFORGE_COST):
		return

	player.alive_dice[0].elements[face_index] = item.element
	_sync_player_dice_pair(player)
	remove_item(item)


func apply_upgrade(player: MobData) -> int:
	var cost := get_upgrade_cost(player)
	if player.alive_dice.is_empty():
		return cost
	if not spend_gold(cost):
		return cost

	player.alive_dice[0].bonus += 1
	_sync_player_dice_pair(player)
	return get_upgrade_cost(player)


func save_pre_combat_snapshot() -> void:
	pre_combat_snapshot.clear()
	for player in team:
		pre_combat_snapshot.append(player.clone())


func restore_pre_combat_snapshot() -> void:
	team.clear()
	for player in pre_combat_snapshot:
		team.append(player.clone())


func end_run(victory: bool = false) -> RunSummary:
	run_active = false

	var summary := RunSummary.new()
	summary.victory = victory
	summary.nodes_cleared = visited_nodes.size()
	summary.gold_earned = total_gold_earned
	summary.items_collected = total_items_collected

	var regions := {}
	for node_id in visited_nodes:
		var node := map.get_node(node_id)
		if node != null:
			regions[node.region_index] = true
	summary.regions_reached = regions.size()

	last_run_summary = summary
	return summary


func reset_run_state() -> void:
	team.clear()
	inventory.clear()
	gold = STARTING_GOLD
	map = null
	current_node_id = -1
	current_region_index = 0
	visited_nodes.clear()
	pre_combat_snapshot.clear()
	total_gold_earned = 0
	total_items_collected = 0
	run_active = false
	last_run_summary = null


func _prepare_player(player: MobData) -> void:
	player.dead = false
	player.current_health = player.max_health
	_sync_player_dice_pair(player)


func _sync_player_dice_pair(player: MobData) -> void:
	if player.alive_dice.is_empty():
		return
	if player.alive_dice.size() == 1:
		player.alive_dice.append(player.alive_dice[0].duplicate(true))
	elif player.alive_dice.size() >= 2:
		player.alive_dice[1] = player.alive_dice[0].duplicate(true)


func _load_spells() -> void:
	all_spells.clear()
	for path in _list_tres_paths("res://Prototyping/Data/Spells"):
		var spell := load(path)
		if spell is Spell:
			all_spells.append(spell)


func _load_env_die() -> void:
	env_die = DiceData.new()
	env_die.type = Consts.DiceType.D6
	env_die.elements = [
		Consts.Elements.Idle,
		Consts.Elements.Fire,
		Consts.Elements.Idle,
		Consts.Elements.Nature,
		Consts.Elements.Idle,
		Consts.Elements.Forest,
	]


func _load_regions() -> void:
	region_configs.clear()
	for path in _list_tres_paths("res://Prototyping/Data/Regions"):
		var region := load(path)
		if region is RegionConfig:
			region_configs.append(region)


func _list_tres_paths(base_path: String) -> Array[String]:
	var results: Array[String] = []
	var dir := DirAccess.open(base_path)
	if dir == null:
		return results

	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if not dir.current_is_dir() and entry.ends_with(".tres"):
			results.append("%s/%s" % [base_path, entry])
		entry = dir.get_next()
	dir.list_dir_end()

	results.sort()
	return results
