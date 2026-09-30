# Deferred work

## Nerd Fonts library support

User requested all fonts from https://www.nerdfonts.com/font-downloads to be usable and explicitly deferred implementation on 2026-09-29.

Conversion completed on 2026-09-30 after the user requested it: all 72 release families / 2,252 faces have lossless 48px grayscale alpha atlases, metrics and original licensing documents under assets/fonts. Printable ASCII is prepared for text fonts, and the SymbolsOnly faces include all supported symbols. Source tar archives are cached outside the repository. Remaining work: runtime renderer integration, font selection, loading only the selected face, and any additional Unicode/icon coverage needed by the HUD.

WorldGUI depth occlusion is now visually confirmed. Mesh code is archived, public menus are reduced to DBF-HUD and DBF-HUD Placement.

## Three explicit camera-mode mounting points

User deferred this idea on 2026-09-30: define three persistent GUI mounting points for first-person aim, third-person right shoulder, and third-person left shoulder. Select the appropriate mount and snap the GUI to it, rather than continually shifting one mount between mode-specific offsets. Revisit transition smoothing and per-weapon mount overrides when implementing; neither is decided by this note. Preserve current placement behavior until this work is resumed.

## Camera-state detection and production cleanup

Locate and verify accepted first-person and shoulder states; replace distance/lateral heuristics that can misclassify fast camera motion. Later cleanup: gate native API/resource diagnostics behind a debug flag, document public tuning separately from archived mesh settings, and separate the optional font library from the small runtime install when font loading is implemented.
