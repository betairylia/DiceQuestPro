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
