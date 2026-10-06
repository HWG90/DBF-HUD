HUD={};for _,name in ipairs(DBF_BUNDLE_MODULES)do if name~='bundled_defaults'then HUD[name]=dofile('src/'..name..'.lua')end end
local C=HUD.compass
assert(C.heading({[5]=0,[6]=1})==0 and C.heading({[5]=1,[6]=0})==90)
assert(C.heading({[5]=0,[6]=-1})==180 and C.heading({[5]=-1,[6]=0})==270)
assert(C.heading({[5]=0,[6]=0})==nil and C.ticks(0/0)==nil)
local a=C.ticks(359);local b=C.ticks(0);assert(#a>=12 and #b>=12)
local cfg=HUD.config.new();local out=HUD.df_retro_panel.primitive({value=2,reserve=48,fire_mode='SEMI',compass_heading=90},0,0,1,1,cfg)
local shells={};local reserve={}
for _,v in ipairs(out)do
 if v.shell_side and v.type=='rect' then
  local bounds=shells[v.shell_side]or{math.huge,math.huge,-math.huge,-math.huge};shells[v.shell_side]=bounds
  bounds[1]=math.min(bounds[1],v.x);bounds[2]=math.min(bounds[2],v.y);bounds[3]=math.max(bounds[3],v.x+v.w);bounds[4]=math.max(bounds[4],v.y+v.h)
 end
 if v.center_x and not v.shell_side then local l,_,r=HUD.font.measure(v.text,v.size,v.font,true);assert(math.abs(v.x+(l+r)/2-64)<1e-6 or v.text=='N' or v.text=='NE' or v.text=='E' or v.text=='SE' or v.text=='S')end
 if v.reserve_part then reserve[#reserve+1]=v end
end
for side=1,2 do local b=shells[side];assert(math.abs(b[3]-b[1]-43.2)<1e-6 and math.abs(b[4]-b[2]-88)<1e-6)end
assert(#reserve==3);local minx,maxx=math.huge,-math.huge
for _,v in ipairs(reserve)do local l,_,r=HUD.font.measure(v.text,v.size,v.font,true);minx=math.min(minx,v.x+l);maxx=math.max(maxx,v.x+r)end
assert(math.abs((minx+maxx)/2-64)<1e-6,'reserve group is not centered')
print('PASS camera compass cardinal/wrap/unknown handling, Lua shell dimensions and actual font-bound header/reserve centering')
