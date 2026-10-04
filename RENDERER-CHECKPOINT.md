# Renderer checkpoint: 0.3.42

This source checkpoint preserves the accepted installed weapon panels, including the plasma family, Bolt Pistol, Ultimatum, Leveller, Breacher, Hot Shot and Punisher. Projectile illustration backing is transparent; Breacher uses its flipped shell and SHELLS reserve label. Unapproved remaining-weapon review drafts are not installed by this checkpoint.

The production world renderer maps all 40 shader choices into panel coordinates using a direct planar inverse. Main/folded panels and panel/effect material state are isolated. Weapon Appearance provides independent Panel pattern size and Effect pattern size sliders, from 0.25 to 4, default 1. These change pattern frequency, not panel dimensions. Panel opacity defaults and bundled presets are 0.8; individual saved settings are not published here.

The MCM preview repair uses the existing mapped materials, normalized panel coordinates, retained uniform refresh, and separate material state for the four main/child and panel/effect roles. Latest visual acceptance remains pending a game launch. Earlier user feedback verified stationary local mapping and visible Warning hatch; it did not certify every shader choice.

## Optional animation assets

`assets/panel-shaders/mapped` holds production static pixel-shader sources. `assets/panel-shaders/animated` contains the optional counterparts for all 40 designs. Their animation choices are described in `animation-designs.json`. Animation shaders compile and the matched 732-resource package is staged in Arsenal, but live animation is unverified. Production Lua in this checkpoint retains the static path.

Both shader variants retain the native untextured triangle vertex program. Depth is sampled through t0/s0. Panel inverse rows use scissor_rect.xyz, atlas_scissor.xyz, and clip_box.xyz. In animation candidates, scissor_rect.w carries seconds and atlas_scissor.w is the enable flag; disabled preserves the frozen sample. Native metadata must retain those vector offsets. New native shader packages require deployment and a fresh game session. Do not put the standalone startup adapter in an MDL/LLL lifecycle folder.

## Validation

`python tests/run.py --suite tests/renderer_checkpoint.lua` checks independent scales, bounds, inheritance, opacity, degenerate rejection and 800 planar projection cases. The source bundle builds. The companion MCM checkpoint tests retained preview updates, role isolation and GUI cleanup.

The older broad `tests/contracts.lua` suite currently stops at its legacy Bingus control-count assertion. Its earlier logging assertion has been updated to distinguish ordinary material availability probes from opt-in research output. The rest of the historical suite and old visual snapshots still require reconciliation with accepted menu and panel changes. This checkpoint does not claim all historical tests pass or that the latest menu repair is visually proven.

## Static artwork as textures

The current screen renderer clears prior rectangle triangles and emits at least two `Gui.triangle` calls per visible art rectangle. Clipping may create a larger triangle fan. Material initialization is cached per render pass, but art rectangles are not submitted as a single batch. Recycled Lua tracking records reduce allocations, not the number of native triangle submissions. Text is separate atlas-glyph rendering.

The composed command counts from the targeted suite are: Leveller 146 art rectangles, Breacher 59, Punisher 76, Hot Shot 125, and Ultimatum 179. These are CPU command counts, not a GPU profiler or frame-time measurement.

A practical future design is a transparent static artwork texture per panel or atlas region, with dynamic counts, meters, loaded-state coloring, modes and selected decorations kept separate. It could replace hundreds of small art triangles with a few clipped textured quads. Existing font rendering proves an atlas/textured-quad path, but the current panel shader uses an untextured vertex program. A new matched material must sample artwork using the panel inverse or a verified textured vertex input, while keeping the scene-depth sampler separate. Simply passing UVs to the current panel shader is insufficient.

An atlas can reduce texture/material switches. Extra textures consume memory and add native packaging work; compression and mipmaps affect clarity and memory cost. Shader backgrounds can remain an independent layer. Scaling and clipping can continue using the existing panel coordinates. Benchmark Lua layout time, native submission time and total frame cost with the same panel/view before claiming an improvement. No texture conversion is made in this checkpoint.
