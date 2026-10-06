# Source and runtime maintenance

`tools/build.py` owns the module order. Startup and managed bundles use the same module body and different lifecycle adapters. Tests obtain that module list from the build script rather than maintaining another list. Core contracts deliberately omit user-authored bundled defaults.

## Local build

```
python tools/build.py
python tools/build.py --check
python tests/test_build.py
python tests/run.py
```

An ordinary build writes only `dist/dbf_hud.lua` and `mdl/dbf_hud/mod.lua`. It does not install into the game, modify Local AppData, or create a release ZIP. Use `--output-dir DIRECTORY` for an isolated candidate. Use `--package-mdl` explicitly when an MDL ZIP is needed. `build_complete.py` still packages Complete explicitly.

## Check installed drift

```
python tools/audit_bundle.py PATH_TO_INSTALLED_MOD_LUA
```

The audit reports matching, different, and source-less embedded modules and the installed file hash. Differences require review; do not blindly import an installed module or deploy a rebuilt bundle over a tested runtime. The audit compares module bodies, not lifecycle adapters or resource packages, and is not a live rendering test.

## Rendering ownership

- `runtime.lua`: selects normal layout, ready weapon artwork, and protected fallback.
- `df_neogeo_atlas.lua`: owns atlas resource identities and the all-resources-ready check.
- `screen_scene.prepare_commands`: applies world styling, texture expansion, and preflight before native allocation.
- `hot_panel_art.lua` and runtime texture modules: own upload/publication/lifetime. Drawing code must not bypass their readiness checks.

## Remaining reconciliation

The installed runtime was being edited by another chat during this cleanup. Its reviewed modules still differ from source; no deployment was made here. The main contract suite now gets past its missing hot-panel dependency and stale menu/API assertions, but stops at the Airburst presentation marker assertion (tests/contracts.lua, Airburst live controls test). This remains unresolved; no accepted visuals or snapshots were changed. Rendering option-matrix, atlas, texture layers, theme, and owned-source checks pass independently. Do not treat the full contract suite as passing or update accepted snapshots merely to hide drift.
