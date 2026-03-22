extends PickCasters

static func Do(ctx: SpellContext):
    for c in ctx.targets:
        c.get_damage_heal(DamageInfo.new(
            ctx.power,
            Consts.DamageType.Healing
        ))
