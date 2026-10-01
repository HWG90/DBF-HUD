HUD={}
for _,name in ipairs({'config','font_data','nerd_font_data','font','motion','model','layout','memory','layouts','reader','pose','camera_mode','projection','camera_state','anchor','view','pose_motion','world_probe','offscreen_test','scene_test','menu','runtime'}) do HUD[name]=assert(loadfile('src/'..name..'.lua'))() end
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
    U(state,45);m=assert(reader.poll());assert(m.rounds==46 and m.capacity==46)
end)
test('rounds selects correct tube and includes chamber',function()
    local rm=manager('rounds');bind(rm,0x28,0x40,20,weapon);P(rm+0x50,state);P(rm+0x58,runtime)
    map(rm+0x68,{[20]=0});local cfgaddr=alloc(0x88);P(rm+0xa8,cfgaddr)
    F(cfgaddr+0x4c,4);U(cfgaddr+0x50,20);bytes[cfgaddr+0x68]=1
    U(flags,0x140);U(state+8,3);U(state+16,1);U(runtime+4,1);U(runtime,12)
    local m=assert(reader.poll(),reader.status);assert(m.rounds==4 and m.capacity==4 and m.reserve==12)
    U(runtime+4,2);assert(reader.poll()==nil);U(runtime+4,1)
end)
test('heat uses configured limit and lock state',function()
    local hm=manager('heat');bind(hm,0x28,0x40,20,weapon);P(hm+0x58,runtime)
    map(hm+0x68,{[20]=0});local c=alloc(0x250);P(hm+0xa8,c);F(c+0x60,100);U(c+0x5c,3)
    U(flags,0x240);U(runtime,2);F(runtime+4,92);bytes[runtime+8]=1
    local m=assert(reader.poll(),reader.status);assert(math.abs(m.heat-.92)<1e-6 and m.locked and m.reserve==2)
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
    map(owner+L.entity_map,{[10]=0,[20]=1,[21]=2})
    local rm=alloc(256);P(base+L.resource[1],rm);bind(rm,0x20,0x38,20,weapon)
    local resource=alloc(36);P(rm+0x48,resource);U(resource,21)
    local dm=alloc(256);P(base+L.deposit[1],dm);bind(dm,0x20,0x38,21,dep)
    local counts=alloc(8);P(dm+0x50,counts);U(counts,17);U(flags,0x400)
    local m=assert(reader.poll(),reader.status);assert(m.kind=='resource' and m.rounds==17)
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
    for _,f in ipairs({0,.74,.74999}) do assert(HUD.layout.heat_color(f,0,c)==c.heat_white) end
    for _,f in ipairs({.75,.85,.85999}) do assert(HUD.layout.heat_color(f,0,c)==c.heat_yellow) end
    for _,f in ipairs({.86,.94,.94999}) do assert(HUD.layout.heat_color(f,0,c)==c.heat_red) end
    for _,f in ipairs({.95,1}) do
        assert(HUD.layout.heat_color(f,0,c)==c.heat_red)
        assert(HUD.layout.heat_color(f,.25,c)==c.heat_yellow)
        assert(HUD.layout.heat_color(f,.5,c)==c.heat_red)
    end
end)
test('heat fill grows from the bottom and preserves partial cells',function()
    local function fills(f)
        local m=HUD.model.normalize({id=1,kind='heat',heat=f,reserve=2})
        local d=HUD.layout.compose(m,0,0,1,1,HUD.config.new(),0);local out={}
        for _,v in ipairs(d) do if v.type=='rect' and v.w==9 and v.a==.95 then out[#out+1]=v end end
        return out,d
    end
    assert(#fills(0)==0)
    local half=fills(.5);assert(#half==10 and half[1].y==-8 and math.abs(half[10].y-14.5)<1e-8)
    local partial=fills(.525);assert(#partial==11 and math.abs(partial[11].h-1)<1e-8)
    local full,d=fills(1);assert(#full==20 and math.abs(full[20].y-39.5)<1e-8)
    local found=false;for _,v in ipairs(d) do if v.text=='OVERHEAT' then found=true end end;assert(found)
end)
test('vent pulses red without disappearing even below the heat threshold',function()
    local cfg=HUD.config.new()
    local m={kind='heat',fraction=.5,value=50,state='VENT',reserve=1}
    local a=HUD.layout.compose(m,0,0,1,1,cfg,0)
    local b=HUD.layout.compose(m,0,0,1,1,cfg,.25)
    local red=HUD.config.rgb(cfg.heat_red)
    for i=1,3 do assert(a[2].c[i]==red[i] and b[2].c[i]==red[i]) end
    assert(math.abs(b[2].a/a[2].a-.25)<1e-6)
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
    local restored=HUD.config.new();HUD.config.apply(restored,loaded);for k,v in pairs(c) do assert(restored[k]==v) end
    assert(not pcall(HUD.config.apply,c,{scale=1.5,archived_mesh={unknown=1}}) and c.scale==1)
    assert(not pcall(HUD.config.apply,c,{saturation=1,archived_mesh={saturation=2}}))
end)
test('all ten Nerd Fonts draw within measured bounds and fit panel frames',function()
    assert(#HUD.config.fonts==12)
    for i=3,#HUD.config.fonts do
        local name=HUD.config.fonts[i];local cfg=HUD.config.new();HUD.config.apply(cfg,{font=name})
        for _,size in ipairs({12,24,36,53.5}) do
            local text='0123456789 % HEAT SINKS /?';local l,b,r,t=HUD.font.measure(text,size,name);local count=0
            HUD.font.draw(text,size,0,0,function(x,y,w,h)
                assert(w>0 and h>0 and x>=l-1e-6 and y>=b-1e-6 and x+w<=r+1e-6 and y+h<=t+1e-6);count=count+1
            end,name)
            assert(count>0)
        end
        local commands=HUD.layout.compose({kind='heat',fraction=.8,value=80,reserve=3,state='READY'},0,0,1,1,cfg,0)
        local frame=commands[1]
        for _,c in ipairs(commands) do if c.type=='text' then
            local l,b,r,t=HUD.font.measure(c.text,c.size,name)
            assert(c.x+l>=frame.x-1e-6 and c.y+b>=frame.y-1e-6 and c.x+r<=frame.x+frame.w+1e-6 and c.y+t<=frame.y+frame.h+1e-6)
        end end
        local restored=HUD.config.new();HUD.config.apply(restored,assert(loadstring(HUD.config.serialize(cfg)))());assert(restored.font==name)
    end
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
            for i=#plain+1,#decorated do local r=decorated[i]
                assert(r.decoration and r.w>0 and r.h>0 and r.x>=f.x-1e-6 and r.y>=f.y-1e-6 and r.x+r.w<=f.x+f.w+1e-6 and r.y+r.h<=f.y+f.h+1e-6)
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
        p.auto_mount=a;c.placement_mode='auto';local x,y,z=HUD.scene_test.mount(p,c);assert(x==a.x and y==a.y and z==a.z)
    end
    c.placement_mode='manual';p.left_shoulder=false
    local x,y,z=HUD.scene_test.mount(p,c);assert(x==.3 and y==.4 and z==.7)
    assert(c.mount_x==.3 and c.mount_y==.4 and c.mount_z==.5)
end)

test('native menu keeps colors config-only and persists placement',function()
    local options,values,callbacks={},{},{};local writes=0
    ModOptionsMenu={api=1,register_option=function(id,spec) options[id]=spec;values[id]=spec.default;return true end,
        on_change=function(id,fn)callbacks[id]=fn;return true end,set=function(id,v)values[id]=v;return true end}
    local h={config=HUD.config.new()};local menu
    h.configure=function(v)HUD.config.apply(h.config,v);menu.sync()end
    h.save_tuning=function()writes=writes+1 end
    menu=HUD.menu.new(h);menu.poll();assert(menu.status=='Options > Mods > DBF-HUD')
    local n=0;for _ in pairs(options) do n=n+1 end;assert(n==32)
    callbacks['dbf_hud_placement.offset_x'](-120);assert(h.config.offset_x==-120)
    assert(not callbacks['dbf_hud_v3.color_target'] and not callbacks['dbf_hud_v3.rgba1'])
    callbacks['dbf_hud_v4.font_nerd'](2);assert(h.config.font=='debug' and writes==2)
    callbacks['dbf_hud_v4.font_nerd'](1);assert(h.config.font=='bigblue' and writes==3)
    callbacks['dbf_hud_v4.debug_logging'](true);assert(h.config.debug_logging and writes==4)
    callbacks['dbf_hud_v4.decoration'](4);assert(h.config.decoration=='helldivers' and writes==5)
    callbacks['dbf_hud_v4.decoration'](1);assert(h.config.decoration=='none' and writes==6)
    local groups={};for _,spec in pairs(options) do groups[spec.mod]=(groups[spec.mod] or 0)+1 end
    assert(groups['DBF-HUD']==10 and groups['DBF-HUD Placement']==22)
    assert(not options['dbf_hud_v4.emissive_intensity'] and not options['dbf_hud_v4.pose_marker'])
    callbacks['dbf_hud_v4.display_mode'](1);assert(h.config.anchor_mode=='weapon')
    callbacks['dbf_hud_v4.display_mode'](2);assert(h.config.anchor_mode=='crosshair')
    callbacks['dbf_hud_v4.display_mode'](3);assert(h.config.anchor_mode=='world')
    callbacks['dbf_hud_v4.always_show_3d'](true);assert(h.config.occlusion_mode=='gui' and h.config.always_show_3d)
    callbacks['dbf_hud_v4.always_show_3d'](false);assert(h.config.occlusion_mode=='gui_depth' and not h.config.always_show_3d)
    menu.retire();callbacks['dbf_hud_placement.offset_x'](42);assert(h.config.offset_x==-120)
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
    v.draw(command);assert(bitmaps==0 and panelalpha==255)
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
            if c.text==string.format('%02d',m.value) then number=c end
            if c.text=='%' then percent=c end
        end
        assert(number and percent and percent.x-(number.x+#number.text*number.size*.6)==4)
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
    assert(b[1].w>a[1].w)
end)

test('BigBlue glyph drawing snaps to pixels and fits its measured bounds',function()
    for code=32,126 do
        for _,size in ipairs({6,12,18,24,36,72,144}) do
            local text=string.char(code);local a,b,c,d=HUD.font.measure(text,size);local n=0
            HUD.font.draw(text,size,.3,-.3,function(x,y,w,h)
                n=n+1;assert(x==math.floor(x) and y==math.floor(y))
                assert(w>0 and h>0 and w==math.floor(w) and h==math.floor(h))
                assert(x>=a and y>=b and x+w<=c and y+h<=d)
            end)
            assert(n<=12)
        end
    end
end)

test('BigBlue frame contains glyphs and stacked labels across scales',function()
    for _,scale in ipairs({.25,.5,.67,1,1.25,1.5,2,3,4}) do
        for _,heat in ipairs({.62,1}) do
            local m=HUD.model.normalize({kind='heat',heat=heat,reserve=3})
            local commands=HUD.layout.compose(m,100.3,120.7,scale,1,HUD.config.new(),0)
            local panel=commands[1];local header,number,footer
            for _,c in ipairs(commands) do
                if c.type=='text' then
                    assert(c.a==1 and c.font=='bigblue')
                    local a,b,e,f=HUD.font.measure(c.text,c.size)
                    if c.text=='HEAT' then header=c elseif c.text==string.format('%02d',m.value) then number={c.y+b,c.y+f} elseif c.text:find('SINKS') or c.text=='OVERHEAT' then footer={c.y+b,c.y+f} end
                    HUD.font.draw(c.text,c.size,c.x,c.y,function(x,y,w,h)
                        assert(x>=panel.x and x+w<=panel.x+panel.w)
                        assert(y>=panel.y and y+h<=panel.y+panel.h)
                    end)
                end
            end
            assert(header.y>number[2] and footer[2]<number[1])
        end
    end
end)

test('BigBlue renderer uses rectangles and releases all of them',function()
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
    v.draw({cmd});assert(texts==0 and index>0 and index<=12*#cmd.text)
    v.clear();assert(next(active)==nil)
    cmd.font='debug';v.draw({cmd});assert(texts==1);v.release();assert(next(active)==nil)
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
    assert(received.x==1 and received.y==2.5 and received.z==3)
    local before=pose_reads;for i=1,10 do update(1/144)end;assert(pose_reads==before+10)
    local alpha=h.opacity;valid=false;update(1/60)
    assert(h.anchor_status~='weapon attachment' and h.opacity>=alpha)
    valid=true;update(1/60);assert(math.abs(h.motion_x-576)<1e-6)
    h.configure({anchor_mode='crosshair'});update(1/60);assert(h.anchor_status~='weapon attachment')
    h.configure({anchor_mode='world',always_show_3d=false});update(1/60);assert(world_draws==1 and selected_mode=='gui_depth')
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
        local menu=HUD.menu.new(h);menu.poll();assert(registered==32)
        callbacks['dbf_hud_placement.offset_x'](77);assert(h.config.offset_x==77 and writes==cycle)
        menu.retire();callbacks['dbf_hud_placement.offset_x'](88);assert(h.config.offset_x==77 and writes==cycle)
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
    callbacks['dbf_hud_placement.offset_x'](188);assert(h.config.offset_x==188)
    menu.retire();ModOptionsMenu=nil
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
        Gui={move=function()moved=moved+1 end,rect=function()drawn=drawn+1 end}}
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
    assert(probe.draw(p,cfg,commands));assert(material_draws>20)
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
    assert(probe.draw(p,cfg,commands));assert(drawn>previous+20)
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
print(string.format('%d contract tests passed',tests))

