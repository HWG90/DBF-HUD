-- Read the native crosshair controller AFTER the game's update.
-- Layout independently traced from hud_crosshair -> native update -> screen XY.
-- Never invokes game functions or writes game memory.
local M={}
local SPEC={
    manager=0x346D538,camera=0x346D560,hud=0x24E340,crosshair=0x19AAF8,
    signatures={
        {0x12F53AF,'488b2d82811702'},
        {0x12F588F,'488d8d40e32400448bc60f28cee8af63ffffeb17'},
        {0x12EBDF4,'498d8ef8aa1900448bc30f28cfe85aa74c00'},
        {0x17B6718,'488b0521fcb6018b8830c50a00'},
        {0x17B6FF5,'f20f1008488b4424500f28c1f3410f118f88200000f30f5cce0fc6c055f3410f11878c200000'},
        {0x17B7050,'f30f594010498bcf8b542424f30f114583488b44245849898790200000'},
        {0x144C370,'488b81f00000004885c074130f1f4000488bc8488b80f00000004885c075f1488bc1c3'}
    }
}
M.spec=SPEC
function M.new(backend)
    local r=HUD.memory.new(backend)
    local base,validated,failed;local self={status='not sampled',samples=0}
    local function validate()
        r.reset();base=assert(backend.module('game.dll'),'game.dll not loaded')
        local d=r.read(base,64);assert(d:sub(1,2)=='MZ','DOS signature')
        local offset=r.u(d,0x3c);assert(offset<0x100000,'PE offset')
        local h=r.read(base+offset,0x80)
        assert(h:sub(1,4)=='PE\0\0' and HUD.layouts.stamps[r.u(h,8)]==r.u(h,0x50),'unsupported anchor build')
        for _,s in ipairs(SPEC.signatures) do
            local expected=s[2]:gsub('..',function(hex)return string.char(tonumber(hex,16))end)
            assert(r.read(base+s[1],#expected)==expected,string.format('anchor signature %X',s[1]))
        end
        validated=true
    end
    local function optional_pointer(a)
        local b=r.read(a,8);local p=r.u(b,0)+r.u(b,4)*2^32
        if p==0 then return nil end
        assert(p>=65536 and p<2^47,'anchor pointer');return p
    end
    local function snapshot()
        r.reset()
        local manager=r.p(base+SPEC.manager)
        local hud=manager+SPEC.hud
        if r.read(hud+0x58,1):byte(1)==0 or r.read(hud+0x21f5b0,1):byte(1)==0 then return nil,'native HUD inactive' end
        local control=hud+SPEC.crosshair
        local b=r.read(control+0x2080,24)
        local state=r.u(b,0)
        if state==1 then return nil,'native reticle hidden' end
        assert(state>=2 and state<=4,'invalid reticle state')
        local pixel_x,pixel_y=r.f(b,8),r.f(b,12)
        local dx,dy=r.f(b,16),r.f(b,20)
        -- This is the same bounded parent walk as native UI root lookup 144C370.
        local root=control;local visited={};local finished=false
        for _=1,32 do
            assert(not visited[root],'UI parent cycle');visited[root]=true
            local parent=optional_pointer(root+0xf0)
            if not parent then finished=true;break end
            root=parent
        end
        assert(finished,'UI parent depth')
        local size=r.read(root+0xc,8);local width,height=r.f(size,0),r.f(size,4)
        assert(width>=64 and width<=32768 and height>=64 and height<=32768,'UI root dimensions')
        local camera=r.p(base+SPEC.camera);local offset=r.read(camera+0xdc,8)
        local cx,cy=r.f(offset,0),r.f(offset,4)
        assert(math.abs(cx)<=1 and math.abs(cy)<=1,'camera screen offset')
        -- Native: local = (screen - 0.5*viewport*(1+camera_offset))/viewport * UI_size.
        -- Invert it to normalize without confusing render-scale pixels with output pixels.
        local nx,ny=0.5*(1+cx)+dx/width,0.5*(1+cy)+dy/height
        assert(nx>=-1 and nx<=2 and ny>=-1 and ny<=2,'reticle coordinates out of range')
        assert(math.abs(pixel_x)<=65536 and math.abs(pixel_y)<=65536,'screen position out of range')
        assert(r.p(base+SPEC.manager)==manager and r.u(r.read(control+0x2080,4),0)==state,'reticle changed during read')
        self.samples=self.samples+1;self.native_state=state
        self.pixel_x,self.pixel_y,self.dx,self.dy=pixel_x,pixel_y,dx,dy
        self.min_x=math.min(self.min_x or nx,nx);self.max_x=math.max(self.max_x or nx,nx)
        self.min_y=math.min(self.min_y or ny,ny);self.max_y=math.max(self.max_y or ny,ny)
        return {x=math.max(0,math.min(1,nx)),y=math.max(0,math.min(1,1-ny)),visible=true},'native crosshair'
    end
    function self.poll()
        if failed then return nil end
        if not validated then
            local ok,err=pcall(validate)
            if not ok then self.status=tostring(err);failed=not self.status:find('game.dll not loaded',1,true);return nil end
        end
        local ok,result,status=pcall(snapshot)
        self.status=ok and status or tostring(result)
        return ok and result or nil
    end
    return self
end
return M
