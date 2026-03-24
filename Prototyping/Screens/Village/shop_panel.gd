extends VBoxContainer

const SHOP_ITEM_COUNT_MIN := 3
const SHOP_ITEM_COUNT_MAX := 5
const POTION_STOCK := 1

@onready var _gold_label: RichTextLabel = $GoldLabel
@onready var _sell_list: VBoxContainer = $Lists/SellColumn/SellList
@onready var _buy_list: VBoxContainer = $Lists/BuyColumn/BuyList

var _offers: Array[Item] = []


func _ready() -> void:
	if _offers.is_empty():
		_generate_offers()
	refresh()


func refresh() -> void:
	_gold_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gold_label.text = "金币 %d" % GameState.gold

	_clear_children(_sell_list)
	_clear_children(_buy_list)

	var sellable_items: Array[Item] = []
	for item in GameState.inventory:
		if item is DiceFaceItem or item is HealthPotionItem:
			sellable_items.append(item)

	if sellable_items.is_empty():
		var empty_label := RichTextLabel.new()
		empty_label.fit_content = true
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_label.text = "没有可出售的物品"
		_sell_list.add_child(empty_label)
	else:
		for item in sellable_items:
			var button := Button.new()
			button.theme = preload("res://Prototyping/HUD/pixelated.tres")
			button.text = "%s  售价 %d" % [_item_label(item), _sell_price(item)]
			button.pressed.connect(_on_sell_pressed.bind(item))
			_sell_list.add_child(button)

	for item in _offers:
		var button := Button.new()
		button.theme = preload("res://Prototyping/HUD/pixelated.tres")
		button.text = "%s  价格 %d" % [_item_label(item), _buy_price(item)]
		button.disabled = GameState.gold < _buy_price(item)
		button.pressed.connect(_on_buy_pressed.bind(item))
		_buy_list.add_child(button)


func _generate_offers() -> void:
	_offers.clear()

	var region := GameState.get_current_region()
	if region == null and not GameState.region_configs.is_empty():
		region = GameState.region_configs[0]
	if region == null:
		return

	var other_pool: Array[MobData] = []
	for config in GameState.region_configs:
		if config == region:
			continue
		other_pool.append_array(config.enemy_pool)

	var item_count := randi_range(SHOP_ITEM_COUNT_MIN, SHOP_ITEM_COUNT_MAX)
	var dice_offer_count := max(item_count - POTION_STOCK, 0)
	for _idx in dice_offer_count:
		var use_exotic := not other_pool.is_empty() and randf() < region.shop_exotic_chance
		var pool := other_pool if use_exotic else region.enemy_pool
		_offers.append(MapGenerator.generate_item_from_pool(pool))

	for _idx in POTION_STOCK:
		_offers.append(HealthPotionItem.new())


func _on_sell_pressed(item: Item) -> void:
	GameState.add_gold(_sell_price(item))
	GameState.remove_item(item)
	refresh()


func _on_buy_pressed(item: Item) -> void:
	if not GameState.spend_gold(_buy_price(item)):
		return
	GameState.add_item(item)
	_offers.erase(item)
	refresh()


func _item_label(item: Item) -> String:
	if item is DiceFaceItem:
		return "%s %d" % [Consts.SYMBOLS.get(item.element, "?"), item.digit]
	return item.display_name


func _buy_price(item: Item) -> int:
	if item is DiceFaceItem:
		return item.buy_value
	if item is HealthPotionItem:
		return item.buy_value
	return 0


func _sell_price(item: Item) -> int:
	if item is DiceFaceItem:
		return item.sell_value
	if item is HealthPotionItem:
		return item.sell_value
	return 0


func _clear_children(node: Node) -> void:
	for child in node.get_children():
		node.remove_child(child)
		child.queue_free()
