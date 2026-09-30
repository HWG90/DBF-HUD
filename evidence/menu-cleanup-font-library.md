# Menu cleanup and prepared fonts, 2026-09-30

Public menu groups: DBF-HUD (8 options) and DBF-HUD Placement (21 options), below the API's 32-option group limit. Existing placement option IDs are reused to avoid overflowing that limit during live upgrade. Old Effects/Legacy/diagnostic rows have their callbacks retired and disappear on restart.

Three display choices retain the existing config anchor values: weapon (2D hybrid), crosshair (2D HUD/crosshair), world (3D direct WorldGUI). Always Show HUD (3D) maps on to gui / depth disabled, off to gui_depth / verified depth material. Old mesh tuning migrates to gui_depth. The mesh dispatch is commented out, while its implementation and offscreen renderer remain in source.

The active MDL adapter no longer creates or updates an offscreen texture, nor overrides the user's display mode. Startup and MDL now share runtime WorldGUI dispatch. Switching into 2D and losing a weapon release the old WorldGUI. Scale is applied to world panel width while preserving its measured aspect ratio. Color tuning remains config-only.

Nerd Fonts v3.5.1 conversion completed for 72 families and 2,252 faces with zero importer errors. All text faces have printable-ASCII alpha atlases and metrics at 48px, with explicit missing-codepoint metadata; two SymbolsOnly faces each contain 10,624 symbols. Source digests, archive URLs and upstream license/readme files accompany every family. The assets are prepared for later renderer integration, not exposed as live font choices yet. Original compressed archives remain in the workspace's external font cache.

All 47 contracts pass, including public toggle semantics, two-menu limits, mesh migration, direct 3D dispatch without texture input, mode switching, retirement and preserved legacy mesh geometry checks. Combined startup Lua compiles; ZIP integrity and exact verified depth-asset equality pass. New package is DBF-HUD-Complete-0.3.37.zip. The installed live Lua was updated atomically. No live visual verification of the revised menu/dispatch is claimed.
