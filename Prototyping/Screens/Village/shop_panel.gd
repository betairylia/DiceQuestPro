extends VBoxContainer

const SHOP_ITEM_COUNT_MIN := 3
const SHOP_ITEM_COUNT_MAX := 5

@onready var _gold_label: RichTextLabel = $GoldLabel
@onready var _sell_list: VBoxContainer = $Lists/SellColumn/SellList
@onready var _buy_list: VBoxContainer = $Lists/BuyColumn/BuyList

var _offers: Array[DiceFaceItem] = []


func _ready() -> void:
	if _offers.is_empty():
		_generate_offers()
	refresh()


func refresh() -> void:
	_gold_label.text = "[center]金币 %d[/center]" % GameState.gold

	for child in _sell_list.get_children():
		child.queue_free()
	for child in _buy_list.get_children():
		child.queue_free()

	if GameState.inventory.is_empty():
		var empty_label := RichTextLabel.new()
		empty_label.fit_content = true
		empty_label.text = "[center]没有可出售的骰面[/center]"
		_sell_list.add_child(empty_label)
	else:
		for item in GameState.inventory:
			var button := Button.new()
			button.theme = preload("res://Prototyping/HUD/pixelated.tres")
			button.text = "%s %d  售价 %d" % [Consts.SYMBOLS.get(item.element, "?"), item.digit, item.sell_value]
			button.pressed.connect(_on_sell_pressed.bind(item))
			_sell_list.add_child(button)

	for item in _offers:
		var button := Button.new()
		button.theme = preload("res://Prototyping/HUD/pixelated.tres")
		button.text = "%s %d  价格 %d" % [Consts.SYMBOLS.get(item.element, "?"), item.digit, item.buy_value]
		button.disabled = GameState.gold < item.buy_value
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
	for _idx in item_count:
		var use_exotic := not other_pool.is_empty() and randf() < region.shop_exotic_chance
		var pool := other_pool if use_exotic else region.enemy_pool
		_offers.append(MapGenerator.generate_item_from_pool(pool))


func _on_sell_pressed(item: DiceFaceItem) -> void:
	GameState.add_gold(item.sell_value)
	GameState.remove_item(item)
	refresh()


func _on_buy_pressed(item: DiceFaceItem) -> void:
	if not GameState.spend_gold(item.buy_value):
		return
	GameState.add_item(item)
	_offers.erase(item)
	refresh()
