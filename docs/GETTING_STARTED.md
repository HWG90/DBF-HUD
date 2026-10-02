# Getting started with DBF-HUD

## Downloads

- [HUD prerelease and Complete bundle](https://github.com/HWG90/DBF-HUD/releases/tag/hud-v0.3.41-preview.1)
- [Optional MCM prerelease](https://github.com/HWG90/DBF-MCM/releases/tag/mcm-v0.1.24-preview.1)
- [Bingus Shared Loader releases](https://github.com/CowboyBingus/BingusSharedLoader/releases)
- [Arsenal download](https://www.nexusmods.com/helldivers2/mods/4664)
- [Official Arsenal instructions](https://docs.rsnl.gg/)

## First installation

Download Complete, install Bingus Shared Loader, and import Complete into Arsenal. Choose **Complete HUD - startup** for installation without MDL. Disable earlier separate HUD/font/depth/probe packages and duplicate MDL HUD instances. Deploy and restart. Keep the loader at the priority specified by its own installation instructions.

Alternatively choose **MDL live reload - bridge and all assets**, copy the included MDL/dbf_hud folder into `%LOCALAPPDATA%/MDL/Helldivers2/Mods`, and enable it with MDL API 2. A verified public MDL download link is still pending; use startup installation if you do not already have MDL.

Preserve existing settings and layouts. Bundled Configuration files are examples. The newly merged Complete archive is offline-validated; clean startup installation still needs live testing.

## Appearance and optional MCM

MCM currently requires MDL API 2. Install its dbf_mcm folder beside dbf_hud, preserving settings. Enable it and press F10. DBF-HUD > Appearance provides display mode, scale, 72 fonts, styles, decorations, colors, text/panel opacity, effects and an equipped-weapon preview.

Styles affect interiors; Decorations controls borders. Scanlines, Flicker and Scanning sweep are independent checkboxes. Fade when not aiming works across modes; HUD always visible disables world-depth occlusion for the 3D path.

## Layout editor

Equip and aim, then F6 enables editing. Arrows move; Page Up/Down changes 3D depth; minus/plus scales; brackets cycle 3D nodes. Comma/period rolls in 45-degree steps; Ctrl selects pitch, Alt selects yaw, and Shift uses 5-degree steps. Movement follows the rotated axes. F7 saves; F8 restores the starting edit; F6 closes. First/third person and 2D mode profiles are separate. Re-enable editing after switching weapons.

## Presets

MCM > DBF-HUD > Presets saves appearance and all layouts. Enter and accept a name, save and confirm. Use the saved-presets dropdown to load. Files are `%LOCALAPPDATA%/DBF/Presets/DBF-HUD-preset-<name>.layout`; existing names are not overwritten. Default reset makes backups. Loading/reset still need live verification.

## Known issues

First-person rotation wiggle remains unresolved. MCM installed files have reverted to older versions; the writer is unidentified. Menu-label retention is a trial awaiting live confirmation. Report weapon, view, mode and reproduction steps, preserving logs before restart. See [Handoff](HANDOFF.md).
