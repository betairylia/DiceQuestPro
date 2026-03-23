extends RefCounted
class_name RegionMap

var regions: Array[RegionConfig] = []
var nodes: Dictionary = {}
var start_node_ids: Array[int] = []


func get_node(node_id: int) -> MapNode:
	return nodes.get(node_id) as MapNode
