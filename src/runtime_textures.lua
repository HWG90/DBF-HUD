-- Queued immutable uploads. The adapter owns native contracts and render phase.
local M={max_image_bytes=16777216,max_retained_bytes=167772160}
local function dimensions(image)
    assert(type(image)=='table' and image.format=='RGBA8','RGBA8 image required')
    for _,key in ipairs({'width','height'}) do
        local n=image[key];assert(type(n)=='number' and n==n and n>=1 and n%1==0 and n<=2048,'invalid image dimensions')
    end
    local count=image.width*image.height*4
    assert(count<=M.max_image_bytes and image.row_pitch==image.width*4,'invalid image pitch')
    return count
end
function M.validate(image)
    local count=dimensions(image)
    assert(type(image.rgba)=='string' and #image.rgba==count,'invalid pixel length')
    return count
end
local function snapshot(image)
    return {format=image.format,width=image.width,height=image.height,row_pitch=image.row_pitch,rgba=image.rgba,path=image.path}
end
function M.read_image(path,width,height)
    assert(type(path)=='string' and not path:find('%z'),'invalid image path')
    assert(type(width)=='number','invalid image width')
    local count=dimensions({format='RGBA8',width=width,height=height,row_pitch=width*4})
    local f=assert(io.open(path,'rb'),'image file unavailable')
    local pixels=f:read(count+1);f:close()
    local image={format='RGBA8',width=width,height=height,row_pitch=width*4,rgba=pixels,path=path}
    M.validate(image);return image
end
function M.new(adapter,store)
    assert(type(adapter.ready)=='function','texture completion acknowledgment required')
    store=store or {bytes=0,resources={},claims={}}
    local self={targets={},closing=false,status='idle'}
    local function valid(t)return adapter.valid(t.native)==true end
    local function retain(image)
        local size=M.validate(image)
        assert(store.bytes+size<=M.max_retained_bytes,'retained texture budget exhausted; restart required')
        -- Reserve first: failed native uploads can still have queued GPU work.
        store.bytes=store.bytes+size
        local record={bytes=size};store.resources[#store.resources+1]=record
        adapter.upload(image,record)
        assert(record.resource,'upload did not return an owned resource')
        return record
    end
    function self.register(id,native,original)
        assert(not self.closing and type(id)=='string' and id~='' and not self.targets[id],'invalid target')
        assert(not store.claims[id],'target still owned by another instance')
        M.validate(original);if adapter.validate_image then adapter.validate_image(native,original)end
        assert(adapter.valid(native)==true,'target identity unavailable')
        self.targets[id]={native=native,original_image=snapshot(original),width=original.width,height=original.height}
        store.claims[id]=self
        return true
    end
    function self.swap(id,image)
        assert(not self.closing,'texture manager retiring')
        local t=assert(self.targets[id],'unknown texture target');M.validate(image)
        assert(image.width==t.width and image.height==t.height,'replacement dimensions differ')
        if adapter.validate_image then adapter.validate_image(t.native,image)end
        if t.active and not t.restore and t.current_image and t.current_image.rgba==image.rgba then
            t.file=image.path or t.file;return true
        end
        t.pending=snapshot(image);t.restore=false;return true -- Coalesce before allocation.
    end
    function self.restore(id)
        local t=assert(self.targets[id],'unknown texture target');t.pending=nil;t.restore=true;return true
    end
    function self.reload_files()
        for id,t in pairs(self.targets) do
            if t.file then self.swap(id,M.read_image(t.file,t.width,t.height)) end
        end
        return true
    end
    function self.close()
        self.closing=true
        for _,t in pairs(self.targets)do t.pending=nil;t.restore=true end
    end
    function self.step()
        assert(adapter.in_render_phase()==true,'texture work requires render bridge')
        local complete=true
        for id,t in pairs(self.targets)do
            local ok,err=pcall(function()
                if not t.pending and not t.job and not (t.restore and t.active) then t.restore=false;return end
                if not valid(t) then
                    -- Retired units cannot be restored through stale pointers.
                    t.pending=nil;t.job=nil;t.restore=false;t.active=false;t.retired=true
                elseif t.restore then
                    t.job=nil
                    if t.active then
                        adapter.bind(t.native,assert(t.original).resource)
                        t.active=false;t.current_image=nil;self.status='original pixels restored; visible result requires verification'
                    end
                    t.restore=false
                else
                    if t.pending then
                        local image=t.pending;t.pending=nil;t.job=nil
                        assert(store.bytes+M.validate(image)+(t.original and 0 or M.validate(t.original_image))<=M.max_retained_bytes,'retained texture budget exhausted; restart required')
                        if not t.original then t.original=retain(t.original_image) end
                        t.job={candidate=retain(image),image=image}
                    end
                    local job=t.job
                    if job and adapter.ready(t.original)==true and adapter.ready(job.candidate)==true then
                        -- Both transfer commands were consumed before publication.
                        -- Mark before binding: refresh may fail after set_resource.
                        t.active=true;t.candidate=job.candidate;t.file=job.image.path;t.job=nil
                        adapter.bind(t.native,job.candidate.resource)
                        t.current_image=job.image
                        self.status='submitted; visible result requires verification'
                    elseif job then self.status='waiting for texture transfer acknowledgment' end
                end
            end)
            if not ok then
                self.status=tostring(err)
                if t.active then t.restore=true end
            end
            if self.closing then
                if t.active or t.restore then complete=false
                elseif store.claims[id]==self then store.claims[id]=nil end
            end
        end
        return self.closing and complete
    end
    function self.stats()return {retained_bytes=store.bytes,retained_resources=#store.resources,status=self.status}end
    return self
end
return M
