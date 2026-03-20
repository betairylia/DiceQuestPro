extends Control
signal act
signal reroll

@onready var player_spells: SpellsDetailPanel = $PlayerSpells
@onready var enemy_spells: SpellsDetailPanel = $EnemySpells

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_act_button_pressed() -> void:
	act.emit()


func _on_reroll_button_pressed() -> void:
	reroll.emit()


func set_reroll_enabled(enabled: bool) -> void:
	$RerollButton.disabled = not enabled


func _on_prototype_player_spell_updated(spells: Array[MatchedSpell]) -> void:
	player_spells.populate(spells)


func _on_prototype_enemy_spell_updated(spells: Array[MatchedSpell]) -> void:
	enemy_spells.populate(spells)
