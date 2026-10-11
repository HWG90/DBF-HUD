# Primary HUD design exploration

Scope chosen by David on 2026-10-10: primaries first. Explore a fresh visual style and information layout; preserve the current HUD as a fallback.

## First study

`dist/primary-design-study-01/index.html` compares three fresh Liberator sketches: Receiver, Open, and Dial. They use the same illustrative state and allow ready, low, empty, unknown, firing, reload, and fire-mode changes. Sample capacity and reserves are not weapon defaults. `contact.png` is a static comparison.

The comparison is about visual direction and readout hierarchy. It does not establish mounting, perspective, occlusion, readability in combat, performance, or native renderer feasibility. David liked Receiver and Open; Dial was unusual but not rejected. He then selected Open with variable background translucency. Nothing is installed by these studies.

## Selected direction: Open

`dist/primary-design-study-02/index.html` adds a 0-100% background-translucency control: 0% is solid backing and 100% removes the backing. Foreground text, brackets, and gauge clarity remain independent. Its 75% initial value is a preview choice, not an approved runtime default. The ready display omits the redundant ROUNDS caption and reserves that space for LOW AMMO, EMPTY, or NO DATA. The backing has no intrinsic frame.

The preview compares fixed translucency examples and provides compact low/empty examples. Readings remain illustrative; native capacities and reserve units still come from the reader. Preserve Receiver and Dial as alternatives while developing the selected Open direction.

## Vertical candidate

At David's request, `dist/primary-design-study-03/index.html` explores a vertical Open arrangement: loaded count, secondary capacity, remaining-load gauge, reserve/unit, then mode. The background-translucency control remains independent of the foreground. LOW AMMO, EMPTY, and NO DATA use the space between the gauge and reserve. The horizontal Open study is preserved; the vertical orientation has not been selected or installed.

David then asked for a more rigid, seven-segment, Helldivers-oriented feel: the soft version looked like text floating in a box. `dist/primary-design-study-04/index.html` addresses this with beveled polygon digits, fixed digit cells and dim leading zeros, alignment rails, fixed capacity/reserve bands, and a mode indicator bank. The palette uses warm white, olive, and yellow accents; the backing remains independently adjustable. This refinement is still a review candidate. Preserve the earlier studies.

David approved the segmented design, then specified that it is for **Fancy only**, with **white, gold, and navy blue** as the theme. Empty loaded ammunition must be red. UI elements need contrast strokes for translucent backing. `dist/primary-design-study-05/index.html` applies that requested theme and outlines while retaining the approved geometry. Low ammunition uses gold; confirmed empty uses red; unknown readings remain dashes. Simple artwork is not part of this design revision. Neither preview nor user approval of the design implies that it is installed.

Empty-counter behavior: David also requested flashing when confirmed empty. Pulse the active loaded-counter segments red; keep capacity, reserve, mode, and gauge steady. Stop the flash on refill or unavailable telemetry. Reduced-motion presentation retains steady red.

The earlier `dist/segmented-fancy-texture-20261010` implementation is superseded. The face and segmented digits remain cached textures and small labels remain native glyphs, but the artwork now uses the existing HUD Texture setting and renderer. The backing is rectangular and the shared decoration system supplies the perimeter. The HTML studies remain preserved design references.

## Primary mechanics inventory

Current implementation: `dist/hud-texture-caps-fix-20261010` uses the existing HUD Texture setting, 20 artwork images and four available shader slots. It restores the status band, 20-tick gauge and AUTO/BURST/SEMI cells with the active outline/underline. Native projection caches its FFI function type and reuses four corner projections per surface. After the required normal restart, David confirmed shooting/diving visibility; he also confirmed the optimized draw time remains below 2.5ms. Recorded draw CPU averaged 0.540ms over 20 seconds. DEPLOYMENT.json distinguishes that live rendering evidence from artwork acceptance.

David then supplied triangular/faceted and slanted LED references and clarified that seven segments are not required. `dist/primary-digit-study-06/index.html` compares both complete instruments. The loaded counter is 12.4% shorter and its leading-zero alpha is reduced to .14. David selected **slanted**; v4 uses that digit atlas and hierarchy through the existing compositor. He confirmed the in-game result matches and liked the native CHAMBERED +1 status strip. The faceted study remains a review alternative.

Implementation update: the separate segmentation toggle and native WorldGUI replacement were rejected. The approved primary face/atlas plugs into the ordinary HUD Texture/faithful composer and existing shader/depth renderer. Earlier restored-path and separate-segmentation packages are superseded. Shared decoration, palette and font controls apply.

The maintained catalog has named mappings for 54 entries in the observed [primary weapon index](https://helldivers.wiki.gg/wiki/Category%3APrimary_Weapons). The index has 55 weapon pages; SMG-37 Defender lacks a verified named resource mapping in the maintained source. These counts describe the inventory audit, not installed artwork or live reader coverage.

| Readout needs | Named weapons in the first scope |
| --- | --- |
| Rifle magazine/count | Liberator, Penetrator, Carbine, Concussive, Adjudicator, Tenderizer, Coyote, Suppressor, Pacifier, MA5C, StA-52 |
| Marksman magazine/count | Diligence, Counter Sniper, Amendment, Hyena, Censor |
| SMG magazine/count | Pummeler, Gallant, Reprimand, Knight, StA-11, M7S |
| Other counted projectiles | Dominator, Eruptor, Crossbow, Variable |
| Individual-round rifles | Constitution, Deadeye |
| Round-loaded shotguns | Punisher, Slugger, Halt, Cookout, Sweeper, M90A, Double Freedom |
| Magazine shotguns | Breaker, Spray & Pray, Breaker Incendiary |
| Heat and replaceable sinks | Scythe, Sickle, Double-Edge Sickle, Trident, Sai |
| Counted plasma/power cells | Scorcher, Punisher Plasma, Purifier, Accelerator, Hot-Shot |
| Fuel | Torcher |
| Arc/readiness | Blitzer |
| Multiple ammunition branches | Arbitrator (rifle/shotgun), One-Two (rifle/grenade), Stoker (SMG/fuel) |
| Individual-round explosives | Evictor |

Identity evidence is `src/weapon_names.lua`; mechanics evidence is `src/reader.lua`, `src/model.lua`, and `assets/ballistic-family/PANEL-SPECS.json`. Presentation families in `weapon_styles.lua` do not prove a weapon's equipment slot. Unresolved aliases in `COVERAGE.json` remain unresolved; do not silently assign Defender to a generic personal-defense-weapon resource.

## Readout constraints

- Reserve units follow native state, including MAGS, ROUNDS, SINKS, and PACK. Do not force a unit because the artwork resembles a magazine or shell.
- Loaded totals already include a verified chamber round where supported. Do not add a second chamber round in presentation.
- Unknown telemetry remains unknown. An empty value is not a substitute for an unavailable value.
- Purifier has an explicit native charge branch. Accelerator's current charge behavior is described by its [weapon page](https://helldivers.wiki.gg/wiki/Accelerator), but its resource is absent from the maintained native charge-reader branch. A future design can reserve a zone; it cannot claim a working charge meter yet.
- Blitzer does not receive an invented charge percentage. Hot-Shot uses counted power cells rather than a cooling heat gauge.
- Halt, Arbitrator, One-Two, and Stoker need explicit active-branch handling. Their displays cannot infer both branches from one generic loaded count.

After a direction is selected, a useful mechanics spread is Liberator, Punisher, Breaker, Scythe, Purifier, Torcher, and Blitzer, with One-Two for branch handling and Deadeye for individual-round rifles. Each weapon's hierarchy can differ while sharing legible typography and state cues.
