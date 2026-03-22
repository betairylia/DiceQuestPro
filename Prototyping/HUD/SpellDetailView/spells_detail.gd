extends VBoxContainer
class_name SpellsDetailPanel

const SPELL_ROW = preload("res://Prototyping/HUD/SpellDetailView/spell_row.tscn")

@onready var _container := $ScrollContainer/SpellDetailContainer
@onready var _total_damage := $TotalStats/Damage


func populate(matches: Array[MatchedSpell]) -> void:
	for child in _container.get_children():
		child.queue_free()

	for ms in matches:
		var row := SPELL_ROW.instantiate()
		_container.add_child(row)
		row.get_node("Pattern").bbcode_enabled = true
		row.get_node("Pattern").text = Consts.colored_pattern(ms.level_data().pattern)
		row.get_node("Name").text = ms.level_data().display_name
		row.get_node("Damage").text = "%d +%d" % [ms.digit_sum(), ms.level_data().power]

	var total := 0
	for ms in matches:
		total += ms.digit_sum() + ms.level_data().power
	_total_damage.text = str(total)
