-- Read-only selected-weapon root pose. Native code is inspected, never invoked.
-- See WEAPON_BINDING.md. Unknown implementations or recycled handles fail closed.
local M={}
local function unhex(s) return (s:gsub('..',function(h)return string.char(tonumber(h,16))end)) end
local pose_prefix=unhex('40534883ec204863da')
local pose_suffix=unhex('488bc84c8b0041ff90e8000000488bcb48c1e10648034828488bc14883c4205bc3')
local resolver_prefix=unhex('48895c24084889742410574883ec20488b35')
local resolver_body=unhex('8bc325ffff3f003b8698000000720433dbeb1c8bc8488b86a0000000c1eb16381c0175eb488b8688000000488b1cc8')
function M.new(backend)
    local r=HUD.memory.new(backend)
    local self={status='not sampled',samples=0}
    function self.snapshot(raw)
        assert(raw and raw.binding,'no weapon binding')
        local b=raw.binding;r.reset()
        -- The reader must validate the game build before returning this binding.
        local api=r.p(b.module_base+0x3326308);local unit_api=r.p(api+0x18)
        local getter=r.p(unit_api+0x90);local code=r.read(getter,48)
        assert(code:sub(1,9)==pose_prefix and code:byte(10)==0xe8 and code:sub(15,47)==pose_suffix,'unknown pose getter')
        local resolver=getter+14+r.i(code,10);code=r.read(resolver,116)
        assert(code:sub(1,18)==resolver_prefix and code:sub(0x26,0x54)==resolver_body,'unknown unit resolver')
        local registry=r.p(resolver+0x16+r.i(code,0x12))
        local cap=r.u(r.read(registry+0x98,4),0);assert(cap>0 and cap<=0x400000,'unit capacity')
        local index=b.candidate%0x400000;local generation=math.floor(b.candidate/0x400000)%256
        assert(index>0 and index<cap,'unit index')
        local array=r.p(registry+0x88);local generations=r.p(registry+0xa0)
        assert(r.read(generations+index,1):byte()==generation,'recycled unit')
        local object=r.p(array+index*8)
        assert(r.u(r.read(object+8,4),0)==b.candidate,'unit identity')
        local accessor=r.p(r.p(object)+0xe8)
        assert(r.read(accessor,5)==unhex('488d4160c3'),'unknown scene accessor')
        local nodes=r.u(r.read(object+0x70,4),0);assert(nodes>0 and nodes<=4096,'node count')
        local address=r.p(object+0x88);local bytes=r.read(address,64);local matrix={}
        for i=1,16 do matrix[i]=r.f(bytes,(i-1)*4) end
        for _,i in ipairs({4,8,12}) do assert(math.abs(matrix[i])<1e-5,'matrix affine row') end
        assert(math.abs(matrix[16]-1)<1e-5,'matrix homogeneous component')
        for _,k in ipairs({1,5,9}) do
            local norm=0;for j=0,2 do norm=norm+matrix[k+j]^2 end
            assert(math.abs(norm-1)<.05,'matrix axis scale')
        end
        for _,pair in ipairs({{1,5},{1,9},{5,9}}) do
            local dot=0;for j=0,2 do dot=dot+matrix[pair[1]+j]*matrix[pair[2]+j] end
            assert(math.abs(dot)<.05,'matrix axes')
        end
        for i=13,15 do assert(math.abs(matrix[i])<1e7,'matrix position') end
        -- Revalidate both ends after the read; no persistent entity/matrix pointer cache.
        local record=r.read(b.record,24)
        assert(r.u(record,8)==raw.id and r.u(record,12)==b.candidate and r.u(record,16)==raw.unit_ref,'weapon changed')
        assert(r.read(generations+index,1):byte()==generation and r.p(array+index*8)==object,'unit recycled during read')
        assert(r.u(r.read(object+8,4),0)==b.candidate and r.p(object+0x88)==address,'pose owner changed')
        return {id=raw.id,resource_hex=raw.resource_hex,candidate=b.candidate,node_count=nodes,
            matrix=matrix,x=matrix[13],y=matrix[14],z=matrix[15]}
    end
    function self.poll(raw)
        local ok,value=pcall(self.snapshot,raw)
        if not ok then self.status=tostring(value);return nil end
        self.status='verified root pose';self.samples=self.samples+1;return value
    end
    return self
end
return M
