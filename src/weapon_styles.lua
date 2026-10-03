-- Catalog panel presentation only. Counts, modes, heat and charge remain reader-owned.
local M={catalog={
    ['006e44327bb953fe']={name='GL-15 Evictor',family='explosive',detail='standard'},
    ['02cd7321cd8445f5']={name='Verified auxiliary grenade entity on the equipped rifle.',family='explosive',detail='standard'},
    ['02eecd0b1fa49630']={name='GL-21 Grenade Launcher',family='explosive',detail='standard'},
    ['03e67a19b07c6523']={name='R-63 Diligence',family='precision',detail='standard'},
    ['05d8d8c073b9d502']={name='SG-8P Punisher Plasma',family='plasma',detail='standard'},
    ['05e4e5c2db6e44a2']={name='P-2 Peacemaker',family='sidearm',detail='standard'},
    ['07419ebc09a1a7c5']={name='railgun',family='laser',detail='standard'},
    ['076dd5d4f4360204']={name='ARC-12 Blitzer',family='arc',detail='standard'},
    ['0807aea5217e4767']={name='SMG-72 Pummeler',family='compact',detail='concussive'},
    ['0b882808c6f498e8']={name='P-35 Re-Educator',family='dart',detail='standard'},
    ['0c197bbd8d2c725b']={name='assault_rifle_penetrator',family='rifle',detail='penetrator'},
    ['0f83639ab8c86165']={name='R-2 Amendment',family='precision',detail='standard'},
    ['11c27d3babb38956']={name='machinegun',model='MG-43',family='belt',detail='standard'},
    ['11ec8e2296a3d662']={name='pump_shotgun_02',family='shotgun',detail='standard'},
    ['14d5d4506056c7a4']={name='P-33 Missile Pistol',family='rocket',detail='standard'},
    ['16051937941bb709']={name='smg_rhino',family='compact',detail='standard'},
    ['186ea95de7306b1a']={name='SMG-203 Gallant',family='compact',detail='standard'},
    ['1a437158e1b8d2a1']={name='P-113 Verdict',family='sidearm',detail='standard'},
    ['1abbff60d26ba391']={name='R/40-K Hot-Shot Marksman Rifle',family='precision',detail='standard'},
    ['2152d5147b0ac418']={name='heavy_mg',family='rifle',detail='standard'},
    ['2383b0439f0bc465']={name='assault_rifle_rico',family='rifle',detail='standard'},
    ['25aa2fd4643cf4ee']={name='FAF-14 Spear',family='rocket',detail='standard'},
    ['26df5aa208ce216e']={name='railgun',family='laser',detail='standard'},
    ['26e40437ea275296']={name='RL-77 Airburst Rocket Launcher',family='rocket',detail='standard'},
    ['27ee1ed8f6fb6356']={name='LAS-5 Scythe',family='laser',detail='standard'},
    ['295beb26dc4f8ff1']={name='LAS-17 Double-Edge Sickle',family='laser',detail='standard'},
    ['2b28e17ffed05f7c']={name='SG-22 Bushwhacker',family='shotgun',detail='standard'},
    ['2df1cfb9ed77e06c']={name='marksman_rifle',family='precision',detail='standard'},
    ['2e9d0bdc48b09e60']={name='RS-422 Railgun',family='laser',detail='standard'},
    ['30061f91af477f5e']={name='PLAS-39 Accelerator Rifle',family='plasma',detail='standard'},
    ['3575aabc5f1f9326']={name='P-19 Redeemer',family='sidearm',detail='standard'},
    ['35a61296619cc47e']={name='LAS-99 Quasar Cannon',family='laser',detail='standard'},
    ['3828e2051aa9e897']={name='S-11 Speargun',family='dart',detail='standard'},
    ['39ab99895147a3bf']={name='FLAM-40 Flamethrower',family='fuel',detail='standard'},
    ['3c86e871923f3970']={name='LAS-13 Trident',family='laser',detail='standard'},
    ['3f92ba65ef65cca9']={name='P-72 Crisper',family='fuel',detail='standard'},
    ['416d053372c4e433']={name='LAS-58 Talon',family='laser',detail='standard'},
    ['41eac4a03987faa0']={name='SG-8 Punisher',family='shotgun',detail='standard'},
    ['43a58cb89cfa197c']={name='M-1000 Maxigun',family='belt',detail='standard'},
    ['43b2d7766120203b']={name='chemgun',family='rifle',detail='standard'},
    ['43cb1033961a2276']={name='AR-23P Liberator Penetrator',family='precision',detail='penetrator'},
    ['46183b50961d1328']={name='SG-225 Breaker',family='shotgun',detail='standard'},
    ['46427f2630a80d88']={name='faf_missile_launcher_helghast',family='rocket',detail='standard'},
    ['4ba41b6f9f405cc2']={name='StA-11 SMG',family='compact',detail='standard'},
    ['4c786785c79d44e7']={name='R-63CS Diligence Counter Sniper',family='precision',detail='standard'},
    ['4d58c77087b774c5']={name='M6C/SOCOM Pistol',family='sidearm',detail='standard'},
    ['4dbd74f49c8ffc13']={name='MA5C Assault Rifle',family='rifle',detail='standard'},
    ['4e310b1fe4c52b52']={name='SG-20 Halt',family='shotgun',detail='concussive'},
    ['4e4a613eb9bf5c24']={name='personal_defense_weapon',family='rifle',detail='standard'},
    ['4f749e2ee26f532d']={name='SG-8S Slugger',family='shotgun',detail='standard'},
    ['4fb0f8c02f55c82b']={name='FLAM-66 Torcher',family='fuel',detail='standard'},
    ['52071f49263415e4']={name='SG-88 Break-Action Shotgun',family='shotgun',detail='standard'},
    ['52cdbfbaca3cb397']={name='CQC-30 Stun Baton',family='tool',detail='standard'},
    ['52e4334e6a128caf']={name='Grenade Pistol',family='explosive',detail='standard'},
    ['53eebe75cd6e26df']={name='pump_shotgun_slug',family='shotgun',detail='standard'},
    ['5990123d142b16cb']={name='MLS-4X Commando',family='rocket',detail='standard'},
    ['5ebaea70c0d060b9']={name='SG-225SP Breaker Spray&Pray',family='shotgun',detail='standard'},
    ['5f3ec9bda2bd8553']={name='CQC-20 Breaching Hammer',family='tool',detail='standard'},
    ['5fecab819f96a3e8']={name='BR-14 Adjudicator',family='precision',detail='standard'},
    ['6228d0242bde56b6']={name='assault_shotgun_sprayandpray',family='shotgun',detail='standard'},
    ['644d748f359de03e']={name='railgun',family='laser',detail='standard'},
    ['692eb345969d368e']={name='lat_oneshot',family='rocket',detail='standard'},
    ['6cfcc7f8801a0266']={name='40-K Meltagun',family='plasma',detail='standard'},
    ['6dfa768b4e2401a7']={name='railgun',family='laser',detail='standard'},
    ['6e68194b95d60145']={name='marksman_rifle_vigilance_counter_sniper',family='precision',detail='standard'},
    ['708ea298c82093d0']={name='AR-59 Suppressor',family='precision',detail='standard'},
    ['719f42b7d137789c']={name='jet_rifle_phoenix',family='rifle',detail='standard'},
    ['72170a55a1f37ff1']={name='DBS-2 Double Freedom',family='shotgun',detail='standard'},
    ['75816077c139c850']={name='CQC-5 Combat Hatchet',family='tool',detail='standard'},
    ['7617642765ac38c7']={name='EAT-411 Leveller',family='rocket',detail='standard'},
    ['78a8185f63a70795']={name='heavy_flamethrower',family='fuel',detail='standard'},
    ['7b75e5132ffd4ca6']={name='R-2124 Constitution',family='precision',detail='standard'},
    ['7c47244d3b030884']={name='railgun',family='laser',detail='standard'},
    ['7e3145a5baa4b948']={name='laser_rifle_charge',family='laser',detail='standard'},
    ['8039834a4b7489b9']={name='assault_rifle_penetrator',family='rifle',detail='penetrator'},
    ['80932fa0ed6901d3']={name='lat_oneshot',family='rocket',detail='standard'},
    ['80f1a156d9fa1e36']={name='JAR-5 Dominator',family='precision',detail='standard'},
    ['84354339522c932d']={name='AR-2 Coyote',family='precision',detail='incendiary'},
    ['8645f167b3c813a2']={name='LAS-16 Sickle',family='laser',detail='standard'},
    ['8666e5f49f440d44']={name='faf_missile_launcher',family='rocket',detail='standard'},
    ['88c2d09ad85a7c9f']={name='GL-28 Belt-Fed Grenade Launcher',family='explosive',detail='standard'},
    ['88f61afff48ac8a4']={name='TX-41 Sterilizer',family='fuel',detail='standard'},
    ['89c5493e08ca4207']={name='APW-1 Anti-Materiel Rifle',family='laser',detail='standard'},
    ['8a307bd1811a5fe9']={name='SMG/FLAM-34 Stoker',family='fuel',detail='standard'},
    ['8a35c1dc19f41870']={name='bolt_action_rifle',family='precision',detail='standard'},
    ['8d3d52a3b2f19402']={name='P-4 Senator',family='sidearm',detail='standard'},
    ['8dc91f277c6096ee']={name='jet_rifle_phoenix',family='rifle',detail='standard'},
    ['90ddc374f4e3d756']={name='M90A Shotgun',family='shotgun',detail='standard'},
    ['945f7e132049b514']={name='railgun',family='laser',detail='standard'},
    ['94bd931b5fb4ee95']={name='SMG-32 Reprimand',family='compact',detail='standard'},
    ['9571ca51f0daf35b']={name='MP-98 Knight',family='compact',detail='standard'},
    ['968211c0033dce64']={name='AR-23 Liberator',family='precision',detail='standard'},
    ['96de9cd50f7306e6']={name='ARC-3 Arc Thrower',family='arc',detail='standard'},
    ['9b0a7b78126c2fec']={name='missile_launcher',family='rocket',detail='standard'},
    ['9b75217d8312dd67']={name='B/MD C4 Pack',family='tool',detail='standard'},
    ['9eb160830321bfd6']={name='GP-20 Ultimatum',family='explosive',detail='standard'},
    ['9f80d67a12a7e40f']={name='GR-8 Recoilless Rifle',family='rocket',detail='standard'},
    ['a6a735accb4a327f']={name='M-105 Stalwart',family='belt',detail='standard'},
    ['a7ee1ebf58fcdf1f']={name='AR-23A Liberator Carbine',family='precision',detail='standard'},
    ['a8a91eb54892b6b2']={name='AR-11 Arbitrator',family='precision',detail='standard'},
    ['a8cffb316f0b5c5f']={name='AC-8 Autocannon',family='explosive',detail='standard'},
    ['a955c4ea6f6d4203']={name='AR/GL-21 One-Two',family='explosive',detail='standard'},
    ['a9e574cd953d3b3a']={name='faf_missile_helghast',family='rocket',detail='standard'},
    ['aa69a60d74a3ec54']={name='PLAS-15 Loyalist',family='plasma',detail='standard'},
    ['ab2a2b390c539f18']={name='assault_rifle_explosive',family='rifle',detail='standard'},
    ['b0f1b354ba1d38d8']={name='CQC-1 One True Flag',family='tool',detail='standard'},
    ['b16c9d490aa59b77']={name='MGX-42 Bullet Storm',family='belt',detail='standard'},
    ['b2b5e0d185605f9e']={name='EAT-700 Expendable Napalm',family='rocket',detail='incendiary'},
    ['b6aff2195568767f']={name='R-36 Eruptor',family='precision',detail='standard'},
    ['bc29613666df696b']={name='AR-32 Pacifier',family='precision',detail='concussive'},
    ['bcc2177439d231be']={name='pump_shotgun',family='shotgun',detail='standard'},
    ['be70ee0d8d44028e']={name='M7S SMG',family='compact',detail='standard'},
    ['bf4cfd2aeabfb5a4']={name='CQC-9 Defoliation Tool',family='tool',detail='standard'},
    ['bf9504e95c0103a1']={name='battle_rifle_ceremonial',family='precision',detail='standard'},
    ['bfe35746f5084222']={name='assault_rifle_karbin',family='rifle',detail='standard'},
    ['c0a9ee8ce12f682a']={name='railgun',family='laser',detail='standard'},
    ['c12a34f375bd5a87']={name='SG-225IE Breaker Incendiary',family='shotgun',detail='incendiary'},
    ['c4232a0e62166d91']={name='personal_defense_weapon_pepper',family='rifle',detail='standard'},
    ['c780bcd79547da0f']={name='P-69 Veto',family='sidearm',detail='standard'},
    ['c85f576d5e086147']={name='LAS-12 Sai',family='laser',detail='standard'},
    ['cc786f6491fe7e65']={name='StA-X3 W.A.S.P. Launcher',family='rocket',detail='standard'},
    ['cdf28be026bb7d84']={name='StA-52 Assault Rifle',family='rifle',detail='standard'},
    ['cdf733b0106a23c3']={name='assault_shotgun_incendiary',family='shotgun',detail='incendiary'},
    ['ce063aa33d95a812']={name='AR-61 Tenderizer',family='precision',detail='standard'},
    ['cf5f176e0e322be1']={name='AR-23C Liberator Concussive',family='precision',detail='concussive'},
    ['cf8934ff6567a42d']={name='P-92 Warrant',family='sidearm',detail='standard'},
    ['d323de60855898ac']={name='SG-451 Cookout',family='shotgun',detail='incendiary'},
    ['d54b9505c0f72873']={name='LAS-98 Laser Cannon',family='laser',detail='standard'},
    ['d6b1fb05b9109353']={name='P-11 Stim Pistol',family='medical',detail='standard'},
    ['dbb6c961c59fadc1']={name='P/40-K Bolt Pistol',family='sidearm',detail='standard'},
    ['dcd1c835407ef7ba']={name='SG-97 Sweeper',family='shotgun',detail='standard'},
    ['de18775fa447a9bf']={name='MS-11 Solo Silo',family='rocket',detail='standard'},
    ['df8decb6b6538265']={name='railgun',family='laser',detail='standard'},
    ['e3b6aedd07fcb464']={name='CQC-19 Stun Lance',family='tool',detail='standard'},
    ['e5796355a8fd67e0']={name='R-4 Hyena',family='precision',detail='standard'},
    ['e6d932be83729076']={name='R-6 Deadeye',family='precision',detail='standard'},
    ['e8d5f49ad7780e54']={name='PLAS-45 Epoch',family='plasma',detail='standard'},
    ['e8ffad77b73c221c']={name='railgun',family='laser',detail='standard'},
    ['e91f569c2ad8af01']={name='P-34 Breacher',family='sidearm',detail='standard'},
    ['eea5e3cef1e12c14']={name='PLAS-1 Scorcher',family='plasma',detail='standard'},
    ['efdcef306cea63fe']={name='plasma_rifle_charge',family='plasma',detail='standard'},
    ['f0338468dcdb6a6c']={name='R-72 Censor',family='precision',detail='standard'},
    ['f49227a0630a3f7f']={name='CB-9 Exploding Crossbow',family='dart',detail='standard'},
    ['f992ce97577c8a7f']={name='VG-70 Variable',family='rifle',detail='standard'},
    ['fb3a19078694708a']={name='PLAS-101 Purifier',family='plasma',detail='standard'},
    ['fcd8a6e67eac635a']={name='CQC-2 Saber',family='tool',detail='standard'},
    ['fe3b29b2cfa63f9b']={name='GL-52 De-Escalator',family='explosive',detail='standard'},
    ['ffc18b2ce10ca381']={name='battle_rifle',family='precision',detail='standard'},
}}
local palettes={
 rifle={{23,31,28},{171,190,170},{213,183,109}},
 precision={{22,29,34},{185,203,213},{209,165,82}},
 sidearm={{29,30,34},{192,202,211},{200,165,112}},
 compact={{24,33,35},{161,193,202},{181,206,213}},
 belt={{28,32,28},{160,184,151},{218,172,78}},
 shotgun={{21,30,39},{139,183,221},{65,145,235}},
 explosive={{29,34,27},{184,197,156},{229,179,68}},
 rocket={{25,31,30},{161,192,181},{224,180,95}},
 laser={{18,31,35},{135,202,215},{74,222,231}},
 plasma={{25,25,39},{174,158,221},{157,121,241}},
 arc={{21,28,38},{144,181,220},{92,185,255}},
 fuel={{34,27,22},{210,183,143},{241,155,61}},
 dart={{24,31,32},{163,200,194},{118,206,185}},
 tool={{28,30,32},{173,184,192},{227,193,82}},
 medical={{20,35,31},{170,211,192},{92,226,153}},
}
-- Specialized live gauges and indicators keep their data arrangement within the new themes.
local retained={['5f3ec9bda2bd8553']=true,['14d5d4506056c7a4']=true,['4dbd74f49c8ffc13']=true}

local icons={rifle='RIFLE_SEMI',precision='AMR_CARTRIDGE',sidearm='SIDEARM_CARTRIDGE',compact='SIDEARM_CARTRIDGE',
 belt='LINKED_BELT',shotgun='SHELL',explosive='GRENADE_PISTOL_SHELL',rocket='MISSILE_SIDE',
 laser='ENERGY_CELL',plasma='PLASMA',arc='ARC_EMBLEM',fuel='FUEL',dart='DART',tool='TOOL_BLADE',medical='STIM_DART'}
local function double_breech(frame,m,scale,cfg,opacity,measure,decorate)
 local icon=HUD.munition_art.icon(M.catalog[m.resource_hex],m,nil)
 local left=frame.x+frame.w/2-icon.w*scale/2;local bottom=frame.y
 local out={{type='panel',double_breech=true,breech_scale=1.12,weapon_theme='shotgun',x=left,y=bottom-17*scale,w=icon.w*scale,h=(icon.h+59)*scale,c={34,42,47},a=cfg.panel_opacity*opacity,frosted=cfg.frosted}}
 local f=out[1];local edge={119,143,153}
 for _,r in ipairs({{f.x,f.y,f.w,scale},{f.x,f.y+f.h-scale,f.w,scale},{f.x,f.y,scale,f.h},{f.x+f.w-scale,f.y,scale,f.h}}) do
  out[#out+1]={type='rect',x=r[1],y=r[2],w=r[3],h=r[4],c=edge,a=opacity*.8,double_breech=true}
 end
 -- MG-43 material weight with a recessed ammunition bay.
  local function hardware(x,y,w,h,c,a)
   out[#out+1]={type='rect',double_breech=true,x=left+x*scale,y=bottom+y*scale,w=w*scale,h=h*scale,c=c,a=opacity*(a or 1)}
  end
  out[1].c={24,29,33}
  hardware(9,43,132,97,{9,15,18},.9)
  hardware(9,43,132,.6,{103,117,125},.45)
  hardware(9,139.4,132,.6,{103,117,125},.45)
  hardware(9,43,.6,97,{103,117,125},.45)
  hardware(140.4,43,.6,97,{103,117,125},.45)
  hardware(3,-14,144,.6,{105,119,128},.45)
  hardware(3,148,144,.6,{105,119,128},.45)
  hardware(3,-14,.6,162,{64,78,88},.65)
  hardware(146.4,-14,.6,162,{64,78,88},.65)
  for _,x in ipairs({5,140}) do for _,y in ipairs({-11,142}) do
   hardware(x,y,4,4,{12,19,24})
   hardware(x+1,y+1.6,2,.5,{139,151,156},.65)
  end end
  -- Short clamps support the shell artwork without competing full-height rails.
  for _,x in ipairs({9,134}) do
   hardware(x,49,7,9,{49,61,70})
   hardware(x+1,55,5,.6,{137,150,157},.55)
   hardware(x,124,7,9,{49,61,70})
   hardware(x+1,130,5,.6,{137,150,157},.55)
  end
  hardware(18,38,114,.6,{108,121,129},.45)
  hardware(19,28,112,.5,{104,116,124},.25)
  hardware(12,145,7,1,{184,145,78},.6)
  hardware(131,145,7,1,{184,145,78},.6)
  for _,run in ipairs(icon.runs) do
  out[#out+1]={type='rect',double_breech=true,catalog_heading=true,x=left+run[1]*scale,y=bottom+(32+run[2])*scale,w=run[3]*scale,h=run[4]*scale,c=run[5],a=opacity}
  if run.quad then local q={};for i,p in ipairs(run.quad) do q[i]={left+p[1]*scale,bottom+(32+p[2])*scale} end;out[#out].quad=q end
 end
 local function label(text,y,size)
  local a,b,e,t=0,0,#text*size*.6,size
  if measure then a,b,e,t=measure(text,size) end
  out[#out+1]={type='text',text=text,font=cfg.font,size=size,x=left+icon.w*scale/2-(a+e)/2,y=y,c={201,207,209},a=opacity,numeric_display=false,center_in_frame=true}
 end
 label(m.reserve~=nil and string.format('%03d SHELLS',math.max(0,m.reserve)) or '--- SHELLS',bottom+9*scale,12*scale)
 label(m.fire_mode or 'SEMI',bottom-9*scale,10*scale)
 decorate(out,out[1],scale,cfg,opacity)
  return out
end
function M.apply(out,m,scale,cfg,opacity,measure,decorate,clock)
 local style=M.catalog[m.resource_hex]
 if not style then return out end
 -- Restore the preceding fuel/gas gauge; telemetry and warning zones stay in layout.lua.
 if m.label=='FUEL' or m.label=='GAS' then return out end
 if HUD.shared_suite and (HUD.shared_suite.enabled or cfg.shared_suite_preview==true) and HUD.shared_suite.eligible(m.resource_hex) then return HUD.shared_suite.compose(out,m,scale,cfg,opacity,style,measure,decorate) end
 if m.resource_hex=='72170a55a1f37ff1' then out[1].weapon_theme='shotgun';return out end -- Original compact HUD and its shared child boxes.
 if m.resource_hex=='9f80d67a12a7e40f' and m.capacity==1 then return HUD.recoilless_panel.compose(out[1],m,scale,cfg,opacity,measure) end
 if m.resource_hex=='3828e2051aa9e897' and m.capacity==1 then return HUD.speargun_panel.compose(out[1],m,scale,cfg,opacity,measure) end
 if m.resource_hex=='6cfcc7f8801a0266' then return HUD.melta_panel.compose(out[1],m,scale,cfg,opacity,measure) end
 if m.resource_hex=='e6d932be83729076' or m.resource_hex=='89c5493e08ca4207' or m.resource_hex=='52e4334e6a128caf' or m.resource_hex=='2e9d0bdc48b09e60' then
   out[1].weapon_theme=style.family;return out -- Accepted bespoke displays live in layout.lua.
 end
 local palette=palettes[style.family]
 local frame=out[1];if not frame or frame.type~='panel' then return out end
 frame.weapon_theme=style.family
 local kept={}
 local main_top=-math.huge
 local special=retained[m.resource_hex] or m.kind=='heat' or m.label=='FUEL' or m.label=='GAS'
 for _,v in ipairs(out) do
   if v.type=='text' and v.size>=20*scale and not v.child and not v.heat_label then
     local b,t=-v.size*.2,v.size*.8
     if measure then local a,bb,e,tt=measure(v.text,v.size);if tt then b,t=bb,tt end end
     main_top=math.max(main_top,v.y+t)
   end
 end
 local relocate=not special and main_top>-math.huge
 for _,v in ipairs(out) do
   if relocate and v.mode_icon then -- Retire the old side icon; the header owns the only projectile.
   elseif not (relocate and v.ammo_heading and not m.ammo_mode and (m.chamber_bonus~=1 or m.resource_hex=='11c27d3babb38956')) and not (relocate and v.decoration and not v.child) then
     if v.type=='panel' and not v.charge_meter then v.c=palette[1]
     elseif v.decoration then v.c=palette[2]
     elseif not special and v.type=='rect' and v.center_bar and not (v.fuel_group or v.heat_vertical or v.heat_detail or v.barrel_indicator) then v.c=palette[3] end
     kept[#kept+1]=v
   end
 end
 out=kept
 if relocate then
   local icon=HUD.fire_icons[m.energy_icon or m.ammo_icon]
   if style.family=='tool' then
     local name=style.name:lower()
     local key=name:find('hatchet',1,true) and 'TOOL_HATCHET' or name:find('flag',1,true) and 'TOOL_FLAG' or name:find('c4',1,true) and 'TOOL_PACK' or name:find('stun',1,true) and 'TOOL_BATON' or 'TOOL_BLADE'
     icon=HUD.fire_icons[key]
   elseif style.family=='medical' then icon=HUD.fire_icons.STIM_DART end
   if m.resource_hex=='2e9d0bdc48b09e60' then icon=HUD.fire_icons.RAILGUN_DISPLAY
   elseif m.resource_hex=='89c5493e08ca4207' or m.resource_hex=='e6d932be83729076' then icon=HUD.fire_icons.AMR_CARTRIDGE end
   if not icon or icon==HUD.fire_icons.BULLET or icon==HUD.fire_icons.SEMI or icon==HUD.fire_icons.AUTO or icon==HUD.fire_icons.BURST then
     local name=icons[style.family]
     if (style.family=='rifle' or style.family=='precision') and m.fire_mode=='AUTO' then name='RIFLE_AUTO'
     elseif (style.family=='rifle' or style.family=='precision') and m.fire_mode=='BURST' then name='RIFLE_AUTO' end
     icon=HUD.fire_icons[name]
   end
   if not m.ammo_mode and not m.safety_mode then icon=HUD.munition_art.icon(style,m,icon) end
   icon=HUD.munition_art.autocannon_icon(m,icon)
   if icon then
     local side_row=m.resource_hex=='11c27d3babb38956'
     local il,ib,ir,it=math.huge,math.huge,-math.huge,-math.huge
     for _,r in ipairs(icon.runs) do il=math.min(il,r[1]);ib=math.min(ib,r[2]);ir=math.max(ir,r[1]+r[3]);it=math.max(it,r[2]+r[4]) end
     local enhanced=HUD.catalog_housing.eligible(m.resource_hex)
     local header_height=enhanced and ((style.family=='belt' or m.fire_mode=='AUTO' or m.fire_mode=='BURST') and 46 or 40) or ((style.family=='belt' or m.fire_mode=='AUTO' or m.fire_mode=='BURST') and 28 or 18)
     local double=m.resource_hex=='72170a55a1f37ff1'
     if double then header_height=64 end
     local factor=math.min(header_height*scale/(it-ib),(frame.w-(double and 22 or enhanced and 42 or 24)*scale)/(ir-il))
     local py=main_top+4*scale
     -- Preserve programmable-ammunition labels in their existing heading band.
     if m.ammo_mode or m.chamber_bonus==1 then py=frame.y+frame.h+3*scale end
     local px=frame.x+frame.w/2-(il+ir)*factor/2
     py=py-ib*factor
     if side_row then
       for _,v in ipairs(out) do if v.type=='text' and v.size>=20*scale and not v.child then
         local a,b,e,t=0,-v.size*.2,#v.text*v.size*.6,v.size*.8
         if measure then local aa,bb,ee,tt=measure(v.text,v.size);if tt then a,b,e,t=aa,bb,ee,tt end end
         local iw=(ir-il)*factor;local gap=4*scale;local needed=e-a+gap+iw+24*scale
         if frame.w<needed then frame.x=frame.x-(needed-frame.w)/2;frame.w=needed end
         local start=frame.x+(frame.w-(e-a+gap+iw))/2
         v.x=start-a;v.center_in_frame=nil;v.mode_count=true;v.mode_gap=4*scale
         px=start+e-a+gap-il*factor;py=v.y+(b+t-(it-ib)*factor)/2-ib*factor
         break
       end end
     end
     frame.h=math.max(frame.h,py+it*factor+8*scale-frame.y)
     for _,r in ipairs(icon.runs) do
       local color=r[5] or palette[3]
       if icon==HUD.fire_icons.SHELL or icon==HUD.fire_icons.DOUBLE_SHELL or icon==HUD.fire_icons.TRIPLE_SHELL then color=r[2]<9 and {218,172,78} or {65,145,235} end
       out[#out+1]={type='rect',catalog_heading=not side_row,catalog_side_icon=side_row,mode_icon=side_row,railgun_heading=m.safety_mode~=nil,x=px+r[1]*factor,y=py+r[2]*factor,w=r[3]*factor,h=r[4]*factor,c=color,a=opacity*(r[6] or 1)}
     end
     if m.safety_mode=='UNSAFE' then
       local phase=math.floor((clock or 0)*12)%3
       local function arc(dx,dy,w,h)
         out[#out+1]={type='rect',railgun_heading=true,railgun_arc=true,catalog_heading_effect=true,x=px+dx*factor,y=py+dy*factor,w=w*factor,h=h*factor,c={196,244,255},a=opacity*.7}
       end
       for _,edge in ipairs({il-2,ir+1}) do
         arc(edge,ib+2+phase,1,3);arc(edge-1,ib+4+phase,2,.5)
       end
       arc(il+4,it+1,5,.5);arc(il+8,it+.5+phase*.2,.5,1)
     end
     local designation=style.model or style.name:match('^([A-Z][A-Z0-9/%-%.]+) ')
     if designation then
       local size=(side_row and 12 or 7)*scale;local left,bottom,right,top=0,-size*.2,#designation*size*.6,size*.8
       if measure then local a,b,c,d=measure(designation,size);if d then left,bottom,right,top=a,b,c,d end end
       local base=(side_row and main_top or py+it*factor)+3*scale-bottom
       out[#out+1]={type='text',catalog_caption=true,text=designation,font=cfg.font,size=size,
         x=frame.x+frame.w/2-(left+right)/2,y=base,c=palette[2],a=opacity*.8}
       frame.h=math.max(frame.h,base+top+5*scale-frame.y)
     end
     if not side_row then for _,v in ipairs(out) do if v.mode_count then v.mode_count=nil;v.mode_gap=nil;v.center_in_frame=true end end end
   end
   decorate(out,frame,scale,cfg,opacity)
   for _,v in ipairs(out) do if v.decoration and not v.child then v.c=palette[2] end end
 end
 -- Family details indicate physical design, not invented live readings.
 local function mark(dx,dy,w,h,color)
   out[#out+1]={type='rect',catalog_detail=true,x=frame.x+dx*scale,y=frame.y+dy*scale,w=w*scale,h=h*scale,c=color or palette[3],a=.7*opacity}
 end
 local width,height=frame.w/scale,frame.h/scale
 if style.family=='laser' or style.family=='plasma' or style.family=='arc' then
   for _,edge in ipairs({3,width-4}) do for k=0,2 do mark(edge,height-6-k*3,1,2) end end
 elseif style.family=='belt' or style.family=='fuel' or style.family=='explosive' or style.family=='rocket' then
   for k=0,2 do mark(3+k*3,height-4,1.5,1) end
 else
   mark(3,height-4,4,.7);mark(width-7,height-4,4,.7)
   mark(3,height-7,.7,2);mark(width-4,height-7,.7,2)
 end
 -- Recessed mounting screws and a keyed inner corner make this an instrument housing.
 for _,dx in ipairs({3,width-5}) do
   mark(dx,3,2,2,{49,60,65});mark(dx+.5,3.8,1,.4,{174,193,201})
 end
 for _,dx in ipairs({6,width-12}) do mark(dx,height-3,6,.4,palette[2]) end
 if style.family=='precision' then
   for k=0,3 do mark(width-4,9+k*3,1,k%2==0 and 1.5 or .7,palette[2]) end
 elseif style.family=='shotgun' then
   mark(3,height-10,2,4,{65,145,235});mark(width-5,height-10,2,4,{218,172,78})
 elseif style.family=='rocket' or style.family=='explosive' then
   for k=0,2 do mark(width-11+k*2,height-6,1,2,{242,183,54}) end
 end
 if style.detail=='incendiary' then mark(width-7,3,3,1,{249,132,51})
 elseif style.detail=='penetrator' then mark(width-7,3,3,1,{220,230,237});mark(width-6,5,1,2,{220,230,237})
 elseif style.detail=='concussive' then mark(width-7,3,3,1,{124,201,232});mark(width-7,5,3,1,{124,201,232}) end
 if m.mg43_flash and m.resource_hex=='11c27d3babb38956' then
   -- Replace visible content only; telemetry continues updating underneath.
   local elapsed=math.max(0,(clock or 0)-(m.mg43_flash_start or clock or 0))
   local pop=1+.12*math.exp(-elapsed*18)
   local size=26*scale*pop
   local a,b,c,d=0,-size*.2,11*size*.6,size*.8
   if measure then local aa,bb,cc,dd=measure('GET SOME!!!',size);if dd then a,b,c,d=aa,bb,cc,dd end end
   size=size*math.min(1,(frame.w-20*scale)/(c-a),(frame.h-24*scale)/(d-b))
   if measure then a,b,c,d=measure('GET SOME!!!',size) else a,b,c,d=0,-size*.2,11*size*.6,size*.8 end
   local phase=math.floor(elapsed/.12)%3
   local flash_colors={{255,221,0},{255,255,255},{255,174,48}}
   local tx=frame.x+frame.w/2-(a+c)/2
   local ty=frame.y+frame.h/2-(b+d)/2+scale*math.exp(-elapsed*18)
   out={frame,
     {type='text',text='GET SOME!!!',font=cfg.font,size=size,x=tx+scale,y=ty-scale,c={12,16,19},a=opacity*.9,mg43_shadow=true},
     {type='text',text='GET SOME!!!',font=cfg.font,size=size,x=tx,y=ty,c=flash_colors[phase+1],a=opacity,mg43_easter=true}}
   local inset=(4+2*math.exp(-elapsed*14))*scale
   local function accent(x,y,w,h)
     out[#out+1]={type='rect',x=x,y=y,w=w,h=h,c={255,204,64},a=opacity*.8,mg43_accent=true}
   end
   for _,right in ipairs({false,true}) do
     local edge=right and frame.x+frame.w-inset or frame.x+inset
     local x=right and edge-6*scale or edge
     accent(right and edge-scale or edge,frame.y+inset,scale,frame.h-2*inset)
     accent(x,frame.y+inset,6*scale,scale)
     accent(x,frame.y+frame.h-inset-scale,6*scale,scale)
     for k=0,2 do
       local w=(6-k)*scale
       accent(frame.x+frame.w/2-w/2+(k-1)*3*scale,frame.y+inset+(k+2)*2*scale,w,.6*scale)
     end
   end
   decorate(out,frame,scale,cfg,opacity)
 end
 out=HUD.catalog_housing.apply(out,m,scale,cfg,opacity,style,icons[style.family],measure)
 return out
end
return M
