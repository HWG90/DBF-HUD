# HUD texture layers

Source-only implementation. Not installed or live-verified. Live experiments are stopped following the reported crash; its cause remains unresolved.

Atlas regions are supported with `atlas_rect={u,v,width,height}` on each layer,
using top-left texture coordinates. Regions compose with the existing perspective
mapping rather than stretching the entire atlas into each segment. Visibility
removes a segment's drawing commands while keeping the source image resident.
The current implementation is bounded to eight visible images and uses separate
material instances for independent mappings. It is not yet an optimized atlas
batch renderer, and no low-cost performance claim is supported. Per-weapon custom
font atlases and complex per-segment shader effects remain follow-up work.

A `texture` drawing command can include ordered `texture_layers`. The base image stays first. Each layer supports a separate texture, normalized rectangle, tint, alpha, explicit drawing order, and visibility. A layer can disable the selected theme with `theme=false`.

Weapon-driven visibility is provided by `HUD.panel_texture_layers.prepare`.
For Double Freedom, use a shell-free base and two independent shell images:

```lua
layout.texture_layers = HUD.panel_texture_layers.double_freedom(
    {texture='mods/dbf_hud/textures/df_shell',
     material='mods/dbf_hud/materials/df_shell'},
    {{.25,.34,.2,.36}, {.55,.34,.2,.36}})
```

The same shell image can be reused in both positions. Count 2 displays both,
count 1 displays the second barrel, and count 0 displays neither. Reloading
restores the images. SEMI/VOLLEY selection does not change ammo occupancy.
Unknown counts hide loaded-shell images rather than invent ammunition. Missing
layer assets retain the native panel. No texture creation/upload occurs on firing.
These names illustrate the asset contract; they are not shipped shell resources.

The accepted Mechanical renderer has a separate, undeployed stateful-layers
candidate. It replaces native shell primitives only when explicit image layers
are configured, and otherwise retains the existing shell rendering. Separate
shell art and a shell-free housing still need to be packaged and visually checked.

```lua
texture_layers = {
    { texture='mods/dbf_hud/textures/autocannon_shells',
      rect={.1,.2,.8,.3}, alpha=1, tint={255,255,255}, visible=true },
}
```

`rect` is left, bottom, width, height relative to the base image. `material` defaults to the base material and must use the artwork-texture shader contract. `texture` defaults to the base resource. Transparent RGBA pixels reveal the lower images. Commands can update visibility or choose another shell texture each frame without replacing the base artwork.

The renderer isolates each image in its own owned GUI/material instance so rebinding the same material for a second image cannot replace the first image's binding. Geometry uses the existing projection, clipping and depth path. Native primitives are cleared each frame; layer GUIs are reused and released with their parent. Eight visible texture images are supported per composed panel, including the base. Normal text and meters remain separate commands.

The Autocannon artwork has not been split into layer assets yet. This supplies the rendering capability; an asset definition still needs a transparent shell overlay.

Texture swaps retain immutable pixel files and publish a complete batch after every submission call returns. This does not establish GPU completion. The integrated HUD upload returned and published at 08:49:31 on October 5, but the same process (145156) crashed at 08:49:32.993. The later 08:50:20 restoration message is not evidence the original process survived. This trial failed the stability gate; it strongly implicates the upload temporally without proving the original corrupting operation. No layer candidate has been deployed.

Batch budget accounting deduplicates identical pixels at the same dimensions across logical names. Tests cover two layers sharing one resource at the exact retained-memory limit, and Restore cancellation at every pending upload stage. Native contract checks and the combined candidate's Lua compilation pass. Repeated live A/B/A swaps, layered rendering, garbage collection and shutdown remain required validation gates before calling the pathway reliable.

Renderer lifecycle mocks also exercise independent bindings for two images sharing a material, removal of hidden-layer primitives, reuse of existing layer GUIs, and exactly-once GUI destruction. These do not validate native GUI draw ordering in the game.

Layer commands reject non-finite color components and invalid drawing-order values before native drawing. The refreshed combined candidate compiles. A subsequent read-only code capture completed without uploading textures; it identified additional bookkeeping queues, but did not locate a GPU completion or backing-retirement contract. No further live swap validation was performed.

The backing verifier now reuses a probe buffer and byte-count output rather than allocating both for every 256-byte span. A local-buffer test exercises the actual verifier and proves unchanged full-span coverage with three temporary buffers per invocation for a 520x640 image. This is source-only allocation-pressure reduction, not a demonstrated crash repair; pixel ownership and retirement remain unresolved.

A weak-reference test confirms that the process-lifetime store keeps a mocked resource alive through two full collections after its manager closes. Inspected loader prototype source evicts the named module rather than the texture-store key; equivalence to the installed loader has not been hash-established. Neither result proves the engine's native backing lifetime.
