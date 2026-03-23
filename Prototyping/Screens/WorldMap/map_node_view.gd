extends Button

var node_id: int = -1


func configure(node: MapNode, reachable: bool, visited: bool) -> void:
	node_id = node.id
	text = _icon_for(node.type)
	disabled = not reachable
	focus_mode = Control.FOCUS_NONE
	custom_minimum_size = Vector2(42, 30)
	modulate = Color(0.55, 0.55, 0.60) if visited else (Color.WHITE if reachable else Color(0.85, 0.85, 0.90))
	tooltip_text = "%s" % _label_for(node.type)


func _icon_for(node_type: int) -> String:
	match node_type:
		MapNode.NodeType.COMBAT:
			return "⚔"
		MapNode.NodeType.BOSS:
			return "☠"
		MapNode.NodeType.TREASURE:
			return "📦"
		MapNode.NodeType.VILLAGE:
			return "村"
		_:
			return "?"


func _label_for(node_type: int) -> String:
	match node_type:
		MapNode.NodeType.COMBAT:
			return "战斗"
		MapNode.NodeType.BOSS:
			return "首领"
		MapNode.NodeType.TREASURE:
			return "宝藏"
		MapNode.NodeType.VILLAGE:
			return "村庄"
		_:
			return "未知"
