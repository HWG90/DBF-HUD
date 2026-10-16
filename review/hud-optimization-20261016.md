# Split CPU optimization pass — 16 October 2026

Status: source built, deployed through the existing Arsenal entry, and restarted on 16 October. Settings/projection changes have been sampled in the running game. The new label textures still need visible combat samples and a filtering comparison. The under-50-ms/s target is not yet established.

## Changes

- Fixed Split labels use a bounded atlas copied from the existing Hack and BigBlue font pixels. There are 164 labels per font. Other fonts, changing headings, numeric readouts, and unsupported strings retain native glyph rendering. The gold chamber digit is unchanged.
- Labels use the established HUD Texture material, scene depth, weapon attachment, tint, and opacity. There are no offscreen render targets, runtime text uploads, or new shaders. Existing shader slots take priority within the 24-image budget. Missing label assets fall back to native glyphs.
- The render settings cache reuses its working tables while detecting scalar, per-weapon, and nested shader edits on the next frame. It clears frame-only fields before reuse and leaves public menu/edit settings independent.
- Native projection still checks every camera owner immediately before each corner call. Fresh identity bytes are compared directly instead of repeatedly decoding the same pointers. Immutable planar coefficients and CPU projection constants are captured once per snapshot.

A compiled native batch projection helper was not introduced. This source has no packaged native batching component; these changes reduce repeated work within the existing guarded projection route. The four discontiguous ownership reads and snapshot tearing checks remain intact.

## Evidence

All rates below are CPU milliseconds per wall-clock second, not milliseconds per game frame. These are visible Adjudicator windows in the same game session; changing frame rate limits the direct rate comparison.

| Build | Visible FPS | Total CPU ms/s | Draw CPU ms/s | Total CPU ms/frame |
| --- | ---: | ---: | ---: | ---: |
| Before | 89.8–100.7 | 75.321–81.885 | 34.350–40.170 | 0.748–0.878 |
| Settings/projection, settled | 107.5–109.6 | 69.143–74.875 | 32.280–34.396 | 0.635–0.683 |

One earlier 49.743-ms/s reading included only 6.66 seconds of visible draws in a 10.51-second window. It is excluded. A zero-draw window is also excluded. The sampler now requires at least 90% visible-time coverage.

After the user's Arsenal deployment and restart, all nine staged files still matched the accepted receipt. Read-only hashes of the deployed native Assets body and GPU file matched the staged payload. The new game process started at 14:17 local time, and its Lua environment contains the new Hack label resource metadata. A game capture at 14:21 showed the ship; repeated status reads through 14:25 reported `no selected weapon`, no texture route, and zero prepared labels. These checks establish deployment, not label visibility or performance. No combat timing result was accepted from that interval.

The label comparison sampler also requires an unchanged HUD instance, weapon, view, active profiler, and prepared-label count. It clears its profiler even when the runtime resets a sample after a hidden frame. `native_label_count` counts prepared commands rather than visible submissions, so capture and valid visible timing coverage remain required.

Offline production-renderer integration proves that `RELOADING` changes from 18 glyph submissions to two textured triangles, with full-rate camera movement, scene-depth parameters, alpha, and missing-asset fallback. Source glyph pixels and native-em bounds match. Projected texture filtering still needs visual comparison in game.

Passed suites: native labels, production label scene, render settings cache, native projection guards, native planar projection, native screen scene, Split HUD, Split spatial, and global texture-off behavior. Complete startup and modular packages compile. The label artifact and merged HUD/War Journalist resources pass verification.

The shared shader closure remains `56fded63f8695a60a8426faf50cb8a266b9918f3e37c99a5a6bdd974764efba6`: 245 libraries, 322 registered IDs, 77 stock IDs. Both load orders pass. War Journalist's payload does not need replacement for this texture-only addition.

## Deployment and rollback

The source-built Complete package is `dist/releases/shader-coexistence/DBF-HUD-Complete-0.3.42.zip`; modular source is `dist/releases/modular-20261010/dbf_hud-0.3.42-LLL-Modular.zip`. Updated runtime and Assets files are staged in the existing `DBF-HUD-Complete-0.3.42_AR388795` Arsenal entry. Modular source is installed in the existing LLL mod directory. No game-folder or saved-setting edits were made.

Local preimage hashes, backups, capture, timing windows, and deployment receipts are under `dist/perf-pass-20261016`. The experimental retained WorldGUI/mesh renderer remains off. For a same-session label comparison, `DBFHUD.config.native_label_sprites=false` selects the original glyph path; restore the prior value after testing. This diagnostic is not serialized as a user setting. The live screen scene exposes `native_label_count` to confirm that a measurement actually uses the label textures.
