extends RefCounted
class_name MapNode

## A single node on the world map.
enum NodeType { COMBAT, BOSS, TREASURE, VILLAGE }

var id: int
var type: NodeType
## Normalized 0-1 coords for visual layout.
var position: Vector2
var successors: Array[int] = []
var predecessors: Array[int] = []
var region_index: int
## Pre-generated for COMBAT/BOSS nodes.
var enemies: Array[MobData] = []
## For TREASURE nodes.
var treasure_gold: int = 0
var treasure_items: Array[DiceFaceItem] = []
## Visibility state.
var visible: bool = false
var revealed_edges: bool = false