local HUD={}
HUD.memory=(function()
-- Private FFI symbols prevent collisions with other addons' declarations.
local M={}
function M.native()
    local ffi=require('ffi')
    pcall(ffi.cdef, [[
    void *dbf_hud_module(const char*) __asm__("GetModuleHandleA");
    void *dbf_hud_process(void) __asm__("GetCurrentProcess");
    int dbf_hud_read(void*,const void*,void*,size_t,size_t*) __asm__("ReadProcessMemory");
    unsigned long dbf_hud_filename(void*,char*,unsigned long) __asm__("GetModuleFileNameA");
    ]])
    local k=ffi.load('kernel32'); local process=k.dbf_hud_process()
    local buffer=ffi.new('uint8_t[4096]');local got=ffi.new('size_t[1]')
    local file,log_size;local log_attempted=false
    local backend={
        module=function(name) local p=k.dbf_hud_module(name); if p~=nil then return tonumber(ffi.cast('uintptr_t',p)) end end,
        read=function(address,size)
            if address<65536 or address+size>=2^47 or size<1 or size>4096 then return nil end
            got[0]=0
            if k.dbf_hud_read(process,ffi.cast('const void*',address),buffer,size,got)==0 or tonumber(got[0])~=size then return nil end
            return ffi.string(buffer,size)
        end
    }
    function backend.log(line)
        if not log_attempted then
            log_attempted=true
            local buf=ffi.new('char[4096]');local n=tonumber(k.dbf_hud_filename(nil,buf,4096))
            if n and n>0 and n<4096 then
                local exe=ffi.string(buf,n):gsub('\\','/')
                local root=exe:match('^(.*)/[Bb][Ii][Nn]/[^/]+$')
                if root then backend.log_path=root..'/DBF-HUD.log';file=io.open(backend.log_path,'w') end
            end
            log_size=0
        end
        if file and log_size<512*1024 then
            file:write(line..'\n');file:flush();log_size=log_size+#line+1
        end
    end
    local function tuning_path()
        local buf=ffi.new('char[4096]');local n=tonumber(k.dbf_hud_filename(nil,buf,4096))
        assert(n>0 and n<4096,'executable path unavailable')
        local root=ffi.string(buf,n):gsub('\\','/'):match('^(.*)/[Bb][Ii][Nn]/[^/]+$')
        assert(root,'game installation root unavailable')
        return root..'/DBF-HUD-tuning.lua'
    end
    function backend.camera_log_path() return tuning_path():gsub('DBF%-HUD%-tuning.lua$','DBF-HUD-camera.log') end
    function backend.camera_request()
        local path=tuning_path():gsub('DBF%-HUD%-tuning.lua$','DBF-HUD-camera-request.txt')
        local file=io.open(path,'r');if not file then return nil end
        local label=file:read(65);file:close();assert(os.remove(path),'camera request acknowledgement failed')
        assert(#label<=64 and label:match('^[%w_%-]+%s*$'),'invalid camera snapshot label')
        return label:match('^[%w_%-]+')
    end
    function backend.read_tuning()
        local path=tuning_path();local f=io.open(path,'r')
        -- Compatibility: old settings are readable; writes use the new filename.
        if not f then path=path:gsub('DBF%-HUD%-tuning.lua$','AstraAmmo-tuning.lua');f=io.open(path,'r') end
        if not f then return nil end
        local body=f:read(65537);f:close();assert(#body<=65536,'tuning file too large')
        local chunk=assert(loadstring(body,'@'..path));setfenv(chunk,{})
        local values=chunk();assert(type(values)=='table','tuning file must return a table')
        return values
    end
    function backend.write_tuning(body)
        local path=tuning_path();local tmp=path..'.tmp'
        local f=assert(io.open(tmp,'w'));local ok,err=f:write(body);local closed,cerr=f:close()
        assert(ok and closed,err or cerr)
        -- Windows rename cannot replace an existing file; keep a recoverable backup.
        local previous=io.open(path,'r')
        if previous then previous:close();os.remove(path..'.bak');assert(os.rename(path,path..'.bak')) end
        local moved,why=os.rename(tmp,path)
        if not moved then os.rename(path..'.bak',path);error(why) end
        return path
    end
    function backend.close() if file then file:close();file=nil end end
    return backend
end
function M.new(backend)
    local r={reads=0,bytes=0}
    function r.reset() r.reads,r.bytes=0,0 end
    function r.read(a,n)
        assert(type(a)=='number' and a==a and a%1==0 and a>=65536 and a+n<2^47,'invalid address')
        assert(n>0 and n<=4096,'invalid read size')
        r.reads,r.bytes=r.reads+1,r.bytes+n
        assert(r.reads<=512 and r.bytes<=65536,'read budget exceeded')
        local s=backend.read(a,n); assert(s and #s==n,'unreadable memory');return s
    end
    function r.u(s,o)
        local a,b,c,d=s:byte(o+1,o+4);assert(d,'short uint32');return a+b*256+c*65536+d*16777216
    end
    function r.i(s,o) local v=r.u(s,o);return v>=2^31 and v-2^32 or v end
    function r.f(s,o)
        local v=r.u(s,o);local sign=v>=2^31 and -1 or 1
        local e=math.floor(v/2^23)%256;local m=v%2^23
        assert(e~=255,'nonfinite float')
        return sign*(e==0 and m*2^-149 or (1+m/2^23)*2^(e-127))
    end
    function r.p(a)
        local s=r.read(a,8);local p=r.u(s,0)+r.u(s,4)*2^32
        assert(p>=65536 and p<2^47,'invalid pointer');return p
    end
    function r.map(a,key,limit)
        local h=r.read(a,20);local n,empty,mult=r.u(h,8),r.u(h,12),r.u(h,16)
        if n==0 or key==empty or key==0xffffffff then return nil end
        assert(n<=limit and n>0,'invalid map capacity')
        local pow=n;while pow>1 and pow%2==0 do pow=pow/2 end
        assert(pow==1,'invalid map capacity')
        local p=r.p(a)
        -- Split multiplication keeps the low 32 bits exact under Lua doubles.
        local start=((key%65536)*(mult%65536)+((math.floor(key/65536)*(mult%65536)+(key%65536)*math.floor(mult/65536))%65536)*65536)%2^32
        for probe=0,math.min(n,128)-1 do
            local row=r.read(p+((start+probe)%n)*8,8);local k=r.u(row,0)
            if k==empty then return nil end
            if k==key then local index=r.u(row,4);if index~=0xffffffff then return index end;return nil end
        end
        error('map probe limit')
    end
    return r
end
return M

end)()
HUD.layouts=(function()
-- Reference facts: Reticle Ammo HUD 1.1.0, Steam 25327279 and September 24 PE.
-- No layout is guessed on unknown builds. Offsets relative to game.dll.
return {
    stamps={[0x6AA96B14]=0x4770000,[0x6AB3B43F]=0x4744000},
    player=0x3326468,owner=0x346BF98,inventory=0x3326738,driver=0x3326660,
    selector=0x3326420,magazine=0x3326648,rounds=0x3326CF0,heat=0x3326D48,
    entity_map=0xF1AEB0,unit_map=0xF22EC8,records=0xF32F18,
    deposit={0x33265F0,0x33265E8},resource={0x3326AA0,0x3326AA8,0x3326A98,0x3326AB0},
    static={magazine={0xF124A0,540,160},rounds={0xF12820,50,0x88},heat={0xF12CC8,58,0x250}},
    signatures={
        {0x607200,'488b0561f2d10283b88400000000'},
        {0x6066ed,'8b9410a8030000'},
        {0xfd9c93,'4c8b15fe224902'},
        {0xfd9cc5,'498b9ac82ef200'},
        {0xfd9d83,'498b9ab0aef100'},
        {0x9a83e0,'4c8b1551e39702'},
        {0x745db6,'488b1da308be02'},
        {0x744dc2,'4c8b0d271fbe02'},
        {0x744d02,'488b2d3f19be02'},
        {0x764efa,'4c8b15471ebc02'},
        {0x764f79,'8bc8498b4258488d1449807c9008000f94c0'}
    }
}

end)()
HUD.reader=(function()
local Memory,Layout=HUD.memory,HUD.layouts
local M={}
local function flag(v,b) return math.floor(v/b)%2==1 end
local function valid(v,limit) return v>=0 and v<=limit end
function M.new(backend)
    local r=Memory.new(backend);local base;local checked=false
    local self={status='starting'}
    local function global(name) return r.p(base+Layout[name]) end
    local function component(m,map,registry,id,record)
        local index=r.map(m+map,id,65536)
        if not index then return nil end
        assert(index<4096,'component index')
        assert(r.read(r.p(r.p(m+registry)+index*8),24)==record,'component identity')
        return index
    end
    local function entity(owner,id)
        if not id or id==0 or id==0xffffffff then return nil end
        local index=r.map(owner+Layout.entity_map,id,1048576)
        if not index then return nil end
        assert(index<1048576,'entity index')
        local rec=r.read(owner+Layout.records+index*24,24)
        assert(r.u(rec,8)==id,'entity identity');return rec,owner+Layout.records+index*24
    end
    local function config(kind,m,id,rec,owner)
        local spec=Layout.static[kind]
        if kind~='magazine' then
            local i=r.map(m+0x68,id,65536)
            if i then assert(i<4096,'override index');return r.read(r.p(m+0xa8)+i*spec[3],spec[3]) end
        end
        local p=r.p(owner+spec[1]);local n=spec[2];local key=rec:sub(1,8)
        local home=((r.u(rec,4)%n)*(2^32%n)+r.u(rec,0)%n)%n
        for probe=0,math.min(n,128)-1 do
            local row=r.read(p+((home+probe)%n)*16,16)
            if row:sub(1,8)==string.rep('\0',8) then return nil end
            if row:sub(1,8)==key then
                local i=r.u(row,8);assert(i<n and r.u(row,12)==0,'config index')
                return r.read(p+n*16+i*spec[3],spec[3])
            end
        end
        return nil
    end
    local function deposit(owner,id)
        local rec=entity(owner,id);if not rec then return nil end
        for _,off in ipairs(Layout.deposit) do
            local ok,v=pcall(function()
                local m=r.p(base+off);local i=component(m,0x20,0x38,id,rec)
                if not i then return nil end
                local c=r.i(r.read(r.p(m+0x50)+i*8,8),0)
                if valid(c,5000) then return c end
            end)
            if ok and v then return v end
        end
    end
    function self.validate()
        r.reset();base=backend.module('game.dll');assert(base,'game.dll not loaded')
        local dos=r.read(base,64);assert(dos:sub(1,2)=='MZ','DOS signature')
        local pe=r.u(dos,0x3c);assert(pe<0x100000,'PE offset')
        local header=r.read(base+pe,0x80)
        assert(header:sub(1,4)=='PE\0\0','PE signature')
        assert(Layout.stamps[r.u(header,8)]==r.u(header,0x50),'unsupported game build')
        for _,s in ipairs(Layout.signatures) do
            local bytes=s[2]:gsub('..',function(h) return string.char(tonumber(h,16)) end)
            assert(r.read(base+s[1],#bytes)==bytes,'layout signature mismatch')
        end
        checked=true;self.status='validated'
    end
    function self.snapshot()
        if not checked then self.validate() end
        r.reset()
        local pm=global('player');local n=r.read(pm+0x84,8)
        if r.u(n,0)==0 or r.u(n,4)==0 then return nil,'no local player' end
        local pl=r.read(r.p(pm+0xe8),24)
        assert(flag(pl:byte(21),1) and r.map(pm+0xd0,r.u(pl,8),64)==0,'local ownership')
        local unit=r.u(r.read(pm+0x3a8,4),0)
        if unit==0x7fff then return nil,'no avatar' end
        local owner=global('owner');local ai=r.map(owner+Layout.unit_map,unit,1048576)
        if not ai then return nil,'no avatar entity' end
        assert(ai<1048576,'avatar index')
        local avatar=r.read(owner+Layout.records+ai*24,24);local aid=r.u(avatar,8)
        assert(r.u(avatar,16)==unit and flag(avatar:byte(21),1),'avatar identity')
        local inv=global('inventory');local ii=component(inv,0x28,0x40,aid,avatar)
        if not ii then return nil,'no inventory' end
        assert(ii<r.u(r.read(inv+0x14,4),0),'inventory index')
        local inventory=r.read(r.p(inv+0x50)+ii*48,48);local slot=r.u(inventory,28)
        local offset=({[1]=0,[2]=4,[3]=8,[4]=16,[5]=16,[6]=12})[slot]
        local wid=offset and r.u(inventory,offset);local inventory_weapon=wid
        local lowered=false;local mounted=false
        local sm=global('selector');local si=r.map(sm+0x30,aid,1048576)
        if si then
            local live=r.u(r.read(sm+0x18,4),0);local cap=r.u(r.read(sm+0x10,4),0)
            assert(live<=cap and live<=262144 and si<live,'selector bounds')
            assert(r.read(r.p(r.p(sm+0x48)+si*8),24)==avatar,'selector identity')
            local at=r.p(sm+0x60)+si*0x1d0;local selected=r.u(r.read(at,4),0)
            -- Selector interpolation rates are NOT a reliable movement visibility signal.
            if selected~=0 and selected~=0xffffffff and selected~=aid then
                wid=selected;mounted=wid~=inventory_weapon
            end
        end
        local rec,record_address=entity(owner,wid);if not rec then return nil,'no selected weapon' end
        -- The machine gun uses the identity-checked magazine path below. Its
        -- inherited exclusion was removed after bounded live component checks.
        assert(mounted or flag(rec:byte(21),1),'weapon ownership')
        local driver=global('driver');local di=component(driver,0x28,0x40,wid,rec)
        if not di then return nil,'no weapon driver' end
        local flags=r.u(r.read(r.p(driver+0x50)+di*40,40),0)
        local result={id=wid,unit_ref=r.u(rec,16),avatar_unit_ref=unit,resource_hex=string.format('%08x%08x',r.u(rec,4),r.u(rec,0)),lowered=lowered,alternate=mounted,reloadable=flag(flags,0x40)}
        -- Diagnostic values only. +0x0C is not yet a verified engine/Lua handle.
        -- All bytes below were already read for ownership and ammo selection.
        result.binding={module_base=base,record=record_address,candidate=r.u(rec,12),
            avatar_id=aid,avatar_record=owner+Layout.records+ai*24,avatar_candidate=r.u(avatar,12)}
        local kind=flag(flags,0x80) and 'magazine' or flag(flags,0x100) and 'rounds' or flag(flags,0x200) and 'heat'
        if kind then
            local m=global(kind);local mag=kind=='magazine'
            local i=component(m,mag and 0x20 or 0x28,mag and 0x38 or 0x40,wid,rec)
            if not i then return nil,'ammo component missing' end
            local cfg=config(kind,m,wid,rec,owner);result.kind=kind
            if kind=='heat' then
                local rt=r.read(r.p(m+0x58)+i*12,12)
                if not cfg then return nil,'heat calibration missing' end
                local limit=r.f(cfg,0x60);local heat=r.f(rt,4)
                assert(limit>0 and limit<1e7 and heat>=-1 and heat<1e7,'heat range')
                result.heat=math.max(0,math.min(1,heat/limit));result.locked=rt:byte(9)==1
                local sinks=r.i(rt,0)
                if valid(sinks,1000) and r.u(cfg,0x5c)>0 then result.reserve=sinks;result.reserve_kind='SINKS' end
            else
                local st=r.read(r.p(m+(mag and 0x48 or 0x50))+i*(mag and 16 or 24),mag and 16 or 24)
                local rt=r.read(r.p(m+(mag and 0x50 or 0x58))+i*(mag and 12 or 20),mag and 12 or 20)
                local sel=mag and 0 or r.u(rt,4);assert(sel<=1,'magazine selection')
                local chambered=cfg and cfg:byte((mag and 0x9c or 0x68)+1)==1
                local chamber=chambered and r.u(st,mag and 8 or 16)>0 and 1 or 0
                result.rounds=r.i(st,mag and 0 or 4+sel*4)+chamber
                assert(valid(result.rounds,5001),'ammo range')
                if cfg then
                    local capacity=mag and r.u(cfg,0x88) or r.f(cfg,0x48+sel*4)
                    if valid(capacity,5000) and capacity>=1 then result.capacity=math.max(capacity,result.rounds) end
                end
                local reserve=r.i(rt,0)
                local reserve_max=cfg and r.u(cfg,mag and 0x94 or 0x50)
                if valid(reserve,100000) and (not reserve_max or reserve_max>0) then
                    result.reserve=reserve;result.reserve_kind=mag and 'MAGS' or 'ROUNDS'
                end
                -- Only a known spawned pair is used; arbitrary backpacks never become reserve.
                if cfg and reserve_max==0 and not mounted then
                    for off=12,24,4 do
                        local bid=r.u(inventory,off)
                        if bid==wid+1 then result.reserve=deposit(owner,bid);result.reserve_kind='PACK' end
                    end
                end
            end
        elseif flag(flags,0x400) then
            result.kind='resource'
            for _,off in ipairs(Layout.resource) do
                local ok,count=pcall(function()
                    local m=r.p(base+off);local i=component(m,0x20,0x38,wid,rec)
                    if not i then return nil end
                    local provider=r.u(r.read(r.p(m+0x48)+i*36,36),0)
                    return deposit(owner,provider)
                end)
                if ok and count then result.rounds=count;break end
            end
            if not result.rounds then return nil,'resource provider unavailable' end
        else return nil,'unsupported ammo component' end
        self.status='ok';return result
    end
    function self.poll()
        local ok,value,reason=pcall(self.snapshot)
        if not ok then self.status=tostring(value);return nil end
        self.status=reason or 'ok';return value
    end
    return self
end
return M

end)()
HUD.pose=(function()
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
    function self.snapshot(raw,research)
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
        local sight
        -- Optional named anchor; any unavailable or changing table keeps root fallback.
        local sight_ok,sight_value=pcall(function()
            assert(nodes<=128,'sight node limit')
            local hashes=r.p(object+0xa0);local data=r.read(hashes,nodes*4)
            for n=0,nodes-1 do
                if r.u(data,n*4)==0x527c9c73 then
                    local pose=r.read(address+n*64,64);local delta={}
                    for j=1,3 do delta[j]=r.f(pose,(11+j)*4)-matrix[12+j];assert(math.abs(delta[j])<5,'sight bounds') end
                    assert(r.p(object+0xa0)==hashes and r.read(hashes,nodes*4)==data,'sight table changed')
                    local result={index=n}
                    for axis,k in ipairs({1,5,9}) do
                        local v=0;for j=1,3 do v=v+delta[j]*matrix[k+j-1] end
                        result[({'x','y','z'})[axis]]=v
                    end
                    return result
                end
            end
        end)
        if sight_ok then sight=sight_value end
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
            node_parts=node_parts,sight=sight,matrix=matrix,x=matrix[13],y=matrix[14],z=matrix[15]}
    end
    function self.poll(raw)
        local ok,value=pcall(self.snapshot,raw)
        if not ok then self.status=tostring(value);return nil end
        self.status='verified root pose';self.samples=self.samples+1;return value
    end
    return self
end
return M

end)()
HUD.camera_state=(function()
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

end)()
local backend,reader,file,next_poll= nil,nil,nil,0
local function cleanup() if file then file:close();file=nil end;backend=nil;reader=nil end
return {
 name='DBF-HUD Camera Research',version='0.1',author='DBF-HUD',
 description='Read-only, on-request camera state snapshots. No HUD or camera changes.',
 on_enable=function(ctx)
  ctx.on_cleanup(cleanup);backend=HUD.memory.native();reader=HUD.reader.new(backend)
  file=assert(io.open(backend.camera_log_path(),'a'))
  file:write('CAMERA_RESEARCH enabled\n');file:flush()
 end,
 on_update=function(ctx,dt)
  next_poll=next_poll-(dt or 0);if next_poll>0 then return end;next_poll=1
  local hud=rawget(_G,'DBFHUD');if not hud or not hud.config or not hud.config.debug_logging then return end
  local label=backend.camera_request();if not label then return end
  if label=='camera_apis' or label=='weapon_node_apis' then
   local sr=rawget(_G,'stingray') or {};local names={}
   for name,namespace in pairs(sr) do
    if type(name)=='string' and (name:lower():find('camera',1,true) or name:lower():find('input',1,true) or name:lower():find('player',1,true) or name:lower():find('controller',1,true) or (label=='weapon_node_apis' and name=='Unit')) then
     names[#names+1]=name
     if type(namespace)=='table' then local entries={};for key,value in pairs(namespace) do if type(value)=='function' then entries[#entries+1]=tostring(key) end end;table.sort(entries)
      file:write('CAMERA_API '..name..' '..table.concat(entries,' ')..'\n')
     end
    end
   end
   table.sort(names);file:write('CAMERA_API namespaces '..table.concat(names,' ')..'\nCAMERA_CAPTURE complete label='..label..'\n');file:flush();return
  end
  local probe=label=='trace_code' or (label:find('wide_state',1,true) and 'wide_state')
  if label:find('camera_links',1,true) then probe='camera_links' end
  if label:find('control_links',1,true) then probe='control_links' end
  if label:match('^code_probe_%d+$') then probe=label end
  if label:find('avatar_control',1,true) then probe='avatar_control' end
  if label:match('^avatar_page_%d+_') then probe=label end
  if label:find('shoulder_code',1,true) then probe='shoulder_code' end
  if label:find('command_flags',1,true) then probe='command_flags' end
  if label:find('camera_preferences',1,true) then probe='camera_preferences' end
  local ok,parts
  if label:find('avatar_nodes',1,true) then
   ok,parts=pcall(function()
    local raw=assert(reader.poll());local b=raw.binding
    local r=HUD.memory.new(backend);local rec=r.read(b.avatar_record,24)
    assert(r.u(rec,8)==b.avatar_id and r.u(rec,12)==b.avatar_candidate and r.u(rec,16)==raw.avatar_unit_ref,'avatar identity changed')
    return HUD.pose.new(backend).snapshot({id=b.avatar_id,unit_ref=raw.avatar_unit_ref,
     binding={module_base=b.module_base,record=b.avatar_record,candidate=b.avatar_candidate}},'avatar').node_parts
   end)
  elseif label:find('weapon_nodes',1,true) then
   ok,parts=pcall(function()return HUD.pose.new(backend).snapshot(reader.poll(),label:find('unit_api',1,true) and 'api' or true).node_parts end)
  else ok,parts=pcall(HUD.camera_state.capture,backend,reader.poll(),probe) end
  if ok then
   for _,part in ipairs(parts) do
    local hex=part.data:gsub('.',function(ch)return string.format('%02X',ch:byte())end)
    file:write(string.format('CAMERA_CAPTURE label=%s part=%s address=0x%X hex=%s\n',label,part.name,part.address,hex))
   end
   file:write('CAMERA_CAPTURE complete label='..label..'\n')
  else file:write('CAMERA_CAPTURE failure label='..label..' '..tostring(parts)..'\n') end
  file:flush()
 end,
 on_disable=cleanup,
}
