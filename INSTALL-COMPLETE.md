# Complete installation


## Downloads and requirements

- [DBF-HUD downloads](https://github.com/HWG90/DBF-HUD/releases): choose the Complete ZIP.
- [Bingus Shared Loader](https://github.com/CowboyBingus/BingusSharedLoader/releases): required to start the Complete HUD.
- [Arsenal](https://www.nexusmods.com/helldivers2/mods/4664): installs and deploys the mod archive. See [Arsenal documentation](https://docs.rsnl.gg/) for setup.
- [DBF-MCM](https://github.com/HWG90/DBF-MCM/releases): optional configuration menu, presets and Appearance preview. Choose its Shared Loader startup package for use without MDL. Bingus Mod Options is not required.

## Install with Bingus Shared Loader

1. Close the game. Install Shared Loader following its own instructions.
2. Import the DBF-HUD Complete ZIP into Arsenal.
3. Choose **Complete HUD - startup**. Disable an existing MDL HUD instance and older separate HUD, font or depth packages to avoid duplicate startup or competing assets.
4. Enable the package and deploy with Arsenal. Follow Shared Loader's documented deployment order.
5. Start the game. The Complete archive includes HUD code, render bridge, fonts and depth assets; MDL is not required for this installation.
6. For configuration, install DBF-MCM's Shared Loader startup package separately, deploy and restart. Press F10 and open DBF-HUD.

Use exactly one startup path for each mod. Arsenal does not need to remain open while playing.

## Optional MDL live reload

Choose **MDL live reload - bridge and all assets** in the Complete archive instead of startup. Install the included MDL/dbf_hud folder in your MDL Mods folder and use MDL API 2. The bridge and assets still need deployment. Lua reload does not install updated fonts or shaders.

## First setup

New installations use the bundled tuned settings and weapon layouts. The three approved starter presets are copied into the preset folder only when those filenames do not already exist. Existing local settings, layouts and presets take priority during updates.

Appearance contains fonts, colors, text and panel opacity, scale, styles, decorations, effects, frosted backgrounds and aiming fade. Its preview uses the held weapon, or a fallback HUD when no weapon is equipped. Placement contains the occlusion debug control and weapon blacklist actions.

## Layout editor

- F6: toggle editor.
- Arrows: move; Page Up/Down: depth in 3D; plus/minus: scale, down to 5 percent.
- Hold Shift for finer adjustments.
- Brackets: select attachment node. Weapon Root is the default.
- Comma/period: rotate 45 degrees; Ctrl adjusts pitch, Alt adjusts yaw, Shift uses 5 degrees.
- F7: save the selected weapon and view. F8: restore the editor's starting layout.
- F9: reset position to zero and scale to one.

First- and third-person layouts save independently. Movement follows the panel's rotated axes.

## Presets and storage

In MCM's Presets page, type a filename and choose Save. Clicking away accepts typed text. Select a saved preset to load or delete it, then confirm. Overwriting keeps a backup. Reset to defaults restores the bundled setup; it is separate from normal preset actions.

Active settings and weapon layouts are stored in `%LOCALAPPDATA%/DBF`. Named `.layout` presets are in `%LOCALAPPDATA%/DBF/Presets`. Legacy configuration migrates only when no current copy exists. Back up this folder before manual changes.

## Preview limitations

This is a prerelease. Offline contracts and archive validation do not replace a clean installation test. Intermittently disappearing MCM dropdown labels remain under investigation. Some attachment orientations and first-person scope occlusion may require layout adjustment. Report the weapon, view, startup path and steps to reproduce when filing an issue.
