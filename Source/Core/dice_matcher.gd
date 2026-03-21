extends Object
class_name DiceMatcher


# Requirement: { accepts: Array[Elements], count: int }
# A concrete element like "S" → accepts = [Sword], count = N
# A category like "P"      → accepts = [Sword, Bow, ...], count = N

# Parse "FFFPP" → Array of requirements, e.g.:
#   [{ accepts: [Fire], count: 3 }, { accepts: [Sword, ...], count: 2 }]
# Sorted narrowest-first so specific slots consume tokens before broad categories.
static func parse_pattern(s: String) -> Array:
	# Build reverse map: char → [Elements] (single-element array)
	var char_to_accepts := {}
	for elem in Consts.SHORTHANDS:
		char_to_accepts[Consts.SHORTHANDS[elem]] = [elem]
	# Add category chars
	for cat_char in Consts.CATEGORIES:
		char_to_accepts[cat_char] = Consts.CATEGORIES[cat_char]

	# Count occurrences per unique char
	var counts := {}
	for i in s.length():
		var c := s[i]
		if not char_to_accepts.has(c):
			push_error("DiceMatcher.parse_pattern: unknown shorthand '%s'" % c)
			continue
		counts[c] = counts.get(c, 0) + 1

	# Build requirement array
	var reqs: Array = []
	for c in counts:
		reqs.append({ "accepts": char_to_accepts[c], "count": counts[c] })

	# Sort narrowest-first (fewer accepts = more specific = matched first)
	reqs.sort_custom(func(a, b): return a["accepts"].size() < b["accepts"].size())
	return reqs


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


# Try to satisfy requirements from pool. Consumes tokens across requirements.
# Returns Array[DiceResult] on success, [] on failure.
static func _try_match(pool: Array, reqs: Array) -> Array:
	var remaining := pool.duplicate()
	var selected: Array[DiceResult] = []

	for req in reqs:
		var accepts: Array = req["accepts"]
		var count: int = req["count"]
		# Filter tokens whose element is in accepts
		var candidates: Array = remaining.filter(
			func(t): return accepts.has(t["element"])
		)
		# Sort: digit DESC, then idx ASC (deterministic tiebreaker)
		candidates.sort_custom(func(a, b):
			if a["digit"] != b["digit"]:
				return a["digit"] > b["digit"]
			return a["idx"] < b["idx"]
		)
		if candidates.size() < count:
			return []
		for j in count:
			selected.append(candidates[j]["die"])
			remaining.erase(candidates[j])
	return selected


# Total token count needed across all requirements.
static func _total_needed(reqs: Array) -> int:
	var n := 0
	for req in reqs:
		n += req["count"]
	return n


# Match one spell at the highest achievable level; returns MatchedSpell or null.
static func match_spell(results: Array[DiceResult], spell: Spell) -> MatchedSpell:
	var pool := _build_token_pool(results)
	# Iterate levels from highest to lowest
	for level in range(spell.levels.size() - 1, -1, -1):
		var reqs := parse_pattern(spell.levels[level].pattern)
		var matched := _try_match(pool, reqs)
		if matched.size() == _total_needed(reqs):
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
		var pattern: String = ms.level_data().pattern
		var sum: int = ms.digit_sum()
		var mob_names: Array = []
		for mob in ms.source_mobs():
			mob_names.append(mob.display_name if "display_name" in mob else str(mob))
		print("[%s Lv.%d] %s | dice sum=%d | mobs: [%s]" % [
			ms.level_data().display_name, ms.level, pattern, sum, ", ".join(mob_names)
		])
