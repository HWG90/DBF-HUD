# Split instrument study 08

**Selected direction:** David chose Split, the open asymmetric readout cluster, on October 11, 2026. This refinement makes that direction the default and keeps Study 07 as the fallback exploration. Selection of the design direction does not establish a completed universal runtime implementation or acceptance of every weapon-specific layout.

The first production implementation is now in `src/split_hud.lua`, using the existing HUD Texture renderer and configuration system. David approved this as a first-pass baseline and authorized replacing old appearance choices. See [the current handoff](../../docs/HANDOFF.md) for deployment and live verification; this gallery remains the illustrative design reference.

The armory workbench presents the same approved instrument with an enlarged responsive bench, field comparison, scenario shortcuts and selectable resource cards. Page controls affect the preview. Saved game placement remains independent; the Split appearance action now preserves offsets and scale.

## The instrument

The center contains the dominant resource, its short unit label, a proportion rail, and a subordinate capacity or loaded-shot reading. The left reserve pod preserves its actual unit. Relevant selected settings sit on independent open nodes to the right. The compact status strip stays underneath the resource, including the liked CHAMBERED +1 presentation.

There is no enclosing perimeter box. A small feathered navy backing supports the main register, with an open gold bracket and short connector stubs giving the separate pods a shared structure. The accepted slanted LED numeral geometry remains white, with a navy stroke; explicit empty counts turn red and flash at 2 Hz. Reduced-motion users receive a steady red count. Identity remains small.

Combat mode is the default. It always reports each available selected setting, with a reinforcing symbol and its value. Inspect settings adds names such as FIRE SELECT, FIRE RATE, AMMUNITION, and SAFETY. It does not invent additional capabilities or hide necessary settings in combat. The mixed test specimen carries all four field types simultaneously; it is explicitly illustrative and is not an assertion about a real weapon.

## Universal semantics

| System | Main register | Reserve pod | Context |
| --- | --- | --- | --- |
| Magazine | Loaded rounds, `/ capacity`, proportion rail | MAGS | Selected fire mode when known |
| Belt | Three-digit count, `/ capacity` | BELTS | Selected RPM when known |
| Individual shells | Loaded shells, `/ capacity` | SHELLS | Fixed fire mode omitted |
| Heat | HEAT percentage and increasing rail | SINKS when known | HOT / VENTING status; no invented fire selector |
| Charge | Active charge percentage; loaded shot remains below | SHOTS in this Railgun specimen | SAFE / UNSAFE when known |
| Ammunition selector | Loaded resource and capacity | PACK in this specimen | Selected ammunition independently of other setting fields |
| Expendable | One shot; SPENT after use | Absent if not reported | SINGLE USE needs verified reloadability or metadata |
| Fuel | Fuel amount, capacity, proportion rail | TANKS | Applicable settings only |
| Infinite energy | Proposed infinity glyph for the existing infinite kind | Absent if not reported | No fabricated counts or reserve |

All values are illustrative static data, not current game-stat references. Missing settings disappear. Unknown counts are dashes with NO DATA, never fabricated zeros. The chambered state sets `chamber_rounds = 1`, `chamber_bonus = 1`, and a loaded count of `capacity + 1`; the status is shown only while those conditions agree. The reader already includes the chamber in loaded rounds.

Current source ownership and capability detail are mapped in [Study 07's brief](../universal-hud-study-07/BRIEF.md). The normalized model exposes loaded amount, capacity, typed reserve, heat, fire select, ammunition mode, safety, selectable RPM, several charge fields and the raw reader's `reloadable` flag. SINGLE USE requires explicitly false reloadability. Universal zoom, flashlight state, fuse distance, targeting range, all selector choice lists, and simultaneous alternate resource pools need further reader contracts.

## Spatial and edge review

Gameplay remains compact at **70%** by default, approximately **224 × 113 pixels** at the **1920 × 1080 reference** in Combat mode. Critical resource-unit, reserve-unit, selected-context, and status labels use approximately 11.5 source pixels, or 8 pixels at this default. Main ammunition numerals are approximately 34 pixels. Overview cards remain at 100% for inspection; the size slider can increase the instrument when an oblique angle or longer view distance needs it.

The three separate SVG planes can be offset in simulated depth; weapon-angle approximation and draggable placement remain available on the four optional third-person references. This is a spatial study, not live tracking or a new rendering pathway. Backing opacity, feather width, dither blend, and grain controls are also preview-only here. Existing runtime edge controls are a separate implementation.

The original gameplay captures remain local and unchanged under `../universal-hud-study-07/reference/`. They and their local hash provenance are excluded from publication. Public clones fall back to a neutral field with an optional-reference message if those files are absent. Generated standalone art previews contain no game capture.

## Validation and limits

- Node syntax checks passed for Study 07 and this refinement.
- 100 Split composition cases cover ten specimens, five states, and both reading modes. The four-setting test verifies independent context nodes in both modes, including Combat when a legacy `settings: false` option is passed.
- Standalone SVGs and PNGs are generated from the actual composition and mask functions using Sharp. `comparison.png`, `family-overview.png`, `settings-stress.png`, and `actual-scale.png` are visually inspected assets.
- The browser tool rejected the earlier local `file:///` URL under its URL policy. No browser workaround or new browser inspection was attempted. DOM interaction, responsive page layout, missing-image fallback behavior, and 3D perspective remain unverified in a browser.
- No maintained Lua source, installed game files, saved settings, or renderer was changed by this study.

Open [index.html](index.html) for the focused review. `family-overview.png` shows nine resource systems; `settings-stress.png` compares Combat and Inspect settings; `actual-scale.png` shows Normal, Chambered +1, and Empty at the default 70% size. The original three-direction exploration remains available in Study 07.
