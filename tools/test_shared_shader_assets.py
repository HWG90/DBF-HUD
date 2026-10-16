"""Verify standalone closure and both mod load orders against source bytes."""
import struct
from shared_shader_assets import (GROUP, SHADER, complete_hud_resources,
                                 merge_shader_closure, photo_module, shared_resources)

def registry(rows):
    groups = [r for r in rows if r[1] == GROUP]
    assert len(groups) == 1
    body = groups[0][2]; n = struct.unpack_from('<I', body, 16)[0]
    ids = struct.unpack_from('<%dQ' % n, body, 24)
    assert len(set(ids)) == len(ids)
    return set(ids)

def main():
    hud, ha = complete_hud_resources()
    photo, _, pa = photo_module().resources()
    assert ha == pa['shader_compatibility']
    for rows in (hud, photo):
        assert len(registry(rows)) == ha['registry_ids']
        assert {r[0] for r in rows if r[1] == SHADER} <= registry(rows)
    for first, last in ((hud, photo), (photo, hud)):
        mounted = {r[:2]: r for r in first}
        mounted.update({r[:2]: r for r in last})
        assert registry(list(mounted.values())) == registry(hud)
        for row in first + last:
            if row[1] == SHADER:
                assert mounted[row[:2]] == row, 'Load order changed a shader program'
    stock = bytes(16) + struct.pack('<IIQ', 1, 0, 7)
    a = (9, SHADER, b'cpu', b'gpu')
    try:
        merge_shader_closure([a], [(9, SHADER, b'cpu', b'changed')], stock)
    except ValueError:
        pass
    else:
        raise AssertionError('Conflicting same-ID shader accepted')
    merged, _ = merge_shader_closure([a], [(10, SHADER, b'cpu', b'new')], stock)
    assert registry(merged) == {7, 9, 10}, 'New companion shader omitted'
    print('PASS standalone closure, both load orders, new shader preservation and conflict rejection:', ha)

if __name__ == '__main__':
    main()
