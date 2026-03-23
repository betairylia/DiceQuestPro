extends RefCounted
class_name RegionMap

## Container for the full procedural map.
var regions: Array[RegionConfig] = []
## All nodes keyed by ID.
var nodes: Dictionary = {}
## Entry points for the player.
var start_node_ids: Array[int] = []


func get_node(id: int) -> MapNode:
	return nodes.get(id)