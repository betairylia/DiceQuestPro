extends Node

@onready var players: Array[Mob] = [$"PlayerChar-Combat", $"PlayerChar-Combat2", $"PlayerChar-Combat3"]
@export var spells: Array[Spell]
@export var playersData: Array[MobData]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for i in range(3):
		players[i].setup(playersData[i])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _roll_player() -> void:
	for player in players:
		player.RollAll()
		await get_tree().create_timer(0.25).timeout
	
	var results: Array[DiceResult] = []
	for player in players:
		results.append_array(await player.dice_rolled)
	
	print(results)
	
	var all_matched_spells = DiceMatcher.match_all_spells(results, spells)
	DiceMatcher.print_matches(all_matched_spells)


func _on_combat_hud_act() -> void:
	pass


func _on_combat_hud_reroll() -> void:
	await _roll_player()
	
