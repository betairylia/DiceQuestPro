extends Node
class_name Combat

enum CombatExecPhase {
	PlayerRegular,
	PlayerSpells,
	EnemyRegular,
	EnemySpells,
	Preparation
}

# --- Combat schedule ---
signal phase_entered(phase: CombatExecPhase)
signal spell_triggered(spell: MatchedSpell)

signal player_spell_updated(spells: Array[MatchedSpell])
signal enemy_spell_updated(spells: Array[MatchedSpell])
signal reroll_energy_updated(rerolls: int)

@onready var players: Array[Mob] = [$"PlayerChar-Combat", $"PlayerChar-Combat2", $"PlayerChar-Combat3"]
@onready var enemies: Array[Mob] = [$EnemySlot1]
@onready var combat_hud: Control = $CombatHud
@export var spells: Array[Spell]
@export var playersData: Array[MobData]
@export var enemiesData: Array[MobData]

# Flat dice lists rebuilt each turn from mob children.
var _player_dice: Array[RollableDice] = []
var _enemy_dice: Array[RollableDice] = []
# Full set of player results this turn; updated in-place on selective reroll.
var _player_results: Array[DiceResult] = []
# Full list of matched spells for player and enemy
var _player_matched_spells: Array[MatchedSpell] = []
var _enemy_matched_spells: Array[MatchedSpell] = []

var _phase: CombatExecPhase = CombatExecPhase.Preparation
var _rerolls: int = 3


func _ready() -> void:
	for i in range(3):
		players[i].setup(playersData[i])
	enemies[0].setup(enemiesData[0])

	_turn()


func _enter_phase(phase: CombatExecPhase) -> void:
	_phase = phase
	phase_entered.emit(phase)


func _turn() -> void:
	# Rebuild dice lists and sync state_entered connections.
	# Only connect new dice / disconnect removed ones to avoid duplicates.
	var new_player_dice = _collect_dice(players)
	for die in _player_dice:
		if die not in new_player_dice:
			die.state_entered.disconnect(_update_reroll_button)
	for die in new_player_dice:
		if die not in _player_dice:
			die.state_entered.connect(_update_reroll_button)
	_player_dice = new_player_dice
	_enemy_dice = _collect_dice(enemies)

	_enter_phase(CombatExecPhase.Preparation)

	await _roll_enemies()
	await _roll_players()


func _collect_dice(mobs: Array[Mob]) -> Array[RollableDice]:
	var result: Array[RollableDice] = []
	for mob in mobs:
		result.append_array(mob.get_dice())
	return result


# Fires all animations concurrently, then awaits each result in order.
func _roll_dice(dice: Array[RollableDice]) -> Array[DiceResult]:
	for die in dice:
		die.Roll()
	var results: Array[DiceResult] = []
	for die in dice:
		results.append(await die.roll_finished)
	return results


func _update_reroll_button(_s) -> void:
	var any_selected := _player_dice.any(func(d): return d.state == RollableDice.DiceCombatState.Selected)
	combat_hud.set_reroll_enabled(any_selected)


func _regular_attack(froms: Array[Mob], tos: Array[Mob], from_dice: Array[DiceResult]) -> void:
	await BindGroupAwait.all(Arr.emap(from_dice,
		func(i: int, die: DiceResult):
			return die.node.Attack.bind(tos, i * 0.15)
	))

func _resolve_spells(froms: Array[Mob], tos: Array[Mob], from_spells: Array[MatchedSpell]) -> void:
	for spell in from_spells:
		spell_triggered.emit(spell)
		await BindGroupAwait.all(Arr.emap(Arr.unique(spell.matched_dice),
			func(i: int, die: DiceResult):
				return die.node.Attack.bind(tos, i * 0.15)
		))


func _on_combat_hud_act() -> void:

	for die in _player_dice:
		die.SetState(RollableDice.DiceCombatState.Determined)

	_enter_phase(CombatExecPhase.PlayerRegular)
	await _regular_attack(players, enemies, _player_results)

	_enter_phase(CombatExecPhase.PlayerSpells)
	await _resolve_spells(players, enemies, _player_matched_spells)

	_turn()


func _roll_enemies() -> void:
	var results = await _roll_dice(_enemy_dice)
	for die in _enemy_dice:
		die.SetState(RollableDice.DiceCombatState.Determined)
	_enemy_matched_spells = DiceMatcher.match_all_spells(results, spells)
	enemy_spell_updated.emit(_enemy_matched_spells)


func _roll_players() -> void:
	_player_results = await _roll_dice(_player_dice)
	for die in _player_dice:
		die.SetState(RollableDice.DiceCombatState.Unselected)
	_player_matched_spells = DiceMatcher.match_all_spells(_player_results, spells)
	player_spell_updated.emit(_player_matched_spells)


func _on_combat_hud_reroll() -> void:

	var to_roll = _player_dice.filter(func(d): return d.state == RollableDice.DiceCombatState.Selected)

	# TODO: Toggle auto-deselect
	for die in to_roll:
		die.SetState(RollableDice.DiceCombatState.Unselected)

	var new_results = await _roll_dice(to_roll)
	# Patch only the rerolled slots; leave the rest of _player_results intact.
	for new_result in new_results:
		var idx = _player_dice.find(new_result.node)
		if idx >= 0:
			_player_results[idx] = new_result
	_player_matched_spells = DiceMatcher.match_all_spells(_player_results, spells)
	player_spell_updated.emit(_player_matched_spells)
