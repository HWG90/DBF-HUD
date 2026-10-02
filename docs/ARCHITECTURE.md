# Architecture

## Runtime pipeline

```text
MDL on_enable -> memory.native -> runtime.start(managed=true)
MDL on_update -> runtime.tick -> identity-checked reader sample
 -> model.normalize -> pose + camera state -> placement.update
 -> layout.compose -> screen_scene projected geometry and native text
 -> editor/debug screen overlays
```

`tools/build.py` bundles modules into a local `HUD` table in explicit order. Source modules return tables; they are not independently installed mods. Add a new module to the builder's ORDER and the contract-test loader. The bundle exposes the running instance as `DBFHUD`.

`runtime.lua` owns orchestration, clocks, sampling, configuration, renderer selection and shutdown. Ammo discovery samples at approximately 30 Hz; weapon pose follows update cadence to avoid stepped movement. MDL-managed startup does not replace global update/shutdown. The legacy standalone bundle has a compatibility startup path; do not run both copies.

## Module map

| Module | Responsibility |
| --- | --- |
| config | Global defaults, validation, serialization; sparse fallback profiles |
| memory | Native read backend, bounded read helpers, logs, tuning/profile file IO, editor key polling |
| reader | Verified weapon identity, ammo/resource/heat/charge and fire-selection data |
| model | Normalize reader output and derive display state; unknown data is not zero |
| ammo_types / weapon_names | Catalog classification/labels and readable resource names |
| pose | Root/sight/custom-node transforms and bounded node enumeration |
| camera_mode | Verified first-person, shoulder and aiming flags |
| projection / anchor / motion | Camera projection, native anchor and 2D smoothing |
| placement | Automatic mount, per-view corrections, shared laser mounting and profile scale |
| weapon_offsets | Profile validation and deterministic serialization |
| layout_editor | Editing state, hotkeys, node cycling, save/reset and editor overlay |
| layout | Render-independent composition: text, bars, frames, ticks, icons and special layouts |
| fire_icons | Game-derived projectile/fire-mode shapes |
| native_font / native_font_data / font | Native font mapping and measurement support |
| view | Screen renderer and numeric/text handling |
| screen_scene | Projects panel geometry and native text using the weapon anchor; selects scene-depth materials |
| depth_marker | Optional diagnostic marker comparison; disabled by default |
| world_probe | Direct WorldGUI command rendering and depth-material selection |
| pose_motion / world_style | World transform smoothing and style helpers |
| menu | Mod Options Menu routes, native ModBindingsMenu shortcut and debug notice |
| mdl | MDL enable/update/disable adapter and cleanup |

Camera research instrumentation is separate from normal HUD data flow.

## Identity and native boundaries

Profiles are keyed by stable 16-hex weapon resource identities, not entity handles, display names or equipped instance IDs. Equipped entity/component identity must be revalidated before native reads. Reader and pose code contain build-specific signatures, structure sizes and bounds; re-prove them after a game update. Never treat an old capture, SDK schema or passing mock as a current native proof.

The memory helper enforces bounded read sizes and per-operation budgets. IO loads small Lua table files in an empty environment, then validates values. Failed native reads should leave data unavailable rather than create a guessed ammo count or fabricated charge signal.

## Rendering and color

`layout.compose` produces command tables, including text/rect/panel primitives and metadata used by renderers. Coordinates begin as logical layout units, then scale. The active renderer projects geometry and native text directly.

Heat zones are white below 65%, yellow 65-85%, red from 85%. The final 95-100% bar section alternates bright red/white once heat reaches 95%. Percentage warning logic separately still alternates configured red/yellow at 95%; do not assume both effects share their palette. Non-percentage heat labels remain neutral except during venting. Venting turns the HUD red and replaces the gauge with flashing OVERHEAT.

Fuel gauges use remaining fraction, draining as fuel is consumed. Low-fuel zones are red 0-15%, yellow 15-35%, white above 35%. The F is geometric so its strokes can split black over fill / white over cleared space.

Global opacity applies to filled gauges; unfilled warning zones retain a 25% multiplier. The current texture is fine, uniform procedural marks, not a stretched Quasar texture. Dense calibration marks include emphasized 50% and 75% ticks.

## Occlusion

The current MDL weapon-panel path uses screen projection and materials that sample
scene depth. This preserves the tracking observed in the screen marker tests while
comparing each panel draw against geometry. Force occlusion selects depth-aware
materials; disabling it selects the clear path. Native text uses a matching
projected orientation and font material. The older WorldGUI renderer is retained
for compatibility and research; it is not the fix for the original trailing.

Tracking and occlusion were user-confirmed. A separate first-person wiggle remains
unresolved, and the native/manual camera comparison does not prove viewmodel
alignment in every frame.

The native binding is registered through `_G.ModBindingsMenu.register_binding` with ID `dbf_hud_debug.force_occlusion`, label Force occlusion, category Debug tools - DBF HUD and automatic native action allocation. `is_down` is sampled once per update and edge-triggered. A press configures the toggle, saves tuning and starts a three-second `[DEBUG] Occlusion ON/OFF` screen notice. Polling stops when the menu instance retires; the manager has no unregister API in the inspected installation.

Mod Options Menu registrations use stable IDs and reusable dispatch routes. Retiring an instance removes its route ownership so a stale callback cannot modify the new HUD.

## Extension recipes

- New weapon label/icon: resolve its stable identity, inspect active-ammo classification in reader/model/ammo_types, map the symbol in fire_icons, and check alternate modes separately.
- New display layout: add command composition in layout; keep native reads out of layout. Confirm the screen renderer understands new command metadata.
- New attachment name: add only a justified hash/name mapping in layout_editor. Keep unmatched nodes labeled by index. A candidate hash match is not proof of behavior on every weapon.
- New editor field: extend profile validation/serializer, editor copy/save/reset, overlay/menu controls, placement/render consumption and contracts together.
- New native signal: compare labeled released/held/returned samples on the same weapon, validate identity and build, and keep thresholds provisional until confirmed.

## Font settings

The native font data table holds 72 families and glyph metrics. Configuration
preserves the original five choices first, then adds the remaining families.
The menu registers a direct DBFMCM font page with lifetime cleanup and saves the
selected family into ordinary HUD tuning. Legacy Mod Options Menu font groups
remain available, but their registrations can survive hot reload.
