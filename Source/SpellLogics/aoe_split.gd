extends PickAllAlive

static func Do(ctx: SpellContext):
    for target in ctx.targets:
        target.get_damage_heal(DamageInfo.new(
            ctx.power / len(ctx.targets),
            Consts.DamageType.Special
        ))
