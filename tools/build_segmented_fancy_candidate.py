# Historical one-off review builder; use tools/build_lll.py for maintained modular HUD packages.
"""Build the Fancy instrument while preserving the installed runtime's extra modules."""
from pathlib import Path
import ctypes
import hashlib
import json
import os
import re
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'dist/segmented-fancy-primary-20261010'
INSTALLED = Path(os.environ['LOCALAPPDATA']) / 'LLL/Helldivers2/Mods/dbf_hud/mod.lua'
LUA_DLL = Path(r'C:\Program Files (x86)\Steam\steamapps\common\Helldivers 2\bin\lua51.dll')


def digest(data):
    return hashlib.sha256(data).hexdigest()


def module_span(bundle, name):
    starts = list(re.finditer(r'^HUD\.(\w+)=\(function\(\)\n', bundle, re.M))
    matches = [i for i, match in enumerate(starts) if match.group(1) == name]
    if len(matches) != 1:
        raise RuntimeError('Expected one installed module: ' + name)
    i = matches[0]
    end = starts[i + 1].start() if i + 1 < len(starts) else bundle.index('return (function()\n', starts[i].end())
    return starts[i].start(), end


def source(name):
    return (ROOT / 'src' / (name + '.lua')).read_text(encoding='utf-8')


def replace_once(text, old, new):
    if text.count(old) != 1:
        raise RuntimeError('Installed baseline no longer matches: ' + old.splitlines()[0])
    return text.replace(old, new, 1)


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    baseline = INSTALLED.read_bytes()
    live = baseline.decode('utf-8')
    # Config/menu replace only their own module boundaries. The source config
    # retains the installed owned-copy optimization in texture_policy.
    for name in ('config', 'menu'):
        start, end = module_span(live, name)
        live = live[:start] + 'HUD.' + name + '=(function()\n' + source(name) + '\nend)()\n' + live[end:]
    marker = 'HUD.hud_composition=(function()\n'
    if live.count(marker) != 1:
        raise RuntimeError('Current composition adapter unavailable; refusing broad replacement')
    modules = ''.join('HUD.' + name + '=(function()\n' + source(name) + '\nend)()\n' for name in ('segmented_primary_specs', 'segmented_fancy'))
    live = live.replace(marker, modules + marker, 1)
    # Reuse the same source composition block in the installed extracted adapter.
    runtime = source('runtime')
    start = runtime.index('        if HUD.segmented_fancy and HUD.config.segmented_eligible')
    end = runtime.index('        cfg=HUD.config.texture_policy(cfg)', start)
    block = runtime[start:end].replace('self.segmented_seen', 'owner.segmented_seen')
    block = block.replace("if backend.log then pcall(backend.log,", "if log then pcall(log,")
    anchor = "        if cfg.presentation_view=='third' then return HUD.view_presentation.compose(m,x,y,scale,opacity,cfg)end\n"
    live = replace_once(live, anchor, anchor + block)
    live = replace_once(live, '    self.config=HUD.config.new()\n',
        '    self.config=HUD.config.new()\n    if options and options.activate_segmented_fancy then self.config.segmented_fancy=true end\n')
    panel_anchor = '        local cfg=HUD.config.effective(self.config,resource)\n'
    panel_start = live.index('    function self.panel_settings(resource)')
    panel_end = live.index('    function self.configure_panel(values,resource)', panel_start)
    panel_block = live[panel_start:panel_end]
    panel_block = replace_once(panel_block, panel_anchor,
        panel_anchor + "        if self.config.hud_presentation~='practical'and HUD.config.segmented_eligible(cfg,resource)then return HUD.config.segmented_appearance(cfg,resource)end\n")
    live = live[:panel_start] + panel_block + live[panel_end:]
    configure_start = runtime.index('    function self.configure_panel(values,resource)')
    configure_end = runtime.index('    function self.export_tuning()', configure_start)
    old_start = live.index('    function self.configure_panel(values,resource)')
    old_end = live.index('    function self.export_tuning()', old_start)
    live = live[:old_start] + runtime[configure_start:configure_end] + live[old_end:]
    # Preserve the complete existing managed adapter, inserting only activation.
    live = replace_once(live, '        local backend=HUD.memory.native()\n',
        '        local backend=HUD.memory.native()\n        local settings_ok,previous_settings=pcall(backend.read_tuning)\n')
    old_startup = '        hud=HUD.runtime.start(sr,backend,{managed=true,screen_bone_hud=false,frame_trial=false})\n'
    new_mdl = source('mdl')
    activation_start = new_mdl.index('        local activate_segmented=')
    activation_end = new_mdl.index('        if backend.log then', activation_start)
    live = replace_once(live, old_startup, new_mdl[activation_start:activation_end])
    patched = live.encode('utf-8')
    target = OUTPUT / 'current-install/dbf_hud/mod.lua'
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(patched)
    subprocess.run([sys.executable, str(ROOT / 'tools/build.py'), '--output-dir', str(OUTPUT / 'maintained')], check=True)
    dll = ctypes.CDLL(str(LUA_DLL)); dll.luaL_newstate.restype = ctypes.c_void_p
    dll.luaL_loadfile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    dll.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]; dll.lua_tolstring.restype = ctypes.c_char_p
    dll.lua_close.argtypes = [ctypes.c_void_p]
    for lua in (target, OUTPUT / 'maintained/dist/dbf_hud.lua', OUTPUT / 'maintained/mdl/dbf_hud/mod.lua'):
        state = dll.luaL_newstate()
        try:
            if dll.luaL_loadfile(state, str(lua).encode()):
                raise RuntimeError(dll.lua_tolstring(state, -1, None).decode())
        finally:
            dll.lua_close(state)
    plan = {
        'scope': 'Fancy only; 54 verified named primary identities',
        'installed_baseline_sha256': digest(baseline), 'candidate_sha256': digest(patched),
        'installed_extra_modules_preserved': True, 'rectangular_backing': True,
        'shared_decoration_system': True, 'native_assets_required': False,
        'white_gold_navy': True, 'empty_red_counter_flash_hz': 2,
        'simple_artwork_changed': False, 'installed': False, 'live_visual_verified': False,
    }
    (OUTPUT / 'PLAN.json').write_text(json.dumps(plan, indent=2), encoding='utf-8')
    readme = (
        'Segmented Fancy primary HUD - 2026-10-10\n\n'
        'Fancy only. Rectangular independently translucent backing; white/gold/navy theme; native counts/units; '
        'red empty counter flashes at 2Hz. Borders are supplied by the existing Decorations selector. '
        'Simple, support weapons and sidearms retain their current artwork.\n\n'
        'The managed Lua preserves the installed composition/preview and screen-rendering updates. '
        'Back up the installed mod and tuning before replacing dbf_hud/mod.lua. On first enable, the new setting '
        'is activated and Fancy selected through the HUD settings API. Existing placements and legacy palettes remain. '
        'Disable Segmented Fancy primaries in Appearance to return to the existing renderer. '
        'No native assets, DLLs or texture uploads are added.\n'
    )
    (OUTPUT / 'README.txt').write_text(readme, encoding='utf-8')
    archive = OUTPUT / 'DBF-HUD-Segmented-Fancy-Primaries-20261010.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as package:
        package.write(target, 'dbf_hud/mod.lua')
        package.write(INSTALLED.parent / 'manifest.json', 'dbf_hud/manifest.json')
        package.write(OUTPUT / 'README.txt', 'README.txt')
        package.write(OUTPUT / 'PLAN.json', 'PLAN.json')
    with zipfile.ZipFile(archive) as package:
        assert package.testzip() is None
    if INSTALLED.read_bytes() != baseline:
        raise RuntimeError('Installed HUD changed during build; rebuild before deploying')
    print(archive)
    print('Managed/current-install and maintained Lua syntax passed; ZIP integrity passed. Nothing deployed.')


if __name__ == '__main__':
    main()
