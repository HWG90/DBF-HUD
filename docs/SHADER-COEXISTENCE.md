# HUD and War Journalist shader assets

Both mods replace the same engine `default_shaders` resource. A registration
list containing only one mod's shaders disables the other's materials even
when resource lookup and texture upload succeed. Resource availability is not
proof that the renderer registered a shader template.

Build the matching Arsenal payloads with:

```
py -3 tools/build_arsenal_pair.py
```

The sibling DBF_PhotoMode checkout is required. Missing source, a changed native
snapshot, or different shader definitions under the same ID fails the build.
No build reads the game folder or Arsenal's mod cache as an asset input.

`shared_shader_assets.py` combines the promoted HUD native snapshot with War
Journalist's current owned release resources. Each package ships the complete
library set and the same registry, retaining stock order. This avoids dangling
registrations when either mod is installed alone and makes the matching pair
independent of deployment order. Non-shader resources stay with their owner.

The native snapshot is explicitly promoted from the maintained HUD package;
its provenance and hashes are in `assets/native-runtime/provenance.json`.
Update it deliberately when rebuilding HUD native resources. It is not an
automatically refreshed installed-file input.

When shader membership or program bytes change, rebuild and ship both payloads
together. Compare `shader_closure_sha256` in their receipts. A stale third-party
or historical package can still replace the global registry; this engine does
not merge registries at deployment. Do not promise compatibility with arbitrary
older payloads. Different same-ID shader programs are rejected rather than
silently chosen by load order.

The pair verifier reads the completed ZIPs and compares every shader and the
registry against the source closure. Native asset tests do not prove live pixels.
Install through Arsenal, deploy there, restart normally, and verify the running
shader-template table and the visible HUD. Never repair the game data directory
or hand-edit an Arsenal cache as the source fix.
