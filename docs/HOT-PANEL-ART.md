# Hot HUD artwork: loading and reclamation

HUD artwork can now be replaced repeatedly without retaining every previous revision until restart. The live deployment uses completion-gated resource reclamation. This contract applies to `hot_panel_art`, not the separate world-mesh/scope runtime-texture controller.

## Use

1. Prepare tightly packed RGBA8 files and `manifest.tsv` in `%LOCALAPPDATA%/DBF/HotTextures` using the artwork preparation/conversion tools.
2. In DBF-HUD Global Options, select **Reload texture files**.
3. Wait for the complete batch to publish. The existing artwork stays active while replacement uploads are pending.
4. **Restore packaged artwork** cancels pending publication, detaches override materials, and retires the hot resources after completion.

A HUD script update still requires reloading DBF-HUD. Replacing artwork after that does not require restarting the game. Unchanged pixels and dimensions reuse a valid resident resource. Requests while a batch is running do not replace its transaction.

## Limits

- Each image is RGBA8, at most 2048 by 2048 pixels and 16 MiB. Row pitch and exact file length are checked before allocation.
- The retained texture payload budget is 64 MiB. The active batch plus in-flight replacement must fit; this is a finite concurrent budget, not a cumulative edit limit.
- Repeated successful swaps reclaim retired payloads. A larger cap is not the reclamation mechanism.
- Unknown builds, changed native signatures, device loss, or uncertain native failures fail closed. Resources whose release cannot be proved remain retained and the upload session is quarantined.
- Retained-byte counters measure texture payload accounting, not total process RAM or a GPU-memory profiler. Lua buffers and in-flight renderer allocations add overhead.

## Ownership and release

Creation, owned source preparation, native submission, readiness, and publication run on separate render callbacks. The whole batch publishes atomically.

Before publication changes a binding, registered render consumers destroy their GUI/material owners. Old records are removed from image lookups and the pixel cache. A captured renderer serial then gates retirement: the completed serial must be strictly greater than the captured serial. Queue consumption alone is not GPU completion, and elapsed-frame guesses are not used.

Only after transfer consumption, material detachment, and completion are acknowledged does the adapter call `Renderer.destroy_resource`. Its wrapper invalidates the CPU resource descriptor immediately, so the handle is never inspected afterward or retried after an uncertain outcome. Successful retirement removes the record, owned source buffer, pixel string, and budget reservation.

Cancellation before native creation returns the unused reservation. An already-created unpublished candidate finishes its transfer without becoming visible, then retires. Cleanup polling continues through shutdown or transfers to the replacement HUD owner. The read backend remains open until its cleanup finishes. Empty cache buckets and retired consumer registrations are removed.

The implementation is divided between `hot_panel_art.lua` (staging/publication), `texture_pool.lua` (batch retirement and cache accounting), `texture_completion.lua` (guarded completion reads), and `runtime_texture_native.lua` (verified native contracts). `screen_scene.lua` registers material detachment; `runtime.lua` defers backend closure.

## Validation on October 5, 2026

The initial live migration reclaimed **13,851,280 bytes** of historical artwork. The active baseline was **21,500,656 bytes and six resources**.

A live stress test created and retired **32 fresh native resources of 6,291,456 bytes each**, using unchanged full-size artwork bytes and rebuilding the actual HUD material owners at publication. It returned to exactly the same active baseline. An earlier 32-cycle test used distinct 1-pixel payloads and also returned to baseline. Subsequent HUD reloads reused the six active assets, and the game continued rendering without a restart.

The actual staged uploader also passed **1,000 unique swaps offline**, with bounded retained bytes/resources, plus stage-by-stage cancellation, restore/reload, shared aliases, owner replacement, partial-failure quarantine, and deferred backend cleanup. Offline tests verify logic; the live runs establish native allocation, binding-owner detachment, upload, and release behavior on the measured build.

The full-size live validator did not change visible artwork and does not establish the correctness of unrelated color, typography, transparency, or shader changes.

A one-shot local `RECLAIM-TEST.txt` containing a count from 1 to 64 enables the allocation test on the next HUD reload. It is consumed once and should not be shipped as a default. The largest active artwork is copied into fresh test resources; the temporary alias is removed when the run ends.

See [validation evidence](validation/hot-art-reclamation-2026-10-05.json). `upload-stages.log` records publication and reclaimed-byte counts across script reloads.
