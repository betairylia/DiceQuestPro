extends VBoxContainer
class_name SpellsDetailPanel

const SPELL_ROW = preload("res://Prototyping/HUD/SpellDetailView/spell_row.tscn")

const ELEMENT_COLORS = {
	# Physical (white / silver)
	Consts.Elements.Sword:   Color(0.67, 0.67, 0.67),
	Consts.Elements.Bow:     Color(0.67, 0.67, 0.67),
	Consts.Elements.Defense: Color(0.80, 0.80, 0.80),
	# Fire (orange / red)
	Consts.Elements.Fire:    Color(1.0,  0.40, 0.13),
	# Water (blue)
	Consts.Elements.Water:   Color(0.27, 0.67, 1.0),
	Consts.Elements.Ice:     Color(0.53, 0.80, 1.0),
	# Thunder (yellow)
	Consts.Elements.Thunder: Color(1.0,  0.87, 0.0),
	Consts.Elements.Radiant: Color(1.0,  0.93, 0.47),
	# Nature (green)
	Consts.Elements.Nature:  Color(0.27, 0.80, 0.27),
	Consts.Elements.Forest:  Color(0.13, 0.60, 0.33),
	Consts.Elements.Heal:    Color(0.47, 0.93, 0.47),
	# Dark (violet / crimson)
	Consts.Elements.Dark:    Color(0.40, 0.13, 0.53),
	Consts.Elements.Poison:  Color(0.60, 0.20, 0.60),
	Consts.Elements.Blood:   Color(0.67, 0.13, 0.20),
	# Wind
	Consts.Elements.Wind:    Color(0.67, 0.87, 1.0),
	# Special
	Consts.Elements.Idle:    Color(0.50, 0.50, 0.50),
	Consts.Elements.Revive:  Color(0.47, 0.93, 0.47),
}

@onready var _container := $ScrollContainer/SpellDetailContainer
@onready var _total_damage := $TotalStats/Damage


func _colored_pattern(pattern_str: String) -> String:
	# Build a reverse map from shorthand char -> Elements value
	var char_to_element := {}
	for elem in Consts.SHORTHANDS:
		char_to_element[Consts.SHORTHANDS[elem]] = elem

	# Build a map from category char -> color (use first element as representative)
	var category_color := {}
	for cat_char in Consts.CATEGORIES:
		var first_elem: Consts.Elements = Consts.CATEGORIES[cat_char][0]
		category_color[cat_char] = ELEMENT_COLORS[first_elem]

	var result := ""
	for i in pattern_str.length():
		var c := pattern_str[i]
		if char_to_element.has(c):
			var col: Color = ELEMENT_COLORS[char_to_element[c]]
			result += "[color=#%s]%s[/color]" % [col.to_html(false), c]
		elif category_color.has(c):
			var col: Color = category_color[c]
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
		row.get_node("Name").text = ms.level_data().display_name
		row.get_node("Damage").text = "%d +%d" % [ms.digit_sum(), ms.level_data().power]

	var total := 0
	for ms in matches:
		total += ms.digit_sum() + ms.level_data().power
	_total_damage.text = str(total)
