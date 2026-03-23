# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running the Project

- **Engine**: Godot 4.6 (GL Compatibility renderer)
- **Run**: Open in Godot editor and press F5, or use `godot --path .` from the project root
- **Main scene**: `res://Prototyping/Prototype.tscn`
- No build step required; Godot handles compilation on run

## Project Architecture

The codebase is split into two top-level directories:

- **`Source/`** — Pure logic systems (no scene dependencies)
- **`Prototyping/`** — Scenes, UI, and game content (.tres resources)

### Core Systems

**Combat loop** (`Prototyping/combat.gd`): Orchestrates the full turn cycle across 5 `CombatExecPhase` states: Preparation → PlayerRegular → PlayerSpells → EnemyRegular → EnemySpells. Each turn: rolls environment die → rolls enemy dice (auto-matches spells) → rolls player dice (matches spells, awaits player input) → player presses Act → all phases execute sequentially.

**Dice matching** (`Source/Core/dice_matcher.gd`): Pattern matching engine. Patterns like `"FFF"` (3 fire) or `"Sppp"` (1 sword + 3 physical-any) are parsed against rolled dice. Extreme rolls (last face on a die) count as 2 tokens. Matching is greedy — highest-level spells matched first, highest-digit dice consumed first.

**Spell execution** (`Source/Core/spell_logic.gd` + `Source/SpellLogics/`): Dynamic script loader. Each spell's `logic` field names a script in `Source/SpellLogics/` (e.g. `"aoe_split"`). That script exposes `PickTarget()` and `Do()` functions. Adding a new spell type = adding a new `.gd` file there.

**Mob base class** (`Source/Core/mob.gd`): Health, dice, animations, death/revive. Signals: `being_attacked`, `health_changed`, `died`, `revived`, `dice_changed`. On death, swaps from `alive_dice` to `dead_dice`. `PlayerMob` extends this to show a DicePreview.

**Async pattern** (`Source/Core/Promise/`): `BindGroupAwait` runs multiple Callables concurrently (used for parallel dice roll animations). `AwaitWrapper` wraps a Callable into a signal-emitting node.

### Data & Content

All game content lives in `Prototyping/Data/` as Godot `.tres` Resource files:
- `Players/` — Player character definitions (`MobData` resources with nested `DiceData` arrays)
- `Enemies/` — Enemy definitions (same structure)
- `Spells/` — Spell definitions (`Spell` resources containing arrays of `SpellLevel`)

**DiceData fields**: `type` (Consts.DiceType enum: D4–D12), `elements` (array of element enum values per face), `bonus` (flat roll bonus).

**SpellLevel fields**: `display_name`, `pattern` (matching string), `logic` (script name), `power` (damage value), `anim`.

### Spell Spreadsheet Workflow

Spell balance is iterated in `DataSheets/Spells.fods` (LibreOffice Calc) → exported to `DataSheets/spells-Spells.csv` → imported via the `spell_importer` editor plugin (in `addons/spell_importer/`) which converts CSV rows into `.tres` Spell resources.

### Key Constants

`Source/Core/consts.gd` defines element enums, dice types, element category shorthands used in spell patterns (`p`=physical, `f`=fire, `w`=water/ice, `t`=thunder/radiant, `n`=nature, `d`=dark, `m`=magical), and element colors for UI.

### Autoload

`Tooltip` singleton (`Prototyping/HUD/Tooltip/tooltip.tscn`) is globally accessible for showing tooltips on hover.

## Adding Content

- **New enemy/player**: Create a `.tres` MobData resource in `Prototyping/Data/Enemies/` or `Players/`; assign `DiceData` resources for `alive_dice` and `dead_dice`.
- **New spell type**: Add a script to `Source/SpellLogics/` implementing `PickTarget(casters, allies, enemies)` and `Do(matched_spell, casters, allies, enemies)`. Reference it by filename (without `.gd`) in the spell's `logic` field.
- **New spells (balance iteration)**: Edit `DataSheets/Spells.fods`, export CSV, then use the spell_importer plugin from the Godot editor toolbar.
