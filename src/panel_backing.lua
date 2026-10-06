-- Separate a white alpha backing mask from untouched artwork pixels.
-- The caller owns live readout composition and texture-off primitive fallback.
local M={}
local function unit(v,default)
    if type(v)~='number' or v~=v then return default end
    return math.max(0,math.min(1,v))
end
function M.ready(spec,resource)
    return spec and spec.backing and spec.foreground and type(resource)=='function'
        and resource(spec.backing.resource)~=nil and resource(spec.foreground.resource)~=nil
end
function M.compose(spec,x,y,s,opacity,cfg,resource)
    cfg=HUD.config.texture_policy(cfg)
    if cfg.texture_art_trial==false or cfg.texture_art_variant=='original' or not M.ready(spec,resource) then return nil end
    assert(spec.dynamic_text_removed==true,'Separated artwork still contains baked live readouts')
    local w,h=spec.logical_size[1],spec.logical_size[2]
    assert(type(w)=='number' and type(h)=='number' and w>0 and h>0,'Invalid backing bounds')
    local out={{type='panel',x=x,y=y,w=w*s,h=h*s,a=0,c={0,0,0},frosted=false,atlas_frame=true,world_reference_width=spec.reference_width or w*s}}
    local function image(layer,color,alpha,order)
        out[#out+1]={type='texture',x=x,y=y,w=w*s,h=h*s,c=color,a=opacity*alpha,
            texture_resource=layer.resource,texture_material=spec.material,atlas_rect=layer.uv,
            texture_theme=false,texture_layer=order,isolated_backing=order==49}
    end
    image(spec.backing,HUD.config.rgb(cfg.background_color or '#202628'),unit(cfg.panel_opacity,.8),49)
    image(spec.foreground,{255,255,255},1,49.1)
    return out
end
return M
