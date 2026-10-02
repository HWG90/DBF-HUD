# Layout editor and weapon profiles

First-person placement uses the right-side profile. Older side settings are accepted for compatibility and normalized to right; the side selector is retired.

## Controls

Equip and aim with the weapon before entering editing.

| Key | Action |
| --- | --- |
| F6 | Toggle editor; captures starting profiles for the equipped weapon |
| Left / Right | Sway: weapon-local x |
| Up / Down | Heave: weapon-local z |
| Page Up / Page Down | Surge: forward/back weapon-local y |
| Shift | Fine movement: 0.125 inches; scale: 1% |
| Ctrl | Coarse movement: 2 inches |
| No modifier | Movement: 0.5 inches; scale: 5% |
| [ / ] | Previous / next attachment point available on this weapon |
| - / = (+ key) | Smaller / larger scale |
| F7 | Save all profiles; displays readable weapon and view confirmation |
| F8 | Restore this weapon's profiles from when this edit session began |
| F9 | Zero position offsets for the selected weapon and current mode/view; F7 saves. Rotation, scale and attachment stay unchanged. |

Movement repeats while held; scale and attachment cycling are press-edge operations. Keys are read without consuming game input. Changing weapons closes the editor; use F6 again for the next weapon. Closing without saving leaves preview changes in memory. The close status currently says unsaved preview even if the last action was a save.

F8 restores the edit-session starting state, not the most recently saved file. Press F7 after restoring if the reset should persist. Reset restores all views of the current weapon, not just the visible view.

The options panel also provides editor/view/position/scale/save/reset controls. The live hotkey workflow is the faster path.

## Storage

`%LOCALAPPDATA%/DBF/DBF-HUD-weapon-offsets.lua` stores every weapon. Appearance and behavior use `%LOCALAPPDATA%/DBF/DBF-HUD-tuning.lua`. Missing files migrate automatically from the game folder; an existing AppData file takes priority. Legacy files remain as backups. Each entry may contain `right`, `left`, `first_left`, `first_right` views. The active third-person path currently uses `right`; do not assume left shoulder independently consumes the retained `left` profile.

```lua
return {
    ['0123456789abcdef'] = {
        right = { x = 0.0254, y = -0.0508, z = -0.1524, scale = 1 },
        first_right = { attach_point = 'sight', x = 0, y = 0, z = 0 },
    },
}
```

This is a schema example, not a real weapon identity. Coordinates are metres in weapon-local space: x right, y forward, z up. One inch is 0.0254 metres. Missing coordinates mean zero correction; missing scale means 1. Saved corrections are added to automatic mounting offsets, not absolute world positions.

Validation accepts only four view names; x/y/z must be finite and within two metres. Editor position controls allow +/-72 inches. Scale is 0.25-3. Attachment accepts `sight`, `root`, or `node:` followed by eight hex characters. Files are limited to 64 KiB.

F7 writes the entire current profile table deterministically. It writes a temporary file, rotates the previous file to `.bak`, renames the temporary file and attempts backup restoration if the final rename fails. The backend raises failures; successful save logs name, resource, view and positions. Preserve backups before manual changes.

**Live profiles are the user's authoritative layout data.** The repository file is a baseline/example and may differ substantially. Do not overwrite live profiles during Lua deployment. External profile edits are loaded at runtime startup; rebuild/reload the installed MDL Lua bundle or use MDL Reload afterward. Editing the file while an old editor session remains active can be overwritten by its next F7 save.

## Position and scale

Automatic first-person and third-person mounts differ to stay visible in their cameras. Matching raw correction numbers alone does not guarantee visible parity. Judge receiver/sight/magazine clearance in both views.

Laser catalog entries can use shared mounting: the right profile applies in both views when there is a sight and no explicit per-view attachment. Selecting a bone opts the active view out of shared mounting. Explicit attachment fields allow independent first-person anchors.

Final panel size is global HUD scale multiplied by the selected profile scale, with any special weapon layout transform still applied. Individual profile scale changes panel size without shifting its position. Global scale also changes lateral/vertical clearance around the anchor; tuned forward depth remains independent.

## Attachment points

Sight and root are built-in choices. Indexed nodes are enumerated only while editing, from the identity-checked equipped weapon pose table. Saved custom attachments use node hashes rather than transient indices.

Current name mappings include slide, attach_mag_2, muzzle, attach_optic, sight, attach_muzzle, c_grip, barrel, eject, attach_weapon, trigger, root, hammer, c_scope, bolt and attach_mag. Only actual nodes on the weapon appear when cycling. Unmatched nodes remain Unnamed with an index. Barrel and magazine positions were confirmed by the user; the remaining candidate names are hash matches and need weapon-specific visual checks.

A node saved for one weapon may not exist on another. Missing node data can fall back to legacy root/projection placement; there is no dedicated unavailable-node warning yet. When copying positions across weapon variants, preserve existing scale/attachments unless explicitly asked to copy the whole layout.
