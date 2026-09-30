# DBF-HUD

Experimental modular ammo HUD for Helldivers 2, branded **DBF-HUD**. Current development snapshot: **0.3.40**.

## Working features

- Dynamic crosshair tracking with damped movement.
- Weapon-following hybrid mode and an angled world-GUI panel mode.
- Weapon-pose smoothing, configurable mounting offsets, scale, opacity and config-file colors.
- Content-sized frames and BigBlue Terminal pixel typography.
- Vertical heat gauge: white below 75%, yellow from 75%, red from 86%; vent mode pulses red.
- MDL API 2 live Lua reload and menu/Lua tuning.

Runtime global: `DBFHUD`; new MDL folder and resource namespace: `dbf_hud`. Tuning and logs use `DBF-HUD-tuning.lua` and `DBF-HUD.log`. Legacy tuning, runtime retirement and optional material lookup remain supported for upgrades. The addon GUID is unchanged.

An existing live installation may retain its `astra_ammo` folder to preserve MDL enablement. For a fresh installation, disable/remove that entry before enabling `dbf_hud`; never enable both. Historical archives keep their original names.

## Current limitations

Direct WorldGUI occlusion was visually confirmed on September 30 using the registered depth-enable-only shader probe. The scene mesh is now archived in code and commented out of public dispatch. The main menu exposes three display modes; Always Show HUD (3D) switches direct WorldGUI between depth-tested and non-occluded drawing. World-space frosted blur is unresolved, and first-person/shoulder placement currently uses camera heuristics rather than verified camera-state flags.

The complete archive retains the startup bridge for compatibility. Direct WorldGUI renders text and bars without an intermediate texture; the active MDL path no longer allocates or updates mesh textures. The verified depth assets are included; the combined startup installation still needs its own live verification.

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

The runner uses a local Windows LuaJIT DLL. **47 offline contracts pass** at this snapshot. They cover data/layout behavior, smoothing, lifecycle and guarded render integration; they cannot establish native GPU behavior or in-game occlusion.

## Contents and attribution

Source, generated Lua bundles, preview, tests and development notes are included. Game binaries, memory captures, private logs and anti-cheat bypass code are not included. The complete install archive contains the verified compiled GUI depth resources needed by this renderer. The complete install archive includes the verified WorldGUI depth assets. Older experiments remain separate and should be disabled when installing it.

Ammo layout facts originated from Reticle Ammo HUD. This implementation was developed independently of HD2UI; Derive was used for read-only investigation.

BigBlue Terminal printable ASCII glyphs were imported from Nerd Fonts v3.5.1. Font attribution and CC BY-SA 4.0 terms are preserved in [licenses/BigBlueTerminal](licenses/BigBlueTerminal). See `tools/import_bigblue.py` for regeneration. No blanket license is granted for the remaining project code in this snapshot.

Nerd Fonts v3.5.1 has been converted into a future font library: 72 families and 2,252 faces, with 48px grayscale atlases, glyph metrics, source checksums and upstream license documents. HUD text uses printable ASCII; SymbolsOnly includes all 10,624 supported symbols per face. Runtime font selection beyond BigBlue/debug is still deferred. See [font assets](assets/fonts/README.md) and [BACKLOG.md](BACKLOG.md).

## Complete install archive

See [complete installation](INSTALL-COMPLETE.md). `tools/build_complete.py --addon-builder <path-to-build_addon.py>` creates one Arsenal archive with startup and MDL installation choices, the render bridge, verified depth assets, loose MDL Lua, starter tuning, source and font licenses. Disable the previous component addons before deployment.

Debug logging is opt-in; active and archived tuning are separated. See [TUNING.md](TUNING.md).

HUD font now offers ten additional Nerd Font families, ranked by v3.5.1 GitHub release ZIP plus tar.xz download counts (2026-09-30), excluding Symbols Only. BigBlue remains the default. Regular Mono faces are baked into printable-ASCII glyph geometry; no system font installation or intermediate texture is needed. Source selection and face details are in assets/fonts/runtime-selection.json and runtime-faces.json. Regenerate with tools/build_runtime_fonts.py.
