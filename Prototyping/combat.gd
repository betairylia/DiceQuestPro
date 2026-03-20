extends Node

signal player_spell_updated(spells: Array[MatchedSpell])
signal enemy_spell_updated(spells: Array[MatchedSpell])

@onready var players: Array[Mob] = [$"PlayerChar-Combat", $"PlayerChar-Combat2", $"PlayerChar-Combat3"]
@onready var enemies: Array[Mob] = [$EnemySlot1]
@onready var combat_hud: Control = $CombatHud
@export var spells: Array[Spell]
@export var playersData: Array[MobData]
@export var enemiesData: Array[MobData]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	for i in range(3):
		players[i].setup(playersData[i])
	for player in players:
		player.die_state_changed.connect(_update_reroll_button)
	
	enemies[0].setup(enemiesData[0])
	
	await _roll_enemies()
	await _roll_players()


# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta: float) -> void:
# 	pass


func _update_reroll_button() -> void:
	var any_selected := players.any(func(p): return p.has_selected_dice())
	combat_hud.set_reroll_enabled(any_selected)


func _on_combat_hud_act() -> void:
	pass


func _roll_enemies() -> void:

	var results = DiceResult.Flatten(
		await BindGroupAwait.all(
			enemies.map(func(m): return m.RollAll)
		)
	)

	var all_matched_spells = DiceMatcher.match_all_spells(results, spells)
	enemy_spell_updated.emit(all_matched_spells)


func _roll_players() -> void:
	
	var results = DiceResult.Flatten(
		await BindGroupAwait.all(
			players.map(func(m): return m.RollAll)
		)
	)
	
	var all_matched_spells = DiceMatcher.match_all_spells(results, spells)
	DiceMatcher.print_matches(all_matched_spells)
	player_spell_updated.emit(all_matched_spells)


func _on_combat_hud_reroll() -> void:
	
	var results = DiceResult.Flatten(
		await BindGroupAwait.all(
			players.map(func(m): return m.RollSelected)
		)
	)
	
	var all_matched_spells = DiceMatcher.match_all_spells(results, spells)
	DiceMatcher.print_matches(all_matched_spells)
	player_spell_updated.emit(all_matched_spells)
