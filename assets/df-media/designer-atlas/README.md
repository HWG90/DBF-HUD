# Selected Double Freedom texture assets — runtime atlas v1

Authority: ../concept-board.png (latest selected media-inspired design). The static frame is the shader executor's board-derived assets/df-media/frame.png, copied without recoloring or pixel edits. Missing state-core art was generated from the selected board, then extracted and packed losslessly. This is not the flat Lua square-v4 or the older blue/brass shell art.

## Files and memory

Frame:1448 x1086 RGBA8,6,290,112 bytes. Core atlas:528 x1584 RGBA8,3,345,408 bytes. Combined raw payload9,635,520 bytes (9.19 MiB). Both are below the2048 dimension and16 MiB per-image limits. manifest.tsv describes TWO distinct resources; keep these distinct texture bindings when drawing the base and two state overlays. Never draw the raw atlas sheet as the HUD.

RGB and alpha are preserved. No gamma, saturation or channel conversion was performed. PNGs use straight alpha. Outside the frame is truly transparent; chamber wells are partially translucent (example alpha187–190 at their centers); most textured metal and footer remain nearly opaque (alpha252–253). Don't describe this as uniformly translucent center paneling. Overall display opacity can be controlled by the existing renderer.

## Coordinates

ATLAS.json is authoritative, all coordinates TOP-LEFT.

Frame resource df_media_frame_v1: full image1448 x1086, rendered crop[51,46,1373,982]. Preserve1373:982 aspect; the initial logical extent is128 x91.548434. Do not stretch into the previous120-square or generation-brief120x112.

Core resource df_media_cores_v1:512-square cells at[8,8,512,512] loaded,[8,536,512,512] unavailable,[8,1064,512,512] unknown. Eight-pixel transparent gutters. All centers are registered to the cell center, within half a source pixel; there is no state-dependent render-size change. Each core draws into the SAME32 x32 logical overlay box. Frame-space centers are[436,492] and[985,492]; transformed logical centers are in the JSON. Core size32 includes glow padding; the visible disc is smaller than the outer chamber rim.

Loaded is warm-ivory glass/glow; unavailable is dim muted-red glass; unknown is neutral gray with a broken ring. Static chamber rims are already in the frame, so don't add duplicate ring textures or primitives.

DBS-2, active SEMI/VOLLEY, and reserve+RES use native atlas/Lua text. No dynamic text or round count is baked in any supplied PNG. Top-left pixel readout centers/zones are in ATLAS.json. Convert Y deliberately if the native command coordinate convention is bottom-left. The reserve number is reserve only; don't add a second loaded-round count. Preserve text-free backdrop rather than cutting rectangular alpha holes around live text.

## State binding

Select the two cores from authoritative loaded/firing data; a known one-round state has left unavailable/right loaded in the existing observed sequence. Use UNKNOWN when ammo ownership/data is unavailable. Zero ammo does not prove physical ejection. A verified reload event may mark unavailable but must not fabricate an OPEN/EJECTED state from ammo zero. No physical ejected/reloading sprite is supplied in this three-state atlas.

## Handoff

This folder is isolated. Native runtime/material pair and installed files are untouched. Shader executor owns compatible compositor integration, manifest staging and hot-load. The offline SVG previews demonstrate the ACTUAL prepared textures with separate sample text, not native projection, live state, performance or verified camera mounting.
