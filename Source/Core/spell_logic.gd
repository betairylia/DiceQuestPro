extends Object
class_name SpellLogic

static var _logic_cache: Dictionary = {}

static func execute(logic_name: String, ctx: SpellContext) -> void:
	if not _logic_cache.has(logic_name):
		var fullpath := "res://Source/Spells/" + logic_name + ".gd"
		var script := load(fullpath)
		assert(script != null, "SpellLogic: script not found: " + fullpath)
		_logic_cache[logic_name] = Callable(script, "_do")
	
	var logic: Callable = _logic_cache[logic_name]
	await logic.call(ctx)
