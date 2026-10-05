# Runtime texture swaps

The October 5 weapon-wall experiment visibly replaced all four cyan blueprint screens with the supplied smiley during one running game session. David confirmed both the replacement and the return of the original screens. No restart, input automation, HUD configuration change or production deployment was involved. Private images, captures, asset extracts and test scripts remain in the outside-Git review archive.

## What made the change visible

The atlas is `4412eaa6fe6a9627`, a 1024 x 1024 BC7 image bound to `emissive_map` on material `aa43784ff664c0f5`. The weapon-wall unit is `be0be6b1875a4a66`; its screen material slot is `a340edce`. Meshes 3 through 6 share that material. The candidate changed only the blueprint rectangle, preserving all other decoded atlas pixels.

`Material.set_resource` changed the recorded binding, but the screens stayed unchanged until `Mesh.refresh_instance_hash` was called for the affected meshes. The successful trial used that refresh after both replacement and restoration. Reinitializing the shader alone did not make the earlier change visible.

The failed test misinterpreted `Unit.set_material`'s boxed 64-bit return as a direct Material pointer. Its wrapper constructs an IdString64 value; the corrected test returned zero. `Mesh.material` returns the actual pointer expected by `Material.set_resource`. The invalid return was passed to Material APIs in the crashing trial. This is a demonstrated contract violation and the leading crash explanation; no dump analysis has established the exact fault instruction. The implementation never uses that return as a Material.

The clear replacement capture proves actual world-screen rendering. Restoration was confirmed by David and the successful stop log. Follow-up captures were obscured by the Windows task switcher and Steam playback, so they are not independent clear restoration proof. The same game PID survived the successful swap, restore and probe removal.

## Source integration

`runtime_textures.lua` owns registration, pending requests, immutable uploads, file reload, original-pixel restoration and target ownership. `runtime_texture_native.lua` implements the measured native ABI. `runtime_texture_bridge.lua` executes queued work only in the verified render callback. Both bundled builds include the modules. Initialization is lazy: ordinary HUD startup makes no texture allocations or swaps.

The native adapter checks the measured executable timestamp and API wrapper fingerprints. Other builds fail closed and need contract verification. Supported native targets are explicit unit/mesh materials for world screens and scope texture channels. World targets refresh all declared affected meshes. Scope targets retain the previously verified direct binding behavior. Registration requires the real unit, its resource identity, the material identity and slot, mesh indices, texture channel and original pixels. Every bind reacquires the material through Mesh.material and checks the live unit inventory. Retired units receive no stale native calls.

The current packaged HUD artwork pipeline is preserved. General GUI material targets, arbitrary shader channels, automatic asset discovery, encoded-image decoding inside the game and a universal texture loader are unsupported. The queue module accepts adapters, but an additional adapter must be independently verified before those targets are enabled. This source implementation is offline-tested; the successful live demonstration used the narrow prototype, not this new integrated manager.

## Preparing and using an image

Use `python tools/prepare_runtime_texture.py input.png output.rgba` outside the game. The converter preserves dimensions and RGBA channels and emits metadata with a SHA-256 digest. `--red-mask` emits R,0,0,255 pixels for the verified lens-occlusion channel. Do not resize or replace an entire shared atlas if only one atlas region is intended to change. A replacement must have the same dimensions as the supplied original.

An authorized integration can obtain the lazy controller from `DBFHUD.runtime_texture_swaps()`:

```lua
local textures = DBFHUD.runtime_texture_swaps()
textures.register('weapon-wall', {
    kind = 'world_mesh', unit = verified_wall_unit,
    unit_resource = 'be0be6b1875a4a66', meshes = {3,4,5,6},
    material_slot = 'a340edce', material_id = 'aa43784ff664c0f5',
    texture_slot = 'emissive_map'
}, textures.image(original_rgba_path, 1024, 1024))
textures.swap_file('weapon-wall', candidate_rgba_path)
-- Later, while the same unit still exists:
textures.restore('weapon-wall')
```

This queues work; it does not certify visible rendering. Inspect `textures.stats()` for status, then verify the result in the game. No target or image is automatically registered by this feature. Keep originals and private artwork in the local DBF folder or another private location, not in published source assets.

`DBFHUD.reload_runtime_textures()` rereads the last registered candidate files. The existing settings reload calls it when a runtime manager exists. Unchanged pixels are deduplicated, and multiple requests before the next render coalesce. A failed artwork reload is reported separately and does not undo valid settings/layout reloads.

## Upload and cleanup limits

Images are tightly packed RGBA8, at most 2048 x 2048 and 16 MiB each. Pitch and exact byte length are validated before upload. Pixels are copied into an exact-size Lua-owned buffer. The verified producer snapshots its pointer during submission; the engine backing pointer is restored immediately. Only four matching prefix bytes pass through the native decoder. The complete image never enters that decoder and never overwrites the engine allocation. Resources and source buffers remain retained for the process lifetime, under the 32 MiB retained-pixel budget. Publication waits for the verified command-manager reset after consumption, rather than an assumed one-frame delay; this acknowledgment is not a GPU fence.

The successful prototype establishes the full-backing upload path for these measured targets. No arbitrary game-memory write or existing game texture backing mutation is used. The original is uploaded into its own immutable resource before any replacement binding. Restoration restores the decoded original pixels rather than relying on the unreliable original-ID setter. It does not restore the original compressed resource identity.

GPU fences and safe destruction have not been verified. Resources, including those allocated by failed uploads, remain strongly retained in shared Lua module storage until process exit. A 32 MiB retained backing budget blocks further allocations before exhausting it; original and candidate are budgeted together. Failed bind/refresh operations queue restoration. Failed restoration keeps ownership and the render callback pending; cleanup completes only on an explicit true result. HUD retirement cancels pending replacements and queues restoration. A new HUD cannot claim a target still owned by retiring cleanup.

No production artifacts were installed as part of this integration. A separate live check of the integrated manager is still required before treating it as production-proven.

## Offline validation and handoff

The owning DBF-HUD checkout passed 18 runtime-manager contracts and 11 native-adapter contracts. Existing texture-art tests also passed for retention, scaling, opacity, fallback and faithful/realistic geometry. Standalone and MDL bundles generated from this checkout compiled with LuaJIT in temporary staging; installed files and existing generated artifacts were not replaced. The edited runtime and build hooks passed whitespace checks.

The broader contract suite is not a passing result: it fails because its mock lacks `Application.can_get`. The unmodified baseline reproduces the same failure. These checks establish offline behavior and syntax, not native rendering or GPU lifetime safety.

The later message "game crashed" is a new user report, not an explicit review of the earlier failed boxed-handle trial. At inspection the original game process still existed and no newer local crash dump was found. Its cause remains unresolved; the source integration was not deployed. Live probes remain removed and the stopped experiment must not be restarted implicitly.

Next deployment requires an explicit decision to install the integrated build and run a bounded native-target test. No target is enabled by default. Keep the known-good build and original pixels available, verify replacement and restoration visually, and retain the resources until process exit.


## 2026-10-05 reliability investigation
The metadata reader had a reproduced one-byte overflow when an N-byte FFI array was initialized from an N-byte string. It now decodes bounded metadata directly, without temporary FFI arrays. The exact source-buffer path passes guarded allocator checks. In PID 143604, 64x64, 520x640 and 1448x1086 uploads survived repeated collections. An exact-material A/B/A test reached the Double Freedom HUD binding and restored its hooks; the normal reload entry point also completed A/B/A, reusing A without a third allocation. A live owner replacement also retained both source buffers through full garbage collection. The post-reload A/B/A sequence also passed with the same two retained allocations. The standalone toolkit resumed its ready state. Normal uploads were enabled after these checks; David confirmed the visible swaps and repeated HUD reloads. The prior quarantine text remains as a backup.
