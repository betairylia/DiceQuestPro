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
					if node.id not in prev_node.successors:
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
