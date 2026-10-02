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
    function self.snapshot(raw,research,anchor_hash,enumerate)
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
        local sight,selected_hash;local anchors={}
        -- Optional named anchor; any unavailable or changing table keeps root fallback.
        local sight_ok,sight_value=pcall(function()
            assert(nodes<=128,'sight node limit')
            local hashes=r.p(object+0xa0);local data=r.read(hashes,nodes*4)
            for n=0,nodes-1 do
                local hash=r.u(data,n*4)
                if enumerate then anchors[#anchors+1]={index=n,hash=string.format('%08x',hash)} end
                if hash==(anchor_hash or 0x4d25685a) or (not anchor_hash and hash==0x527c9c73 and selected_hash~=0x4d25685a) then
                    local pose=r.read(address+n*64,64);local delta={}
                    for j=1,3 do delta[j]=r.f(pose,(11+j)*4)-matrix[12+j];assert(math.abs(delta[j])<5,'sight bounds') end
                    assert(r.p(object+0xa0)==hashes and r.read(hashes,nodes*4)==data,'sight table changed')
                    local node_matrix={}
                    for j=1,16 do node_matrix[j]=r.f(pose,(j-1)*4) end
                    for _,k in ipairs({1,5,9}) do
                        local norm=0;for j=0,2 do norm=norm+node_matrix[k+j]^2 end
                        assert(math.abs(norm-1)<.05,'attachment axis scale')
                    end
                    local result={index=n,matrix=node_matrix}
                    for axis,k in ipairs({1,5,9}) do
                        local v=0;for j=1,3 do v=v+delta[j]*matrix[k+j-1] end
                        result[({'x','y','z'})[axis]]=v
                    end
                    sight=result
                    selected_hash=hash
                end
            end
        end)
        if not sight_ok then sight=nil;anchors={} end
        local node_parts
        if research then
            assert(nodes<=128,'research node limit')
            node_parts={{name='weapon_identity',address=b.record,data=r.read(b.record,24)},{name='weapon_scene_header',address=object+0x60,data=r.read(object+0x60,128)}}
            -- Native node lookup (+0x6d8) uses scene+0x40; parent lookup
            -- (+0x500) uses scene+0x38. Scene accessor returns object+0x60.
            local node_hashes=r.p(object+0xa0);local parents=r.p(object+0x98)
            node_parts[#node_parts+1]={name='weapon_scene_node_hashes',address=node_hashes,data=r.read(node_hashes,nodes*4)}
            node_parts[#node_parts+1]={name='weapon_scene_parents',address=parents,data=r.read(parents,nodes*4)}
            assert(r.p(object+0xa0)==node_hashes and r.p(object+0x98)==parents and r.u(r.read(object+0x70,4),0)==nodes,'scene tables changed')
            local scene_resource=r.p(object+0x68)
            node_parts[#node_parts+1]={name='weapon_scene_resource',address=scene_resource,data=r.read(scene_resource,512)}
            for first=0,nodes-1,64 do
                local at=address+first*64
                node_parts[#node_parts+1]={name='weapon_nodes_'..first,address=at,data=r.read(at,math.min(64,nodes-first)*64)}
            end
            if research~='avatar' then
            local resource_getter=r.p(r.p(object)+0x1b0)
            local resource_code=r.read(resource_getter,64)
            node_parts[#node_parts+1]={name='weapon_resource_accessor',address=resource_getter,data=resource_code}
            assert(resource_code:sub(1,8)==unhex('488b8178010000c3'),'unknown weapon resource accessor')
            local resource=r.p(object+0x178);local names=r.p(resource+0x28)
            local header=r.read(names,32);local count=r.u(header,0x14);local offset=r.u(header,0x18)
            node_parts[#node_parts+1]={name='weapon_resource_header',address=resource,data=r.read(resource,256)}
            node_parts[#node_parts+1]={name='weapon_lookup_table_header',address=names,data=header}
            assert(count<=128 and offset<0x100000,'lookup table bounds')
            if count>0 then node_parts[#node_parts+1]={name='weapon_lookup_hashes',address=names+offset,data=r.read(names+offset,count*4)} end
            assert(r.p(object+0x178)==resource and r.p(resource+0x28)==names,'weapon resource changed')
            node_parts[#node_parts+1]={name='weapon_object_header',address=object,data=r.read(object,96)}
            if research=='api' then
                for off=0x4f8,0x700,8 do
                    local ok,entry=pcall(function()local fn=r.p(unit_api+off);return {name=string.format('weapon_api_%x',off),address=fn,data=r.read(fn,128)} end)
                    if ok then node_parts[#node_parts+1]=entry end
                end
            end
            local lookup=r.p(unit_api+0x3b0)
            node_parts[#node_parts+1]={name='weapon_node_lookup_code',address=lookup,data=r.read(lookup,512)}
            end
        end
        -- Revalidate both ends after the read; no persistent entity/matrix pointer cache.
        local record=r.read(b.record,24)
        assert(r.u(record,8)==raw.id and r.u(record,12)==b.candidate and r.u(record,16)==raw.unit_ref,'weapon changed')
        assert(r.read(generations+index,1):byte()==generation and r.p(array+index*8)==object,'unit recycled during read')
        assert(r.u(r.read(object+8,4),0)==b.candidate and r.p(object+0x88)==address,'pose owner changed')
        return {id=raw.id,resource_hex=raw.resource_hex,candidate=b.candidate,node_count=nodes,
            node_parts=node_parts,sight=sight,anchors=anchors,matrix=matrix,x=matrix[13],y=matrix[14],z=matrix[15]}
    end
    function self.poll(raw,anchor_hash,enumerate)
        local ok,value=pcall(self.snapshot,raw,nil,anchor_hash,enumerate)
        if not ok then self.status=tostring(value);return nil end
        self.status='verified root pose';self.samples=self.samples+1;return value
    end

    return self
end
return M
