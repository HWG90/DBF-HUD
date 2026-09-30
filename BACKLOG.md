# Deferred work

## Nerd Fonts library support

User requested all fonts from https://www.nerdfonts.com/font-downloads to be usable and explicitly deferred implementation on 2026-09-29.

Provide font selection through the native menu and Lua tuning. BigBlue's current 8x12 pixel conversion is specific to that font; other font families need an appropriate import/rendering path rather than being forced onto its pixel grid. Determine glyph coverage and packaging strategy when this work resumes. Do not download or bundle the full library yet.

Current priority: native offscreen image rendering and a scene surface with verified depth occlusion. Hybrid and world-GUI weapon attachment are already working.
