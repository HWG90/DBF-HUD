# Native Hack test

The debug-font comparison was visually confirmed to draw and occlude with the cloned material. Hack glyph rendering is not yet verified.

1. Disable older native-font depth and shader-loader-control test packages in Arsenal. Keep the withdrawn WorldGUI Depth State Test disabled.
2. Import `releases/DBF-HUD-Native-Hack-Test-0.1.zip`, enable its Native Hack test option, deploy, and restart Helldivers 2.
3. Install the separate `releases/DBF-HUD-Native-Font-Probe-MDL-0.1.zip` as a loose MDL mod, then enable DBF-HUD Native Font Probe. The installed development probe is already updated.
4. With a weapon equipped, the cyan sample should read HACK 0123456789 using Hack Regular. The yellow ORIGINAL sample uses the game's debug font.
5. Check letter shapes, digit spacing, missing glyphs, scale, and cyan occlusion behind scenery. Neither the main HUD nor its font selection is changed by this test.
6. Disable the probe to remove the comparison text. Disable the asset package and redeploy/restart to unload the experiment.

This first package preserves the native template's 193-character lookup order. Full Nerd symbol coverage and final HUD integration remain outstanding. Native header fields not established by this comparison retain their original template values. The atlas and metrics are draft artifacts generated from the original HackNerdFont-Regular.ttf; the recorded SHA256 matches its existing import record. The material uses the verified font-depth shader; texture and metrics still require live validation.

Rebuild assets with `python tools/build_native_font_depth.py --depth-probe`, then `python tools/build_native_hack.py`. These build packages, not deployment. The main HUD remains at the prior 69-check checkpoint.
