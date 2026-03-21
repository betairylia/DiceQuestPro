extends Control
signal act
signal reroll

@onready var player_spells: SpellsDetailPanel = $PlayerSpells
@onready var enemy_spells: SpellsDetailPanel = $EnemySpells
@onready var spell_name_label: RichTextLabel = $SpellName
@onready var spell_anno_label: RichTextLabel = $SpellAnnotation
@onready var phase_anno_label: RichTextLabel = $PhaseAnnotation

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


func set_reroll_energy(energy: int) -> void:
	$RerollButton.text = "重骰 [%d]" % energy


func _on_prototype_player_spell_updated(spells: Array[MatchedSpell]) -> void:
	player_spells.populate(spells)


func _on_prototype_enemy_spell_updated(spells: Array[MatchedSpell]) -> void:
	enemy_spells.populate(spells)


func _on_prototype_phase_entered(phase: Combat.CombatExecPhase) -> void:
	if phase == Combat.CombatExecPhase.Preparation:
		spell_name_label.text = ""
		spell_anno_label.text = ""
		phase_anno_label.text = ""
	elif phase == Combat.CombatExecPhase.PlayerRegular:
		spell_name_label.text = "普通攻击"
		spell_anno_label.text = ""
		phase_anno_label.text = "- PLAYER -"
	elif phase == Combat.CombatExecPhase.EnemyRegular:
		spell_name_label.text = "普通攻击"
		spell_anno_label.text = ""
		phase_anno_label.text = "- ENEMY -"
	elif phase == Combat.CombatExecPhase.PlayerSpells:
		spell_name_label.text = ""
		spell_anno_label.text = ""
		phase_anno_label.text = "- PLAYER -"
	elif phase == Combat.CombatExecPhase.EnemySpells:
		spell_name_label.text = ""
		spell_anno_label.text = ""
		phase_anno_label.text = "- ENEMY -"


func _on_prototype_spell_triggered(spell: MatchedSpell) -> void:
	print(spell.spell.display_name)
	spell_name_label.text = spell.spell.display_name
	spell_anno_label.text = ""
