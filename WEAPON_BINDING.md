# Weapon binding investigation

## Live transform result — September 29

Targeted Derive reads resolved all three user-selected weapons through entity-record `+0x0C` into engine unit objects and root matrices. No native function was called and no Lua userdata was forged.

| Weapon | Observed UnitRef | Scene nodes | Result |
| --- | --- | --- | --- |
| Scythe | `0x2074` | 40 | 24 changing position/rotation samples; maximum squared-axis-length error below 0.000001 |
| Bolt Pistol | `0x2079` | 32 | Unit identity, generation and rigid affine matrix checked |
| Autocannon | `0x8002DC` | 63 | Same checks; resolved again after drop/pickup |

The Autocannon retained its object/handle through that particular drop/pickup. This confirms reacquisition in this case, not coverage of every despawn or recreation scenario. These handle values and all absolute pointers are session-specific.

The observed path is:

1. `*(game.dll + 0x3326308)` is the script API table; its `+0x18` entry is the unit API candidate corroborated by native call sites.
2. Unit API `+0x90` points to a pose getter. Its current instruction sequence resolves ECX as a UnitRef, calls the object's scene-graph accessor at vtable `+0xE8`, then returns the matrix-array pointer plus `node_index * 64`.
3. The resolver takes `index = UnitRef & 0x3FFFFF`; it checks the index against registry `+0x98` and compares the byte at the generation table (`+0xA0`) with the low byte of `UnitRef >> 22`. The object-pointer array is registry `+0x88`.
4. Object `+0x08` repeats the UnitRef. The inspected scene accessor is exactly `lea rax,[rcx+0x60]; ret`. Scene node count is object `+0x70`, and its world-matrix array is object `+0x88`. Root node zero gives the first 64-byte matrix.
5. Matrix translation is floats 13–15, with basis vectors in floats 1–3, 5–7 and 9–11. All sampled matrices had affine final components and orthonormal axes, and positions were near the avatar.

`src/pose.lua` follows this path using bounded ReadProcessMemory only, inspecting the getter/resolver/accessor instruction bytes first. It rechecks ownership and generation after reading, checks matrix validity and does not retain unit/matrix pointers between polls. Unknown implementations fail closed. Getter and resolver addresses are decoded from current-session pointers and relative instructions, never reused from this document.

Version 0.3.9 exposes the result as `DBFHUD.weapon_pose` and logs `POSE` samples once per second. It does not yet move the HUD onto the gun. Camera projection, root-axis calibration, a visible attachment marker, and the camera-facing blend remain to be verified.

The public [Stingray C API headers](https://github.com/AutodeskGames/stingray-plugin-api-samples/blob/master/stingray_sdk/engine_plugin_api/c_api/c_api_unit.h) helped identify the API family, but their function offsets differ from this game and are not used as authority for the live offsets.

## Earlier investigation notes

## Status after the 0.3.3 crash

0.3.4 removes world/rig enumeration and native text measurement. Both were introduced in the crashing branch; the last log entry does not identify the faulting instruction. Passing offline tests does not establish in-game stability. Weapon attachment remains disabled pending a baseline test and a verified binding.

## Offline evidence

The independent September 27 mapped game.dll capture contains a useful call at RVA `0x770E12`. In its enclosing function, `0x770D40`, the input record is preserved in R14 and its entity ID is read from offset `+0x08`. Later:

```text
770DF5  edx = uint32(config + 0x10)
770DFC  rax = pointer(game.dll + 0x3326308)
770E03  rcx = pointer(rax + 0x18)
770E07  rax = pointer(rcx + 0x3B0)
770E0E  ecx = uint32(entity_record + 0x0C)
770E12  call rax
770E14  uint32(component_runtime + 0x04) = eax
```

This establishes that the engine consumes the entity field at `+0x0C` through this API table. It does **not** establish the API's name, the Lua handle encoding, or a safe transformation call. A node lookup taking a unit handle and configured name/hash is a working hypothesis only.

The ammo reader already reads the whole 24-byte entity record, but reports its `+0x10` native unit reference. These fields must not be treated as interchangeable. The baseline deliberately makes no new reads or engine calls using the candidate field.

| Record offset | Evidence / interpretation |
| --- | --- |
| `+0x00` | Resource/configuration key, 64 bits |
| `+0x08` | Entity identity, checked by the existing reader |
| `+0x0C` | Candidate engine unit handle; passed into the call above |
| `+0x10` | Native unit reference used by the existing ownership lookup |
| `+0x14` | Flags used by the existing ownership checks |

Entity lookup at RVA `0xFD9D40` resolves the entity map under the owner manager to a 24-byte record. Offsets and API slots here describe this capture only, not a portable engine contract.

## Next validation boundary

The user confirmed 0.3.4 works through gameplay and explicitly authorized using the Derive mod as a diagnostic aid. Installed DBF-derive R11 provides a file-command interface in `%APPDATA%/Arrowhead/Helldivers2`: `derive_in.txt` and `derive_out.log`. Its inspected commands include targeted `read`, `hex` (maximum 4096 bytes), and `watch`/`unwatch`. This is a memory inspection tool, not a ready-made weapon transform provider. The installed copy is packaged under HD2UI; no implementation is copied into DBF-HUD.

Prefer targeted Derive reads once a current module base and record address are established. Do not overwrite a pending command or interrupt another scan. A log saying INSTALLED establishes initialization at that time, not current responsiveness. External module enumeration returned no usable game.dll base during the initial check; do not reuse addresses from another game session.

First establish that 0.3.4 remains running through movement, firing and weapon changes. In parallel, trace additional consumers of `+0x0C` and identify the API table's signatures offline. A subsequent diagnostic can report the candidate from the already-read record, without invoking it or enumerating world units. Only after handle representation and lifetime are established should a selected-weapon transform be requested.

An attachment experiment should start with one marker, then orientation, then a camera-facing blend, then the ammo panel. No arbitrary handle casts or guessed native calls belong in the baseline. Lua pcall cannot recover from a native access violation.

## Camera projection diagnostic — 0.3.10

After disabling the packaged startup addon and redeploying, the fresh 0.3.9 log contained one timeline, no NUL gaps, and valid Scythe samples after mission landing. The previous overlapping runtime issue was not proven fixed by the takeover code.

Read-only tracing of the reticle call at game RVA 0x17B6FDF resolves ScriptAPI Camera (+0x20), world-to-screen entry (+0xF8). That function uses the camera at [game+0x346D560] -> [0], scene at camera+0x18, matrix index at +0x20, and scene matrix array at +0x28. Camera +0x28 is near plane, +0x34 vertical FOV, +0x30 perspective mode, +0x50 frustum mode. The inspected camera had identity local offset (+0x80 quaternion, +0x90 translation). The native projection first inverts scene pose and local offset, then applies the perspective projection.

The initial diagnostic implements only the observed symmetric perspective / identity-offset case; other modes fail closed. It draws a white cross at the weapon root using existing GUI rectangles. Native functions are inspected but never invoked. The marker is not yet visually validated or used to position the HUD. Thirty-five offline contract tests pass, including projection orientation/aspect/clipping and camera ownership rejection.

### 0.3.11 hybrid attachment

User confirmed the diagnostic marker follows the weapon. The HUD now supports a projected weapon-local mount, a camera-facing panel, configurable screen offsets, bounded damped motion, and reticle fallback. See MDL.md for controls and current calibration limits. All 37 offline checks pass; the full panel still needs live confirmation.

### World GUI availability probe (0.3.12)

Adds a startup-only check of the exposed World, Gui and Matrix4x4 function types. It does not invoke world GUI creation, movement or matrix constructors. Existing hybrid rendering remains active. Engine documentation supports world-space GUI primitives and transform-based movement, but game binding availability and depth behavior remain unverified.

Reference: https://help.autodesk.com/cloudhelp/ENU/Stingray-Help/lua_ref/obj_stingray_Gui.html
