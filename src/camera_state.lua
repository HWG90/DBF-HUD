-- Research only: bounded snapshots from already verified camera/player roots.
-- Never drives placement and never calls engine functions or writes game memory.
local M={}
function M.capture(backend,raw,trace_code)
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
    part('player_header',player,0x380)
    part('camera_state_tail',state+512,512)
    local code_page=type(trace_code)=='string' and trace_code:match('^code_probe_(%d+)$')
    local avatar_page=type(trace_code)=='string' and trace_code:match('^avatar_page_(%d+)_')
    if code_page then
        code_page=tonumber(code_page);assert(code_page>=0 and code_page<384,'code probe bounds')
        for i=0,11 do
            local address=base+0x500000+code_page*49152+i*4096
            local data=r.read(address,4096)
            if data:find(string.char(0xec,2,0,0),1,true) then
                parts[#parts+1]={name=string.format('code_match_%x',address-base),address=address,data=data}
            end
        end
    elseif trace_code=='shoulder_code' then
        for i=0,11 do part('shoulder_code'..i,base+0xa46000+i*1024,1024) end
    elseif trace_code=='command_flags' then
        local manager=r.p(base+0x3326d20)
        local index=r.map(manager+0xf8,raw.binding.avatar_id,65536)
        assert(index and index<16,'no bounded command flags slot')
        local identity=r.p(manager+0x110+index*8)
        assert(identity==raw.binding.avatar_record,'command flags identity mismatch')
        part('command_flags',manager+0x53e880+index*0x1238,128)
        assert(r.p(base+0x3326d20)==manager and r.p(manager+0x110+index*8)==identity,'command flags owner changed')
    elseif trace_code=='camera_preferences' then
        local manager=r.p(base+0x347cdd8)
        for i=0,5 do part(string.format('camera_preferences_%x',0x89000+i*1024),manager+0x89000+i*1024,1024) end
        assert(r.p(base+0x347cdd8)==manager,'camera preferences owner changed')
    elseif trace_code=='avatar_control' or avatar_page then
        local manager=r.p(base+0x3326d20)
        local index=r.map(manager+0xf8,raw.binding.avatar_id,65536)
        assert(index and index<16,'no bounded avatar control slot')
        local identity=r.p(manager+0x110+index*8)
        assert(identity==raw.binding.avatar_record,'avatar control identity mismatch')
        if avatar_page then
            avatar_page=tonumber(avatar_page);assert(avatar_page>=0 and avatar_page<14,'avatar page bounds')
            for i=0,11 do
                local off=avatar_page*49152+i*4096
                if off<0xa7aec then part(string.format('avatar_control_%x',off),manager+index*0xa7aec+off,math.min(4096,0xa7aec-off)) end
            end
        else
            for _,off in ipairs({0x1800,0x1c00,0x3000,0x3400}) do
                part(string.format('avatar_control_%x',off),manager+index*0xa7aec+off,1024)
            end
        end
        assert(r.p(manager+0x110+index*8)==identity,'avatar control changed during snapshot')
    elseif trace_code=='wide_state' then
        for i=1,3 do part('player_tail'..i,player+i*1024,1024) end
    elseif trace_code=='control_links' then
        for _,off in ipairs({0x18,0x20}) do
            local address=r.p(player+off)
            part(string.format('player_link_%x',off),address,1024)
            assert(r.p(player+off)==address,'player link changed during snapshot')
        end
    elseif trace_code=='camera_links' then
        for _,off in ipairs({0x180,0x188,0x190,0x1a0}) do
            local address=r.p(state+off)
            part(string.format('camera_link_%x',off),address,512)
            assert(r.p(state+off)==address,'camera link changed during snapshot')
        end
    elseif trace_code then
        part('weapon_control_code',base+0x764e00,1024)
        part('player_control_code',base+0xa40000,1024)
        for i=1,24 do
            part('player_control_follow'..i,base+0xa40000+i*1024,1024)
        end
    end
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
