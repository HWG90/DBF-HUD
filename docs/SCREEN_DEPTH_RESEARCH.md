# Screen-depth rendering

## Active path

`screen_scene.lua` projects the saved weapon attachment and panel geometry each update. Text uses the same projected orientation and scale. Depth-aware materials sample the scene’s linear-depth texture and compare it against the panel depth. Clear materials bypass occlusion.

Tracking and scene occlusion were confirmed together in game. Diagnostic markers are disabled by default. First-person panel wiggle remains a separate unresolved alignment issue.

## Assets

Custom shader source and bytecode are in `assets/scene-depth-probe`. `hud_scene_depth.hlsl` handles depth-aware text and `hud_scene_fill.hlsl` handles panel geometry. `compile_scene_depth_probe.py`, `build_scene_depth_probe.py` and `build_scene_hud.py` compile and package assets.

Packaging requires matching local shader-library donor files extracted from the game. These inputs are not distributed in the public checkpoint. Preserve serialized binding layouts and shader-group composition. Package validation is separate from live shader acceptance.

## Deployment

Keep the combined screen-depth/font package after earlier font/depth packages in Arsenal so its shader group remains active. Disable obsolete access-probe packages. Deploy and restart for shader changes; MDL Lua reload alone cannot replace compiled assets.

## Verification

Check text, digits, icons, opacity, panel orientation and both camera views. Put a panel behind scene geometry, toggle Force occlusion and compare. A loaded material or successful draw call does not prove visible output or correct depth comparison.
