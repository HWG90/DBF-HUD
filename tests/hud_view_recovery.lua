-- One-shot recovery uses actual HUD geometry and the existing panel pose path.
HUD={}
for _,name in ipairs(assert(DBF_BUNDLE_MODULES))do
 if name~='bundled_defaults'then HUD[name]=assert(loadfile('src/'..name..'.lua'))()end
end
local Placement=HUD.placement;local Scene=HUD.screen_scene
local key='968211c0033dce64';local other='1111111111111111'
local function close(a,b)assert(math.abs(a-b)<1e-6,tostring(a)..' ~= '..tostring(b))end
local function copy(t)
 if type(t)~='table'then return t end
 local out={};for k,v in pairs(t)do out[k]=copy(v)end;return out
end
local function same(a,b)
 if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
 for k,v in pairs(a)do if not same(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end;return true
end
-- Construct rigid camera/weapon axes from independent heading/elevation/roll.
local function matrix(heading,elevation,roll,x,y,z)
 local h,p,r=math.rad(heading),math.rad(elevation),math.rad(roll)
 local right={math.cos(h),-math.sin(h),0}
 local forward={math.sin(h)*math.cos(p),math.cos(h)*math.cos(p),math.sin(p)}
 local up={-math.sin(h)*math.sin(p),-math.cos(h)*math.sin(p),math.cos(p)}
 local m={0,0,0,0,forward[1],forward[2],forward[3],0,0,0,0,0,x,y,z,1}
 for i=1,3 do m[i]=right[i]*math.cos(r)+up[i]*math.sin(r);m[i+8]=up[i]*math.cos(r)-right[i]*math.sin(r)end
 return m
end
local function model()return {resource_hex=key,kind='magazine',value=46,capacity=45,reserve=6,reserve_kind='MAGS',fire_mode='AUTO',fraction=1,state='READY',chamber_bonus=1}end
local function commands(cfg)
 return assert(HUD.ballistic_family.compose(model(),0,0,2*cfg.scale,1,cfg,function()return true end,function()return true end))
end
local function check_visible(p,settings,cfg,offset,camera,fov,aspect)
 local self={weapon_pose=copy(p),first_person=p.first_person,config=settings,clock=0,weapon_clearance={[key]={[p.first_person and'first_right'or'right']=offset}}}
 self.weapon_pose.attach_point='root'
 Placement.update(self,{}, {},{avatar_unit_ref=1},function()end)
 local updated=copy(cfg);updated.scale=settings.scale*offset.scale*(p.first_person and 1 or settings.third_person_scale)
 updated.panel_rotation=offset.rotation;updated.panel_pitch=offset.pitch;updated.panel_yaw=offset.yaw
 local prepared=HUD.world_style.prepare(commands(updated),self.weapon_pose,updated)
 local axes,at=Scene.panel_pose(self.weapon_pose,updated,prepared)
 for _,column in ipairs({1,5,9})do for i=0,2 do close(axes[column+i],camera[column+i])end end
 local tested=0
 local function point(x,y)
  local wx,wy,wz=Scene.point(axes,at,x,y)
  local projected=assert(HUD.projection.project(camera,wx,wy,wz,fov,aspect,.005),'Recovery corner is outside the viewport')
  assert(projected.x>=.08 and projected.x<=.92 and projected.y>=.08 and projected.y<=.92,'Recovery corner missed its safe viewport margin')
  tested=tested+1
 end
 for _,v in ipairs(prepared)do
  if v.quad then for _,q in ipairs(v.quad)do point(q[1],q[2])end
  elseif v.type=='text'then
   local a,b,c,d=HUD.font.measure(v.text,v.size,v.font,true)
   point(v.x+a,v.y+b);point(v.x+c,v.y+d)
  elseif v.w and v.h then
   point(v.x,v.y);point(v.x+v.w,v.y);point(v.x+v.w,v.y+v.h);point(v.x,v.y+v.h)
  end
 end
 assert(tested>40)
 -- The correction is fixed in weapon coordinates, not reevaluated per frame.
 local before=copy(offset)
 self.weapon_pose.x=self.weapon_pose.x+.25;self.weapon_pose.matrix[13]=self.weapon_pose.x
 local _,moved=Scene.panel_pose(self.weapon_pose,updated,prepared)
 close(moved.x-at.x,.25);assert(same(offset,before))
end
local cases=0
for _,first in ipairs({false,true})do for _,global_scale in ipairs({.5,1,2})do
 for _,rotation in ipairs({{0,0,0},{90,0,0},{-70,-60,45},{35,80,-130},{0,90,0},{0,-90,0}})do
  for _,fov in ipairs({.16,.7,1.4})do for _,aspect in ipairs({16/9,.75})do
   local settings=HUD.config.new();settings.anchor_mode='world';settings.placement_mode='auto';settings.fp_auto_side='right'
   settings.scale=global_scale;settings.hud_presentation='weapon_specific';settings.third_person_scale=.75
   local camera=matrix(0,0,0,12,24,3)
   local root=matrix(rotation[1],rotation[2],rotation[3],12.2,23.8,2.9)
   local p={matrix=root,x=root[13],y=root[14],z=root[15],resource_hex=key,id=1,candidate=1,first_person=first,attach_point='node:4d25685a',sight={matrix=matrix(120,20,60,12,24,3),x=.5,y=.2,z=.3}}
   assert(not HUD.projection.project(camera,p.x,p.y,p.z,fov,aspect,.005),'Fixture should begin behind the camera')
   local cfg=copy(settings);cfg.presentation_view='first';cfg.scale=global_scale*3*(first and 1 or settings.third_person_scale)
   cfg.decoration='helldivers';cfg.keep_hud_upright=false
   cfg.shader_layers={{id=1,shader='crt_scan',scale=1,strength=2,blend=1,enabled=true,opacity=.37,pattern_size=.25}}
   local cfg_before=copy(cfg);local p_before=copy(p)
   local recovered,offset=pcall(Placement.recover,p,cfg,commands(cfg),camera,fov,aspect,settings,3)
   assert(recovered,tostring(offset)..' first='..tostring(first)..' global='..global_scale..' rotation='..table.concat(rotation,',')..' fov='..fov..' aspect='..aspect)
   assert(same(cfg,cfg_before)and same(p,p_before),'Recovery changed appearance or sampled pose')
   assert(offset.attach_point=='root'and offset.scale>=.05 and offset.scale<=3)
   check_visible(p,settings,cfg,offset,camera,fov,aspect);cases=cases+1
  end end
 end
end end
-- A rolled camera, tilted weapon, and the optional upright base use the same solve.
do
 local settings=HUD.config.new();settings.anchor_mode='world';settings.placement_mode='auto';settings.scale=1
 local camera=matrix(40,-25,20,10,20,30)
 local root=matrix(-60,50,110,10.2,19.8,29.9)
 local p={matrix=root,x=root[13],y=root[14],z=root[15],first_person=false,resource_hex=key}
 local cfg=copy(settings);cfg.presentation_view='first';cfg.scale=settings.third_person_scale;cfg.keep_hud_upright=true
 local offset=Placement.recover(p,cfg,commands(cfg),camera,1.1,16/9,settings,1)
 check_visible(p,settings,cfg,offset,camera,1.1,16/9);cases=cases+1
end

-- Preview/save retain other weapons, other views, appearance, and settings.
local settings=HUD.config.new();settings.anchor_mode='world';settings.placement_mode='auto'
local baseline={[key]={right={x=1.8,rotation=170,scale=3,attach_point='node:4d25685a'},first_right={x=.31,scale=1.2}},[other]={right={z=.4,rotation=22}}}
local h={clock=0,config=settings,first_person=false,weapon_pose={resource_hex=key},weapon_clearance=copy(baseline)}
local saved,writes=nil,0
h.layout_editor=HUD.layout_editor.new(h,{write_weapon_offsets=function(body)saved=assert(loadstring(body))();writes=writes+1 end},function()end)
local config_before=copy(settings)
local offset={x=.1,y=.2,z=.3,rotation=25,pitch=-30,yaw=15,scale=.6,attach_point='root'}
assert(Placement.apply_recovery(h,offset)and h.layout_editor.active and writes==0)
assert(h.weapon_clearance[key].right==offset and same(h.weapon_clearance[key].first_right,baseline[key].first_right))
assert(same(h.weapon_clearance[other],baseline[other])and same(settings,config_before))
assert(h.layout_editor.save()and writes==1 and same(saved[key].first_right,baseline[key].first_right)and same(saved[other],baseline[other]))
assert(h.layout_editor.reset()and same(h.weapon_clearance,baseline))
-- Invalid/missing cameras fail before changing a profile or settings.
assert(not pcall(Placement.recover,{matrix=matrix(0,0,0,0,0,0)},settings,{},nil,1,1,settings,1))

-- Native Placement recovery is directly accessible without fetching appearance.
local recoveries=0
local ui={clock=0,config=HUD.config.new(),bring_hud_into_view=function()recoveries=recoveries+1;return true,'F7 saves, F8 restores'end}
ui.configure=function()error('Recovery control altered global settings')end;ui.save_tuning=function()error('Recovery control wrote settings')end
local old_mcm=rawget(_G,'DBFMCM');local registered
_G.DBFMCM={register=function(spec)registered=spec;return{unregister=function()end}end}
ui.fetch_weapon_appearance=function()error('Recovery required Fetch')end
local native_menu=HUD.menu.new(ui);native_menu.poll()
local placement_page
for _,page in ipairs(registered.pages)do if page.id=='placement'then placement_page=page end end
assert(placement_page and placement_page.name=='Placement'and placement_page.require_confirmation==false)
local recovery_control
for _,control in ipairs(placement_page.controls)do if control.id=='bring_hud_into_view'then recovery_control=control end end
assert(recovery_control and recovery_control.type=='button'and recovery_control.on_activate()=='F7 saves, F8 restores'and recoveries==1)
native_menu.retire();_G.DBFMCM=old_mcm
print('PASS HUD recovery: '..cases..' actual viewport/facing cases including diving and gimbal angles; one-shot following, isolated preview/save/restore, and direct native Placement button without Fetch')
