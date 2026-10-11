# Universal HUD study 07

Review-only spatial design study, October 11, 2026. Maintained source owner: the `DBF-HUD` repository. The study changes only this named `dist` folder. Game deployment and the separately developed live edge controls are outside this study.

## Three compositions

- **Orbit** — an open arc around the main resource, with small reserve and selector satellites. The arc serves the resource proportion; it does not pretend to be a compass or targeting reticle. The main readout is the visual anchor, with reserve and context placed at different simulated depths. This is the strongest exploration of a weapon-mounted instrument in 3D space.
- **Rail** — a low register and proportion bar. It retains the fastest left-to-right reading and the smallest vertical footprint. A typed reserve sits at its right. Selectable settings fit in one understated row.
- **Split** — a main readout held by one open bracket, a small reserve node to its left, and settings to its right. It leaves the center of the composition mostly open, without imposing one enclosing plate.

These are alternate arrangements of the same semantics, not separate feature sets. They preserve the selected white/gold/navy theme and approved slanted LED glyph geometry. Red belongs to explicit empty, spent, or venting states; only the empty ammunition counter flashes, at 2 Hz. Reduced-motion users receive a steady counter.

## Common hierarchy

1. The useful resource is dominant: loaded ammunition, heat, active charge, or fuel. An active charge percentage takes priority while the loaded shot remains visible below it.
2. Capacity is a subordinate `/ capacity` when it is meaningful. No second CAP register is needed.
3. Reserve is a compact count with its real unit: MAGS, BELTS, SHELLS, SINKS, SHOTS, TANKS, or PACK. A missing reserve does not become zero.
4. The separate compact status strip is reserved for meaningful states such as CHAMBERED +1, LOW AMMO, EMPTY, SPENT, CHARGING, HOT, VENTING, or NO DATA.
5. Context shows the selected value of an applicable setting. Fixed fire mode and absent metadata consume no space. A HUD should report a changed selection, not constantly display every alternative choice.

Weapon identity remains small. Symbols reinforce a written unit or selected value rather than requiring the player to learn an unlabelled symbol language. No clipped enclosing corners or fixed perimeter style are required; final runtime decoration must continue to respect the existing decoration system.

## Spatial review

The four original supplied gameplay screenshots are local optional references, preserved unchanged in `reference/` and loaded through relative URLs. Those user captures and their local hash provenance are excluded from publication. If they are absent in a public clone, the study shows a neutral field and an optional-reference message. Source and copy hashes are checked locally in `REFERENCE-HASHES.json`. The screenshots are not edited or composited into a new raster. The HTML instrument can be dragged independently to test nearby positions. Its angle approximates the visible weapon angle, and primary, reserve, and selector planes can be separated in simulated depth. This is an offline spatial mockup, not live weapon tracking or a new rendering pathway.

The scene reference is **1920 × 1080**. The original 3839 × 2159 screenshots are displayed at this reference size. Gameplay defaults to **70% instrument size**: Orbit is approximately 231 × 133 reference pixels; Rail 231 × 112; Split 224 × 113. The 50-pixel main numeral becomes 35 pixels, and critical unit/context/status labels are approximately 8 pixels. Overview cards stay at 100% for inspection. `actual-scale.png` shows all three designs at the 70% gameplay size without enlarging them.

Fit scene scales the entire scene together; 100% screen draws reference pixels as CSS pixels and centers the crop around the instrument; Inspect ×3 magnifies the same scene and instrument. The size slider can restore 100% or increase to 150%. This reference is useful for comparing footprint and glance reading, but does not claim pixel-perfect equivalence to the current game mount settings, projection, font rasterization, or monitor DPI. Small labels will need a real angle/distance check before accepting a final in-game minimum size.

Backing, feather width, edge dither, grain, and spatial controls here are **preview-only**. The procedural SVG alpha masks illustrate the visual direction. The backing and outer accents fade together; numbers, labels, and the status strip stay crisp. A stable ordered pattern breaks up only the fade, and its grain scale is independent of the underlying game screenshots.

## Current source capability mapping

The source was inspected on October 11; all fixtures are illustrative static values, not observations of a live weapon. Their number, capacity, and rate values must not be used as a game-stat reference.

| Display role | Current source fields and evidence | Design rule |
| --- | --- | --- |
| Loaded resource / capacity | `src/model.lua:30–36` normalizes `raw.rounds` into `value` and validates `capacity`; invalid/unknown values are not fabricated. `src/reader.lua:210–243` obtains the selected ammo state, capacity, and reserve. | Largest register; capacity subordinate; unknown uses a dash with NO DATA. |
| Typed reserve | `src/reader.lua:203` reads sinks. `src/reader.lua:243` identifies MAGS or ROUNDS. `src/reader.lua:260` identifies PACK. `src/ammo_types.lua:195–280` maps meaningful unit labels such as batteries, belts, fuel tanks, shells, and shots. | Preserve reader-owned units; no estimated total ammunition. |
| Chambered bonus | `src/model.lua:34` requires supported chamber state and `value == capacity + 1`. | CHAMBERED +1 status; the reader already includes the chamber in the displayed loaded count. |
| Heat and lockout | `src/reader.lua:171–203` validates heat and lockout. `src/model.lua:14–25` defines heat percentage, HOT, VENT, and Quasar charge handling. | Label HEAT explicitly; percentage and gauge grow together. VENTING is an explicit state. |
| Selectable fire mode | `src/reader.lua:282–303` reads optional control metadata. `src/ammo_types.lua:181–187` returns a mode only when multiple valid distinct choices are exposed; known AUTO / SEMI / BURST / ALT mappings are in `:176–180`. VOLLEY is a special handling case in reader. | Show the selected mode only when available; do not guess AUTO or SEMI for a fixed-mode weapon. |
| Selectable fire rate | `src/reader.lua:306–334` validates rate selections, returns a rate only with at least two enabled slots, and ties the selection to the equipped entity. `src/model.lua:11–12` accepts the validated selectable rate. | One compact `n RPM` item, not a second large meter. |
| Ammunition selector | `src/reader.lua:292–297` reads known Autocannon, Recoilless, Airburst, and missile-pistol selectors. `src/ammo_types.lua` provides the corresponding label mappings. | Selected ammunition has its own context item, independently of fire select or RPM. |
| Safety | `src/reader.lua:300` maps Railgun SAFE / UNSAFE. The model carries `safety_mode`. | Short labeled item; no inferred mode or universal safety control. |
| Charge | `src/reader.lua:175–199` calibrates Quasar. `:338–412` handles Railgun, Melta, Epoch, Loyalist, and Purifier charge contracts. `src/model.lua:9–10` preserves the normalized fields; `src/view_presentation.lua:24–35` determines existing charge presentation. | Active charge takes priority, loaded ammunition remains subordinate. Different systems retain different calibrated semantics; this study does not infer a common lethal deadline. |
| Expendable state | `src/reader.lua:153` reads `reloadable`; `src/model.lua:36` distinguishes SPENT from EMPTY. `src/view_presentation.lua` selects expendable semantics from the model state. | ONE SHOT / SINGLE USE; no invented reserve. Reporting SINGLE USE while still loaded needs reloadability carried through normalization or verified weapon metadata; the current normalized model does not retain `reloadable`. |
| Infinite energy | `src/model.lua:27–28` uses `kind == infinite`, value `--`, label ENERGY, and fraction 1. | This concept uses `∞` as a proposed visual translation of the infinite kind. That glyph is a design proposal, not an existing runtime value. |

The source can carry fire select, rate, ammunition mode, and safety independently. The universal design must therefore retain separate context slots rather than choosing one field with an `or` chain. A tenth **Mixed settings · illustrative** specimen combines all four supported field types deliberately; it is not a real-weapon assertion. Orbit and Split stack four context items away from the resource register; Rail divides its lower row into four slots. `settings-stress.png` shows all three adaptations. The real-identity fixtures demonstrate source capabilities without pretending that every possible combination has been observed on one weapon.

### Additional contracts still required

The current normalized model does not expose a universal scope-zoom selector, flashlight state, programmable fuse distance, targeting range, a full list of choice labels for every selector, or every alternate resource pool at once. These must receive reader-owned contracts and coverage before presentation can claim complete catalog integration. A new design language can reserve space for them without reporting fabricated values today.

## Validation

`node --check study.js` passed. Offline `qa.cjs` executes the actual fixture/composition functions, generates the actual procedural masks, validates every concept/family/state composition, and rasterizes standalone SVG snapshots with Sharp. This is code and asset QA.

Interactive browser layout inspection was blocked by the browser tool's URL policy because this is a local `file:///` artifact. No localhost, alternate browser surface, raw browser command, or other workaround was used. Responsive layout, DOM interaction, and 3D perspective remain unverified in a browser; the generated standalone SVG assets can be visually inspected independently.

Open `index.html` for the full study. `comparison.png` and the three `*-chamber.svg` / `*-chamber.png` files provide standalone concept review. `family-overview.png` shows nine resource systems in Orbit, and `settings-stress.png` shows all three compositions with four independently applicable settings. The selected default is Orbit, but no concept is yet accepted for runtime implementation.
