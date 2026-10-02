# Screen marker depth investigation

## Live evidence

- Original magenta screen square tracks correctly in first and third person.
- Separate WorldGUI marker occludes but inherits the visible trailing.
- Screen bitmap_3d experiments in the main world were invisible, including at zero depth.
- Ordinary screen bitmaps in the UI world are visible and track with the magenta reference.
- The green outline using the depth-enabled loader-control material does not occlude.
- Main HUD and saved weapon layouts remain unchanged. Cyan is hidden.

## Asset evidence inspected

The extracted renderer configuration's `hud_world_ui_and_composite_layer` clears
`ui_depth_stencil` before UI draws. Its global resources separately declare
`linear_depth` (R32F, dependent on `depth_stencil_buffer`). This is an asset-level
finding; availability to a custom shader in the active UI pass is not live verified.

The loader-control pixel shader has no scene-texture input. Enabling its hardware
depth state alone cannot establish a marker-versus-scene comparison in the UI pass.

The native GUI blur shader provides a renderer-texture binding precedent:
`__tex_hdr0_div4_fullres` at t0 and `__samp_hdr0_div4_fullres` at s0. The high 32 bits
of the `hdr0_div4_fullres` hash occur outside its compiled DXBC at offsets 0x5ec,
0xf18, 0x3d88 and 0x3d98 in the extracted `gui-depth-blur.gpu`. These locations are
candidates for binding metadata, not a validated patch recipe.

## Compiled probes and access-only package

`assets/scene-depth-probe/screen_depth_probe.hlsl` contains two pixel shader probes:

1. `depth_access`: display sampled depth without hiding pixels.
2. `depth_compare`: compare sampled scene depth with marker depth carried in vertex color.

`tools/compile_scene_depth_probe.py` compiles both with the Windows D3D compiler and
checks their reflected texture/sampler bindings; the comparison shader contains
discard instructions. Both compile successfully. This proves shader syntax and
bytecode generation only. An access-only Arsenal package is now built, but no new
shader library or material has been deployed in-game.

Unverified assumptions include automatic `linear_depth` binding in the UI pass,
depth units, viewport/upscaling alignment and color-channel transport of marker depth.
Do not activate discard before the access-only probe establishes those details.

## Package and next live check

`tools/build_scene_depth_probe.py` builds `../DBF-HUD-Scene-Depth-Access-Probe-0.1.zip`.
It duplicates the native GUI blur library under a new identity, changes its four
renderer-texture binding records to `linear_depth`, and substitutes the compiled
access-only pixel shader. Compiler-owned private data preserves the original
serialized bytecode window; raw trailing padding was rejected and is not used.
The builder validates the padded DXBC through the D3D parser and reads back the
exact ZIP payloads. Existing 79 deployed shader-group entries are preserved and
one new library is appended. Native library parsing and binding remain unverified.

Private-data API reference: [Microsoft D3DSetBlobPart documentation](https://learn.microsoft.com/en-us/windows/win32/api/d3dcompiler/nf-d3dcompiler-d3dsetblobpart).

The installed Lua diagnostic detects the new material and draws a grayscale tile
beside the locked green/magenta squares. It logs material availability and submission,
not successful texture access. Its lifecycle checks pass in the 95-test contract suite.

Import the package into Arsenal, enable it alongside the existing depth/font packages,
deploy and restart. Aim at nearby character/gun geometry and then distant scenery;
check whether the tile displays spatially varying grayscale depth. A solid tile or
mere material availability is insufficient evidence. Do not enable discard until
the sampled texture, units and viewport alignment are established. All weapon offsets
and the main HUD remain unchanged.

## Live access result and comparison package

The access package initially deployed before the depth/font packages; later group
resources omitted its shader. Material availability and draw submission therefore
did not prove shader registration. After correcting load order, the user saw the
grayscale tile and confirmed nearby geometry darker and distant scenery lighter.
This supports a functioning scene-depth sample. It does not establish its units.

`python tools/build_scene_depth_probe.py --compare` builds the same-addon update
`../DBF-HUD-Scene-Depth-Occlusion-Probe-0.2.zip`. Replace the access-only package,
keep it last after depth/fonts, deploy and restart. The new comparison material
replaces the green reference outline; magenta remains unoccluded. Camera-space
bone depth is encoded in 16 bits across two vertex color channels over 0..64 metres.
The shader discards pixels where scene depth plus a 1cm tolerance is nearer.
The units, color transport and actual occlusion remain provisional until live tested.
The grayscale tile stops drawing when the comparison material is available.
The 95-contract suite checks encoding, material selection and primitive cleanup;
it does not prove native occlusion.

## Confirmed comparison and real HUD migration

The user confirmed the comparison outline occludes behind the character and remains
locked while sweeping in both views. This is live evidence for the isolated marker,
not yet for the full HUD. The former interpretation that magenta trails is incorrect.

`tools/build_scene_hud.py` builds the same-addon replacement, Screen Depth Renderer
0.3. Keep it LAST after the existing depth and native-font packages in Arsenal.
It retains the comparison probe and all 79 baseline shader-group entries, and adds
two shader libraries for colored fills and textured native atlas glyphs. The native
diffuse+blur shader template already binds two textures; only its renderer-texture
hashes change from blurred color to linear depth. The atlas remains unchanged.
Compiled pixel bytecode is padded with compiler-owned private data, disassembled,
and inserted without changing serialized record lengths or vertex shaders.

`screen_scene.lua` reuses placement's saved attachment and offset result, the existing
world-style geometry fitting, and speargun rotation/fold logic. It projects each quad
corner from that geometry into the same UI world as magenta. Text uses the existing
native glyph atlases and metrics, with two textured triangles per glyph; no new font
rasterization or replacement pixel font is introduced. Numeric leading zeros retain
their fixed positions and dim alpha. No WorldGUI pose move or motion smoothing is
used on this path. Profile files are not overwritten.

Depth comparison uses the existing material scalar names `threshold_fade` (panel
camera depth) and `scissor_mode` (comparison enabled). Fill and font colors/alpha are
ordinary vertex colors. Separate GUI instances prevent the speargun's folded child
from overwriting the main panel's material depth. Force occlusion and ordinary
aiming rules are retained. Depth is currently constant per panel, rather than
interpolated across its plane; angled/long panels need a specific live edge check.

The runtime attempts migration only when the new fill material is available. Missing
assets or a Lua submission error retain the original WorldGUI rendering. Set
`DBFHUD.screen_scene_hud=false` to revert temporarily; removing the new addon and
restarting also restores the previous asset-gated path. Diagnostic squares remain
for the initial comparison. Shader material setters, textured triangle UVs, actual
font coverage, and full-HUD occlusion/tracking still require the first live test.
The 99-contract suite proves geometry preservation, color/alpha transport, atlas UV
bounds, mode gating and cleanup offline, not native rendering.
