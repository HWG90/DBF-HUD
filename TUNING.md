# Tuning and diagnostics

Use the native DBF-HUD menu for display and appearance, and DBF-HUD Placement for positioning. Camera detection and placement behavior are unchanged.

Debug logging is off by default. Enable it in DBF-HUD to capture capability inventories, resource availability, weapon bindings, pose and camera samples, and periodic renderer status. Disabling it stops those probes and traces. Startup, tuning/menu failures and rendering errors remain logged. It saves as `debug_logging` in the Lua tuning file.

The tuning file keeps active settings at the top level. `archived_mesh` contains emission, texture refresh, scanlines, saturation and the rifle-material experiment; these do not affect the active direct WorldGUI renderer. `research` contains optional diagnostic markers and the historical rectangle probe, which require debug logging.

Existing flat tuning files remain accepted. Saving through the menu reorganizes their values into these groups without discarding archived values. Unknown or duplicate entries reject the entire update. `always_show_3d` is the authoritative saved occlusion setting; old `hud_occlusion` and `occlusion_mode` aliases remain accepted for migration.

Colors remain in Lua tuning. No experimental conversion or saturation is reintroduced. Prepared Nerd Fonts and the archived mesh implementation remain available in the source package.
