# Production UI Pass — Puck King Hell

Heavy-metal arcade hockey HUD, menus, audio. Designed for couch + controller, not
broadcast television.

## What was built in this iteration

| Area                | Result                                                                                          |
|---------------------|-------------------------------------------------------------------------------------------------|
| Main Menu           | Title, preset picker (Quick Hit / Standard / Marathon / Sudden Death / Adventure), Settings, Quit. |
| Settings (stub)     | Master / SFX / Music sliders wired to the audio bus. Rebinding flagged "coming soon".            |
| Scoreboard          | HOME tile (blue glow) + center Timer/Period tile (gold) + AWAY tile (red glow). Live clock.      |
| Match Clock         | Period countdown, period changes, overtime, sudden-death, mercy rule, first-to-N, draw handling. |
| Win Condition       | Fires `match_ended(winner, home, away)`, opens Game Over modal.                                  |
| Game Over Modal     | "YOU WIN / YOU LOSE / DRAW" + score + Rematch / Return To Menu.                                  |
| Upgrade Display     | Compact pills with icon glyph; live updates on draft pick.                                       |
| Reward Draft        | Three big arcade cards, mouse / 1-2-3 keys / A-X-Y pad navigation.                               |
| Goal Banner         | **Now properly centred on screen** (set_anchors_and_offsets_preset). Lightning-bolt accents.    |
| Pause Menu          | Resume / Restart / Quit-To-Menu (now lands on the real Main Menu, not the desktop).              |
| Audio Pipeline      | `SfxPlayer` autoload generates 16-bit PCM samples for goal-horn, hits, UI clicks, chimes.        |

## Architecture

```
project.godot
  autoload: UiPalette       — colour palette + label/button stylers
            SfxPlayer        — procedural audio bus
            MatchSession     — preset hand-off between scenes

assets/fonts/
  Bungee-Regular.ttf
  BungeeInline-Regular.ttf

scenes/ui/
  MainMenu.tscn              Main menu Control
  MatchHUD.tscn              In-match HUD CanvasLayer
  RewardDraft.tscn           CanvasLayer modal
  PauseMenu.tscn             CanvasLayer modal (always processes)
  GameOver.tscn              CanvasLayer modal (always processes)

scripts/data/
  match_preset.gd            class_name MatchPreset — catalog + adventure roll + clock helpers

scripts/match/
  match_clock.gd             class_name MatchClock — timer + win conditions + signals

scripts/core/
  match_session.gd           autoload MatchSession — preset hand-off + result memory

scripts/audio/
  sfx_player.gd              autoload SfxPlayer — procedural samples + pool of AudioStreamPlayer

scripts/ui/
  ui_palette.gd              UiPalette autoload
  main_menu.gd               main menu + settings stub
  match_hud.gd               scoreboard / upgrades / notifications / banner host
  notification_banner.gd     reusable slide-down banner
  goal_banner.gd             big centred GOAL! banner
  upgrade_card.gd            single reward draft card
  reward_draft.gd            three-card modal
  pause_menu.gd              pause overlay
  game_over.gd               post-match modal

scenes/match/TestRink.tscn   unchanged (still the in-match scene)
scripts/hockey/test_rink.gd  drives match clock + UI + audio events.
                              Quit-To-Menu now `change_scene_to_file(MainMenu)`.
```

## Match presets

Selectable from the main menu (`MatchPreset.catalog()`):

| ID            | Length              | Win condition                      |
|---------------|---------------------|------------------------------------|
| QUICK HIT     | 3 × 60s             | Most goals; mercy at +3            |
| STANDARD      | 3 × 90s             | Most goals; OT on tie              |
| MARATHON      | 3 × 3 min           | Most goals; OT on tie              |
| SUDDEN DEATH  | no clock            | First to 3                          |
| ADVENTURE     | randomised          | Random equatable variant per match |

Adventure mode rolls one of four variants (sprint / duel / double-or-nothing /
blitz). All variants are tuned to roughly the same difficulty as STANDARD.

## Audio events

`SfxPlayer` exposes these ids — call `SfxPlayer.play(SfxPlayer.ID_GOAL_HORN)` etc.

| ID                | Fires when                                  |
|-------------------|---------------------------------------------|
| GOAL_HORN         | A goal is scored                            |
| CHECK_HIT         | Body check connects *(wired for future)*    |
| UI_CLICK          | Any menu button press                       |
| UI_FOCUS          | Slider scrubbed / preset focused            |
| REWARD_PICK       | An upgrade card is chosen                   |
| PERIOD_END        | A period changes / OT begins                |
| MATCH_WIN         | `match_ended` fires                         |

To swap in real .wav files, edit `_build_samples()` in `scripts/audio/sfx_player.gd`
and assign `_samples[ID_*] = load("res://path/to.wav")`.

## Critical bug fixed

The previous GOAL banner appeared in the **top-left** because
`set_anchors_preset(FULL_RECT, false)` recomputes offsets to keep the rect at
its current (zero) position when called inside `_ready()` (i.e. after the
Control is parented). All UI scripts now use
`set_anchors_and_offsets_preset(FULL_RECT)` which sets both anchors AND
offsets to the preset values, so the GoalBanner properly fills the viewport
and the inner banner panel ends up centred at `(viewport_w/2, viewport_h/2)`.

Pixel verification: hot-gold centroid of the GOAL! text was `(782, 76)`
before the fix and is now `(1265, 691)` versus a viewport centre of `(1280, 720)`.

## Testing instructions

### One-time setup
1. Open the project in Godot 4.6 (or run `godot --headless --import` once).

### Boot to menu
- Launching the project lands on **MainMenu**.
- Pick a preset on the left (the right blurb updates).
- Press **PLAY MATCH** to start.
- **SETTINGS** opens an overlay with three volume sliders + a "rebind coming
  soon" line. ESC / back-button closes it.
- **QUIT** exits the application. (ESC on the menu does the same.)

### In a match
- Top-center scoreboard shows the live timer (e.g. `01:24`), period label
  (`1ST PERIOD` / `2ND PERIOD` / `OVERTIME`), HOME score / name / logo, AWAY
  score / name / logo. Score numbers pulse on every goal.
- Top-left UPGRADES panel reads `NO PERKS YET` and stacks pills with the
  upgrade glyph + name as you collect them.
- Top-right hint: `ESC / START — PAUSE`.

### Goal flow
- Drive the puck into the right net (HOME goal).
- Banner punches in, plays for ~3s, with lightning-bolt accents and the
  HOME blue-tinted backdrop. After it fades, the **Reward Draft** appears.
- Pick a card with mouse, 1/2/3, or A/X/Y on the pad. A "PICKED UP: ..."
  notification slides down. The new perk also appears in the top-left panel.
- For AWAY goals, the banner plays with the red AWAY tint and the puck is
  reset after the banner.

### Period flow
- The clock counts down. When it hits zero, the period advances and a
  notification slides in (`2ND PERIOD — START!`).
- After the last period:
  - If scores differ, the match ends.
  - If tied and the preset allows OT, `OVERTIME` starts and the next goal
    wins.

### Pause
- ESC or controller Start opens the **Pause Menu**.
- **Resume** unpauses. **Restart Match** reloads the scene. **Quit To Menu**
  changes the scene back to the **Main Menu** (no longer quits the app).

### Game over
- A modal appears with `YOU WIN! / YOU LOSE / DRAW`, the final score, and:
  - **Rematch** reloads the same preset.
  - **Return To Menu** goes back to the Main Menu.

### Audio
- Every goal plays a procedural goal-horn blat.
- UI clicks and slider scrubs produce a short pop.
- Period changes and the match win each play a short chime/whistle.
- All sounds are generated in code from sine + saw waves and routed through
  a 6-player pool. No external audio assets are required.

## Files Created (this iteration)

- `scenes/ui/MainMenu.tscn`
- `scenes/ui/GameOver.tscn`
- `scripts/ui/main_menu.gd`
- `scripts/ui/game_over.gd`
- `scripts/data/match_preset.gd`
- `scripts/match/match_clock.gd`
- `scripts/core/match_session.gd`
- `scripts/audio/sfx_player.gd`
- `docs/main_menu.png`, `hud_initial.png`, `goal_banner.png`,
  `reward_draft.png`, `after_reward.png`, `pause_menu.png`, `game_over.png`

## Files Modified (this iteration)

- `project.godot` — main scene → MainMenu, two new autoloads (SfxPlayer,
  MatchSession).
- `scripts/hockey/test_rink.gd` — match clock integration, audio events,
  game-over signal handling, Quit-To-Menu now changes scene to Main Menu.
- `scripts/ui/match_hud.gd` — scoreboard rebuilt with HOME / Center / AWAY
  tiles, timer + period readouts, team logo glyphs, upgrade pill icons.
- `scripts/ui/goal_banner.gd` — full rewrite to fix centering, lightning-bolt
  flanks, team-tinted accents.
- `scripts/ui/notification_banner.gd`, `pause_menu.gd`, `reward_draft.gd`,
  `upgrade_card.gd` — all `set_anchors_preset` calls migrated to
  `set_anchors_and_offsets_preset`.

## Screenshots

| State | File |
|-------|------|
| Main Menu | `docs/main_menu.png` |
| HUD (match start) | `docs/hud_initial.png` |
| Goal banner | `docs/goal_banner.png` |
| Reward draft | `docs/reward_draft.png` |
| After reward | `docs/after_reward.png` |
| Pause menu | `docs/pause_menu.png` |
| Game over | `docs/game_over.png` |
