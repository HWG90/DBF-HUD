# DBF-HUD Complete

One Arsenal archive contains HUD startup Lua, render bridge, native fonts and current screen-depth assets. Bingus Shared Loader remains external. MDL is optional.

Close the game. Disable earlier separate HUD startup/bridge, font and depth/probe packages to avoid overriding the merged shader group. Keep Bingus Shared Loader enabled. Import this Complete ZIP and choose exactly one option:

- **Complete HUD - startup:** HUD and all assets. Disable the separate DBF-HUD MDL mod to avoid duplicate instances.
- **MDL live reload - bridge and all assets:** assets and bridge only. Copy `MDL/dbf_hud` to `%LOCALAPPDATA%/MDL/Helldivers2/Mods`, and enable it in MDL API 2.

Deploy and restart. Keep the loader at its documented highest priority. MCM is an optional separate download for Appearance preview and presets. Existing tuning/layouts are not replaced; Configuration contains examples only.

Combined startup Lua and archive structure are checked offline. This new combined archive still needs a fresh in-game test, especially its standalone startup option. Rotation wiggle and MCM rollback/label issues remain pending. See GETTING_STARTED.md.
