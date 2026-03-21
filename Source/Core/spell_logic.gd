extends Object
class_name SpellLogic

static var _logic_cache: Dictionary = {}

static func execute(logic_name: String, ctx: SpellContext) -> void:

	if logic_name == "":
		return

	if not _logic_cache.has(logic_name):
		var fullpath := "res://Source/SpellLogics/" + logic_name + ".gd"
		var script := load(fullpath)
		assert(script != null, "SpellLogic: script not found: " + fullpath)
		_logic_cache[logic_name] = {
			"PickTarget": Callable(script, "PickTarget"),
			"Do": Callable(script, "Do")
		}
	
	var logic: Dictionary = _logic_cache[logic_name]
	var targets: Array[Mob] = logic.PickTarget.call(ctx)

	if len(targets) == 0:
		return

	ctx.targets = targets
	await logic.Do.call(ctx)
