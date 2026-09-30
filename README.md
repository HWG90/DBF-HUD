# DBF-HUD

Experimental modular ammo HUD for Helldivers 2, branded **DBF-HUD**. Current development snapshot: **0.3.36**.

## Working features

- Dynamic crosshair tracking with damped movement.
- Weapon-following hybrid mode and an angled world-GUI panel mode.
- Weapon-pose smoothing, configurable mounting offsets, scale, opacity and hex colors.
- Content-sized frames and BigBlue Terminal pixel typography.
- Vertical heat gauge: white below 75%, yellow from 75%, red from 86%, alternating red/yellow from 95%.
- MDL API 2 live Lua reload and menu/Lua tuning.

Runtime global: `DBFHUD`; new MDL folder and resource namespace: `dbf_hud`. Tuning and logs use `DBF-HUD-tuning.lua` and `DBF-HUD.log`. Legacy tuning, runtime retirement and optional material lookup remain supported for upgrades. The addon GUID is unchanged.

An existing live installation may retain its `astra_ammo` folder to preserve MDL enablement. For a fresh installation, disable/remove that entry before enabling `dbf_hud`; never enable both. Historical archives keep their original names.

## Current limitations

The original 3D world-GUI panel still draws through scenery and characters. The experimental scene-mesh carrier is visible and an intervening object hides it, but its ammo image is not yet visually confirmed. The live panel texture is confirmed in the screen preview. Native frost works in hybrid mode; it is disabled in 3D mode because it rendered incorrectly there. Scene-mesh occlusion has a visually confirmed working path; world-space frost remains unresolved.

The experimental native-screen path has successfully created a render target, bound it to the game's offscreen weapon-screen viewport, detached it and cleaned up. The four-color image and live ammo-panel texture have both been visually verified, followed by an occluded scene-plane test. A subsequent reload lost the host render callback and the user reported a crash. The offscreen client now requires a separate startup render bridge to avoid MDL global cleanup. Without that bridge it remains inactive; see bridge/README.md and the investigation notes. This is a development snapshot, not a stable release.

See [native display research](NATIVE_DISPLAY_TRACE.md), [depth investigation](DEPTH_RENDERING.md), and [weapon binding](WEAPON_BINDING.md). These documents include chronological experiments and results; earlier proposed steps are not claims of current functionality.

## Build and install

```sh
python tools/build.py
```

This produces `dist/dbf_hud.lua`, `mdl/dbf_hud/mod.lua`, and an MDL ZIP in the parent directory. Optional Arsenal packaging requires an external Bingus addon builder, supplied with `--addon-builder`.

Copy `mdl/dbf_hud` into `%LOCALAPPDATA%/MDL/Helldivers2/Mods`, then enable **DBF-HUD (Live)**. Disable the packaged startup copy to avoid duplicate HUDs. See [MDL setup](MDL.md). With auto-reload enabled, installed Lua file writes take effect immediately; validate locally and copy atomically.

Configure through the mod menu or game-root `DBF-HUD-tuning.lua`. The file in this repository is an example, not a copy of personal live settings. Open `preview/index.html` for the browser design preview; it does not reproduce the native rendering pipeline.

## Validation

```sh
python tests/run.py --lua-dll "path/to/lua51.dll"
```

The runner uses a local Windows LuaJIT DLL. **41 offline contracts pass** at this snapshot. They cover data/layout behavior, smoothing, lifecycle and guarded render integration; they cannot establish native GPU behavior or in-game occlusion.

## Contents and attribution

Source, generated Lua bundles, preview, tests and development notes are included. Extracted compiled game materials, game binaries, memory captures, private logs and anti-cheat bypass code are not included. The optional experimental depth-material assets referenced in historical notes are not shipped here; code falls back when they are unavailable.

Ammo layout facts originated from Reticle Ammo HUD. This implementation was developed independently of HD2UI; Derive was used for read-only investigation.

BigBlue Terminal printable ASCII glyphs were imported from Nerd Fonts v3.5.1. Font attribution and CC BY-SA 4.0 terms are preserved in [licenses/BigBlueTerminal](licenses/BigBlueTerminal). See `tools/import_bigblue.py` for regeneration. No blanket license is granted for the remaining project code in this snapshot.

Full Nerd Fonts support is deferred in [BACKLOG.md](BACKLOG.md).
