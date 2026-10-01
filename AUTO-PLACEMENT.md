# Automatic 3D placement

Auto is the active 3D placement path. The public menu no longer exposes Manual or its nine position sliders. First-person side, upright orientation and smoothing remain selectable.

## Responsibilities

- `pose.lua`: bounded, identity-checked weapon and character transform reads; named sight and right-shoulder anchors.
- `camera_mode.lua`: first-person, shoulder and observed aiming state reads.
- `placement.lua`: weapon/view mount calculation and per-weapon corrections.
- `weapon_offsets.lua`: external profile validation and fallback.
- `world_probe.lua`: orientation, smoothing and direct WorldGUI drawing.
- `runtime.lua`: coordinates those modules and chooses visibility.

Sight mounts update from the current node each frame. They have no settling delay or screen-seed cache. Only weapons without a usable sight retain the earlier root-based fallback, including its 0.4 second settling interval and per-equip/view cache.

## Current mounts

Offsets in metres relative to the named sight:
- Right shoulder: (+0.16, +0.10, +0.04).
- First person: (+/-0.12, +0.45, +0.01), with half-size rendering. Left is the default side.
- Left shoulder fallback: (+0.16, -0.25, +0.12); the sampled pistol adds (+0.05, -0.08, 0).

Third-person placement uses the same sight mount for both shoulders. Character-shoulder relocation and camera-facing shoulder transforms have been removed from the active path.

Visibility is fixed: non-occluded while the observed game aiming state is active, scene-depth-tested otherwise. The menu has no visibility selector. Validation failure keeps occlusion enabled. Old saved visibility settings are accepted for compatibility but cannot change the fixed runtime behavior.

## Editable profiles

`DBF-HUD-weapon-offsets.lua` lives beside the game's `DBF-HUD-tuning.lua`. It is loaded when DBF-HUD starts; reload the HUD in MDL or restart after editing. Merely rewriting an identical bundled mod does not reliably trigger MDL auto-reload.

Profiles use stable weapon resource identities, with separate `right`, `left`, `first_left`, and `first_right` entries. Each axis is an additional weapon-local correction in metres; absent axes and views add zero. Menu saves never overwrite this file. An empty return table disables built-in corrections. Invalid files log a rejection and use built-in defaults.

The Scythe and autocannon currently have right-shoulder profiles. Automatic model-clearance queries and backpack detection remain unimplemented. The layout editor is deferred until this cleanup is verified in-game.

## Rendering organization

`scene_test.lua` selects direct WorldGUI depth behavior. `world_style.lua` prepares scaled geometry, fits pixel glyph bounds, and applies style presets. Mesh experiments are retained separately in `archived_mesh.lua`. Placement and external profile validation remain in their own modules.
