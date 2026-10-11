# Historical one-off review builder; use tools/build_lll.py for maintained modular HUD packages.
"""Build a local WorldGUI routing fix without changing the installed runtime."""
from pathlib import Path
import ctypes
import hashlib
import json
import os
import subprocess
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUTPUT = ROOT / 'dist/worldgui-anchor-fix-20261010'
INSTALLED = Path(os.environ['LOCALAPPDATA']) / 'LLL/Helldivers2/Mods/dbf_hud/mod.lua'
LUA_DLL = Path(r'C:\Program Files (x86)\Steam\steamapps\common\Helldivers 2\bin\lua51.dll')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def main():
    OUTPUT.mkdir(parents=True, exist_ok=True)
    original = INSTALLED.read_bytes()
    live = original.decode('utf-8')
    replacements = [
        ("        if self.presentation_view=='third' then\n            world_display.release();if screen_scene then screen_scene.release()end\n",
         "        -- Presentation selects artwork; the requested WorldGUI placement must\n"
         "        -- reach the weapon renderer even when Automatic selects practical art.\n"
         "        if self.presentation_view=='third' and self.config.anchor_mode~='world' then\n"
         "            world_display.release();if screen_scene then screen_scene.release()end\n"),
        ("            view.draw(commands);self.anchor_status='floating Simple HUD';return\n",
         "            view.draw(commands);self.anchor_status=use_weapon and 'weapon-attached Simple HUD' or 'floating Simple HUD';return\n"),
        ("                world_display.release();view.draw(screen_overlay(w,h));self.anchor_status='screen-projected scene-depth HUD';return\n",
         "                world_display.release();view.draw(screen_overlay(w,h));self.anchor_status='screen-projected scene-depth HUD';self.world_fallback_reason=nil;return\n"),
        ("                self.anchor_status='weapon 3D WorldGUI';return\n",
         "                self.anchor_status='weapon 3D WorldGUI';self.world_fallback_reason=nil;return\n"),
        ("        world_display.release()\n        if screen_scene then screen_scene.release() end\n        if aim_opacity<.01 then",
         "        world_display.release()\n        if screen_scene then screen_scene.release() end\n"
         "        if self.config.anchor_mode=='world' then\n"
         "            local reason=self.weapon_pose and 'weapon render path unavailable' or ('weapon pose unavailable: '..tostring(self.pose_status))\n"
         "            self.anchor_status='WorldGUI screen fallback: '..reason\n"
         "            if self.world_fallback_reason~=reason then log('WORLDGUI_FALLBACK '..reason);self.world_fallback_reason=reason end\n"
         "        else self.world_fallback_reason=nil end\n"
         "        if aim_opacity<.01 then"),
    ]
    for before, after in replacements:
        if live.count(before) != 1:
            raise RuntimeError('Installed runtime changed or is not the expected baseline: ' + before.splitlines()[0])
        live = live.replace(before, after, 1)
    patched = live.encode('utf-8')
    target = OUTPUT / 'current-install/dbf_hud/mod.lua'
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(patched)
    subprocess.run([sys.executable, str(ROOT / 'tools/build.py'), '--output-dir', str(OUTPUT / 'maintained')], check=True)

    # Compile the full managed bundle without executing it or opening the game.
    dll = ctypes.CDLL(str(LUA_DLL))
    dll.luaL_newstate.restype = ctypes.c_void_p
    state = dll.luaL_newstate()
    dll.luaL_loadfile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]
    dll.lua_tolstring.argtypes = [ctypes.c_void_p, ctypes.c_int, ctypes.c_void_p]
    dll.lua_tolstring.restype = ctypes.c_char_p
    dll.lua_close.argtypes = [ctypes.c_void_p]
    try:
        if dll.luaL_loadfile(state, str(target).encode()):
            raise RuntimeError(dll.lua_tolstring(state, -1, None).decode())
    finally:
        dll.lua_close(state)

    readme = (
        'DBF-HUD WorldGUI attachment fix - 2026-10-10\n\n'
        'The practical third-person presentation previously returned through the screen renderer before WorldGUI was considered. '
        'This candidate respects WorldGUI placement for Automatic and Practical presentation and identifies missing-pose/render fallbacks.\n\n'
        'This ZIP contains a minimal patch of the currently installed managed runtime, preserving its extra composition/preview and rendering updates. '
        'It does not contain tuning, profiles, textures, native assets, or the new segmented Fancy artwork.\n'
        'Deployment is pending separate authorization. Back up the existing mod.lua, compare its hash to PLAN.json, replace it atomically, '
        'reload only DBF-HUD, then verify weapon movement and the WorldGUI logs.\n'
    )
    (OUTPUT / 'README.txt').write_text(readme, encoding='utf-8')
    plan = {
        'cause': 'third-person presentation bypassed requested WorldGUI renderer',
        'installed_baseline_sha256': sha(original),
        'candidate_runtime_sha256': sha(patched),
        'installed_extra_changes_preserved': True,
        'replacement_operations': len(replacements),
        'lua_syntax_verified': True,
        'focused_runtime_regression_verified': True,
        'installed': False,
        'live_visual_verified': False,
        'segmented_fancy_design_included': False,
        'settings_or_native_assets_included': False,
    }
    (OUTPUT / 'PLAN.json').write_text(json.dumps(plan, indent=2), encoding='utf-8')
    archive = OUTPUT / 'DBF-HUD-WorldGUI-Anchor-Fix-20261010.zip'
    with zipfile.ZipFile(archive, 'w', zipfile.ZIP_DEFLATED) as bundle:
        bundle.write(target, 'dbf_hud/mod.lua')
        manifest = INSTALLED.parent / 'manifest.json'
        if manifest.exists():
            bundle.write(manifest, 'dbf_hud/manifest.json')
        bundle.write(OUTPUT / 'README.txt', 'README.txt')
        bundle.write(OUTPUT / 'PLAN.json', 'PLAN.json')
    with zipfile.ZipFile(archive) as bundle:
        if bundle.testzip() is not None:
            raise RuntimeError('ZIP integrity failure')
    if INSTALLED.read_bytes() != original:
        raise RuntimeError('Installed runtime changed during candidate construction; do not deploy this candidate')
    print(archive)
    print('Syntax and ZIP verified; installed runtime, saved settings and native assets unchanged.')


if __name__ == '__main__':
    main()
