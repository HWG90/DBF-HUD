HUD={}
for _,name in ipairs({'native_font_data','native_font_uv','native_font','config','font','motion','ammo_types','model','fire_icons','munition_art','mg_easter','df_shell_state','recoilless_state','senator_state','senator_panel','doom_easter','melta_panel','speargun_panel','recoilless_panel','catalog_housing','shared_suite','weapon_styles','layout','memory','layouts','reader','pose','camera_mode','projection','camera_state','anchor','view','pose_motion','world_probe','depth_marker','offscreen_test','world_style','archived_mesh','scene_test','screen_scene','placement','weapon_names','weapon_offsets','layout_editor','menu','runtime'}) do HUD[name]=assert(loadfile('src/'..name..'.lua'))() end
local tests=0
local function test(name,f) f();tests=tests+1;print('PASS '..name) end
local cfg={follow=1,travel=55,settle=0.22}
test('spring is frame-rate invariant',function()
    local values={}
    for _,fps in ipairs({30,60,144}) do
        local s=HUD.motion.new();HUD.motion.step(s,nil,0,cfg)
        for i=1,fps do HUD.motion.step(s,{x=40,y=-20},1/fps,cfg) end
        values[#values+1]=s.x
    end
    assert(math.abs(values[1]-values[3])<1e-8)
end)
test('travel envelope survives impulses and direction reversals',function()
    local s=HUD.motion.new()
    for i=1,2000 do
        HUD.motion.step(s,{x=math.sin(i*0.06)*5000,y=math.cos(i*0.09)*5000},1/144,cfg)
        assert(s.x*s.x+s.y*s.y<=55*55+1e-6)
    end
end)
test('stale anchor returns to center and long stalls reset velocity',function()
    local s=HUD.motion.new();HUD.motion.step(s,{x=30,y=20},0,cfg)
    for i=1,60 do HUD.motion.step(s,nil,1/60,cfg) end
    assert(math.abs(s.x)<0.001)
    HUD.motion.step(s,{x=-40,y=0},1,cfg);assert(s.x==-40 and s.vx==0)
end)
test('unknown ammo is not zero; heat and empty semantics',function()
    assert(HUD.model.normalize({kind='magazine'})==nil)
    local m=HUD.model.normalize({kind='magazine',rounds=0,reserve=0});assert(m.state=='EMPTY' and m.reserve==0)
    assert(HUD.model.normalize({kind='heat',heat=0/0})==nil)
    assert(HUD.model.normalize({kind='heat',heat=0.92,locked=true}).state=='VENT')
end)
local ffi=require('ffi')
local bytes={};local nextaddr=0x10000000;local regions={}
local function alloc(n) local a=nextaddr;nextaddr=nextaddr+n+32;regions[#regions+1]={a,a+n};return a end
local function put(a,s) for i=1,#s do bytes[a+i-1]=s:byte(i) end end
local function u(v) local b={};for i=1,4 do b[i]=string.char(v%256);v=math.floor(v/256) end;return table.concat(b) end
local function U(a,v) put(a,u(v)) end
local function P(a,v) put(a,u(v)..u(0)) end
local function F(a,v) local b=ffi.new('float[1]',v);put(a,ffi.string(b,4)) end
local function read(a,n)
    local b={}
    for i=0,n-1 do
        local value=bytes[a+i]
        if value==nil then
            for _,region in ipairs(regions) do if a+i>=region[1] and a+i<region[2] then value=0;break end end
        end
        if value==nil then return nil end
        b[#b+1]=string.char(value)
    end
    return table.concat(b)
end
local base=0x100000;local L=HUD.layouts
put(base,'MZ'..string.rep('\0',62));U(base+0x3c,0x100)
put(base+0x100,'PE\0\0'..string.rep('\0',124));U(base+0x108,0x6AB3B43F);U(base+0x150,0x4744000)
for _,s in ipairs(L.signatures) do put(base+s[1],s[2]:gsub('..',function(h)return string.char(tonumber(h,16))end)) end
local function map(a,pairs_)
    local p=alloc(64);P(a,p);U(a+8,8);U(a+12,0xffffffff);U(a+16,1)
    for i=0,7 do U(p+i*8,0xffffffff) end
    for k,v in pairs(pairs_) do local pos=k%8;while read(p+pos*8,4)~=u(0xffffffff) do pos=(pos+1)%8 end;U(p+pos*8,k);U(p+pos*8+4,v) end
end
local function manager(name,n) local a=alloc(n or 512);P(base+L[name],a);return a end
local owner=manager('owner',0xF40000)
local avatar=owner+L.records;local weapon=avatar+24
U(avatar+8,10);U(avatar+16,77);bytes[avatar+20]=1
U(weapon,123);U(weapon+8,20);bytes[weapon+20]=1
map(owner+L.unit_map,{[77]=0});map(owner+L.entity_map,{[10]=0,[20]=1})
local pm=manager('player',0x500);U(pm+0x84,1);U(pm+0x88,1);P(pm+0xe8,avatar);map(pm+0xd0,{[10]=0});U(pm+0x3a8,77)
local function bind(m,mo,ro,id,rec)
    map(m+mo,{[id]=0});local p=alloc(8);P(m+ro,p);P(p,rec)
end
local inv=manager('inventory');bind(inv,0x28,0x40,10,avatar);U(inv+0x14,1)
local inventory=alloc(48);P(inv+0x50,inventory);U(inventory,20);U(inventory+28,1)
local selector=manager('selector');bind(selector,0x30,0x48,10,avatar);U(selector+0x18,1);U(selector+0x10,1)
local selection=alloc(0x1d0);P(selector+0x60,selection);U(selection,20);F(selection+0x1ac,1.5);F(selection+0x1b0,3)
local driver=manager('driver');bind(driver,0x28,0x40,20,weapon);local flags=alloc(40);P(driver+0x50,flags)
local mags=manager('magazine');bind(mags,0x20,0x38,20,weapon)
local state=alloc(24);local runtime=alloc(20);P(mags+0x48,state);P(mags+0x50,runtime)
local spec=L.static.magazine;local tablebase=alloc(spec[2]*16+spec[3]);P(owner+spec[1],tablebase)
put(tablebase+(123%spec[2])*16,u(123)..u(0)..u(0)..u(0))
local config=tablebase+spec[2]*16;U(config+0x88,45);U(config+0x94,7);bytes[config+0x9c]=1
local backend={module=function()return base end,read=read}
local reader=HUD.reader.new(backend)
test('known build signatures accepted',function() reader.validate() end)

test('isolated camera helper compiles without running game APIs',function()
    assert(loadfile('dist/dbf_camera_research.lua'))
end)

test('camera research snapshots are bounded and reject stale ownership',function()
    local cs=alloc(1024);local cam=alloc(160);P(base+0x346d560,cs);P(cs,cam)
    local raw={avatar_unit_ref=77,binding={module_base=base,avatar_id=10,avatar_record=avatar}}
    local total=0;local b={read=function(a,n)assert(n<=1024);total=total+n;return read(a,n)end}
    local parts=HUD.camera_state.capture(b,raw);assert(#parts==6 and total<4096)
    assert(parts[1].name=='camera_state' and #parts[1].data==512)
    assert(parts[6].name=='selector' and #parts[6].data==0x1d0)
    U(pm+0x3a8,78);assert(not pcall(HUD.camera_state.capture,b,raw));U(pm+0x3a8,77)
    local changed=false
    b.read=function(a,n)
        local value=read(a,n)
        if a==cam and not changed then changed=true;P(cs,cam+16)end
        return value
    end
    assert(not pcall(HUD.camera_state.capture,b,raw));P(cs,cam)
end)

test('expanded avatar control pages stay bounded and reject ownership changes',function()
    local manager=alloc(0xa7aec);P(base+0x3326d20,manager)
    map(manager+0xf8,{[10]=0});P(manager+0x110,avatar)
    local raw={avatar_unit_ref=77,binding={module_base=base,avatar_id=10,avatar_record=avatar}}
    local total=0;local b={read=function(a,n)assert(n<=4096);total=total+n;return read(a,n)end}
    local parts=HUD.camera_state.capture(b,raw,'avatar_page_0_test')
    assert(#parts==18 and total<65536)
    parts=HUD.camera_state.capture({read=read},raw,'avatar_page_13_test')
    local last=parts[#parts-1];assert(last.address+#last.data<=manager+0xa7aec)
    assert(not pcall(HUD.camera_state.capture,{read=read},raw,'avatar_page_14_test'))
    b.read=function(a,n)local value=read(a,n);if a==manager and n==4096 then P(manager+0x110,weapon) end;return value end
    assert(not pcall(HUD.camera_state.capture,b,raw,'avatar_page_0_test'));P(manager+0x110,avatar)
end)

test('native first-person state handles false and rejects stale or unknown bindings',function()
    local sigs={{0xa42a74,'4c8b0ded398e02'},{0xa42b1f,'4138bc24ec020000'},{0xa42b2a,'41888424ec020000'}}
    for _,s in ipairs(sigs) do put(base+s[1],s[2]:gsub('..',function(h)return string.char(tonumber(h,16))end)) end
    local raw={avatar_unit_ref=77,binding={module_base=base,avatar_id=10}}
    bytes[pm+0x2ec]=0;assert(HUD.camera_mode.read(backend,raw)==false)
    bytes[pm+0x2ec]=1;assert(HUD.camera_mode.read(backend,raw)==true)
    -- The local-player entity is distinct from the controlled avatar in-game.
    local local_player=alloc(24);U(local_player+8,11);bytes[local_player+20]=1
    P(pm+0xe8,local_player);map(pm+0xd0,{[11]=0})
    assert(HUD.camera_mode.read(backend,raw)==true)
    P(pm+0xe8,avatar);map(pm+0xd0,{[10]=0})
    bytes[pm+0x2ec]=2;assert(HUD.camera_mode.read(backend,raw)==nil)
    bytes[pm+0x2ec]=0;U(pm+0x3a8,78);assert(HUD.camera_mode.read(backend,raw)==nil);U(pm+0x3a8,77)
    bytes[base+0xa42b2a]=0;assert(HUD.camera_mode.read(backend,raw)==nil);bytes[base+0xa42b2a]=0x41
    local changed={read=function(a,n)
        local value=read(a,n);if a==pm+0x2ec then U(pm+0x3a8,78) end;return value
    end}
    assert(HUD.camera_mode.read(changed,raw)==nil);U(pm+0x3a8,77)
end)

test('native shoulder state rejects stale ownership and unknown code',function()
    for _,s in ipairs({{0xa4604c,'4c8b15cd0c8e02'},{0xa460da,'4869c138120000'},{0xa460e1,'4a8b841088e8530048c1e82a2401'}}) do
        put(base+s[1],s[2]:gsub('..',function(h)return string.char(tonumber(h,16))end))
    end
    local manager=alloc(0x540000);P(base+0x3326d20,manager)
    map(manager+0xf8,{[10]=0});P(manager+0x110,avatar)
    local raw={avatar_unit_ref=77,binding={module_base=base,avatar_id=10,avatar_record=avatar}}
    bytes[manager+0x53e88d]=32;assert(HUD.camera_mode.read_shoulder(backend,raw)==false)
    bytes[manager+0x53e88d]=36;assert(HUD.camera_mode.read_shoulder(backend,raw)==true)
    P(manager+0x110,weapon);assert(HUD.camera_mode.read_shoulder(backend,raw)==nil);P(manager+0x110,avatar)
    local changed={read=function(a,n)local v=read(a,n);if a==manager+0x53e88d then P(manager+0x110,weapon)end;return v end}
    assert(HUD.camera_mode.read_shoulder(changed,raw)==nil);P(manager+0x110,avatar)
    bytes[base+0xa4604c]=0;assert(HUD.camera_mode.read_shoulder(backend,raw)==nil)
end)

test('Spear reserves follow the owned matching pack rather than adjacent entity IDs',function()
    local original=read(weapon,8)
    local resource=u(0x643cf4ee)..u(0x25aa2fd4)
    local home=((0x25aa2fd4%spec[2])*(2^32%spec[2])+0x643cf4ee%spec[2])%spec[2]
    local row=tablebase+home*16;local oldrow=read(row,16)
    put(weapon,resource);put(row,resource..u(0)..u(0))
    local pack=weapon+24;put(pack,u(0x5f2e579a)..u(0x8ec3026b));U(pack+8,50)
    map(owner+L.entity_map,{[10]=0,[20]=1,[50]=2});U(inventory+12,50)
    local deposit=alloc(512)
    P(base+L.deposit[1],deposit);bind(deposit,0x20,0x38,50,pack)
    local counts=alloc(8);P(deposit+0x50,counts);U(counts,4)
    U(flags,0x81);U(state,1);U(state+8,1);U(runtime,0);U(config+0x88,1)
    local value=assert(reader.poll(),reader.status)
    assert(value.label=='GUIDED RCKT' and value.ammo_icon=='SPEAR_ROCKET')
    assert(value.reserve==4 and value.reserve_kind=='PACK')
    U(counts,0);value=assert(reader.poll(),reader.status);assert(value.reserve==0)
    put(pack,u(123)..u(0));value=assert(reader.poll(),reader.status);assert(value.reserve_kind~='PACK')
    U(inventory+12,0);map(owner+L.entity_map,{[10]=0,[20]=1})
    put(weapon,original);put(row,oldrow)
end)

test('Recoilless reserves follow matching pack, including empty and wrong-pack cases',function()
    local original=read(weapon,8)
    local resource=u(0x12a7e40f)..u(0x9f80d67a)
    local home=((0x9f80d67a%spec[2])*(2^32%spec[2])+0x12a7e40f%spec[2])%spec[2]
    local row=tablebase+home*16;local oldrow=read(row,16)
    put(weapon,resource);put(row,resource..u(0)..u(0))
    local pack=weapon+24;put(pack,u(0x2aa22980)..u(0x96dfc654));U(pack+8,50)
    map(owner+L.entity_map,{[10]=0,[20]=1,[50]=2});U(inventory+12,50)
    local deposit=alloc(512)
    P(base+L.deposit[1],deposit);bind(deposit,0x20,0x38,50,pack)
    local counts=alloc(8);P(deposit+0x50,counts);U(counts,4)
    U(flags,0x81);U(state,1);U(state+8,1);U(runtime,0);U(config+0x88,1)
    local value=assert(reader.poll(),reader.status)
    assert(value.reserve==4 and value.reserve_kind=='PACK')
    U(counts,0);value=assert(reader.poll(),reader.status);assert(value.reserve==0)
    put(pack,u(123)..u(0));value=assert(reader.poll(),reader.status);assert(value.reserve_kind~='PACK')
    U(inventory+12,0);map(owner+L.entity_map,{[10]=0,[20]=1})
    put(weapon,original);put(row,oldrow)
end)

test('machine gun uses verified magazine path and rejects stale component identity',function()
    local original=read(weapon,8)
    local resource=string.char(0x56,0x89,0xb3,0xab,0x3b,0x7d,0xc2,0x11)
    put(weapon,resource)
    local low=HUD.memory.new(backend).u(resource,0)
    local high=HUD.memory.new(backend).u(resource,4)
    local home=((high%spec[2])*(2^32%spec[2])+low%spec[2])%spec[2]
    put(tablebase+home*16,resource..u(0)..u(0))
    U(flags,0x20c1);U(state,174);U(state+8,1);U(runtime,3);U(config+0x88,175)
    local value=assert(reader.poll(),reader.status)
    assert(value.kind=='magazine' and value.rounds==175 and value.capacity==175 and value.reserve==3)
    local registry=HUD.memory.new(backend).p(mags+0x38)
    P(registry,avatar)
    assert(reader.poll()==nil and reader.status:find('component identity',1,true))
    P(registry,weapon)
    put(weapon,original);put(tablebase+home*16,string.rep('\0',16));U(config+0x88,45)
end)
test('magazine adds chamber once and preserves tactical reload',function()
    U(flags,0xc0);U(state,44);U(state+8,1);U(runtime,6)
    local m=assert(reader.poll(),reader.status);assert(m.rounds==45 and m.capacity==45 and m.reserve==6)
    U(state,45);m=assert(reader.poll());assert(m.rounds==46 and m.capacity==45 and m.chamber_rounds==1)
    local shown=HUD.model.normalize(m);assert(shown.value==46 and shown.chamber_bonus==1)
    U(state,44);U(state+8,0);bytes[runtime+8]=1
    m=assert(reader.poll());assert(m.rounds==45 and m.chamber_rounds==0 and m.pending_chamber_round==1)
    assert(not HUD.model.normalize(m).chamber_bonus)
    bytes[runtime+8]=0;m=assert(reader.poll());assert(m.rounds==44 and not m.pending_chamber_round)
    U(state+8,1)
end)
test('single-shot launcher stays empty while its reload flag is set',function()
    U(config+0x88,1);U(flags,0xc0);U(state,0);U(state+8,0);bytes[runtime+8]=1
    local m=assert(reader.poll(),reader.status)
    assert(m.rounds==0 and m.chamber_rounds==0 and not m.pending_chamber_round)
    U(state+8,1);m=assert(reader.poll());assert(m.rounds==1)
    U(config+0x88,45);bytes[runtime+8]=0
end)
test('recoilless programmable modes have distinct labels and rocket silhouettes',function()
    for control,mode in pairs({[0x50]='HEAT',[0x54]='HE'}) do
        assert(HUD.ammo_types.recoilless_mode(control)==mode)
        local raw=HUD.ammo_types.apply({kind='magazine',resource_hex='9f80d67a12a7e40f',ammo_mode=mode})
        assert(raw.label==mode and raw.ammo_icon=='ROCKET_'..mode and HUD.fire_icons[raw.ammo_icon])
    end
    assert(HUD.ammo_types.recoilless_mode(0x58)==nil)
end)

test('rounds selects correct tube and includes chamber',function()
    local rm=manager('rounds');bind(rm,0x28,0x40,20,weapon);P(rm+0x50,state);P(rm+0x58,runtime)
    map(rm+0x68,{[20]=0});local cfgaddr=alloc(0x88);P(rm+0xa8,cfgaddr)
    F(cfgaddr+0x48,8);F(cfgaddr+0x4c,4);U(cfgaddr+0x50,20);bytes[cfgaddr+0x68]=1
    U(cfgaddr+0x40,14);U(cfgaddr+0x44,240)
    U(flags,0x140);U(state+8,3);U(state+16,1);U(runtime+4,1);U(runtime,12)
    local m=assert(reader.poll(),reader.status);assert(m.rounds==4 and m.capacity==4 and m.reserve==12)
    assert(m.ammo_slot==1 and m.label=='SLUG')
    U(state+4,6);U(runtime+4,0);m=assert(reader.poll());assert(m.rounds==7 and m.capacity==8 and m.label=='BUCKSHOT' and m.ammo_slot==0)
    U(runtime+4,2);assert(reader.poll()==nil);U(runtime+4,1)
end)
test('autocannon rounds path counts inserted first clip before chambering',function()
    local original=read(weapon,8)
    put(weapon,string.char(0x5f,0x5c,0x0b,0x6f,0x31,0xfb,0xcf,0xa8))
    local rm=HUD.memory.new(backend).p(base+L.rounds);local cfgaddr=HUD.memory.new(backend).p(rm+0xa8)
    F(cfgaddr+0x48,10);bytes[cfgaddr+0x68]=1
    U(flags,0x140);U(runtime+4,0);U(state+4,4);U(state+16,0);bytes[runtime+16]=1
    local m=assert(reader.poll(),reader.status);assert(m.rounds==5 and m.pending_chamber_round==1)
    U(state+16,115);bytes[runtime+16]=0;m=assert(reader.poll());assert(m.rounds==5 and not m.pending_chamber_round)
    U(state+4,3);m=assert(reader.poll());assert(m.rounds==4 and not m.pending_chamber_round)
    put(weapon,original)
end)

test('heat uses configured limit and lock state',function()
    local hm=manager('heat');bind(hm,0x28,0x40,20,weapon);P(hm+0x58,runtime)
    map(hm+0x68,{[20]=0});local c=alloc(0x250);P(hm+0xa8,c);F(c+0x60,100);U(c+0x5c,3)
    U(flags,0x240);U(runtime,2);F(runtime+4,92);bytes[runtime+8]=1
    local m=assert(reader.poll(),reader.status);assert(math.abs(m.heat-.92)<1e-6 and m.locked and m.reserve==2)
end)
test('Talon reads its owned heat component instead of round bookkeeping',function()
    local old=read(weapon,8)
    U(weapon,0x72c4e433);U(weapon+4,0x416d0533);U(flags,0x140)
    local m=assert(reader.poll(),reader.status)
    assert(m.kind=='heat' and math.abs(m.heat-.92)<1e-6 and m.energy_icon=='LASER')
    put(weapon,old);U(flags,0x240)
end)
test('ownership mismatch and missing player clear data',function()
    bytes[avatar+20]=0;assert(reader.poll()==nil);bytes[avatar+20]=1
    U(pm+0x84,0);assert(reader.poll()==nil);U(pm+0x84,1)
end)
test('unknown builds and changed signatures fail closed',function()
    U(base+0x108,123);assert(HUD.reader.new(backend).poll()==nil);U(base+0x108,0x6AB3B43F)
    local at=base+L.signatures[1][1];local old=bytes[at];bytes[at]=0
    assert(HUD.reader.new(backend).poll()==nil);bytes[at]=old
end)
test('read budget prevents unbounded probing',function()
    local r=HUD.memory.new(backend);local ok=pcall(function() for i=1,513 do r.read(base,1) end end);assert(not ok)
end)
test('resource ammo resolves an identity-checked deposit',function()
    local dep=owner+L.records+48;U(dep+8,21);bytes[dep+20]=1
    U(dep,0x1a1860e0);U(dep+4,0x43eb1c3c)
    map(owner+L.entity_map,{[10]=0,[20]=1,[21]=2})
    local rm=alloc(256);P(base+L.resource[1],rm);bind(rm,0x20,0x38,20,weapon)
    local resource=alloc(36);P(rm+0x48,resource);U(resource,21)
    local dm=alloc(256);P(base+L.deposit[1],dm);bind(dm,0x20,0x38,21,dep)
    local counts=alloc(8);P(dm+0x50,counts);U(counts,17);U(flags,0x400)
    local m=assert(reader.poll(),reader.status);assert(m.kind=='resource' and m.rounds==17 and m.capacity==500)
    U(counts,0);assert(reader.poll().rounds==0)
end)
test('selected seat weapon works without an inventory slot',function()
    U(inventory+28,0);local m=assert(reader.poll(),reader.status);assert(m.id==20)
    U(inventory+28,1)
end)
-- Native crosshair fixture: independent screen/UI dimensions and a parent chain.
for _,s in ipairs(HUD.anchor.spec.signatures) do put(base+s[1],s[2]:gsub('..',function(h)return string.char(tonumber(h,16))end)) end
local ui=alloc(0x46e000);P(base+HUD.anchor.spec.manager,ui)
local hudroot=ui+0x24e340;bytes[hudroot+0x58]=1;bytes[hudroot+0x21f5b0]=1
local reticle=hudroot+0x19aaf8;local parent=alloc(256);local root=alloc(256)
P(reticle+0xf0,parent);P(parent+0xf0,root);F(root+0xc,1920);F(root+0x10,1080)
local camera=alloc(256);P(base+HUD.anchor.spec.camera,camera);F(camera+0xdc,0);F(camera+0xe0,0)
U(reticle+0x2080,3);F(reticle+0x2088,1020);F(reticle+0x208c,515)
F(reticle+0x2090,60);F(reticle+0x2094,-25)
test('native anchor follows stored reticle displacement without injected provider',function()
    local anchor=HUD.anchor.new(backend);local p=assert(anchor.poll(),anchor.status)
    assert(math.abs(p.x-(.5+60/1920))<1e-8 and math.abs(p.y-(.5+25/1080))<1e-8)
    F(reticle+0x2090,-90);F(reticle+0x2094,40)
    p=assert(anchor.poll());assert(p.x<.5 and p.y<.5)
    assert(anchor.samples==2 and anchor.max_x>anchor.min_x)
end)
test('anchor normalization accounts for UI size and camera screen offset',function()
    F(root+0xc,1280);F(root+0x10,720);F(camera+0xdc,.2);F(camera+0xe0,-.1)
    F(reticle+0x2090,64);F(reticle+0x2094,36)
    local a=HUD.anchor.new(backend);local p=assert(a.poll(),a.status)
    assert(math.abs(p.x-.65)<1e-6 and math.abs(p.y-.5)<1e-6)
    F(root+0xc,1920);F(root+0x10,1080);F(camera+0xdc,0);F(camera+0xe0,0)
end)
test('native anchor rejects bad signatures, hidden state and cyclic parents',function()
    local at=base+HUD.anchor.spec.signatures[1][1];local save=bytes[at];bytes[at]=0
    assert(HUD.anchor.new(backend).poll()==nil);bytes[at]=save
    local a=HUD.anchor.new(backend);U(reticle+0x2080,1);assert(a.poll()==nil and a.status=='native reticle hidden')
    U(reticle+0x2080,3);P(root+0xf0,reticle);assert(a.poll()==nil and a.status:find('cycle'))
    P(root+0xf0,0);assert(a.poll())
end)
test('runtime preserves callback results, expires anchors and releases GUI',function()
    local active={};local nextid=0;local calls=0;local destroyed=0
    local sr={Application={worlds=function()return {1}end,main_world=function()return 1 end},
        World={create_screen_gui=function()return 2 end,destroy_gui=function()destroyed=destroyed+1 end},
        Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,Color=function(...)return {...}end,
        Gui={resolution=function()return 1920,1080 end}}
    local function add()nextid=nextid+1;active[nextid]=true;return nextid end
    local function remove(g,id)assert(active[id]);active[id]=nil end
    sr.Gui.rect=add;sr.Gui.text=add;sr.Gui.destroy_rect=remove;sr.Gui.destroy_text=remove
    local previous=function()calls=calls+1;return 7,nil,9 end;update=previous
    local hud=HUD.runtime.start(sr,backend)
    local a,b,c=update(1/60);assert(a==7 and b==nil and c==9 and calls==1)
    hud.set_anchor_provider(function()return nil end)
    hud.push_anchor(.6,.4);update(1/60);assert(hud.anchor_status=='external provider')
    update(.2);assert(hud.anchor_status:find('center fallback',1,true))
    assert(not pcall(hud.configure,{scale=0}))
    U(pm+0x84,0);update(.1);assert(next(active)==nil);U(pm+0x84,1)
    hud.retire();assert(update==previous and destroyed==1 and next(active)==nil)
end)
test('research logging is opt-in and errors remain visible',function()
    local messages={};local lookups=0
    local b={};for k,v in pairs(backend) do b[k]=v end
    b.log=function(line)messages[#messages+1]=line end
    b.read_tuning=function()return {debug_logging=false}end
    local sr={Application={can_get=function()lookups=lookups+1;return false end},Gui={resolution=function()error('controlled render failure')end}}
    local h=HUD.runtime.start(sr,b,{managed=true})
    assert(lookups==0 and not table.concat(messages,'\n'):find('SCREEN_RESOURCE',1,true))
    h.configure({debug_logging=true});assert(lookups==6)
    assert(table.concat(messages,'\n'):find('SCREEN_RESOURCE',1,true))
    h.configure({debug_logging=false});h.tick(6)
    assert(lookups==6 and table.concat(messages,'\n'):find('ERROR',1,true))
    h.retire()
end)

test('movement does not fade the HUD and automatic native input moves it',function()
    local sr={Application={worlds=function()return {1}end,main_world=function()return 1 end,back_buffer_size=function()return 2560,1440 end},
        World={create_screen_gui=function()return 2 end,destroy_gui=function()end},
        Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,Color=function(...)return {...}end,
        Gui={resolution=function()return 1280,720 end,rect=function()return 1 end,text=function()return 2 end,destroy_rect=function()end,destroy_text=function()end}}
    update=function()end
    local normalize=HUD.model.normalize
    HUD.model.normalize=function(raw)local m=normalize(raw);if m then m.lowered=true end;return m end
    F(reticle+0x2090,0);F(reticle+0x2094,0)
    local h=HUD.runtime.start(sr,backend)
    for _=1,60 do update(1/60) end
    assert(h.opacity>.99 and math.abs(h.motion_x)<1e-6)
    F(selection+0x1ac,6);F(selection+0x1b0,12)
    F(reticle+0x2090,80);F(reticle+0x2094,-30)
    for _=1,60 do update(1/60) end
    assert(h.opacity>.99 and h.motion_x>20 and h.motion_y<0 and h.anchor_status=='native crosshair')
    U(reticle+0x2080,1)
    for _=1,60 do update(1/60) end
    assert(h.opacity>.99 and math.abs(h.motion_x)<.01)
    U(reticle+0x2080,3);h.retire();HUD.model.normalize=normalize
end)
test('heat thresholds and alternating overheat colors',function()
    local c=HUD.config.new()
    for _,f in ipairs({0,.64,.64999}) do assert(HUD.layout.heat_color(f,0,c)==c.heat_white) end
    for _,f in ipairs({.65,.75,.84,.84999}) do
        assert(HUD.layout.heat_color(f,0,c)==c.heat_yellow)
        local d=HUD.layout.compose(HUD.model.normalize({kind='heat',heat=f,reserve=2}),0,0,1,1,c,0)
        local expected=HUD.config.rgb(c.heat_yellow)
        for _,v in ipairs(d) do if v.heat_label then
            for i=1,3 do assert(v.c[i]==(v.heat_label=='percent' and expected[i] or 255)) end
        end end
    end
    for _,f in ipairs({.85,.86,.94,.94999}) do assert(HUD.layout.heat_color(f,0,c)==c.heat_red) end
    for _,f in ipairs({.95,1}) do
        assert(HUD.layout.heat_color(f,0,c)==c.heat_red)
        assert(HUD.layout.heat_color(f,.25,c)==c.heat_yellow)
        assert(HUD.layout.heat_color(f,.5,c)==c.heat_red)
    end
end)
test('heat gauge preserves fractional progress across warning zones',function()
    for _,fraction in ipairs({0,.5,.525,.8,.9,1}) do
        local m=HUD.model.normalize({kind='heat',heat=fraction,reserve=2})
        local d=HUD.layout.compose(m,0,0,1,1,HUD.config.new(),0)
        local background,filled=0,0
        for _,v in ipairs(d) do
            if v.heat_background then background=background+v.w end
            if v.heat_fill then filled=filled+v.w end
        end
        assert(math.abs(filled/background-fraction)<1e-9)
    end
end)
test('vent pulses red without disappearing even below the heat threshold',function()
    local cfg=HUD.config.new()
    local m={kind='heat',fraction=.5,value=50,state='VENT',reserve=1}
    local a=HUD.layout.compose(m,0,0,1,1,cfg,0)
    local b=HUD.layout.compose(m,0,0,1,1,cfg,.25)
    local red=HUD.config.rgb(cfg.heat_red)
    local ta,tb
    for _,v in ipairs(a) do if v.heat_label=='percent' then ta=v end end
    for _,v in ipairs(b) do if v.heat_label=='percent' then tb=v end end
    for i=1,3 do assert(ta.c[i]==red[i] and tb.c[i]==red[i]) end
    assert(math.abs(tb.a/ta.a-.25)<1e-6)
    local warning
    for _,v in ipairs(a) do
        assert(not v.heat_background and not v.heat_fill and not v.heat_scanline)
        for i=1,3 do assert(v.c[i]==red[i]) end
        if v.overheat_warning then warning=v end
    end
    assert(warning and warning.text=='OVERHEAT' and warning.size>16)
end)

test('configuration validates atomically and roundtrips as Lua',function()
    local c=HUD.config.new();HUD.config.apply(c,{text_color='a0B1c2',offset_x=-900,frosted=false})
    assert(c.text_color=='#A0B1C2' and c.offset_x==-900 and c.frosted==false)
    assert(not pcall(HUD.config.apply,c,{scale=1.5,heat_red='#GGGGGG'}) and c.scale==1)
    assert(not pcall(HUD.config.apply,c,{offset_y=0/0}))
    HUD.config.apply(c,{occlusion_mode='mesh'});assert(c.occlusion_mode=='gui_depth' and not c.always_show_3d)
    HUD.config.apply(c,{always_show_3d=true});assert(c.occlusion_mode=='gui' and not c.hud_occlusion)
    local f=assert(loadstring(HUD.config.serialize(c)));setfenv(f,{})
    local loaded=f();assert(loaded.archived_mesh and loaded.research and loaded.saturation==nil)
    local restored=HUD.config.new();HUD.config.apply(restored,loaded);for k,v in pairs(c) do
        if k~='weapon_panels' and k~='show_3d' and k~='always_show_3d' and k~='occlusion_mode' and k~='hud_occlusion' and k~='placement_mode' and not k:match('^left_mount_') and not k:match('^fp_mount_') and not k:match('^mount_') then assert(restored[k]==v) end
    end
    assert(not pcall(HUD.config.apply,c,{scale=1.5,archived_mesh={unknown=1}}) and c.scale==1)
    assert(not pcall(HUD.config.apply,c,{saturation=1,archived_mesh={saturation=2}}))
end)
test('decorations default off, fit dynamic perimeter and preserve content',function()
    local c=HUD.config.new();assert(c.decoration=='none')
    local model={kind='heat',fraction=.8,value=80,reserve=3,state='READY'}
    for _,font in ipairs(HUD.config.fonts) do for _,scale in ipairs({.5,1,2}) do
        c.font=font;c.decoration='none';local plain=HUD.layout.compose(model,15,20,scale,.8,c,0)
        for _,style in ipairs(HUD.config.decorations) do
            HUD.config.apply(c,{decoration=style});local decorated=HUD.layout.compose(model,15,20,scale,.8,c,0)
            local f=decorated[1];assert(f.x==plain[1].x and f.y==plain[1].y and f.w==plain[1].w and f.h==plain[1].h)
            assert((style=='none' and #decorated==#plain) or (style~='none' and #decorated>#plain))
            local child
            for _,r in ipairs(decorated) do if r.heat_child and r.type=='panel' then child=r end end
            for _,r in ipairs(decorated) do if r.decoration then
                local owner=r.heat_child and child or f
                assert(r.w>0 and r.h>0 and r.x>=owner.x-1e-6 and r.y>=owner.y-1e-6 and r.x+r.w<=owner.x+owner.w+1e-6 and r.y+r.h<=owner.y+owner.h+1e-6)
            end
            end
        end
    end end
    assert(not pcall(HUD.config.apply,c,{decoration='unknown'}))
end)

test('upright mount removes roll while preserving forward direction',function()
    local q=math.sqrt(.5)
    local m={q,0,-q,0,0,1,0,0,q,0,q,0,2,3,4,1}
    local u=HUD.pose_motion.upright(m)
    assert(u[1]==1 and u[3]==0 and u[5]==m[5] and u[6]==m[6] and u[7]==m[7])
    assert(u[9]==0 and u[10]==0 and u[11]==1 and u[13]==2)
    local vertical={1,0,0,0,0,0,1,0,0,-1,0,0,0,0,0,1}
    assert(HUD.pose_motion.upright(vertical)==vertical)
end)

test('auto placement projects to its target and preserves manual offsets',function()
    local m={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
    local p={x=.2,y=1,z=.1,matrix=m}
    local c=HUD.config.new();c.mount_x=.3;c.mount_y=.4;c.mount_z=.5
    for _,left in ipairs({false,true}) do
        p.left_shoulder=left
        local a=HUD.projection.auto_mount(m,p,1,16/9,.1)
        local screen=assert(HUD.projection.project(m,p.x+a.x,p.y+a.y,p.z+a.z,1,16/9,.1))
        assert(math.abs(screen.x-(left and .42 or .58))<1e-6 and math.abs(screen.y-.48)<1e-6)
        p.auto_mount=a;c.placement_mode='auto';local x,y,z=HUD.scene_test.mount(p,c);assert(x==a.x and math.abs(y-a.y-.0762)<1e-9 and z==a.z)
    end
    c.placement_mode='manual';p.left_shoulder=false
    local x,y,z=HUD.scene_test.mount(p,c);assert(x==.3 and math.abs(y-.4762)<1e-9 and z==.7)
    assert(c.mount_x==.3 and c.mount_y==.4 and c.mount_z==.5)
end)

test('native menu keeps colors config-only and persists placement',function()
    local options,values,callbacks={},{},{};local writes=0
    ModOptionsMenu={api=1,register_option=function(id,spec) if spec.type=='choice' then assert(#spec.choices>=2 and #spec.choices<=16) end;options[id]=spec;values[id]=spec.default;return true end,
        on_change=function(id,fn)callbacks[id]=fn;return true end,set=function(id,v)values[id]=v;return true end}
    local h={config=HUD.config.new()};local menu
    h.configure=function(v)HUD.config.apply(h.config,v);menu.sync()end
    h.save_tuning=function()writes=writes+1 end
    menu=HUD.menu.new(h);menu.poll();assert(menu.status=='Options > Mods > DBF-HUD')
    local n=0;for _ in pairs(options) do n=n+1 end;assert(n==25)
    callbacks['dbf_hud_v4.debug_sight_root_orientation'](true);assert(h.config.debug_sight_root_orientation and writes==1);writes=writes-1
    callbacks['dbf_hud_v4.force_occlusion'](true);assert(h.config.force_occlusion and writes==1);writes=writes-1
    assert(not options['dbf_hud_placement.fp_auto_side'] and h.config.fp_auto_side=='right')
    HUD.config.apply(h.config,{fp_auto_side='left'});assert(h.config.fp_auto_side=='right')
    callbacks['dbf_hud_placement.travel'](120);assert(h.config.travel==120)
    assert(not callbacks['dbf_hud_v3.color_target'] and not callbacks['dbf_hud_v3.rgba1'])
    callbacks['dbf_hud_v6.font_native'](2);assert(h.config.font=='hack' and writes==2)
    callbacks['dbf_hud_v6.font_native'](1);assert(h.config.font=='bigblue' and writes==3)
    callbacks['dbf_hud_v4.debug_logging'](true);assert(h.config.debug_logging and writes==4)
    callbacks['dbf_hud_v4.decoration'](4);assert(h.config.decoration=='helldivers' and writes==5)
    callbacks['dbf_hud_v4.decoration'](1);assert(h.config.decoration=='none' and writes==6)
    local groups={};for _,spec in pairs(options) do groups[spec.mod]=(groups[spec.mod] or 0)+1 end
    assert(groups['DBF-HUD']==16 and groups['DBF-HUD Placement']==9)
    assert(not options['dbf_hud_v4.emissive_intensity'] and not options['dbf_hud_v4.pose_marker'])
    callbacks['dbf_hud_v4.display_mode'](1);assert(h.config.anchor_mode=='weapon')
    callbacks['dbf_hud_v4.display_mode'](2);assert(h.config.anchor_mode=='crosshair')
    callbacks['dbf_hud_v4.display_mode'](3);assert(h.config.anchor_mode=='world')
    menu.retire();callbacks['dbf_hud_placement.travel'](42);assert(h.config.travel==120)
    ModOptionsMenu=nil;assert(HUD.menu.new(h).status=='Mod Options Menu not installed')
end)
test('native frost is availability gated and bitmap lifecycle is released',function()
    local active={};local nextid=0;local bitmaps=0;local panelalpha;local available=false
    local function add()nextid=nextid+1;active[nextid]=true;return nextid end
    local function remove(g,id)assert(active[id]);active[id]=nil end
    local sr={Application={worlds=function()return {1}end,main_world=function()return 1 end,
        can_get=function(kind,name)assert(kind=='material');return available end},
        World={create_screen_gui=function()return 2 end,destroy_gui=function()end},
        Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,Color=function(...)return {...}end,
        Gui={rect=function(g,p,s,c)panelalpha=c[1];return add()end,text=add,
            bitmap=function()bitmaps=bitmaps+1;return add()end,destroy_rect=remove,destroy_text=remove,destroy_bitmap=remove}}
    local v=HUD.view.new(sr);local command={{type='panel',x=0,y=0,w=103,h=83,c={32,38,40},a=.55,frosted=true}}
    v.draw(command);assert(bitmaps==0 and panelalpha==140)
    v.release();assert(next(active)==nil);available=true
    v.draw(command);assert(bitmaps==1 and panelalpha==140 and v.material_status:find('native frost',1,true))
    v.release();assert(next(active)==nil)
end)

test('heat proportions scale together and percent remains adjacent',function()
    for _,heat in ipairs({0,.62,1}) do
        local m=HUD.model.normalize({id=1,kind='heat',heat=heat,reserve=3})
        local config=HUD.config.new();config.font='debug'
        local one=HUD.layout.compose(m,0,0,1,1,config,0)
        local two=HUD.layout.compose(m,0,0,2,1,config,0)
        assert(one[1].w>0 and one[1].h>0)
        local number,percent
        for i,c in ipairs(one) do
            assert(two[i].x==2*c.x and two[i].y==2*c.y)
            if c.size then assert(two[i].size==2*c.size) end
            if c.heat_label=='percent' then number=c end
            if c.text=='%' then percent=c end
        end
        assert(number and number.text:sub(-1)=='%')
    end
end)
test('frame fits measured text including bearings and grows for content',function()
    local function measure(t,size) return -2,-size*.25,#t*size*.7,size*.9 end
    local function card(value,reserve)
        return HUD.layout.compose({kind='magazine',value=value,label='AMMO',state='READY',reserve=reserve,reserve_kind='MAGAZINES',fraction=.5},0,0,1,1,HUD.config.new(),0,measure)
    end
    local small=card(7,1);local large=card(12345,99999)
    assert(large[1].w>small[1].w)
    for _,commands in ipairs({small,large}) do
        local p=commands[1]
        for i=4,#commands do
            local c=commands[i];local a,b,e,f=0,0,c.w,c.h
            if c.type=='text' then a,b,e,f=measure(c.text,c.size) end
            assert(c.x+a>=p.x+8-1e-8 and c.x+e<=p.x+p.w-8+1e-8)
            assert(c.y+b>=p.y+8-1e-8 and c.y+f<=p.y+p.h-8+1e-8)
        end
    end
    local a=HUD.layout.compose(HUD.model.normalize({kind='heat',heat=.99,reserve=1}),0,0,1,1,HUD.config.new(),0,measure)
    local b=HUD.layout.compose(HUD.model.normalize({kind='heat',heat=1,reserve=1}),0,0,1,1,HUD.config.new(),0,measure)
    assert(math.abs(b[1].w-a[1].w)<1e-8)
end)

test('native text renderer releases engine text objects',function()
    local active={};local index=0;local texts=0
    local function add()index=index+1;active[index]=true;return index end
    local sr={Application={worlds=function()return {1}end,main_world=function()return 1 end},
        World={create_screen_gui=function()return 2 end,destroy_gui=function()end},
        Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,Color=function(...)return {...}end,
        Gui={rect=add,text=function()texts=texts+1;return add()end,
            destroy_rect=function(g,id)assert(active[id]);active[id]=nil end,
            destroy_text=function(g,id)assert(active[id]);active[id]=nil end}}
    local v=HUD.view.new(sr)
    local cmd={type='text',text='0123456789 HEAT SINKS',font='bigblue',size=24,x=.4,y=.7,a=1,c={255,255,255}}
    v.draw({cmd});assert(texts==1 and index==1)
    v.clear();assert(next(active)==nil)
    cmd.font='debug';v.draw({cmd});assert(texts==2);v.release();assert(next(active)==nil)
    local cfg=HUD.config.new();assert(not pcall(HUD.config.apply,cfg,{font='unverified/path'}))
end)

test('pose reader checks code, generations, matrices and ownership after read',function()
    local function hex(s)return (s:gsub('..',function(h)return string.char(tonumber(h,16))end))end
    local testbase=0x900000
    local api=alloc(32);local unitapi=alloc(160);local getter=alloc(48);local resolver=alloc(116)
    local slot=alloc(8);local registry=alloc(176);local objects=alloc(32);local generations=alloc(4)
    local object=alloc(160);local vtable=alloc(240);local accessor=alloc(5);local matrix=alloc(64);local record=alloc(24)
    local candidate=3*0x400000+2
    P(testbase+0x3326308,api);P(api+0x18,unitapi);P(unitapi+0x90,getter)
    put(getter,hex('40534883ec204863dae8')..u(resolver-getter-14)..hex('488bc84c8b0041ff90e8000000488bcb48c1e10648034828488bc14883c4205bc3cc'))
    put(resolver,hex('48895c24084889742410574883ec20488b35'));U(resolver+0x12,slot-resolver-0x16)
    put(resolver+0x25,hex('8bc325ffff3f003b8698000000720433dbeb1c8bc8488b86a0000000c1eb16381c0175eb488b8688000000488b1cc8'))
    P(slot,registry);U(registry+0x98,4);P(registry+0x88,objects);P(registry+0xa0,generations)
    P(objects+16,object);bytes[generations+2]=3;U(object+8,candidate)
    P(object,vtable);P(vtable+0xe8,accessor);put(accessor,hex('488d4160c3'))
    U(object+0x70,63);P(object+0x88,matrix)
    for i,v in ipairs({1,0,0,0,0,1,0,0,0,0,1,0,12,23,34,1})do F(matrix+(i-1)*4,v)end
    U(record+8,123);U(record+12,candidate);U(record+16,77)
    local raw={id=123,unit_ref=77,resource_hex='test',binding={module_base=testbase,record=record,candidate=candidate}}
    local p=HUD.pose.new(backend);local value=assert(p.poll(raw),p.status)
    assert(value.x==12 and value.y==23 and value.z==34 and value.node_count==63)
    bytes[generations+2]=4;assert(p.poll(raw)==nil and p.status:find('recycled'));bytes[generations+2]=3
    local first=bytes[getter];bytes[getter]=0;assert(p.poll(raw)==nil and p.status:find('getter'));bytes[getter]=first
    F(matrix,math.huge);assert(p.poll(raw)==nil);F(matrix,1)
    F(matrix+4,.5);assert(p.poll(raw)==nil);F(matrix+4,0)
    U(record+8,124);assert(p.poll(raw)==nil and p.status:find('weapon changed'));U(record+8,123)
    local tearing={read=function(a,n)local s=read(a,n);if a==matrix then bytes[generations+2]=4 end;return s end}
    assert(HUD.pose.new(tearing).poll(raw)==nil);bytes[generations+2]=3
    assert(p.poll(raw))
end)


test('weapon attachment follows distant targets with bounded lag and resets',function()
    local c=HUD.config.new();local a=HUD.motion.new()
    local x,y=HUD.motion.attach(a,{x=600,y=-300},1/60,c)
    assert(x==600 and y==-300)
    for i=1,100 do
        local t={x=600+i*10,y=-300+i*5}
        x,y=HUD.motion.attach(a,t,1/60,c)
        assert((x-t.x)^2+(y-t.y)^2<=c.weapon_lag^2+1e-7)
    end
    c.weapon_lag=0;x,y=HUD.motion.attach(a,{x=-800,y=400},1/60,c)
    assert(x==-800 and y==400)
    x,y=HUD.motion.attach(a,{x=100,y=200},1,c);assert(x==100 and y==200)
end)

test('runtime attaches without reticle travel clamp and falls back when projection fails',function()
    local draw_x=0
    local sr={Application={back_buffer_size=function()return 3840,2160 end,worlds=function()return {1}end,main_world=function()return 1 end},
        World={create_screen_gui=function()return 2 end,destroy_gui=function()end},
        Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,Color=function(...)return {...}end,
        Gui={resolution=function()return 1920,1080 end,rect=function(gui,pos)draw_x=math.max(draw_x,pos[1]);return 1 end,text=function()return 2 end,destroy_rect=function()end,destroy_text=function()end}}
    local saved_pose,saved_projection,saved_scene=HUD.pose.new,HUD.projection.new,HUD.scene_test.new
    local world_draws=0;local selected_mode
    HUD.scene_test.new=function()return {draw=function(p,c,target,dt,aspect,commands)assert(target==nil and commands and #commands>0);world_draws=world_draws+1;selected_mode=c.occlusion_mode;return true end,release=function()end}end
    local valid=true;local received;local pose_reads=0
    HUD.pose.new=function()return {poll=function()pose_reads=pose_reads+1;return {id=20,candidate=1,node_count=1,x=1,y=2,z=3,matrix={0,1,0,0,-1,0,0,0,0,0,1,0,1,2,3,1}}end,status='test'}end
    HUD.projection.new=function()return {status='test',poll=function(base,p,aspect)received=p;if valid then return {x=.8,y=.2,depth=2} end end}end
    update=function()end
    local h=HUD.runtime.start(sr,backend);h.configure({mount_x=.5,anchor_mode='weapon'})
    update(1/60);assert(h.anchor_status=='weapon attachment')
    assert(draw_x>0 and draw_x<1920,'screen geometry must stay in GUI coordinates despite a larger back buffer')
    assert(math.abs(h.motion_x-576)<1e-6 and math.abs(h.motion_y+324)<1e-6)
    assert(math.abs(received.x-.8238)<1e-6 and math.abs(received.y-2.16)<1e-6 and math.abs(received.z-3.04)<1e-6)
    local before=pose_reads;for i=1,10 do update(1/144)end;assert(pose_reads==before+10)
    local alpha=h.opacity;valid=false;update(1/60)
    assert(h.anchor_status~='weapon attachment' and h.opacity>=alpha)
    valid=true;update(1/60);assert(math.abs(h.motion_x-576)<1e-6)
    h.configure({anchor_mode='crosshair'});update(1/60);assert(h.anchor_status~='weapon attachment')
    h.configure({anchor_mode='world',always_show_3d=false});update(1/60);assert(world_draws==1 and selected_mode=='gui')
    h.configure({always_show_3d=true});update(1/60);assert(world_draws==2 and selected_mode=='gui')
    h.configure({anchor_mode='weapon'});update(1/60);assert(world_draws==2)
    h.retire();HUD.pose.new,HUD.projection.new,HUD.scene_test.new=saved_pose,saved_projection,saved_scene
end)

test('projection handles perspective, aspect, camera rotation and clipping',function()
    local m={1,0,0,0,0,1,0,0,0,0,1,0,10,20,30,1}
    local p=assert(HUD.projection.project(m,10,30,30,math.pi/2,2,.05))
    assert(math.abs(p.x-.5)<1e-9 and math.abs(p.y-.5)<1e-9)
    p=assert(HUD.projection.project(m,20,30,35,math.pi/2,2,.05))
    assert(math.abs(p.x-.75)<1e-9 and math.abs(p.y-.75)<1e-9)
    assert(HUD.projection.project(m,10,19,30,math.pi/2,2,.05)==nil)
    assert(HUD.projection.project(m,1000,30,30,math.pi/2,2,.05)==nil)
    m={0,1,0,0,-1,0,0,0,0,0,1,0,0,0,0,1}
    p=assert(HUD.projection.project(m,-10,5,0,math.pi/2,1,.05))
    assert(math.abs(p.x-.75)<1e-9)
    m[1]=1;assert(not pcall(HUD.projection.project,m,-10,5,0,math.pi/2,1,.05))
end)

test('camera reader rejects changed code, camera modes and torn ownership',function()
    local base,api,cap,getter,impl,state,cam,scene,mat=0x50000000,0x60000000,0x60001000,0x60002000,0x60003000,0x60004000,0x60005000,0x60006000,0x60007000
    local function hex(s)return (s:gsub('..',function(h)return string.char(tonumber(h,16))end))end
    P(base+0x3326308,api);P(api+0x20,cap);P(cap+0xf8,getter)
    put(getter,hex('48895c2408574883ec60'))
    put(getter+0x132,hex('e8')..u(impl-getter-0x137))
    put(impl,hex('488bc448895808488968104889701857'))
    put(impl+0x62,hex('488b471848c1e206418be948035028e80a951500'))
    P(base+0x346d560,state);P(state,cam);put(cam,string.rep(string.char(0),160))
    P(cam+0x18,scene);U(cam+0x20,0);U(cam+0x30,1);F(cam+0x28,.05);F(cam+0x34,math.pi/2);F(cam+0x8c,1);P(scene+0x28,mat)
    for i,v in ipairs({1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1})do F(mat+(i-1)*4,v)end
    local reader=HUD.projection.new(backend);local pose={x=0,y=10,z=0}
    assert(reader.poll(base,pose,2),reader.status)
    U(cam+0x50,2);assert(not reader.poll(base,pose,2));U(cam+0x50,0)
    F(cam+0x90,1);assert(not reader.poll(base,pose,2));F(cam+0x90,0)
    bytes[getter]=0;assert(not reader.poll(base,pose,2));bytes[getter]=0x48
    local tearing={read=function(a,n)local b=read(a,n);if a==mat then U(cam+0x20,1)end;return b end}
    assert(not HUD.projection.new(tearing).poll(base,pose,2));U(cam+0x20,0)
    assert(reader.poll(base,pose,2))
end)

test('MDL cycles preserve host callbacks, retire old HUD and clean every resource',function()
    local active={};local sequence=0;local destroyed=0;local closed=0;local host_calls=0
    local function add()sequence=sequence+1;active[sequence]=true;return sequence end
    local function remove(g,id)assert(active[id]);active[id]=nil end
    local saved_sr=stingray;local saved_native=HUD.memory.native
    stingray={Application={worlds=function()return {1}end,main_world=function()return 1 end},
        World={create_screen_gui=function()return 2 end,destroy_gui=function()destroyed=destroyed+1 end},
        Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,Color=function(...)return {...}end,
        Gui={resolution=function()return 1920,1080 end,rect=add,text=add,destroy_rect=remove,destroy_text=remove}}
    HUD.memory.native=function()return {module=backend.module,read=backend.read,close=function()closed=closed+1 end}end
    update=function()host_calls=host_calls+1;return 7,nil,9 end
    shutdown=function()return 'host shutdown' end
    local old=HUD.runtime.start(stingray,backend);update(1/60)
    -- Simulate a later addon wrapping the original boot HUD.
    local chained=update;local host=function(...)return chained(...)end;update=host
    for cycle=1,4 do
        local cleanup;local def=assert(loadfile('src/mdl.lua'))()
        local ctx={api=2,on_cleanup=function(fn)cleanup=fn end,
            global=function(name,value)assert(name=='DBFHUD');rawset(_G,name,value)end,log=function()end}
        def.on_enable(ctx)
        local host_shutdown=shutdown
        assert(update==host)
        local current=DBFHUD;local before=host_calls
        local a,b,c=update(1/60);assert(a==7 and b==nil and c==9 and host_calls==before+1)
        assert(current.clock==0) -- host chain cannot tick the managed instance
        def.on_update(ctx,1/60);assert(current.clock==1/60 and next(active))
        assert(update==host and shutdown==host_shutdown)
        def.on_disable(ctx);cleanup();def.on_disable(ctx)
        assert(next(active)==nil and closed==cycle and destroyed==cycle+1)
        def.on_update(ctx,1);current.frame(1);current.tick(1);assert(current.clock==1/60)
        assert(update==host and shutdown==host_shutdown)
        DBFHUD=nil
    end
    HUD.memory.native=saved_native;stingray=saved_sr
end)

test('menu reload reuses dispatchers and releases retired callbacks',function()
    local registered=0;local callbacks={};local writes=0
    ModOptionsMenu={api=1,register_option=function()return true end,
        on_change=function(id,fn)registered=registered+1;callbacks[id]=fn;return true end,set=function()return true end}
    for cycle=1,5 do
        local h={config=HUD.config.new(),save_tuning=function()writes=writes+1 end}
        h.configure=function(v)HUD.config.apply(h.config,v)end
        local menu=HUD.menu.new(h);menu.poll();assert(registered==25)
        callbacks['dbf_hud_placement.travel'](77);assert(h.config.travel==77 and writes==cycle)
        menu.retire();callbacks['dbf_hud_placement.travel'](88);assert(h.config.travel==77 and writes==cycle)
    end
    ModOptionsMenu=nil
end)

test('live menu reuses boot registrations with changed saved defaults',function()
    local callbacks={};local h={config=HUD.config.new(),save_tuning=function()end}
    h.config.offset_x=177;h.config.font='debug'
    ModOptionsMenu={api=1,get=function()return 1 end,
        register_option=function()error('existing boot schema must not be registered with new defaults')end,
        on_change=function(id,fn)callbacks[id]=fn;return true end,set=function()return true end}
    h.configure=function(v)HUD.config.apply(h.config,v)end
    local menu=HUD.menu.new(h);menu.poll();assert(menu.status=='Options > Mods > DBF-HUD')
    callbacks['dbf_hud_placement.travel'](128);assert(h.config.travel==128)
    menu.retire();ModOptionsMenu=nil
end)

test('first-person world frame contains quantized glyphs after scaling',function()
    local saved=HUD.world_probe.new;local captured
    HUD.world_probe.new=function()return {draw=function(_,_,commands)captured=commands;return true end,release=function()end}end
    local c=HUD.config.new();c.decoration='brackets';local carrier=HUD.scene_test.new({},function()end)
    local commands=HUD.layout.compose({kind='magazine',value=7,label='AMMO',reserve=2,reserve_kind='MAGS',state='READY'},0,0,2,1,c,0)
    carrier.draw({first_person=true},c,nil,.016,nil,commands)
    local frame=captured[1]
    for _,v in ipairs(captured) do if v.type=='text' then
        local a,b,e,f=HUD.font.measure(v.text,v.size,v.font,true)
        assert(v.x+a>=frame.x and v.y+b>=frame.y and v.x+e<=frame.x+frame.w and v.y+f<=frame.y+frame.h)
    end end
    local right_edge=false
    for _,v in ipairs(captured) do if v.decoration then
        assert(v.x>=frame.x-1e-8 and v.y>=frame.y-1e-8 and v.x+v.w<=frame.x+frame.w+1e-8 and v.y+v.h<=frame.y+frame.h+1e-8)
        if math.abs(v.x+v.w-frame.x-frame.w)<1e-8 then right_edge=true end
    end end
    assert(right_edge)
    HUD.world_probe.new=saved
end)

test('3D smoothing preserves rigid axes, bounds lag and resets on weapon changes',function()
    local identity={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
    local turn={-1,0,0,0,0,-1,0,0,0,0,1,0,0,0,0,1}
    local c=HUD.config.new();c.world_rotation_smooth=.3;c.world_max_lag=.5
    local results={}
    for _,fps in ipairs({30,60,144})do
        local state={};HUD.pose_motion.step(state,identity,0,0,0,1,0,c)
        local out
        for i=1,fps do out=HUD.pose_motion.step(state,turn,.5,0,0,1,1/fps,c)end
        for _,k in ipairs({1,5,9})do assert(math.abs(out[k]^2+out[k+1]^2+out[k+2]^2-1)<1e-8)end
        assert(math.abs(out[1]*out[5]+out[2]*out[6]+out[3]*out[7])<1e-8)
        results[#results+1]=out
    end
    for i=1,16 do assert(math.abs(results[1][i]-results[3][i])<1e-7)end
    local state={};HUD.pose_motion.step(state,identity,0,0,0,1,0,c);c.world_max_lag=.12
    local out=HUD.pose_motion.step(state,turn,1,0,0,1,1/144,c);assert(1-out[13]<=.12000001)
    out=HUD.pose_motion.step(state,identity,-1,0,0,2,1/144,c);assert(out[13]==-1 and out[1]==1)
    out=HUD.pose_motion.step(state,turn,20,0,0,2,1/144,c);assert(out[13]==20 and out[1]==-1)
    c.world_position_smooth=0;c.world_rotation_smooth=0
    out=HUD.pose_motion.step(state,identity,20.1,0,0,2,1/144,c);assert(out[13]==20.1 and out[1]==1)
end)

test('world GUI probe uses live worlds, moves and releases without stale handles',function()
    local worlds={1};local created,moved,destroyed,drawn=0,0,0,0
    local sr={Application={worlds=function()return worlds end,main_world=function()return worlds[1] end},
        Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,Color=function(...)return {...}end,
        Matrix4x4={from_axes=function(x,y,z,t)return {x,y,z,t}end},
        World={create_world_gui=function(w,p,x,y,mode)assert(w==worlds[1] and x==1000 and mode=='immediate');created=created+1;return created end,
            destroy_gui=function(w,g)assert(w==worlds[1]);destroyed=destroyed+1 end},
        Gui={move=function()moved=moved+1 end,rect=function()drawn=drawn+1 end,text=function()drawn=drawn+1 end}}
    local probe=HUD.world_probe.new(sr,function()end);local cfg=HUD.config.new();cfg.world_probe=true
    local p={x=0,y=0,z=0,matrix={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}}
    probe.draw(p,cfg);probe.draw(p,cfg);assert(created==1 and moved==1 and drawn==4)
    local commands=HUD.layout.compose({kind='heat',value=83,fraction=.83,reserve=3,state='READY'},0,0,2,1,cfg,0)
    local material_draws=0
    sr.Application.can_get=function(kind,name)return name=='mods/dbf_hud/materials/depth_fill'end
    probe.release();probe=HUD.world_probe.new(sr,function()end)
    local old_rect=sr.Gui.rect
    sr.Gui.bitmap=function(g,material,pos,size,color)assert(material=='mods/dbf_hud/materials/depth_fill');material_draws=material_draws+1;return old_rect()end
    sr.Gui.rect=function(g,pos)assert(pos[3]==1,'foreground must use explicit material');return old_rect()end
    assert(probe.draw(p,cfg,commands));assert(material_draws>=2)
    -- World GUI must omit the broken frost draw and preserve tint transparency.
    local frost_alpha,tint_alpha
    sr.Application.can_get=function()return true end
    sr.Gui.bitmap=function(g,material,pos,size,color)
        assert(material~='mods/dbf_hud/materials/depth_blur')
        if material=='content/ui/shared/material/gui_blur' then frost_alpha=color[1]
        elseif material=='mods/dbf_hud/materials/depth_fill' and pos[3]==1 then tint_alpha=color[1] end
    end
    sr.Gui.rect=function(g,pos,size,color)assert(pos[3]==1);tint_alpha=color[1]end
    local panel={{type='panel',x=0,y=0,w=100,h=80,c={0,0,0},a=.25,frost_a=.8}}
    cfg.frosted=true;assert(probe.draw(p,cfg,panel))
    assert(frost_alpha==nil and tint_alpha==64)
    panel[1].a=0;assert(probe.draw(p,cfg,panel));assert(frost_alpha==nil and tint_alpha==0)
    panel[1].a=.25
    frost_alpha=nil;cfg.frosted=false;assert(probe.draw(p,cfg,panel))
    assert(frost_alpha==nil and tint_alpha==64)
    cfg.frosted=true
    probe.release();sr.Gui.rect=old_rect;sr.Gui.bitmap=nil;sr.Application.can_get=nil
    -- Rebaseline counters for the remaining lifetime checks.
    created,moved,destroyed,drawn=1,1,0,4
    probe=HUD.world_probe.new(sr,function()end);probe.draw(p,cfg);created=1
    local previous=drawn;cfg.world_probe=false
    assert(probe.draw(p,cfg,commands));assert(drawn>=previous+2)
    cfg.world_probe=true
    probe.draw(nil,cfg);probe.release();assert(destroyed==1)
    probe.draw(p,cfg);worlds={2};probe.draw(p,cfg);assert(created==3 and destroyed==1)
    cfg.world_probe=false;probe.draw(p,cfg);assert(destroyed==2)
    cfg.world_probe=true;sr.World.create_world_gui=function()error('unsupported binding')end
    probe.draw(p,cfg);assert(probe.status:find('unsupported binding'))
    sr.World.create_world_gui=function()error('must not retry')end;probe.draw(p,cfg)
    assert(probe.status:find('unsupported binding'))
end)

test('offscreen test waits for render, preserves returns and releases in order',function()
    local events={};local rendered=0
    local function event(name,ret)return function(...)events[#events+1]=name;return ret end end
    local original=function(a)return a,nil,9 end
    local globals={render=original}
    local env=setmetatable({_G=globals},{__index=_G})
    local bridge=assert(loadfile('bridge/render_bridge.lua'));setfenv(bridge,env);bridge()
    local host_render=globals.render
    local sr={Application={can_get=function()return true end,new_world=event('world',1),
        release_world=event('free world'),create_viewport=event('viewport',2),destroy_viewport=event('free viewport'),
        render_world=function(w,c,v,e)assert(w==1 and c==4 and v==2 and e==5);rendered=rendered+1 end},
        World={update=function(w,dt)assert(w==1 and dt==0);events[#events+1]='world update' end,spawn_unit=event('unit',3),create_default_shading_environment=event('environment',5),
        destroy_shading_environment=event('free environment'),create_screen_gui=event('gui',6),destroy_gui=event('free gui')},
        Unit={camera=function(u,n)assert(u==3 and n==1);return 4 end},
        Renderer={create_resource=event('texture',7),destroy_resource=event('free texture')},
        Viewport={set_output_render_target=function(v,t)assert(v==2 and t==7)end},
        Gui={rect=event('rect')},Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,Color=function(...)return {...}end}
    local messages={}
    local probe=HUD.offscreen_test.start(sr,function(line)messages[#messages+1]=line end,globals)
    assert(rendered==0 and globals.render==host_render)
    globals.render(8);assert(rendered==0)
    probe.tick();assert(events[#events]=='world update')
    local a,b,c=globals.render(8);assert(a==8 and b==nil and c==9 and rendered==1)
    assert(table.concat(messages,'\n'):find('Gui.material unavailable',1,true))
    globals.render(8);assert(rendered==1)
    probe.release();assert(globals.render==host_render)
    assert(table.concat(events,','):find('free gui,free viewport,free environment,free world,free texture',1,true))
    local count=#events;probe.release();assert(#events==count)
    globals.HUDRenderBridge=nil;HUD.offscreen_test.start(sr,function()end,globals);assert(#events==count)
    globals.HUDRenderBridge=bridge()
    sr.Gui.destroy_rect=event('free rect')
    sr.Gui.rect=function(gui,pos,size)assert(pos[1]==0 and pos[2]==0 and size[1]==80 and size[2]==40);return 1 end
    local panel_width=20
    local dynamic=HUD.offscreen_test.start(sr,function()end,globals,function()return {{type='rect',x=0,y=0,w=panel_width,h=10,c={255,255,255},a=1}} end)
    dynamic.tick(0);globals.render(8);assert(rendered==2)
    dynamic.tick(0.01);globals.render(8);assert(rendered==2)
    dynamic.tick(0.1);globals.render(8);assert(rendered==3)
    panel_width=30;dynamic.tick(0.1);assert(dynamic.resize_required);globals.render(8);assert(rendered==3)
    dynamic.release()
end)

test('startup render bridge isolates subscribers and keeps host callback',function()
    local calls=0;local globals={render=function(v)calls=calls+1;return v,nil,17 end}
    local env=setmetatable({_G=globals},{__index=_G})
    local chunk=assert(loadfile('bridge/render_bridge.lua'));setfenv(chunk,env);local bridge=chunk()
    local installed=globals.render;assert(chunk()==bridge and globals.render==installed)
    local old=bridge.subscribe('test',function()error('old callback')end)
    local ran=0;local remove=bridge.subscribe('test',function()ran=ran+1 end);old()
    local a,b,c=globals.render(9);assert(a==9 and b==nil and c==17 and ran==1)
    bridge.subscribe('broken',function()error('isolated')end);globals.render(9)
    assert(calls==2 and bridge.errors.broken)
    remove();globals.render(9);assert(ran==2 and globals.render==installed)
end)

test('occlusion toggle switches renderers exclusively and releases the previous path',function()
    local original_new,original_overlay=HUD.scene_test.new,HUD.world_probe.new
    local draws={front=0,back=0,gui=0,depth=0};local releases={front=0,back=0,gui=0,depth=0}
    local function stub(key)return {draw=function()draws[key]=draws[key]+1;return true end,release=function()releases[key]=releases[key]+1 end}end
    HUD.scene_test.new=function(sr,log,side) if side then return stub(side==1 and 'front' or 'back')end return original_new(sr,log,side)end
    HUD.world_probe.new=function(sr,log,direct)return stub(direct and 'gui' or 'depth')end
    local carrier=HUD.scene_test.new({},function()end)
    local commands={{x=0,y=0,w=100,h=50}}
    carrier.draw({}, {occlusion_mode='gui_depth'},nil,0.016,nil,commands)
    assert(draws.depth==1 and draws.front==0 and draws.back==0)
    carrier.draw({}, {occlusion_mode='gui'},nil,0.016,nil,commands)
    assert(draws.gui==1 and draws.depth==1 and releases.depth==2)
    carrier.draw({}, {occlusion_mode='mesh'},nil,0.016,nil,commands)
    assert(draws.depth==2 and draws.front==0 and draws.back==0)
    carrier.release()
    HUD.scene_test.new,HUD.world_probe.new=original_new,original_overlay
end)

test('scene carrier binds once, retires on pose loss and rejects null materials',function()
    local destroyed,bindings,moves=0,0,0
    local scale
    local material=65536
    local sr={Application={worlds=function()return {1}end,main_world=function()return 1 end,can_get=function()return true end},
        World={spawn_unit=function()return 2 end,destroy_unit=function()destroyed=destroyed+1 end},
        Unit={set_material=function(_,slot,name)assert(slot=='material' and name=='content/art_shared/materials/placeholder_red_transparent')end,num_meshes=function()return 1 end,mesh=function()return 3 end,set_local_pose=function()moves=moves+1 end,set_local_scale=function(_,_,v)scale=v end},
        Mesh={num_materials=function()return 1 end,material=function()return material end},
        Material={set_resource=function()bindings=bindings+1 end,set_scalar=function()end,set_vector2=function(_,key,v)assert((key=='uv_scale' and v[1]==-1 and v[2]==1) or (key=='uv_offset' and v[1]==1 and v[2]==0))end,set_vector3=function()end},
        Matrix4x4={from_axes=function(...)return {...}end},Vector2=function(...)return {...}end,Vector3=function(...)return {...}end}
    local p={id=1,candidate=1,x=0,y=0,z=0,matrix={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}}
    local probe=HUD.scene_test.new(sr,function()end,1)
    probe.draw(p,HUD.config.new(),131072,0.016);probe.draw(p,HUD.config.new(),131072,0.016)
    assert(bindings==2 and moves==2)
    -- Asset mesh XZ is rotated into root XY by its internal joint transform.
    -- A 2:1 image must therefore have twice the root-X extent as root-Y.
    assert(math.abs(scale[1]/scale[2]-2)<1e-6 and scale[3]==0.24)
    probe.draw(nil,HUD.config.new(),131072,0.016);assert(destroyed==1)
    probe.release();assert(destroyed==1)
    material=0
    local bad=HUD.scene_test.new(sr,function()end,1);bad.draw(p,HUD.config.new(),131072,0.016)
    assert(bindings==2 and destroyed==2)
    material=65536
    local poses={}
    sr.Unit.set_local_pose=function(_,_,v)poses[#poses+1]=v end
    -- Archived mesh implementation is checked directly, never exposed by dispatch.
    local front=HUD.scene_test.new(sr,function()end,1);local back=HUD.scene_test.new(sr,function()end,-1)
    local pair={draw=function(...)front.draw(...);back.draw(...)end,release=function()front.release();back.release()end}
    pair.draw(p,HUD.config.new(),131072,0.016,2)
    assert(bindings==6 and #poses==2)
    for i=1,3 do
        assert(poses[1][1][i]==-poses[2][1][i])
        assert(poses[1][2][i]==poses[2][2][i])
        assert(poses[1][3][i]==-poses[2][3][i])
    end
    pair.release();assert(destroyed==4)
    pair.release();assert(destroyed==4)
end)

test('camera placement heuristic has hysteresis and fails back on missing data',function()
    assert(HUD.projection.first_person(false,.508,1.047))
    assert(not HUD.projection.first_person(false,1.25,1.571))
    assert(HUD.projection.first_person(true,.8,1.35))
    assert(not HUD.projection.first_person(false,.8,1.35))
    assert(not HUD.projection.first_person(true,nil,nil))
end)

test('shoulder placement separates observed views with hysteresis',function()
    assert(HUD.projection.left_shoulder(false,.95,false))
    assert(not HUD.projection.left_shoulder(true,.16,false))
    assert(HUD.projection.left_shoulder(true,.55,false))
    assert(not HUD.projection.left_shoulder(false,.55,false))
    assert(not HUD.projection.left_shoulder(true,.95,true))
    assert(not HUD.projection.left_shoulder(true,nil,false))
end)

test('bundle compiles and excludes crashing diagnostic paths',function()
    assert(loadfile('dist/dbf_hud.lua'))
    local live=assert(loadfile('mdl/dbf_hud/mod.lua'))()
    assert(type(live.on_enable)=='function' and type(live.on_update)=='function' and type(live.on_disable)=='function')
    local f=assert(io.open('dist/dbf_hud.lua','r'));local source=f:read('*a');f:close()
    assert(not source:find('BINDING2',1,true) and not source:find('HUD.probe',1,true))
    assert(not source:find('G.text_extents',1,true) and not source:find('World.units',1,true))
end)
test('sight placement updates without cache and profiles affect only their weapon/view',function()
    local p={id=1,candidate=2,resource_hex='0123456789abcdef',sight={x=0,y=-.1,z=.2}}
    local h={weapon_pose=p,config=HUD.config.new(),clock=0,weapon_clearance={['0123456789abcdef']={right={x=.05}}}}
    local reader={shoulder=function()return nil end}
    HUD.placement.update(h,reader,{}, {avatar_unit_ref=3},function()end)
    assert(math.abs(p.auto_mount.x-.21)<1e-9 and math.abs(p.auto_mount.y)<1e-9)
    p.sight.z=.1;h.first_person=true
    HUD.placement.update(h,reader,{}, {avatar_unit_ref=3},function()end)
    assert(p.auto_mount.x==.12 and math.abs(p.auto_mount.z-.11)<1e-9)
    p.sight.z=.15
    HUD.placement.update(h,reader,{}, {avatar_unit_ref=3},function()end)
    assert(math.abs(p.auto_mount.z-.16)<1e-9)
end)
test('missile pistol shows verified guidance and centered three-digit missile reserves',function()
    local cfg=HUD.config.new()
    for control,label in pairs({[0x50]='GUIDED',[0x54]='UNGUIDED'}) do
        local mode=HUD.ammo_types.missile_pistol_mode(control);assert(mode==label)
        for _,rounds in ipairs({0,1}) do
            local raw=HUD.ammo_types.apply({resource_hex='14d5d4506056c7a4',kind='magazine',rounds=rounds,capacity=1,reserve=4,ammo_mode=mode})
            local list=HUD.layout.compose(HUD.model.normalize(raw),0,0,1,1,cfg,0)
            local found={}
            for _,c in ipairs(list) do
                if c.type=='text' then
                    assert(c.text==label or c.text=='004' or c.text=='MSL')
                    found[c.text]=c
                end
                if c.hammer_indicator and rounds==0 then assert(c.c[1]==255 and c.c[2]==55) end
            end
            assert(found[label] and found['004'] and found.MSL)
            assert(found['004'].y>found.MSL.y)
        end
    end
    assert(HUD.ammo_types.missile_pistol_mode(0x58)==nil)
end)

test('hammer uses an icon charge indicator and keeps reserve charges when empty',function()
    local cfg=HUD.config.new()
    local function commands(value,clock)
        local raw=HUD.ammo_types.apply({resource_hex='5f3ec9bda2bd8553',kind='magazine',rounds=value,capacity=1,reserve=4,reserve_kind='MAGS'})
        assert(raw.label=='' and raw.reserve_kind=='CHARGES' and raw.ammo_icon=='HAMMER')
        return HUD.layout.compose(HUD.model.normalize(raw),0,0,1,1,cfg,clock)
    end
    local function inspect(list,empty)
        local icon,reserve
        for _,c in ipairs(list) do
            if c.hammer_indicator then icon=c;if empty then assert(c.c[1]==255 and c.c[2]==55) end end
            if c.type=='text' then
                assert(not c.numeric_display or c.text=='004 CHARGES')
                if c.text=='004 CHARGES' then reserve=true end
            end
        end
        assert(icon and reserve);return icon.a
    end
    local full=inspect(commands(1,0),false)
    local a=inspect(commands(0,0),true);local b=inspect(commands(0,.2),true)
    assert(a~=b and full>=a)
end)

test('five percent weapon scales persist and smaller values are rejected',function()
    local key='0123456789abcdef'
    local profiles={[key]={right={scale=.05}}}
    local parsed=assert(loadstring(HUD.weapon_offsets.serialize(profiles)))()
    local loaded=HUD.weapon_offsets.load({read_weapon_offsets=function()return parsed end},function()end)
    assert(loaded[key].right.scale==.05)
    profiles[key].right.scale=.049
    assert(not pcall(HUD.weapon_offsets.serialize,profiles))
end)

test('missing attachment placement is stable across reload and first view entry',function()
    local function instance()
        return {weapon_pose={id=1,candidate=2,resource_hex='test'},config=HUD.config.new(),clock=0,
            weapon_clearance={test={right={x=.03},first_right={y=-.2}}}}
    end
    local h=instance()
    local mounts={}
    for _,first in ipairs({false,true,false,true}) do
        h.first_person=first
        HUD.placement.update(h,{}, {}, {avatar_unit_ref=3},function()end)
        local m=h.weapon_pose.auto_mount
        assert(m)
        local key=first and 'first' or 'third'
        if mounts[key] then assert(m.x==mounts[key].x and m.y==mounts[key].y and m.z==mounts[key].z) end
        mounts[key]=m
        h.clock=h.clock+10
    end
    h=instance();h.first_person=true
    HUD.placement.update(h,{}, {}, {avatar_unit_ref=3},function()end)
    local m=h.weapon_pose.auto_mount
    assert(m.x==mounts.first.x and m.y==mounts.first.y and m.z==mounts.first.z)
end)

test('automatic clearance follows scale around sight without accumulating or changing depth',function()
    local p={id=1,candidate=2,resource_hex='0123456789abcdef',sight={x=.3,y=.2,z=.4}}
    local h={weapon_pose=p,config=HUD.config.new(),clock=0,weapon_clearance={}}
    for _,first in ipairs({false,true}) do
        h.first_person=first
        local base
        for _,scale in ipairs({1,.5,2,1}) do
            h.config.scale=scale
            HUD.placement.update(h,{}, {}, {avatar_unit_ref=3},function()end)
            local m=p.auto_mount
            if not base then base=m end
            assert(math.abs(m.x-(p.sight.x+(base.x-p.sight.x)*scale))<1e-9)
            assert(math.abs(m.z-(p.sight.z+(base.z-p.sight.z)*scale))<1e-9)
            assert(m.y==base.y)
        end
    end
end)

test('shotgun shell icons share Double Freedom hull and brass colors',function()
    assert(HUD.fire_icons.SHELL==HUD.fire_icons.BARREL_SHELL)
    local m=HUD.model.normalize({kind='magazine',rounds=4,capacity=8,reserve=2,label='SHELLS',ammo_icon='SHELL'})
    local commands=HUD.layout.compose(m,0,0,1,1,HUD.config.new(),0)
    local blue,gold=false,false
    for _,command in ipairs(commands) do
        if command.mode_icon and command.c then
            blue=blue or (command.c[1]==65 and command.c[2]==145 and command.c[3]==235)
            gold=gold or (command.c[1]==218 and command.c[2]==172 and command.c[3]==78)
        end
    end
    assert(blue and gold)
end)

test('Airburst live controls select flak and cluster labels and icons',function()
    for control,mode in pairs({[0x50]='FLAK',[0x54]='CLUSTER'}) do
        assert(HUD.ammo_types.airburst_mode(control)==mode)
        local raw=HUD.ammo_types.apply({resource_hex='26e40437ea275296',ammo_mode=mode,rounds=1,capacity=1})
        assert(raw.label==mode and raw.ammo_icon==(mode=='CLUSTER' and 'AIRBURST_CLUSTER' or 'AIRBURST'))
        local commands=HUD.layout.compose(HUD.model.normalize(raw),0,0,1,1,HUD.config.new(),0)
        local icon=false
        for _,command in ipairs(commands) do icon=icon or command.mode_icon==true or command.catalog_heading==true end
        assert(icon)
    end
    assert(HUD.ammo_types.airburst_mode(0x51)==nil)
end)

test('weapon blacklist persists and removing one weapon preserves others',function()
    local cfg=HUD.config.new();local a,b='0123456789abcdef','fedcba9876543210'
    assert(not HUD.config.is_blacklisted(cfg,a))
    HUD.config.apply(cfg,{weapon_blacklist=HUD.config.blacklist_value(cfg,a,true)})
    HUD.config.apply(cfg,{weapon_blacklist=HUD.config.blacklist_value(cfg,b,true)})
    local saved=assert(loadstring(HUD.config.serialize(cfg)))()
    assert(HUD.config.is_blacklisted(saved,a) and HUD.config.is_blacklisted(saved,b))
    HUD.config.apply(cfg,{weapon_blacklist=HUD.config.blacklist_value(cfg,a,false)})
    assert(not HUD.config.is_blacklisted(cfg,a) and HUD.config.is_blacklisted(cfg,b))
    assert(not pcall(HUD.config.apply,cfg,{weapon_blacklist='abc'}))
end)

test('external profiles reject malformed data and empty table clears built-in profiles',function()
    local errors=0;local log=function()errors=errors+1 end
    assert(next(HUD.weapon_offsets.load({read_weapon_offsets=function()return {} end},log))==nil)
    local bad={['0123456789abcdef']={right={x=0/0}}}
    assert(HUD.weapon_offsets.load({read_weapon_offsets=function()return bad end},log)==HUD.config.weapon_clearance and errors==1)
end)
test('autocannon reload reminder pulses at five and below and low warning starts at three',function()
    local function model(n,key) return HUD.model.normalize({kind='magazine',rounds=n,capacity=10,resource_hex=key or 'a8cffb316f0b5c5f'}) end
    assert(model(5).reload_reminder and not model(5).warning)
    assert(model(4).reload_reminder and not model(4).warning)
    assert(model(3).warning and model(3).reload_reminder)
    assert(model(0).warning and model(0).state=='EMPTY')
    assert(not model(5,'other').reload_reminder)
    assert(not model(6).reload_reminder)
    for n=0,5 do assert(model(n).reload_reminder) end
    local function number_alpha(clock)
        for _,v in ipairs(HUD.layout.compose(model(5),0,0,1,1,HUD.config.defaults,clock)) do
            if v.type=='text' and v.text=='005' then return v.a end
        end
        error('ammo number missing')
    end
    assert(number_alpha(0)>number_alpha(.25))
end)
test('ammo labels preserve heat and magazine reserves and tolerate unknown projectiles',function()
    local raw=HUD.ammo_types.apply({kind='magazine',resource_hex='unknown',reserve_kind='MAGS',projectile_type=99999})
    assert(raw.label=='ROUNDS' and raw.reserve_kind=='MAGS')
    raw=HUD.ammo_types.apply({kind='heat',reserve_kind='SINKS'})
    assert(raw.label==nil and raw.reserve_kind=='SINKS')
end)
test('plasma ammunition uses bolts and battery reserves for each catalog variant',function()
    for _,id in ipairs({'05d8d8c073b9d502','e8d5f49ad7780e54','eea5e3cef1e12c14','efdcef306cea63fe','fb3a19078694708a'}) do
        local raw=HUD.ammo_types.apply({kind='magazine',resource_hex=id,reserve_kind='MAGS'})
        assert(raw.label=='BOLTS' and raw.reserve_kind=='BATTS' and raw.ammo_icon=='PLASMA')
    end
    local alt=HUD.ammo_types.apply({kind='magazine',resource_hex='fb3a19078694708a',ammo_resource_hex='02cd7321cd8445f5',alternate_fire=true,reserve_kind='ROUNDS'})
    assert(alt.label=='40MM HE' and alt.reserve_kind=='GRNDS')
end)

test('rear heat gauge keeps warning zones and opposing readouts contained in world view',function()
    for _,fraction in ipairs({0,.25,.5,.8,1}) do
        local m=HUD.model.normalize({kind='heat',heat=fraction,reserve=2})
        local cfg=HUD.config.new();cfg.decoration='double'
        local d=HUD.layout.compose(m,0,0,2,1,cfg,0)
        for _,commands in ipairs({d,HUD.world_style.prepare(d,{first_person=true},cfg)}) do
            local backgrounds,background,filled,left,right=0,0,0
            for _,v in ipairs(commands) do
                assert(not v.heat_child)
                if v.heat_background then backgrounds=backgrounds+1;background=background+v.w end
                if v.heat_fill then filled=filled+v.w;assert(v.y>=commands[1].y and v.y+v.h<=commands[1].y+commands[1].h) end
                if v.heat_label=='left' then left=v end
                if v.heat_label=='right' then right=v end
            end
            assert(backgrounds==3 and math.abs(filled/background-fraction)<1e-9)
            assert(left and right and left.x<right.x and left.y>right.y and left.text:find('HEAT:') and right.text=='002:HTSNKS')
            local a,b,e,f=HUD.font.measure(left.text,left.size,left.font,true)
            local ra,rb,re,rf=HUD.font.measure(right.text,right.size,right.font,true)
            assert(left.x+e<right.x+ra)
        end
    end
end)
test('Sterilizer gas uses draining fuel gauge and cloud icon',function()
    local raw=HUD.ammo_types.apply({kind='magazine',resource_hex='88f61afff48ac8a4',rounds=113,capacity=125,reserve=4,reserve_kind='MAGS'})
    local m=HUD.model.normalize(raw)
    assert(m.label=='GAS'and m.reserve_kind=='TANKS'and m.ammo_icon=='GAS'and math.abs(m.fraction-113/125)<1e-6)
    local commands=HUD.layout.compose(m,0,0,1,1,HUD.config.defaults,0)
    local prefix,cloud,fill=false,false,false
    for _,c in ipairs(commands)do
        if c.text=='GAS: 'then prefix=true end
        if c.fuel_flame then cloud=true end
        if c.fuel_fill then fill=true end
    end
    assert(prefix and cloud and fill)
end)

test('fuel gauge drains across reversed warning zones in screen and world views',function()
    for _,id in ipairs({'39ab99895147a3bf','4fb0f8c02f55c82b','78a8185f63a70795','8a307bd1811a5fe9'}) do
        for _,n in ipairs({100,50,20,5,0}) do
            local raw=HUD.ammo_types.apply({kind='magazine',resource_hex=id,alternate_fire=id=='8a307bd1811a5fe9',rounds=n,capacity=100,reserve=3,reserve_kind='MAGS'})
            local model=HUD.model.normalize(raw)
            local commands=HUD.layout.compose(model,0,0,1,1,HUD.config.defaults,0)
            for _,view in ipairs({commands,HUD.world_style.prepare(commands,{first_person=true},HUD.config.defaults)}) do
                local labels,bg,fill,flame={},0,0,false
                for _,v in ipairs(view) do
                    if v.type=='text' then labels[v.text]=v end
                    if v.fuel_background then bg=bg+v.w end
                    if v.fuel_fill then fill=fill+v.w end
                    if v.fuel_flame then flame=true end
                    assert(not v.heat_danger)
                end
                assert(labels.E and labels.F and labels['003 TANKS'] and labels['FUEL: '] and labels[string.format('%03d',n)] and flame)
                assert(math.abs(fill/bg-n/100)<1e-9)
            end
        end
    end
    assert(HUD.ammo_types.deposit_capacity('43eb1c3c1a1860e0')==500)
end)

test('fuel endpoint splits its strokes precisely at the moving fill edge',function()
    local commands={{type='rect',fuel_fill=true,x=0,y=0,w=3.25,h=10},
        {type='text',text='F',fuel_endpoint=true,x=0,y=0,size=10,a=1}}
    HUD.layout.fuel_marker(commands,function()return 0,0,6,10 end)
    local black,white=false,false
    for _,v in ipairs(commands) do if v.fuel_marker_piece then
        if v.c[1]==0 then black=true;assert(v.x+v.w<=3.25)
        else white=true;assert(v.x>=3.25) end
    end end
    assert(black and white)
    local count=#commands
    HUD.layout.fuel_marker(commands,function()return 0,0,6,10 end)
    assert(#commands==count)
end)
test('De-escalator keeps its grenade icon with selectable fire modes',function()
    local railgun=HUD.ammo_types.apply({kind='magazine',resource_hex='2e9d0bdc48b09e60',reserve_kind='MAGS'})
    assert(railgun.reserve_kind=='SHOTS' and railgun.ammo_icon=='RAILGUN' and #HUD.fire_icons.RAILGUN.runs>0)
    local regular=HUD.ammo_types.apply({kind='rounds',resource_hex='02eecd0b1fa49630',fire_mode='SEMI',reserve_kind='MAGS'})
    assert(regular.ammo_icon=='GL_GRENADE' and regular.reserve_kind=='BELTS' and #HUD.fire_icons.GL_GRENADE.runs>0)
    assert(HUD.ammo_types.apply({kind='magazine',resource_hex='11c27d3babb38956',reserve_kind='MAGS'}).reserve_kind=='BELTS')
    for _,mode in ipairs({'SEMI','AUTO','BURST'}) do
        local raw=HUD.ammo_types.apply({kind='rounds',resource_hex='fe3b29b2cfa63f9b',fire_mode=mode,rounds=3,capacity=3,reserve=4,reserve_kind='ROUNDS'})
        assert(raw.ammo_icon=='DEESCALATOR' and raw.fire_mode==mode and raw.reserve_kind=='GRNDS')
        local commands=HUD.layout.compose(HUD.model.normalize(raw),0,0,1,1,HUD.config.defaults,0)
        local icon=false
        for _,v in ipairs(commands) do if v.mode_icon or v.catalog_heading then icon=true end end
        assert(icon)
    end
end)
test('Melta uses larger upright thermal oval with shots and canister reserves',function()
    local raw=HUD.ammo_types.apply({kind='magazine',resource_hex='6cfcc7f8801a0266',reserve_kind='MAGS'})
    assert(raw.label=='SHOTS' and raw.ammo_icon=='MELTA' and raw.reserve_kind=='CNSTRS')
    assert(HUD.fire_icons.MELTA.scale==1.4 and HUD.fire_icons.MELTA.h>HUD.fire_icons.MELTA.w)
    assert(HUD.fire_icons.MELTA and #HUD.fire_icons.MELTA.runs>0)
end)

test('extra chamber count uses native total and colors only above capacity',function()
 local raw={kind='magazine',rounds=31,capacity=30,chamber_supported=true,chamber_rounds=1,label='ROUNDS'}
 local m=HUD.model.normalize(raw);assert(m.value==31 and m.chamber_bonus==1)
 local found=false
 for _,v in ipairs(HUD.layout.compose(m,0,0,1,1,HUD.config.defaults,0)) do
  assert(v.text~='ROUNDS +1');if v.text=='031' then assert(v.last_digit_color);found=true end
 end
 assert(found)
 raw.rounds=30;m=HUD.model.normalize(raw);assert(m.value==30 and not m.chamber_bonus)
 raw.kind='rounds';raw.rounds=9;raw.capacity=8;m=HUD.model.normalize(raw);assert(m.value==9 and m.chamber_bonus==1)
 raw.capacity=nil;assert(not HUD.model.normalize(raw).chamber_bonus)
end)
test('autocannon mode is explicit and its indicator fits beside the count',function()
    assert(HUD.ammo_types.autocannon_mode(0x50)=='APHET')
    assert(HUD.ammo_types.autocannon_mode(0x54)=='FLAK')
    assert(HUD.ammo_types.autocannon_mode(0x1050)=='APHET')
    assert(HUD.ammo_types.autocannon_mode(0x1054)=='FLAK')
    assert(HUD.ammo_types.autocannon_mode(0x51)==nil)
    assert(HUD.ammo_types.autocannon_mode(nil)==nil)
    assert(HUD.ammo_types.fire_mode(1)=='AUTO')
    assert(HUD.ammo_types.fire_mode(2)=='SEMI')
    assert(HUD.ammo_types.fire_mode(3)=='BURST')
    assert(HUD.ammo_types.fire_mode(8)=='ALT')
    assert(HUD.ammo_types.fire_mode(4)==nil)
    assert(HUD.ammo_types.selectable_fire_mode(1,{1,2,0})=='AUTO')
    assert(HUD.ammo_types.selectable_fire_mode(2,{1,2,0})=='SEMI')
    assert(HUD.ammo_types.selectable_fire_mode(8,{2,8,0})=='ALT')
    assert(HUD.ammo_types.selectable_fire_mode(1,{1,0,0})==nil)
    assert(HUD.ammo_types.selectable_fire_mode(1,{1,1,0})==nil)
    assert(HUD.ammo_types.selectable_fire_mode(8,{1,2,0})==nil)
    for _,mode in ipairs({'APHET','FLAK'}) do
        local m=HUD.model.normalize({kind='rounds',rounds=10,capacity=10,ammo_mode=mode,label='AMMO'})
        assert(not m.chamber_bonus)
        local commands=HUD.layout.compose(m,0,0,1,1,HUD.config.defaults,0)
        local panel=commands[1];local number,indicator
        for _,v in ipairs(commands) do
            if v.type=='text' and v.text=='010' then number=v end
            if v.type=='text' and v.text==mode then indicator=v end
            if v.type=='rect' and not v.decoration then
                assert(v.x>=panel.x and v.y>=panel.y and v.x+v.w<=panel.x+panel.w and v.y+v.h<=panel.y+panel.h)
            end
        end
        assert(number and indicator and indicator.y>number.y)
        local a,b,e=HUD.font.measure(indicator.text,indicator.size,HUD.config.defaults.font)
        assert(math.abs(indicator.x+(a+e)/2-(panel.x+panel.w/2))<1e-6)
    end
end)
test('fire-mode child frame inherits decorations and remains separate after world scaling',function()
    local m=HUD.model.normalize({kind='rounds',rounds=10,capacity=10,ammo_mode='FLAK',fire_mode='AUTO',label='AMMO'})
    for _,style in ipairs({'outline','brackets','helldivers','double'}) do
        local cfg=HUD.config.new();cfg.decoration=style
        local commands=HUD.layout.compose(m,0,0,1,1,cfg,0)
        local child,decorations
        for _,v in ipairs(commands) do
            if v.child and v.type=='panel' then child=v end
            if v.child and v.decoration then decorations=true end
        end
        assert(child and decorations)
        assert(child.w==commands[1].w)
        assert(math.abs(commands[1].y-(child.y+child.h)-2)<1e-6)
        assert(math.abs(child.x+child.w/2-(commands[1].x+commands[1].w/2))<1e-6)
        local world=HUD.world_style.prepare(commands,{first_person=true},cfg)
        local frame=world[1];local text
        for _,v in ipairs(world) do
            if v.child and v.type=='panel' then child=v end
            if v.child and v.type=='text' then text=v end
        end
        assert(child.y+child.h<frame.y)
        assert(child.w==frame.w)
        local a,b,e,f=HUD.font.measure(text.text,text.size,cfg.font,true)
        assert(text.x+a>=child.x and text.x+e<=child.x+child.w)
        assert(text.y+b>=child.y and text.y+f<=child.y+child.h)
    end
end)
test('game fire-mode masks fit the count row and alternate labels stay isolated',function()
    for _,mode in ipairs({'AUTO','SEMI','BURST','ALT'}) do
        local icon=assert(HUD.fire_icons[mode]);assert(#icon.runs>0)
        local commands=HUD.layout.compose({kind='rounds',value=1,label='40MM HE',reserve=5,reserve_kind='GRNDS',state='READY',fire_mode=mode},0,0,1,1,HUD.config.defaults,0)
        local frame=commands[1];local count=0
        for _,v in ipairs(commands) do if v.mode_icon then
            count=count+1;assert(v.x>=frame.x and v.x+v.w<=frame.x+frame.w)
            assert(v.y>=frame.y and v.y+v.h<=frame.y+frame.h)
        end end
        assert(count==#icon.runs)
    end
    local raw=HUD.ammo_types.apply({kind='rounds',resource_hex='a955c4ea6f6d4203',ammo_resource_hex='02cd7321cd8445f5',alternate_fire=true,reserve_kind='ROUNDS'})
    assert(raw.label=='40MM HE' and raw.reserve_kind=='GRNDS')
end)
test('ordinary ammo rows center against the final frame',function()
    local cfg={};for k,v in pairs(HUD.config.defaults) do cfg[k]=v end
    local commands=HUD.layout.compose({kind='magazine',value=40,label='ROUNDS',chamber_bonus=1,reserve=2,reserve_kind='MAGS',state='READY',fire_mode='BURST'},0,0,2,1,cfg,0,function(t,size)return HUD.font.measure(t,size,cfg.font) end)
    commands=HUD.world_style.prepare(commands,{first_person=false},cfg)
    local panel=commands[1];local center=panel.x+panel.w/2
    for _,v in ipairs(commands) do
        if v.center_in_frame and not v.mode_count then
            local a,b,e,f=HUD.font.measure(v.text,v.size,v.font,true)
            assert(math.abs(v.x+(a+e)/2-center)<.001)
        end
    end
end)
test('laser catalog symbols and heat rows share centered presentation',function()
    local cfg=HUD.config.new()
    local raw=HUD.ammo_types.apply({kind='heat',resource_hex='d54b9505c0f72873',heat=.62,reserve=3})
    assert(raw.energy_icon=='LASER')
    local m=HUD.model.normalize(raw);assert(m.energy_icon=='LASER')
    local commands=HUD.layout.compose(m,0,0,2,1,cfg,0)
    commands=HUD.world_style.prepare(commands,{first_person=false},cfg)
    local panel=commands[1];local center=panel.x+panel.w/2;local symbols=0
    for _,v in ipairs(commands) do
        if v.mode_icon then symbols=symbols+1 end
        if v.center_in_frame and not v.mode_count then
            local a,b,e,f=HUD.font.measure(v.text,v.size,v.font,true)
            assert(math.abs(v.x+(a+e)/2-center)<.001)
        end
    end
    assert(symbols==0) -- Heat now uses the bespoke meter rather than a number-and-icon panel.
    raw=HUD.ammo_types.apply({kind='rounds',resource_hex='5990123d142b16cb'})
    assert(not raw.energy_icon,'laser-guided missiles are not beam weapons')
end)
test('all 72 native families have finite bounds and selectable labels',function()
    local count=0
    for name,face in pairs(HUD.native_font_data.faces) do
        count=count+1;assert(face.font and face.depth and face.clear and face.label)
        local cfg=HUD.config.new();HUD.config.apply(cfg,{font=name})
        for _,size in ipairs({6,12,36,53.5}) do
            local a,b,e,f=HUD.font.measure('0123456789 AMMO +1 HEAT',size,name)
            assert(a==a and b==b and e>a and f>b)
        end
    end
    assert(count==72 and #HUD.config.fonts==72)
end)
test('direct appearance menu exposes all fonts styles and color wheels',function()
    local spec,removed,writes
    writes=0
    DBFMCM={register=function(v)spec=v;return {unregister=function()removed=true end}end}
    local h={config=HUD.config.new(),save_tuning=function()writes=writes+1 end}
    h.configure=function(v)HUD.config.apply(h.config,v)end
    local menu=HUD.menu.new(h);menu.poll()
    assert(spec)
    local controls={};for _,v in ipairs(spec.pages[1].controls)do controls[v.id]=v end
    assert(#controls.family.choices==72 and controls.hud_scale.type=='slider' and #controls.display_mode.choices==3)
    assert(#controls.style.choices==5 and controls.panel_color.type=='color' and controls.decoration_color.type=='color')
    controls.style.on_change(5);assert(h.config.style_3d=='retro')
    controls.panel_color.on_change('#123456');assert(h.config.background_color=='#123456')
    controls.decoration_color.on_change('#ABCDEF');assert(h.config.decoration_color=='#ABCDEF' and writes==3)
    menu.retire();assert(removed);controls.style.on_change(1);assert(h.config.style_3d=='retro')
    DBFMCM=nil
end)
test('native resource resolver selects separate clear and depth materials',function()
    local sr={Application={can_get=function()return true end}}
    local face=HUD.native_font_data.faces.hack
    local font,material=HUD.native_font.resolve(sr,'hack',false);assert(font==face.font and material==face.clear)
    font,material=HUD.native_font.resolve(sr,'hack',true);assert(font==face.font and material==face.depth)
    assert(not HUD.font.draw,'rectangle glyph renderer must not exist')
end)
test('missing native resources use native debug and fail closed for unverified depth',function()
    local sr={Application={can_get=function()return false end}}
    local font,material=HUD.native_font.resolve(sr,'hack',false)
    assert(font=='core/performance_hud/debug' and material==font)
    assert(HUD.native_font.resolve(sr,'hack',true)==nil)
end)
test('screen font commands make one native draw and no glyph rectangles',function()
    local texts,rects,destroyed=0,0,0
    local sr={Application={worlds=function()return {1}end,main_world=function()return 1 end,can_get=function()return true end},
        World={create_screen_gui=function()return 2 end,destroy_gui=function()end},
        Vector2=function(...)return {...}end,Vector3=function(...)return {...}end,Color=function(...)return {...}end,
        Gui={rect=function()rects=rects+1 end,text=function(g,t,font,size,material)texts=texts+1;assert(font==HUD.native_font_data.faces.hack.font and material==HUD.native_font_data.faces.hack.clear);return texts end,destroy_text=function()destroyed=destroyed+1 end}}
    local view=HUD.view.new(sr)
    view.draw({{type='text',text='40MM HE',font='hack',size=36,x=0,y=0,a=1,c={255,255,255}}})
    assert(texts==1 and rects==0);view.release();assert(destroyed==1)
end)
test('Stoker labels follow its active ammo source and fuel has no grenade icon or chamber bonus',function()
    local primary=HUD.ammo_types.apply({kind='magazine',resource_hex='8a307bd1811a5fe9',rounds=41,capacity=40,chamber_supported=true,chamber_rounds=1,fire_mode='AUTO'})
    assert(primary.label=='ROUNDS' and HUD.model.normalize(primary).chamber_bonus==1)
    local alt=HUD.ammo_types.apply({kind='magazine',resource_hex='8a307bd1811a5fe9',ammo_resource_hex='unknown',alternate_fire=true,rounds=41,capacity=40,chamber_supported=true,chamber_rounds=1,fire_mode='ALT'})
    local model=HUD.model.normalize(alt)
    assert(alt.label=='FUEL' and model.reserve_kind=='TANKS' and model.ammo_icon=='FUEL' and not model.chamber_bonus)
    assert(HUD.fire_icons[model.ammo_icon]==HUD.fire_icons.FUEL)
end)
test('fixed mode weapons use upright ammo symbols without replacing fire selection',function()
    local fixed=HUD.ammo_types.apply({kind='rounds',resource_hex='ffc18b2ce10ca381'})
    assert(fixed.ammo_icon=='BULLET' and HUD.fire_icons.BULLET.h>HUD.fire_icons.BULLET.w)
    local selected=HUD.ammo_types.apply({kind='rounds',resource_hex='ffc18b2ce10ca381',fire_mode='AUTO'})
    assert(not selected.ammo_icon and selected.fire_mode=='AUTO')
    local stoker=HUD.ammo_types.apply({kind='magazine',resource_hex='8a307bd1811a5fe9'})
    assert(stoker.label=='ROUNDS' and stoker.ammo_icon=='BULLET')
end)
test('published starter layouts are valid and include both tuned and untouched views',function()
    local profiles=assert(loadfile('DBF-HUD-weapon-offsets.lua'))()
    local loaded=HUD.weapon_offsets.load({read_weapon_offsets=function()return profiles end},function(message)error(message)end)
    assert(loaded==profiles)
    local bundled=assert(loadfile('src/bundled_defaults.lua'))()
    local old=HUD.bundled_defaults;HUD.bundled_defaults=bundled
    local defaults=assert(loadfile('src/config.lua'))()
    HUD.bundled_defaults=old
    assert(defaults.defaults.font==bundled.settings.font and defaults.defaults.style_3d==bundled.settings.style_3d)
    assert(defaults.weapon_clearance['14d5d4506056c7a4'].right.x==profiles['14d5d4506056c7a4'].right.x)
    local names=0
    for filename,body in pairs(bundled.presets) do
        assert(filename:match('%.layout$'))
        local value=assert(loadstring(body))();assert(type(value.settings)=='table' and type(value.layouts)=='table')
        HUD.config.apply(HUD.config.new(),value.settings)
        assert(HUD.weapon_offsets.load({read_weapon_offsets=function()return value.layouts end},function(message)error(message)end)==value.layouts)
        names=names+1
    end
    assert(names>=3)
end)

test('all weapon mount views add three inches forward after profile corrections',function()
    local cfg=HUD.config.new();cfg.placement_mode='auto'
    local x,y,z=HUD.scene_test.mount({auto_mount={x=.1,y=.2,z=.3}},cfg)
    assert(x==.1 and math.abs(y-.2762)<1e-9 and z==.3)
    cfg.placement_mode='manual'
    for _,p in ipairs({{}, {first_person=true}, {left_shoulder=true}}) do
        local a,b,c=HUD.scene_test.mount(p,cfg);assert(math.abs(b-.0762)<1e-9)
    end
end)
test('verified Purifier charge readiness pulses only the ammo number cyan',function()
    local raw={kind='rounds',resource_hex='fb3a19078694708a',rounds=12,capacity=15,label='ROUNDS',charge_ready=true}
    local model=HUD.model.normalize(raw);assert(model.charge_ready)
    local commands=HUD.layout.compose(model,0,0,1,1,HUD.config.defaults,0)
    local count=0
    for _,v in ipairs(commands) do
        if v.type=='text' and v.c[1]==0 and v.c[2]==255 and v.c[3]==255 then count=count+1;assert(v.text=='012') end
    end
    assert(count==1)
end)
test('craftsmanship profiles retain mechanical detail and distinguish named ammunition',function()
 local names={'BR-14 Adjudicator','R-63 Diligence','AR-23P Liberator Penetrator','P-113 Verdict','P-4 Senator','M-105 Stalwart','PLAS-45 Epoch','LAS-99 Quasar Cannon','FAF-14 Spear','MLS-4X Commando','GL-21 Grenade Launcher','S-11 Speargun'}
 local families={'precision','precision','precision','sidearm','sidearm','belt','plasma','laser','rocket','rocket','explosive','dart'}
 local signatures={}
 for i,name in ipairs(names) do
  local style={name=name,family=families[i]};local mode={fire_mode='SEMI'}
  local icon=assert(HUD.munition_art.icon(style,mode,HUD.fire_icons.BULLET))
  assert(icon==HUD.munition_art.icon(style,mode,HUD.fire_icons.BULLET),'cached artwork')
  assert(#icon.runs>=15,name)
  local signature={};local colors={}
  for _,r in ipairs(icon.runs) do
   assert(r[3]>0 and r[4]>0,name)
   signature[#signature+1]=table.concat({r[1],r[2],r[3],r[4]},',')
   colors[table.concat(r[5],',')]=true
  end
  local count=0;for _ in pairs(colors)do count=count+1 end;assert(count>=4,name)
  local key=table.concat(signature,';');assert(not signatures[key],name..' duplicates '..tostring(signatures[key]));signatures[key]=name
 end
end)
test('accepted custom panels bypass subsequent catalog redesigns',function()
 for _,id in ipairs({'e6d932be83729076','89c5493e08ca4207','52e4334e6a128caf','2e9d0bdc48b09e60'}) do
  local raw=HUD.ammo_types.apply({resource_hex=id,kind='magazine',rounds=7,capacity=10,reserve=8,reserve_kind='MAGS',safety_mode=id=='2e9d0bdc48b09e60' and 'UNSAFE' or nil})
  local out=HUD.layout.compose(HUD.model.normalize(raw),0,0,1,1,HUD.config.defaults,0)
  local expected=false
  for _,v in ipairs(out)do
   assert(not v.catalog_heading and not v.catalog_detail and not v.catalog_caption,id)
   expected=expected or (id=='e6d932be83729076' and v.text=='R-6 DEADEYE') or (id=='89c5493e08ca4207' and v.amr_heading) or (id=='52e4334e6a128caf' and v.grenade_heading) or (id=='2e9d0bdc48b09e60' and v.railgun_heading)
  end
  assert(expected,id)
 end
end)
test('regular Machine Gun alone keeps linked cartridges right of the measured count',function()
 local id='11c27d3babb38956'
 for _,scale in ipairs({.05,.65,2})do
  local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex=id,kind='magazine',rounds=175,capacity=175,reserve=3,reserve_kind='BELTS',rpm_selectable=true,rpm=900}))
  assert(m.label=='MG-43')
  local commands=HUD.layout.compose(m,0,0,scale,1,HUD.config.defaults,0,function(t,size)return HUD.font.measure(t,size,HUD.config.defaults.font)end)
  local designation=false;for _,v in ipairs(commands)do designation=designation or v.text=='MG-43';assert(v.text~='ROUNDS')end;assert(designation)
  for _,list in ipairs({commands,HUD.world_style.prepare(commands,{first_person=true},HUD.config.defaults)})do
   local number,low,high=nil,math.huge,-math.huge
   for _,v in ipairs(list)do
    if v.mode_count then number=v end
    if v.catalog_side_icon then low=math.min(low,v.x);high=math.max(high,v.x+v.w);assert(v.mode_icon and not v.catalog_heading) end
   end
   assert(number and low<math.huge)
   local a,b,e=HUD.font.measure(number.text,number.size,number.font,true)
   assert(low>number.x+e and high<list[1].x+list[1].w,'side row padding')
  end
 end
 local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='a6a735accb4a327f',kind='magazine',rounds=250,capacity=250,reserve=3,reserve_kind='BELTS'}))
 for _,v in ipairs(HUD.layout.compose(m,0,0,1,1,HUD.config.defaults,0))do assert(not v.catalog_side_icon)end
end)
test('catalog themes cover all known names and preserve bounded geometry and live values',function()
    local total=0
    for id in pairs(HUD.weapon_names) do assert(HUD.weapon_styles.catalog[id],id) end
    for id,style in pairs(HUD.weapon_styles.catalog) do
        total=total+1
        for _,scale in ipairs({.05,.65,2}) do
            for _,mode in ipairs({'SEMI','AUTO','BURST'}) do
                local raw=HUD.ammo_types.apply({resource_hex=id,kind='magazine',rounds=7,capacity=10,reserve=8,reserve_kind='MAGS',fire_mode=mode})
                local m=assert(HUD.model.normalize(raw));local original=m.value
                local commands=HUD.layout.compose(m,0,0,scale,1,HUD.config.defaults,0)
                assert(m.value==original and m.reserve==8 and m.fire_mode==mode,id)
                assert((m.label=='FUEL' or m.label=='GAS' or HUD.ammo_types.laser_weapons[id]) and commands[1].weapon_theme==nil or commands[1].weapon_theme==style.family,id)
                local frame=commands[1];local minx,maxx=math.huge,-math.huge
                for _,v in ipairs(commands) do
                    assert(v.x==v.x and v.y==v.y,id)
                    if v.type~='text' then assert(v.w>0 and v.h>0,id) end
                    if v.catalog_heading or v.catalog_detail then
                        assert(v.x>=frame.x-.0001 and v.y>=frame.y-.0001 and v.x+v.w<=frame.x+frame.w+.0001 and v.y+v.h<=frame.y+frame.h+.0001,id)
                    end
                    if v.catalog_heading then minx=math.min(minx,v.x);maxx=math.max(maxx,v.x+v.w) end
                end
                local measured=HUD.layout.compose(m,0,0,scale,1,HUD.config.defaults,0,function(t,size)return HUD.font.measure(t,size,HUD.config.defaults.font) end)
                local world=HUD.world_style.prepare(measured,{first_person=true},HUD.config.defaults)
                local wf=world[1]
                for _,v in ipairs(world) do if v.catalog_heading then
                    assert(v.x>=wf.x-.001 and v.x+v.w<=wf.x+wf.w+.001 and v.y>=wf.y-.001 and v.y+v.h<=wf.y+wf.h+.001,id..' world heading')
                end end
                if minx<math.huge then
                    assert(math.abs((minx+maxx)/2-frame.x-frame.w/2)<.001,id)
                    for _,v in ipairs(commands) do assert(not v.mode_icon,id) end
                end
            end
        end
    end
    assert(total==148)
    local unknown=HUD.layout.compose({resource_hex='unknown',kind='magazine',value=7,label='ROUNDS',state='READY'},0,0,1,1,HUD.config.defaults,0)
    assert(not unknown[1].weapon_theme)
end)

test('AMR cartridge is centered inside the heading without a duplicate side icon',function()
    local raw=HUD.ammo_types.apply({kind='magazine',resource_hex='89c5493e08ca4207',rounds=7,capacity=7,reserve=6,reserve_kind='MAGS'})
    local commands=HUD.layout.compose(HUD.model.normalize(raw),0,0,1,1,HUD.config.defaults,0)
    local frame=commands[1];local low,high=math.huge,-math.huge;local count=0
    for _,v in ipairs(commands) do
        assert(not v.mode_icon)
        if v.amr_heading then
            count=count+1;low=math.min(low,v.x);high=math.max(high,v.x+v.w)
            assert(v.y>=frame.y and v.y+v.h<=frame.y+frame.h)
        end
    end
    assert(count>0 and low>frame.x and high<frame.x+frame.w)
    assert(math.abs((low+high)/2-frame.x-frame.w/2)<.001)
end)

test('railgun safety child retains projectile and parent width',function()
    for _,mode in ipairs({'SAFE','UNSAFE'}) do
        local raw=HUD.ammo_types.apply({kind='magazine',resource_hex='2e9d0bdc48b09e60',rounds=1,capacity=1,reserve=19,reserve_kind='MAGS',safety_mode=mode,charge_fraction=.5})
        local commands=HUD.layout.compose(HUD.model.normalize(raw),0,0,1,1,HUD.config.defaults,0)
        local label,child,icon
        for _,v in ipairs(commands) do
            if v.child and v.type=='text' and v.text==mode then label=v end
            if v.child and v.type=='panel' then child=v end
            if v.railgun_heading then icon=true end
        end
        assert(label and child and icon)
        local arcs=0
        local frame=commands[1]
        for _,v in ipairs(commands) do if v.railgun_arc then
            arcs=arcs+1
            assert(v.x>=frame.x and v.y>=frame.y and v.x+v.w<=frame.x+frame.w and v.y+v.h<=frame.y+frame.h)
        end end
        assert((mode=='UNSAFE' and arcs>0) or (mode=='SAFE' and arcs==0))
        local meter
        for _,v in ipairs(commands) do if v.charge_meter and v.type=='panel' then meter=v end end
        assert(meter and math.abs(meter.y-child.y)<.001)
        assert(math.abs(meter.y+meter.h-frame.y-frame.h)<.001)
        assert(math.abs(child.w-commands[1].w)<.001)
        local world=HUD.world_style.prepare(commands,{first_person=true},HUD.config.defaults)
        local wf,wm,wc=world[1]
        for _,v in ipairs(world) do
            if v.charge_meter and v.type=='panel' then wm=v end
            if v.child and v.type=='panel' then wc=v end
        end
        assert(wm and wc and math.abs(wm.y-wc.y)<.001)
        assert(math.abs(wm.y+wm.h-wf.y-wf.h)<.001,'world charge height')

    end
end)
test('laser aiming HUD honors independent first-person profiles at every scale',function()
    local p={id=1,candidate=2,resource_hex='27ee1ed8f6fb6356',sight={x=.3,y=.2,z=.4}}
    local h={weapon_pose=p,config=HUD.config.new(),clock=0,weapon_clearance={['27ee1ed8f6fb6356']={right={x=-.0508,z=-.0381},first_left={x=.12,z=-.127},first_right={x=-.12,z=-.127}}}}
    for _,scale in ipairs({.5,1,2}) do
        h.config.scale=scale;h.first_person=false
        HUD.placement.update(h,{}, {}, {avatar_unit_ref=3,energy_icon='LASER'},function()end)
        local expected=p.auto_mount
        for _,side in ipairs({'left','right'}) do
            h.first_person=true;h.config.fp_auto_side=side
            HUD.placement.update(h,{}, {}, {avatar_unit_ref=3,energy_icon='LASER'},function()end)
            local correction=h.weapon_clearance[p.resource_hex]['first_'..side]
            assert(math.abs(p.auto_mount.x-(p.sight.x+(.16+correction.x)*scale))<1e-9)
            assert(math.abs(p.auto_mount.z-(p.sight.z+(.04+correction.z)*scale))<1e-9)
        end
    end
end)
test('heat display reserves three fixed slots and dims only leading zeros',function()
    local reference
    for _,value in ipairs({0,9,10,65,99,100}) do
        local d=HUD.layout.compose(HUD.model.normalize({kind='heat',heat=value/100,reserve=3}),0,0,1,1,HUD.config.new(),0)
        local slots={}
        for _,v in ipairs(d) do if v.heat_digit_slot then slots[v.heat_digit_slot+1]=v end end
        assert(#slots==4)
        local text='';for _,v in ipairs(slots) do text=text..v.text end
        assert(text==string.format('%03d%%',value))
        if reference then
            assert(math.abs(d[1].w-reference.w)<1e-8)
            for i,v in ipairs(slots) do assert(math.abs(v.x-reference.x[i])<1e-8) end
        else reference={w=d[1].w,x={slots[1].x,slots[2].x,slots[3].x,slots[4].x}} end
        if value<100 then assert(slots[1].a<slots[3].a) else assert(slots[1].a==slots[3].a) end
        if value<10 then assert(slots[2].a<slots[3].a) else assert(slots[2].a==slots[3].a) end
    end
end)
test('catalog numeric counters keep fixed slots and dim unused leading zeros',function()
    local bounds
    for _,value in ipairs({0,5,45,99,100}) do
        local t=string.format('%03d',value)
        local a,b,e,f=HUD.font.measure(t,32,'hack')
        if bounds then assert(a==bounds[1] and b==bounds[2] and e==bounds[3] and f==bounds[4]) else bounds={a,b,e,f} end
        local parts=HUD.font.numeric_parts({text=t..' BATTS',numeric_display=true,size=32,font='hack'})
        assert(#parts==4 and parts[4].text==' BATTS')
        assert(parts[3].alpha==1 and parts[4].alpha==1)
        assert(parts[1].alpha==(value<100 and 1/3 or 1))
        assert(parts[2].alpha==(value<10 and 1/3 or 1))
        assert(parts[2].dx-parts[1].dx==parts[3].dx-parts[2].dx)
    end
    local p=HUD.font.numeric_parts({text='-- RES',size=12})
    assert(#p==1 and p[1].text=='-- RES' and p[1].alpha==1)
end)
test('autocannon first-person corrections remain separate for each saved view',function()
    local profiles=assert(loadfile('DBF-HUD-weapon-offsets.lua'))()
    local p={id=1,candidate=2,resource_hex='a8cffb316f0b5c5f',sight={x=.1,y=.2,z=.3}}
    local h={weapon_pose=p,config=HUD.config.new(),clock=0,weapon_clearance=profiles,first_person=true}
    for _,side in ipairs({'left','right'}) do
        h.config.fp_auto_side=side
        local correction=profiles[p.resource_hex]['first_'..side]
        HUD.placement.update(h,{}, {}, {avatar_unit_ref=3},function()end)
        local target=p.auto_mount
        assert(math.abs(target.x-(.1+(side=='right' and .12 or -.12)+(correction.x or 0)))<1e-9)
        assert(math.abs(target.y-(.2+.45+(correction.y or 0)))<1e-9)
        assert(math.abs(target.z-(.3+.01+(correction.z or 0)))<1e-9)
    end
end)

test('forward panel tilt preserves mount and pitches top forty-five degrees',function()
    local m={1,0,0,0,0,1,0,0,0,0,1,0,2,3,4,1}
    local tilted=HUD.pose_motion.forward_tilt(m,math.pi/4)
    assert(math.abs(tilted[10]-math.sqrt(.5))<1e-9 and math.abs(tilted[11]-math.sqrt(.5))<1e-9)
    assert(tilted[13]==2 and tilted[14]==3 and tilted[15]==4)
    assert(m[10]==0 and m[11]==1)
end)
test('layout editor locks weapon, previews active view, saves all profiles and restores baseline',function()
    local key='0123456789abcdef';local other='1111111111111111';local body;local keys={}
    local identity={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
    local h={clock=0,config={fp_auto_side='left'},editor_camera_matrix=identity,weapon_pose={resource_hex=key,matrix=identity},weapon_clearance={
        [key]={right={x=.0254},first_left={z=-.1524}},[other]={right={y=.3}}}}
    local e=HUD.layout_editor.new(h,{write_weapon_offsets=function(v)body=v end,editor_key=function(k)return keys[k] or false end},function()end)
    assert(e.bind());e.set('x',4);assert(math.abs(h.weapon_clearance[key].right.x-.1016)<1e-9)
    h.first_person=true;e.tick(.01);assert(e.view=='first_left');e.set('z',-2)
    assert(e.save());local saved=assert(loadstring(body))();assert(saved[other].right.y==.3 and math.abs(saved[key].first_left.z+.0508)<1e-9)
    e.reset();assert(h.weapon_clearance[key].right.x==.0254 and h.weapon_clearance[key].first_left.z==-.1524)
    keys[38]=true;h.clock=.1;e.tick(.1);assert(math.abs(h.weapon_clearance[key].first_left.z+.1397)<1e-9)
    h.weapon_pose.resource_hex=other;h.clock=.2;e.tick(.1);assert(not e.active and h.weapon_clearance[other].right.y==.3)
    h.weapon_pose.resource_hex=key;h.placement_view_parity=true;assert(e.bind());e.set_view(true);assert(e.view=='first_left')
    local failed=HUD.layout_editor.new(h,{write_weapon_offsets=function()error('disk full')end},function()end)
    assert(failed.bind() and not failed.save());assert(failed.status:find('Save failed',1,true))
end)
test('attachment points persist per view and bone cycling preserves offsets',function()
    local key='968211c0033dce64';local saved
    local h={config={fp_auto_side='right'},first_person=true,weapon_pose={resource_hex=key,anchors={{index=0,hash='12345678'},{index=1,hash='527c9c73'}}},weapon_clearance={
        [key]={right={x=.1},first_right={y=.2}}}}
    local e=HUD.layout_editor.new(h,{write_weapon_offsets=function(body)saved=assert(loadstring(body))()end},function()end)
    assert(e.bind() and e.name=='AR-23 Liberator')
    assert(e.points()[1].value=='root')
    e.cycle(1);assert(h.weapon_clearance[key].first_right.attach_point=='node:4d25685a' and h.weapon_clearance[key].first_right.y==.2)
    e.cycle(1);assert(h.weapon_clearance[key].first_right.attach_point=='node:12345678')
    e.set_scale(1.4)
    assert(e.zero_position())
    local zero=h.weapon_clearance[key].first_right
    assert(zero.x==0 and zero.y==0 and zero.z==0 and zero.scale==1 and zero.attach_point=='node:12345678')
    assert(h.weapon_clearance[key].right.x==.1)
    assert(e.save() and saved[key].first_right.attach_point=='node:12345678' and saved[key].first_right.scale==1 and not saved[key].right.scale and not saved[key].right.attach_point)
    assert(e.status:find('AR-23 Liberator',1,true))
    assert(HUD.weapon_offsets.load({read_weapon_offsets=function()return saved end},function(err)error(err)end)==saved)
    e.reset();assert(not h.weapon_clearance[key].first_right.attach_point and e.scale()==1)
end)
test('native mod binding toggles occlusion once per press and retires cleanly',function()
    local previous=rawget(_G,'ModBindingsMenu');local down=false;local registrations,writes=0,0
    local h={config={force_occlusion=false}}
    h.configure=function(p)h.config.force_occlusion=p.force_occlusion end
    h.save_tuning=function()writes=writes+1 end
    _G.ModBindingsMenu={register_binding=function(id,label,slot,opts)
        assert(id=='dbf_hud_debug.force_occlusion' and label=='Force occlusion' and slot==nil)
        assert(opts.category=='Debug tools - DBF HUD');registrations=registrations+1;return true
    end,is_down=function()return down end}
    local m=HUD.menu.new(h);m.poll_bindings();down=true;m.poll_bindings();m.poll_bindings()
    assert(h.config.force_occlusion and writes==1 and registrations==1)
    assert(m.overlay(1920,1080,'hack')[1].text=='[DEBUG] Occlusion ON')
    down=false;m.poll_bindings();down=true;m.poll_bindings();assert(not h.config.force_occlusion and writes==2)
    assert(m.overlay(1920,1080,'hack')[1].text=='[DEBUG] Occlusion OFF')
    h.clock=3;assert(#m.overlay(1920,1080,'hack')==0)
    m.retire();down=false;m.poll_bindings();down=true;m.poll_bindings();assert(writes==2)
    _G.ModBindingsMenu=previous
end)
test('depth marker draws isolated primitives without moving GUI and releases on missing pose',function()
    local calls,destroyed=0,0;local main={};local sr={}
    sr.Vector3=function(...)return {...}end;sr.Vector2=sr.Vector3;sr.Color=sr.Vector3
    sr.Matrix4x4={identity=function()return {}end,from_axes=function(...)return {...}end}
    sr.Application={main_world=function()return main end,worlds=function()return {main}end,can_get=function()return true end}
    sr.World={create_world_gui=function(w,m,x,y,mode)assert(w==main and x==1 and y==1 and mode=='immediate');return {}end,
        destroy_gui=function()destroyed=destroyed+1 end}
    sr.Gui={bitmap_3d=function(g,material,tm,pos,layer,size,color)
        assert(material=='mods/dbf_hud/materials/depth_state_test_loader_control' and layer==2)
        assert(tm[4][2]==1 and size[1]>0 and size[2]>0);calls=calls+1
    end,move=function()error('must not move GUI')end}
    local p=HUD.depth_marker.new(sr,function(e)error(e)end)
    assert(p.draw({x=0,y=1,z=0},{1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1},1,1080))
    assert(calls==4);assert(not p.draw(nil,nil,nil,1080) and destroyed==1)
end)
test('screen depth candidate uses UI world and persistent bitmap lifecycle',function()
    local main,ui={},{};local made,drawn,removed,destroyed=0,0,0,0
    local access,compare=false,false;local messages={}
    local sr={Vector3=function(...)return {...}end};sr.Vector2=sr.Vector3;sr.Color=sr.Vector3
    sr.Application={main_world=function()return main end,worlds=function()return {main,ui}end,
        can_get=function(kind,name)
            if name=='mods/dbf_hud/materials/screen_scene_depth_access' then return access end
            if name=='mods/dbf_hud/materials/screen_scene_depth_compare' then return compare end
            return true end}
    sr.World={create_screen_gui=function(w)assert(w==ui);made=made+1;return {}end,
        destroy_gui=function(w)assert(w==ui);destroyed=destroyed+1 end}
    sr.Gui={bitmap_3d=function()error('screen path must use bitmap')end,
        bitmap=function(g,mat,pos,size,color)assert(pos[3]==50)
            if mat=='mods/dbf_hud/materials/screen_scene_depth_access' then assert(size[1]==128 and color[2]==255)
            elseif mat=='mods/dbf_hud/materials/screen_scene_depth_compare' then
                assert(math.abs((color[2]+color[3]*256)*64/65535-1)<.001)
            else assert(color[2]==0 and color[3]==255) end
            drawn=drawn+1;return drawn end,
        destroy_bitmap=function()removed=removed+1 end}
    local marker=HUD.depth_marker.new(sr,function(e)messages[#messages+1]=e end)
    local camera={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
    assert(marker.draw({x=0,y=1,z=0},camera,1,1080,1920))
    assert(marker.draw({x=0,y=1,z=0},camera,1,1080,1920))
    assert(made==1 and drawn==8 and removed==4)
    access=true;assert(marker.draw({x=0,y=1,z=0},camera,1,1080,1920))
    assert(drawn==13 and removed==8 and #messages==1)
    compare=true;assert(marker.draw({x=0,y=1,z=0},camera,1,1080,1920))
    assert(drawn==17 and removed==13 and #messages==2)
    marker.draw(nil,nil,nil,1080,1920);assert(destroyed==1)
end)
test('screen scene preserves saved mounts and shader font colors with dimmed digits',function()
    local original=HUD.world_style.prepare;HUD.world_style.prepare=function(commands)return commands end
    local camera={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
    local p={matrix=camera,x=0,y=1,z=0,auto_mount={x=.1,y=.2,z=.03},resource_hex='test'}
    local cfg={placement_mode='auto',occlusion_mode='gui_depth'}
    local commands={{type='panel',x=-10,y=-10,w=20,h=20,a=.5,c={200,100,50}},
        {type='text',x=0,y=0,size=12,text='001',numeric_display=true,font='bigblue',a=.6,c={250,120,20}}}
    local matrix,at=HUD.screen_scene.panel_pose(p,cfg,commands)
    assert(math.abs(at.x-.1)<1e-9 and math.abs(at.y-1.2762)<1e-9 and math.abs(at.z-.03)<1e-9)
    local bone={0,1,0,0,-1,0,0,0,0,0,1,0,2,3,4,1}
    p.sight={x=.02,y=.03,z=.04,matrix=bone}
    local oriented,locked=HUD.screen_scene.panel_pose(p,cfg,commands)
    assert(oriented==bone and math.abs(locked.x-(2-(.2762-.03)))<1e-9 and math.abs(locked.y-3.08)<1e-9 and math.abs(locked.z-3.99)<1e-9)
    cfg.debug_sight_root_orientation=true
    local restored,root_at=HUD.screen_scene.panel_pose(p,cfg,commands)
    assert(restored==matrix and root_at.x==at.x and root_at.y==at.y and root_at.z==at.z)
    cfg.debug_sight_root_orientation=false
    p.sight=nil
    local available=false;local made,drawn,removed,destroyed=0,{},0,0;local params={}
    local sr={Application={main_world=function()return 'main'end,worlds=function()return {'main','ui'}end,can_get=function()return available end},
        Vector2=function(x,y)return {x,y}end,Vector3=function(x,y,z)return {x,y,z}end,Color=function(a,r,g,b)return {a,r,g,b}end,
        World={create_screen_gui=function(w)assert(w=='ui');made=made+1;return made end,destroy_gui=function()destroyed=destroyed+1 end},
        Material={set_texture=function(handle,key,value)assert(key=='diffuse_map' and value==HUD.native_font_data.faces.bigblue.font) end,set_scalar=function(handle,key,value)params[key]=value end},
        Gui={material=function(gui,name)return name end,triangle=function(gui,a,b,c,layer,color,material,u0,u1,u2)
            drawn[#drawn+1]={color=color,material=material,uv=u0};return #drawn end,
            destroy_triangle=function()removed=removed+1 end}}
    local renderer=HUD.screen_scene.new(sr,function()end)
    assert(not renderer.draw(p,cfg,commands,camera,1,1920,1080,.05) and made==0)
    available=true;assert(renderer.draw(p,cfg,commands,camera,1,1920,1080,.05))
    assert(#drawn==8 and made==1 and math.abs(params.threshold_fade-at.y)<1e-9 and params.scissor_mode==1)
    assert(drawn[3].color[1]==51 and drawn[3].color[2]==250 and drawn[3].color[3]==120 and drawn[3].color[4]==20)
    assert(drawn[7].color[1]==153 and drawn[7].uv and drawn[7].material:find('_scene',1,true))
    cfg.occlusion_mode='gui';assert(renderer.draw(p,cfg,commands,camera,1,1920,1080,.05));assert(params.scissor_mode==0 and removed==8)
    renderer.release();assert(destroyed==1)
    local text_draws={};local text_removed=0
    sr.Gui.text=function(gui,text,font,size,material,pos,color)
        assert(font==HUD.native_font_data.faces.bigblue.font and size>0 and material:find('_scene',1,true))
        text_draws[#text_draws+1]={text=text,color=color};return #text_draws
    end
    sr.Gui.destroy_text=function()text_removed=text_removed+1 end
    local native_renderer=HUD.screen_scene.new(sr,function()end)
    assert(native_renderer.draw(p,cfg,commands,camera,1,1920,1080,.05))
    assert(#text_draws==2 and text_draws[1].text=='00' and text_draws[1].color[1]==51 and text_draws[2].color[1]==153)
    assert(native_renderer.draw(p,cfg,commands,camera,1,1920,1080,.05) and text_removed==2)
    native_renderer.release()
    local oriented={};local oriented_removed=0
    sr.Matrix4x4={from_axes=function(right,forward,up,at)return {right=right,up=up,at=at}end}
    sr.Gui.text_3d=function(gui,text,font,size,material,transform,pos,layer,color)
        assert(size==12 and layer==51 and material:find('_scene',1,true))
        assert(transform.right[1]~=0 and transform.up[3]~=0)
        oriented[#oriented+1]={text=text,color=color,transform=transform};return #oriented
    end
    sr.Gui.destroy_text_3d=function()oriented_removed=oriented_removed+1 end
    local oriented_renderer=HUD.screen_scene.new(sr,function()end)
    local previous_text_count=#text_draws
    assert(oriented_renderer.draw(p,cfg,commands,camera,1,1920,1080,.05))
    assert(#oriented==3 and #text_draws==previous_text_count and oriented[1].text=='0' and oriented[2].text=='0' and oriented[3].text=='1')
    assert(oriented[1].color[1]==51 and oriented[2].color[1]==51 and oriented[3].color[1]==153)
    assert(oriented[1].transform.at[1]<oriented[2].transform.at[1] and oriented[2].transform.at[1]<oriented[3].transform.at[1])
    assert(oriented_renderer.draw(p,cfg,commands,camera,1,1920,1080,.05) and oriented_removed==3)
    oriented_renderer.release();assert(oriented_removed>=2)
    local strips={};local strips_removed=0
    sr.Gui.bitmap_3d_uv=function(gui,material,uv0,uv1,transform,pos,layer,size,color)
        assert(layer==51 and size[1]==1 and size[2]==1)
        assert(uv0[1]<uv1[1] and uv0[2]<uv1[2])
        strips[#strips+1]={uv0=uv0,uv1=uv1,transform=transform,color=color};return #strips
    end
    sr.Gui.destroy_bitmap_3d=function()strips_removed=strips_removed+1 end
    local tilted={};for i=1,16 do tilted[i]=camera[i] end;tilted[10]=.5
    p.matrix=tilted
    local strip_renderer=HUD.screen_scene.new(sr,function()end)
    local native_count=#oriented
    assert(strip_renderer.draw(p,cfg,commands,camera,1,1920,1080,.05))
    assert(#strips==6 and #oriented==native_count)
    assert(strips[1].color[1]==51 and strips[5].color[1]==153)
    assert(strips[1].transform.right[1]~=strips[2].transform.right[1])
    assert(math.abs(strips[1].uv0[2]-strips[2].uv1[2])<1e-9)
    assert(strip_renderer.draw(p,cfg,commands,camera,1,1920,1080,.05) and strips_removed==6)
    strip_renderer.release();assert(strips_removed==6) -- GUI destruction releases remaining strips.
    local created,destroyed,released,live,allocated,reused=strip_renderer.resource_stats()
    assert(created==destroyed+released+live and live==0,'native draw resources must balance across redraw and release')
    assert(reused>0 and allocated<created,'redraw bookkeeping must reuse bounded entries')
    local updates=0
    sr.Gui.update_bitmap_3d_uv=function(g,id,name,u0,u1,tm,pos,layer,size,ink)
        assert(layer==51 and name:find('_scene',1,true) and u0[2]<u1[2] and tm.right[1]~=0)
        updates=updates+1
    end
    local retained=HUD.screen_scene.new(sr,function()end)
    local before=#strips
    assert(retained.draw(p,cfg,commands,camera,1,1920,1080,.05))
    assert(retained.draw(p,cfg,commands,camera,1,1920,1080,.05))
    assert(#strips==before+6 and updates==6,'glyphs reuse native bitmap objects')
    cfg.profile_skip_text=true
    assert(retained.draw(p,cfg,commands,camera,1,1920,1080,.05));cfg.profile_skip_text=nil
    retained.release()
    local a,b,c,d,_,_,u=retained.resource_stats()
    assert(a==b+c+d and d==0 and u==6,'glyph reuse trims and releases resources')
    local fallback=HUD.screen_scene.new(sr,function()end)
    assert(fallback.draw(p,cfg,commands,camera,1,1920,1080,.05))
    sr.Gui.update_bitmap_3d_uv=function()error('simulated unsupported update')end
    assert(fallback.draw(p,cfg,commands,camera,1,1920,1080,.05))
    assert(fallback.draw(p,cfg,commands,camera,1,1920,1080,.05))
    fallback.release()
    local a,b,c,d=fallback.resource_stats();assert(a==b+c+d and d==0,'failed update falls back without leaking or disabling HUD')
    sr.Gui.update_bitmap_3d_uv=nil
    HUD.world_style.prepare=original
end)
test('generated native glyph UVs stay within existing atlas bounds',function()
    local count=0
    for key,glyphs in pairs(HUD.native_font_uv) do
        assert(HUD.native_font_data.faces[key]);count=count+1
        for code,v in pairs(glyphs) do assert(code>=32 and code<=126 and v[1]>=0 and v[2]>=0 and v[3]<=1 and v[4]<=1 and v[3]>=v[1] and v[4]>=v[2]) end
    end
    assert(count==72)
end)
test('Arbitrator secondary is a shotgun shell without altering its rifle magazine',function()
    local primary=HUD.ammo_types.apply({kind='magazine',resource_hex='a8a91eb54892b6b2',reserve_kind='MAGS'})
    assert(primary.reserve_kind=='MAGS' and primary.label=='4MM')
    local secondary=HUD.ammo_types.apply({kind='magazine',resource_hex='a8a91eb54892b6b2',ammo_resource_hex='unknown',alternate_fire=true,fire_mode='ALT',reserve_kind='MAGS'})
    assert(secondary.reserve_kind=='SHELLS' and secondary.label=='10G' and secondary.ammo_icon=='SHELL')
end)
test('RPM presentation requires an explicit selected live rate',function()
    local raw={kind='magazine',rounds=30,capacity=30,rpm=750,fire_mode='AUTO'}
    assert(HUD.model.normalize(raw).rpm==nil)
    raw.rpm_selectable=true;assert(HUD.model.normalize(raw).rpm==750)
    raw.rpm=0/0;assert(HUD.model.normalize(raw).rpm==nil)
end)
test('rotation profiles roundtrip and retired opacity cannot dim the HUD',function()
    local key='0123456789abcdef'
    local profiles={[key]={right={rotation=90,pitch=-45,yaw=135},first_left={rotation=-90}}}
    local encoded=HUD.weapon_offsets.serialize(profiles)
    local loaded=HUD.weapon_offsets.load({read_weapon_offsets=function()return assert(loadstring(encoded))()end},function(e)error(e)end)
    assert(loaded[key].right.pitch==-45 and loaded[key].right.yaw==135 and loaded[key].first_left.rotation==-90)
    local c=HUD.config.new();HUD.config.apply(c,{opacity=.2,effect_scanlines=true,effect_flicker=true,effect_sweep=true})
    assert(c.opacity==1 and c.effect_scanlines and c.effect_flicker and c.effect_sweep)
end)
test('screen numeric grouping retains leading-zero opacity and proportional spacing',function()
    local face=HUD.native_font_data.faces.profont
    local grouped=HUD.screen_scene.text_parts({text='045',numeric_display=true,size=36,font='profont'},face)
    assert(#grouped==2 and grouped[1].text=='0' and grouped[1].alpha==1/3 and grouped[2].text=='45' and grouped[2].alpha==1)
    local full=HUD.screen_scene.text_parts({text='145',numeric_display=true,size=36,font='profont'},face)
    assert(#full==1 and full[1].text=='145')
    local variable={glyphs={}};for digit=48,57 do variable.glyphs[digit]={digit} end
    assert(#HUD.screen_scene.text_parts({text='145',numeric_display=true,size=36,font='profont'},variable)==3)
end)
test('font availability checks reuse results only within one frame',function()
    local calls=0;local sr={Application={can_get=function()calls=calls+1;return true end}}
    HUD.native_font.begin_frame()
    local f,m,face=HUD.native_font.resolve(sr,'profont',false)
    local again=HUD.native_font.resolve(sr,'profont',false)
    assert(f==again and face and calls==2)
    HUD.native_font.end_frame();HUD.native_font.resolve(sr,'profont',false);assert(calls==4)
    HUD.native_font.begin_frame();HUD.native_font.resolve(sr,'profont',false);assert(calls==6);HUD.native_font.end_frame()
end)
test('Bushwhacker selector uses shell symbols in semi and volley',function()
    for _,mode in ipairs({'SEMI','VOLLEY'}) do
        local raw=HUD.ammo_types.apply({resource_hex='2b28e17ffed05f7c',kind='magazine',rounds=3,capacity=3,reserve=12,fire_mode=mode})
        assert(raw.ammo_icon==(mode=='VOLLEY' and 'TRIPLE_SHELL' or 'SHELL'))
        local commands=HUD.layout.compose(HUD.model.normalize(raw),0,0,1,1,HUD.config.new(),0)
        local label=false;local blue=false
        for _,c in ipairs(commands) do
            label=label or c.text==mode
            blue=blue or ((c.mode_icon or c.catalog_heading) and c.c[1]==65 and c.c[2]==145 and c.c[3]==235)
        end
        assert(label and blue)
    end
end)


 test('editor movement follows camera axes regardless of panel rotation',function()
    local key='968211c0033dce64'
    local identity={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
    local turned={0,1,0,0,-1,0,0,0,0,0,1,0,0,0,0,1}
    local h={config={fp_auto_side='right'},weapon_pose={resource_hex=key,matrix=turned,attach_point='root'},
        editor_camera_matrix=identity,weapon_clearance={[key]={right={rotation=90,pitch=45,yaw=90}}}}
    local e=HUD.layout_editor.new(h,{},function()end);assert(e.bind())
    assert(e.move('x',1));local x,y,z=e.values();assert(math.abs(x)<1e-9 and math.abs(y+1)<1e-9 and z==0)
    assert(e.move('z',1));x,y,z=e.values();assert(z==1)
    h.config.debug_sight_root_orientation=false;h.weapon_pose.attach_point='sight';h.weapon_pose.sight={matrix=identity}
    assert(e.move('x',1));x,y,z=e.values();assert(math.abs(x-1)<1e-9)
    h.editor_camera_matrix=nil;assert(not e.move('x',1));assert(e.values()==x)
 end)

test('settings reload hotkey requires Ctrl and fires once per press',function()
    local keys,calls={},0
    local h={clock=0,config={},reload_settings=function()calls=calls+1;return true,'Reloaded' end}
    local e=HUD.layout_editor.new(h,{editor_key=function(k)return keys[k] or false end},function()end)
    keys[116]=true;e.tick(.01);assert(calls==0)
    keys[116]=false;e.tick(.01);keys[17]=true;keys[116]=true
    e.tick(.01);e.tick(.01);assert(calls==1 and e.status=='Reloaded')
    keys[116]=false;e.tick(.01);h.reload_settings=function()return false,'invalid file' end
    keys[116]=true;e.tick(.01);assert(e.status=='Reload failed: invalid file')
end)

test('first-person clipping accepts surfaces inside the world near plane',function()
    local camera={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
    assert(not HUD.projection.project(camera,0,.045,0,1,1,.05))
    assert(HUD.projection.project(camera,0,.045,0,1,1,.005))
    local corners={{x=-.001,y=.045,z=-.001},{x=.001,y=.045,z=-.001},{x=.001,y=.045,z=.001},{x=-.001,y=.045,z=.001}}
    assert(#HUD.projection.clip_polygon(camera,corners,1,1,.05)==0)
    assert(#HUD.projection.clip_polygon(camera,corners,1,1,.005)==4)
    assert(not HUD.projection.project(camera,0,-.01,0,1,1,.005))
end)

test('frustum clips crossing polygons without dropping visible portions',function()
    local camera={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
    local function point(x,y,z,s,v)return {x=x,y=y,z=z,s=s,v=v} end
    local quad={point(-2,1,-.5,0,1),point(.5,1,-.5,1,1),point(.5,1,.5,1,0),point(-2,1,.5,0,0)}
    local clipped=HUD.projection.clip_polygon(camera,quad,math.pi/2,1,.05)
    assert(#clipped==4)
    local edge=false
    for _,p in ipairs(clipped) do
        assert(p.x>=0 and p.x<=1 and p.y>=0 and p.y<=1)
        if p.x==0 then assert(math.abs(p.s-.4)<1e-6);edge=true end
    end
    assert(edge)
    local near={point(-.02,.01,-.02),point(.02,.1,-.02),point(.02,.1,.02),point(-.02,.01,.02)}
    local visible=HUD.projection.clip_polygon(camera,near,math.pi/2,1,.05)
    assert(#visible>=3);for _,p in ipairs(visible) do assert(p.depth>=.05-1e-9) end
    assert(#HUD.projection.clip_polygon(camera,{point(2,1,0),point(3,1,0),point(3,1,.1)},math.pi/2,1,.05)==0)
    local enclosing={point(-2,1,-2),point(2,1,-2),point(2,1,2),point(-2,1,2)}
    assert(#HUD.projection.clip_polygon(camera,enclosing,math.pi/2,1,.05)==4)
end)
test('MG Easter egg requires ammo cadence and resets with cooldown',function()
 local s=HUD.mg_easter.new();local m={resource_hex='11c27d3babb38956',id='mg',value=200}
 local rolls=0;local function lucky() rolls=rolls+1;return 0 end
 for i=0,60 do assert(not HUD.mg_easter.step(s,m,i*.1,true,lucky)) end
 for i=1,45 do m.value=200-i;HUD.mg_easter.step(s,m,6+i*.1,true,lucky) end
 assert(rolls==1 and s.until_at and s.cooldown>50)
 assert(not HUD.mg_easter.step(s,m,11,true,lucky));assert(s.start==nil)
 m.value=200;HUD.mg_easter.step(s,m,11.1,true,lucky)
 for i=1,45 do m.value=200-i;assert(not HUD.mg_easter.step(s,m,11.1+i*.1,true,lucky)) end
 assert(rolls==1)
 HUD.mg_easter.step(s,nil,16,true,lucky);assert(s.id==nil and s.until_at==nil)
 assert(not HUD.mg_easter.step(s,m,17,false,lucky))
 local other={resource_hex='a6a735accb4a327f',value=100};assert(not HUD.mg_easter.step(s,other,18,true,lucky))
end)
test('MG flash replaces content without changing telemetry or other styles',function()
 local c=HUD.config.new();local m=HUD.model.normalize({id='mg',resource_hex='11c27d3babb38956',kind='magazine',rounds=175,capacity=200,reserve=1})
 m.mg43_flash=true
 local out=HUD.layout.compose(m,0,0,1,1,c,10)
 local seen=false;for _,v in ipairs(out) do if v.type=='text' then assert(v.text=='GET SOME!!!');seen=true end end
 assert(seen and m.value==175 and m.reserve==1)
 m.mg43_flash=false;out=HUD.layout.compose(m,0,0,1,1,c,11)
 local caption=false;for _,v in ipairs(out) do if v.text=='MG-43' then assert(v.size==12);caption=true end;assert(v.text~='GET SOME!!!') end
 assert(caption)
end)
test('MG chamber bonus has one model caption with real plus one',function()
 local c=HUD.config.new();local m=HUD.model.normalize({id='mg',resource_hex='11c27d3babb38956',kind='magazine',rounds=201,capacity=200,chamber_supported=true,chamber_rounds=1})
 assert(m.chamber_bonus==1 and m.value==201)
 local out=HUD.layout.compose(m,0,0,1,1,c,0);local n=0
 for _,v in ipairs(out) do if v.type=='text' and v.text:find('MG-43',1,true) then n=n+1;assert(v.text=='MG-43' and v.catalog_caption and v.size==12) end end
 assert(n==1)
end)
test('MG quote uses three readable color stages and fits measured panel',function()
 local c=HUD.config.new();local m=HUD.model.normalize({id='mg',resource_hex='11c27d3babb38956',kind='magazine',rounds=175,capacity=200,reserve=1})
 m.mg43_flash=true;m.mg43_flash_start=10
 local expected={{255,221,0},{255,255,255},{255,174,48}}
 for i,elapsed in ipairs({0,.13,.25}) do
  local out=HUD.layout.compose(m,0,0,1,1,c,10+elapsed)
  local frame=out[1];local found=false
  for _,v in ipairs(out) do if v.mg43_easter then
   assert(v.text=='GET SOME!!!');for k=1,3 do assert(v.c[k]==expected[i][k]) end
   assert(v.x>=frame.x and v.x+11*v.size*.6<=frame.x+frame.w+.001);found=true
  end end
  assert(found and m.value==175)
 end
end)
test('MG punch accents and shadow stay in frame throughout animation',function()
 local cfg=HUD.config.new();local m=HUD.model.normalize({id='mg',resource_hex='11c27d3babb38956',kind='magazine',rounds=175,capacity=200})
 m.mg43_flash=true;m.mg43_flash_start=0
 for _,scale in ipairs({.05,1,2}) do for i=0,110 do
  local out=HUD.layout.compose(m,0,0,scale,1,cfg,i*.01);local f=out[1];local accents=0;local shadow=false
  for _,v in ipairs(out) do
   if v.mg43_accent then
    assert(v.x>=f.x and v.y>=f.y and v.x+v.w<=f.x+f.w+.001 and v.y+v.h<=f.y+f.h+.001);accents=accents+1
   elseif v.mg43_shadow then
    assert(v.x>=f.x and v.x+11*v.size*.6<=f.x+f.w+.001);shadow=true
   end
  end
  assert(accents>=6 and shadow)
 end end
end)
test('MG chamber total and gold final digit follow native chamber without double count',function()
 local cfg=HUD.config.new()
 for _,sample in ipairs({{176,1},{175,1},{175,0},{174,1},{0,0}}) do
  local m=HUD.model.normalize({id='mg',resource_hex='11c27d3babb38956',kind='magazine',rounds=sample[1],capacity=175,chamber_supported=true,chamber_rounds=sample[2]})
  assert(m.value==sample[1])
  local out=HUD.layout.compose(m,0,0,1,1,cfg,0);local seen=false
  for _,v in ipairs(out) do if v.mode_count then
   assert(v.text==string.format('%03d',sample[1]))
   local parts=HUD.font.numeric_parts(v);for i,part in ipairs(parts) do assert((part.c~=nil)==(sample[1]==176 and i==#parts)) end
   local grouped=HUD.screen_scene.text_parts(v,HUD.native_font_data.faces[v.font]);assert((grouped[#grouped].c~=nil)==(sample[1]==176));seen=true
  end;assert(not (v.text and v.text:find('+1',1,true))) end
  assert(seen)
 end
 local other=HUD.model.normalize({kind='magazine',rounds=31,capacity=30,chamber_supported=true,chamber_rounds=1});assert(other.value==31 and other.chamber_bonus==1)
end)
test('verified chamber treatment covers catalog counts and excludes unsupported telemetry',function()
 local cfg=HUD.config.new();local checked=0
 local function measure(text,size) return HUD.font.measure(text,size,'bigblue',true) end
 for id in pairs(HUD.weapon_styles.catalog) do
  for _,state in ipairs({{31,1},{30,0},{1,1},{0,0}}) do
   local m=HUD.model.normalize({id=id,resource_hex=id,kind='magazine',rounds=state[1],capacity=30,chamber_supported=true,chamber_rounds=state[2],label='ROUNDS',fire_mode='SEMI'})
   assert(m.value==state[1] and (m.chamber_bonus==1)==(state[1]==31))
   local out=HUD.layout.compose(m,0,0,1,1,cfg,0,measure)
   for _,v in ipairs(out) do
    assert(not (v.type=='text' and v.text:find('+1',1,true)))
    if v.last_digit_color then
     assert(tonumber(v.text)==state[1] and state[1]==31)
     local parts=HUD.font.numeric_parts(v);assert(parts[#parts].c==v.last_digit_color)
     for i=1,#parts-1 do assert(not parts[i].c) end
     local a,b,e,f=measure(v.text,v.size);assert(e>a and f>b);checked=checked+1
    end
   end
  end
 end
 assert(checked>100)
 for _,raw in ipairs({{kind='magazine',rounds=31,capacity=30,chamber_rounds=1},
  {kind='magazine',rounds=31,capacity=30,chamber_supported=false,chamber_rounds=1},
  {kind='heat',heat=.5,chamber_supported=true,chamber_rounds=1},
  {kind='infinite',chamber_supported=true,chamber_rounds=1}}) do assert(not HUD.model.normalize(raw).chamber_bonus) end
 local tube=HUD.model.normalize({kind='rounds',rounds=6,capacity=5,chamber_supported=true,chamber_rounds=1});assert(tube.value==6 and tube.chamber_bonus==1)
end)
test('first shot removes extra-round gold and restores original themed ink',function()
 local cfg=HUD.config.new();cfg.text_color='#53ACD8'
 for _,id in ipairs({'11c27d3babb38956','e6d932be83729076','89c5493e08ca4207','52e4334e6a128caf'}) do
  local ink
  for _,total in ipairs({31,30,29,31}) do
   local m=HUD.model.normalize({id=id,resource_hex=id,kind='magazine',rounds=total,capacity=30,chamber_supported=true,chamber_rounds=1,label='ROUNDS'})
   local found=false
   for _,v in ipairs(HUD.layout.compose(m,0,0,1,1,cfg,0)) do if v.text==string.format('%03d',total) and v.size>=20 then
    assert((v.last_digit_color~=nil)==(total==31))
    if not ink then ink=v.c end;for k=1,3 do assert(v.c[k]==ink[k]) end
    local parts=HUD.font.numeric_parts(v);assert((parts[#parts].c~=nil)==(total==31));found=true
   end end
   assert(found)
  end
 end
end)
test('Autocannon FLAK recolors only shell projectile and restores normal mode',function()
 local function legacy_icon(m,icon)return HUD.munition_art.autocannon_icon(m,icon,false) end
 local source=HUD.fire_icons.GRENADE_PISTOL_SHELL
 local normal={resource_hex='a8cffb316f0b5c5f',ammo_mode=HUD.ammo_types.autocannon_mode(0x50)}
 local flak={resource_hex=normal.resource_hex,ammo_mode=HUD.ammo_types.autocannon_mode(0x1054)}
 assert(legacy_icon(normal,source)==source)
 local art=legacy_icon(flak,source);assert(art~=source and art.w==source.w and art.h==source.h)
 assert(legacy_icon(flak,source)==art)
 local changed=0
 for i,r in ipairs(art.runs) do local s=source.runs[i]
  for k=1,4 do assert(r[k]==s[k]) end
  if s[1]<14 then assert(r[5]==s[5]) else assert(r[5]~=s[5]);changed=changed+1 end
 end
 assert(changed>5)
 assert(legacy_icon(normal,source)==source)
 assert(legacy_icon({resource_hex='26e40437ea275296',ammo_mode='FLAK'},source)==source)
 assert(legacy_icon({resource_hex=normal.resource_hex},source)==source)
 local cfg=HUD.config.new();local first
 for _,mode in ipairs({'APHET','FLAK','APHET'}) do
  local m=HUD.model.normalize({resource_hex=normal.resource_hex,kind='rounds',rounds=11,capacity=10,chamber_supported=true,chamber_rounds=1,ammo_mode=mode,label='AMMO'})
  local commands=HUD.layout.compose(m,0,0,1,1,cfg,0);local colors={};local gold=false
  for _,v in ipairs(commands) do if v.catalog_heading then colors[#colors+1]=table.concat(v.c,',') end;if v.text=='011' then assert(v.last_digit_color);gold=true end end
  assert(gold and #colors>0);local signature=table.concat(colors,'/')
  if not first then first=signature elseif mode=='FLAK' then assert(signature~=first) else assert(signature==first) end
 end
end)
test('Melta thermal housing uses real counts and preserves per-digit chamber rendering',function()
 local cfg=HUD.config.new();local measure=function(t,size)return HUD.font.measure(t,size,cfg.font,true)end
 for _,scale in ipairs({.05,1,2}) do
  local m=HUD.model.normalize({resource_hex='6cfcc7f8801a0266',kind='magazine',rounds=11,capacity=10,reserve=3,chamber_supported=true,chamber_rounds=1,label='SHOTS',ammo_icon='MELTA'})
  local out=HUD.layout.compose(m,0,0,scale,1,cfg,0,measure);local f=out[1];assert(f.melta_panel)
  local detail,count,reserve=0,false,false
  for _,v in ipairs(out) do
   if v.melta_detail then assert(v.x>=f.x and v.y>=f.y and v.x+v.w<=f.x+f.w+.001 and v.y+v.h<=f.y+f.h+.001);detail=detail+1 end
   if v.melta_text then local a,b,e,h=measure(v.text,v.size);assert(v.x+a>=f.x and v.x+e<=f.x+f.w+.001 and v.y+b>=f.y and v.y+h<=f.y+f.h+.001) end
   if v.text=='011' then assert(v.last_digit_color);count=true end
   if v.text=='003 CNSTRS' then reserve=true end
  end
  assert(detail>65 and count and reserve)
 end
end)
test('Melta research candidate cannot silently become verified charge telemetry',function()
 local raw={resource_hex='6cfcc7f8801a0266',kind='magazine',rounds=3,capacity=5,binding={melta_charge_candidate=.53}}
 local m=HUD.model.normalize(raw);assert(m.charge_fraction==nil and m.value==3)
 local cfg=HUD.config.new();local out=HUD.layout.compose(m,0,0,1,1,cfg,0)
 assert(out[1].melta_panel);for _,v in ipairs(out) do assert(not (v.text and v.text:find('HEAT',1,true))) end
end)
test('native Melta glow follows ramp, cancel, discharge and switch cleanup',function()
 local s={};local function sample(n,charge,time)
  local m=HUD.model.normalize({id='melta',resource_hex='6cfcc7f8801a0266',kind='magazine',rounds=n,capacity=5,melta_charge_level=charge})
  HUD.melta_panel.step(s,m,time);return m
 end
 local idle=sample(3,0,0);assert(HUD.melta_panel.glow(idle)==0)
 local charging=sample(3,.5,.4);assert(HUD.melta_panel.glow(charging)>.7)
 local cancel=sample(3,0,.5);assert(HUD.melta_panel.glow(cancel)==0)
 local shot=sample(2,0,1);assert(HUD.melta_panel.glow(shot)==1)
 local settled=sample(2,0,1.2);assert(HUD.melta_panel.glow(settled)==0)
 HUD.melta_panel.step(s,nil,1.3);assert(not s.id and not s.pulse)
 local swapped=sample(1,0,1.4);assert(HUD.melta_panel.glow(swapped)==0)
 local other=HUD.model.normalize({resource_hex='other',kind='magazine',rounds=3,melta_charge_level=.9});assert(not other.melta_charge_level)
end)
test('S-11 single-shot spear presence preserves reserves and bounds',function()
 local cfg=HUD.config.new()
 for _,scale in ipairs({.05,1,2}) do for _,n in ipairs({0,1}) do
  local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='3828e2051aa9e897',kind='rounds',rounds=n,capacity=1,reserve=8}))
  local out=HUD.layout.compose(m,0,0,scale,1,cfg,0);assert(out[1].speargun_panel)
  local projectile=false;local reserve=false;local state=false
  for _,d in ipairs(out) do
   if d.spear_projectile then projectile=true end
   if d.type=='rect' then assert(d.x>=out[1].x-.001 and d.y>=out[1].y-.001 and d.x+d.w<=out[1].x+out[1].w+.001 and d.y+d.h<=out[1].y+out[1].h+.001) end
   if d.text=='008 SPEARS' then reserve=true end
   if d.text==(n==1 and 'SPEAR READY' or 'EMPTY') then state=true end
   assert(d.text~='0' and d.text~='1' and d.text~='001')
  end
  assert(projectile==(n==1) and reserve and state)
 end end
 local m=HUD.model.normalize({resource_hex='3828e2051aa9e897',kind='rounds',rounds=2,capacity=2})
 assert(not HUD.layout.compose(m,0,0,1,1,cfg,0)[1].speargun_panel)
 local other=HUD.model.normalize({resource_hex='25aa2fd4643cf4ee',kind='rounds',rounds=1,capacity=1})
 assert(not HUD.layout.compose(other,0,0,1,1,cfg,0)[1].speargun_panel)
end)
test('GR-8 ammunition cradle follows loaded state, reserves and verified modes',function()
 local cfg=HUD.config.new()
 for _,scale in ipairs({.05,1,2}) do for _,mode in ipairs({'HEAT','HE','UNKNOWN'}) do for _,n in ipairs({0,1}) do
  local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='9f80d67a12a7e40f',kind='rounds',rounds=n,capacity=1,reserve=5,ammo_mode=mode}))
  local out=HUD.layout.compose(m,0,0,scale,1,cfg,0);assert(out[1].recoilless_panel)
  local art,reserve,label,state=false,false,false,false
  for _,d in ipairs(out) do
   if d.recoilless_round then art=true end
   if d.type=='rect' then assert(d.x>=out[1].x-.001 and d.y>=out[1].y-.001 and d.x+d.w<=out[1].x+out[1].w+.001 and d.y+d.h<=out[1].y+out[1].h+.001) end
   if d.text=='005 RCKTS' then reserve=true end
   if d.text==(mode=='UNKNOWN' and 'AMMO' or mode) then label=true end
   if d.text==(n==1 and 'LOADED' or 'EMPTY') then state=true end
   assert(d.text~='001' and d.text~='000')
  end
  assert(art==(n==1) and reserve and label and state)
 end end end
 local m=HUD.model.normalize({resource_hex='9f80d67a12a7e40f',kind='rounds',rounds=1,capacity=1})
 local found=false;for _,d in ipairs(HUD.layout.compose(m,0,0,1,1,cfg,0)) do if d.text=='-- RCKTS' then found=true end end;assert(found)
end)
test('accepted panel rendering stays byte-for-byte identical across catalog upgrade',function()
local function serial(v)
 if type(v)~='table' then return type(v)..':'..tostring(v) end
 local keys={};for k in pairs(v) do keys[#keys+1]=k end;table.sort(keys,function(a,b)return tostring(a)<tostring(b) end)
 local out={};for _,k in ipairs(keys) do out[#out+1]=serial(k)..'='..serial(v[k]) end;return '{'..table.concat(out,';')..'}'
end
local file=assert(io.open(assert(DBF_APPROVED_SNAPSHOT,'run tests/run.py to unpack accepted fixture'),'r'));local index=0
for _,id in ipairs({'e6d932be83729076','89c5493e08ca4207','52e4334e6a128caf','2e9d0bdc48b09e60','11c27d3babb38956','a8cffb316f0b5c5f','6cfcc7f8801a0266','3828e2051aa9e897','9f80d67a12a7e40f','84354339522c932d','5fecab819f96a3e8','0f83639ab8c86165','a6a735accb4a327f','72170a55a1f37ff1','14d5d4506056c7a4','5f3ec9bda2bd8553','4dbd74f49c8ffc13','0b882808c6f498e8','e5796355a8fd67e0','416d053372c4e433','b2b5e0d185605f9e','26e40437ea275296','2b28e17ffed05f7c'}) do for _,scale in ipairs({.05,1,2}) do for _,mode in ipairs({'SEMI','AUTO','BURST'}) do for _,cap in ipairs({1,10}) do for _,n in ipairs({0,1}) do
local raw=HUD.ammo_types.apply({resource_hex=id,kind='magazine',rounds=n,capacity=cap,reserve=8,reserve_kind='MAGS',fire_mode=mode,ammo_mode=id=='a8cffb316f0b5c5f' and 'FLAK' or nil,safety_mode=id=='2e9d0bdc48b09e60' and 'UNSAFE' or nil})
local commands=HUD.layout.compose(HUD.model.normalize(raw),0,0,scale,1,HUD.config.defaults,.3)
index=index+1;local expected=file:read('*l');if id~='72170a55a1f37ff1' and id~='a8cffb316f0b5c5f' and id~='9f80d67a12a7e40f' and id~='416d053372c4e433' then assert(serial(commands)==expected,'accepted panel changed '..id..' sample '..index) end
end end end end end
assert(file:read('*l')==nil);file:close()
end)
test('machined catalog covers unapproved families without changing telemetry or gauges',function()
 local eligible,total=0,0
 for id,style in pairs(HUD.weapon_styles.catalog) do
  total=total+1
  if HUD.catalog_housing.eligible(id) then
   eligible=eligible+1
   for _,scale in ipairs({.05,1,2}) do for _,mode in ipairs({'SEMI','AUTO','BURST'}) do
    local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex=id,kind='magazine',rounds=7,capacity=10,reserve=8,reserve_kind='MAGS',fire_mode=mode}))
    local before=m.value;local out=HUD.layout.compose(m,0,0,scale,1,HUD.config.defaults,0)
    local fuel=m.label=='FUEL' or m.label=='GAS'
    assert(not HUD.catalog_housing.enabled or fuel and not out[1].machined_catalog or id=='72170a55a1f37ff1' and out[1].type=='panel' or out[1].machined_catalog or out[1].shared_suite,id);assert(m.value==before and m.reserve==8 and m.fire_mode==mode,id)
    local hardware=0
    for _,d in ipairs(out) do if d.machined_detail then
     hardware=hardware+1;local f=out[1]
     assert(d.x>=f.x-.001 and d.y>=f.y-.001 and d.x+d.w<=f.x+f.w+.001 and d.y+d.h<=f.y+f.h+.001,id)
    end end
    if not HUD.catalog_housing.enabled or fuel or out[1].shared_suite or id=='72170a55a1f37ff1' then assert(hardware==0,id) else assert(hardware>20,id) end
   end end
  end
 end
 assert(total==148 and eligible==0)
 for _,kind in ipairs({'heat','rounds'}) do
  local raw={resource_hex='27ee1ed8f6fb6356',kind=kind,rounds=30,capacity=100,heat=.7,reserve=3}
  local m=HUD.model.normalize(raw);local out=HUD.layout.compose(m,0,0,1,1,HUD.config.defaults,0)
  if kind=='heat' then local meter=false;for _,d in ipairs(out) do meter=meter or d.heat_fill end;assert(meter and m.fraction==.7) end
 end
end)
test('Double Freedom precision panel preserves loaded states, mode and reserves',function()
 for _,mode in ipairs({'SEMI','VOLLEY'}) do for n=0,2 do
  local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='72170a55a1f37ff1',kind='rounds',rounds=n,capacity=2,reserve=30,reserve_kind='SHELLS',fire_mode=mode}))
  local out=HUD.layout.compose(m,0,0,1,1,HUD.config.defaults,0)
  local child,label,reserves,art=false,false,false,false
  for _,d in ipairs(out) do
   child=child or d.type=='panel' and d.child
   label=label or d.text==mode
   reserves=reserves or d.text=='030 SHELLS'
   if d.text=='DBS-2' or d.text=='DOUBLE FREEDOM' then assert(d.weapon_label and d.c[1]==218 and d.c[2]==172 and d.c[3]==78,'weapon label stays gold across ammo states') end
   if d.type=='rect' and not d.decoration then local f=out[1];assert(d.x>f.x and d.x+d.w<f.x+f.w and (d.child or d.y>f.y and d.y+d.h<f.y+f.h),'decorations own outer borders') end
   art=art or d.barrel_indicator~=nil
   assert(d.text~=string.format('%03d',n),'shells replace numeric loaded-ammo count')
  end
  assert(child and label and reserves and art and m.value==n and m.reserve==30)
  assert(#out<120,'compact shared receiver display budget')
  local shells=0;for _,d in ipairs(out) do if d.shotgun_shell_art then
   shells=shells+1
   local side=d.x<60 and 1 or 2
   local loaded=mode=='VOLLEY' and n==2 or mode=='SEMI' and n>=(3-side)
   assert(d.y>=32 and d.y+d.h<=77 and d.x>=24.499 and d.x+d.w<=95.501,'side-by-side shell bounds and two-pixel extra title clearance')
   local brass=d.y<32+6*1.5
   assert(loaded and (brass and d.c[1]>d.c[2] and d.c[2]>d.c[3] or not brass and d.c[3]>d.c[2] and d.c[2]>d.c[1]) and d.a==.9 or not loaded and d.c[1]==198 and d.a==.18,'blue hulls, brass bases; dim empty shells')
  end end
  assert(shells==#HUD.fire_icons.DOUBLE_FREEDOM_SHELL.runs*2,'two subordinate shell symbols')
  local states={}
  for _,d in ipairs(out) do if d.shell_loaded~=nil then states[d.barrel_indicator]=d.shell_loaded end end
  for side=1,2 do assert(states[side]==(mode=='VOLLEY' and n==2 or mode=='SEMI' and n>=(3-side))) end
 end end
end)

test('Double Freedom breech bases empty in native semi and volley order',function()
 local style=HUD.weapon_styles.catalog['72170a55a1f37ff1']
 for _,mode in ipairs({'SEMI','VOLLEY'}) do for n=0,2 do
  local icon=HUD.munition_art.icon(style,{resource_hex='72170a55a1f37ff1',value=n,fire_mode=mode},nil)
  for side=1,2 do local loaded=mode=='VOLLEY' and n==2 or (mode=='SEMI' and n>=(side==1 and 2 or 1));assert(icon.loaded[side]==loaded) end
  assert(icon.w==150 and icon.h==110 and #icon.runs<=448 and #icon.runs>=40)
  for _,r in ipairs(icon.runs) do assert(r[1]>=0 and r[2]>=0 and r[1]+r[3]<=150 and r[2]+r[4]<=110) end
  assert(HUD.munition_art.icon(style,{resource_hex='72170a55a1f37ff1',value=n,fire_mode=mode},nil)==icon,'art is cached by ammo state')
 end end
end)
test('Doom reload event rolls once on reserve-backed completed reload and clears on switch',function()
 local s=HUD.doom_easter.new();local rolls=0;local function rng()rolls=rolls+1;return 0 end
 local m={resource_hex='72170a55a1f37ff1',capacity=2,value=0,reserve=30}
 assert(not HUD.doom_easter.step(s,m,0,rng));m.value=2;m.reserve=28
 assert(HUD.doom_easter.step(s,m,1,rng)==1)
 for i=1,10 do HUD.doom_easter.step(s,m,1+i*.01,rng) end;assert(rolls==1)
 assert(not HUD.doom_easter.step(s,m,1+HUD.doom_easter.duration,rng));HUD.doom_easter.step(s,nil,5,rng)
 assert(not HUD.doom_easter.step(s,m,6,rng) and rolls==1)
 m.value=0;HUD.doom_easter.step(s,m,7,rng);m.value=2;HUD.doom_easter.step(s,m,8,rng);assert(rolls==1)
end)

test('authoritative Doom GIF preserves timed sequence and aspect-fit bounds',function()
 local e=HUD.doom_easter;assert(e.width==107 and e.height==128 and #e.frames==70 and #e.sequence==76 and math.abs(e.duration-7.6)<.00001)
 for _,t in ipairs({0,.1,.9,2.4,7.5}) do
  local out=e.apply({{type='panel',x=0,y=0,w=90,h=90}},{resource_hex='72170a55a1f37ff1',doom_start=0},1,1,t)
  for i=2,#out do local d=out[i];assert(d.x>=0 and d.y>=0 and d.x+d.w<=90.001 and d.y+d.h<=90.001 and d.a>0 and d.a<=1) end
 end
end)

test('retired single-shot artwork bay restores earlier numeric ammunition display',function()
 local cfg=HUD.config.new()
 for _,value in ipairs({0,1}) do
  local m=HUD.model.normalize({resource_hex='692eb345969d368e',kind='magazine',rounds=value,capacity=1,reserve=3})
  local out=HUD.layout.compose(m,0,0,1,1,cfg,0);local count=false
  for _,d in ipairs(out) do count=count or d.text==string.format('%03d',value);assert(not d.machined_detail and not d.machined_catalog) end
  assert(count and m.value==value and m.reserve==3)
 end
end)

-- Snapshot projector must preserve bounds and near-plane decisions exactly.
test('snapshot projector matches guarded projection and rejects invalid cameras',function()
    local m={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
    local project=HUD.projection.projector(m,1,16/9,.005)
    for i=1,1200 do
        local x=(i%31-15)*.1;local y=(i%47)*.03;local z=(i%19-9)*.1
        local a,why=HUD.projection.project(m,x,y,z,1,16/9,.005)
        local b,other=project(x,y,z)
        assert(why==other and (a==nil)==(b==nil))
        if a then assert(a.x==b.x and a.y==b.y and a.depth==b.depth) end
    end
    m[1]=2;assert(not pcall(HUD.projection.projector,m,1,16/9,.005))
end)
test('reusable clipping scratch preserves visible and clipped polygon results',function()
    local m={1,0,0,0,0,1,0,0,0,0,1,0,0,0,0,1}
    local scratch={camera={},result={}}
    for i=1,300 do
        local x=(i%21-10)*.12;local depth=.003+(i%13)*.09
        local vertices={{x=x,y=depth,z=-.1,s=0,v=1},{x=x+.2,y=depth,z=-.1,s=1,v=1},{x=x+.2,y=depth+.04,z=.1,s=1,v=0},{x=x,y=depth+.04,z=.1,s=0,v=0}}
        local expected=HUD.projection.clip_polygon(m,vertices,1,16/9,.005)
        local actual=HUD.projection.clip_polygon(m,vertices,1,16/9,.005,scratch)
        assert(#actual==#expected)
        for j,p in ipairs(expected) do for k,v in pairs(p) do assert(actual[j][k]==v) end end
    end
end)
test('Double Freedom preserves selected shared edge decoration within final custom bounds',function()
 local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='72170a55a1f37ff1',kind='rounds',rounds=2,capacity=2,reserve=30,reserve_kind='SHELLS',fire_mode='SEMI'}))
 for _,style in ipairs({'none','outline','brackets','helldivers','double'}) do
  local cfg={};for k,v in pairs(HUD.config.defaults) do cfg[k]=v end
  cfg.decoration=style;cfg.decoration_color='#FFFFFF'
  local out=HUD.layout.compose(m,0,0,1,1,cfg,0);local frame=out[1];local n=0
  for _,d in ipairs(out) do if d.decoration and not d.child then
   n=n+1;assert(d.x>=frame.x and d.y>=frame.y and d.x+d.w<=frame.x+frame.w+.001 and d.y+d.h<=frame.y+frame.h+.001)
   assert(d.c[1]==255 and d.c[2]==255 and d.c[3]==255)
  end end
  assert(style=='none' and n==0 or style~='none' and n>0,style)
 end
end)
test('complete font catalog registers through the real legacy menu validator without saving tuning',function()
 local old,host=ModOptionsMenu,DBFMCM;DBFMCM=nil
 local compat=assert(loadfile('tests/fixtures/mcm_compat.lua'))()
 local api,state=compat.new(nil);ModOptionsMenu=api
 local writes=0;local h={config=HUD.config.new()}
 h.configure=function(v)HUD.config.apply(h.config,v)end
 h.save_tuning=function()writes=writes+1 end
 local menu=HUD.menu.new(h);menu.poll()
 assert(menu.status=='Options > Mods > DBF-HUD',menu.status)
 for _,o in pairs(state.options) do for _,label in ipairs(o.choices or {}) do assert(#label<=48)end end
 assert(writes==0);menu.retire();ModOptionsMenu=old;DBFMCM=host
end)
test('Double Freedom scanlines and sweeps follow final BigBlue parent and child bounds',function()
 local cfg=HUD.config.new();cfg.font='bigblue';cfg.effect_scanlines=true;cfg.effect_sweep=true
 local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='72170a55a1f37ff1',kind='rounds',rounds=2,capacity=2,reserve=30,fire_mode='SEMI'}))
 local out=HUD.world_style.prepare(HUD.layout.compose(m,0,0,1,1,cfg,.4),{first_person=true},cfg)
 local parent,child=out[1];for _,v in ipairs(out)do if v.type=='panel' and v.child then child=v end end
 local n=0;for _,v in ipairs(out)do if v.df_effect_frame then
  local frame=v.df_effect_frame=='child' and child or parent
  assert(v.x==frame.x and v.w==frame.w and v.y>=frame.y and v.y+v.h<=frame.y+frame.h+.001);n=n+1
 end end
 assert(n>48)
 local pitch,parent_y,child_y;for _,v in ipairs(out)do if v.scanline_layer then
  local previous;if v.df_effect_frame=='child' then previous=child_y else previous=parent_y end
  if previous then local gap=v.y-previous;if pitch then assert(math.abs(gap-pitch)<.001)else pitch=gap end end
  if v.df_effect_frame=='child' then child_y=v.y else parent_y=v.y end
 end end
 assert(pitch and parent.y+parent.h-parent_y<=pitch*2 and child.y+child.h-child_y<=pitch*2)
end)
test('weapon panel overrides isolate Double Freedom and Autocannon and persist through reload',function()
 local cfg=HUD.config.new();local df,ac='72170a55a1f37ff1','a8cffb316f0b5c5f'
 local global=HUD.config.serialize(cfg)
 HUD.config.set_panel(cfg,df,{panel_opacity=.9,background_color='#17191B',effect_scanlines=true,effect_scanline_count=31,decoration='none'})
 assert(HUD.config.effective(cfg,df).panel_opacity==.9 and HUD.config.effective(cfg,ac).panel_opacity==cfg.panel_opacity)
 assert(HUD.config.effective(cfg,ac).effect_scanline_count==21)
 local restored=HUD.config.new();HUD.config.apply(restored,assert(loadstring(HUD.config.serialize(cfg)))())
 assert(HUD.config.effective(restored,df).effect_scanline_count==31 and HUD.config.effective(restored,ac).background_color==cfg.background_color)
 local before=HUD.config.serialize(restored)
 assert(not pcall(HUD.config.set_panel,restored,df,{effect_scanline_count=100}));assert(HUD.config.serialize(restored)==before)
 assert(not pcall(HUD.config.set_panel,restored,df,{mount_x=1}))
 HUD.config.set_panel(restored,df,false);assert(HUD.config.serialize(restored)==global)
 local other=HUD.config.new();assert(next(other.weapon_panels)==nil)
end)
test('weapon appearance menu follows equipped identity without saving while switching',function()
 local core=assert(loadfile('../ModConfigurationMenu/src/core.lua'))();local host=core.new(nil,function()end)
 local previous,legacy=DBFMCM,ModOptionsMenu;DBFMCM=host;ModOptionsMenu=nil
 local df,ac='72170a55a1f37ff1','a8cffb316f0b5c5f';local equipped=df;local writes=0
 local h={config=HUD.config.new()}
 h.appearance_weapon=function()return equipped end
 h.panel_settings=function()return HUD.config.effective(h.config,equipped)end
 h.configure_panel=function(v,id)HUD.config.set_panel(h.config,id or equipped,v)end
 h.configure=function(v)HUD.config.apply(h.config,v)end;h.save_tuning=function()writes=writes+1;return true end
 local menu=HUD.menu.new(h);menu.poll();local mod=host.mods.dbf_hud_fonts;assert(mod.controls.weapon_panel_opacity)
 assert(mod.handle.set('weapon_panel_opacity',.9));assert(writes==1)
 assert(h.config.panel_opacity~=.9 and h.config.weapon_panels[df].panel_opacity==.9)
 equipped=ac;menu.poll();assert(mod.handle.get('weapon_panel_opacity')==h.config.panel_opacity and writes==1)
 assert(mod.handle.set('weapon_panel_opacity',.7));equipped=df;menu.poll();assert(mod.handle.get('weapon_panel_opacity')==.9 and writes==2)
 assert(math.abs(h.config.weapon_panels[ac].panel_opacity-.7)<1e-9)
 equipped=nil;menu.poll();assert(mod.controls.weapon_panel_opacity.disabled)
 menu.retire();DBFMCM=previous;ModOptionsMenu=legacy
end)



test('fuel rollback reproduces the gauge before catalog styling and leaves Stoker bullets themed',function()
 local apply=HUD.weapon_styles.apply
 local function same(a,b)
  if type(a)~=type(b) then return false end
  if type(a)~='table' then return a==b end
  for k,v in pairs(a) do if not same(v,b[k]) then return false end end
  for k in pairs(b) do if a[k]==nil then return false end end
  return true
 end
 for _,id in ipairs({'39ab99895147a3bf','3f92ba65ef65cca9','4fb0f8c02f55c82b','78a8185f63a70795','88f61afff48ac8a4','8a307bd1811a5fe9'}) do
  for _,scale in ipairs({.05,1,2}) do for _,n in ipairs({0,5,20,50,100}) do
   local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex=id,kind='magazine',rounds=n,capacity=100,reserve=3,reserve_kind='MAGS',alternate_fire=id=='8a307bd1811a5fe9'}))
   local actual=HUD.layout.compose(m,0,0,scale,1,HUD.config.defaults,0)
   HUD.weapon_styles.apply=function(out)return out end
   local previous=HUD.layout.compose(m,0,0,scale,1,HUD.config.defaults,0)
   HUD.weapon_styles.apply=apply
   assert(same(actual,previous),id)
  end end
 end
 local bullets=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='8a307bd1811a5fe9',kind='magazine',rounds=7,capacity=10,reserve=3,reserve_kind='MAGS'}))
 assert(bullets.label=='ROUNDS' and not HUD.layout.compose(bullets,0,0,1,1,HUD.config.defaults,0)[1].machined_catalog)
end)

test('Double Freedom open crimps follow observed firing and clear on reload or ownership loss',function()
 local track=HUD.df_shell_state.new()
 local function step(n,mode,id)
  local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='72170a55a1f37ff1',id=id or 1,unit_ref=id or 1,kind='rounds',rounds=n,capacity=2,reserve=14,reserve_kind='SHELLS',fire_mode=mode}))
  HUD.df_shell_state.step(track,m)
  local art=HUD.layout.compose(m,0,0,1,1,HUD.config.defaults,0);local spent={false,false};local count=0
  for _,v in ipairs(art) do if v.shotgun_shell_art then
   count=count+1
   local side=v.shotgun_shell_barrel
   spent[side]=spent[side] or v.shell_spent
   if v.shell_spent then assert(v.a==.55) end
  end end
  assert(count==2*#HUD.fire_icons.DOUBLE_FREEDOM_SHELL.runs+(spent[1] and 5 or 0)+(spent[2] and 5 or 0))
  assert(#art<140)
  return spent
 end
 local s=step(0,'SEMI');assert(not s[1] and not s[2],'unknown empty has no invented shot')
 s=step(2,'SEMI');assert(not s[1] and not s[2])
 s=step(1,'SEMI');assert(s[1] and not s[2],'left fires first')
 s=step(0,'SEMI');assert(s[1] and s[2])
 s=step(1,'SEMI');assert(not s[1] and not s[2],'reload clears observed-shot status')
 s=step(2,'VOLLEY');assert(not s[1] and not s[2])
 s=step(0,'VOLLEY');assert(s[1] and s[2],'volley opens both crimps')
 s=step(0,'VOLLEY',2);assert(not s[1] and not s[2],'replacement weapon clears status')
 step(2,'SEMI',2);s=step(1,'SEMI',2);assert(s[1]);HUD.df_shell_state.step(track,nil)
 s=step(1,'SEMI',2);assert(not s[1] and not s[2],'loss of ownership clears status')
 s=step(1,'VOLLEY',2);assert(not s[1] and not s[2],'mode change alone never invents firing')
end)

test('shared-suite proposal scope protects accepted panels and aliases and preserves live values',function()
 local function same(a,b)
  if type(a)~=type(b) then return false end
  if type(a)~='table' then return a==b end
  for k,v in pairs(a) do if not same(v,b[k]) then return false end end
  for k in pairs(b) do if a[k]==nil then return false end end
  return true
 end
 local total=0
 for id,style in pairs(HUD.weapon_styles.catalog) do
  local eligible=HUD.shared_suite.eligible(id)
  if eligible then total=total+1 end
  for _,scale in ipairs({.05,1,2}) do for _,mode in ipairs({'SEMI','AUTO','BURST'}) do for _,n in ipairs({0,1,7}) do
   local cfg=HUD.config.new();local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex=id,kind='magazine',rounds=n,capacity=10,reserve=8,reserve_kind='MAGS',fire_mode=mode}))
   local old=HUD.layout.compose(m,0,0,scale,1,cfg,0);cfg.shared_suite_preview=true
   local out=HUD.layout.compose(m,0,0,scale,1,cfg,0)
   assert(m.value==n and m.reserve==8 and m.fire_mode==mode)
   if not eligible or HUD.ammo_types.laser_weapons[id] then assert(same(old,out),'protected panel or deferred alias changed '..id)
   else
    assert(out[1].shared_suite and out[1].weapon_theme==style.family,id)
    local title=false;local count=false;local reserve=false;local label=false
    for _,v in ipairs(out) do
     if v.weapon_label then title=true;assert(v.c[1]==218 and v.c[2]==172 and v.c[3]==78) end
     count=count or v.text==string.format('%03d',n)
     reserve=reserve or v.type=='text' and v.text:find('008',1,true)~=nil
     label=label or v.text==mode
     if v.type=='rect' and not v.decoration and not v.child then local f=out[1];assert(v.x>f.x and v.x+v.w<f.x+f.w and v.y>f.y and v.y+v.h<f.y+f.h,id) end
    end
    assert(title and count and reserve and label,id);assert(#out<120,id)
   end
  end end end
 end
 assert(total==79)
 for _,kind in ipairs({'heat','infinite'}) do
  local cfg=HUD.config.new();cfg.shared_suite_preview=true
  local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='27ee1ed8f6fb6356',kind=kind,heat=.9,reserve=3,locked=false}))
  local out=HUD.layout.compose(m,0,0,1,1,cfg,0);assert(not out[1].shared_suite)
  if kind=='heat' then local fill=false;for _,v in ipairs(out) do fill=fill or v.heat_fill end;assert(fill and m.fraction==.9 and m.warning) else assert(m.value=='--') end
 end
end)

test('Autocannon long-case preview preserves mode colors, telemetry and compact panel',function()
 local source=HUD.fire_icons.GRENADE_PISTOL_SHELL
 for _,mode in ipairs({'APHET','FLAK'}) do
  local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='a8cffb316f0b5c5f',kind='rounds',rounds=8,capacity=10,reserve=7,reserve_kind='PACK',ammo_mode=mode,fire_mode='SEMI'}))
  local old=HUD.munition_art.autocannon_icon(m,source,false);local icon=HUD.munition_art.autocannon_icon(m,source,true)
  assert(icon.w==52 and icon.h==12 and #icon.runs==#old.runs and source.w==32)
  for i,r in ipairs(icon.runs) do assert(r[2]==old.runs[i][2] and r[4]==old.runs[i][4] and r[5]==old.runs[i][5]) end
  local cfg=HUD.config.new();local before=HUD.layout.compose(m,0,0,1,1,cfg,0);cfg.autocannon_long_preview=true
  local out=HUD.layout.compose(m,0,0,1,1,cfg,0);assert(out[1].w==before[1].w and out[1].h==before[1].h and #out==#before)
  local label,count,reserve,fire=false,false,false,false
  for _,v in ipairs(out) do
   label=label or v.text==mode;count=count or v.text=='008';reserve=reserve or v.text=='007 PACK';fire=fire or v.text=='SEMI'
   if v.catalog_heading then local f=out[1];assert(v.x>=f.x and v.x+v.w<=f.x+f.w) end
  end
  assert(label and count and reserve and fire and m.value==8 and m.reserve==7)
 end
 assert(HUD.munition_art.autocannon_icon({resource_hex='52e4334e6a128caf'},source,true)==source)
end)

test('Autocannon APHET and FLAK transitions preserve parent child and content anchors',function()
 for font in pairs(HUD.native_font_data.faces) do for _,scale in ipairs({.05,.65,2}) do for _,n in ipairs({0,1,8,11}) do
  local cfg=HUD.config.new();cfg.font=font;cfg.decoration='helldivers';local expected
  for _,mode in ipairs({'APHET','FLAK','APHET','FLAK'}) do
   local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='a8cffb316f0b5c5f',kind='rounds',rounds=n,capacity=10,reserve=7,reserve_kind='PACK',fire_mode='SEMI',ammo_mode=mode,chamber_supported=true,chamber_rounds=n==11 and 1 or 0}))
   local out=HUD.layout.compose(m,42,17,scale,1,cfg,0);local signature={}
   for _,v in ipairs(out) do
    if v.type=='panel' then signature[#signature+1]=string.format('P:%.9f,%.9f,%.9f,%.9f',v.x,v.y,v.w,v.h)
    elseif v.text==string.format('%03d',n) or v.text=='SEMI' or v.text=='007 PACK' or v.catalog_caption then signature[#signature+1]=string.format('T:%s:%.9f,%.9f,%.9f',v.text,v.x,v.y,v.size)
    elseif v.catalog_heading then signature[#signature+1]=string.format('I:%.9f,%.9f,%.9f,%.9f',v.x,v.y,v.w,v.h) end
   end
   signature=table.concat(signature,';')
   if not expected then expected=signature else assert(signature==expected,font..' mode-switch layout shifted') end
  end
 end end end
end)

test('Recoilless reference detail preview preserves panel and native ammunition state',function()
 for _,scale in ipairs({.05,1,2}) do for _,mode in ipairs({'HEAT','HE'}) do for _,n in ipairs({0,1}) do
  local cfg=HUD.config.new();cfg.recoilless_topthird_preview=false;local m={value=n,ammo_mode=mode,reserve=6}
  local frame={x=0,y=0};cfg.recoilless_detail_preview=false;local old=HUD.recoilless_panel.compose(frame,m,scale,cfg,1)
  cfg.recoilless_detail_preview=nil;local out=HUD.recoilless_panel.compose(frame,m,scale,cfg,1)
  assert(out[1].w==old[1].w and out[1].h==old[1].h)
  local rounds=0;local labels={}
  for _,v in ipairs(out) do
   if v.recoilless_round then rounds=rounds+1;assert(v.x>=59.8*scale and v.x+v.w<=72.2*scale and v.y>=33*scale and v.y+v.h<=90*scale) end
   if v.type=='text' then labels[v.text]=true end
  end
  assert(labels[mode] and labels['006 RCKTS'] and labels[n==1 and 'LOADED' or 'EMPTY'])
  assert(n==0 and rounds==0 or n==1 and rounds>40)
  local texts={};for _,v in ipairs(old) do if v.type=='text' then texts[v.text]=v end end
  for _,v in ipairs(out) do if v.type=='text' then local before=texts[v.text];assert(before and v.x==before.x and v.y==before.y and v.size==before.size) end end
 end end end
end)

test('Recoilless close-up clips uniformly and retains casing only after observed firing',function()
 local s=HUD.recoilless_state.new()
 local function step(n,unit)
  local m={resource_hex='9f80d67a12a7e40f',value=n,id=1,unit_ref=unit or 9,ammo_mode='HEAT',reserve=5}
  HUD.recoilless_state.step(s,m);return m
 end
 assert(not step(0).recoilless_spent,'initial empty is not an observed shot')
 local full=step(1);assert(not full.recoilless_spent)
 local spent=step(0);assert(spent.recoilless_spent and step(0).recoilless_spent)
 local cfg=HUD.config.new();cfg.recoilless_topthird_preview=true
 for _,scale in ipairs({.05,1,2}) do
  local high={}
  for i,m in ipairs({full,spent}) do
   high[i]=0;local count=0
   for _,v in ipairs(HUD.recoilless_panel.compose({x=0,y=0},m,scale,cfg,1)) do
    if v.recoilless_round then
     count=count+1;if i==2 then assert(v.recoilless_part=='case' and not (v.c[1]==226 and v.c[2]==200 and v.c[3]==102),'spent case must not retain projectile or colored band') end;assert(v.x>=24*scale and v.x+v.w<=108*scale and v.y>=33*scale and v.y+v.h<=90*scale)
     high[i]=math.max(high[i],(v.y+v.h)/scale)
    end
   end
   assert(count>0,'retained casing is visible')
  end
  assert(high[1]>89 and high[2]>57 and high[2]<58,'projectile removed; original case shoulder retained')
 end
 assert(not step(1).recoilless_spent,'reload clears shot state')
 step(0);assert(not step(0,10).recoilless_spent,'ownership change clears shot state')
 step(1);step(0);HUD.recoilless_state.step(s,nil);assert(not step(0).recoilless_spent)
end)

test('Double Freedom reference proportions preview preserves anchors and observed states',function()
 local cfg=HUD.config.new();cfg.double_freedom_proportions_preview=true;cfg.double_freedom_compact_preview=false
 local tracker=HUD.df_shell_state.new()
 for _,scale in ipairs({.05,1,2}) do
  for _,n in ipairs({2,1,0,2}) do
   local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='72170a55a1f37ff1',kind='rounds',rounds=n,capacity=2,reserve=14,reserve_kind='SHELLS',fire_mode='SEMI'}))
   HUD.df_shell_state.step(tracker,m)
   local out=HUD.layout.compose(m,0,0,scale,1,cfg,0);local art=0
   for _,v in ipairs(out) do
    if v.shotgun_shell_art then
     art=art+1;assert(v.y>=32*scale and v.y+v.h<=77*scale+.000001)
     local left=out[1].w/scale/2+(v.shotgun_shell_barrel==1 and -25 or 25)-10.5
     assert(v.x>=left*scale and v.x+v.w<=(left+21)*scale+.000001)
     if v.c[1]>v.c[2] and v.c[2]>v.c[3] then assert(v.y+v.h<=41*scale+.000001,'brass occupies bottom 20 percent') end
    elseif v.weapon_label then assert(v.y==84*scale or v.y==99*scale)
    elseif v.barrel_indicator then assert(v.y==26*scale) end
   end
   assert(art>0 and m.value==n and m.reserve==14)
  end
 end
end)

test('Deadeye decoration preset reproduces original geometry and persists without changing selection',function()
 local cfg=HUD.config.new();assert(cfg.decoration=='none')
 HUD.config.apply(cfg,{decoration='deadeye'})
 local saved=HUD.config.serialize(cfg);local restored=HUD.config.new()
 HUD.config.apply(restored,assert(loadstring(saved))());assert(restored.decoration=='deadeye')
 assert(HUD.config.decorations[5]=='double' and HUD.config.decorations[6]=='deadeye')
 local out={};HUD.layout.decorate(out,{x=0,y=0,w=126,h=100},1,cfg,1)
 assert(#out==8 and out[1].w==126 and out[1].h==1 and out[1].c[1]==198 and out[1].a==.55)
 assert(out[5].x==4 and out[5].y==4 and out[5].w==3 and out[5].c[1]==218 and out[5].a==.75)
 assert(out[8].x==119 and out[8].y==93)
 for _,id in ipairs({'e6d932be83729076','72170a55a1f37ff1','a8cffb316f0b5c5f','9f80d67a12a7e40f','39ab99895147a3bf'}) do
  for _,scale in ipairs({.05,1,2}) do
   local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex=id,kind='rounds',rounds=1,capacity=id=='9f80d67a12a7e40f' and 1 or 10,reserve=5,ammo_mode=id=='a8cffb316f0b5c5f' and 'FLAK' or nil,fire_mode='SEMI'}))
   local commands=HUD.layout.compose(m,13,27,scale,1,cfg,0);local panels={};local decorations=0
   for _,v in ipairs(commands) do if v.type=='panel' then panels[#panels+1]=v end end
   for _,v in ipairs(commands) do if v.decoration then
    decorations=decorations+1;local inside=false
    for _,f in ipairs(panels) do inside=inside or (v.x>=f.x-.000001 and v.y>=f.y-.000001 and v.x+v.w<=f.x+f.w+.000001 and v.y+v.h<=f.y+f.h+.000001) end
    assert(inside)
   end end
   assert(decorations==8*#panels)
  end
 end
end)

test('Double Freedom tighter box keeps full size shells and all content inside bounds',function()
 for font in pairs(HUD.native_font_data.faces) do for _,scale in ipairs({.05,1,2}) do
  local cfg=HUD.config.new();cfg.font=font;cfg.double_freedom_compact_preview=true
  local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='72170a55a1f37ff1',kind='rounds',rounds=2,capacity=2,reserve=14,reserve_kind='SHELLS',fire_mode='SEMI'}))
  local out=HUD.layout.compose(m,0,0,scale,1,cfg,0);local f=out[1];assert(f.w>=120*scale and f.h>=112*scale)
  for _,v in ipairs(out) do if not v.child then
   if v.type=='rect' then assert(v.x>=f.x and v.y>=f.y and v.x+v.w<=f.x+f.w+.000001 and v.y+v.h<=f.y+f.h+.000001)
   elseif v.type=='text' then local a,b,e,t=HUD.font.measure(v.text,v.size,font);assert(v.x+a>=0 and v.x+e<=f.w and v.y+b>=0 and v.y+t<=f.h,font..' text fits compact box') end
  end end
 end end
end)

test('Double Freedom stacked titles reserves and modes center in native and final world frames',function()
 for font in pairs(HUD.native_font_data.faces) do for _,scale in ipairs({.05,1,2}) do for _,reserve in ipairs({0,30,999,1234}) do
  local cfg=HUD.config.new();cfg.font=font;cfg.style_3d='standard'
  local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='72170a55a1f37ff1',kind='rounds',rounds=2,capacity=2,reserve=reserve,reserve_kind='SHELLS',fire_mode='VOLLEY'}))
  local native=HUD.layout.compose(m,13,27,scale,1,cfg,0)
  assert(native[1].world_reference_width and native[1].w>=120*scale)
  for _,commands in ipairs({native,HUD.world_style.prepare(native,{first_person=false},cfg)}) do
   local frame=commands[1];local seen=0
   for _,v in ipairs(commands) do
    if v.text=='DBS-2' or v.text=='DOUBLE FREEDOM' or v.text==string.format('%03d SHELLS',reserve) or v.text=='VOLLEY' then
     local a,b,e=HUD.font.measure(v.text,v.size,font,true)
     assert(math.abs(v.x+(a+e)/2-frame.x-frame.w/2)<.000001,font..' measured text centered')
     if v.weapon_label then assert(v.c[1]==218 and v.c[2]==172 and v.c[3]==78) end
     seen=seen+1
    end
   end
   assert(seen==4)
  end
  if font=='bigblue' and scale==2 and reserve==30 then
   local world=HUD.world_style.prepare(native,{first_person=false},cfg)
   assert(world[1].w<215 and world[1].w>195,'actual world panel narrows instead of normalizing back to240: '..world[1].w)
  end
 end end end
end)

test('Double Freedom half-width shells stay centered over unchanged closer capacity lines',function()
 for _,scale in ipairs({.05,1,2}) do for _,mode in ipairs({'SEMI','VOLLEY'}) do
  local cfg=HUD.config.new();local tracker=HUD.df_shell_state.new()
  for _,n in ipairs({2,1,0,2}) do
   local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='72170a55a1f37ff1',kind='rounds',rounds=n,capacity=2,reserve=30,reserve_kind='SHELLS',fire_mode=mode}))
   HUD.df_shell_state.step(tracker,m);local native=HUD.layout.compose(m,0,0,scale,1,cfg,0)
   for _,out in ipairs({native,HUD.world_style.prepare(native,{first_person=true},cfg)}) do
    local bars,spans={},{{math.huge,-math.huge},{math.huge,-math.huge}}
    for _,v in ipairs(out) do
     if v.barrel_indicator then bars[v.barrel_indicator]=v end
     if v.shotgun_shell_art then local span=spans[v.shotgun_shell_barrel];span[1]=math.min(span[1],v.x);span[2]=math.max(span[2],v.x+v.w) end
    end
    for i=1,2 do assert(math.abs(spans[i][2]-spans[i][1]-bars[i].w/2)<.000001 and math.abs((spans[i][1]+spans[i][2])/2-bars[i].x-bars[i].w/2)<.000001,'shell span is half the line and remains centered') end
    assert(math.abs((bars[2].x-bars[1].x-bars[1].w)/bars[1].w-8/42)<.000001,'central gap is eight layout units')
    local f=out[1];assert(math.abs((bars[1].x+bars[2].x+bars[2].w)/2-f.x-f.w/2)<.000001,'pair is symmetric about final frame')
   end
  end
 end end
end)

test('Senator approved six-round layout follows observed firing refills and ownership reset',function()
 for _,scale in ipairs({.05,1,2}) do
  local cfg=HUD.config.new();local tracker=HUD.senator_state.new()
  local function step(n,unit)
   local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex='8d3d52a3b2f19402',id=1,unit_ref=unit or 9,kind='rounds',rounds=n,capacity=6,reserve=30,reserve_kind='ROUNDS',fire_mode='SEMI'}))
   HUD.senator_state.step(tracker,m);return m
  end
  local initial=step(0);for _,v in ipairs(initial.senator_slots) do assert(not v.case) end
  for _,n in ipairs({6,5,3,0,1,6}) do
   local m=step(n);local out=HUD.layout.compose(m,0,0,scale,1,cfg,0);local seen={};local cases={};local footer,mode,title=false,false,false
   for _,v in ipairs(out) do
    if v.senator_part=='projectile' then seen[v.senator_slot]=true end
    if v.senator_part=='case' then cases[v.senator_slot]=true end
    footer=footer or v.text=='030 ROUNDS';mode=mode or v.text=='SEMI';title=title or v.text=='P-4 SENATOR'
    assert(v.text~=string.format('%03d',n),'six tips replace the loaded counter')
   end
   local count=0;for i=1,6 do if seen[i] then count=count+1 end;assert(cases[i]) end
   assert(count==n and footer and mode and title and m.reserve==30)
  end
  step(0);local other=step(0,10);for _,v in ipairs(other.senator_slots) do assert(not v.case) end
  step(6);step(0);HUD.senator_state.step(tracker,nil);local reset=step(0);for _,v in ipairs(reset.senator_slots) do assert(not v.case) end
  assert(not HUD.senator_state.supports_speedloader and not HUD.senator_state.supports_ejection)
 end
end)

test('extra artwork bays are retired and laser variants share their earlier telemetry layout',function()
 assert(not HUD.catalog_housing.enabled and not HUD.shared_suite.enabled)
 local cfg=HUD.config.new();cfg.decoration='deadeye'
 local old=HUD.weapon_styles.apply
 local total=0
 for id in pairs(HUD.ammo_types.laser_weapons) do
  total=total+1
  for _,kind in ipairs({'heat','rounds','infinite'}) do for _,scale in ipairs({.05,1,2}) do
   local m=HUD.model.normalize(HUD.ammo_types.apply({resource_hex=id,kind=kind,heat=.88,rounds=4,capacity=10,reserve=2,reserve_kind='HTSNKS'}))
   local a=HUD.layout.compose(m,0,0,scale,1,cfg,0)
   HUD.weapon_styles.apply=function(out)return out end
   local b=HUD.layout.compose(m,0,0,scale,1,cfg,0);HUD.weapon_styles.apply=old
   assert(#a==#b,id)
   for i,v in ipairs(a) do local q=b[i];assert(v.type==q.type and v.text==q.text and v.x==q.x and v.y==q.y and v.w==q.w and v.h==q.h,id);assert(not v.catalog_heading and not v.machined_detail and not v.catalog_detail,id) end
   assert(m.reserve==2 and (kind~='heat' or m.fraction==.88 and m.warning))
  end end
 end
 assert(total==9)
end)

print(string.format('%d contract tests passed',tests))
