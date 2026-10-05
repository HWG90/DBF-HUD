-- Optional static artwork replacement. Invalid/unavailable groups retain primitives.
local M={}
local function finite(n)return type(n)=='number' and n==n and math.abs(n)<math.huge end
function M.prepare(commands,resource,available,registry,variant)
    local spec=registry and registry[resource]
    if not spec or spec.version~=1 or type(spec.layers)~='table' then return commands end
    local selected=spec.variants and spec.variants[variant or 'faithful']
    if spec.variants and not selected then return commands end
    local groups={};local materials={}
    for index,base in ipairs(spec.layers)do
        local layer={};for k,v in pairs(base)do layer[k]=v end
        if selected then
            local assets=selected[layer.id];if not assets then return commands end
            layer.material,layer.texture=assets.material,assets.texture
        end
        if type(layer.id)~='string' or type(layer.material)~='string' or type(layer.texture)~='string' or groups[layer.id] or materials[layer.material] then return commands end
        materials[layer.material]=true
        if not available('material',layer.material) or not available('texture',layer.texture) then return commands end
        groups[layer.id]={spec=layer,index=index,members={},minx=math.huge,miny=math.huge,maxx=-math.huge,maxy=-math.huge}
    end
    for i,v in ipairs(commands)do
        local g=groups[v.texture_art_layer]
        if g then
            -- Text, panels, meters, effects and state-driven art must never be tagged.
            if v.type~='rect' or v.texture_art_static~=true or v.fold_child or v.child or v.quad or v.heat_fill or v.charge_meter or v.effect_shader_band or v.scanline_layer or v.fuel_marker_piece then return commands end
            if not finite(v.x) or not finite(v.y) or not finite(v.w) or not finite(v.h) or v.w<=0 or v.h<=0 then return commands end
            if not finite(v.texture_art_opacity) or v.texture_art_opacity<0 or v.texture_art_opacity>1 then return commands end
            if g.opacity and g.opacity~=v.texture_art_opacity then return commands end
            g.opacity=v.texture_art_opacity;g.members[#g.members+1]=i
            if v.texture_art_box then
                local b=v.texture_art_box
                if not finite(b.x) or not finite(b.y) or not finite(b.w) or not finite(b.h) or b.w<=0 or b.h<=0 then return commands end
                if g.box and (g.box.x~=b.x or g.box.y~=b.y or g.box.w~=b.w or g.box.h~=b.h) then return commands end
                g.box=b
            end
            g.minx=math.min(g.minx,v.x);g.miny=math.min(g.miny,v.y);g.maxx=math.max(g.maxx,v.x+v.w);g.maxy=math.max(g.maxy,v.y+v.h)
        end
    end
    local replacements,removed={},{}
    for _,g in pairs(groups)do
        if #g.members==0 or #g.members~=g.spec.command_count then return commands end
        if g.box then
            local b=g.box
            if g.minx<b.x-1e-6 or g.miny<b.y-1e-6 or g.maxx>b.x+b.w+1e-6 or g.maxy>b.y+b.h+1e-6 then return commands end
            g.minx,g.miny,g.maxx,g.maxy=b.x,b.y,b.x+b.w,b.y+b.h
        end
        local bounds=g.spec.aspect
        if not finite(bounds) or bounds<=0 or math.abs((g.maxx-g.minx)/(g.maxy-g.miny)-bounds)>1e-5 then return commands end
        replacements[g.members[1]]={type='texture',x=g.minx,y=g.miny,w=g.maxx-g.minx,h=g.maxy-g.miny,c={255,255,255},a=g.opacity,
            texture_material=g.spec.material,texture_resource=g.spec.texture,texture_art_layer=g.spec.id,texture_layer=49+g.index*.01}
        for _,i in ipairs(g.members)do removed[i]=true end
    end
    local out={}
    for i,v in ipairs(commands)do if replacements[i] then out[#out+1]=replacements[i] elseif not removed[i] then out[#out+1]=v end end
    return out
end
return M

