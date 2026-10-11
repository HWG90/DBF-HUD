# Runtime texture swaps: standalone implementation guide

Reviewed against maintained DBF-HUD and Epic-LUT source on October 8, 2026. Native behavior described here depends on the measured game build. Source review does not establish that every path has passed live testing.

## Start here

A texture swap changes which texture a material uses. We create a replacement, upload its pixels, and bind it to the material. The packaged game asset stays intact.

The renderer may read our pixels later, after the Lua call returns. That is why we keep both the texture and its pixel buffer alive. Removing the texture from view does not mean the renderer has finished using it.

The basic flow is:

```text
Read and validate pixels
          |
Keep an immutable copy alive
          |
Create texture -> Submit upload -> Wait for upload acknowledgment
                                             |
                                      Bind replacement
                                             |
                                  Restore / detach when done
                                             |
                         Keep until exit OR retire with completion proof
```

**Restore** means putting the original appearance back. **Detach** means removing references held by materials or drawing objects. **Reclaim** means destroying the owned texture and releasing its memory. These are separate operations.

## Choose the correct routine

| What you are changing | Use | How cleanup works |
| --- | --- | --- |
| A verified world-mesh or scope texture slot | HUD target-swap manager | Restores supplied original pixels; retains uploads until process exit |
| File-backed HUD panel artwork | Hot-art manager | Detaches drawing owners; can reclaim through the verified texture pool |
| Armor/helmet LUT colors | Epic LUT editor/session | Restores captured original bindings; retains successful uploads until process exit |

Only the hot-art path currently connects successful uploads to completion-based reclamation. Do not add `destroy` calls to the other paths as a cleanup shortcut.

## The objects we keep alive

| Object | What it contains | Why it matters |
| --- | --- | --- |
| Input document | File bytes or editable float values | Can be edited before making the upload copy |
| Upload buffer | An owned FFI allocation containing immutable pixels | Native queued work may still read its pointer |
| Texture record | Resource/handle, dimensions, upload state, source buffer | Keeps the upload and texture together |
| Binding record | Unit, mesh, material, slot, original/current identities | Lets us restore only a target we still own |
| Retirement token | Renderer/fence identity and submission serial | Lets the pool check whether old rendering work has completed |

Use a lifetime registry that outlives the feature/module being reloaded. In Lua, a host-owned registry or deliberately persistent `package.loaded` entry can do this; in native code, use an owner whose lifetime covers queued rendering work. Never clear the registry to force cleanup. Garbage collection has no knowledge of outstanding renderer work.

## Implement a material texture swap

A standalone implementation needs four parts: an input validator, an upload owner, a binding owner, and a cleanup state machine. Schedule native operations in the renderer phase verified for your integration. Keep file I/O and request preparation outside that phase where possible.

### Prepare the target and pixels

The target must be a current live unit with verified resource, material, mesh, and slot identities. Discover these through the existing runtime integration. Do not invent hashes or reuse a pointer from an earlier equipment instance.

Both image files must be raw, tightly packed RGBA8:

- Exactly `width * height * 4` bytes, with a row pitch of `width * 4`.
- Width and height: integers from 1 to 2048.
- Replacement dimensions must match the registered original.
- Current limits: 16 MiB per image and 160 MiB of retained pixel payload.

PNG and DDS must be converted before using this reader. The original file must contain the actual original pixels: this manager does not capture the original texture object.

### Implement the state machine

The following is language-neutral pseudocode. Its named operations describe responsibilities you must implement; they are not DBF APIs. The native calls that fulfill them are listed in the native reference below.

```text
capture_target(unit, mesh, material, slot):
    verify live unit, mesh membership, material identity, slot
    save original binding, if the API permits reliable readback
    otherwise require verified original pixels for restoration
    save expected current binding

request_swap(pixels):
    validate format, dimensions, byte length, and budget
    replace latest pending request before allocating

on_verified_render_callback():
    if a request is pending:
        verify target is still live and still owned by us
        reserve lifetime record before native allocation
        copy pixels into a stable owned buffer
        create texture; retain resource and upload buffer
        submit upload; record any queue/completion evidence
        move to WAIT_UPLOAD

    if state is WAIT_UPLOAD and upload_consumed(record):
        verify target and binding ownership again
        save intended current and previous bindings
        bind replacement; refresh or commit mesh
        read back binding where supported
        move to ACTIVE

request_restore():
    cancel unallocated requests
    on a verified callback, check target and binding ownership
    bind original object OR acknowledged original-pixel upload
    refresh or commit mesh; verify restoration
    leave successful uploads retained unless reclamation is proven
```

Record intended ownership **before** binding: the bind can succeed even if the subsequent refresh fails. Keep previous/current identities until the result is known. On failure, restore only a binding that is still yours. Do not overwrite another writer's change.

The reviewed HUD target implementation restores a separately uploaded copy of supplied original pixels. Epic LUT captures and restores the original texture object. Choose explicitly; the two approaches have different input and ownership requirements.

Restoration and closure may need several callbacks. Keep the cleanup callback and its read/renderer dependencies alive until restoration finishes. Treat a retired target as unavailable rather than writing through its old pointer.

## Implement a batch artwork loader

A batch loader prepares all replacement images before exposing the new set to drawing code. The folder and manifest format are application choices. The current implementation uses the format below; a standalone loader can use another validated format.

### Supply a manifest and raw images

`manifest.tsv` contains tab-separated rows:

```text
panel_name<TAB>520<TAB>640<TAB>panel_name.rgba
```

Replace each `<TAB>` with an actual tab. The filename column is optional and defaults to `panel_name.rgba`. Names and file stems allow letters, digits, underscores, and hyphens. The manifest allows up to 512 entries and 64 KiB of text; duplicate names and empty manifests are rejected.

Request a reload by handing the validated image batch to the upload state machine. Keep the currently published artwork available until the replacement batch is ready.

The loader validates the entire batch and its budget first. It then advances each image through separate render-callback stages:

```text
Cache lookup -> Create -> Copy -> Submit -> Wait until ready
                                               |
                                    Process the next image
                                               |
                                     Publish the whole batch
```

A cache entry is reusable only when dimensions and exact pixels match and its retained source/upload are valid. Firing and ammunition changes select existing artwork; they do not require new uploads.

### Track every drawing owner

A consumer is a material, GUI object, or drawing object that holds a texture reference. Track all consumers before publishing resources. Each consumer must provide a release operation that removes those references and reports success. Make release safe to repeat; hiding geometry is insufficient.

```text
publish_batch(prepared):
    require every prepared upload to be acknowledged ready
    ask every old consumer to release its texture references
    if any release fails: keep old resources; stop publication
    capture retirement tokens for unused old textures
    remove old textures from reusable lookup/cache
    expose prepared as the active batch

close_loader():
    prevent this owner from issuing new draws or reloads
    cancel requests that have not allocated resources
    detach its drawing consumers
    finish or retain interrupted uploads
    drain retirement work on verified callbacks
    close backend only after cleanup completion
```

Publication can be atomic at the application lookup level. Consumer release is a native side effect; if one release fails halfway through, earlier releases cannot necessarily be undone. Retain resources and report the failure.

An interrupted but already-created upload is an **orphan**. Complete its remaining upload stages only when its state is known and no native failure has made the outcome uncertain. Otherwise retain it. Free an unallocated reservation only when creation was definitely never attempted.

Restoring packaged artwork means removing the runtime publication and allowing the normal drawing fallback to run. It does not itself prove resources are free to destroy.

## How hot-art memory is reclaimed

The texture pool performs the following sequence:

```text
Upload consumed
      |
All consumers confirm detachment
      |
Evict old resource from lookup/cache; capture retirement token
      |
Wait for the same completion owner to advance beyond token serial
      |
Validate owned resource and destruction API
      |
Destroy once -> Remove record -> Release source -> Reduce byte count
```

The completion check reads the measured renderer/fence metadata. It requires the same owner and a completed serial strictly greater than the captured serial. An unreadable or changed owner, unsupported signature, or unavailable device prevents reclamation.

Before destruction, the adapter sets `release_started`. `Renderer.destroy_resource` frees the CPU descriptor immediately. Never inspect that descriptor after the call. Never retry an uncertain destroy: it may already have succeeded before raising an error.

Only confirmed destruction lets the pool clear the source and subtract its bytes. A batch is published together, but native release calls cannot be rolled back if a consumer callback fails halfway through.

If callbacks stop, cleanup remains incomplete. Keep the lifetime references intact.

## Implement a float LUT edit

A LUT is a small texture whose float values control shader behavior. Implement it using the same ownership pattern, with a float-texture creation API and reliable binding readback:

1. **Decode:** load bounded 2D RGBA16F/RGBA32F DDS data. The decoder converts the top mip to floats and rejects malformed payloads and nonfinite values.
2. **Capture:** record the original live texture bindings. Exclude materials shared with unrelated local pieces.
3. **Check ownership:** confirm each unit/mesh/material still exists and its binding is still the editor's expected object.
4. **Prepare:** cache by dimensions plus exact float bytes. For new content, reserve a persistent record and retain the immutable float allocation before native creation.
5. **Create:** obtain the texture handle/object and retain its source and view descriptor.
6. **Apply:** record current/previous ownership, bind, commit the mesh, and read back the binding.
7. **Restore:** rebind the captured original only where the editor still owns the current or previous binding.

Typical LUTs are 23Ã—N; pattern textures are 3Ã—1. DDS input is limited to 1 MiB and dimensions to 64Ã—32. The editor retains at most 8 MiB of pixel payload and 2,048 records per session.

LUT values include emission, mode, and material semantics. Do not treat every channel as display RGBA or clamp all values to 0-1.

The direct editor attempts reverse-order rollback of the current operation on failure. It restores only bindings it still owns. Failed owned restorations stay pending; `on_cleanup_poll` can retry cleanup.

Successful textures remain retained after editor shutdown. Restart reclaims them. The vendor's construction-failure destroy calls apply only when creation produces no valid object/render handle; they are not a general unload routine.

Although the vendor exposes `Engine.update_texture`, these editor paths use immutable cached creation. Queued updates may still read older buffers. Do not refill or discard them without a measured completion contract. Creation also waits on the render thread and can hitch; avoid creating on every frame or slider event.

## What to do when something fails

| Symptom | Action |
| --- | --- |
| Build/signature check fails | Stop native work; remeasure the changed contract |
| Unit/material changed or another writer owns the slot | Rediscover targets; preserve the other writer's binding |
| Upload or bind raises an error | Keep source/resource records; restore only still-owned bindings |
| Budget exhausted | Stop allocating; retain restoration capability; restart where reclamation is unavailable |
| Destroy outcome uncertain | Mark failure and never retry that resource |
| Cleanup callback stops arriving | Keep references; report cleanup as pending |
| Uploaded art looks opaque, clipped, or haloed | Check shader alpha, sampling, and material compatibility |

For a native-stage failure with uncertain side effects, save a persistent failure reason, stop new uploads, and retain outstanding records. The reviewed hot-art implementation uses this quarantine policy and also supports an `UPLOADS-QUARANTINED.txt` guard. Preserve logs and restart rather than repeatedly trying uploads.

An allocator/GC crash shows where damage was detected; it does not prove the cause. Check queued source pointers, descriptor capacity, outstanding bindings, and the actual loaded package first.

## Proving that it works

Use four levels of validation:

1. **Offline checks:** malformed input, budgets, cache identity, ownership changes, partial failures, cancellation, and pending cleanup.
2. **Runtime checks:** installed package identity, upload acknowledgment, stage logs, and binding readback.
3. **Visual checks:** game capture of a recognizable pattern, correct target, alpha, and restored appearance.
4. **Lifecycle checks:** repeated reload/restore/disable, equipment changes, and completion-based retirement where supported.

A returned upload call does not prove visible output. Queue consumption does not prove safe destruction. Fixtures do not establish a native queue/fence contract.

Expose diagnostics for retained pixel bytes/resources, active images, upload stage, failure reason, and pending retirements. Log each state transition with a job/resource identity. Byte counters cover pixel payload, not total memory overhead.

HUD fixtures include `runtime_textures.lua`, `runtime_texture_native.lua`, `runtime_texture_source.lua`, `hot_panel_art.lua`, `hot_art_quarantine.lua`, `texture_pool.lua`, `texture_completion.lua`, and `texture_retirement.lua` under `tests/`.

## Actual engine calls and measured contracts

### HUD calls

Native initialization checks PE timestamp `0x6ab382e4` and measured API prefixes. Calls run inside `HUDRenderBridge` API 1, with native render phase enabled around protected work.

| Step | Call / behavior |
| --- | --- |
| Create | `Renderer.create_resource('texture', 'R8G8B8A8', width, height)` |
| Copy | Allocate `uint8_t[width * height * 4]`, copy pixels, verify contents, retain the allocation |
| Submit | `Renderer.update_texture_base64(resource, prefix, 4)` under temporary backing-pointer redirection |
| Verify | Inspect queued opcode, resource ID, and captured source pointer |
| Ready | Captured upload queue vector becomes empty; mark `consumed` |
| Bind | `Material.set_resource(material, texture_slot, resource)` |
| Refresh world mesh | `Mesh.refresh_instance_hash(mesh)` |
| Destroy retired | `Renderer.destroy_resource(resource)` after all retirement checks |

The submission technique depends on the measured producer copying a pointer into its command. `prefix` encodes only the first four pixel bytes. The adapter temporarily supplies the owned source pointer, restores the original engine backing pointer immediately after the protected call, then verifies the command. This is not a general Base64 image uploader. Never copy a full image into an engine allocation of unknown capacity.

Before binding, the adapter inventories current worlds/units and checks unit resource, mesh, material-slot, and material identity. Use the direct `Mesh.material` handle; do not substitute a `Unit.set_material` wrapper.

### Epic LUT calls

`Engine.open` requires Windows x64, checks `get_engine_api`, obtains RenderBuffer API 26 and ResourceManager API 5, and verifies expected function addresses. Native mapping/discovery originates from CowboyBingus/Match Your Colors; preserve attribution and `vendor/LICENSE`.

| Step | Call / behavior |
| --- | --- |
| Find original texture | `can_get(TEXTURE_TYPE, name64)` then `get(...)` |
| Find current materials | `alive`, `meshes`, `mesh`, `materials`, `material` |
| Read binding | `Engine.binding` reads bounded arrays at material offsets +24/+32 |
| Create | `native.create(bytes, 1, 3, view, data)` then `native.resource(handle)` |
| Bind and refresh | `native.set_resource(material, slot, object)` then `native.commit(mesh)` |
| Restore | Same calls with original object, followed by binding readback |

The creation descriptor can be constructed without editor modules:

```text
data = owned float[width * height * 4]  // immutable upload copy
view = owned uint32[14], initially zero
view[0..6] = [0x80820820, 0, width, height, 1, 1, 1]
reserve_and_retain(data, view)          // before entering native call
handle = create_buffer(width * height * 16, 1, 3, view, data)
object = lookup_resource(handle)
validate object and render handle
retain(handle, object, data, view)
set_resource(material, 0x7e662968, object)
commit(mesh)
verify material binding equals object
```

Here `create_buffer`, `lookup_resource`, `set_resource`, and `commit` are the verified native function pointers obtained from the API tables. The constants `1` and `3` mean updatable validity and texture view. A standalone implementation must perform API-address validation and target/ownership checks before executing this sequence. Preserve 64-bit identifiers and handles in an exact integer representation.

LUT slot: `0x7e662968`. Pattern slot: `0x81d4c49d`. Texture format: RGBA32F (`0x80820820`), one mip, `width * height * 16` bytes. Handle, texture object, view descriptor, and float buffer are distinct objects.

### Existing implementations: persistent store keys

| Key | Path |
| --- | --- |
| `dbf_hud.runtime_texture_lifetime.v1` | HUD target swaps |
| `dbf_hud.hot_panel_art.lifetime.v1` | Hot artwork |
| `epic.direct_lut.retained.v1` | Direct Epic editor |
| `dbf.armor_lut_editor.retained.v1` | Session-based Epic editor |

## Optional project reference

The explanation above is self-contained. These files are optional examples of the described algorithms; paths are relative to the canonical DBF-Suite workspace.

| File | Responsibility |
| --- | --- |
| `DBF-HUD/src/runtime_textures.lua` | Target requests, budgets, restoration |
| `DBF-HUD/src/runtime_texture_bridge.lua` | Render subscription and lifetime store |
| `DBF-HUD/src/runtime_texture_native.lua` | Native checks, upload/binding, destruction |
| `DBF-HUD/src/runtime_texture_source.lua` | Owned source buffers and pointer redirection |
| `DBF-HUD/src/hot_panel_art.lua` | Files, stages, cache, quarantine, orphans, closure |
| `DBF-HUD/src/texture_pool.lua` | Consumer detachment, publication, reclamation |
| `DBF-HUD/src/texture_completion.lua` | Measured completion tokens |
| `DBF-HUD/src/screen_scene.lua`, `runtime.lua` | Drawing-owner release and backend closure |
| `Epic-LUT/vendor/engine.lua` | Native discovery, creation, binding/readback |
| `Epic-LUT/src/direct_editor.lua`, `session.lua` | Ownership, retention, rollback, restoration |
| `Epic-LUT/src/dds.lua` | Float DDS validation and interchange |

`texture_retirement.lua` is a separate acknowledgment-based abstraction. Hot artwork directly uses `texture_pool`.

## Optional application: Armory lock icons

The shared discussion proposes cosmetic lock icons for Archipelago-restricted items. Our routines could provide icon textures once the Armory surface is verified. An implementation still needs item-to-widget identity, restriction state, a reliable binding/overlay anchor, and handling for scrolling, menu rebuilds, and closure.

Reuse one immutable lock texture across compatible consumers and change visibility as restriction state changes. Register every owner and detach it before retirement. The Armory renderer needs its own verified integration; world-mesh and screen-scene contracts do not establish one. Cosmetic icons alone do not enforce restrictions.
