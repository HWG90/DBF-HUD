# Texture artwork renderer candidate: contract v1

Offline implementation only. No installed HUD, input ownership or release package is changed by this candidate. `texture_art_trial=false` and an empty registry preserve every accepted primitive panel. Reverse the candidate commit to remove it.

## Handoff to Texture: original standard Liberator only

Use the CURRENT ORIGINAL accepted Liberator layout. Do not redesign it or import the rejected 47-weapon batch. Preserve count, reserve, meter, fire-mode, empty/loading and all other state behavior. Identify its verified resource ID in `src/weapon_names.lua` before adding the registry entry. No weapon migration is implemented here.

`src/texture_art_assets.lua` returns a table keyed by weapon resource. Each entry has `version=1` and `layers`, for example:

```lua
return { [VERIFIED_RESOURCE] = {version=1,layers={
 {id='liberator.receiver',material='mods/dbf_hud/materials/art_liberator_receiver',
  texture='mods/dbf_hud/textures/art_liberator_receiver',command_count=EXACT_STATIC_COUNT,aspect=WIDTH/HEIGHT}
}}}
```

The artwork adapter tags only the original static `rect` commands with `texture_art_layer='liberator.receiver'`, `texture_art_static=true`, and `texture_art_opacity=visibility_opacity`. Bake individual original rectangle colors/alpha into the image; the common visibility opacity is applied once by the renderer. Do not bake live values or tags into the image. Do not tag text, panels, state-dependent icons, meters, effects, child/fold geometry or shader backgrounds. Keep the original panel commands for bounds, placement, backgrounds and animation. Each layer needs a unique material name, because its inverse mapping uniforms belong to that rectangle.

Export straight-alpha RGBA, tight to the union of the tagged rectangles, with top-left image origin. Preserve transparent regions. The union's logical aspect ratio must match `aspect`; the runtime checks tagged command count, aspect, finite geometry, ownership and opacity before replacing anything. Missing assets or invalid groups return the original commands atomically. Native execution failure after resource availability is not an established fallback case yet.

The common logical canvas is the existing composed panel coordinate system. Counts/meters retain their original coordinates. Texture bounds are computed from tagged geometry AFTER current world-style scaling, and before rendering. `src/screen_scene.lua` computes a rectangle inverse from the same pose and camera snapshot, then passes the rectangle through existing screen-edge/near-plane polygon clipping and depth settings. No independent texture size/position compensation is applied. 2D and MCM previews retain primitive artwork in v1; the texture adapter runs only in the projected world renderer.

## Native importer/material requirements

`assets/panel-shaders/texture_art.hlsl` is the candidate pixel shader entry `hud_fill`, profile `ps_5_0`. Keep the existing untextured triangle vertex program. UVs are reconstructed from the rectangle inverse per pixel, avoiding affine UV distortion. Preserve `scissor_rect` c0, `scissor_mode` c1.x, `atlas_scissor` c2, `threshold_fade` c3.x and `clip_box` c8 in material metadata. Viewport remains b0/c48, material constants b2. Scene depth is t0/s0; straight-alpha artwork is t1/s1, exposed to Lua as texture parameter `artwork_texture`. Do not replace the depth sampler with artwork. Use standard straight-alpha blending and clamp-address artwork sampling. Register both texture and material resources so `Application.can_get` succeeds.

These native bindings, filtering, blend state and packaging are a required integration test, not proven by Lua mocks or successful shader compilation. The existing single-plane depth approximation is preserved, not corrected by this candidate. Dynamic panel/effect shaders retain their own mapping and animation uniforms; texture layers do not consume or override them.

## Resolution and authoring

Verified current limits: saved weapon-layout editor scale 0.05 to 3.0; generic 2D config scale 0.5 to 2.0. Pattern size 0.25 to 4.0 is a separate shader control and must not choose artwork resolution. Texture's standard Liberator identity is `968211c0033dce64`, logical canvas 124x110. Its 2x export is 248x220 and 4x is 496x440. Uncompressed RGBA bases cost 218240 and 872960 bytes per layer respectively, before mips/native overhead. At maximum editor scale, nominal logical width is 372, but actual projected size depends on camera/pose/FOV, so these sizes alone do not establish adequate resolution. Runtime sampler/mipmap behavior is unverified.

For full-canvas PNG layers, the adapter sets `texture_art_box={x=canvas_x,y=canvas_y,w=124*scale,h=110*scale}` on each tagged source group. This overrides tight-union bounds, preserving transparent padding and aligning live anchors to the same canvas. Reject a noncanonical font-dependent width and retain primitives until fixed-canvas readout anchoring is supplied. Use three unique layer/material IDs for underlay, recesses and details. Their common opacity values are HUD visibility, panel_opacity*HUD visibility and HUD visibility respectively. Texture commands draw at 49.01, 49.02 and 49.03, above panel background 48 and below live rect readouts 50/text 51. Existing shader effects keep their own layers.

To compare faithful and hyper-realistic artwork without changing geometry, keep shared `layers` metadata (id, command_count, aspect), and add `variants={faithful={ [LAYER_ID]={material=...,texture=...}}, realistic={ [LAYER_ID]={material=...,texture=...}}}`. Only asset references vary. Every variant must supply every shared layer. The candidate menu exposes comparison enable and variant selection only for standard Liberator. Both go through the existing per-weapon persistence path. Trial defaults off; faithful is the default variant. No assets registered means primitive fallback. The Texture chat owns both images and editable sources; this renderer supplies no competing conversion.

Author in editable layers at the logical canvas proportions. Export 2x and 4x versions for comparison, not as a fixed requirement. Runtime HUD scale limits are defined by current config/editor sources; world distance, zoom and perspective can make projected pixel size much larger or smaller than logical size. Live text stays on the font atlas path and does not inherit artwork resolution.

Choose resolution from the largest intended projected artwork size, smallest-scale legibility and measured memory cost. For uncompressed RGBA, W*H*4 bytes before mips; a full mip chain adds roughly one third. Actual native format/compression changes that cost. Mips can reduce shimmer when shrinking, but blur thin markings; filtering and mip support must be checked in the imported material. Do not claim 4x optimal or a speedup before matched live samples. A source/template, manifest and importer should let an author export art without learning native shader metadata.

## Validation boundary

`tests/texture_art.lua` tests static replacement, dynamic retention, bounds, opacity, scale, missing resources, malformed grouping and state-command rejection. Existing renderer tests cover 800 planar inverse cases and accepted panels. The registry is empty, so no Liberator texture, in-game artwork, performance gain, filtering quality or native depth proof is supplied yet.

## Realistic artwork and lighting checkpoint

Keep `hyperreal-material-source.png` intact as the approved realistic source. Do not clip its stronger skull or bevels to the faithful vector masks. The faithful three-layer baseline remains separate. Fit the realistic artwork to the same 124x110 logical canvas and live readout anchors; baked recess shading needs an explicit opacity decision before native integration. The faithful source groups contain 50 underlay, 2 recess and 53 detail commands.

The candidate pixel shader is lighting-independent: its output is sampled artwork RGBA multiplied by vertex tint/visibility. It reads no world light, surface normal, shadow or PBR material inputs. Weapon-relative placement and camera projection still position the triangles; scene depth still controls optional occlusion. This is screen-projected GUI geometry, not a scene-lit weapon mesh. Exposure, tone mapping, color-space conversion and actual native material blend/filter behavior remain unverified until the material is imported and tested in game.

This change replaces tagged static artwork only. Geometry clipping, the camera snapshot, saved weapon placement, dynamic counters/meters, font rendering and animated panel/effect shaders retain their existing paths. Their offline regression checks do not establish a live texture integration result. The historical world-mesh experiment and its lighting compensations have not been recovered from source evidence in this checkpoint, so this document does not claim its precise implementation or disposition.
