-- Research only: bounded snapshots from already verified camera/player roots.
-- Never drives placement and never calls engine functions or writes game memory.
local M={}
function M.capture(backend,raw)
    assert(raw and raw.binding,'no identity-checked selected weapon')
    local r=HUD.memory.new(backend);r.reset()
    local base=raw.binding.module_base
    local state=r.p(base+0x346d560);local camera=r.p(state)
    local player=r.p(base+HUD.layouts.player)
    assert(r.u(r.read(player+0x3a8,4),0)==raw.avatar_unit_ref,'avatar changed before camera snapshot')
    local parts={}
    local function part(name,address,n)
        parts[#parts+1]={name=name,address=address,data=r.read(address,n)}
    end
    part('camera_state',state,512);part('camera',camera,160)
    part('player_view',player+0x380,128)
    local selector=r.p(base+HUD.layouts.selector)
    local index=r.map(selector+0x30,raw.binding.avatar_id,1048576)
    if index then
        local count=r.u(r.read(selector+0x18,4),0);assert(index<count and count<=262144,'selector bounds')
        local identity=r.p(r.p(selector+0x48)+index*8)
        assert(identity==raw.binding.avatar_record,'selector avatar record changed')
        assert(r.u(r.read(identity+8,4),0)==raw.binding.avatar_id,'selector avatar identity changed')
        part('selector',r.p(selector+0x60)+index*0x1d0,0x1d0)
        assert(r.p(r.p(selector+0x48)+index*8)==identity,'selector changed during snapshot')
    end
    assert(r.p(base+0x346d560)==state and r.p(state)==camera,'camera changed during snapshot')
    assert(r.p(base+HUD.layouts.player)==player and r.u(r.read(player+0x3a8,4),0)==raw.avatar_unit_ref,'avatar changed during snapshot')
    return parts
end
return M
