Current authoritative state: [2026-10-03 session checkpoint](docs/SESSION-20261003.md). Entries below are chronological; later approved decisions supersede earlier candidates. The alternate Senator cylinder is local-only and excluded from the current public tree.

Double Freedom visual target: the user-selected rear-facing breech reference posted 2026-10-03. Loaded brass shell heads and primers, dark empty bores, steel housing, reserves and a separate functional SEMI/VOLLEY child panel. DOOM is a major artistic inspiration: tactile industrial ammunition and readable instrumentation. The current primitive approximation is not visually accepted. Further art changes need actual game capture.

2026-10-03 implementation: tighter twin bore spacing, muted brass, receiver seams; installed build 20261003-BREECH-FINISH. Loaded SEMI composition reviewed in an actual game capture, with dense scanlines across main and child. 152 contracts passed. This remains an approximation of the reference and is not declared visually accepted. Automatic game capture washes out colors; injected F12 produced no new Steam file and injected fire click produced no observed shell transition. A user-triggered Steam screenshot and real one-fired/empty/volley transitions are still needed for full visual validation. Evidence: evidence/breech-finish-review-20261003.txt and evidence/double-freedom-loaded-live-20261003.png.

2026-10-03 latest direction: Double Freedom now follows Deadeye's ammo-first layout, thin silver frame and brass accents in the shared suite. Four native-font offline states are prepared in preview/double-freedom-deadeye-native.png. Candidate remains uninstalled pending visual approval. Fuel/gas rollback alone was installed as evidence/fuel-rollback-mod.lua; it bypasses catalog styling to recover the compact E/F gauge, preserving tracking, warning zones and Stoker bullet presentation. All other deployed bytes, including Double Freedom BREECH-FINISH, are identical to the prior installation. Live fuel appearance still requires game reload/review.

2026-10-03 preview revision: Double Freedom's two upright shells remain side by side; loaded shells are blue (65,145,235), empty/fired shells are dim silver. Shared frame, numeric ammo and SEMI/VOLLEY behavior preserved. Preview only; not deployed.

2026-10-03 latest preview revision: removed Double Freedom numeric loaded-ammo count at David's request. Two centered side-by-side blue shell symbols convey capacity; empty states remain dim. Reserve count and SEMI/VOLLEY preserved. Preview: preview/double-freedom-blue-shells-no-counter.png. Still uninstalled.

2026-10-03 color clarification: loaded shell hulls are blue; bases/rims are brass. Empty shells remain dim silver. No loaded-ammo number; reserves and SEMI/VOLLEY retained. Revised preview: preview/double-freedom-blue-hulls-brass-bases.png. Candidate remains uninstalled.

2026-10-03 alignment revision: each shell is centered above its own capacity line (centers x40 and x106). Blue hull/brass base treatment and all behavior preserved; preview only, uninstalled.

2026-10-03 live fuel acceptance: David confirmed, 'In-game appearance is good for the fuel-based weapons.' Compact fuel/gas rollback is visually accepted and complete. No further fuel work pending. Double Freedom remains a separate uninstalled preview, with each blue-hull/brass-base shell centered over its capacity line.

2026-10-03 shell fidelity revision: filled blue hulls, beveled shoulders, restrained edge highlights/grooves, and layered brass heads/rims. Dedicated DOUBLE_FREEDOM_SHELL icon leaves other weapon shells unchanged. Each shell uses 20 rectangles versus 10 before (+20 rectangles for the pair); compact panel remains below 120 commands. All 153 offline contracts pass. No live performance claim or deployment. Preview: preview/double-freedom-refined-shells.png.

2026-10-03 approved installation: build 20261003-DF-FLAT-CRIMP installed with flat loaded tops and opened spent crimps. Closed icon 20 rectangles; spent icon 24. Observed-shot status clears on reload/increase or ownership loss; physical ejection is not separately exposed. All 154 contracts pass; artifact/source verified; accepted fuel rollback and restored renderer preserved. Live Double Freedom rendering awaits reload/review.

Live load confirmation: automatic MDL reload produced the new 20261003-DF-FLAT-CRIMP build marker in DBF-HUD.log. No manual restart required. In-game Double Freedom visual acceptance remains pending.

2026-10-03 pixel-art preview: shell-only revision uses integer-grid silhouettes, block shading and a six-color blue/brass palette. Closed shell 14 rectangles (was 20), spent shell 17 (was 24); pair uses 12-14 fewer rectangles depending on firing state. Alignment/frame and shot/reload behavior unchanged. All 154 offline checks pass. Prepared preview/double-freedom-pixel-shells.png only; installed 20261003-DF-FLAT-CRIMP remains untouched pending preview approval.

2026-10-03 approved pixel-shell installation: 20261003-DF-PIXEL-SHELLS deployed and bytes verified against packaged source. Only fire_icons artwork module and build marker differ from prior deployed version. Automatic live reload confirmed: True. All 154 prior checks passed; fuel, renderer, layout and shot/reload behavior preserved. Visual/performance review in game remains pending.

2026-10-03 narrow live corrections installed: build 20261003-DF-STOCKY-SHELLS fixes weapon label gold against saved white text override, removes intrinsic main/child outer border and corner marks (decorations own borders), and widens shells 13.3% without height/center changes. No geometry added. All 154 checks pass; deployed bytes verified. Gauge size is David's visual intent, not an independently verified specification.

2026-10-03 named-suite proposal inventory: 79 named candidate IDs, 29 accepted/protected IDs, 40 deferred internal aliases. Five contact sheets and shared_suite.lua implementation are prepared. David briefly approved then explicitly revoked deployment before any game write. M.enabled=false; proposal remains gated. Installed artifact remains 20261003-DF-RIB-DETAIL, SHA256 c3589e0d990111a41e342122bfef653ef3d6d2ec2a27f2c07284a302be89e1be. Enhanced DF 16-bit hull detail and longer AC cartridge are separate uninstalled proposals.

2026-10-03 pending review artifacts: Double Freedom enhanced sprite hulls now have paired axial ribs, cylindrical block shading and separate reflective brass/rim bands, with close/normal-size comparison in preview/double-freedom-16bit-detail-comparison.png. Candidate icons use 32 closed / 37 spent rectangles versus installed 17 / 20 (+30 per loaded pair, +34 per spent pair). Compact panel remains under 120 commands; live cost unmeasured. Autocannon long-case proposal in preview/autocannon-long-case-proposal.png stretches the brass case and shifts the original projectile, preserving APHET/FLAK colors and source art; icon remains 16 rectangles, unchanged panel dimensions/counts/reserves/modes. Both remain UNINSTALLED. Full scope/state checks: 156 pass. Current live artifact verified unchanged at c3589e0d990111a41e342122bfef653ef3d6d2ec2a27f2c07284a302be89e1be, build 20261003-DF-RIB-DETAIL. Named suite remains disabled after revoked approval; proposals must be reviewed separately before future installation.

2026-10-03 David approved BOTH refined 16-bit Double Freedom shell detail and longer Autocannon case after viewing their previews. Installed isolated build 20261003-DF16-AC-LONG. Only fire_icons and munition_art modules changed; current labels/decorations/width/state behavior, fuel rollback and restored renderer retained. The 79-weapon family set is REJECTED: David said 'They all look the same.' Future family proposals need individual differentiation. shared_suite remains disabled and absent from installed payload. 156 checks pass; packaged/deployed bytes verified. Live visual/performance proof remains separate.


## 2026-10-03 reference proportions and authorized refinements
Use reliable user/in-game references for each ammunition silhouette and its case/projectile proportions. Do not reuse a generic ratio when evidence is missing; request the specific reference. Broad 79-weapon preview remains rejected and disabled.
Installed taller Double Freedom brass cups (+2 sprite rows) and overall shells (28 to 30 rows), retaining blue hull length, widths, centering, ribs and state tracking. Installed fixed Autocannon APHET/FLAK bounds and content anchors.
Recoilless full-detail proposal stays preview-only: approximately 5:1 loaded-round silhouette from user backpack/casing images, brown case and pointed ogive. Perspective estimate, not exact physical dimensions. Existing panel dimensions, loaded/empty tracking, reserves and modes retained.

Recoilless review revision: rotate the detailed reference geometry upright, projectile at top and base below. Uniform 0.56 fit preserves silhouette proportions in the existing bay (approximately 57 tall by 12 wide). Panel, text anchors, ammunition modes and reserves remain unchanged. Preview only; not installed.

Double Freedom requested title gap: title fixed; shell art y=34 to32 and capacity lines y=28 to26. This adds exactly two native layout pixels of title clearance while preserving shell-to-line alignment. Installed narrow layout-only update; Recoilless upright proposal remains uninstalled.

Approved upright Recoilless installed: detailed reference art is now the default; only the deployed recoilless_panel module changed. Double Freedom gap/taller brass, Autocannon fixed dimensions/long case, fuel rollback and renderer preserved. 158 offline contracts passed.

Pending Recoilless top-third revision: uniform 3x magnification clipped within existing bay, preserving round proportions and all text positions. Loaded-to-empty observation latches retained casing with projectile omitted; initial empty/ownership loss/weapon switch/reload clear latch. This denotes observed shot status, not physical retained-case telemetry. Preview only; deployed upright full-round artwork unchanged.
`nRecoilless close-up review: eased uniform zoom from 3x to 2.5x to expose more casing below the shoulder. Same bay, labels, aspect ratio and observed spent/reload behavior. Updated more-casing preview remains uninstalled; 159 offline contracts passed.

Corrected Recoilless crop: reference-sized projectile-to-visible-case split (~57% projectile/band, ~43% plain casing), uniform 1.9x framing. Colored band explicitly tagged projectile and omitted after observed firing. Plain restrained dark purplish case shading follows new spent-casing reference; actual rear rim remains outside the close-up crop. Preview only.

Reference correction: isolated purple spent casing was identified as potential Double Freedom context, not reliable Recoilless material evidence. Recoilless corrected proposal follows authoritative brown/plain small crop; no material transfer from shotgun image.

Approved corrected Recoilless crop installed: plain brown case, crop proportions, projectile-owned band omitted together with projectile on observed shot; reload restores full round. Narrow deployment changes panel and two runtime hook lines, adds observed-shot state module. Other deployed modules preserved. 159 offline checks passed.

Double Freedom reference-proportions proposal (not installed): newest comparison shot and prior spent-shell references support slimmer body and shorter brass fraction. Perspective estimates ~15�25% brass and ~3.5�4.5 overall length/width; proposed 20% brass, 45x12 native envelope (3.75:1), blue hull retains detail. Same total height, title clearance, centerlines, capacity lines and observed-shot behavior. Opt-in double_freedom_proportions_preview gate; 160 offline contracts passed.

Double Freedom review correction: first proportion proposal was too thin. Middle-width proposal widens 12 to16.8 native units (installed width22.2), preserving height45, 20% brass fraction and centers40/106. Feedback takes precedence over perspective estimate. Preview only; 160 offline checks passed.

Approved middle-width Double Freedom installed: 16.8x45 native shell envelope, 20% brass, longer ribbed blue hull. Same centers, title gap and shell state logic; layout-only deployment preserves other accepted modules. 160 offline checks passed.

Reusable Deadeye receiver decoration installed as optional existing-selector option (global and Equipped weapon appearance). Original silver perimeter .55 and four brass inset squares .75; final parent/child bounds; fixed original palette. Default/current selections preserved byte-for-byte in tuning. Intrinsic legacy Deadeye border/rivets skipped only when preset selected. Other accepted content unchanged.
Double Freedom tighter box installed: native BigBlue width150 to142; height100 retained to clear top corner accents and header. Shells retain16.8x45 dimensions, brass20%, moved left4 together with capacity lines/reserves/title; child box follows width. Font measurements reserve enough space for wider faces. 162 offline contracts passed; game loaded.

Double Freedom live correction: previous native width shrink was normalized back to240 by world_style.prepare; reserve text remained left-aligned because centering request had not been implemented. Installed stacked gold DBS-2 / DOUBLE FREEDOM, centered reserve glyphs plus center_in_frame for final world fitting, native120x112 BigBlue frame, unchanged16.8x45 shell dimensions/66 center spacing and lower header clearance. Capacity lines shortened symmetrically42wide; reserve and mode centered. DF-only world_reference_width preserves prior glyph/art scale while allowing actual narrower display (~199.54 vs240 in tested world path). Other panel scales unchanged. 163 offline tests, including all-font/count centering at native/final-world bounds.

Authorized Double Freedom wide/close refinement installed: widen complete shell art to42 native units matching unchanged42-wide capacity segments; shorten center spacing66 to50 and clear segment/rim gap24 to8. Symmetric pair moves with lines, height45 unchanged, brass20%, stacked gold labels/reserve/mode centering and actual narrow world display retained. Loaded/spent/reload checks and exact line/art span equivalence pass in native and final world coordinates. 164 offline contracts passed; layout-only deployment.

Latest explicit correction supersedes line-fill width: installed shell width halved42 to21, with height45 unchanged and complete blue/brass/rim/crimp/rib horizontal geometry scaled together. Each remains centered over its unchanged42-wide line; eight-unit central line gap, panel, stacked gold title, reserves/mode centering and state behavior unchanged. 164 offline checks passed; layout-only deployment.

Double Freedom slightly realistic fidelity proposal (preview only): preview/df_realistic_icons.lua overrides only the two shell icons for review. Broad cylindrical blue reflections, restrained paired ribs, brass cup/rim reflections, rolled closed cap and dark open mouth/crimp petals. Same21x45 envelope and half-line centered placement; no real-world proportion changes. Native rectangles loaded32 to42, spent37 to47: +20 commands per two-shell pair. Static shading, no texture/shader/render-backend change; no live performance claim. Preview geometry/native-world/state/content-preservation checks passed. Installed art unchanged.

Approved slightly realistic Double Freedom shell art installed: cylindrical blue shading, subtle ribs, brass reflections and open/closed crimps. Native21x45 envelope, unchanged lines/gap/header/reserve/mode/decorations/state behavior. Only fire_icons deployed module changed; 164 offline contracts passed. Loaded42 and spent47 rectangles per shell, +20 per pair; live performance untested.


## Canonical artwork direction - approved 2026-10-03
David explicitly selects the installed realistic Double Freedom shells as the visual reference for future artwork: the specific pixel definition, shading and sense of depth are the target.

Reference: preview/double-freedom-realistic-detail-proposal.png. Approved implementation: src/fire_icons.lua, DOUBLE_FREEDOM_SHELL and DOUBLE_FREEDOM_SPENT. Deployment evidence: evidence/df-realistic-approved-deployment.json; build 20261003-DF-REALISTIC.

Keep crisp pixel edges with nuanced cylindrical or shape-appropriate shading, darker edges and restrained reflections that give volume. Use subtle structural detail such as ribs, believable material-specific metallic highlights, and clearly readable closed/open or loaded/spent silhouettes. Preserve readability at the actual compact HUD size; enlarged previews supplement native-size review. Prefer efficient supported native artwork and record drawing-element costs; do not infer live performance from offline checks.

Transfer this craftsmanship, not the same silhouette or dimensions, to future assets. Ground each ammunition type's proportions, components and material identity in reliable user/in-game references. When a needed shape or ratio is unknown, ask David for the specific reference instead of inventing measurements. Respect component ownership in state transitions (for example, the Recoilless colored band belongs to its projectile). The rejected 79-weapon set remains disabled; its interchangeable-looking artwork is not a reference.

This adoption requests guidance only. No additional artwork changes, deployments or global memory updates.

Senator chosen proposal: six upright cartridges, projectile omitted after observed decrease, previously observed case retained; count increases replenish. Preview-only state module validated across firing-to-empty, individual refills, full refill and ownership/weapon reset. Display slot order is not physical cylinder telemetry. Current reader exposes counts/capacity/reserves and controls, not verified speedloader or ejection/reload-phase signals; falling-case animation pending real signal. Artwork blocked on explicit loaded-round versus spent-case boundary/proportion reference, rather than reuse invented case24/neck2/tip8 profile. No Senator deployment.

Senator upright proposal reference now supplied: six long brass cartridges with small rounded noses and a visible seam. Native silhouette10x44 (~4.4:1) with 8-unit projectile (~18%), interpreted from visual reference rather than measured game dimensions. Six tips replace redundant loaded number; reserve/mode centered. All-font/three-scale/state/geometry checks pass. Speedloader/ejection animation remains pending verified signal. New rear-cylinder reference and bottom firing chamber recorded for later option; current row unchanged. Preview only.

Approved Senator six-upright-round design installed. Observed ammo decreases remove projectiles while known cases remain; increases restore loaded rounds, ownership/weapon loss resets retained-case state. Six tips replace numeric count; reserve/mode centered. Unsupported speedloader/ejection remains pending. Narrow deployment adds senator_state/senator_panel, layout selection and two runtime hooks, preserves other modules and tuning. 165 offline contracts passed; live appearance/state review pending.

### Senator upper-round close-up preview
Preview only: `preview/senator-larger-closeup-proposal.png`. Uniform 1.6x art enlargement with lower casing cropped to y32..80; six distinct rounds at 18-unit pitch. Native body width 8 -> 12.8. Frame and labels unchanged. 1080 font/scale/state combinations passed; final world art width remains exactly 1.6x. Installed Senator payload unchanged. Speedloader/ejection remains pending verified signals.

Approved close-up installed: only senator_panel changed; 165 contract checks passed; ZIP and deployed bytes verified; tuning preserved; automatic game reload confirmed by SENATOR-CLOSEUP marker. Visual acceptance in game still requires user check.

### Publication scope correction
The alternate Senator cylinder is local-only. Its source and previews were removed from the current public tree by a normal corrective commit; they remain in earlier Git history. Public source retains the approved upright Senator.
