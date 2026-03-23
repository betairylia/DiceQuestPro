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

signal combat_won
signal combat_lost

const PLAYER_MOB_SCENE = preload("res://Prototyping/Nodes/Player/PlayerMob.tscn")
const ENEMY_MOB_SCENE  = preload("res://Prototyping/Nodes/mob.tscn")

const BASELINE_Y       := 182.0
const PLAYER_CENTER_X  := 150.0   # center of the player half
const ENEMY_CENTER_X   := 470.0   # center of the enemy half
const MOB_INTERVAL     := 15.0    # gap between mobs
const DICE_WIDTH       := 30.0    # visual width per die
const SPELL_WAIT_TIME  := 0.5

var players: Array[Mob] = []
var enemies: Array[Mob] = []

@onready var combat_hud: Control = $CombatHud
@onready var env_die: RollableDice = $EnvironmentDice
@export var spells: Array[Spell]
@export var playersData: Array[MobData]
@export var enemiesData: Array[MobData]
@export var envDie: DiceData

# Flat dice lists rebuilt each turn from mob children.
var _player_dice: Array[RollableDice] = []
var _enemy_dice: Array[RollableDice] = []
# Full set of player results this turn; updated in-place on selective reroll.
var _player_results: Array[DiceResult] = []
var _enemy_results: Array[DiceResult] = []
# Full list of matched spells for player and enemy
var _player_matched_spells: Array[MatchedSpell] = []
var _enemy_matched_spells: Array[MatchedSpell] = []

var _phase: CombatExecPhase = CombatExecPhase.Preparation
var _rerolls: int = 1
var _combat_ended: bool = false


func _ready() -> void:
	# Don't auto-start — wait for init() call from wrapper
	pass


func init(players_data: Array[MobData], enemies_data: Array[MobData], spells_data: Array[Spell], env_die_data: DiceData) -> void:
	playersData = players_data
	enemiesData = enemies_data
	spells = spells_data
	envDie = env_die_data

	env_die.setup(envDie)
	env_die.SetState(RollableDice.DiceCombatState.Determined)

	_spawn_mobs(playersData, PLAYER_MOB_SCENE, players, true)
	_spawn_mobs(enemiesData, ENEMY_MOB_SCENE, enemies, false)

	_combat_ended = false
	_turn()


func _spawn_mobs(mob_data: Array[MobData], scene: PackedScene, list: Array[Mob], is_player: bool) -> void:
	# Compute widths and total span up front
	var widths: Array[float] = []
	var total_w := 0.0
	for md in mob_data:
		var w := md.alive_dice.size() * DICE_WIDTH
		widths.append(w)
		total_w += w
	total_w += (mob_data.size() - 1) * MOB_INTERVAL

	var center_x := PLAYER_CENTER_X if is_player else ENEMY_CENTER_X
	var cursor := center_x - total_w / 2.0

	# Players: index 0 = leftmost (furthest from center)
	# Enemies: index 0 = leftmost (closest to center)
	for i in mob_data.size():
		var idx := (mob_data.size() - 1 - i) if is_player else i
		var mob: Mob = scene.instantiate()
		mob.position = Vector2(cursor + widths[idx] / 2.0, BASELINE_Y)
		mob.knockback_direction = Vector2(-1, 0) if is_player else Vector2(1, 0)
		add_child(mob)
		mob.setup(mob_data[idx])
		mob.died.connect(_on_mob_died.bind(mob, is_player))
		mob.revived.connect(_on_mob_revived.bind(mob, is_player))
		if is_player:
			list.push_front(mob)
		else:
			list.append(mob)
		cursor += widths[idx] + MOB_INTERVAL


func _enter_phase(phase: CombatExecPhase) -> void:
	_phase = phase
	phase_entered.emit(phase)


func _turn() -> void:
	_sync_player_dice()
	_enemy_dice = _collect_dice(enemies)

	_rerolls += 1
	_rerolls = clamp(_rerolls, 0, 5)
	reroll_energy_updated.emit(_rerolls)
	combat_hud.set_reroll_energy(_rerolls)

	_enter_phase(CombatExecPhase.Preparation)

	await _roll_env()
	await _roll_enemies()
	await _roll_players()


func _sync_player_dice() -> void:
	var new_dice = _collect_dice(players)
	for die in _player_dice:
		if die not in new_dice:
			die.state_entered.disconnect(_update_reroll_button)
	for die in new_dice:
		if die not in _player_dice:
			die.state_entered.connect(_update_reroll_button)
	_player_dice = new_dice


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


# TODO: Use signals
func _update_reroll_button(_s) -> void:
	var any_selected := _player_dice.any(func(d): return d.state == RollableDice.DiceCombatState.Selected)
	combat_hud.set_reroll_enabled(any_selected and _rerolls > 0)


func _regular_attack(froms: Array[Mob], tos: Array[Mob], from_dice: Array[DiceResult]) -> void:
	await BindGroupAwait.all(Arr.emap(from_dice,
		func(i: int, die: DiceResult):
			if is_instance_valid(die.node):
				return die.node.AnimatedAttack.bind(tos, i * 0.15)
	))

func _resolve_spells(froms: Array[Mob], tos: Array[Mob], from_spells: Array[MatchedSpell]) -> void:
	for spell in from_spells:
		var level_data := spell.level_data()
		spell_triggered.emit(spell)
		await BindGroupAwait.all(Arr.emap(Arr.unique(spell.matched_dice),
			func(i: int, die: DiceResult):
				if is_instance_valid(die.node):
					return die.node.AnimatedAttack.bind(tos, i * 0.15)
		))

		# Apply spell logic
		var ctx := SpellContext.new()
		ctx.matched = spell
		ctx.power = level_data.power
		ctx.casters.assign(spell.source_mobs())
		ctx.allies  = froms
		ctx.targets = tos
		await SpellLogic.execute(level_data.logic, ctx)

		await get_tree().create_timer(SPELL_WAIT_TIME).timeout


func _check_combat_end() -> bool:
	if _combat_ended:
		return true
	if enemies.all(func(e): return not e.is_alive()):
		_combat_ended = true
		combat_won.emit()
		return true
	if players.all(func(e): return not e.is_alive()):
		_combat_ended = true
		combat_lost.emit()
		return true
	return false


func _on_combat_hud_act() -> void:
	for die in _player_dice:
		die.SetState(RollableDice.DiceCombatState.Determined)

	_enter_phase(CombatExecPhase.PlayerRegular)
	await _regular_attack(players, enemies, _player_results)
	if _check_combat_end():
		return

	_enter_phase(CombatExecPhase.PlayerSpells)
	await _resolve_spells(players, enemies, _player_matched_spells)
	if _check_combat_end():
		return

	_refresh_enemy_spells()
	_enter_phase(CombatExecPhase.EnemyRegular)
	await _regular_attack(enemies, players, _enemy_results)
	if _check_combat_end():
		return

	_enter_phase(CombatExecPhase.EnemySpells)
	await _resolve_spells(enemies, players, _enemy_matched_spells)
	if _check_combat_end():
		return

	_turn()


func _roll_env() -> void:
	await env_die.Roll()


func _roll_enemies() -> void:
	_enemy_results = await _roll_dice(_enemy_dice)
	for die in _enemy_dice:
		die.SetState(RollableDice.DiceCombatState.Determined)
	
	var _enemy_with_env = _enemy_results.duplicate()
	_enemy_with_env.append(env_die.dice_result)
	_enemy_matched_spells = DiceMatcher.match_all_spells(_enemy_with_env, spells)

	enemy_spell_updated.emit(_enemy_matched_spells)


func _roll_players() -> void:
	_player_results = await _roll_dice(_player_dice)
	for die in _player_dice:
		die.SetState(RollableDice.DiceCombatState.Unselected)
	
	var _player_with_env = _player_results.duplicate()
	_player_with_env.append(env_die.dice_result)
	_player_matched_spells = DiceMatcher.match_all_spells(_player_with_env, spells)

	player_spell_updated.emit(_player_matched_spells)


func _refresh_enemy_spells() -> void:
	_enemy_dice = _collect_dice(enemies)
	_enemy_results.assign(_enemy_dice.map(func(d): return d.dice_result))

	var with_env := _enemy_results.duplicate()
	with_env.append(env_die.dice_result)
	_enemy_matched_spells = DiceMatcher.match_all_spells(with_env, spells)
	enemy_spell_updated.emit(_enemy_matched_spells)


func _on_mob_died(_mob: Mob, is_player: bool) -> void:
	# Rebuild the flat dice list so future rolls use dead_dice.
	if is_player:
		_sync_player_dice()
	else:
		_enemy_dice = _collect_dice(enemies)


func _on_mob_revived(_mob: Mob, is_player: bool) -> void:
	if is_player:
		_sync_player_dice()
	else:
		_enemy_dice = _collect_dice(enemies)


func _on_combat_hud_reroll() -> void:
	_rerolls -= 1
	reroll_energy_updated.emit(_rerolls)
	_update_reroll_button(null)

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
	
	var _player_with_env = _player_results.duplicate()
	_player_with_env.append(env_die.dice_result)
	_player_matched_spells = DiceMatcher.match_all_spells(_player_with_env, spells)

	player_spell_updated.emit(_player_matched_spells)
