local Memory,Layout=HUD.memory,HUD.layouts
local M={}
local function flag(v,b) return math.floor(v/b)%2==1 end
local function valid(v,limit) return v>=0 and v<=limit end
function M.new(backend)
    local r=Memory.new(backend);local base;local checked=false
    local self={status='starting'}
    local rpm_cache
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
            local i=r.map(m+(spec[4] or 0x68),id,65536)
            if i then assert(i<4096,'override index');return r.read(r.p(m+(spec[5] or 0xa8))+i*spec[3],spec[3]) end
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
                if valid(c,5000) then
                    local resource=string.format('%08x%08x',r.u(rec,4),r.u(rec,0))
                    return c,HUD.ammo_types.deposit_capacity(resource)
                end
            end)
            if ok and v then
                local resource=string.format('%08x%08x',r.u(rec,4),r.u(rec,0))
                return v,HUD.ammo_types.deposit_capacity(resource)
            end
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
        local main_rec,main_wid,main_address=rec,wid,record_address
        local control_address,active_mode
        local control_ok,address,mode=pcall(function()
            assert(r.read(base+0x75673a,7)==string.char(0x4c,0x8b,0x15,0x9f,0x05,0xbd,0x02),'weapon control getter binding')
            local control_manager=r.p(base+0x3326ce0)
            local control_index=component(control_manager,0x30,0x48,wid,rec)
            if not control_index then return nil end
            local count=r.u(r.read(control_manager+0x20,4),0)
            assert(count<=4096 and control_index<count,'weapon control bounds')
            local at=r.p(control_manager+0x60)+control_index*12
            return at,r.u(r.read(at,4),0)
        end)
        if control_ok then control_address,active_mode=address,mode end
        if active_mode==8 then
            local auxiliary=r.p(base+0x3326a38)
            local index=r.map(auxiliary+0x278,wid,4096)
            if not index or index>=4096 or not si then return nil,'alternate ammunition unavailable' end
            local state=r.read(r.p(auxiliary+0x2a0)+index*128,128)
            local ammo_id=r.u(state,0x64)
            local selector=r.read(r.p(sm+0x60)+si*0x1d0,5*0x50)
            local attached=false
            for slot=0,4 do
                if r.u(selector,slot*0x50)==wid and r.u(selector,slot*0x50+4)==ammo_id then attached=true end
            end
            if not attached then return nil,'alternate weapon attachment mismatch' end
            local ammo_rec,ammo_address=entity(owner,ammo_id)
            if not ammo_rec then return nil,'alternate weapon missing' end
            local owner_manager=r.p(base+0x3326730)
            local oi=component(owner_manager,0x18,0x30,ammo_id,ammo_rec)
            if not oi or r.u(r.read(r.p(owner_manager+0x38)+oi*4,4),0)~=aid then return nil,'alternate weapon owner mismatch' end
            wid,rec,record_address=ammo_id,ammo_rec,ammo_address
        end
        local driver=global('driver');local di=component(driver,0x28,0x40,wid,rec)
        if not di then return nil,'no weapon driver' end
        local driver_state=r.read(r.p(driver+0x50)+di*40,40)
        local flags=r.u(driver_state,0)
        local result={id=main_wid,unit_ref=r.u(main_rec,16),avatar_unit_ref=unit,resource_hex=string.format('%08x%08x',r.u(main_rec,4),r.u(main_rec,0)),lowered=lowered,alternate=mounted,reloadable=flag(flags,0x40)}
        if wid~=main_wid then result.ammo_resource_hex=string.format('%08x%08x',r.u(rec,4),r.u(rec,0));result.alternate_fire=true end
        -- Diagnostic values only. +0x0C is not yet a verified engine/Lua handle.
        -- All bytes below were already read for ownership and ammo selection.
        result.binding={module_base=base,record=main_address,candidate=r.u(main_rec,12),
            avatar_id=aid,avatar_record=owner+Layout.records+ai*24,avatar_candidate=r.u(avatar,12),driver_state=driver_state}
        local kind=flag(flags,0x80) and 'magazine' or flag(flags,0x100) and 'rounds' or flag(flags,0x200) and 'heat'
        -- Talon exposes round bookkeeping alongside its heat component.
        -- Prefer heat only when that component belongs to the selected entity.
        if result.resource_hex=='416d053372c4e433' then
            local hm=global('heat')
            if component(hm,0x28,0x40,wid,rec) then kind='heat' end
        end
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
                result.binding.ammo_state=st
                result.binding.ammo_runtime=rt
                result.binding.driver_flags=flags
                local sel=mag and 0 or r.u(rt,4);assert(sel<=1,'magazine selection')
                result.ammo_slot=sel
                if not mag and cfg then
                    result.projectile_type=r.u(cfg,0x40+sel*4)
                    result.binding.ammo_types=cfg:sub(0x40+1,0x48)
                end
                local chambered=cfg and cfg:byte((mag and 0x9c or 0x68)+1)==1
                local chamber=chambered and r.u(st,mag and 8 or 16)>0 and 1 or 0
                result.rounds=r.i(st,mag and 0 or 4+sel*4)+chamber
                result.chamber_rounds=chamber
                result.chamber_supported=chambered==true
                assert(valid(result.rounds,5001),'ammo range')
                if cfg then
                    local capacity=mag and r.u(cfg,0x88) or r.f(cfg,0x48+sel*4)
                    if valid(capacity,5000) and capacity>=1 then result.capacity=capacity end
                    -- A full replacement magazine reserves its chamber round before
                    -- the bolt animation completes. Observed runtime +8 clears on chambering.
                    if mag and chambered and chamber==0 and result.capacity and result.capacity>1 and
                        result.rounds==result.capacity-1 and rt:byte(9)==1 then
                        result.pending_chamber_round=1
                        result.rounds=result.rounds+1
                    end
                end
                -- Autocannon tube reload reserves the fifth clip round until chambering.
                -- Live rounds runtime +16 is set during that stage and clears on chambering.
                if not mag and result.resource_hex=='a8cffb316f0b5c5f' and chambered and
                    chamber==0 and result.rounds==4 and rt:byte(17)==1 then
                    result.pending_chamber_round=1
                    result.rounds=result.rounds+1
                end
                local reserve=r.i(rt,0)
                local reserve_max=cfg and r.u(cfg,mag and 0x94 or 0x50)
                if valid(reserve,100000) and (not reserve_max or reserve_max>0) then
                    result.reserve=reserve;result.reserve_kind=mag and 'MAGS' or 'ROUNDS'
                end
                -- Inventory ownership plus the matching pack resource survives respawns;
                -- adjacent entity IDs alone do not identify an autocannon backpack.
                local autocannon=result.resource_hex=='a8cffb316f0b5c5f'
                if autocannon or (cfg and reserve_max==0 and not mounted) then
                    for off=12,24,4 do
                        local bid=r.u(inventory,off)
                        local matches=not autocannon and bid==wid+1
                        if autocannon and bid~=wid then
                            local pack=entity(owner,bid)
                            matches=pack and string.format('%08x%08x',r.u(pack,4),r.u(pack,0))=='e60ae045e0090f4c'
                        end
                        if matches then
                            local count=deposit(owner,bid)
                            if count~=nil then result.reserve=count;result.reserve_kind='PACK';break end
                        end
                    end
                end
            end
        elseif flag(flags,0x400) then
            result.kind='resource'
            for _,off in ipairs(Layout.resource) do
                local ok,count,capacity=pcall(function()
                    local m=r.p(base+off);local i=component(m,0x20,0x38,wid,rec)
                    if not i then return nil end
                    local provider=r.u(r.read(r.p(m+0x48)+i*36,36),0)
                    return deposit(owner,provider)
                end)
                if ok and count then result.rounds=count;result.capacity=capacity;break end
            end
            if not result.rounds then return nil,'resource provider unavailable' end
        else return nil,'unsupported ammo component' end
        do
            -- Optional mode metadata must not suppress otherwise valid ammunition.
            local ok,mode,fire_mode,safety_mode=pcall(function()
                assert(r.read(base+0x75673a,7)==string.char(0x4c,0x8b,0x15,0x9f,0x05,0xbd,0x02),'ammo control getter binding')
                local manager=r.p(base+0x3326ce0)
                local index=component(manager,0x30,0x48,main_wid,main_rec)
                if not index then return nil end
                local count=r.u(r.read(manager+0x20,4),0)
                assert(count<=4096 and index<count,'ammo control bounds')
                local controls=r.read(r.p(manager+0x60)+index*12,12)
                result.binding.ammo_controls=controls
                assert(r.read(main_address,24)==main_rec,'ammo control weapon changed')
                local mode=result.resource_hex=='a8cffb316f0b5c5f' and HUD.ammo_types.autocannon_mode(r.u(controls,4)) or nil
                if result.resource_hex=='9f80d67a12a7e40f' then mode=HUD.ammo_types.recoilless_mode(r.u(controls,4)) end
                local settings=config('weapon_data',manager,main_wid,main_rec,owner)
                local choices=settings and {r.u(settings,0x90),r.u(settings,0x94),r.u(settings,0x98)}
                local fire_mode=result.alternate_fire and 'ALT' or HUD.ammo_types.selectable_fire_mode(r.u(controls,0),choices)
                local safety_mode=result.resource_hex=='2e9d0bdc48b09e60' and ({[5]='SAFE',[6]='UNSAFE'})[r.u(controls,0)] or nil
                return mode,fire_mode,safety_mode
            end)
            if ok then result.ammo_mode=mode;result.fire_mode=fire_mode;result.safety_mode=safety_mode end
        end
        do
            local ok,rpm=pcall(function()
                assert(r.read(base+0x617974,7)=='\072\139\029\093\237\208\002','RPM selector binding')
                local manager=r.p(base+0x33266d8)
                local count=r.u(r.read(manager+0x38,4),0)
                assert(count>0 and count<=384,'RPM component bounds')
                local entities=r.p(manager+0x68)
                local index
                if rpm_cache and rpm_cache.manager==manager and rpm_cache.index<count and
                    r.p(entities+rpm_cache.index*8)==main_address then index=rpm_cache.index end
                if not index then
                    local pointers=r.read(entities,count*8)
                    for i=0,count-1 do
                        local ptr=r.u(pointers,i*8)+r.u(pointers,i*8+4)*2^32
                        if ptr==main_address then index=i;break end
                    end
                end
                if not index then return nil end
                rpm_cache={manager=manager,index=index}
                local data=r.read(r.p(manager+0x70)+index*0x20,0x20)
                local selected=r.u(data,0x1c);assert(selected<3,'RPM selected index')
                local enabled=0
                for i=0,2 do local rate=r.f(data,0x10+i*4);assert(rate>=0 and rate<=10000,'RPM slot range');if rate>0 then enabled=enabled+1 end end
                if enabled<2 then return nil end
                local rate=r.f(data,0x10+selected*4)
                assert(rate>0 and r.read(main_address,24)==main_rec,'RPM weapon changed')
                assert(r.read(r.p(manager+0x70)+index*0x20+0x1c,4)==data:sub(29,32),'RPM selection changed')
                return rate
            end)
            if ok and rpm then result.rpm=rpm;result.rpm_selectable=true end
        end
        if result.resource_hex=='2e9d0bdc48b09e60' then
            local ok,charge=pcall(function()
                -- Verified native getter: manager +0x40, 40-byte records, first float.
                assert(r.read(base+0x745b85,14)==string.char(0x8b,0xc8,0x49,0x8b,0x43,0x40,0x48,0x8d,0x14,0x89,0xf3,0x0f,0x10,0x04),'charge getter binding')
                local manager=r.p(base+0x3326c20)
                local index=component(manager,0x20,0x38,main_wid,main_rec)
                if not index then return nil end
                local count=r.u(r.read(manager+0x10,4),0)
                assert(count<=4096 and index<count,'charge component bounds')
                local data=r.read(r.p(manager+0x40)+index*40,40)
                local value=r.f(data,0)
                assert(value>=0 and value<=10,'charge value range')
                assert(r.read(main_address,24)==main_rec,'charge weapon changed')
                return value
            end)
            if ok and charge then
                result.charge_fraction=math.min(1,charge)
                -- Provisional visual-test threshold, not a verified firing deadline.
                result.charge_warning=charge>=.95
            end
        end
        if control_address then assert(r.u(r.read(control_address,4),0)==active_mode,'fire mode changed during snapshot') end
        self.status='ok';return HUD.ammo_types.apply(result)
    end
    function self.poll()
        local ok,value,reason=pcall(self.snapshot)
        if not ok then self.status=tostring(value);return nil end
        self.status=reason or 'ok';return value
    end
    return self
end
return M
