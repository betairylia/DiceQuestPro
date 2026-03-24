extends Resource
class_name RegionConfig

@export var region_name: String
@export var enemy_pool: Array[MobData]
@export var boss_encounters: Array  ## Each element is Array[MobData] (one encounter)
@export var min_enemies: int = 2
@export var max_enemies: int = 4
@export var enemy_health_scale: float = 1.0
@export var shop_exotic_chance: float = 0.2
@export var node_count: int = 12
