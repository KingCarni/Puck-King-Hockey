# Puck King Hell — PRD

## Original Problem Statement
Implement the first production-quality UI pass for **Puck King Hell**, a Godot 4.6
arcade hockey roguelite. The gameplay (movement, sprint, possession, shooting,
checking, AI, scoring, post-match reward draft, upgrades) is already in place but
the UI is debug/prototype quality. Replace it with proper UI scenes for:
scoreboard, upgrade display, reward draft, goal celebration banner, reusable
notification system, and pause menu — all controller/TV friendly, bold, arcade
in style (Mutant League Hockey / NHL Hitz / pro wrestling vibe).

## Game Vision
- Arcade hockey, not a simulation.
- Fun > realism. Spectacle, personality, readability.
- Bold, large, controller-friendly UI. Big scoreboards, animated banners, goal
  celebrations, wrestling-style presentation.

## User Persona
- Couch player on a TV with an Xbox-style controller.
- Also playable at desk with mouse + keyboard.

## Core Requirements (static)
- React fast and arcade-loud at all viewport sizes.
- Controller-first: focus-based navigation, big buttons.
- Reusable UI components for future features (e.g. minimap, power meters).

## What's been implemented — 2026-01

### UI Milestone 1 (this iteration)
- **Theme palette autoload** (`scripts/ui/ui_palette.gd`) — fonts (Bungee +
  Bungee Inline), colour constants, label/button/panel style helpers.
- **MatchHUD** scene + script — top-center scoreboard with team pills, big gold
  scores, VS plate, "PUCK KING HELL" identity; top-left "PERKS" panel that
  pops new perks in; top-right pause hint; hosts notification banner + goal
  banner.
- **Notification banner** — reusable slide-down/hold/slide-up banner.
- **Goal banner** — full-width punch-in/hold/punch-out celebration; tints
  home/away appropriately; pulses the relevant score number.
- **Reward draft** modal — three big arcade cards with ribbon, icon, title,
  description and hotkey pill. Mouse click, focus-driven keyboard navigation,
  hotkeys 1/2/3 and pad A/X/Y all wired up.
- **Pause menu** — Resume / Restart Match / Quit To Menu, opened via ESC or
  controller Start. Resume button auto-focused. Always processes during pause.
- **Project config** — added `pause_menu` input action (ESC + JOY_BUTTON_START)
  and `UiPalette` autoload.
- **Refactor**: removed all UI building code from `scripts/hockey/test_rink.gd`.
  It now instantiates the three new UI scenes and coordinates goal celebration
  timing with the reward draft (banner plays first, then cards appear).

## Files Changed
- `project.godot`
- `scripts/hockey/test_rink.gd`

## Files Created
- `assets/fonts/Bungee-Regular.ttf` (+ `.import`)
- `assets/fonts/BungeeInline-Regular.ttf` (+ `.import`)
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
- `docs/UI.md`
- `docs/01_initial.png` … `docs/05_pause_menu.png`

## Validation Done
Project was scanned and run headlessly with Godot 4.3 (arm64) on the build
environment. Five state screenshots were captured under Xvfb at 2560×1440 and
pixel-sampled for expected gold/red/white regions in each UI state (initial,
goal banner, reward draft, post-reward, pause menu). No runtime errors.

## Prioritized Backlog
- **P1**: Main menu scene so "Quit To Menu" can land somewhere instead of
  exiting the application.
- **P1**: Period timer + match length + win condition UI.
- **P2**: Sound effects (puck hit, goal horn, banner whoosh) — currently silent.
- **P2**: Localized strings (currently inline English in scripts).
- **P2**: Settings menu (sensitivity, volume, key/pad rebinding).
- **P3**: Icon art for upgrade cards (currently placeholder star glyph).
- **P3**: Per-upgrade colour theme on the card ribbon.
- **P3**: HUD shake on big hits / goals.

## Next Action Items
1. Add a main menu scene (`scenes/menus/MainMenu.tscn`) and route
   "Quit To Menu" to it.
2. Add a period timer + first-to-N or timed win condition to the scoreboard.
3. Hook up goal horn / SFX once an audio pipeline exists.
