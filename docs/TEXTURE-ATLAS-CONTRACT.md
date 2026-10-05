# Panel atlas art handoff

Status: panel region/state mapping implemented in an undeployed candidate. Native
hot upload is quarantined following allocator crashes. Packaged atlas loading,
visual integration and custom weapon font registration remain unverified.

For the first Double Freedom test, deliver `double-freedom-atlas.png` and
`double-freedom-atlas.json`. Use a transparent RGBA PNG, preferably 1024x512,
with at least four transparent pixels between regions. No resize is performed
between authored atlas and metadata. Pixel rectangles use the top-left origin;
the adapter converts them to normalized UV rectangles.

Required independent regions:

- `housing`: panel artwork with no ammunition shells baked into it.
- `shell_loaded`: one blue hull with a brass rear base, reusable twice.
- `recess`: optional empty barrel recess, independent of loaded shell visibility.
- `selector_semi` and `selector_volley`: optional selection artwork. Native mode
  text remains authoritative until custom font/selector integration is completed.

Keep fired/spent shell artwork separate if supplied. Do not create three complete
panels for loaded/one-fired/empty. The runtime hides the first loaded-shell
instance at count 1 and both at count 0, then restores them from the current count.
Unknown count must not invent loaded ammunition.

Example authoring metadata (example rectangles only):

```json
{
  "version": 1,
  "weapon": "72170a55a1f37ff1",
  "image": "double-freedom-atlas.png",
  "size": [1024, 512],
  "regions": {
    "housing": [0, 0, 512, 512],
    "shell_loaded": [520, 0, 128, 256],
    "recess": [656, 0, 128, 256],
    "selector_semi": [520, 264, 240, 64],
    "selector_volley": [520, 336, 240, 64]
  }
}
```

Runtime `atlas_rect={u,v,width,height}` uses top-left normalized UV coordinates.
Runtime layer `rect={left,bottom,width,height}` uses the panel's bottom-left origin.
These are different coordinate systems. Set `layout.atlas_rect` for the housing
region and `atlas_rect` on each overlay for its source region.

Each overlay references an explicit compiled texture/material; they can all point
to the same atlas. Current limit is eight visible images including the housing.
Independent material mappings are isolated per image. This is not yet optimized
batching, and performance must be measured in game.

For the military stencil font, supply a separate transparent font atlas and
metadata for at least `0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ /-:.?`. Keep glyphs
white with alpha so the HUD controls tint. Include pixel rectangle, advance,
bearing, baseline and nominal em size for each glyph. Custom weapon font atlas
registration is not implemented yet; this is an authoring handoff for that next
step, not a claim that the current candidate can render the font.

No art or font from this handoff should be deployed through the quarantined native
hot-upload path. It must be compiled and packaged through the normal asset route.
