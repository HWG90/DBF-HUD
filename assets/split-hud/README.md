# Split instrument textures

Generated from Study 08 by `tools/build_split_textures.cjs`. The SVG/PNG sources and immutable RGBA8 payloads contain authored numeral, symbol and bracket geometry; no game capture or extracted font donor is included.

The atlas is rasterized at 2048x1024 while retaining logical 1024x512 UV coordinates. The face and coverage images are 640x322 for the 320x161 Combat instrument. Four static payloads total 10,861,568 bytes. `manifest-additions.tsv` declares their existing hot-art resource names and content-addressed files. `CHECKS.json` and `TEXTURES.json` record generation checks and hashes.

The runtime retains native font controls. Labels are native glyphs; numerals and symbols are atlas textures. Dynamic feather/dither masks are built from the hard coverage and face by `src/edge_mask.lua`, then published atomically by the existing generated-image pipeline. Each shader layer retains an independent material slot and full-UV carrier. The selected decoration system remains authoritative.

Offline checks: `tests/split_hud.lua`, `tests/split_spatial.lua`, `tests/split_masks.lua` and `tests/generated_image_batch.lua`. Live readability, occlusion and performance require in-game verification.
