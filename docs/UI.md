# Production UI Pass — Puck King Hell

This document describes the first production-quality UI pass for Puck King Hell.

## Vision

Heavy-metal arcade hockey, fight-night energy. Bold gold + blood-red + bone-white
on near-black, chunky display fonts, big readable numbers. The HUD is meant to be
legible across a couch with a TV and a controller.

## What was built

| Area                 | Result                                                                                          |
|----------------------|-------------------------------------------------------------------------------------------------|
| Scoreboard           | Top-center, gold-bordered panel. HOME/AWAY pills, huge gold scores, VS plate, PUCK KING HELL.   |
| Upgrade display      | Top-left panel with "PERKS" ribbon. Compact list of pills, animated pop-in for new perks.       |
| Reward draft         | Three big arcade cards with PICK ribbon, icon, title, description, hotkey pill.                 |
| Goal celebration     | Full-width banner with stripes. Punch-in (0.18s), settle, hold (~2.5s), punch-out (0.34s).      |
| Notification system  | Reusable banner that slides in from the top. Used for "FACEOFF AT CENTER", "PICKED UP: ...".    |
| Pause menu           | ESC or controller Start. Resume / Restart Match / Quit. Focus on Resume by default.             |
| Score pulse          | Score number pulses (scale up, ease back) on every goal.                                        |

## Architecture

```
project.godot
  autoload: UiPalette  →  scripts/ui/ui_palette.gd

assets/
  fonts/
    Bungee-Regular.ttf        # main display font
    BungeeInline-Regular.ttf  # accent font

scenes/ui/
  MatchHUD.tscn               # CanvasLayer host for HUD widgets
  RewardDraft.tscn            # CanvasLayer modal
  PauseMenu.tscn              # CanvasLayer modal (always processes)

scripts/ui/
  ui_palette.gd               # autoload: fonts, colours, label/button styling helpers
  match_hud.gd                # scoreboard + upgrade list + notification + goal banner host
  notification_banner.gd      # reusable transient banner (slide-in / hold / slide-out)
  goal_banner.gd              # big "GOAL!" celebration banner
  upgrade_card.gd             # single reward draft card (hover/focus animated)
  reward_draft.gd             # three-card modal
  pause_menu.gd               # pause overlay

scenes/match/TestRink.tscn    # unchanged (root node)
scripts/hockey/test_rink.gd   # UI logic removed; now instantiates the three scenes
```

The `UiPalette` autoload owns the fonts and provides convenience helpers
(`style_display_label`, `style_button`, `make_panel_box`, ...). Every UI widget
queries it on `_ready`, so swapping the palette later changes the whole game.

`test_rink.gd` no longer builds any UI. It instantiates `MatchHUD`,
`RewardDraft` and `PauseMenu`, then calls the public methods:

```gdscript
_hud.set_score(home, away)
_hud.set_upgrades(list)
_hud.celebrate_goal("HOME")
_hud.show_notification("FACEOFF AT CENTER")
_reward_draft.show_draft()
_pause_menu.toggle()
```

## Input

A new project-level input action has been added:

```
pause_menu = Escape, JOY_BUTTON_START (Pad index 6)
```

Existing actions (`skate_*`, `puck_shoot`, `body_check`) are untouched.

## Files Changed

- `project.godot` — added `UiPalette` autoload + `pause_menu` input action.
- `scripts/hockey/test_rink.gd` — UI building removed; now wires up the three new UI scenes and coordinates goal celebration timing with the reward draft.

## Files Created

- `assets/fonts/Bungee-Regular.ttf`
- `assets/fonts/BungeeInline-Regular.ttf`
- `scenes/ui/MatchHUD.tscn`
- `scenes/ui/RewardDraft.tscn`
- `scenes/ui/PauseMenu.tscn`
- `scripts/ui/ui_palette.gd`
- `scripts/ui/match_hud.gd`
- `scripts/ui/notification_banner.gd`
- `scripts/ui/goal_banner.gd`
- `scripts/ui/upgrade_card.gd`
- `scripts/ui/reward_draft.gd`
- `scripts/ui/pause_menu.gd`
- `docs/UI.md` (this document)
- `docs/01_initial.png` ... `docs/05_pause_menu.png` (state screenshots)

## Testing Instructions

### One-time setup
1. Open the project in **Godot 4.6** (or later) once. The editor will auto-import
   the two `.ttf` files in `assets/fonts/`, generating their `.import` sidecars.
2. Press F5 to play. Main scene is `res://scenes/match/TestRink.tscn`.

### Scoreboard
- On launch, the top-center scoreboard should read `HOME 0 [VS] 0 AWAY` with a
  big gold border, blood-red and steel-blue team pills, and a "PUCK KING HELL"
  block under the VS plate.
- Resize the window: the scoreboard must stay centred at the top and remain
  legible at small and large viewport sizes.

### Upgrade display
- Top-left "PERKS" panel should read `NO PERKS YET` on launch.
- After picking a reward, the picked perk title appears as an upgrade pill in
  this panel (with a pop-in animation).
- Picking multiple rewards stacks more pills.

### Reward draft
- Score a goal into the right (HOME) net. The GOAL banner plays, then ~2.6s
  later three big cards appear. Each card has:
  - A red "PICK N" ribbon
  - An icon area with a placeholder glyph
  - Title in big gold Bungee
  - Description body
  - Hotkey pill (`1 / A`, `2 / X`, `3 / Y`)
- Hover with mouse — the card scales up and the border glows hot-gold.
- D-pad / arrow keys move focus — focused card uses the same hover style.
- Press `1`, `2` or `3` on keyboard, or `A`, `X`, `Y` on the controller, or
  click the card. The selection is applied and the draft closes.

### Goal celebration banner
- HOME goal: stripes turn steel-blue, "GOAL!" punches in, subtitle reads
  "HOME SCORES". Banner lasts ~3s total.
- AWAY goal: stripes turn fire-red, subtitle reads "AWAY SCORES". The faceoff
  resets after the banner finishes.
- The score number on the scoreboard pulses when its team scores.

### Notifications
- On launch, you should briefly see "FIRST HOME GOAL TRIGGERS REWARD DRAFT".
- After picking a reward, a "PICKED UP: <name>" notification appears.
- Each notification slides in from the top, holds, and slides out.

### Pause menu
- Press **ESC** on keyboard, or the **Start** button on the controller. The
  game pauses, screen dims, and a panel shows PAUSED with three buttons.
- Resume button is auto-focused (great for controllers).
- `Resume`: closes the menu and unpauses.
- `Restart Match`: reloads the current scene.
- `Quit To Menu`: quits the application (no main-menu scene exists yet).
- Pressing ESC / Start again while paused also resumes.

### What was NOT changed
- Player movement, sprint, puck possession, shooting and checking.
- AI opponent behaviour.
- Reward logic / stat math.
- The 3D rink scene (`TestRink.tscn`) itself — only the script that builds it
  is now leaner.

## Screenshots

| State | File |
|-------|------|
| Initial HUD | `docs/01_initial.png` |
| Goal banner | `docs/02_goal_banner.png` |
| Reward draft | `docs/03_reward_draft.png` |
| After reward pick | `docs/04_after_reward.png` |
| Pause menu | `docs/05_pause_menu.png` |
