# DBF-HUD

A weapon-mounted ammo, fuel, heat and charge HUD for Helldivers 2. Current development version: **0.3.41**. This is the source checkout; generated releases may lag behind it.

## Start here

For a new coding chat, read these in order:

1. [Handoff and current state](docs/HANDOFF.md): current environment, verified behavior, unfinished work and preservation rules.
2. [Architecture](docs/ARCHITECTURE.md): data flow, module responsibilities and safe extension points.
3. [Layout editor and profiles](docs/LAYOUT_EDITOR.md): controls, coordinates, attachment points, scale and persistence.
4. [Development and deployment](docs/DEVELOPMENT.md): build, validation, live reload and troubleshooting.

Historical research remains in the root Markdown files. It records experiments, not necessarily current functionality. Current source and these guides take precedence when describing the active implementation.

## Current features

- Native engine fonts: BigBlue Terminal, Hack, JetBrains Mono, Fira Code and Iosevka.
- Direct WorldGUI panels, a weapon-following 2D mode and a crosshair-relative 2D mode.
- Weapon-specific ammo labels and projectile symbols, fire-mode child panels, fuel and heat gauges, and a railgun charge gauge.
- Fixed three-digit numeric slots with dimmed leading zeros; counts above 999 can expand.
- Live layout editor with saved per-weapon/per-view position, scale and attachment points.
- Configurable decorations and shared settings through Mod Options Menu.
- Native Force occlusion binding under **Debug tools - DBF HUD**, with a three-second debug state notice.
- MDL API 2 lifecycle and live Lua reload.

## Quick development loop

```powershell
python tests/run.py
python tools/build.py
```

The test runner uses the installed game's LuaJIT DLL by default; `--lua-dll` overrides its path. **93 offline contracts passed at the October 1 documentation checkpoint.** They do not replace an in-game visual check.

Build outputs include `dist/dbf_hud.lua`, `mdl/dbf_hud/mod.lua` and an MDL ZIP in the parent directory. The active loose MDL mod is installed under `%LOCALAPPDATA%/MDL/Helldivers2/Mods/dbf_hud`.

**Never replace the live game-root weapon-offsets file with the repository example during a code update.** The live file contains user-edited layouts. Back it up before any profile migration.

## Assets and attribution

Lua reload changes code, not compiled engine assets. Native text and decoration depth materials require the deployed combined font/depth package. The native-font update was confirmed working in-game during this session; retained archive versions must still be checked before deployment.

See [MDL lifecycle notes](MDL.md), [native display research](NATIVE_DISPLAY_TRACE.md), [depth research](DEPTH_RENDERING.md) and [weapon identity research](WEAPON_BINDING.md). Browser preview is a design aid and does not reproduce native rendering or occlusion.

Game binaries, private captures and private testing-tool packages are not project documentation artifacts. Preserve font attribution and terms in `licenses/`. No blanket license is granted for the remaining project code in this snapshot.
