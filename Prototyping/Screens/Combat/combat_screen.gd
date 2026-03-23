extends Control

const PROTOTYPE_SCENE := preload("res://Prototyping/Prototype.tscn")
const REWARD_SCENE := "res://Prototyping/Screens/Reward/RewardScreen.tscn"
const WORLD_MAP_SCENE := "res://Prototyping/Screens/WorldMap/WorldMap.tscn"
const GAME_OVER_SCENE := "res://Prototyping/Screens/GameOver/GameOverScreen.tscn"

@onready var _combat_root: Control = $CombatRoot
@onready var _defeat_overlay: PanelContainer = $DefeatOverlay

var _combat: Combat


func _ready() -> void:
	var node := GameState.get_current_node()
	if node == null or not node.is_combat_node():
		SceneTransition.change_scene(WORLD_MAP_SCENE)
		return

	_defeat_overlay.visible = false
	_combat = PROTOTYPE_SCENE.instantiate() as Combat
	_combat_root.add_child(_combat)
	await get_tree().process_frame
	_combat.combat_won.connect(_on_combat_won)
	_combat.combat_lost.connect(_on_combat_lost)
	_combat.init(GameState.team, _duplicate_mobs(node.enemies), GameState.all_spells, GameState.env_die)


func _on_combat_won() -> void:
	var node := GameState.get_current_node()
	if node != null:
		GameState.complete_node(node.id)
	SceneTransition.change_scene(REWARD_SCENE)


func _on_combat_lost() -> void:
	_defeat_overlay.visible = true


func _on_retry_button_pressed() -> void:
	GameState.restore_pre_combat_snapshot()
	SceneTransition.change_scene("res://Prototyping/Screens/Combat/CombatScreen.tscn")


func _on_give_up_button_pressed() -> void:
	GameState.end_run(false)
	SceneTransition.change_scene(GAME_OVER_SCENE)


func _duplicate_mobs(source: Array[MobData]) -> Array[MobData]:
	var result: Array[MobData] = []
	for mob in source:
		result.append(mob.clone())
	return result
