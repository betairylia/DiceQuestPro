extends Object
class_name AllyHealAll


static func PickTarget(ctx: SpellContext) -> Array[Mob]:
	return ctx.allies.filter(func(mob: Mob): return mob != null and mob.is_alive())


static func Do(ctx: SpellContext) -> void:
	for mob in ctx.targets:
		if mob == null or not mob.is_alive():
			continue
		mob.get_damage_heal(DamageInfo.new(
			ctx.power,
			Consts.DamageType.Healing
		))
