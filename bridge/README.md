# Startup render bridge

Experimental callback dispatcher for the offscreen HUD test. Install `DBF-HUD-Render-Bridge-0.1.zip` as a normal Bingus Shared Loader addon through Arsenal, enable it, deploy and restart. Keep the packaged DBF-HUD HUD disabled; DBF-HUD (Live) remains managed by MDL.

Do not install render_bridge.lua as an MDL loose mod. This separation is essential: MDL tracks and deletes changes to globals on reload. The startup addon owns the dispatcher for the game session; live clients subscribe and unsubscribe through HUDRenderBridge API 1. It preserves the host callback and isolates subscriber Lua errors. It contains no game assets and does not itself allocate or render anything.

Live 0.3.36 requires the bridge before its offscreen test can allocate resources. The test creates a private camera and four-color texture, renders once, then attempts a small screen-space preview. The experiment's visual output and GPU lifetime on reload remain unverified. It does not yet create a depth-tested ammo-panel mesh.

Source packaging uses the external Bingus `build_addon.py`, resource name `mods/holographic_utility_display/render_bridge`, and stable GUID `2d860b40-510b-4a22-bbad-0911f9537d64`.
