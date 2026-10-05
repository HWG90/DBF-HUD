"""Offline checks for shared modules, adapter isolation and stale artifact detection."""
import importlib.util
from pathlib import Path
import tempfile
import unittest
spec = importlib.util.spec_from_file_location('hud_build', Path(__file__).parents[1] / 'tools/build.py')
build = importlib.util.module_from_spec(spec)
spec.loader.exec_module(build)

class BundleTests(unittest.TestCase):
    def test_adapters_share_modules_and_keep_lifecycle_separate(self):
        products = build.render_bundles()
        startup = products['dist/dbf_hud.lua']
        managed = products['mdl/dbf_hud/mod.lua']
        start = startup.index('local HUD={}\n')
        end = startup.index('local ok,result=pcall(function() return HUD.runtime.start')
        common = startup[start:end]
        self.assertIn(common, managed)
        self.assertEqual(common.count('HUD.runtime=(function()'), 1)
        self.assertEqual(common.count('HUD.faithful_fragments=(function()'), 1)
        self.assertIn('MDL API 2 required', managed[len(common):])
        self.assertNotIn('on_enable=function(ctx)', startup)

    def test_check_detects_stale_without_overwriting(self):
        with tempfile.TemporaryDirectory() as folder:
            root = Path(folder)
            target = build.bundle(root)
            self.assertEqual(build.bundle(root, check=True), target)
            target.write_bytes(b'stale')
            with self.assertRaisesRegex(SystemExit, 'Stale generated bundles'):
                build.bundle(root, check=True)
            self.assertEqual(target.read_bytes(), b'stale')
            self.assertEqual(set(p.relative_to(root).as_posix() for p in root.rglob('*') if p.is_file()),
                             {'dist/dbf_hud.lua', 'mdl/dbf_hud/mod.lua'})

if __name__ == '__main__':
    unittest.main()
