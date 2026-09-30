# Native display trace — 2026-09-29

## 0.3.36 startup dispatcher separation

Recovery 0.3.34 was observed running after restart. Added authored startup-only HUDRenderBridge addon; MDL client no longer writes/restores the global render callback. It subscribes through API 1 and unsubscribes before GUI/viewport/world/texture cleanup. The bridge preserves host arguments/returns, isolates listener Lua failures and prevents an old unsubscribe from deleting a replacement listener. Existing global ownership is not registered with MDL. Offline tests cover these behaviors (41 pass).

HUD-Render-Bridge-0.1.zip contains only this dispatcher, packaged with the existing Bingus addon builder. It requires normal Arsenal deployment and restart; do not load it through MDL. Live client 0.3.36 is installed and remains inert with respect to offscreen rendering until the bridge exists. The four-color texture preview remains the next live experiment; callback ownership fix does not establish GPU cleanup safety or visual correctness.

## CTD recovery — 0.3.34

Further catalog inspection found the actual loaded camera resource `core/units/camera` (465f4895f3dc98d1) in the boot archive. 0.3.32 successfully created that private camera, the named shading environment, and the four-color GUI; the live render callback submitted render_world without a Lua error. Pixel content was not verified.

0.3.33 added a preview attempt using core/performance_hud/gui and Material.set_resource(diffuse_map, target). After auto-reload, the log instead reported no global render callback. The user then reported a CTD and the process exited. No preview success was observed.

Root-cause evidence for callback loss: the inspected MDL make_env implementation wraps rawset and records all writes targeting the real global table in mod.globals. Thus the experiment's direct rawset(render) was tracked even without ctx.global. Teardown called the experiment's restoration first, then deleted every tracked global, including the restored render callback. This is a verified lifecycle bug; without a crash dump it is not conclusive proof of the native CTD's entire cause. Offscreen GPU teardown timing remains unverified too.

0.3.34 removes automatic offscreen-test startup entirely and is installed in the live folder. No further render hooks or offscreen allocations are attempted by the live entry. Existing HUD behavior is preserved. 41 offline checks pass, including a disabled-entry regression check. A fresh game process is necessary to restore the host's original callback. Do not re-enable the experiment until MDL ownership and GPU lifetime behavior are addressed.

## Packaged-camera candidate audit

Read-only base-archive scan for the Appkit camera names, editor camera, camera_marker, and configured midday environment found only the latter two resources. The environment exists as resource 9f09b0185b47408f, type fe73c7dcff8a7ca5, 6528 bytes. camera_marker exists as unit 6144b1b6ad477ffb, 1984 main bytes, in archive fc5b6bff0db90aab. Its payload contains mesh metadata, a lambert1 material reference (0a44cebaf396d921), and script keys LevelEditor/is_gizmo_unit. This makes it an editor-marker candidate, not a verified render camera. No camera unit was packaged or spawned based on its name. The generic Appkit names were not found by this scan; this does not prove absence from every patch or unnamed asset.

The packaged-camera route remains unverified. A usable camera component and its dependencies must be established before deploying any unit. Live 0.3.31 remains unchanged.

## Auto-reload enabled; 0.3.30–0.3.31 live results

User confirmed MDL automatically reloads live Lua. Treat every write to the installed mod as an immediate deployment: build and test in the workspace first, then atomically replace the live file. Do not ask for manual reloads unless auto-reload fails.

0.3.29 stopped on missing create_default_shading_environment. 0.3.30 adds the standard named create_shading_environment fallback using the renderer's configured midday asset, guarded by can_get. Live setup then stopped on the unavailable Appkit camera unit before reaching environment allocation. 0.3.31 enumerated available camera APIs and checked alternate named resources. Camera exposes transform/projection operations, but no creation function; World exposes camera-shake/debug operations only. The Appkit camera, camera_marker, and editor_camera alternatives all report unavailable. These are loaded-resource checks, not proof the archives lack those assets.

No render_world submission occurred. The ammo HUD remains operational. All 40 offline tests pass. A valid engine camera must be obtained through a verified existing-camera interface or an independently packaged camera unit before this test can advance. The named shading-environment fallback is still not exercised live.

## 0.3.29 camera and render-callback experiment

MDL live now runs a guarded offscreen test. It requires an existing global render callback, all lifecycle APIs including create_default_shading_environment, and the loaded core/appkit/units/camera/camera resource. Missing prerequisites stop setup with a log entry. On success it creates a private world, camera unit, shading environment, native offscreen viewport, 64x64 texture, and retained four-color screen GUI. A wrapper submits exactly one render_world call before forwarding to the original render callback with all arguments/returns preserved. A submission log is not pixel verification. Resources remain alive until disable/reload.

The wrapper is restored explicitly when still owned by this test; it is not registered via ctx.global, whose inspected MDL implementation would delete that name on cleanup. Cleanup destroys GUI, viewport, shading environment, world (including camera unit), then texture, stopping on a cleanup error. The normal ammo panel is unchanged. The previous completed target-binding smoke test is removed.

All 40 offline contracts pass, including one-shot submission, callback return preservation, restoration, absent-callback behavior, and cleanup order/idempotence. Native initialization/rendering and the existence/timing of the host's render callback remain live checks. No pixel output or 3D mesh has been claimed yet.

## 0.3.28 live binding succeeded

The live log confirms world/viewport/texture creation, output binding, detachment, and cleanup of all three objects completed. Native offscreen target assignment is now exercised successfully; no pixels have yet been rendered or displayed.

Follow-up read-only inspection traced Application.render_world through its Lua wrapper to the current process implementation at 0x7FF692858150. It dereferences the camera at +0x18/+0x20 without a null guard. A nil-camera UI-only render is therefore not a valid next test. A valid camera and a verified render-phase integration are needed. The inspected MDL source exposes on_update and cleanup but no on_render callback; this does not establish that the host lacks another render integration. No render call or new deployment was made during this inspection.

## Target setter signature traced / 0.3.28

Read-only Derive inspection of the logged Viewport.set_output_render_target entry (this process: 0x7FF69296CAA0) shows userdata extraction for arguments 1 and 2 followed by a call to 0x7FF6928732C0. The implementation stores the second pointer at viewport +0x78 and enqueues an output-resource update. The null branch restores the viewport template's configured output ID. This supports set_output_render_target(viewport, render_resource_or_nil). register_render_resource separately extracts a hash/name argument 2 and userdata argument 3; it is not required for the direct output test.

0.3.28 creates a temporary world, creates its offscreen_ui_weapon_screen viewport, allocates a 64x64 texture, binds and detaches it, then destroys viewport, world and texture. It does not render or spawn anything. Each stage is logged and Lua errors enter cleanup; native faults cannot be caught. A failed viewport/world cleanup deliberately prevents texture destruction to avoid freeing a possibly referenced resource. The 39 existing offline checks pass, but do not verify native GPU behavior. Installed for live reload.

## Allocation confirmed; binding signature inspection

0.3.26 live log confirms create complete and destroy complete for the 64x64 render target. This verifies allocation/lifetime only, not rendering. 0.3.27 removes the completed allocation test and uses protected jit.util.funcinfo lookups to log C entry addresses for target assignment, resource registration, viewport creation, world rendering, texture upload, and mesh material access. The funcinfo address facility was checked offline against a C function using the installed LuaJIT DLL. None of these inspected engine functions is invoked by the diagnostic. Existing 39 tests pass; installed for reload. Public documentation and available offline binary captures did not establish the custom setter signature.

## 0.3.25 results / 0.3.26 allocation test

Live enumeration found Viewport.set_output_render_target and register_render_resource. Their signatures are not established by the public Viewport C header, which contains only set_rect. Neither was called. Renderer also exposes resource and update_texture_base64; their presence is not proof of a supported panel pipeline. Unit exposes mesh access; upstream examples obtain material pointers through Mesh.material rather than Unit.material.

0.3.26 performs one documented Renderer.create_resource('render_target','R8G8B8A8',64,64) and immediately destroys the returned resource, logging both steps. This is a texture-lifecycle smoke test only. It does not bind a viewport, render a GUI, or spawn a surface. Lua errors are caught, but native faults cannot be caught by pcall. The existing 39 offline tests pass; live GPU allocation is pending. Current visual modes and user tuning remain unchanged.

## Live results and decoded render configuration

0.3.24 confirmed Renderer.create_resource/destroy_resource and Material.set_resource, but both guessed Viewport target setters are absent. Unit.material is absent. Both hologram unit resources report available; the named weapon-screen material reports unavailable in this session. No resource allocation was attempted.

Extracted `rendering/renderer` (resource ee6b1ba7e22d71ed, type 27862fe24795319c) from the same-named base archive, and decoded its typed binary configuration. Selected records are saved in NATIVE_RENDER_PATHS.json. The offscreen_ui_weapon_screen viewport has empty output_rt/output_dst, no private resources, and layer_config ui_only. That layer clears its color output then submits the transparent pass without a depth attachment. This establishes a native offscreen template but not the runtime method for assigning its destination.

The ui_3d configuration explicitly clears its own depth/stencil target. The HUD composite configuration also creates/clears UI depth and runs blur_behind_ui. These records explain why a UI pass cannot be assumed to retain scene depth; they do not identify the exact viewport submitting DBF-HUD's current world GUI.

0.3.25 enumerates actual Viewport/Renderer/Material function names and material/mesh-related Unit names without invoking them. Installed for one reload; all 39 contracts pass. Current HUD appearance and settings remain unchanged. Image destination assignment and native mesh material access remain the next missing bindings.

## Live prerequisite check: 0.3.24

Installed a one-time lookup-only probe for Renderer resource creation/destruction, Material resource binding, viewport/render APIs, surface lifecycle functions, and availability of the native plane/cylinder/weapon-screen assets. It does not allocate GPU resources, spawn units, call render_world, or alter the current panel. All 39 offline contracts pass. A live reload is required to obtain the results.

Upstream [Renderer documentation](https://help.autodesk.com/cloudhelp/ENU/Stingray-Help/lua_ref/ns_stingray_Renderer.html) describes creating an R8G8B8A8 render target. [Application documentation](https://help.autodesk.com/cloudhelp/ENU/Stingray-Help/lua_ref/ns_stingray_Application.html) requires a configured viewport template for rendering. Those documents do not establish which functions or templates are available in this game. Target assignment and render-callback timing must be verified before rendering an offscreen GUI.

Read-only extraction from the installed game's base bundle archives. No runtime functions were called, no assets were deployed, and the working HUD was not changed. Patched resource precedence and live occlusion have not been verified.

## Weapon screen: strongest candidate

`content/fac_helldivers/equipment/primary_weapons/assault_rifle_nacho/materials/weapon_screen` was present as material `09fb77881b4cc43e`, with a 688-byte main payload. Its base material reference is `2661ebb51d18778d`.

That base was located in archive `18235e0c9ec0e636`: 608 bytes of main data and 480,944 bytes of GPU data containing 62 DXBC signatures. Extracted shader symbol strings include:

- `cb_world`, `cb_last_world`, `camera_view_projection`
- `__tex_input_image`
- `screen_enabled`, `screen_rect`, `Atlas_size`
- `emissive_amount`

These are evidence of a scene material accepting an image and screen-region parameters. They suggest an image/atlas-fed display; they do not establish which API supplies the image, exact parameter semantics, or depth state. Counting DXBC signatures is not a count of render passes.

## Objective terminal: corroborating reference

`content/objectives/obj_cyborgs/cyborg_generic_objective_terminal/materials/m_cy_computer_screen` was present as material `9441410bcfb5ae85`. It references base `2f8279894fea04c5`, also in archive `18235e0c9ec0e636`. The base GPU data is 952,384 bytes with 120 DXBC signatures and the same image/screen parameter names above.

The terminal and weapon instances reference scratches, dirt, black dummy input, light bleed, distortion, and roughness textures. Their native draw setup likely provides a live screen input, but static texture references alone do not prove a runtime binding.

## Ship hologram: less suitable

The `content/env_ship/hologram/units/hologram_cylinder` unit's parsed material table contains slot `cd121f4b` referencing material `10e79f2595b39bc1`. Its GPU payload contains symbols including `c_hologram_common`, `hologram_position`, `hologram_wp_to_real_wp0` through `3`, fade bounds, and distortion settings. This is a specialized hologram path, not evidence that it can substitute for a generic GUI material.

The named hologram plane unit was also located; its material-list offset is zero under the current Filediver header layout. No material binding was inferred for that unit. The catalog's `bridge_hologram_map_00` name was not located by this bounded scan.

## Next binding to establish

Trace the native screen's `input_image` resource assignment and `screen_rect` setup. Verify whether an exposed API can render the existing GUI into that image, and whether an independently created surface can use it. Verify scene depth on an actual native reference before claiming successful occlusion. Do not assign these mesh materials to Gui.bitmap merely because they exist: their vertex inputs and resource bindings differ from the GUI path.

The 3D panel currently retains its transparent fallback. This investigation found a concrete native image-backed screen reference, not a completed depth or frost fix.

## DBF-HUD research resume

The current session reports `OFFSCREEN blocked: startup HUD render bridge required`. Earlier submissions do not establish bridge availability after a restart. No offscreen pixels or scene occlusion are verified. The preview now reports unavailable APIs explicitly, and logs GUI creation, material lookup, resource binding and bitmap drawing separately. Offline coverage verifies that a missing preview API is reported without a second render submission. This diagnostic does not change render timing, shaders or resource ownership.

The subsequent live reload found the bridge, created the private scene, and returned from render_world. Preview GUI creation and material lookup returned; the final log was `OFFSCREEN preview texture binding begin`. No completion or bitmap draw was logged. This localizes the interruption to Material.set_resource but does not yet establish its cause. That call is disabled pending game-specific signature/handle verification. A bridge that becomes available after MDL startup is now detected without requiring a manual reload.

## Null material identified

Read-only inspection of the current Material.set_resource wrapper confirms argument order (material, slot, resource). Its native implementation immediately reads material + 0x18 without a null guard. Gui.material can return a null light userdata when lookup fails; Lua treats that value as truthy. The guarded live diagnostic reported material=0x0 and a nonzero render-target pointer. Thus assert(Gui.material(...)) was insufficient and the previous setter call had a null first argument. An explicit native-pointer guard now rejects it before any setter call. The setter remains disabled even for nonnull values pending successful lookup and further validation. No image or depth result is claimed.

## Material comparison in the same live GUI

A bounded lookup-only comparison returned a null pointer for core/performance_hud/gui, while content/ui/shared/material/gui_fill and content/ui/shared/material/gui_white_alpha returned distinct nonzero pointers. All three passed Application.can_get. Therefore can_get is not sufficient evidence that this GUI can instantiate the requested material. The GUI can return valid material instances; the failure is specific to the performance-HUD candidate. Neither working candidate has yet been verified to accept the render target or the assumed diffuse_map slot. No texture setter was invoked. Next: verify the texture-sampling shader and slot for an instantiable GUI material before binding the offscreen target.

## Native image material binding succeeds

The catalog identifies content/ui/shared/material/gui_diffuse_map. Read-only extraction found its 160-byte material payload in base archive 007e093ca718ca1a, with diffuse_map slot hash 3aa8b87e and shader identifier ba25de35. A lookup in the same live preview GUI returned a nonzero pointer. After both material and target pointer checks, Material.set_resource(material, 'diffuse_map', target) returned, followed by Gui.bitmap returning and the preview-placement log. The game process remained responsive. Actual four-color image visibility is awaiting user observation; successful API calls alone do not confirm rendered pixels or depth.

## Preview world placement

The user saw neither the bound image nor independent magenta/white rectangle controls. Inspection found that the working screen HUD selects a non-main world, whereas the preview used Application.main_world. The preview now uses the HUD selection pattern while explicitly excluding its private offscreen world. The live log confirms HUD-world selection and completed drawing. Visual confirmation is pending. This distinguishes compositor placement from offscreen image content.

The user confirmed magenta and white control squares after the world change, but no four-color image; the larger sampled bitmap appears white. Placement is therefore verified while texture contents remain unverified. A single World.update(private_world, 0) now runs from the managed update callback before the first render submission. The live log confirms the update and render returned; this is not proof that it corrected the image. The offline contract enforces update-before-render ordering.

## Bitmap argument parser mismatch

The screenshot showed the 200-pixel magenta control at its requested position, a 48-pixel white marker, and a separate white shape clipped against the origin. Read-only inspection of Gui.bitmap's argument parser showed that in the normal GUI path the optional material argument accepts a string or a tagged IdString64, not an untagged Material pointer. Passing the pointer leaves the argument index unchanged; subsequent position and size parsing reads the wrong arguments and can retain the default 100-by-100 dimensions. The preview now binds the resource via the checked Material pointer but draws by the material resource name, allowing the GUI's material cache to resolve that instance. The test is moved above/right of the native player HUD to avoid overlap. Visual verification is pending.

## Four-color image visually confirmed

The user confirmed seeing the four-color square after switching Gui.bitmap from the raw Material pointer to the resource name. This verifies the private GUI render, render-target binding, native image material sampling, and HUD-world display together. It does not verify scene-mesh rendering, depth testing, or frosted transparency. This is the working texture-pipeline checkpoint.

## Live panel texture preview

The confirmed four-color checkpoint is preserved in Git and evidence/offscreen-four-color-confirmed.png. The next diagnostic feeds the current weapon model through the existing layout and BigBlue rectangle renderer into a 512x256 target. It refreshes at 10 Hz, updates only the private world, and submits rendering only through the startup bridge. The screen-space preview uses the verified named material. Offline coverage checks throttled redraw and render ordering. Live process remains responsive; visual panel content and updates await user confirmation. Scene-mesh attachment and occlusion are still unverified.

The user confirmed that the actual ammo panel appears in the texture preview and updates while firing or switching weapons. The next diagnostic checks existing plane unit availability and mesh counts in the private world only; it does not attach a mesh to the gameplay world or assign scene materials.

## First scene-mesh carrier test

content/art_shared/meshes/plane_primitive is loaded and spawned in the private world with one mesh, one material slot, and a nonzero material pointer. Base asset inspection finds material 29ddde373c760d73 with color_map and emissive_map inputs. The scene carrier uses that existing plane in the main world, binds the live panel texture to those two verified inputs, and follows the damped weapon pose. Live logs reached `SCENE plane texture bound`; the process remains responsive. Visibility, orientation, lighting, and depth occlusion await observation. The screen preview remains a reference. Cleanup destroys the scene unit before the offscreen texture. Offline tests cover binding once, pose-loss retirement and null-material rejection; 42 tests pass.

## Scene-panel occlusion visually confirmed

The user confirmed seeing the new scene-mesh panel and confirmed that an intervening wall or character hides it. This is the first visually confirmed occlusion result for the project. The exact occluder was not separately identified in the response, so independent wall and character checks are still useful. This establishes a working scene-mesh route for the live panel texture. It does not establish frosted transparency, final orientation/scale, all camera modes, or long-session stability.

### Correction and material switches

The user clarified that the scene plane is occluded but blank: live ammo pixels were confirmed only in the screen preview. The earlier milestone wording overstated scene-texture visibility. The plane also lies flat. Its decoded material settings have use_color_map=0, use_emissive_map=0, emissive_intensity=0, emissive=(0,0,0), base_color=(0.431,0.431,0.431), and uv_scale=(1,1). The test now enables the verified map switches, sets emissive intensity to 1 and white multipliers, and rotates the carrier 90 degrees around local X. Visual results remain pending.

## Facing correction

The user identified the upright plane as facing the wrong direction. The local-X quarter-turn is now reversed to expose the opposite face. During the scene test, the original screen/world-GUI panel is hidden only while a weapon pose and offscreen texture are available; the separate texture preview remains visible. This diagnostic visibility change does not edit saved user tuning. All 42 offline tests pass. Scene-texture legibility still awaits visual confirmation.

## Scene image confirmed; content fit corrected

After reversing the upright facing, the user confirmed ammo pixels on the scene plane, but reported the image compressed into one corner and a black panel. The source renderer had placed natural panel bounds into only part of the fixed 512x256 canvas. It now maps the measured frame across the full canvas and carries its aspect ratio into the scene plane scale, preserving the displayed panel proportions. The existing scene material remains opaque: transparent texels do not make the mesh transparent. No frost or alpha-blending success is claimed.


## Content-sized target and transparent carrier trial

The user preferred resizing the texture over stretching the counter. The target now uses the measured natural panel bounds, recreating the scene carrier and target when those bounds change. Source glyph geometry is not stretched; the scene aspect ratio follows the target. Offline coverage checks layout-driven resize detection. Supersampling was discussed but is not enabled.

The native placeholder_red_transparent material is loaded in the current session. Asset inspection identifies the standard_transparent base, color_map/emissive_map inputs, opacity, and use_opacity_map. The glass candidates instead use packed normal/roughness/opacity textures and are not suitable substitutes for the panel image. The plane asset slot hashes to the name material. The trial assigns the loaded transparent material through Unit.set_material, obtains and validates its resulting instance, binds both panel texture inputs, and enables opacity-map sampling with opacity 1. This preserves source alpha rather than uniformly fading the text. Actual transparency and retained scene occlusion require visual verification; frosted blur remains unresolved. The previous opaque material remains the fallback when the transparent resource or setter is unavailable.


## Transparent scene panel visually confirmed

The user confirmed that the scene panel has a see-through background and is still hidden by character or scenery after the transparent-material trial. This establishes live panel imagery, alpha transparency, weapon following, and scene occlusion together for the tested session. Frosted blur remains unimplemented. The carrier uses the measured texture width/height ratio: its local X width stays fixed and its local Z height is width divided by that ratio. A rectangular content texture therefore produces a rectangular plane, not an enforced square.


### Aspect-axis correction

The user reported continued squishing. Decoding the primitive unit shows a square XZ mesh, attached to transform index 2 with an internal 90-degree X rotation. Its root-space surface is therefore XY. The earlier root-Z scale correction affected the normal rather than visible height; the preceding aspect claim was incorrect. The carrier now scales root Y by inverse texture aspect and keeps root Z unchanged. An offline regression check enforces the resulting 2:1 root-space extent ratio. Live visual verification remains required.


## Emission and heat-cell spacing

The user confirmed the corrected aspect ratio. Scene emission now defaults to 3, with a live 0-10 menu slider and Lua tuning setting. Material intensity updates only when changed. The user then reported uneven heat-bar gaps: at source scale 2 the old heat geometry used a fractional 4.7-pixel pitch and 3.5-pixel height. BigBlue now uses a 5-pixel pitch and 4-pixel full-cell height at that scale. Partial heat fill remains continuous. All 42 contracts pass. Visual brightness and spacing confirmation remain pending; perspective minification may still alias.


## Four-times texture density

The user confirmed even heat-bar spacing and requested much sharper texture rendering. Live panel render targets now use four times the natural width and height (sixteen times the pixels), with all source geometry uniformly scaled. Scene aspect and physical size are unchanged; the screen reference also retains its former display size. The allocation limit remains 2048 per axis. Tests verify scaled source geometry and resize detection. In-game sharpness, filtering, and bloom remain visual checks.


## Back-facing carrier

The user confirmed the supersampled panel is sharp. A second carrier now shares the same render target, with root X and Z axes reversed (180 degrees about panel up). This exposes an outward front face on each side with readable rather than mirrored text, preserving proper rotation, alpha material and depth behavior. Both units retire before the render target. Tests verify opposite facing, shared up direction, both bindings and idempotent cleanup. Live rear-face appearance remains to be checked.


The user confirmed rear visibility and requested mirrored rear text instead of independently readable text. The rear material now uses uv_scale (-1,1) and uv_offset (1,0), horizontally reversing the shared image. Geometry facing remains unchanged. Offline checks validate the UV settings; live appearance awaits confirmation.
