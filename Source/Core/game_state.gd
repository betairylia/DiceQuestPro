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
var run_summary: RunSummary


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
	var files: Array[String] = []
	dir.list_dir_begin()
	var file_name := dir.get_next()
	while file_name != "":
		if file_name.ends_with(".tres"):
			files.append(file_name)
		file_name = dir.get_next()
	files.sort()
	for f in files:
		var config = load("res://Prototyping/Data/Regions/" + f)
		if config is RegionConfig:
			region_configs.append(config)


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
	assert(not region_configs.is_empty(), "No region configs loaded — check Prototyping/Data/Regions/")
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
	run_summary = summary
	return summary
