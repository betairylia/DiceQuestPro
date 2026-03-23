extends Control

## Shop panel — buy and sell dice face items.

const SHOP_ITEM_COUNT_MIN := 3
const SHOP_ITEM_COUNT_MAX := 5

var _shop_items: Array[DiceFaceItem] = []


func _ready() -> void:
	_generate_shop_items()


func refresh() -> void:
	_update_gold_label()
	_update_sell_list()
	_update_buy_list()


func _generate_shop_items() -> void:
	_shop_items.clear()
	var count := randi_range(SHOP_ITEM_COUNT_MIN, SHOP_ITEM_COUNT_MAX)
	var region_idx := GameState.current_region_index
	var current_config: RegionConfig = null
	if region_idx < GameState.region_configs.size():
		current_config = GameState.region_configs[region_idx]

	for _i in count:
		var use_exotic := current_config and randf() < current_config.shop_exotic_chance
		var pool: Array[MobData]

		if use_exotic and GameState.region_configs.size() > 1:
			# Pick from a different region
			var other_idx := randi() % GameState.region_configs.size()
			while other_idx == region_idx and GameState.region_configs.size() > 1:
				other_idx = randi() % GameState.region_configs.size()
			pool = GameState.region_configs[other_idx].enemy_pool
		elif current_config:
			pool = current_config.enemy_pool
		else:
			continue

		_shop_items.append(MapGenerator._random_item_from_pool(pool))


func _update_gold_label() -> void:
	$GoldLabel.text = "金币: %d" % GameState.gold


func _update_sell_list() -> void:
	var container: VBoxContainer = $SellList
	for child in container.get_children():
		child.queue_free()

	for item in GameState.inventory:
		var btn := Button.new()
		var symbol: String = Consts.SYMBOLS.get(item.element, "?")
		btn.text = "%s %d  [卖 %d金]" % [symbol, item.digit, item.sell_value]
		btn.pressed.connect(_on_sell.bind(item))
		container.add_child(btn)

	if GameState.inventory.is_empty():
		var label := Label.new()
		label.text = "(空)"
		container.add_child(label)


func _update_buy_list() -> void:
	var container: VBoxContainer = $BuyList
	for child in container.get_children():
		child.queue_free()

	for item in _shop_items:
		var btn := Button.new()
		var symbol: String = Consts.SYMBOLS.get(item.element, "?")
		btn.text = "%s %d  [买 %d金]" % [symbol, item.digit, item.buy_value]
		btn.disabled = GameState.gold < item.buy_value
		btn.pressed.connect(_on_buy.bind(item))
		container.add_child(btn)


func _on_sell(item: DiceFaceItem) -> void:
	GameState.add_gold(item.sell_value)
	GameState.remove_item(item)
	refresh()


func _on_buy(item: DiceFaceItem) -> void:
	if GameState.spend_gold(item.buy_value):
		GameState.add_item(item)
		_shop_items.erase(item)
		refresh()