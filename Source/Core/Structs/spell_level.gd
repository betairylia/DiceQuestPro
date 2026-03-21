extends Resource
class_name SpellLevel

@export var display_name: String
@export var pattern: String            # e.g. "FFF", "SSSS"
@export var logic: String = "single_damage"  # logic script name
@export var power: int = 0         # spell power
@export var anim: String
