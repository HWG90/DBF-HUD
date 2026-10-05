-- Native support is opt-in and limited to the measured game/API contracts.
local M={}
local function unhex(s)return(s:gsub('..',function(v)return string.char(tonumber(v,16))end))end
local contracts={
    create_resource='488bd1e9a8fbffffcccccccccccccccc',
    update_texture_base64='48895c240848896c2410488974241848',
    set_resource='48895c24184889742420574883ec20ba',
    refresh_instance_hash='4883ec28ba01000000ff15b9eff60048'
}
function M.new(sr,backend)
    local ffi=require('ffi');local util=require('jit.util')
    local function read(address,count)
        assert(type(address)=='number' and address>65535 and address+count<2^47 and count<=4096,'invalid native span')
        return assert(backend.read(address,count),'native span unreadable')
    end
    local function u32(bytes,offset)local b=ffi.new('uint8_t[?]',#bytes,bytes);return tonumber(ffi.cast('uint32_t*',b+offset)[0])end
    local function ptr(bytes,offset)local b=ffi.new('uint8_t[?]',#bytes,bytes);return tonumber(ffi.cast('uintptr_t*',b+offset)[0])end
    local module=assert(backend.module('helldivers2.exe'),'game module unavailable')
    local pe=read(module+u32(read(module,64),60),12)
    assert(pe:sub(1,4)=='PE\0\0' and u32(pe,8)==0x6ab382e4,'unverified game build')
    local apis={create_resource=sr.Renderer.create_resource,update_texture_base64=sr.Renderer.update_texture_base64,
        set_resource=sr.Material.set_resource,refresh_instance_hash=sr.Mesh.refresh_instance_hash}
    for name,fn in pairs(apis) do
        local address=assert(tonumber(util.funcinfo(assert(fn)).addr),'native API required')
        assert(read(address,16)==unhex(contracts[name]),'unverified native API: '..name)
    end
    local phase=false
    local self={}
    function self.set_phase(value)phase=value==true end
    function self.in_render_phase()return phase end
    local function texture(resource,width,height)
        assert(type(resource)=='userdata','factory userdata required')
        local address=tonumber(ffi.cast('uintptr_t',resource));local h=read(address,64)
        assert(h:byte(4)==0 and u32(h,8)==0 and u32(h,20)==width and u32(h,24)==height and u32(h,28)==1,'unexpected owned texture')
        assert(u32(h,48)==1 and u32(h,52)>=1,'unexpected owned backing array')
        local backing=ptr(read(ptr(h,56),8),0)
        return address,backing
    end
    local alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local function prefix64(bytes)
        local a,b,c,d=bytes:byte(1,4);local n=a*65536+b*256+c
        local function at(i)return alphabet:sub(i+1,i+1)end
        return at(math.floor(n/262144)%64)..at(math.floor(n/4096)%64)..at(math.floor(n/64)%64)..at(n%64)..at(math.floor(d/4))..at((d%4)*16)..'=='
    end
    function self.upload(image,record)
        assert(phase,'upload outside render bridge')
        for _,key in ipairs({'width','height'})do
            local n=image[key];assert(type(n)=='number' and n>=1 and n<=1024 and n%1==0,'invalid upload dimensions')
        end
        assert(image.format=='RGBA8' and image.row_pitch==image.width*4 and type(image.rgba)=='string' and #image.rgba==image.width*image.height*4,'invalid upload bytes')
        record.resource=assert(sr.Renderer.create_resource('texture','R8G8B8A8',image.width,image.height))
        local address,backing=texture(record.resource,image.width,image.height)
        local count=#image.rgba
        for offset=0,count-1,4096 do read(backing+offset,math.min(4096,count-offset))end
        local current_address,current_backing=texture(record.resource,image.width,image.height)
        assert(address==current_address and backing==current_backing,'owned allocation identity changed')
        ffi.copy(ffi.cast('void*',backing),image.rgba,count)
        for offset=0,count-1,4096 do
            local size=math.min(4096,count-offset)
            assert(read(backing+offset,size)==image.rgba:sub(offset+1,offset+size),'pixel readback differs')
        end
        record.address=address;record.backing=backing
        -- Native decoder has a small stack buffer. Never pass the whole image.
        sr.Renderer.update_texture_base64(record.resource,prefix64(image.rgba),4)
    end
    function self.target(spec)
        assert(type(spec)=='table' and (spec.kind=='world_mesh' or spec.kind=='scope'),'unsupported texture target kind')
        assert(type(spec.unit)=='userdata' and type(spec.unit_resource)=='string' and #spec.unit_resource==16 and spec.unit_resource:match('^[0-9a-f]+$'),'verified unit required')
        assert(type(spec.material_id)=='string' and spec.material_id:match('^[0-9a-f]+$') and #spec.material_id==16,'material identity required')
        assert(type(spec.texture_slot)=='string' and ({emissive_map=true,lens_occlusion_texture=true,reticle_texture=true,artwork_texture=true})[spec.texture_slot],'unverified texture slot')
        assert(type(spec.meshes)=='table' and #spec.meshes>=1 and #spec.meshes<=16,'mesh list required')
        assert(type(spec.material_slot)=='string' and #spec.material_slot==8 and spec.material_slot:match('^[0-9a-f]+$'),'material slot required')
        local t={kind=spec.kind,unit=spec.unit,unit_resource=spec.unit_resource,material_id=spec.material_id,
            texture_slot=spec.texture_slot,material_slot=spec.material_slot,meshes={}}
        for i,v in ipairs(spec.meshes)do assert(type(v)=='number' and v%1==0 and v>=1 and v<=256,'invalid mesh');t.meshes[i]=v end
        return t
    end
    local function resolve(t)
        local found,total=false,0
        for _,world in pairs(sr.Application.worlds())do for _,unit in pairs(sr.World.units(world))do
            total=total+1;assert(total<=32768,'unit inventory exceeds bound')
            if unit==t.unit then found=sr.IdString64.to_hex(sr.Unit.resource_name(unit)):lower()==t.unit_resource end
        end end
        if not found then return nil end
        local material,meshes=nil,{}
        local count=sr.Unit.num_meshes(t.unit)
        for _,index in ipairs(t.meshes)do
            if index>count then return nil end
            local mesh=sr.Unit.mesh(t.unit,index);if not mesh then return nil end
            local matched=false;local slots=sr.Mesh.num_materials(mesh);if slots>128 then return nil end
            for j=1,slots do
                if sr.IdString32.to_hex(sr.Mesh.material_slot_id(mesh,j)):lower()==t.material_slot then
                    local h=sr.Mesh.material(mesh,j);if not h then return nil end
                    -- Mesh.material returns the direct pointer; Unit.set_material does not.
                    local header=read(tonumber(ffi.cast('uintptr_t',h)),64)
                    if u32(header,0)==0x6f6f4d64 then return nil end
                    if sr.IdString64.to_hex(sr.Material.id64(h)):lower()~=t.material_id then return nil end
                    if material and material~=h then return nil end
                    material=h;matched=true
                end
            end
            if not matched then return nil end;meshes[#meshes+1]=mesh
        end
        return material,meshes
    end
    function self.valid(t)return resolve(t)~=nil end
    function self.validate_image(t,image)
        if t.texture_slot=='lens_occlusion_texture' then
            for i=1,#image.rgba,4 do
                local _,g,b,a=image.rgba:byte(i,i+3)
                assert(g==0 and b==0 and a==255,'lens mask requires R,0,0,255 pixels')
            end
        end
    end
    function self.bind(t,resource)
        assert(phase,'binding outside render bridge')
        local material,meshes=resolve(t);assert(material,'target retired or identity changed')
        sr.Material.set_resource(material,t.texture_slot,resource)
        if t.kind=='world_mesh' then for _,mesh in ipairs(meshes)do sr.Mesh.refresh_instance_hash(mesh)end end
    end
    return self
end
return M

