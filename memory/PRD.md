# Puck King Hell — PRD

## Original Problem Statement
Implement the next UI milestones for **Puck King Hell**, a Godot 4.6 arcade
hockey roguelite. Iteration 1 delivered the first production UI pass; this
iteration extends it with a match clock, win conditions, main menu, settings
stub, game-over screen, and procedural audio pipeline — and fixes the
goal-banner positioning bug.

## Game Vision
Arcade hockey, not simulation. Fun > realism. Bold, large, controller-friendly
UI. Big banners, wrestling-style spectacle. Couch + TV first.

## User Persona
Couch player on a TV with an Xbox-style controller (with mouse + keyboard as a
secondary).

## Static Core Requirements
- React fast and arcade-loud at all viewport sizes.
- Controller-first: focus-based navigation, big buttons.
- Reusable UI components for future features (overlays, banners, panels).

## What's been implemented

### UI Milestone 1 (previous)
- Heavy-metal HUD: scoreboard, upgrade panel, notifications, goal banner.
- Reward Draft modal with three cards (mouse / 1-2-3 / A-X-Y).
- Pause Menu (ESC / Start).

### UI Milestone 2 (this iteration — 2026-01)
- **Main Menu** scene with preset picker, settings stub, quit.
- **Match presets**: Quick Hit / Standard / Marathon / Sudden Death /
  Adventure (randomised, equatable). Player-selectable from main menu.
- **Match clock + period system** with overtime, sudden-death, mercy rule,
  and draw handling.
- **Scoreboard rebuild**: HOME tile / center timer-and-period tile / AWAY
  tile with team logo glyphs.
- **Game Over modal** with rematch and return-to-menu options.
- **Goal banner centering bug** fixed (`set_anchors_and_offsets_preset`).
- **Procedural audio pipeline**: `SfxPlayer` autoload generates 16-bit PCM
  samples in-code for goal horn, hits, UI clicks, chimes, whistles, match
  win — routed through a 6-player pool. Drop real .wav files in
  `_build_samples()` later.
- **Quit-to-menu** now actually goes to the Main Menu (was quitting the app).
- **Match session** autoload carries preset + last-match result between
  scenes.

## Files Modified
- `project.godot` (main scene → MainMenu, new autoloads)
- `scripts/hockey/test_rink.gd`
- `scripts/ui/match_hud.gd`
- `scripts/ui/goal_banner.gd`
- `scripts/ui/notification_banner.gd`, `pause_menu.gd`, `reward_draft.gd`,
  `upgrade_card.gd` (anchors-preset bug fix)

## Files Created
- `scenes/ui/MainMenu.tscn`, `scenes/ui/GameOver.tscn`
- `scripts/ui/main_menu.gd`, `game_over.gd`
- `scripts/data/match_preset.gd`
- `scripts/match/match_clock.gd`
- `scripts/core/match_session.gd`
- `scripts/audio/sfx_player.gd`
- `docs/UI.md` (updated)
- `docs/main_menu.png`, `hud_initial.png`, `goal_banner.png`,
  `reward_draft.png`, `after_reward.png`, `pause_menu.png`, `game_over.png`

## Validation
Project scanned + run headlessly with Godot 4.3 (arm64) on the build
environment. Screenshots of all 7 key states (main menu → match → goal
banner → reward draft → after reward → pause → game over) captured under
Xvfb at 2560×1440 and pixel-sampled to verify centering and colour
correctness.

Specifically for the goal banner:
- Pre-fix: hot-gold "GOAL!" pixel centroid at `(782, 76)` (top-left).
- Post-fix: hot-gold "GOAL!" pixel centroid at `(1265, 691)` versus viewport
  centre `(1280, 720)`.

## Prioritized Backlog

### P1
- Real SFX files (drop .wav into `assets/audio/` and rewire `_build_samples`).
- Real upgrade card icons (replace the placeholder glyph in `upgrade_card.gd`).
- Apply Adventure-mode label to the scoreboard subtitle when picked
  (currently shows the rolled variant title via notification only).
- Proper rebinding screen (currently a "coming soon" line).

### P2
- Goalies + 5-on-5 skaters (UI scaffolding only — non-UI work).
- Music bus + procedural soundtrack stinger.
- Crowd ambience track.
- Per-upgrade ribbon tinting on draft cards.

### P3
- Localized strings (everything currently inline English).
- Replays / camera flourishes during the goal celebration.
- Achievement / unlock toasts using the existing notification banner.

## Next Action Items
1. Drop real SFX files in `assets/audio/` and wire them into
   `scripts/audio/sfx_player.gd`.
2. Author icon sprites for the three current upgrades; swap the glyph in the
   reward-card icon area.
3. Build a "ROUND CLEARED" celebration screen when Adventure runs gain a
   `runs` concept (separate from a single match).
