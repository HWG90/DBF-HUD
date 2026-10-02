# Development, deployment and troubleshooting

## Build and validate

Run from the source checkout:

```powershell
python tests/run.py
python tools/build.py
```

`tests/run.py` loads `tests/contracts.lua` with the game's LuaJIT DLL and stops on a contract failure. Override the DLL using `--lua-dll`. The October 1 checkpoint has 93 contracts covering model/layout, numerical display, guarded reads, lifecycle, profiles, editor save/reset/scale/attachments, menu behavior and edge-triggered occlusion notice behavior.

`tools/build.py` generates the startup bundle, loose MDL bundle and parent-directory MDL ZIP. `--addon-builder` can generate an Arsenal addon through the external Bingus builder. Font conversion/depth asset builders are separate tools; normal Lua build does not rebuild deployed native assets.

## Install Lua without replacing layouts

Current local deployment:

```powershell
$hudSource = '<your HUD checkout>'
$hudTarget = Join-Path $env:LOCALAPPDATA 'MDL/Helldivers2/Mods/dbf_hud/mod.lua'
Copy-Item -LiteralPath (Join-Path $hudSource 'mdl/dbf_hud/mod.lua') -Destination $hudTarget -Force
```

MDL auto reload is enabled in this development setup, but verify it rather than assuming it on another machine. Prefer a staged replacement/manual Reload if partial reads are possible. Never copy repository tuning or offsets as part of routine code deployment.

Disable the competing packaged startup HUD before enabling the loose MDL mod. A compatibility global takeover is not sufficient proof that two separately loaded startup/render paths are inactive.

New shaders/materials/font assets require normal asset deployment and possibly a restart. A later Arsenal deployment can overwrite a direct game-file patch; update the package selected in Arsenal too.

## Where data lives

| Data | Location |
| --- | --- |
| Live global tuning | Game root / DBF-HUD-tuning.lua |
| Live weapon profiles | Game root / DBF-HUD-weapon-offsets.lua |
| HUD log | Game root / DBF-HUD.log |
| Research log | Game root / DBF-HUD-camera.log |
| Loose MDL Lua | %LOCALAPPDATA%/MDL/Helldivers2/Mods/dbf_hud/mod.lua |
| MDL lifecycle log | %LOCALAPPDATA%/MDL/Helldivers2/Logs/MDL.log |
| Native bindings log | %LOCALAPPDATA%/CowboyBingus/Helldivers2/Logs/ModBindingsMenu.log |

A runtime restart resets the HUD log. Preserve interesting signal captures before reload. Do not publish personal settings, native captures, logs or private test tooling as part of documentation.

## Live acceptance checklist

1. One HUD instance; disabling MDL removes it, enabling restores it.
2. Weapon identity/count/reserves and alternate modes are correct.
3. Inspect first- and third-person aim, released aim and relevant reload/vent states.
4. Check sight clearance, receiver placement, frame bounds, native text/icons and occlusion.
5. Edit position, scale and bone; F7 confirms readable weapon/view; reload and verify persistence.
6. Bind Force occlusion in Change Bindings > Mods > Debug tools - DBF HUD; press, observe debug notice and depth behavior.

Offline contracts establish code behavior. Native GPU rendering, memory signals and weapon placement require live evidence. A user-confirmed visual result is distinct from a structurally valid asset package.

## Common failures

- **Settings revert:** a repository example or stale runtime save replaced live tuning/profiles. Restore backup, retire stale editor, reload.
- **No native shortcut row:** check installed ModBindingsMenu and registration log, then close/reopen the bindings page. No default shortcut is assigned; bind it yourself.
- **Double HUD:** competing startup and loose MDL installations. Disable one and deploy cleanly.
- **Text renders but decorations disappear:** verify combined native text/decorations depth assets, not only menu selection.
- **Fuel bar stuck empty:** verify both live fuel count and capacity. Cremator capacity was corrected to 500 for its resource deposit.
- **First-person HUD disappears after copying third-person offsets:** camera-specific base mounts differ; inspect and tune each camera.
- **Wrong alternate icon:** follow active ammo type, not only the weapon's base catalog category.
- **Reader fails after update:** revalidate build signatures and owned components. Do not patch bounds or guesses just to suppress errors.

For unresolved signals, capture same-weapon released/held/returned states with labeled samples and stable identity. Avoid mixing damage, reload, equip or expired capture windows with the state being isolated.
