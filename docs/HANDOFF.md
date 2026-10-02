# Development handoff

Start with README, ARCHITECTURE, LAYOUT_EDITOR and DEVELOPMENT. This is an experimental source checkpoint, not a complete asset installer.

## Current system

MDL owns the HUD lifecycle. Weapon state is read with identity and build guards. A render-independent layout supplies screen-projected geometry and oriented native text. Scene-depth materials provide occlusion. Saved per-weapon/per-view profiles supply attachment, position and scale; live profiles must survive code updates.

The live editor supports position, scale and attachment cycling. Save confirms the readable weapon name and view. Force occlusion has a native binding and debug notice. The custom DBF-HUD Fonts page exposes 72 families directly; its latest menu update still needs live confirmation.

## Current weapon presentation

- Ammo and reserves use fixed digit slots and dim leading zeros. Speargun loaded count is a single digit, with native upward arrowheads, no heading and reserves even when empty.
- Heat/fuel/gas use textured gauges and calibration ticks. Heat’s final section flashes red/white; fuel/gas drain with remaining capacity.
- Railgun has Safe/Unsafe status and a vertical charge meter; its final warning threshold remains provisional.
- Recoilless HEAT/HE labels/icons and pack reserves are separate from loaded count.
- Autocannon pulses at five or fewer; first-clip reload correction was confirmed in game.
- Weapon-specific labels include Arbiter 4MM/10G, Dominator 15x100MM, Crossbow BOLTS, Re-Educator DARTS, Sterilizer GAS/TANKS and Leveller WARHEAD.

## Evidence and remaining work

Screen tracking, scene occlusion, restored text and several weapon placements were confirmed in game. The isolated Lua suite has 101 passing contracts. This does not prove every weapon, font or package works live.

First-person panel wiggle is unresolved. Native and manual projection samples agreed, but that does not establish alignment with the rendered viewmodel. Quasar placement and some charge thresholds need further checks. Sixteen node-name matches are available; barrel and magazine were user-confirmed. Unmatched nodes retain index labels.

## Preservation rules

Never overwrite live tuning or weapon profiles with repository examples. Keep logs, captures and separate private test tools outside publication. Check the deployed artifact and logs after a failed live test before making another speculative change.

## Next edit

Read the relevant source module, make the smallest coherent change, run proportional checks, build the Lua bundle and verify live behavior separately. Asset changes require deployment and restart; Lua changes normally need MDL reload only.
