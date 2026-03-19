extends Node

@export var playersData: Array[MobData]

var players: Array[Mob]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for playerData in playersData:
		players.append(Mob.new(playerData))
	
	$"PlayerChar-Combat".setup(players[0])
	$"PlayerChar-Combat2".setup(players[1])
	$"PlayerChar-Combat3".setup(players[2])


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_combat_hud_act() -> void:
	print("Roll a dice!")
