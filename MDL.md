# DBF-HUD live reload (0.3.34)

Requires MDL API 2. The adapter was checked against installed MDL 1.4.2 source and tested offline. Live enable and reload produced valid pose samples. Testing exposed a concurrent startup copy; deploy with the packaged DBF-HUD addon disabled.

## First use

Place the `dbf_hud` directory from `DBF-HUD-MDL-0.3.34.zip` inside `%LOCALAPPDATA%/MDL/Helldivers2/Mods`. This is a loose MDL mod, not an Arsenal archive.

With MDL 1.4.2 deployed and running, open its in-game panel and enable **DBF-HUD (Live)** under live Lua mods. Mod Options Menu may cause MDL to appear as a floating panel instead of an ESC tab. Refresh/rescan if the new entry has not appeared.

Disable the packaged DBF-HUD addon in Arsenal and redeploy before using the live version. Live testing found that the startup copy could remain active despite the attempted global takeover. Do not rely on the adapter to retire a separately loaded startup copy. After a clean deployment, the live runtime produced one clean log timeline.

## Reloading edits

Build with `python tools/build.py`. Copy the resulting `mdl/dbf_hud/mod.lua` into the installed folder, then use MDL's Reload action. MDL also provides an optional **Auto reload changed Lua files** setting; it is enabled in the current development setup. Publish future file updates atomically so MDL cannot read a partially written script.

Menu settings still save to the same game-root `DBF-HUD-tuning.lua`. This adapter does not overwrite that file. Font glyphs, layout, reader diagnostics and other bundled Lua changes can reload through this path. New engine assets still require the normal asset deployment process.

## Lifecycle

MDL owns frame dispatch through `on_update`. The managed runtime does not replace global `update` or `shutdown`. Disable and cleanup release GUI elements, retire menu handlers and close the log. Cleanup is idempotent. Repeated menu registration reuses stable option IDs and one dispatcher per option.

The `DBFHUD` global belongs to MDL while enabled. Old boot wrappers that cannot be unlinked because other mods wrap them remain inert. No game shutdown callback is invoked when disabling DBF-HUD.

The normal `DBF-HUD.log` is restarted when a new runtime starts; preserve it before reloading if it contains diagnostic results you need. MDL's own log records enable/reload errors. A Lua error can be contained by the lifecycle; this does not make an invalid native engine call recoverable.

## First live check

Enable the live mod, close the menu and verify the counter. Use Reload once, then disable and re-enable it. Expect one HUD throughout, disappearance when disabled, and preserved tuning after re-enabling. Report the result so logs can be checked before resuming weapon binding.

## 0.3.10 attachment marker

A small white cross marks the projected weapon root. The counter retains its existing crosshair anchor. The marker is a projection diagnostic, not a calibrated mounting location. Set pose_marker = false in Lua tuning to disable it. The initial projection supports perspective cameras with identity local camera offsets; unsupported modes, clipped points and failed validation hide the marker. PROJECT log entries report coordinates or the rejection reason. Visual alignment during motion still requires the in-game check.

## 0.3.34 weapon attachment

The user confirmed that the 0.3.10 marker follows the weapon. The screenshot places its unadjusted root near the shoulder rather than the receiver, so mounting offsets still need visual calibration.

Weapon attachment is now the default. The camera-facing panel follows the projected weapon-local mounting point. In Options > Mods > DBF-HUD, choose Attach HUD to: Weapon or Crosshair. Weapon local X/Y/Z move the mounting point along the rotating weapon axes (world units). Weapon panel horizontal/vertical offsets move the panel in screen space (1080p reference pixels), separately from saved reticle offsets. Weapon settling time controls damping; Maximum weapon lag bounds the screen-space distance from the moving target. Defaults are 0.10 seconds and 40 reference pixels. Show attachment marker exposes the mount for calibration and defaults off.

Lua keys: anchor_mode, mount_x, mount_y, mount_z, weapon_offset_x, weapon_offset_y, weapon_settle, weapon_lag, pose_marker. Existing tuning files inherit defaults for new keys. Menu edits save them. The mount defaults to the verified root; per-weapon calibrated profiles are not yet available. Unknown camera modes or clipped mounts fall back to the reticle without hiding the ammo panel. Full panel alignment and motion remain to be confirmed in game; 37 offline contract checks pass.

## 0.3.13 world GUI rectangle experiment

The live availability probe confirmed World.create_world_gui, Gui.move and Matrix4x4.from_axes are exposed as functions. The new experiment invokes them with an engine-returned live main world and a fresh matrix constructed from the verified weapon pose. It submits a charcoal rectangle with a yellow edge, approximately 24 by 14 cm at 1000 GUI units per world unit. The plane uses weapon X/Z axes and is raised 0.20 world units above the configured mount. Existing hybrid HUD remains visible.

Experimental 3D rectangle in the menu (world_probe in Lua) disables the test. Logs record native creation/draw boundaries. A Lua failure disables the experiment until reload. A native engine fault cannot be caught by Lua; this is the first live creation test, not confirmed rendering support. Depth occlusion and sidedness remain unverified. No new textures or world scans are used. Offline suite: 38 checks pass including resource lifecycle and failure handling.

API reference: https://help.autodesk.com/cloudhelp/2021/PTB/Max-Interactive-Help/lua_ref/obj_stingray_World.html

## 0.3.14 full 3D ammo panel

Attach HUD to now has three choices: Weapon (hybrid), Crosshair, and Weapon (3D plane). The third mode composes the existing live panel in local GUI coordinates and draws it on the verified world-space GUI. Ammo changes, heat cells and thresholds, font rendering, colors and automatic frame size use the same model and layout as the screen HUD. The screen copy is suppressed after a successful world draw. World local X/Y/Z offsets and HUD scale control placement and physical size. The plane retains the diagnostic mount's +0.20 local Z lift. There is no rotation-offset control yet.

The renderer uses the native frost material when available and otherwise an opaque background. Its appearance on the world plane still needs live confirmation. Depth occlusion remains unresolved: the panel can draw over the character. No generated texture or new material asset is required. The experimental rectangle defaults off. Lua anchor_mode = 'world' selects the third mode. Offline tests: 38 pass, including drawing populated heat commands through the world renderer.

## 0.3.15 3D pose smoothing

Adds frame-rate independent exponential position filtering and shortest-path quaternion rotation interpolation. Defaults: position time constant 0.045 seconds, rotation time constant 0.08 seconds, maximum positional lag 0.12 world units. Menu controls: 3D position smoothing, 3D rotation smoothing, 3D maximum position lag. Lua keys: world_position_smooth, world_rotation_smooth, world_max_lag. Higher smoothing values mean slower following; zero disables that filter. Position lag is bounded relative to the current mount. Weapon identity changes, world changes, visibility release, long frame stalls and position jumps over two world units reset the filter. This smooths pose only, not ammo/heat values. Offline checks: 39 pass; live feel needs confirmation.

## 0.3.16 pose cadence correction

Weapon root pose now refreshes every update rather than sharing the 30 Hz ammo discovery interval. Each refresh retains the existing code, handle generation, entity identity and matrix validation. Ammo discovery stays at 30 Hz. This removes the held-pose steps entering the smoothing filter and hard lag limit. Existing smoothing settings are preserved. The regression test verifies ten pose reads for ten updates at 144 Hz. All 39 offline checks pass. Visual improvement requires live confirmation; camera-relative filtering may still be useful if residual camera motion remains.

## 0.3.17 depth-material test

Requires the separate material-only DBF-HUD-Depth-Materials-0.1.zip deployed through Arsenal and a game restart. The Lua renderer detects these isolated resources automatically. See DEPTH_RENDERING.md for evidence, installation and limitations. Existing smoothing/tuning is preserved.

## Offscreen experiment disabled

Version 0.3.34 disables offscreen startup after a CTD. MDL tracks writes to the global render callback even through its wrapped rawset and deletes the restored callback on teardown. Do not enable the archived experiment under auto-reload. Normal ammo rendering continues through MDL updates.
