HUD={}
HUD.native_font_data=dofile('src/native_font_data.lua');HUD.native_font=dofile('src/native_font.lua');HUD.font=dofile('src/font.lua');HUD.config=dofile('src/config.lua');HUD.shader_layers=dofile('src/shader_layers.lua')
local M=dofile('src/df_media_panel.lua');local C=HUD.config.new()
for _,value in ipairs({0,1,2})do
 local out=M.compose({value=value,reserve=34,fire_mode='SEMI'},0,0,1,1,C,HUD.font.measure,true)
 assert(out[1].w==128 and out[1].h==96 and #out<600)
 local texts=0;for _,v in ipairs(out)do assert(v.x==v.x and v.y==v.y);assert(v.type~='texture','Lua version uploaded a texture');if v.type=='text'then texts=texts+1;assert(v.text~='0'and v.text~='1'and v.text~='2','loaded-round number duplicated')end end
 assert(texts==4)
end
local df='72170a55a1f37ff1';HUD.config.set_panel(C,df,{texture_art_trial=true})
HUD.config.apply(C,{force_all_hud_texture_off=true});assert(HUD.config.effective(C,df).texture_art_trial==false)
HUD.config.apply(C,{force_all_hud_texture_off=false});assert(HUD.config.effective(C,df).texture_art_trial==true)
local restored=assert(loadstring(HUD.config.serialize(C)))();local copy=HUD.config.new();HUD.config.apply(copy,restored);assert(copy.force_all_hud_texture_off==false and copy.appearance_follow_equipped==true)
print('PASS Lua DF geometry/count bounds, two chamber states, no texture upload or duplicated counts, global override priority and persistence')
