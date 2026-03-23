extends RefCounted
class_name MapGenerator


static func generate(regions: Array[RegionConfig]) -> RegionMap:
	randomize()

	var map := RegionMap.new()
	map.regions = regions

	var next_id := 0
	var prev_region_end_ids: Array[int] = []
	var region_count: int = max(regions.size(), 1)

	for region_idx in regions.size():
		var config := regions[region_idx]
		var layers := _generate_layers(config, region_idx, next_id)
		_offset_positions(layers, region_idx, region_count)

		for layer in layers:
			for node: MapNode in layer:
				map.nodes[node.id] = node
				next_id = max(next_id, node.id + 1)

		_connect_layers(layers)
		_add_cross_edges(layers)
		_assign_types(layers)
		_populate_nodes(layers, config)

		if prev_region_end_ids.is_empty():
			for node: MapNode in layers[0]:
				map.start_node_ids.append(node.id)
				node.visible = true
				node.revealed_edges = true
		else:
			for prev_id in prev_region_end_ids:
				var prev_node := map.get_node(prev_id)
				if prev_node == null:
					continue
				for node: MapNode in layers[0]:
					_add_edge(prev_node, node)

		prev_region_end_ids.clear()
		for node: MapNode in layers[-1]:
			if node.type == MapNode.NodeType.BOSS:
				prev_region_end_ids.append(node.id)

	return map


static func generate_item_from_pool(pool: Array[MobData]) -> DiceFaceItem:
	if pool.is_empty():
		var fallback := DiceFaceItem.new()
		fallback.element = Consts.Elements.Idle
		fallback.digit = 1
		return fallback

	var mob := pool[randi() % pool.size()]
	if mob.alive_dice.is_empty():
		var empty_item := DiceFaceItem.new()
		empty_item.element = Consts.Elements.Idle
		empty_item.digit = 1
		return empty_item

	var dice := mob.alive_dice[randi() % mob.alive_dice.size()]
	if dice.elements.is_empty():
		var empty_faces := DiceFaceItem.new()
		empty_faces.element = Consts.Elements.Idle
		empty_faces.digit = 1
		return empty_faces
	var face_index: int = randi() % max(dice.face_count(), 1)
	var item := DiceFaceItem.new()
	item.element = dice.elements[face_index % dice.elements.size()]
	item.digit = face_index + 1
	return item


static func _generate_layers(config: RegionConfig, region_idx: int, start_id: int) -> Array:
	var target: int = max(config.node_count, 6)
	var layer_count := clampi(roundi(float(target) / 3.0), 3, 5)
	var layers: Array = []
	var id := start_id
	var nodes_placed := 0

	for layer_idx in layer_count:
		var remaining_layers := layer_count - layer_idx
		var remaining_nodes := target - nodes_placed
		var count := clampi(roundi(float(remaining_nodes) / float(remaining_layers)), 2, 4)
		if layer_idx == layer_count - 1:
			count = max(1, remaining_nodes)

		var layer: Array[MapNode] = []
		for node_idx in count:
			var node := MapNode.new()
			node.id = id
			node.region_index = region_idx
			node.position = Vector2(
				float(layer_idx) / float(max(layer_count - 1, 1)),
				float(node_idx + 1) / float(count + 1)
			)
			layer.append(node)
			id += 1
		layers.append(layer)
		nodes_placed += count

	return layers


static func _offset_positions(layers: Array, region_idx: int, region_count: int) -> void:
	const MAP_SIDE_MARGIN := 0.04
	const REGION_GAP_RATIO := 0.12
	var region_width := (1.0 - MAP_SIDE_MARGIN * 2.0) / float(max(region_count, 1))
	var region_gap := region_width * REGION_GAP_RATIO
	var playable_width: int = max(region_width - region_gap, 0.01)
	var region_start := MAP_SIDE_MARGIN + float(region_idx) * region_width + region_gap * 0.5

	for layer in layers:
		for node: MapNode in layer:
			node.position.x = region_start + node.position.x * playable_width


static func _connect_layers(layers: Array) -> void:
	for layer_idx in range(layers.size() - 1):
		var current: Array = layers[layer_idx]
		var next_layer: Array = layers[layer_idx + 1]

		for node: MapNode in current:
			_add_edge(node, next_layer[randi() % next_layer.size()])

		for target: MapNode in next_layer:
			if target.predecessors.is_empty():
				_add_edge(current[randi() % current.size()], target)

		var extra_edges := randi_range(0, 2)
		for _extra in extra_edges:
			_add_edge(
				current[randi() % current.size()],
				next_layer[randi() % next_layer.size()]
			)


static func _add_cross_edges(layers: Array) -> void:
	for layer_idx in range(layers.size() - 2):
		if randf() >= 0.35:
			continue
		var source: MapNode = layers[layer_idx][randi() % layers[layer_idx].size()]
		var target: MapNode = layers[layer_idx + 2][randi() % layers[layer_idx + 2].size()]
		_add_edge(source, target)


static func _add_edge(from_node: MapNode, to_node: MapNode) -> void:
	if to_node.id not in from_node.successors:
		from_node.successors.append(to_node.id)
	if from_node.id not in to_node.predecessors:
		to_node.predecessors.append(from_node.id)


static func _assign_types(layers: Array) -> void:
	for layer in layers:
		for node: MapNode in layer:
			node.type = MapNode.NodeType.COMBAT

	var last_layer: Array = layers[-1]
	var boss_node: MapNode = last_layer[0]
	boss_node.type = MapNode.NodeType.BOSS
	for idx in range(1, last_layer.size()):
		_add_edge(last_layer[idx], boss_node)

	if layers.size() >= 3:
		var mid_layer: Array = layers[layers.size() / 2]
		var village: MapNode = mid_layer[randi() % mid_layer.size()]
		if village.type == MapNode.NodeType.COMBAT:
			village.type = MapNode.NodeType.VILLAGE

		var treasure_idx := randi_range(1, max(layers.size() - 2, 1))
		var treasure_candidates: Array = []
		for candidate: MapNode in layers[treasure_idx]:
			if candidate.type == MapNode.NodeType.COMBAT:
				treasure_candidates.append(candidate)
		if not treasure_candidates.is_empty():
			var treasure: MapNode = treasure_candidates[randi() % treasure_candidates.size()]
			treasure.type = MapNode.NodeType.TREASURE


static func _populate_nodes(layers: Array, config: RegionConfig) -> void:
	for layer_idx in layers.size():
		var progress := float(layer_idx) / float(max(layers.size() - 1, 1))
		var enemy_count := roundi(lerpf(float(config.min_enemies), float(config.max_enemies), progress))

		for node: MapNode in layers[layer_idx]:
			match node.type:
				MapNode.NodeType.COMBAT:
					node.enemies = _pick_enemies(config, enemy_count)
				MapNode.NodeType.BOSS:
					node.enemies = _pick_bosses(config)
				MapNode.NodeType.TREASURE:
					node.treasure_gold = randi_range(6, 16)
					var treasure_count := randi_range(1, 3)
					for _idx in treasure_count:
						node.treasure_items.append(generate_item_from_pool(config.enemy_pool))
				MapNode.NodeType.VILLAGE:
					pass


static func _pick_enemies(config: RegionConfig, count: int) -> Array[MobData]:
	var result: Array[MobData] = []
	if config.enemy_pool.is_empty():
		return result

	for _idx in count:
		var template := config.enemy_pool[randi() % config.enemy_pool.size()]
		result.append(_duplicate_mob(template, config.enemy_health_scale))
	return result


static func _pick_bosses(config: RegionConfig) -> Array[MobData]:
	if config.boss_encounters.is_empty():
		return _pick_enemies(config, config.max_enemies)

	var encounter: Array = config.boss_encounters[randi() % config.boss_encounters.size()]
	var result: Array[MobData] = []
	for mob: MobData in encounter:
		result.append(_duplicate_mob(mob, config.enemy_health_scale))
	return result


static func _duplicate_mob(template: MobData, health_scale: float) -> MobData:
	var duplicate := template.clone()
	duplicate.max_health = max(1, roundi(float(duplicate.max_health) * health_scale))
	duplicate.current_health = duplicate.max_health
	duplicate.dead = false
	return duplicate
