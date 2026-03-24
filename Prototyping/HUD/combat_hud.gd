extends Control

signal act
signal reroll

const INVENTORY_GRID_SCENE := preload("res://Prototyping/HUD/InventoryGrid/inventory_grid.tscn")
const ITEM_CONFIRM_POPUP_SCENE := preload("res://Prototyping/HUD/ItemConfirmPopup/item_confirm_popup.tscn")
const PIXEL_THEME := preload("res://Prototyping/HUD/pixelated.tres")

@onready var player_spells: SpellsDetailPanel = $PlayerSpells
@onready var enemy_spells: SpellsDetailPanel = $EnemySpells
@onready var spell_name_label: RichTextLabel = $SpellName
@onready var spell_anno_label: RichTextLabel = $SpellAnnotation
@onready var phase_anno_label: RichTextLabel = $PhaseAnnotation

var _inventory_grid: InventoryGrid
var _confirm_popup: ItemConfirmPopup
var _reroll_energy: int = 0
var _phase: Combat.CombatExecPhase = Combat.CombatExecPhase.Preparation


func _ready() -> void:
	_build_inventory_ui()


func _build_inventory_ui() -> void:
	_inventory_grid = INVENTORY_GRID_SCENE.instantiate() as InventoryGrid
	_inventory_grid.name = "InventoryGrid"
	_inventory_grid.anchor_left = 1.0
	_inventory_grid.anchor_top = 1.0
	_inventory_grid.anchor_right = 1.0
	_inventory_grid.anchor_bottom = 1.0
	_inventory_grid.offset_left = -164.0
	_inventory_grid.offset_top = -92.0
	_inventory_grid.offset_right = -12.0
	_inventory_grid.offset_bottom = -12.0
	_inventory_grid.columns_count = 4
	_inventory_grid.cell_size = Vector2(30, 30)
	_inventory_grid.filter = func(item: Item): return item != null and item.is_consumable_in_combat
	_inventory_grid.interactive = false
	_inventory_grid.theme = PIXEL_THEME
	_inventory_grid.item_clicked.connect(_on_inventory_item_clicked)
	add_child(_inventory_grid)

	_confirm_popup = ITEM_CONFIRM_POPUP_SCENE.instantiate() as ItemConfirmPopup
	_confirm_popup.name = "ItemConfirmPopup"
	_confirm_popup.visible = false
	_confirm_popup.theme = PIXEL_THEME
	_confirm_popup.confirmed.connect(_on_item_confirmed)
	add_child(_confirm_popup)

	_refresh_inventory_ui()


func _on_act_button_pressed() -> void:
	act.emit()


func _on_reroll_button_pressed() -> void:
	reroll.emit()


func set_reroll_enabled(enabled: bool) -> void:
	$RerollButton.disabled = not enabled
	_refresh_inventory_interaction()


func set_reroll_energy(energy: int) -> void:
	_reroll_energy = energy
	$RerollButton.text = "重骰 [%d]" % energy
	_refresh_inventory_interaction()


func _on_prototype_player_spell_updated(spells: Array[MatchedSpell]) -> void:
	player_spells.populate(spells)


func _on_prototype_enemy_spell_updated(spells: Array[MatchedSpell]) -> void:
	enemy_spells.populate(spells)


func _on_prototype_phase_entered(phase: Combat.CombatExecPhase) -> void:
	_phase = phase
	spell_name_label.modulate = Color.WHITE
	spell_anno_label.modulate = Color.WHITE
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

	_refresh_inventory_interaction()


func _on_prototype_spell_triggered(spell: MatchedSpell) -> void:
	print(spell.level_data().display_name)
	spell_name_label.text = spell.level_data().display_name
	spell_anno_label.text = ""
	spell_name_label.modulate = Color.WHITE


func _on_inventory_item_clicked(item: Item) -> void:
	if _confirm_popup == null or item == null:
		return
	var rect := _inventory_grid.get_item_global_rect(item)
	if rect.size == Vector2.ZERO:
		rect = Rect2(Vector2.ZERO, Vector2.ZERO)
	var title := "Use %s?" % item.display_name
	_confirm_popup.open_for(item, rect, title, "消耗 1 重骰能量")


func _on_item_confirmed(item: Item) -> void:
	var combat := get_parent() as Combat
	if combat == null:
		return
	if combat.try_consume_item(item):
		_refresh_inventory_ui()


func _refresh_inventory_ui() -> void:
	if _inventory_grid != null:
		_inventory_grid.refresh()
	_refresh_inventory_interaction()


func _refresh_inventory_interaction() -> void:
	if _inventory_grid == null:
		return
	var combat := get_parent() as Combat
	_inventory_grid.interactive = combat != null and combat.is_item_consumption_available()
	_inventory_grid.refresh()


func show_item_announcement(text: String, color: Color = Color.WHITE) -> void:
	spell_name_label.text = text
	spell_name_label.modulate = color
	spell_anno_label.text = ""
	spell_anno_label.modulate = color
	_clear_item_announcement_later(text)


func _clear_item_announcement_later(expected_text: String) -> void:
	await get_tree().create_timer(1.0).timeout
	if _phase != Combat.CombatExecPhase.Preparation:
		return
	if spell_name_label.text != expected_text:
		return
	spell_name_label.text = ""
	spell_anno_label.text = ""
	spell_name_label.modulate = Color.WHITE
	spell_anno_label.modulate = Color.WHITE
