extends RefCounted
class_name MapNode

enum NodeType {
	COMBAT,
	BOSS,
	TREASURE,
	VILLAGE,
}

var id: int = -1
var type: NodeType = NodeType.COMBAT
var position: Vector2 = Vector2.ZERO
var successors: Array[int] = []
var predecessors: Array[int] = []
var region_index: int = 0
var enemies: Array[MobData] = []
var treasure_gold: int = 0
var treasure_items: Array[DiceFaceItem] = []
var visible: bool = false
var revealed_edges: bool = false


func is_combat_node() -> bool:
	return type == NodeType.COMBAT or type == NodeType.BOSS
