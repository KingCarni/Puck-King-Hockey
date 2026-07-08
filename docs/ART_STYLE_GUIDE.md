# Puck King Hell — Art Style Guide

This document is the single source of truth for all Puck King Hell artwork.
Every new asset — sprites, icons, textures, effects, UI — must follow these rules
so the game keeps one cohesive visual language as content grows.

**One-line style statement:**

> NHL Hitz meets a heavy-metal fight night: bold silhouettes, thick outlines,
> championship lighting, red-vs-blue drama, gold everywhere it matters.

---

## 1. Design Pillars (art edition)

1. **Readability first.** Every asset must read at gameplay distance in under a
   quarter second. If a detail doesn't survive being shrunk to 64 px, delete it.
2. **Arcade, not simulation.** Exaggerate proportions, saturate colors, fake the
   lighting. Chunky beats accurate.
3. **Championship energy.** Assets should feel like the Stanley Cup final crossed
   with a monster-truck rally poster: rim light, glow, impact.
4. **Silhouette is king.** Team, role and state must be readable from shape and
   color alone, before any interior detail.

---

## 2. Master Palette

These are the canonical colors. They mirror `scripts/ui/ui_palette.gd` — if one
changes, change both.

| Name | Hex | Godot Color | Use |
|---|---|---|---|
| Black | `#0D0D0F` | `(0.05, 0.05, 0.06)` | Backgrounds, kick plates, puck body |
| Ink | `#141417` | `(0.08, 0.08, 0.09)` | Outlines, panel fills |
| Blood Red | `#D91A21` | `(0.85, 0.10, 0.13)` | Banners, goal frames, HELL accents |
| Fire Red | `#FF382E` | `(1.00, 0.22, 0.18)` | Hot highlights, warnings, overtime |
| Gold | `#FFC71A` | `(1.00, 0.78, 0.10)` | Crowns, borders, rewards, trophies |
| Hot Gold | `#FFEB4D` | `(1.00, 0.92, 0.30)` | Focus states, glint highlights |
| Bone | `#F7F5EB` | `(0.97, 0.96, 0.92)` | Primary text, jersey whites |
| Steel | `#8C949E` | `(0.55, 0.58, 0.62)` | Secondary text, metal, rivets |
| Home Blue | `#2E8CFF` | `(0.18, 0.55, 1.00)` | HOME team everything |
| Away Red | `#FF3338` | `(1.00, 0.20, 0.22)` | AWAY team everything |
| Ice White | `#E8F8FF` | `(0.91, 0.97, 1.00)` | Ice surface base |
| Glow Cyan | `#8CE6FF` | `(0.55, 0.90, 1.00)` | Ice glow, glass shine, freeze FX |

**Rules**

- HOME is always blue, AWAY is always red. Never swap. Never introduce a third
  team color into a match scene.
- Gold is *earned*: crowns, rewards, focus, victory. Don't use it as generic decoration.
- Backgrounds stay near-black (`#0D0D0F`–`#141417`) so ice, players and gold pop.

---

## 3. Shape & Outline Language

- **Outlines:** every gameplay sprite gets a thick ink (`#141417`) outline —
  4–5% of the sprite's width (e.g. 20–24 units on a 512 px sprite). UI icons use
  the same ratio inside their badge.
- **Corners:** chunky and rounded. Prefer rounded rectangles (radius ≈ 8–12% of
  the short side) and capsule shapes. No fragile thin spikes except FX.
- **Proportions:** characters are 2–2.5 heads tall equivalent in top-down mass —
  big shoulders, big helmet, small feet. Equipment is oversized (stick blades
  ~1.5× real width).
- **Lighting:** single implied light from screen-top. One highlight tone + one
  shadow tone per material, hard-edged (cel style). Add a soft radial rim/glow
  only for state feedback (possession, stun, charge).
- **Baked shadow:** ground sprites carry a soft elliptical shadow baked into the
  bottom of the sprite (black at ~35% alpha, radial fade) so they sit on the ice.

---

## 4. Typography

| Role | Font | Notes |
|---|---|---|
| Display / titles | **Bungee Regular** | All-caps, always. Ink outline 5–6 px, hard drop shadow (3, 4). |
| Accent / numbers | **Bungee Inline Regular** | Scoreboards, ribbons, pills. |

Text colors: Bone on dark panels, Gold for emphasis, Hot Gold for focus/hover.
Never place text directly on ice without an outline or a dark panel behind it.

---

## 5. Asset Specs & Naming

All source art is **SVG** (Godot 4 imports SVG natively; it rasterizes at import
time, so vectors stay crisp at any scale). Raster exports (from AI tools or
painting) are PNG. Everything lowercase snake_case, prefixed by category.

| Category | Location | Canvas | Prefix / example |
|---|---|---|---|
| Character sprites (top-down) | `assets/art/characters/` | 512×512 | `pkh_skater_home.svg` |
| Rink pieces | `assets/art/rink/` | fit content | `pkh_goal_net_topdown.svg` |
| Puck | `assets/art/puck/` | 256×256 | `pkh_puck_topdown.svg` |
| Power-up icons | `assets/art/powerups/` | 256×256 | `powerup_rocket_shot.svg` |
| UI icons | `assets/ui/icons/` | 128×128 | `icon_play.svg` |
| Effects concepts | `docs/art/` | any | `fx_concepts_sheet.svg` |
| Turnarounds / model sheets | `docs/art/` | any | `character_turnaround_skater.svg` |

**SVG authoring rules (Godot/ThorVG safe):**

- Plain shapes, paths, groups, linear/radial gradients only.
- No filters (`feGaussianBlur` etc.), no masks, no embedded rasters, no text
  elements — convert text to paths or draw letterforms manually.
- Simulate glow with layered shapes at decreasing alpha, not blur filters.

---

## 6. Category Rules

### 6.1 Characters (top-down gameplay sprites)

- Camera-true top-down: helmet dome center, shoulders as the widest mass, stick
  held forward. **Sprite faces image-top** — code rotates the quad so image-top
  = skating direction.
- Team read: jersey = team color, shoulder pads + helmet stripe = darker shade,
  trim = Bone. HOME gets gold trim accents (the "Kings"); AWAY gets black/steel.
- Player-controlled vs teammate: player has a gold captain "C" pad + gold helmet
  crown mark; teammates have steel numbers instead.
- State feedback is done in-engine by tinting the sprite material — art stays
  neutral (no baked-in stun stars, etc.).
- Stick blade and gloves get Bone tape highlights so hands/stick read at distance.
- The sprite is the whole silhouette — sticks, pads and gear live in the artwork,
  never as separate procedural geometry layered on top.
- Goalies are ~12% larger than skaters with Bone leg pads, blocker + catch glove,
  and a caged mask; same team-color and captain/crown language as skaters.

### 6.2 Rink, boards, glass, nets

- Ice: near-white blue (`#E8F8FF`) with subtle lane banding (<6% contrast) and
  scratch marks; NHL-style markings use Blood Red and a `#1438D9`-family blue,
  slightly desaturated so players pop over them.
- Boards: Bone panels, black kick plate, team-color trim caps, steel stanchions.
  Inner faces carry in-world sponsor ads (see `pkh_board_ads.svg`) — fake arcade
  brands only ("TURBO SKATES", "HELL ARENA", crown marks). Ads stay at ≤70%
  brightness of gameplay elements.
- Glass: 30% alpha cyan-white with diagonal shine streaks, steel posts.
- Nets (top-down): Blood Red tubular frame with cel highlight, Bone netting drawn
  as a diamond grid over a darkened interior so the goal mouth reads as a "hole".

### 6.3 Puck

- Solid Black body, Steel edge highlight, subtle top sheen.
- Always carries a Glow Cyan halo ring baked at low alpha — the puck must never
  be lost against ice, boards or players. In-engine an extra glow/trail can be
  layered for shots.

### 6.4 Power-up icons

- 256×256, shared **badge**: rounded-square ink panel, 12 px gold border,
  radial dark vignette. Glyph fills ~70% of the badge.
- One dominant hue per family: movement = Home Blue/cyan, offense = Fire Red /
  orange, defense = Gold/Steel, weird/chaos = purple `#9B4DFF`.
- Glyphs are silhouette-first: they must read as a black shape before color is
  applied.

### 6.5 UI icons

- 128×128, single Bone glyph on transparent, same ink outline ratio, optional
  gold variant for focused state. No badge — buttons provide the panel.

### 6.6 Effects (concept rules)

- Goal explosion: gold crown burst + team-color starburst + paper confetti;
  3 stages (flash → burst → linger sparks), total ≈ 0.8 s.
- Body check: white impact star + radial speedlines, 0.15 s, plus 60 ms hit-stop.
- Skating/boost trail: two thin ice-spray lines; boost adds team-color streak.
- Freeze: crystal hexes + Glow Cyan rim on the victim.
- All FX are additive-bright center with team-color edges; never pure black FX.

---

## 7. Do / Don't

| Do | Don't |
|---|---|
| Exaggerate silhouettes and equipment | Add realistic gear detail that muddies at distance |
| Bake soft shadows under ground sprites | Use engine dynamic shadows for sprites |
| Tint sprites in-engine for states | Author separate per-state sprite files |
| Keep gold for rewards/focus/crowns | Spray gold on everything |
| Layer alpha shapes to fake glow | Use SVG blur filters (Godot won't render them) |
| Keep backgrounds near-black | Introduce mid-gray backgrounds that flatten contrast |

---

## 8. Current asset inventory

| Asset | File | Status |
|---|---|---|
| Ice surface | `assets/art/rink/pkh_ice_surface.png` | production (AI-painted) |
| Splash logo | `assets/ui/title_screen/pkh_logo_splash.png` | production (AI-painted) |
| Main menu backdrop | `assets/ui/title_screen/pkh_main_menu.png` | production (AI-painted) |
| Skater sprites ×4 | `assets/art/characters/pkh_skater_*.svg` | production (vector) |
| Goalie sprites ×2 | `assets/art/characters/pkh_goalie_*.svg` | production (vector) |
| Indicator ring | `assets/art/effects/pkh_ring_indicator.svg` | production (vector) |
| Puck | `assets/art/puck/pkh_puck_topdown.svg` | production (vector) |
| Goal net top-down | `assets/art/rink/pkh_goal_net_topdown.svg` | production (vector) |
| Board ad strip | `assets/art/rink/pkh_board_ads.svg` | production (vector) |
| Power-up icons ×13 | `assets/art/powerups/powerup_*.svg` | production (vector) |
| UI icons ×8 | `assets/ui/icons/icon_*.svg` | production (vector) |
| Skater turnaround | `docs/art/character_turnaround_skater.svg` | concept reference |
| FX concept sheet | `docs/art/fx_concepts_sheet.svg` | concept reference |
