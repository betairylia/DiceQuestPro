extends RefCounted
class_name RegionMap

var regions: Array[RegionConfig] = []
var nodes: Dictionary = {}  ## {int: MapNode}
var start_node_ids: Array[int] = []

func get_node(id: int) -> MapNode:
	return nodes.get(id)
