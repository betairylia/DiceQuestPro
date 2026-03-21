extends Object
class_name Targeting


# Validates target given element at the exact time the attack lands
static func validate(element: Consts.Elements, target: Mob) -> bool:
	return target.is_alive()


## Returns the target this element attacks, or null if it doesn't attack.
## Filters to alive targets internally; individual arms can opt out (e.g. Revive).
static func pick(element: Consts.Elements, targets: Array[Mob]) -> Mob:
	var alive := targets.filter(func(m: Mob) -> bool: return m.is_alive())

	match element:
		Consts.Elements.Idle, Consts.Elements.Revive:
			return null
		Consts.Elements.Sword:
			if alive.is_empty():
				return null
			return alive[0]
		Consts.Elements.Bow:
			if alive.is_empty():
				return null
			return alive[-1]
		_:  # Fire, Water, Thunder, Wind, Nature, Revive — random alive target
			if alive.is_empty():
				return null
			return alive[randi() % alive.size()]
