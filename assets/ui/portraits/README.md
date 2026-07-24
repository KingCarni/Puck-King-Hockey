# Puck King Hell — Player Portraits

Character portrait art for roster cards, HUD, and Adventure Mode.

Expected files (referenced by `scripts/roster/roster_catalog.gd`):

- `duane_clutzky.png`
- `gronk_mckrunk.png`

Guidelines:

- Square (1024×1024 or larger), transparent or dark badge-style background.
- Match the approved badge concept: bold outlined character bust inside a
  team-colored shield/circle frame with name plate and position strip.
- `PlayerDefinition.get_portrait_texture()` returns `null` safely when a
  portrait is missing, so files can land here incrementally.
