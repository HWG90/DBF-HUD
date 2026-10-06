HUD={};HUD.native_font_data=dofile('src/native_font_data.lua');HUD.config=dofile('src/config.lua')
local M=dofile('src/panel_backing.lua');local cfg=HUD.config.new()
local spec={dynamic_text_removed=true,logical_size={128,264},material='existing',backing={resource='backing'},foreground={resource='foreground'}}
local resource=function()return 'ready'end
local serialized=HUD.config.serialize(cfg)
for _,alpha in ipairs({0,.25,1})do
 cfg.panel_opacity=alpha;cfg.background_color='#204060'
 local out=M.compose(spec,0,0,1,.7,cfg,resource)
 assert(#out==3 and out[2].a==.7*alpha and out[3].a==.7)
 assert(out[2].c[1]==32 and out[2].c[2]==64 and out[2].c[3]==96)
 assert(out[3].c[1]==255 and out[3].c[2]==255 and out[3].c[3]==255)
 assert(out[2].texture_resource=='backing' and out[3].texture_resource=='foreground')
end
cfg.force_all_hud_texture_off=true;assert(M.compose(spec,0,0,1,1,cfg,resource)==nil)
cfg.force_all_hud_texture_off=false;assert(M.compose(spec,0,0,1,1,cfg,function()return nil end)==nil)
spec.dynamic_text_removed=false;assert(not pcall(M.compose,spec,0,0,1,1,cfg,resource))
assert(cfg.texture_art_trial==true,'render policy altered saved artwork choice')
print('PASS isolated backing color/alpha, intact foreground, global force-off, missing asset fallback and baked-readout rejection')
