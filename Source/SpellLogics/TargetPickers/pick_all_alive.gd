extends Object
class_name PickAllAlive

static func PickTarget(ctx: SpellContext) -> Array[Mob]:
    var alived: Array[Mob] = ctx.targets.filter(func(m:Mob): return m.is_alive())
    return alived
