# New-chat handoff — October 1, 2026

Read README and linked guides before modifying this system. This checkpoint documents source and live user confirmations; it is not a release receipt for every retained ZIP.

## Working locations

Use this repository as the source checkout. The installed Lua lives in
`%LOCALAPPDATA%/MDL/Helldivers2/Mods/dbf_hud`. Local game captures, logs,
shader donor files and separate developer test tools are not publication artifacts.

## Preservation rules

- User has edited live profiles, including Liberator, Warrant and Autocannon. Never replace the live offsets file with repository defaults.
- Keep existing uncommitted work. The working tree contains the full ongoing HUD/editor pass; do not revert it wholesale.
- Local developer/testing tools are private and must not be uploaded to GitHub or published. They are separate from HUD source.
- Do not claim a build/test passed unless run, or visual behavior works unless observed/user-confirmed.
- Do not silently reintroduce the reverted Always show HUD experiment or the disabled font-probe comparison labels.

## Current confirmed behavior

The user confirmed combined depth/font behavior, fixed-digit heat display, several heat/fuel designs, smooth split-color F, railgun charge fill in Unsafe, attachment cycling, barrel/magazine alignment, editor key movement, editor scale and Force occlusion debug notice.

Machine Gun, Stalwart, Heavy Machine Gun, Anti-Materiel Rifle, Laser Cannon, Autocannon and speargun placements received live checks during the placement pass. This is not a claim every catalog weapon was checked. The user authorized a catalog placement pass, then paused it to build the editor.

The latest profile operation copied only x/y/z from the live regular Liberator to Liberator Penetrator and Liberator Carbine across view entries. Other weapon entries and target scale/attachment fields were preserved. The source Liberator currently has its own first-person scale; that scale was not included in an offsets-only copy. A pre-copy backup is in the work folder. In-game variant fit remains to be checked.

Temporary placement inspection settings used opacity 45% with decorations off. The previous values were backed up in `work/HUD-tuning-before-placement-visibility.lua`. Do not restore the whole old tuning file: newer settings would be lost. Restore only those fields when requested.

## Weapon-specific display decisions

- Plasma: BOLTS / BATTS, Epoch projectile shape; Melta remains separate: SHOTS / CNSTRS with enlarged upright thermal oval.
- Fuel weapons: decreasing styled fuel gauge, flame symbol, small fuel count and tank reserves; Stoker active bullet/fuel modes have separate classification.
- Grenade launchers: heading omitted, own projectile symbols where available. Generic grenade uses 40 mm HE shape. Regular launcher reserve BELTS.
- Regular Machine Gun reserves BELTS; do not automatically apply that to every machine gun.
- Railgun: no ROUNDS heading; SHOTS reserves; upright projectile, verified Safe/Unsafe indicator, vertical charge bar spanning main and child panels. Green band 65-70%.
- Autocannon: count pulses continuously at five or fewer as a reload reminder.
- Speargun: standard upright panel, single loaded digit, native projectile arrowheads rotated upward, no ammo heading, and spear reserves visible even when empty. Flat/folded transforms were removed.
- Helldivers decoration: matching strokes at all four corners; no fixed yellow accents.

## Unfinished or provisional

- Railgun last-safe firing / danger threshold remains provisional even though charge fill was user-confirmed. Do not present it as a calibrated safety guarantee.
- Purifier fully charged signal sampling was paused after unreliable attack/window comparisons. Prepared cyan pulse is not a verified working charge-ready feature.
- Quasar placement was installed beneath the native gauge in first person and nearer receiver in third person; final post-relaunch check was pending when editor work took priority.
- User requested identifying remaining nodes through a previously built Discover tool. The exact tool has not been located. Do not substitute guessed node names or claim discovery completed.
- First-person attachment selection uses recent camera/parity state; inspect transitions if a one-frame discrepancy appears.
- Unknown custom nodes lack a dedicated unavailable-anchor warning.
- World-space frosted blur remains unresolved; browser preview is not native proof.

## Next-chat starting procedure

1. Inspect live profile/tuning files and back them up before touching data.
2. Read module source relevant to the requested edit; use architecture map to avoid broad exploration.
3. Check installed MDL/bindings logs and current game/build if native behavior matters.
4. Make the smallest coherent change, run relevant contracts, build and deploy only Lua when sufficient.
5. Report source/tests, live installation and visual proof separately.

## Orientation trial result
Selected-bone orientation was installed as a trial and did not resolve the lag in the user check. It was reverted to the prior root orientation. First-person lag remains unresolved; do not describe the trial as a fix.

## Active bone tracking diagnostic
A temporary cyan WorldGUI cross is enabled at the selected node position without offsets or smoothing. It draws unoccluded, independently of the main HUD; root is used only when explicitly selected. No marker is drawn if the selected anchor is unavailable. The runtime set_bone_marker(false) method disables it; remove the diagnostic after the comparison. No motion clip has been recorded yet. A trailing marker would implicate sampled pose or shared rendering timing, not uniquely prove either one.

## Motion clip evidence
The user supplied a 19.48-second 3840x2160 clip recorded at 60 fps. Extracted consecutive frames around six seconds show cyan marker and HUD moving together relative to the first-person gun. This supports a shared sampled-pose/render timing issue, not a main-panel offset-only problem. It does not establish exact latency or distinguish stale pose from WorldGUI submission timing. Both diagnostic and main panel use WorldGUI; a screen-projected marker or later render-phase comparison would be needed to separate those paths. Extracted contact sheets remain private in the work folder.

The diagnostic now includes a hollow magenta screen-space square centered on the same sampled world position as the cyan cross, using the existing frame camera snapshot and no extra native reads or smoothing. Compare their centers during motion. The projection is our read-only camera model, not an engine projection call; discrepancies can also indicate camera/projection timing or math. Treat results as narrowing evidence, not a unique proof of pose versus GUI timing.

## Active screen-projected HUD trial
User clarified magenta tracks correctly in both views; do not retain the earlier interpretation that it trails. MDL now opts into screen_bone_hud=true: full HUD uses the diagnostic bone projection directly, bypasses weapon movement smoothing and WorldGUI. Position corrections are not applied in this exact-anchor trial; profile scale remains applied and saved profiles are unchanged. The screen-space path lacks world depth occlusion and folded world-panel orientation. Startup/other adapters remain on their usual path. Existing 93 contracts passed; active trial needs live check. Disable the adapter opt-in to restore normal rendering.

## Screen HUD trial reverted by request
The user confirmed screen-projected HUD tracking was locked, then requested restoring WorldGUI before further depth work. MDL screen_bone_hud is now false. Saved offsets and normal WorldGUI depth behavior apply again; cyan and magenta diagnostic markers remain. Keep depth experiments separate from the working HUD.

## Current migration: screen projection plus scene-depth comparison

The user subsequently confirmed the green comparison probe occludes and stays
locked in both views. The complete HUD migration is now packaged as Screen Depth
Renderer 0.3; full HUD live validation is pending. See SCREEN_DEPTH_RESEARCH.md for
package order, shader transport, known limits and rollback. `screen_scene.lua`
projects the existing fitted world geometry and saved mounts into the UI world.
It uses unchanged native font atlas texels as textured glyph quads, retains RGB and
alpha, and supports the folded speargun child. Missing assets or submission failure
fall back to WorldGUI. Diagnostic squares remain until full-HUD acceptance.

The Arbitrator's secondary presentation now reads 10G SHELL with SHELLS reserves
and the standard shotgun-shell glyph; its primary magazine is unchanged. No claim
is made that a unique 10-gauge game texture has been extracted. A selected RPM slot
is prepared alongside fire mode, but the reader does not yet supply verified live
RPM. It must stay hidden until the selected rate is traced and live-tested.

## Current checkpoint

- Screen-projected HUD tracking and scene-depth occlusion were confirmed in game.
- Native text follows projected panel orientation; panel opacity is respected.
- All 72 font families are exposed through the direct DBF-HUD Fonts custom-menu page.
  The font-page update still needs live confirmation; legacy entries can persist until restart.
- Programmable Recoilless HEAT/HE presentation and empty counts preserve pack reserves.
- Autocannon pending-chamber correction now counts the first inserted clip as five; user confirmed it.
- First-person panel wiggle remains unresolved. Native/manual projection samples agree;
  do not claim the remaining viewmodel alignment issue is fixed.
- Current isolated Lua suite: 101 passing contracts. This is not proof of every live visual.
