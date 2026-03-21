extends VBoxContainer
class_name SpellsDetailPanel

const SPELL_ROW = preload("res://Prototyping/HUD/SpellDetailView/spell_row.tscn")

const ELEMENT_COLORS = {
	Consts.Elements.Sword:   Color(0.67, 0.67, 0.67),
	Consts.Elements.Fire:    Color(1.0,  0.40, 0.13),
	Consts.Elements.Water:   Color(0.27, 0.67, 1.0),
	Consts.Elements.Thunder: Color(1.0,  0.87, 0.0),
	Consts.Elements.Wind:    Color(0.67, 0.87, 1.0),
	Consts.Elements.Nature:  Color(0.27, 0.80, 0.27),
	Consts.Elements.Revive:  Color(0.27, 0.80, 0.27),
}

@onready var _container := $ScrollContainer/SpellDetailContainer
@onready var _total_damage := $TotalStats/Damage


func _colored_pattern(pattern_str: String) -> String:
	# Build a reverse map from shorthand char -> Elements value
	var char_to_element := {}
	for elem in Consts.SHORTHANDS:
		char_to_element[Consts.SHORTHANDS[elem]] = elem

	var result := ""
	for i in pattern_str.length():
		var c := pattern_str[i]
		if char_to_element.has(c):
			var col: Color = ELEMENT_COLORS[char_to_element[c]]
			result += "[color=#%s]%s[/color]" % [col.to_html(false), c]
		else:
			result += c
	return result


func populate(matches: Array[MatchedSpell]) -> void:
	for child in _container.get_children():
		child.queue_free()

	for ms in matches:
		var row := SPELL_ROW.instantiate()
		_container.add_child(row)
		row.get_node("Pattern").bbcode_enabled = true
		row.get_node("Pattern").text = _colored_pattern(ms.level_data().pattern)
		row.get_node("Name").text = ms.spell.display_name
		row.get_node("Damage").text = "%d +%d" % [ms.digit_sum(), ms.level_data().power]

	var total := 0
	for ms in matches:
		total += ms.digit_sum() + ms.level_data().power
	_total_damage.text = str(total)
