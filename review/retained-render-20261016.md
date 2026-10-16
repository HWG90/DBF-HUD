# Retained Split renderer experiment, 16 October 2026

Status: experimental, disabled by default. The established HUD Texture renderer remains active. This is not a fidelity-preserving performance fix and is not ready for promotion.

The experiment reuses the existing offscreen UI viewport and four separate consumers for Split's main, reserve, context, and status planes. Content is composed only when it changes; weapon attachment updates every frame. Session-only modes are `screen_texture`, `worldgui`, and `mesh`, selected with `DBFHUD.set_retained_mode`. Trials automatically return to the ordinary renderer after 90 seconds by default (300 seconds maximum). No saved placement or appearance changes.

The render-bridge callback's CPU time is added to HUD profiling and the timing overlay. These measurements still do not measure GPU execution. They must not be interpreted as total rendering cost.

## Live results

Same running game, Adjudicator, normal visible HUD frames. Three approximately ten-second windows per comparison. Rates are milliseconds of CPU work per wall-clock second, not milliseconds per frame.

| Route | Total CPU ms/s | Draw CPU ms/s | Result |
|---|---:|---:|---|
| Established HUD Texture | 73.685, 70.539, 67.805 | 35.831, 35.220, 33.759 | Accepted route; restored after trials |
| Cached planes through HUD Texture | 60.124, 57.799, 63.198 | 22.583, 20.883, 22.832 | Visible; user confirmed steady while moving/firing; darker output; user reported worse perceived performance |
| Persistent WorldGUI | 41.228, 42.325, 48.724 | 5.214, 5.233, 9.415 | Initially steady, then user reported whole-cluster flicker; disabled |

The three WorldGUI windows contained 0, 4, and 23 surface recompositions respectively. Mostly unchanged content is favorable to this experiment. It does not establish the under-50-ms/s target during combat, and the flicker and color differences fail the fidelity requirement regardless of CPU savings.

An actual mesh trial rendered the cached artwork during movement, with the known lit transparent material. One window with 132 recompositions measured 79.058 total and 36.744 draw ms/s. A subsequent window was incomplete and another had no visible frames; neither is a valid target measurement. The mesh trial also exposed incorrect node-scale update ordering. The carrier now follows the established implementation: set pose, then restore authored scale every frame. That correction is tested offline but has not been live-validated. The earlier mesh numbers are diagnostic only, not a valid comparison at the intended size.

## Fidelity and material gates

1. Offscreen composition darkens translucent colors/labels. The known viewport clears its target before each composition. Ordinary straight-alpha receiver materials can multiply premultiplied color a second time; exact target alpha and color-space behavior still require a direct-versus-cached fractional-alpha comparison. No speculative gamma correction is applied.
2. The same cached textures were steady through the existing HUD Texture placement but flickered through persistent WorldGUI. This isolates a carrier-dependent problem; it does not prove a specific native engine defect.
3. The existing mesh material is lit and does not preserve the approved colors. The old `fullbright_depth_image` shader is GUI-derived and requires vertex COLOR, which the plane mesh does not supply. It must not be assigned blindly to that mesh.
4. The transparent mesh base contains multiple compiled passes and auxiliary render targets. A simple RGBA pixel-shader replacement would break their contracts. A production mesh material needs a verified mesh-compatible fullbright pass, correct transparency, and scene-depth behavior.
5. Surface refresh currently rebuilds the plane's GUI content and its signature. Active-content cost and game frame times must improve before further adoption. Static Lua measurements alone are insufficient.

## Validation and rollback

Offline suites cover retained geometry, exact atlas/font mappings, numeric tint/alpha, animations, callable engine constructors, native pointer guards, four depth planes, placement-scale changes, failed-render recovery, and consumer-before-target destruction. The mesh test double resets scale on every pose update so the observed scaling error cannot recur unnoticed.

Source changes are opt-in only. The existing Arsenal entry receives the normal source-built Startup/LiveBridge payloads; no native asset or game-folder replacement is required for this disabled prototype. Local diagnostic captures, timings, and deployment receipts are under `dist/mesh-render-audit-20261016` and are not release artwork. No claim is made that this experiment meets the performance target or preserves fidelity.
