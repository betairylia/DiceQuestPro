extends PickCasters

static func Do(ctx: SpellContext):
    for c in ctx.targets:
        c.revive(c.data.max_health / 2)
