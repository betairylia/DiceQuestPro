extends Object
class_name PickSingleFront

static func PickTarget(ctx: SpellContext) -> Array[Mob]:
    var alived: Array[Mob] = ctx.targets.filter(func(m:Mob): return m.is_alive())
    if len(alived) > 0:
        return [alived[0]]
    return []
