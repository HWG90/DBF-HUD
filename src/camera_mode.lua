-- Read the game's accepted first-person toggle, never physical key presses.
-- The native toggle resolves the local player and changes one byte at +0x2EC.
local M={}
local signatures={{0xa42a74,'4c8b0ded398e02'},{0xa42b1f,'4138bc24ec020000'},{0xa42b2a,'41888424ec020000'}}
function M.read(backend,raw)
    local ok,value=pcall(function()
        assert(raw and raw.binding,'no current weapon identity')
        local r=HUD.memory.new(backend);r.reset()
        local base=raw.binding.module_base
        for _,s in ipairs(signatures) do
            local expected=s[2]:gsub('..',function(h)return string.char(tonumber(h,16))end)
            assert(r.read(base+s[1],#expected)==expected,'unknown first-person control binding')
        end
        local player=r.p(base+HUD.layouts.player)
        assert(r.u(r.read(player+0x3a8,4),0)==raw.avatar_unit_ref,'avatar changed')
        local local_record=r.p(player+0xe8);local local_data=r.read(local_record,24)
        assert(local_data:byte(21)%2==1 and r.map(player+0xd0,r.u(local_data,8),64)==0,'not local player slot')
        local flag=r.read(player+0x2ec,1):byte()
        assert(flag==0 or flag==1,'invalid first-person state')
        assert(r.p(base+HUD.layouts.player)==player and r.p(player+0xe8)==local_record and
            r.u(r.read(player+0x3a8,4),0)==raw.avatar_unit_ref,'avatar changed during mode read')
        return flag==1
    end)
    if ok then return value,'game first-person state' end
    return nil,tostring(value)
end
return M
