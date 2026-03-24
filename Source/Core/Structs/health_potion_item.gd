extends Item
class_name HealthPotionItem

const ALLY_HEAL_ALL = preload("res://Source/SpellLogics/ally_heal_all.gd")

static var _icon_texture: Texture2D

@export var power: int = 30:
	set(value):
		field = max(value, 1)
		_sync_metadata()


func _init() -> void:
	item_type = ItemType.Consumable
	is_consumable_in_combat = true
	_sync_metadata()


func create_icon() -> Control:
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	icon.texture = _get_icon_texture()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func consume(ctx: Item.CombatConsumeContext) -> void:
	var living_players: Array[Mob] = []
	for player in ctx.players:
		if player != null and player.is_alive():
			living_players.append(player)

	if living_players.is_empty():
		return

	var matched := MatchedSpell.new()
	matched.matched_dice = []

	var spell_ctx := SpellContext.new()
	spell_ctx.matched = matched
	spell_ctx.power = power
	spell_ctx.casters = []
	spell_ctx.allies = ctx.players
	spell_ctx.targets = living_players

	if ctx.combat_node is Combat:
		var combat := ctx.combat_node as Combat
		combat.announce_item_use(display_name)

	ALLY_HEAL_ALL.Do(spell_ctx)


func _sync_metadata() -> void:
	display_name = "Health Potion"
	description = "Restore %d HP to all living allies." % power


static func _get_icon_texture() -> Texture2D:
	if _icon_texture != null:
		return _icon_texture

	var image := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	image.fill(Color(0.0, 0.0, 0.0, 0.0))

	for y in range(3, 13):
		for x in range(4, 12):
			image.set_pixel(x, y, Color(0.17, 0.06, 0.08, 1.0))

	for y in range(5, 12):
		for x in range(5, 11):
			image.set_pixel(x, y, Color(0.79, 0.16, 0.24, 1.0))

	for x in range(6, 10):
		image.set_pixel(x, 2, Color(0.91, 0.87, 0.63, 1.0))
		image.set_pixel(x, 3, Color(0.91, 0.87, 0.63, 1.0))

	for x in range(5, 11):
		image.set_pixel(x, 4, Color(0.91, 0.87, 0.63, 1.0))

	_icon_texture = ImageTexture.create_from_image(image)
	return _icon_texture
