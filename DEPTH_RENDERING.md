# World GUI depth investigation

## 0.3.23 world frost fallback

The 0.3.22 screenshot shows a white world panel with black background_color, zero panel_opacity, overall opacity 1 and frosted enabled. Hybrid blur was confirmed working. This isolates the visible white background to the world frost draw; it does not identify the underlying render-resource failure. 0.3.23 omits native frost in world mode and retains transparent tint at the requested alpha. Hybrid rendering and saved frost preferences remain unchanged. This is a readability fallback, not successful world-space blur or depth occlusion. All 39 offline contracts pass, including no world frost bitmap and zero-alpha tint; installed to MDL live for reload.

## 0.3.22 native background comparison

The user confirmed blur remains visible in Weapon (hybrid) mode. Native frost availability alone does not establish compatibility with a world-space GUI. 0.3.22 corrects the previous coupling of frost alpha to panel tint: frost now follows overall visibility/opacity, independently of panel tint. The world background tint uses native Gui.rect, matching the hybrid path; experimental depth fill remains only on foreground primitives. This isolates the background from the depth material. All 39 tests pass, including zero tint with nonzero frost. Installed to MDL live without editing user tuning. World-space blur and depth occlusion remain unverified.

## 0.3.21 frost and opacity correction

0.3.20 logged distinct addresses for the returned material handles; shader selection and depth behavior remain unresolved. The user clarified that the changed appearance in their screenshot followed their own settings adjustments, not a visual change from the diagnostic release. The screenshot alone does not establish shader corruption.

Code inspection found the world frost layer always submitted alpha 255, while the tint used configured opacity; disabling frost also forced the tint opaque. 0.3.21 passes panel alpha to both layers and preserves tint alpha without frost. It restores the original native gui_blur instead of the experimental depth_blur to remove that variable. The experimental solid fill remains selected when available. All 39 contracts pass, including added checks for native frost selection, matching alpha, and translucent tint with frost disabled. Installed to MDL live; user tuning is untouched. Visual correctness and occlusion require live verification.

## 0.3.20 diagnostic correction

The 0.3.19 live reload succeeded; all three Gui.material calls returned handles. However, engine __tostring emits only [Material], [Gui], and [World], so that diagnostic did not identify object addresses or shader selection. 0.3.20 adds protected LuaJIT string.format('%p', handle) logging. This was verified offline using the installed LuaJIT DLL and userdata with the same generic __tostring behavior. These are Lua userdata addresses, not yet verified native object pointers. No direct dereference is added to the HUD. All 39 contracts pass; the corrected live diagnostic is installed and awaits reload.

## Current status: 0.3.19 diagnostic

The user reports no occlusion with either 0.3.17 or 0.3.18, including against solid scenery. Material availability and explicit bitmap submission therefore have not demonstrated working depth testing. The older sections below record the experiments, not a confirmed fix.

Read-only inspection located the current build's Gui API at ScriptAPI + 0xD0. The public SDK's table placement differs and must not be used as an exact offset map. No native functions were invoked through these addresses and no process memory was changed.

0.3.19 adds one-time logging of the engine-returned world GUI and the material instances returned by Gui.material for available fill/depth assets. This supplies targets for bounded read-only inspection; it does not change shaders, geometry, smoothing, or render state. Getter availability is checked and Lua lookup errors are isolated. Native material handles are not retained. All 39 existing offline contracts pass. Live reload and instance results remain pending.

The user confirmed that the world-space rectangle renders over the character. World GUI placement alone therefore does not supply the requested occlusion on this path.

## Verified evidence

- Autodesk documents depth testing as a UI shader output option. Gui.rect accepts an optional material argument, so a suitable material could be assigned without replacing the world-GUI geometry.
- The installed gui_fill material was extracted read-only from the game archives. Its shader identifier at offset 0x80 is 0x9FCFE126, matching the upper 32 bits of the resource hash for gui, the plain variant.
- The extracted core/performance_hud/gui material identifies gui:DIFFUSE_MAP; this is not a depth-enabled candidate.
- The Filediver resource-name catalog includes both uppercase and lowercase depth-enabled GUI shader variant names. Catalog entries do not prove the corresponding shader program is present or loaded in this game build.
- A search of base archive material payloads up to 2048 bytes did not find the six tested depth-enabled GUI shader identifiers. This is not proof that all depth-tested materials are absent: larger payloads, other shader families, patched resources, and different variant identifiers were not covered.
- No new material or memory patch was deployed. The working world-GUI rectangle is unchanged.

## Next technical requirement

Locate a GUI-compatible depth-tested shader program in the current build before constructing an isolated DBF-HUD material. Do not change the shared native gui_fill material: other HUDs use it. Do not infer that changing a shader-name hash alone produces a valid compiled material. If a new material asset is necessary, it will require normal asset deployment; MDL reload alone only replaces Lua.

## References

- [Autodesk GUI API: optional materials](https://help.autodesk.com/cloudhelp/ENU/Stingray-Help/lua_ref/obj_stingray_Gui.html)
- [Autodesk shader output: UI depth testing](https://help.autodesk.com/cloudhelp/ENU/Stingray-Help/shaders_ref/cat_Output.html)

## Installed shader evidence and isolated test package

Further archive inspection found shader_library resources for gui:depth_test_enabled and gui:depth_test_enabled:blur_background in archive ee6b1ba7e22d71ed. Their GPU payloads are 14576 and 15792 bytes respectively, each containing two DXBC blocks. The corresponding plain variants have matching payload sizes. The solid depth library identifies the uppercase compiled variant 0xD78AB313; the blur depth library identifies 0x63009884. Resource lookup names use lowercase flags, while these compiled identifiers use uppercase flags; they must not be interchanged.

DBF-HUD-Depth-Materials-0.1.zip adds only two materials with unique DBF-HUD paths. The 144-byte native gui_fill and gui_blur payloads were cloned, changing only the shader identifier at byte 128 to the verified compiled identifiers. This is an experimental material reference change, not new shader compilation. It does not modify a shared game resource. Material compatibility, shader loading and visual depth behavior remain to be confirmed in game.

Live 0.3.17 checks availability before selecting the DBF-HUD material. It supplies the solid depth material to panel tint, bars, accents and pixel-font rectangles, and selects the depth blur material when available. The world panel uses BigBlue glyph rectangles so text cannot retain a separate overlay-only font material. If the depth blur is unavailable, the panel becomes opaque; if both assets are missing, the previous material path remains active and the log reports the missing addon.

### Installation for the live test

1. Import DBF-HUD-Depth-Materials-0.1.zip into Arsenal, enable it, and deploy.
2. Keep the packaged DBF-HUD HUD disabled. The new package contains materials only and does not start a second HUD.
3. Restart the game and enable DBF-HUD (Live) in MDL. Its updated Lua is already installed.
4. In 3D plane mode, turn so the panel crosses the shoulder. Verify that the background, digits and heat bar all disappear behind it. Also check the panel against scenery.

All 39 offline contracts pass, including propagation of the material to glyph primitives. No claim of successful live occlusion has been made yet.

## 0.3.18 explicit-material draw test

User reports that 0.3.17 draws through both character and scenery. The live log confirms the isolated solid material is available. This does not confirm the optional material argument on Gui.rect is honored by this game binding. The next test draws all solid primitives with Gui.bitmap, whose material argument is required and already used by the frost path. Existing assets are unchanged. This is an isolation test, not a claimed depth fix. All 39 offline checks pass, with a test that rejects any default rectangle call while a depth material is active.
