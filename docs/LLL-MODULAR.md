# Modular LLL review package

Build with `py -3 tools/build_lll.py`. Output is `dist/releases/modular-20261010`; LLL R30 or later is required. The package uses `main.lua`, separate modules and `config/defaults.cfg`. Existing archive builders and installed mods are unchanged.

HUD tuning/layout files retain their established Local AppData/DBF location. Shipped defaults can be overridden in config/defaults.cfg. dbfhud.global.opacity is percent; scalar settings use normal HUD units. Normal artwork assets remain a separate prerequisite.

Modules compile and constructors are checked in an isolated LuaJIT process. Activation, input, visuals and resource lifetime still need game validation. This work does not deploy the package.
