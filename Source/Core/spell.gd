extends Resource
class_name Spell

@export var display_name: String
# Levels ordered low→high, e.g. ["SSS","SSSS","SSSSS","SSSSSS"]
@export var patterns: Array[String]
