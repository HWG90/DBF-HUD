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
    local function uint(bytes,offset,count)
        assert(type(bytes)=='string' and type(offset)=='number' and offset>=0 and offset%1==0 and offset+count<=#bytes,'invalid metadata span')
        local value=0
        for i=offset+count,offset+1,-1 do value=value*256+bytes:byte(i) end
        return value
    end
    local function u32(bytes,offset)return uint(bytes,offset,4)end
    local function ptr(bytes,offset)
        local value=uint(bytes,offset,8)
        assert(value<2^47,'invalid native pointer')
        return value
    end
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
        return address,backing,ptr(h,56),u32(h,0)
    end
    local alphabet='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
    local function prefix64(bytes)
        local a,b,c,d=bytes:byte(1,4);local n=a*65536+b*256+c
        local function at(i)return alphabet:sub(i+1,i+1)end
        return at(math.floor(n/262144)%64)..at(math.floor(n/4096)%64)..at(math.floor(n/64)%64)..at(n%64)..at(math.floor(d/4))..at((d%4)*16)..'=='
    end
    local function image_contract(image)
        assert(image.format=='RGBA8' and type(image.rgba)=='string','invalid upload image')
        for _,key in ipairs({'width','height'})do local v=image[key];assert(type(v)=='number'and v>=1 and v<=2048 and v%1==0,'invalid dimensions')end
        assert(image.row_pitch==image.width*4 and #image.rgba==image.width*image.height*4,'invalid upload bytes')
    end
    function self.create(image,record)
        assert(phase,'creation outside render bridge');image_contract(image)
        assert(not record.resource,'fresh retained record required')
        record.rgba=image.rgba;record.width=image.width;record.height=image.height
        record.resource=assert(sr.Renderer.create_resource('texture','R8G8B8A8',image.width,image.height))
    end
    local function inspect(resource,width,height)
        local address,backing,array,id=texture(resource,width,height)
        return {address=address,backing=backing,array=array,id=id,kind=0,format=0,count=1,width=width,height=height}
    end
    local function upload_queue()
        local address=tonumber(util.funcinfo(sr.Renderer.update_texture_base64).addr)
        local instruction=read(address+0x1d,7)
        assert(instruction:sub(1,3)==string.char(0x48,0x8b,0x05),'unverified renderer context instruction')
        local displacement=ffi.new('int32_t[1]');ffi.copy(displacement,instruction:sub(4),4)
        local context=ptr(read(address+0x24+tonumber(displacement[0]),8),0)
        local renderer=ptr(read(context+0x338,8),0)
        return ptr(read(renderer+0x1c10,8),0)
    end
    function self.copy(image,record)
        assert(phase,'copy outside render bridge');image_contract(image)
        assert(record.resource and not record.source,'fresh uncopied resource required')
        local source=assert(HUD.runtime_texture_source,'owned texture source module missing')
        record.contract=inspect(record.resource,image.width,image.height)
        record.source=source.prepare(record.rgba,image.width,image.height)
        record.copied=true
    end
    function self.submit(record)
        assert(phase,'submission outside render bridge')
        assert(record.copied and not record.uploaded,'fresh copied resource required')
        self.check(record)
        record.prefix=prefix64(record.rgba)
        HUD.runtime_texture_source.submit(record.resource,record.source,function(resource)
            return inspect(resource,record.width,record.height)
        end,function(resource)
            sr.Renderer.update_texture_base64(resource,record.prefix,4)
        end)
        -- Verify the actual queue command captured our owned source pointer.
        -- A successful Lua call alone is neither transfer nor GPU completion.
        local queue=upload_queue();assert(queue>65535,'texture submission manager missing')
        local vector=read(queue+0x188,16);local count=u32(vector,0)
        assert(count>=1 and count<=4096,'unexpected texture queue length')
        local entry=read(ptr(vector,8)+(count-1)*24,24)
        local command=ptr(entry,8);local header=read(command,16)
        assert(header:byte(13)==3 and header:byte(14)==0,'unexpected texture queue opcode')
        local offset=header:byte(15)+header:byte(16)*256
        local payload=command+offset;local descriptor=read(payload,56)
        assert(u32(descriptor,0)==record.contract.id and u32(descriptor,44)==1,'texture queue identity mismatch')
        assert(ptr(read(payload+u32(descriptor,48),8),0)==record.source.pointer,'texture queue source mismatch')
        record.queue=queue;record.uploaded=true
    end
    function self.ready(record)
        assert(phase and record.uploaded and record.queue,'submitted texture required')
        self.check(record)
        if record.consumed then return true end
        -- The captured manager reset clears this vector after packet execution.
        -- Resources and owned source buffers remain retained after this ack.
        if u32(read(record.queue+0x188,4),0)~=0 then return false end
        record.consumed=true;return true
    end
    function self.check(record)
        assert(phase,'resource validation outside render bridge')
        assert(record.resource and record.contract and record.source,'retained resource and owned source required')
        local address,backing=texture(record.resource,record.width,record.height)
        assert(address==record.contract.address and backing==record.contract.backing,'retained resource identity changed')
        assert(type(record.rgba)=='string' and #record.rgba==record.width*record.height*4,'retained pixels changed')
    end
    local completion
    function self.retirement_token(record)
        assert(phase and record.consumed,'consumed upload and render phase required')
        self.check(record)
        completion=completion or assert(HUD.texture_completion,'completion adapter unavailable').new(backend,module)
        return completion.capture()
    end
    function self.retirement_done(token)
        assert(phase and completion,'retirement outside verified render phase')
        return completion.done(token)
    end
    function self.destroy_retired(record,token,detached)
        assert(phase and detached==true,'material references must be detached')
        assert(not record.release_started and record.consumed,'fresh consumed owned resource required')
        assert(self.retirement_done(token)==true,'old draw completion not acknowledged')
        self.check(record)
        local fn=assert(sr.Renderer.destroy_resource,'resource destruction API unavailable')
        local address=assert(tonumber(util.funcinfo(fn).addr),'native destruction API required')
        assert(read(address,16)==unhex('48895c24084889742410574883ec20ba'),'unverified destruction API')
        -- Native wrapper frees the CPU descriptor immediately. Never inspect it
        -- after this call or retry an uncertain outcome.
        record.release_started=true
        fn(record.resource)
        return true
    end
    function self.upload(image,record)
        -- Existing non-panel callers retain their synchronous contract.
        self.create(image,record);self.copy(image,record);self.submit(record)
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
