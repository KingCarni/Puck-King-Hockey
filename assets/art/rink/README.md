# Rink Art Assets

Drop gameplay rink textures in this folder.

Expected optional files:

- `pkh_ice_surface.png`
- `pkh_ice_surface.webp`

The rink will prefer WebP, then PNG.

Recommended source settings:

- square texture, ideally 2048x2048 or 4096x4096
- top-down / orthographic
- ice only or full rink markings if you want baked markings
- no goals, players, puck, boards, crowd, or UI

The current implementation uses the image as a material texture on the ice surface. Existing procedural rink lines and faceoff markings stay on top for gameplay readability.
