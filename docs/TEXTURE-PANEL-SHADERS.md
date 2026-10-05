# Texture panel shaders

Explicit theme shader selections now select texture-compatible variants for the whole artwork. Auto and None retain the original artwork material. Existing Scale, Animate and Speed controls are supported; artwork alpha, depth testing, projection and live occupancy masking are preserved. Live text/readouts stay separate.

40 shader variants compiled. Existing archive resources were preserved byte-for-byte except the shader library group, which registers the additional variants. Original PNGs, native textures, alpha, settings and layouts are unchanged. Material availability checks fall back to original artwork if variant assets are missing.

Installed into the game and Arsenal while the game was closed. New native resources require the next game launch. Offline compilation, parameter encoding/material selection tests and archive bounds passed. In-game appearance and native loading still need verification. Backup: Documents/Codex/hud-hot-art-deploy/texture-theme-backup. Report: texture-themes/report.json.
