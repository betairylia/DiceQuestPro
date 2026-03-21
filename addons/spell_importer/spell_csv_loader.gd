@tool
extends RefCounted
class_name SpellCsvLoader

const SYMBOLS_CSV  := "res://DataSheets/spells-Symbols.csv"
const SPELLS_CSV   := "res://DataSheets/spells-Spells.csv"
const SPELLS_DIR   := "res://Prototyping/Data/Spells/"


## Load the symbols CSV and return a dict mapping emoji string → shorthand char.
func _load_symbols() -> Dictionary:
	var map := {}
	var file := FileAccess.open(SYMBOLS_CSV, FileAccess.READ)
	if not file:
		push_error("[SpellCsvLoader] Cannot open %s" % SYMBOLS_CSV)
		return map

	file.get_csv_line()  # skip header
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 2 or row[0].strip_edges().is_empty():
			continue
		map[row[0].strip_edges()] = row[1].strip_edges()
	return map


## Convert an emoji pattern string (e.g. "🔥🔥🔥") to shorthand (e.g. "FFF")
## using the symbol map. Handles variable-length emoji sequences.
func _convert_pattern(emoji_pattern: String, symbols: Dictionary) -> String:
	var result := ""
	var i := 0
	while i < emoji_pattern.length():
		var matched := false
		# Try longest possible substring first (max emoji length ~2 chars in GDScript)
		for len in range(mini(4, emoji_pattern.length() - i), 0, -1):
			var substr := emoji_pattern.substr(i, len)
			if symbols.has(substr):
				result += symbols[substr]
				i += len
				matched = true
				break
		if not matched:
			# Skip unknown characters (spaces, variation selectors, etc.)
			i += 1
	return result


## Main sync: read CSVs, group by spell name, create/update Spell resources.
## Returns the number of spells synced.
func sync_spells() -> int:
	var symbols := _load_symbols()
	if symbols.is_empty():
		push_error("[SpellCsvLoader] No symbols loaded — aborting.")
		return 0

	# Read spell rows and group by name (column 0)
	var file := FileAccess.open(SPELLS_CSV, FileAccess.READ)
	if not file:
		push_error("[SpellCsvLoader] Cannot open %s" % SPELLS_CSV)
		return 0

	file.get_csv_line()  # skip header
	file.get_csv_line()  # skip second header row (empty)

	# Group: spell_name -> Array of {pattern, display_name, power, logic, anim}
	var groups := {}
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() < 4:
			continue
		var spell_name := row[0].strip_edges()
		if spell_name.is_empty():
			continue

		var entry := {
			"pattern": _convert_pattern(row[1].strip_edges(), symbols),
			"display_name": row[2].strip_edges() if row.size() > 2 else "",
			"power": int(row[3].strip_edges()) if row.size() > 3 and not row[3].strip_edges().is_empty() else 0,
			"logic": row[4].strip_edges() if row.size() > 4 and not row[4].strip_edges().is_empty() else "",
			"anim": row[5].strip_edges() if row.size() > 5 else "",
		}
		if not groups.has(spell_name):
			groups[spell_name] = []
		groups[spell_name].append(entry)

	# Ensure output directory exists
	if not DirAccess.dir_exists_absolute(SPELLS_DIR):
		DirAccess.make_dir_recursive_absolute(SPELLS_DIR)

	# Create or update Spell resources
	var count := 0
	for spell_name in groups:
		var path: String = SPELLS_DIR + spell_name + ".tres"

		var spell: Spell
		if ResourceLoader.exists(path):
			spell = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		else:
			spell = Spell.new()

		# Build levels array
		var levels: Array[SpellLevel] = []
		for entry in groups[spell_name]:
			var lv := SpellLevel.new()
			lv.display_name = entry["display_name"]
			lv.pattern = entry["pattern"]
			lv.power = entry["power"]
			lv.logic = entry["logic"]
			lv.anim = entry["anim"]
			levels.append(lv)

		spell.levels = levels
		ResourceSaver.save(spell, path)
		# Force the editor to replace its cached copy with the new data
		ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_REPLACE)
		count += 1
		print("[SpellCsvLoader] Saved %s (%d levels)" % [path, levels.size()])

	return count
