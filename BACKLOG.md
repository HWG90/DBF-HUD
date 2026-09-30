# Deferred work

## Nerd Fonts library support

User requested all fonts from https://www.nerdfonts.com/font-downloads to be usable and explicitly deferred implementation on 2026-09-29.

Provide font selection through the native menu and Lua tuning. BigBlue's current 8x12 pixel conversion is specific to that font; other font families need an appropriate import/rendering path rather than being forced onto its pixel grid. Determine glyph coverage and packaging strategy when this work resumes. Do not download or bundle the full library yet.

Current priority: native offscreen image rendering and a scene surface with verified depth occlusion. Hybrid and world-GUI weapon attachment are already working.

## Three explicit camera-mode mounting points

User deferred this idea on 2026-09-30: define three persistent GUI mounting points for first-person aim, third-person right shoulder, and third-person left shoulder. Select the appropriate mount and snap the GUI to it, rather than continually shifting one mount between mode-specific offsets. Revisit transition smoothing and per-weapon mount overrides when implementing; neither is decided by this note. Preserve current placement behavior until this work is resumed.
