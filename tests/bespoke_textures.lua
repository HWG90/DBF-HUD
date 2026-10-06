HUD={}
for _,name in ipairs({'native_font_data','native_font_uv','native_font','config','font','motion','ammo_types','model','fire_icons','munition_art','mg_easter','df_shell_state','recoilless_state','senator_state','senator_panel','melta_panel','speargun_panel','recoilless_panel','catalog_housing','sta11_panel','weapon_styles','layout','world_style','texture_art','texture_art_assets','bespoke_texture_specs','bespoke_texture_panel','runtime'}) do HUD[name]=assert(loadfile('src/'..name..'.lua'))() end
local cfg=HUD.config.new();cfg.anchor_mode='world';cfg.font='bigblue';cfg.texture_art_variant='study'
local measure=function(t,size,font)return HUD.font.measure(t,size,font or cfg.font,true) end
local total=0
for resource,spec in pairs(HUD.bespoke_texture_specs) do
 for _,s in ipairs({.05,.25,1,4}) do
  for _,state in ipairs({'empty','normal','full','unknown'}) do
   local m={resource_hex=resource,value=state=='unknown' and nil or state=='empty' and 0 or state=='normal' and 3 or 30,capacity=state=='unknown' and nil or 30,reserve=state=='unknown' and nil or 4,compass_heading=state=='unknown' and nil or 359.9,warning=state=='empty',label='ROUNDS',kind='magazine'}
   if state=='unknown' then m.value=nil;m.capacity=nil;m.reserve=nil;m.compass_heading=nil end
   local fallback={{type='panel',x=12,y=15,w=124*s,h=110*s,c={255,255,255},a=1}}
   assert(HUD.bespoke_texture_panel.compose(fallback,m,12,15,s,1,cfg,0,measure,function()return false end)==fallback)
   local out=HUD.bespoke_texture_panel.compose(fallback,m,12,15,s,1,cfg,0,measure,function()return true end)
   assert(out~=fallback and out[2].type=='texture' and out[1].w==spec.w*s)
   local count_text,compass
   local function bounds(commands)
    for _,v in ipairs(commands)do if v.texture_readout then
     local a,b,e,f=measure(v.text,v.size,v.font);local z=v.readout_zone
     assert(v.x+a>=z.cx-z.w/2-1e-5 and v.x+e<=z.cx+z.w/2+1e-5,v.readout_key..' horizontal')
     assert(v.y+b>=z.cy-z.h/2-1e-5 and v.y+f<=z.cy+z.h/2+1e-5,v.readout_key..' vertical')
     if v.readout_key=='count' then count_text=v end
     if v.readout_key=='compass' then compass=v.text end
    end end
   end
   bounds(out)
   assert(count_text and count_text.text==(state=='unknown' and '---' or string.format(spec.key=='m7s' and '%03d' or '%02d',m.value)))
   if spec.zones.compass then assert(compass==(state=='unknown' and 'BRG ---' or 'BRG 000')) end
   HUD.runtime.rebase_commands(out,12,15)
   local world=HUD.world_style.prepare(out,{first_person=false},cfg);bounds(world)
   total=total+1
  end
 end
end
local resource='be70ee0d8d44028e';local m={resource_hex=resource,value=31,capacity=30,reserve=3,chamber_bonus=1}
local out=HUD.bespoke_texture_panel.compose({{type='panel',x=0,y=0,w=100,h=100}},m,0,0,1,1,cfg,0,measure,function()return true end)
for _,v in ipairs(out)do if v.readout_key=='count' then assert(v.text=='031' and v.last_digit_color[1]==255)end end
cfg.anchor_mode='screen';local fallback={{type='panel'}}
assert(HUD.bespoke_texture_panel.compose(fallback,m,0,0,1,1,cfg,0,measure,function()return true end)==fallback)
print('PASS '..total..' true-region state/scale layouts, world rebase/refit, unavailable fallback, bearing unknown, chamber plus-one')
