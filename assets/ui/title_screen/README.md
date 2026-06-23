# Puck King Hell Title Screen Assets

Place the approved generated title/menu images here.

Expected files:

- `pkh_logo_splash.webp` or `pkh_logo_splash.png`
  - Used by `SplashScreen.tscn`
  - Recommended: cropped logo on dark/transparent background

- `pkh_main_menu.webp` or `pkh_main_menu.png`
  - Used by `MainMenu.tscn`
  - Recommended: 16:9 menu concept image, 2560x1440 preferred

Current implementation will prefer `.webp`, then fall back to `.png` if present.

This folder is intentionally committed without binary art in this pass because generated binary files should be reviewed and added locally as source assets.
