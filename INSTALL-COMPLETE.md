# DBF-HUD Complete

One archive containing the HUD, render bridge, verified WorldGUI depth assets, optional MDL live mod, starter configuration, source and font licenses.

Requires Bingus Shared Loader v15+ / API 1. MDL API 2 is required only for the live-reload installation choice. These external loaders are not bundled.

## Install or upgrade

1. Disable the previous separate DBF-HUD startup, render-bridge, fullbright-material, shader-loader-control and depth-test/probe addons in Arsenal. Keep Bingus Shared Loader enabled.
2. Import this ZIP into Arsenal and choose exactly one option:
   - **Complete HUD - startup:** installs the HUD and bridge together, plus depth assets. Disable DBF-HUD (Live) in MDL to avoid duplicate HUDs.
   - **MDL live reload - bridge and depth assets:** installs only the startup bridge and depth assets. Copy `MDL/dbf_hud` from this ZIP into `%LOCALAPPDATA%/MDL/Helldivers2/Mods`, replacing the existing live mod, and enable DBF-HUD (Live).
3. Deploy and restart the game. In Options > Mods > DBF-HUD choose **3D, WorldGUI**. Leave **Always Show HUD (3D)** off for occlusion; turn it on to draw through geometry. The other display modes are **2D, Anchor to Weapon (Hybrid)** and **2D, Anchor to HUD/Crosshair**.

Existing tuning is preserved. `Configuration/DBF-HUD-tuning.lua` is an optional starter example; do not overwrite your saved game-root tuning unless you intend to reset it.

The depth assets are byte-identical to the visually confirmed depth probe. The combined installation packaging has been checked offline; its startup installation choice has not yet had a separate in-game verification. World-space frost and reliable camera-state detection remain unresolved. Mesh rendering and its texture/effect controls are archived in code and disabled. The menu has only DBF-HUD and DBF-HUD Placement. Old menu rows can remain until the next game restart. The Fonts directory contains prepared font atlases and metrics for future integration; they are not selectable at runtime yet.
