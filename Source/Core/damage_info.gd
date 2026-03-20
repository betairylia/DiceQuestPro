class_name DamageInfo
extends Object

var value: int
var type: Consts.DamageType

func _init(value: int, type: Consts.DamageType) -> void:
    self.value = value
    self.type = type
