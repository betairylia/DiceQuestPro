extends Object
class_name DiceMatcher


# Parse "FFFSS" → {Elements.Fire: 3, Elements.Sword: 2}
static func parse_pattern(s: String) -> Dictionary:
	# Build reverse map: char → Elements value
	var char_to_elem := {}
	for elem in Consts.SHORTHANDS:
		char_to_elem[Consts.SHORTHANDS[elem]] = elem

	var req := {}
	for i in s.length():
		var c := s[i]
		if not char_to_elem.has(c):
			push_error("DiceMatcher.parse_pattern: unknown shorthand '%s'" % c)
			continue
		var elem: int = char_to_elem[c]
		req[elem] = req.get(elem, 0) + 1
	return req


# Build token pool. Each normal die → 1 token; each extreme die → 2 tokens.
# Token: {element, digit, idx, die}
static func _build_token_pool(results: Array[DiceResult]) -> Array:
	var pool: Array = []
	for i in results.size():
		var r: DiceResult = results[i]
		var copies := 2 if r.is_extreme else 1
		for _c in copies:
			pool.append({ "element": r.element, "digit": r.digit, "idx": i, "die": r })
	return pool


# Try to satisfy requirements from pool. Returns Array[DiceResult] (tokens' .die) or null.
static func _try_match(pool: Array, req: Dictionary) -> Array:
	var selected: Array[DiceResult] = []
	for elem in req:
		var count: int = req[elem]
		# Filter tokens matching this element
		var candidates: Array = pool.filter(func(t): return t["element"] == elem)
		# Sort: digit DESC, then idx ASC (deterministic tiebreaker)
		candidates.sort_custom(func(a, b):
			if a["digit"] != b["digit"]:
				return a["digit"] > b["digit"]
			return a["idx"] < b["idx"]
		)
		if candidates.size() < count:
			return []  # not enough — signal failure via empty + separate flag
		for j in count:
			selected.append(candidates[j]["die"])
	return selected


# Match one spell at the highest achievable level; returns MatchedSpell or null.
static func match_spell(results: Array[DiceResult], spell: Spell) -> MatchedSpell:
	var pool := _build_token_pool(results)
	# Iterate levels from highest to lowest
	for level in range(spell.patterns.size() - 1, -1, -1):
		var req := parse_pattern(spell.patterns[level])
		var matched := _try_match(pool, req)
		# _try_match returns [] on failure; null would be ideal but GDScript arrays
		# can't distinguish empty-success from failure here, so we use req total count.
		var needed := 0
		for elem in req:
			needed += req[elem]
		if matched.size() == needed:
			var ms := MatchedSpell.new()
			ms.spell = spell
			ms.level = level
			ms.matched_dice.assign(matched)
			return ms
	return null


# Match all spells independently (dice not consumed across spells).
static func match_all_spells(results: Array[DiceResult], spells: Array) -> Array[MatchedSpell]:
	var out: Array[MatchedSpell] = []
	for spell in spells:
		var ms := match_spell(results, spell)
		if ms != null:
			out.append(ms)
	return out

# Debug: print matched spells to console.
# Format: "[SpellName Lv.N] pattern | dice sum=X | mobs: [MobData...]"
static func print_matches(matches: Array[MatchedSpell]) -> void:
	for ms in matches:
		var pattern: String = ms.spell.patterns[ms.level]
		var sum: int = ms.digit_sum()
		var mob_names: Array = []
		for mob in ms.source_mobs():
			mob_names.append(mob.display_name if "display_name" in mob else str(mob))
		print("[%s Lv.%d] %s | dice sum=%d | mobs: [%s]" % [
			ms.spell.display_name, ms.level, pattern, sum, ", ".join(mob_names)
		])
