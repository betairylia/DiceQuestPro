extends PickSingleFront

static func Do(ctx: SpellContext):
    ctx.targets[0].get_damage_heal(DamageInfo.new(
        ctx.power,
        Consts.DamageType.Special
    ))
