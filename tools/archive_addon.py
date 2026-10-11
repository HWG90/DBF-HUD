"""Local Shared Loader Lua addon packager; never installs files."""
import json
import struct
import zipfile
from pathlib import Path
from build_native_font_depth import hash64
from build_scene_depth_probe import archive_rows


def build_addon(name, source, guid, output):
    source = bytes(source)
    body, gpu = archive_rows([
        (hash64(name), hash64('lua'), struct.pack('<II', len(source), 2) + source, b'')
    ])
    assert not gpu
    output = Path(output)
    output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as package:
        package.writestr('manifest.json', json.dumps({
            'Version': 1, 'Guid': guid, 'Author': 'Goose',
            'Name': name, 'Options': [{'Name': 'Addon', 'Include': ['Addon']}]
        }))
        stem = 'Addon/9ba626afa44a3aa3.patch_0'
        package.writestr(stem, body)
        package.writestr(stem + '.stream', b'')
        package.writestr(stem + '.gpu_resources', b'')
    with zipfile.ZipFile(output) as package:
        assert package.testzip() is None
    return output
