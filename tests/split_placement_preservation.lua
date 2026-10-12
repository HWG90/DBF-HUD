-- Execute the production reset/configure/save method bodies without native
-- rendering setup. This regression must never write or discard placement.
HUD={native_font_data=dofile('src/native_font_data.lua'),bundled_defaults=dofile('src/bundled_defaults.lua')}
HUD.config=dofile('src/config.lua');HUD.shader_layers=dofile('src/shader_layers.lua');HUD.weapon_offsets=dofile('src/weapon_offsets.lua')
local function copy(t)if type(t)~='table'then return t end;local q={};for k,v in pairs(t)do q[k]=copy(v)end;return q end
local function same(a,b)
 if type(a)~=type(b)then return false end;if type(a)~='table'then return a==b end
 for k,v in pairs(a)do if not same(v,b[k])then return false end end
 for k in pairs(b)do if a[k]==nil then return false end end;return true
end
local file=assert(io.open('src/runtime.lua','rb'));local source=file:read('*a');file:close()
local function method(name,next_name)
 local first=assert(source:find('    function self.'..name..'(',1,true),'Production method missing: '..name)
 local ending=assert(source:find('    function self.'..next_name..'(',first+1,true),'Following production method missing: '..next_name)
 return source:sub(first,ending-1)
end
local install=assert(loadstring('return function(self,backend,HUD,log,menu)\n'..
 method('configure','appearance_weapon')..method('use_split_defaults','save_tuning')..method('save_tuning','reload_tuning')..
 '\nreturn self.use_split_defaults\nend','@production_split_reset_methods'))()
local resource='968211c0033dce64'
for _,active in ipairs({false,true})do
 local cfg=HUD.config.new();cfg.texture_art_variant='faithful';cfg.decoration='helldivers';cfg.font='bigblue'
 cfg.weapon_panels={[resource]={font='bigblue',texture_art_variant='faithful'}}
 local placement={scale=1.6,third_person_scale=.9,mount_x=.27,mount_y=-.17,mount_z=.045,
  fp_mount_x=.03,fp_mount_y=.06,fp_mount_z=-.02,left_mount_x=.4,left_mount_y=-.08,left_mount_z=.1,
  fp_auto_side='right',offset_x=94,offset_y=-31,weapon_offset_x=38,weapon_offset_y=21,keep_hud_upright=true}
 HUD.config.apply(cfg,placement)
 local profiles=copy(HUD.bundled_defaults.layouts)
 profiles[resource]={right={x=.333,y=-.041,z=.117,rotation=12,pitch=-5,yaw=23,scale=.83,attach_point='root'},first_right={x=.046,y=.21,z=-.02,rotation=-9,scale=1.31,attach_point='node:527c9c73'}}
 local mounts={right={x=.29,y=.10,z=.17},first={x=.043,y=.31,z=-.024}}
 local editor={active=active,resource=resource,view='first_right',snapshot=copy(profiles),status='user placement preview'}
 local self={config=cfg,weapon_clearance=profiles,auto_mounts=mounts,layout_editor=editor,appearance_revision=19}
 local before_profiles,before_mounts,before_editor=copy(profiles),copy(mounts),copy(editor)
 local writes,offset_writes,syncs,logs=0,0,0,{}
 local backend={write_weapon_offsets=function()offset_writes=offset_writes+1;error('Appearance reset attempted to write weapon offsets')end,
  write_tuning=function(body)
   writes=writes+1
   local load=assert(loadstring(body));setfenv(load,{})
   local persisted=HUD.config.new();HUD.config.apply(persisted,load(),true)
   assert(persisted.texture_art_variant=='split'and persisted.font=='hack'and persisted.decoration=='split')
   -- Native automatic mount fields are transient and deliberately excluded
   -- from tuning serialization; those are checked on the live object below.
   for key,value in pairs(placement)do if not key:find('mount_',1,true)then assert(persisted[key]==value,'Appearance reset changed persisted placement: '..key)end end
   return 'memory tuning'
  end}
 local menu={sync=function()syncs=syncs+1 end}
 local reset=install(self,backend,HUD,function(line)logs[#logs+1]=line end,menu)
 self.export_tuning=function()return HUD.config.serialize(self.config)end
 local ok,message=reset();assert(ok,message)
 assert(writes==1 and offset_writes==0,'Appearance reset wrote placement or failed to save tuning')
 assert(self.weapon_clearance==profiles and same(profiles,before_profiles),'Appearance reset replaced or mutated weapon profiles')
 assert(self.auto_mounts==mounts and same(mounts,before_mounts),'Appearance reset replaced or mutated the mount cache')
 assert(self.layout_editor==editor and same(editor,before_editor),'Appearance reset altered the active editor/snapshot')
 for key,value in pairs(placement)do assert(self.config[key]==value,'Appearance reset changed live placement: '..key)end
 assert(self.config.texture_art_variant=='split'and self.config.font=='hack'and self.config.decoration=='split'and next(self.config.weapon_panels)==nil)
 assert(syncs==1 and self.appearance_revision==20,'Appearance reset did not refresh its normal config/menu revision')
end
print('PASS Split appearance reset: actual production methods preserve all weapon profiles, cached mounts, editor state and global placement/scale; tuning saved once and weapon-offset writer never called')
