extends Resource
class_name RegionConfig

## Configuration for a region in the roguelike progression.
@export var region_name: String
## Enemies that can spawn in this region.
@export var enemy_pool: Array[MobData]
## Boss encounters - each element is Array[MobData] representing one encounter.
## Godot 4 does not support nested typed arrays in exports, so outer array is untyped.
@export var boss_encounters: Array
## Minimum enemy count for early nodes.
@export var min_enemies: int = 2
## Maximum enemy count for late nodes.
@export var max_enemies: int = 4
## Multiplier on enemy HP.
@export var enemy_health_scale: float = 1.0
## Chance a shop item comes from outside this region.
@export var shop_exotic_chance: float = 0.2
## Target number of nodes.
@export var node_count: int = 12