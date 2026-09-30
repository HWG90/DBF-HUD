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
    if trace_code then
        part('weapon_control_code',base+0x764e00,1024)
        part('player_control_code',base+0x607100,1024)
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
  if label=='camera_apis' then
   local sr=rawget(_G,'stingray') or {};local names={}
   for name,namespace in pairs(sr) do
    if type(name)=='string' and (name:lower():find('camera',1,true) or name:lower():find('input',1,true) or name:lower():find('player',1,true) or name:lower():find('controller',1,true)) then
     names[#names+1]=name
     if type(namespace)=='table' then local entries={};for key,value in pairs(namespace) do if type(value)=='function' then entries[#entries+1]=tostring(key) end end;table.sort(entries)
      file:write('CAMERA_API '..name..' '..table.concat(entries,' ')..'\n')
     end
    end
   end
   table.sort(names);file:write('CAMERA_API namespaces '..table.concat(names,' ')..'\nCAMERA_CAPTURE complete label='..label..'\n');file:flush();return
  end
  local ok,parts=pcall(HUD.camera_state.capture,backend,reader.poll(),label=='trace_code')
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
