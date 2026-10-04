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
-- Reach-style lateral weapon readout, retaining the ODST suppressed SOCOM identity.
local function socom_panel(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local ice,blue,dim={216,233,242},{122,177,208},{65,94,111}
 local w,h=150,96
 local function extent(t,size)
  if measure then local a,b,e,f=measure(t,size*scale);if e then return a/scale,b/scale,e/scale,f/scale end end
  return 0,-size*.2,#t*size*.6,size*.8
 end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'MAGS') or ('--- '..(m.reserve_kind or 'MAGS'))
 local ra,rb,re,rf=extent(reserve,10);w=math.max(w,re-ra+24)
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c=HUD.config.rgb(cfg.background_color),a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted,weapon_theme='sidearm',socom_reach=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,socom_reach=true,socom_detail=tag}
 end
 local function label(t,dx,dy,size,c,numeric)
  local a,b,e,f=extent(t,size)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(dx-a)*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,socom_reach=true}
 end
 -- Lateral hierarchy mirrors Reach's weapon/ammunition cluster instead of a stacked receiver plaque.
 label('M6C/SOCOM',11,80,9,blue,false)
 local sx=w-60
 for _,r in ipairs({{0,70,27,3},{27,69,18,5},{3,73,2,2},{22,73,2,2},{4,60,7,10},{10,64,9,1},{18,65,1,5},{6,59,5,1}}) do
  part(sx+r[1],r[2],r[3],r[4],blue,.85,'suppressed-silhouette')
 end
 part(sx+29,70,14,.6,ice,.7,'suppressor-seam')
 label(string.format('%03d',tonumber(m.value) or 0),11,39,36,m.warning and {245,174,91} or ice,true)
 -- Ammunition sits BESIDE the number in a two-rank strip, like a helmet HUD weapon cluster.
 local cap=tonumber(m.capacity)
 if cap and cap>0 and cap<=24 then
  cap=math.floor(cap);local columns=math.min(6,cap);local gx=w-61
  for i=0,cap-1 do
   local loaded=i<(tonumber(m.value) or 0)
   local dx=gx+(i%columns)*7;local dy=43-math.floor(i/columns)*10
   for step=0,3 do part(dx+step*.55,dy+step*2,2.8,2,loaded and blue or dim,loaded and .95 or .24,'ammo-tile') end
   out[#out].socom_round_slot=i+1;out[#out].socom_round_loaded=loaded
  end
 end
 -- Open visor chamfer ties the large count to the magazine cluster; reserve remains subordinate.
 part(12,26,w-28,.7,blue,.7,'reach-sill')
 for side=0,1 do for step=0,5 do
  part(side==0 and 11-step*.8 or w-16+step*.8,26+step*.9,1.2,.9,blue,.75,'visor-shoulder')
 end end
 part(5,36,.7,33,dim,.5,'visor-side');part(w-5,36,.7,23,dim,.5,'visor-side')
 label(reserve,12,9,10,ice,false)
 part(w-29,12,15,.6,dim,.6,'reserve-rule')
 for step=0,3 do part(w-15+step,12+step,1,.8,dim,.6,'reserve-terminal') end
 decorate(out,frame,scale,cfg,opacity)
 -- Existing mode-child output survives intact, with the same attachment and telemetry.
 for _,v in ipairs(previous) do if v.child then out[#out+1]=v end end
 return out
end
local liberator_titles={
 ['968211c0033dce64']='AR-23 LIBERATOR',
 ['43cb1033961a2276']='AR-23P PENETRATOR',
 ['cf5f176e0e322be1']='AR-23C CONCUSSIVE',
 ['a7ee1ebf58fcdf1f']='AR-23A CARBINE',
}
-- AR-23 standard-issue receiver instrument; magazine/round values remain reader-owned.
local function liberator_panel(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local mg=m.resource_hex=='11c27d3babb38956'
 local title=mg and 'MG-43 MACHINE GUN' or liberator_titles[m.resource_hex]
 local yellow,steel,white,graphite={244,211,31},{141,159,169},{224,231,231},{25,32,36}
 local w,h=124,110
 local function extent(t,size)
  if measure then local a,b,e,f=measure(t,size*scale);if e then return a/scale,b/scale,e/scale,f/scale end end
  return 0,-size*.2,#t*size*.6,size*.8
 end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'MAGS') or ('--- '..(m.reserve_kind or 'MAGS'))
 for _,t in ipairs({reserve,title}) do local a,b,e,f=extent(t,10);w=math.max(w,e-a+24) end
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c={5,13,35},a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted,weapon_theme='rifle',liberator_issue=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,liberator_issue=true,liberator_detail=tag}
 end
 local function label(t,dy,size,c,numeric)
  local a,b,e,f=extent(t,size)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w-a-e)/2*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,center_in_frame=true,liberator_issue=true}
 end
 -- Supplied Helldiver skull silhouette, merged pixel runs; drawn beneath instruments.
 local skull_runs={{21,0,2,1},{18,1,8,1},{15,2,14,1},{12,3,20,1},{9,4,26,1},{6,5,32,1},{4,6,36,2},{5,8,34,14},{5,22,5,1},{15,22,14,1},{34,22,5,1},{6,23,3,1},{16,23,12,2},{35,23,3,1},{5,24,3,1},{36,24,3,1},{4,25,4,1},{17,25,10,4},{36,25,4,1},{3,26,5,1},{36,26,5,1},{2,27,6,1},{36,27,6,1},{1,28,7,1},{36,28,7,1},{0,29,9,1},{16,29,12,1},{35,29,9,1},{1,30,9,1},{15,30,14,1},{34,30,9,1},{2,31,40,1},{2,32,19,1},{23,32,19,1},{3,33,17,1},{24,33,17,1},{4,34,16,1},{24,34,16,1},{5,35,14,1},{25,35,14,1},{6,36,14,1},{21,36,2,1},{24,36,14,1},{7,37,2,1},{13,37,18,4},{35,37,2,1},{14,41,16,2},{15,43,14,1},{17,44,10,1},{21,45,2,1}}
 for _,r in ipairs(skull_runs) do part((w-70)/2+r[1]*70/44,(mg and 31 or 23)+(46-r[2]-r[4])*72/46,r[3]*70/44,r[4]*72/46,yellow,mg and .075 or .105,'skull-watermark') end
 -- The weapon's yellow receiver stencil sits on a recessed graphite designation plate.
 part(7,91,w-14,14,graphite,cfg.panel_opacity*.65,'designation-plate')
 part(8,103,w-16,1.6,yellow,.9,'designation-stripe')
 label(title,93,10,yellow,false)
 -- Linked brass cartridges identify MG-43; no weapon silhouettes.
 if mg then
  local pitch=10;local start=(w-68)/2
  part(start+2,81,64,1,steel,.55,'belt-link')
  for i=0,6 do
   local dx=start+i*pitch
   part(dx+1,77,5,8,{191,152,69},.7,'belt-cartridge')
   part(dx+2,85,3,2,steel,.8,'belt-cartridge-tip')
   part(dx,77,7,1,yellow,.75,'belt-cartridge-base')
   part(dx,81,1,3,steel,.65,'belt-link')
  end
 else
  -- Restore the machined side accents around the cartridge bay.
  for _,dx in ipairs({7,w-17}) do for i=0,3 do part(dx+i*2.4,77,1.2,8,steel,.48,'receiver-rib') end end
  -- User-supplied 5.5 x 50 design context; stylized proportions, no inferred dimensional drawing.
  -- All profile steps are symmetric about local y=6: parallel-sided case body, bottleneck, narrow neck.
  local cx=(w-66)/2
  local ink,shadow,brass,bright={48,34,18},{132,79,21},{225,163,38},{255,220,104}
  local steel,steelshade,shine={184,201,215},{90,114,139},{237,247,255}
  local tip,tiplight=steel,shine
  if m.resource_hex=='43cb1033961a2276' then tip={49,139,66};tiplight={111,203,113}
  elseif m.resource_hex=='cf5f176e0e322be1' then tip={22,25,29};tiplight={58,65,72} end
  local pixels={
   {0,1,3,10,ink},{1,2,2,8,brass},{1,8,2,2,bright},{1,2,2,2,shadow},
   -- Flush base with recessed extractor groove, never wider than the case body.
   {3,3,2,6,shadow},{3,4,1,4,ink},
   -- One straight case body with parallel top/bottom edges; only the shoulder narrows.
   {4,1,38,10,ink},{4,2,38,8,brass},{5,8,37,2,bright},{5,2,37,2,shadow},
   {6,3,2,5,shadow},{8,3,2,5,bright},{11,3,2,5,shadow},
   -- Clearly sloping bottleneck shoulder, ending at a narrow straight neck.
   {42,2,2,8,brass},{42,8,2,2,bright},{42,2,2,2,shadow},
   {44,3,2,6,brass},{44,8,2,1,bright},{44,3,2,1,shadow},
   {46,4,6,4,brass},{46,7,6,1,bright},{46,4,6,1,shadow},
   -- Silver projectile stays centered and narrower than the body of the case.
   {52,4,5,4,steel},{52,7,5,1,shine},{52,4,5,1,steelshade},
   {57,4.5,3,3,steel},{57,6.5,3,1,shine},{57,4.5,3,1,steelshade},
   {60,5,3,2,tip},{60,6,3,1,tiplight},{63,5.5,3,1,tiplight},
   -- Four small internal pixel details; silhouette and bounding box remain identical.
   {16,7,2,1,brass},
   {47,5,1,1,shadow},{53,5.5,3,1,shine},
  }
  for _,r in ipairs(pixels) do
   part(cx+r[1],75+r[2],r[3],r[4],r[5],1,'rifle-round-pixel')
  end

 end
 -- Recessed count window is the primary instrument; physical details remain peripheral.
 part(7,34,w-14,39,{10,16,20},cfg.panel_opacity*.4,'count-recess')
 part(7,73,w-14,.7,steel,.5,'count-seam')
 label(string.format('%03d',tonumber(m.value) or 0),39,36,m.warning and {245,174,91} or white,true)
 -- Exact per-round inspection grid through 60; larger magazines use a labeled percentage gauge.
 local cap=m.capacity
 local valid=type(cap)=='number' and cap==cap and cap>=1 and cap<=100000 and cap%1==0
 if valid and cap<=60 then
  local columns=math.min(15,cap);local pitch=math.min(5.5,(w-26)/columns);local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,cap-1 do
   local loaded=i<(tonumber(m.value) or 0)
   part((w-gridw)/2+(i%columns)*pitch,27-math.floor(i/columns)*3,cw,1.8,loaded and yellow or steel,loaded and .85 or .2,'round-index')
   out[#out].liberator_round_slot=i+1;out[#out].liberator_round_loaded=loaded
  end
 elseif valid then
  local fraction=math.max(0,math.min(1,(tonumber(m.value) or 0)/cap))
  local columns,pitch=15,5.5;local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,columns-1 do
   local dx=(w-gridw)/2+i*pitch
   part(dx,25,cw,3,steel,.2,'capacity-gauge-background')
   local fill=math.max(0,math.min(1,fraction*columns-i))
   if fill>0 then part(dx,25,cw*fill,3,yellow,.85,'capacity-gauge-fill');out[#out].liberator_fraction=fill end
  end
  label(string.format(mg and 'BELT %03d%%' or 'MAG %03d%%',math.floor(fraction*100+.5)),18,6,steel,false)
 else
  label('MAG --',23,8,steel,false)
 end
 part(21,17,w-42,.5,steel,.3,'magazine-sill')
 label(reserve,5,10,steel,false)
 for _,dx in ipairs({3,w-6}) do for _,dy in ipairs({3,104}) do
  part(dx,dy,3,3,graphite,.8,'fastener');part(dx+.5,dy+1.2,2,.5,steel,.65,'fastener-slot')
 end end
 decorate(out,frame,scale,cfg,opacity)
 for _,v in ipairs(previous) do if v.child then out[#out+1]=v end end
 return out
end
local function verdict_panel(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local mg=m.resource_hex=='11c27d3babb38956'
 local title='P-113 VERDICT'
 local yellow,steel,white,graphite={244,211,31},{141,159,169},{224,231,231},{25,32,36}
 local w,h=116,110
 local function extent(t,size)
  if measure then local a,b,e,f=measure(t,size*scale);if e then return a/scale,b/scale,e/scale,f/scale end end
  return 0,-size*.2,#t*size*.6,size*.8
 end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'MAGS') or ('--- '..(m.reserve_kind or 'MAGS'))
 for _,t in ipairs({reserve,title}) do local a,b,e,f=extent(t,10);w=math.max(w,e-a+24) end
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c={5,13,35},a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted,weapon_theme='rifle',liberator_issue=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,liberator_issue=true,liberator_detail=tag}
 end
 local function label(t,dy,size,c,numeric)
  local a,b,e,f=extent(t,size)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w-a-e)/2*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,center_in_frame=true,liberator_issue=true}
 end
 -- Supplied Helldiver skull silhouette, merged pixel runs; drawn beneath instruments.
 local skull_runs={{21,0,2,1},{18,1,8,1},{15,2,14,1},{12,3,20,1},{9,4,26,1},{6,5,32,1},{4,6,36,2},{5,8,34,14},{5,22,5,1},{15,22,14,1},{34,22,5,1},{6,23,3,1},{16,23,12,2},{35,23,3,1},{5,24,3,1},{36,24,3,1},{4,25,4,1},{17,25,10,4},{36,25,4,1},{3,26,5,1},{36,26,5,1},{2,27,6,1},{36,27,6,1},{1,28,7,1},{36,28,7,1},{0,29,9,1},{16,29,12,1},{35,29,9,1},{1,30,9,1},{15,30,14,1},{34,30,9,1},{2,31,40,1},{2,32,19,1},{23,32,19,1},{3,33,17,1},{24,33,17,1},{4,34,16,1},{24,34,16,1},{5,35,14,1},{25,35,14,1},{6,36,14,1},{21,36,2,1},{24,36,14,1},{7,37,2,1},{13,37,18,4},{35,37,2,1},{14,41,16,2},{15,43,14,1},{17,44,10,1},{21,45,2,1}}
 for _,r in ipairs(skull_runs) do part((w-70)/2+r[1]*70/44,(mg and 31 or 23)+(46-r[2]-r[4])*72/46,r[3]*70/44,r[4]*72/46,yellow,mg and .075 or .105,'skull-watermark') end
 -- The weapon's yellow receiver stencil sits on a recessed graphite designation plate.
 part(7,91,w-14,14,graphite,cfg.panel_opacity*.65,'designation-plate')
 part(8,103,w-16,1.6,yellow,.9,'designation-stripe')
 label(title,93,10,yellow,false)
 -- Slide rails and serrations frame an oversized pistol-round sprite, not a rifle silhouette.
 for _,dx in ipairs({8,w-19}) do
  for i=0,3 do part(dx+i*2.6,76,1.3,12,steel,.65,'verdict-slide-serration') end
 end
 local cx=(w-42)/2
 local shadow,brass,highlight,silver={105,66,24},{225,163,38},{255,220,104},{194,210,222}
 part(cx,77,27,10,shadow,1,'verdict-case')
 part(cx+1,79,25,7,brass,1,'verdict-case');part(cx+2,84,23,2,highlight,1,'verdict-case')
 part(cx+3,78,2,7,shadow,1,'verdict-extractor');part(cx+5,80,1,4,highlight,1,'verdict-extractor')
 -- Short broad round-nose projectile distinguishes the pistol ammunition symbol.
 part(cx+27,78,7,8,silver,1,'verdict-projectile')
 part(cx+34,79,4,6,silver,1,'verdict-projectile');part(cx+38,80,3,4,silver,1,'verdict-projectile')
 part(cx+27,84,7,2,{238,248,255},1,'verdict-projectile-glint')
 part(cx+27,78,7,2,{83,111,136},1,'verdict-projectile-shadow')
 part(7,73,w-14,.7,steel,.5,'verdict-slide-rail')
 -- Recessed count window is the primary instrument; physical details remain peripheral.
 part(7,34,w-14,39,{10,16,20},cfg.panel_opacity*.4,'count-recess')
 for _,dx in ipairs({4,w-5}) do part(dx,36,1,34,steel,.35,'verdict-slide-rail') end
 part(7,73,w-14,.7,steel,.5,'count-seam')
 label(string.format('%03d',tonumber(m.value) or 0),39,36,m.warning and {245,174,91} or white,true)
 -- Exact per-round inspection grid through 60; larger magazines use a labeled percentage gauge.
 local cap=m.capacity
 local valid=type(cap)=='number' and cap==cap and cap>=1 and cap<=100000 and cap%1==0
 if valid and cap<=60 then
  local columns=math.min(15,cap);local pitch=math.min(5.5,(w-26)/columns);local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,cap-1 do
   local loaded=i<(tonumber(m.value) or 0)
   part((w-gridw)/2+(i%columns)*pitch,27-math.floor(i/columns)*3,cw,1.8,loaded and yellow or steel,loaded and .85 or .2,'round-index')
   out[#out].liberator_round_slot=i+1;out[#out].liberator_round_loaded=loaded
  end
 elseif valid then
  local fraction=math.max(0,math.min(1,(tonumber(m.value) or 0)/cap))
  local columns,pitch=15,5.5;local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,columns-1 do
   local dx=(w-gridw)/2+i*pitch
   part(dx,25,cw,3,steel,.2,'capacity-gauge-background')
   local fill=math.max(0,math.min(1,fraction*columns-i))
   if fill>0 then part(dx,25,cw*fill,3,yellow,.85,'capacity-gauge-fill');out[#out].liberator_fraction=fill end
  end
  label(string.format(mg and 'BELT %03d%%' or 'MAG %03d%%',math.floor(fraction*100+.5)),18,6,steel,false)
 else
  label('MAG --',23,8,steel,false)
 end
 part(21,17,w-42,.5,steel,.3,'magazine-sill')
 label(reserve,5,10,steel,false)
 for _,dx in ipairs({3,w-6}) do for _,dy in ipairs({3,104}) do
  part(dx,dy,3,3,graphite,.8,'fastener');part(dx+.5,dy+1.2,2,.5,steel,.65,'fastener-slot')
 end end
 decorate(out,frame,scale,cfg,opacity)
 for _,v in ipairs(previous) do if v.child then out[#out+1]=v end end
 return out
end
local function support_candidate_0(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local mg=true
 local title='MG-43 MACHINE GUN'
 local yellow,steel,white,graphite={244,211,31},{141,159,169},{224,231,231},{25,32,36}
 local w,h=124,110
 local function extent(t,size)
  if measure then local a,b,e,f=measure(t,size*scale);if e then return a/scale,b/scale,e/scale,f/scale end end
  return 0,-size*.2,#t*size*.6,size*.8
 end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'MAGS') or ('--- '..(m.reserve_kind or 'MAGS'))
 for _,t in ipairs({reserve,title}) do local a,b,e,f=extent(t,10);w=math.max(w,e-a+24) end
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c={5,13,35},a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted,weapon_theme='rifle',liberator_issue=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,liberator_issue=true,liberator_detail=tag}
 end
 local function label(t,dy,size,c,numeric)
  local a,b,e,f=extent(t,size)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w-a-e)/2*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,center_in_frame=true,liberator_issue=true}
 end
 -- Supplied Helldiver skull silhouette, merged pixel runs; drawn beneath instruments.
 local skull_runs={{21,0,2,1},{18,1,8,1},{15,2,14,1},{12,3,20,1},{9,4,26,1},{6,5,32,1},{4,6,36,2},{5,8,34,14},{5,22,5,1},{15,22,14,1},{34,22,5,1},{6,23,3,1},{16,23,12,2},{35,23,3,1},{5,24,3,1},{36,24,3,1},{4,25,4,1},{17,25,10,4},{36,25,4,1},{3,26,5,1},{36,26,5,1},{2,27,6,1},{36,27,6,1},{1,28,7,1},{36,28,7,1},{0,29,9,1},{16,29,12,1},{35,29,9,1},{1,30,9,1},{15,30,14,1},{34,30,9,1},{2,31,40,1},{2,32,19,1},{23,32,19,1},{3,33,17,1},{24,33,17,1},{4,34,16,1},{24,34,16,1},{5,35,14,1},{25,35,14,1},{6,36,14,1},{21,36,2,1},{24,36,14,1},{7,37,2,1},{13,37,18,4},{35,37,2,1},{14,41,16,2},{15,43,14,1},{17,44,10,1},{21,45,2,1}}
 for _,r in ipairs(skull_runs) do part((w-70)/2+r[1]*70/44,(mg and 31 or 23)+(46-r[2]-r[4])*72/46,r[3]*70/44,r[4]*72/46,yellow,mg and .075 or .105,'skull-watermark') end
 -- The weapon's yellow receiver stencil sits on a recessed graphite designation plate.
 part(7,91,w-14,14,graphite,cfg.panel_opacity*.65,'designation-plate')
 part(8,103,w-16,1.6,yellow,.9,'designation-stripe')
 label(title,93,10,yellow,false)
 -- Full cartridge sprites form a closely spaced ammunition row beneath the title.
 local cw,ch=32,10
 local brass,bright,shadow,silver,ice={225,163,38},{255,220,104},{132,79,21},{184,201,215},{237,247,255}
 local count=3;local gap=2;local roww=count*cw+(count-1)*gap
 for i=0,count-1 do
  local base=(w-roww)/2+i*(cw+gap)
  local cy=81-ch/2;local case=cw*.69
  -- Every cartridge faces right; preserve the accepted full-size sprite.
  local function px(dx,dy,pw,ph,c)
   part(base+dx,cy+dy,pw,ph,c,1,'paired-cartridge')
  end
  px(0,1,case,ch-2,shadow);px(1,2,case-1,ch-4,brass)
  px(1,ch-3,case-2,2,bright);px(2,2,1,ch-4,shadow);px(3,3,1,ch-6,bright)
  px(case,2,2,ch-4,brass);px(case+2,3,3,ch-6,brass)
  px(case+5,3,3,ch-6,silver);px(case+8,4,cw-case-8,math.max(1,ch-8),silver)
  px(case+5,ch-4,3,1,ice)
 end
 -- Recessed count window is the primary instrument; physical details remain peripheral.
 part(7,34,w-14,39,{10,16,20},cfg.panel_opacity*.4,'count-recess')
 part(7,73,w-14,.7,steel,.5,'count-seam')
 label(string.format('%03d',tonumber(m.value) or 0),39,36,m.warning and {245,174,91} or white,true)
 -- Exact per-round inspection grid through 60; larger magazines use a labeled percentage gauge.
 local cap=m.capacity
 local valid=type(cap)=='number' and cap==cap and cap>=1 and cap<=100000 and cap%1==0
 if valid and cap<=60 then
  local columns=math.min(15,cap);local pitch=math.min(5.5,(w-26)/columns);local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,cap-1 do
   local loaded=i<(tonumber(m.value) or 0)
   part((w-gridw)/2+(i%columns)*pitch,27-math.floor(i/columns)*3,cw,1.8,loaded and yellow or steel,loaded and .85 or .2,'round-index')
   out[#out].liberator_round_slot=i+1;out[#out].liberator_round_loaded=loaded
  end
 elseif valid then
  local fraction=math.max(0,math.min(1,(tonumber(m.value) or 0)/cap))
  local columns,pitch=15,5.5;local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,columns-1 do
   local dx=(w-gridw)/2+i*pitch
   part(dx,25,cw,3,steel,.2,'capacity-gauge-background')
   local fill=math.max(0,math.min(1,fraction*columns-i))
   if fill>0 then part(dx,25,cw*fill,3,yellow,.85,'capacity-gauge-fill');out[#out].liberator_fraction=fill end
  end
  label(string.format(mg and 'BELT %03d%%' or 'MAG %03d%%',math.floor(fraction*100+.5)),18,6,steel,false)
 else
  label('MAG --',23,8,steel,false)
 end
 part(21,17,w-42,.5,steel,.3,'magazine-sill')
 label(reserve,5,10,steel,false)
 for _,dx in ipairs({3,w-6}) do for _,dy in ipairs({3,104}) do
  part(dx,dy,3,3,graphite,.8,'fastener');part(dx+.5,dy+1.2,2,.5,steel,.65,'fastener-slot')
 end end
 decorate(out,frame,scale,cfg,opacity)
 for _,v in ipairs(previous) do if v.child then out[#out+1]=v end end
 return out
end
local function support_candidate_1(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local mg=true
 local title='M-105 STALWART'
 local yellow,steel,white,graphite={244,211,31},{141,159,169},{224,231,231},{25,32,36}
 local w,h=124,110
 local function extent(t,size)
  if measure then local a,b,e,f=measure(t,size*scale);if e then return a/scale,b/scale,e/scale,f/scale end end
  return 0,-size*.2,#t*size*.6,size*.8
 end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'MAGS') or ('--- '..(m.reserve_kind or 'MAGS'))
 for _,t in ipairs({reserve,title}) do local a,b,e,f=extent(t,10);w=math.max(w,e-a+24) end
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c={5,13,35},a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted,weapon_theme='rifle',liberator_issue=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,liberator_issue=true,liberator_detail=tag}
 end
 local function label(t,dy,size,c,numeric)
  local a,b,e,f=extent(t,size)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w-a-e)/2*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,center_in_frame=true,liberator_issue=true}
 end
 -- Supplied Helldiver skull silhouette, merged pixel runs; drawn beneath instruments.
 local skull_runs={{21,0,2,1},{18,1,8,1},{15,2,14,1},{12,3,20,1},{9,4,26,1},{6,5,32,1},{4,6,36,2},{5,8,34,14},{5,22,5,1},{15,22,14,1},{34,22,5,1},{6,23,3,1},{16,23,12,2},{35,23,3,1},{5,24,3,1},{36,24,3,1},{4,25,4,1},{17,25,10,4},{36,25,4,1},{3,26,5,1},{36,26,5,1},{2,27,6,1},{36,27,6,1},{1,28,7,1},{36,28,7,1},{0,29,9,1},{16,29,12,1},{35,29,9,1},{1,30,9,1},{15,30,14,1},{34,30,9,1},{2,31,40,1},{2,32,19,1},{23,32,19,1},{3,33,17,1},{24,33,17,1},{4,34,16,1},{24,34,16,1},{5,35,14,1},{25,35,14,1},{6,36,14,1},{21,36,2,1},{24,36,14,1},{7,37,2,1},{13,37,18,4},{35,37,2,1},{14,41,16,2},{15,43,14,1},{17,44,10,1},{21,45,2,1}}
 for _,r in ipairs(skull_runs) do part((w-70)/2+r[1]*70/44,(mg and 31 or 23)+(46-r[2]-r[4])*72/46,r[3]*70/44,r[4]*72/46,yellow,mg and .075 or .105,'skull-watermark') end
 -- The weapon's yellow receiver stencil sits on a recessed graphite designation plate.
 part(7,91,w-14,14,graphite,cfg.panel_opacity*.65,'designation-plate')
 part(8,103,w-16,1.6,yellow,.9,'designation-stripe')
 label(title,93,10,yellow,false)
 -- Full cartridge sprites form a closely spaced ammunition row beneath the title.
 local cw,ch=29,8
 local brass,bright,shadow,silver,ice={225,163,38},{255,220,104},{132,79,21},{184,201,215},{237,247,255}
 local count=4;local gap=2;local roww=count*cw+(count-1)*gap
 for i=0,count-1 do
  local base=(w-roww)/2+i*(cw+gap)
  local cy=81-ch/2;local case=cw*.69
  -- Every cartridge faces right; preserve the accepted full-size sprite.
  local function px(dx,dy,pw,ph,c)
   part(base+dx,cy+dy,pw,ph,c,1,'paired-cartridge')
  end
  px(0,1,case,ch-2,shadow);px(1,2,case-1,ch-4,brass)
  px(1,ch-3,case-2,2,bright);px(2,2,1,ch-4,shadow);px(3,3,1,ch-6,bright)
  px(case,2,2,ch-4,brass);px(case+2,3,3,ch-6,brass)
  px(case+5,3,3,ch-6,silver);px(case+8,4,cw-case-8,math.max(1,ch-8),silver)
  px(case+5,ch-4,3,1,ice)
 end
 -- Recessed count window is the primary instrument; physical details remain peripheral.
 part(7,34,w-14,39,{10,16,20},cfg.panel_opacity*.4,'count-recess')
 part(7,73,w-14,.7,steel,.5,'count-seam')
 label(string.format('%03d',tonumber(m.value) or 0),39,36,m.warning and {245,174,91} or white,true)
 -- Exact per-round inspection grid through 60; larger magazines use a labeled percentage gauge.
 local cap=m.capacity
 local valid=type(cap)=='number' and cap==cap and cap>=1 and cap<=100000 and cap%1==0
 if valid and cap<=60 then
  local columns=math.min(15,cap);local pitch=math.min(5.5,(w-26)/columns);local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,cap-1 do
   local loaded=i<(tonumber(m.value) or 0)
   part((w-gridw)/2+(i%columns)*pitch,27-math.floor(i/columns)*3,cw,1.8,loaded and yellow or steel,loaded and .85 or .2,'round-index')
   out[#out].liberator_round_slot=i+1;out[#out].liberator_round_loaded=loaded
  end
 elseif valid then
  local fraction=math.max(0,math.min(1,(tonumber(m.value) or 0)/cap))
  local columns,pitch=15,5.5;local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,columns-1 do
   local dx=(w-gridw)/2+i*pitch
   part(dx,25,cw,3,steel,.2,'capacity-gauge-background')
   local fill=math.max(0,math.min(1,fraction*columns-i))
   if fill>0 then part(dx,25,cw*fill,3,yellow,.85,'capacity-gauge-fill');out[#out].liberator_fraction=fill end
  end
  label(string.format(mg and 'BELT %03d%%' or 'MAG %03d%%',math.floor(fraction*100+.5)),18,6,steel,false)
 else
  label('MAG --',23,8,steel,false)
 end
 part(21,17,w-42,.5,steel,.3,'magazine-sill')
 label(reserve,5,10,steel,false)
 for _,dx in ipairs({3,w-6}) do for _,dy in ipairs({3,104}) do
  part(dx,dy,3,3,graphite,.8,'fastener');part(dx+.5,dy+1.2,2,.5,steel,.65,'fastener-slot')
 end end
 decorate(out,frame,scale,cfg,opacity)
 for _,v in ipairs(previous) do if v.child then out[#out+1]=v end end
 return out
end
local function support_candidate_2(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local mg=true
 local title='MG-206 HEAVY MG'
 local yellow,steel,white,graphite={244,211,31},{141,159,169},{224,231,231},{25,32,36}
 local w,h=124,110
 local function extent(t,size)
  if measure then local a,b,e,f=measure(t,size*scale);if e then return a/scale,b/scale,e/scale,f/scale end end
  return 0,-size*.2,#t*size*.6,size*.8
 end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'MAGS') or ('--- '..(m.reserve_kind or 'MAGS'))
 for _,t in ipairs({reserve,title}) do local a,b,e,f=extent(t,10);w=math.max(w,e-a+24) end
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c={5,13,35},a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted,weapon_theme='rifle',liberator_issue=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,liberator_issue=true,liberator_detail=tag}
 end
 local function label(t,dy,size,c,numeric)
  local a,b,e,f=extent(t,size)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w-a-e)/2*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,center_in_frame=true,liberator_issue=true}
 end
 -- Supplied Helldiver skull silhouette, merged pixel runs; drawn beneath instruments.
 local skull_runs={{21,0,2,1},{18,1,8,1},{15,2,14,1},{12,3,20,1},{9,4,26,1},{6,5,32,1},{4,6,36,2},{5,8,34,14},{5,22,5,1},{15,22,14,1},{34,22,5,1},{6,23,3,1},{16,23,12,2},{35,23,3,1},{5,24,3,1},{36,24,3,1},{4,25,4,1},{17,25,10,4},{36,25,4,1},{3,26,5,1},{36,26,5,1},{2,27,6,1},{36,27,6,1},{1,28,7,1},{36,28,7,1},{0,29,9,1},{16,29,12,1},{35,29,9,1},{1,30,9,1},{15,30,14,1},{34,30,9,1},{2,31,40,1},{2,32,19,1},{23,32,19,1},{3,33,17,1},{24,33,17,1},{4,34,16,1},{24,34,16,1},{5,35,14,1},{25,35,14,1},{6,36,14,1},{21,36,2,1},{24,36,14,1},{7,37,2,1},{13,37,18,4},{35,37,2,1},{14,41,16,2},{15,43,14,1},{17,44,10,1},{21,45,2,1}}
 for _,r in ipairs(skull_runs) do part((w-70)/2+r[1]*70/44,(mg and 31 or 23)+(46-r[2]-r[4])*72/46,r[3]*70/44,r[4]*72/46,yellow,mg and .075 or .105,'skull-watermark') end
 -- The weapon's yellow receiver stencil sits on a recessed graphite designation plate.
 part(7,91,w-14,14,graphite,cfg.panel_opacity*.65,'designation-plate')
 part(8,103,w-16,1.6,yellow,.9,'designation-stripe')
 label(title,93,10,yellow,false)
 -- Full cartridge sprites form a closely spaced ammunition row beneath the title.
 local cw,ch=36,12
 local brass,bright,shadow,silver,ice={225,163,38},{255,220,104},{132,79,21},{184,201,215},{237,247,255}
 local count=3;local gap=2;local roww=count*cw+(count-1)*gap
 for i=0,count-1 do
  local base=(w-roww)/2+i*(cw+gap)
  local cy=81-ch/2;local case=cw*.69
  -- Every cartridge faces right; preserve the accepted full-size sprite.
  local function px(dx,dy,pw,ph,c)
   part(base+dx,cy+dy,pw,ph,c,1,'paired-cartridge')
  end
  px(0,1,case,ch-2,shadow);px(1,2,case-1,ch-4,brass)
  px(1,ch-3,case-2,2,bright);px(2,2,1,ch-4,shadow);px(3,3,1,ch-6,bright)
  px(case,2,2,ch-4,brass);px(case+2,3,3,ch-6,brass)
  px(case+5,3,3,ch-6,silver);px(case+8,4,cw-case-8,math.max(1,ch-8),silver)
  px(case+5,ch-4,3,1,ice)
 end
 -- Recessed count window is the primary instrument; physical details remain peripheral.
 part(7,34,w-14,39,{10,16,20},cfg.panel_opacity*.4,'count-recess')
 part(7,73,w-14,.7,steel,.5,'count-seam')
 label(string.format('%03d',tonumber(m.value) or 0),39,36,m.warning and {245,174,91} or white,true)
 -- Exact per-round inspection grid through 60; larger magazines use a labeled percentage gauge.
 local cap=m.capacity
 local valid=type(cap)=='number' and cap==cap and cap>=1 and cap<=100000 and cap%1==0
 if valid and cap<=60 then
  local columns=math.min(15,cap);local pitch=math.min(5.5,(w-26)/columns);local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,cap-1 do
   local loaded=i<(tonumber(m.value) or 0)
   part((w-gridw)/2+(i%columns)*pitch,27-math.floor(i/columns)*3,cw,1.8,loaded and yellow or steel,loaded and .85 or .2,'round-index')
   out[#out].liberator_round_slot=i+1;out[#out].liberator_round_loaded=loaded
  end
 elseif valid then
  local fraction=math.max(0,math.min(1,(tonumber(m.value) or 0)/cap))
  local columns,pitch=15,5.5;local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,columns-1 do
   local dx=(w-gridw)/2+i*pitch
   part(dx,25,cw,3,steel,.2,'capacity-gauge-background')
   local fill=math.max(0,math.min(1,fraction*columns-i))
   if fill>0 then part(dx,25,cw*fill,3,yellow,.85,'capacity-gauge-fill');out[#out].liberator_fraction=fill end
  end
  label(string.format(mg and 'BELT %03d%%' or 'MAG %03d%%',math.floor(fraction*100+.5)),18,6,steel,false)
 else
  label('MAG --',23,8,steel,false)
 end
 part(21,17,w-42,.5,steel,.3,'magazine-sill')
 label(reserve,5,10,steel,false)
 for _,dx in ipairs({3,w-6}) do for _,dy in ipairs({3,104}) do
  part(dx,dy,3,3,graphite,.8,'fastener');part(dx+.5,dy+1.2,2,.5,steel,.65,'fastener-slot')
 end end
 decorate(out,frame,scale,cfg,opacity)
 for _,v in ipairs(previous) do if v.child then out[#out+1]=v end end
 return out
end
local function support_candidate_3(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local mg=true
 local title='RS-422 RAILGUN'
 local yellow,steel,white,graphite={73,204,226},{141,173,187},{224,239,243},{16,35,44}
 local w,h=124,110
 local function extent(t,size)
  if measure then local a,b,e,f=measure(t,size*scale);if e then return a/scale,b/scale,e/scale,f/scale end end
  return 0,-size*.2,#t*size*.6,size*.8
 end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'ROUNDS') or '--- ROUNDS'
 for _,t in ipairs({reserve,title}) do local a,b,e,f=extent(t,10);w=math.max(w,e-a+24) end
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c={5,13,35},a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted,weapon_theme='rifle',liberator_issue=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,liberator_issue=true,liberator_detail=tag}
 end
 local function label(t,dy,size,c,numeric)
  local a,b,e,f=extent(t,size)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w-a-e)/2*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,center_in_frame=true,liberator_issue=true}
 end
 -- Supplied Helldiver skull silhouette, merged pixel runs; drawn beneath instruments.
 local skull_runs={{21,0,2,1},{18,1,8,1},{15,2,14,1},{12,3,20,1},{9,4,26,1},{6,5,32,1},{4,6,36,2},{5,8,34,14},{5,22,5,1},{15,22,14,1},{34,22,5,1},{6,23,3,1},{16,23,12,2},{35,23,3,1},{5,24,3,1},{36,24,3,1},{4,25,4,1},{17,25,10,4},{36,25,4,1},{3,26,5,1},{36,26,5,1},{2,27,6,1},{36,27,6,1},{1,28,7,1},{36,28,7,1},{0,29,9,1},{16,29,12,1},{35,29,9,1},{1,30,9,1},{15,30,14,1},{34,30,9,1},{2,31,40,1},{2,32,19,1},{23,32,19,1},{3,33,17,1},{24,33,17,1},{4,34,16,1},{24,34,16,1},{5,35,14,1},{25,35,14,1},{6,36,14,1},{21,36,2,1},{24,36,14,1},{7,37,2,1},{13,37,18,4},{35,37,2,1},{14,41,16,2},{15,43,14,1},{17,44,10,1},{21,45,2,1}}
 for _,r in ipairs(skull_runs) do part((w-70)/2+r[1]*70/44,(mg and 31 or 23)+(46-r[2]-r[4])*72/46,r[3]*70/44,r[4]*72/46,yellow,mg and .075 or .105,'skull-watermark') end
 -- The weapon's yellow receiver stencil sits on a recessed graphite designation plate.
 part(7,91,w-14,14,graphite,cfg.panel_opacity*.65,'designation-plate')
 part(8,103,w-16,1.6,yellow,.9,'designation-stripe')
 label(title,93,10,yellow,false)
 -- Electromagnetic accelerator cell: paired cyan coil banks around a silver sabot.
 local cyan,ice,dark={73,204,226},{211,239,246},{25,71,87}
 for _,dx in ipairs({27,w-38}) do
  part(dx,76,11,13,dark,.8,'rail-cell')
  for i=0,3 do part(dx,77+i*3,11,1.2,cyan,.85,'rail-coil') end
 end
 part(w/2-16,80,28,5,ice,.9,'rail-sabot');part(w/2+12,81,6,3,ice,.9,'rail-sabot')
 for _,dx in ipairs({7,w-10}) do part(dx,78,3,8,cyan,.7,'rail-terminal') end
 -- Recessed count window is the primary instrument; physical details remain peripheral.
 part(7,34,w-14,39,{10,16,20},cfg.panel_opacity*.4,'count-recess')
 part(7,73,w-14,.7,steel,.5,'count-seam')
 label(string.format('%03d',tonumber(m.value) or 0),39,36,m.warning and {245,174,91} or white,true)
 -- Exact per-round inspection grid through 60; larger magazines use a labeled percentage gauge.
 local cap=m.capacity
 local valid=type(cap)=='number' and cap==cap and cap>=1 and cap<=100000 and cap%1==0
 if valid and cap<=60 then
  local columns=math.min(15,cap);local pitch=math.min(5.5,(w-26)/columns);local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,cap-1 do
   local loaded=i<(tonumber(m.value) or 0)
   part((w-gridw)/2+(i%columns)*pitch,27-math.floor(i/columns)*3,cw,1.8,loaded and yellow or steel,loaded and .85 or .2,'round-index')
   out[#out].liberator_round_slot=i+1;out[#out].liberator_round_loaded=loaded
  end
 elseif valid then
  local fraction=math.max(0,math.min(1,(tonumber(m.value) or 0)/cap))
  local columns,pitch=15,5.5;local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,columns-1 do
   local dx=(w-gridw)/2+i*pitch
   part(dx,25,cw,3,steel,.2,'capacity-gauge-background')
   local fill=math.max(0,math.min(1,fraction*columns-i))
   if fill>0 then part(dx,25,cw*fill,3,yellow,.85,'capacity-gauge-fill');out[#out].liberator_fraction=fill end
  end
  label(string.format('MAG %03d%%',math.floor(fraction*100+.5)),18,6,steel,false)
 else
  label('MAG --',23,8,steel,false)
 end
 part(21,17,w-42,.5,steel,.3,'magazine-sill')
 label(reserve,5,10,steel,false)
 for _,dx in ipairs({3,w-6}) do for _,dy in ipairs({3,104}) do
  part(dx,dy,3,3,graphite,.8,'fastener');part(dx+.5,dy+1.2,2,.5,steel,.65,'fastener-slot')
 end end
 decorate(out,frame,scale,cfg,opacity)
 for _,v in ipairs(previous) do if v.child then out[#out+1]=v end end
 return out
end
local function one_two_candidate(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local mg=m.resource_hex=='11c27d3babb38956'
 local title='AR/GL-21 ONE-TWO'
 local yellow,steel,white,graphite={244,211,31},{141,159,169},{224,231,231},{25,32,36}
 local w,h=132,110
 local function extent(t,size)
  if measure then local a,b,e,f=measure(t,size*scale);if e then return a/scale,b/scale,e/scale,f/scale end end
  return 0,-size*.2,#t*size*.6,size*.8
 end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'MAGS') or ('--- '..(m.reserve_kind or 'MAGS'))
 for _,t in ipairs({reserve,title}) do local a,b,e,f=extent(t,10);w=math.max(w,e-a+24) end
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c={5,13,35},a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted,weapon_theme='rifle',liberator_issue=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,liberator_issue=true,liberator_detail=tag}
 end
 local function label(t,dy,size,c,numeric)
  local a,b,e,f=extent(t,size)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w-a-e)/2*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,center_in_frame=true,liberator_issue=true}
 end
 -- Supplied Helldiver skull silhouette, merged pixel runs; drawn beneath instruments.
 local skull_runs={{21,0,2,1},{18,1,8,1},{15,2,14,1},{12,3,20,1},{9,4,26,1},{6,5,32,1},{4,6,36,2},{5,8,34,14},{5,22,5,1},{15,22,14,1},{34,22,5,1},{6,23,3,1},{16,23,12,2},{35,23,3,1},{5,24,3,1},{36,24,3,1},{4,25,4,1},{17,25,10,4},{36,25,4,1},{3,26,5,1},{36,26,5,1},{2,27,6,1},{36,27,6,1},{1,28,7,1},{36,28,7,1},{0,29,9,1},{16,29,12,1},{35,29,9,1},{1,30,9,1},{15,30,14,1},{34,30,9,1},{2,31,40,1},{2,32,19,1},{23,32,19,1},{3,33,17,1},{24,33,17,1},{4,34,16,1},{24,34,16,1},{5,35,14,1},{25,35,14,1},{6,36,14,1},{21,36,2,1},{24,36,14,1},{7,37,2,1},{13,37,18,4},{35,37,2,1},{14,41,16,2},{15,43,14,1},{17,44,10,1},{21,45,2,1}}
 for _,r in ipairs(skull_runs) do part((w-70)/2+r[1]*70/44,(mg and 31 or 23)+(46-r[2]-r[4])*72/46,r[3]*70/44,r[4]*72/46,yellow,mg and .075 or .105,'skull-watermark') end
 -- The weapon's yellow receiver stencil sits on a recessed graphite designation plate.
 part(7,91,w-14,14,graphite,cfg.panel_opacity*.65,'designation-plate')
 part(8,103,w-16,1.6,yellow,.9,'designation-stripe')
 label(title,93,10,yellow,false)
 -- Clean typed selector instead of crude ammunition artwork; selected-feed data only.
 local grenade=m.fire_mode=='ALT' or m.label=='40MM HE' or m.label=='GRNDS'
 local rifle=not grenade and (m.label=='ROUNDS' or m.fire_mode=='AUTO' or m.fire_mode=='SEMI' or m.fire_mode=='BURST')
 local selectorw=(w-22)/2
 for _,entry in ipairs({{8,'RIFLE',rifle},{w/2+3,'GL',grenade}}) do
  local dx,text,active=entry[1],entry[2],entry[3]
  part(dx,76,selectorw,.7,active and yellow or steel,active and .8 or .25,'feed-selector-rule')
  if active then part(dx,78,1.5,9,yellow,.85,'feed-selector-active') end
  local aa,bb,ee,ff=extent(text,8)
  out[#out+1]={type='text',text=text,font=cfg.font,x=x+(dx+(selectorw-aa-ee)/2)*scale,y=y+79*scale,size=8*scale,c=active and yellow or steel,a=opacity*(active and 1 or .45),one_two_selector=true}
 end
 -- Recessed count window is the primary instrument; physical details remain peripheral.
 part(7,34,w-14,39,{10,16,20},cfg.panel_opacity*.4,'count-recess')
 for _,dx in ipairs({4,w-5}) do part(dx,36,1,34,steel,.35,'verdict-slide-rail') end
 part(7,73,w-14,.7,steel,.5,'count-seam')
 label(string.format('%03d',tonumber(m.value) or 0),39,36,m.warning and {245,174,91} or white,true)
 -- Exact per-round inspection grid through 60; larger magazines use a labeled percentage gauge.
 local cap=m.capacity
 local valid=type(cap)=='number' and cap==cap and cap>=1 and cap<=100000 and cap%1==0
 if valid and cap<=60 then
  local columns=math.min(15,cap);local pitch=math.min(5.5,(w-26)/columns);local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,cap-1 do
   local loaded=i<(tonumber(m.value) or 0)
   part((w-gridw)/2+(i%columns)*pitch,27-math.floor(i/columns)*3,cw,1.8,loaded and yellow or steel,loaded and .85 or .2,'round-index')
   out[#out].liberator_round_slot=i+1;out[#out].liberator_round_loaded=loaded
  end
 elseif valid then
  local fraction=math.max(0,math.min(1,(tonumber(m.value) or 0)/cap))
  local columns,pitch=15,5.5;local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,columns-1 do
   local dx=(w-gridw)/2+i*pitch
   part(dx,25,cw,3,steel,.2,'capacity-gauge-background')
   local fill=math.max(0,math.min(1,fraction*columns-i))
   if fill>0 then part(dx,25,cw*fill,3,yellow,.85,'capacity-gauge-fill');out[#out].liberator_fraction=fill end
  end
  label(string.format(mg and 'BELT %03d%%' or 'MAG %03d%%',math.floor(fraction*100+.5)),18,6,steel,false)
 else
  label('MAG --',23,8,steel,false)
 end
 part(21,17,w-42,.5,steel,.3,'magazine-sill')
 label(reserve,5,10,steel,false)
 for _,dx in ipairs({3,w-6}) do for _,dy in ipairs({3,104}) do
  part(dx,dy,3,3,graphite,.8,'fastener');part(dx+.5,dy+1.2,2,.5,steel,.65,'fastener-slot')
 end end
 decorate(out,frame,scale,cfg,opacity)
 for _,v in ipairs(previous) do if v.child then out[#out+1]=v end end
 return out
end
local function redeemer_candidate(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local mg=m.resource_hex=='11c27d3babb38956'
 local title='P-19 REDEEMER'
 local yellow,steel,white,graphite={244,211,31},{141,159,169},{224,231,231},{25,32,36}
 local w,h=116,110
 local function extent(t,size)
  if measure then local a,b,e,f=measure(t,size*scale);if e then return a/scale,b/scale,e/scale,f/scale end end
  return 0,-size*.2,#t*size*.6,size*.8
 end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'MAGS') or ('--- '..(m.reserve_kind or 'MAGS'))
 for _,t in ipairs({reserve,title}) do local a,b,e,f=extent(t,10);w=math.max(w,e-a+24) end
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c={5,13,35},a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted,weapon_theme='rifle',liberator_issue=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,liberator_issue=true,liberator_detail=tag}
 end
 local function label(t,dy,size,c,numeric)
  local a,b,e,f=extent(t,size)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w-a-e)/2*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,center_in_frame=true,liberator_issue=true}
 end
 -- Supplied Helldiver skull silhouette, merged pixel runs; drawn beneath instruments.
 local skull_runs={{21,0,2,1},{18,1,8,1},{15,2,14,1},{12,3,20,1},{9,4,26,1},{6,5,32,1},{4,6,36,2},{5,8,34,14},{5,22,5,1},{15,22,14,1},{34,22,5,1},{6,23,3,1},{16,23,12,2},{35,23,3,1},{5,24,3,1},{36,24,3,1},{4,25,4,1},{17,25,10,4},{36,25,4,1},{3,26,5,1},{36,26,5,1},{2,27,6,1},{36,27,6,1},{1,28,7,1},{36,28,7,1},{0,29,9,1},{16,29,12,1},{35,29,9,1},{1,30,9,1},{15,30,14,1},{34,30,9,1},{2,31,40,1},{2,32,19,1},{23,32,19,1},{3,33,17,1},{24,33,17,1},{4,34,16,1},{24,34,16,1},{5,35,14,1},{25,35,14,1},{6,36,14,1},{21,36,2,1},{24,36,14,1},{7,37,2,1},{13,37,18,4},{35,37,2,1},{14,41,16,2},{15,43,14,1},{17,44,10,1},{21,45,2,1}}
 for _,r in ipairs(skull_runs) do part((w-70)/2+r[1]*70/44,(mg and 31 or 23)+(46-r[2]-r[4])*72/46,r[3]*70/44,r[4]*72/46,yellow,mg and .075 or .105,'skull-watermark') end
 -- The weapon's yellow receiver stencil sits on a recessed graphite designation plate.
 part(7,91,w-14,14,graphite,cfg.panel_opacity*.65,'designation-plate')
 part(8,103,w-16,1.6,yellow,.9,'designation-stripe')
 label(title,93,10,yellow,false)
 -- A staggered pair of polished pistol rounds expresses the compact magazine feed.
 local brass,bright,shadow,silver={225,163,38},{255,220,104},{132,79,21},{184,201,215}
 for _,origin in ipairs({{11,77},{16,84}}) do local dx,dy=origin[1],origin[2]
  part(dx,dy,24,5,shadow,1,'redeemer-feed-case');part(dx+1,dy+1,23,4,brass,1,'redeemer-feed-case')
  part(dx+2,dy+4,20,1,bright,1,'redeemer-feed-highlight');part(dx+3,dy+1,1,3,shadow,1,'redeemer-extractor')
  part(dx+24,dy+.5,6,4,silver,1,'redeemer-projectile');part(dx+30,dy+1.5,3,2,silver,1,'redeemer-projectile')
 end
 -- The selector shows only the reader's supplied mode; unknown remains explicit.
 local mode=m.fire_mode or 'MODE --'
 local aa,bb,ee,ff=extent(mode,8)
 out[#out+1]={type='text',text=mode,font=cfg.font,x=x+(w-32-(aa+ee)/2)*scale,y=y+80*scale,size=8*scale,c=m.fire_mode and yellow or steel,a=opacity,redeemer_selector=true}
 part(54,77,1,12,steel,.35,'redeemer-selector-divider')
 part(7,73,w-14,.7,steel,.5,'redeemer-header-rule')
 for _,dx in ipairs({3,w-6}) do for i=0,2 do part(dx,45+i*7,3,2,steel,.4,'redeemer-grip-notch') end end
 -- Recessed count window is the primary instrument; physical details remain peripheral.
 part(7,34,w-14,39,{10,16,20},cfg.panel_opacity*.4,'count-recess')
 for _,dx in ipairs({4,w-5}) do part(dx,36,1,34,steel,.35,'verdict-slide-rail') end
 part(7,73,w-14,.7,steel,.5,'count-seam')
 label(string.format('%03d',tonumber(m.value) or 0),39,36,m.warning and {245,174,91} or white,true)
 -- Exact per-round inspection grid through 60; larger magazines use a labeled percentage gauge.
 local cap=m.capacity
 local valid=type(cap)=='number' and cap==cap and cap>=1 and cap<=100000 and cap%1==0
 if valid and cap<=60 then
  local columns=math.min(15,cap);local pitch=math.min(5.5,(w-26)/columns);local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,cap-1 do
   local loaded=i<(tonumber(m.value) or 0)
   part((w-gridw)/2+(i%columns)*pitch,27-math.floor(i/columns)*3,cw,1.8,loaded and yellow or steel,loaded and .85 or .2,'round-index')
   out[#out].liberator_round_slot=i+1;out[#out].liberator_round_loaded=loaded
  end
 elseif valid then
  local fraction=math.max(0,math.min(1,(tonumber(m.value) or 0)/cap))
  local columns,pitch=15,5.5;local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,columns-1 do
   local dx=(w-gridw)/2+i*pitch
   part(dx,25,cw,3,steel,.2,'capacity-gauge-background')
   local fill=math.max(0,math.min(1,fraction*columns-i))
   if fill>0 then part(dx,25,cw*fill,3,yellow,.85,'capacity-gauge-fill');out[#out].liberator_fraction=fill end
  end
  label(string.format(mg and 'BELT %03d%%' or 'MAG %03d%%',math.floor(fraction*100+.5)),18,6,steel,false)
 else
  label('MAG --',23,8,steel,false)
 end
 part(21,17,w-42,.5,steel,.3,'magazine-sill')
 label(reserve,5,10,steel,false)
 for _,dx in ipairs({3,w-6}) do for _,dy in ipairs({3,104}) do
  part(dx,dy,3,3,graphite,.8,'fastener');part(dx+.5,dy+1.2,2,.5,steel,.65,'fastener-slot')
 end end
 decorate(out,frame,scale,cfg,opacity)
 for _,v in ipairs(previous) do if v.child then out[#out+1]=v end end
 return out
end
local function amr_candidate(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local mg=m.resource_hex=='11c27d3babb38956'
 local title='APW-1 AMR'
 local yellow,steel,white,graphite={244,211,31},{141,159,169},{224,231,231},{25,32,36}
 local w,h=124,110
 local function extent(t,size)
  if measure then local a,b,e,f=measure(t,size*scale);if e then return a/scale,b/scale,e/scale,f/scale end end
  return 0,-size*.2,#t*size*.6,size*.8
 end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'MAGS') or ('--- '..(m.reserve_kind or 'MAGS'))
 for _,t in ipairs({reserve,title}) do local a,b,e,f=extent(t,10);w=math.max(w,e-a+24) end
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c={5,13,35},a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted,weapon_theme='precision',amr_candidate=true,liberator_issue=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,liberator_issue=true,liberator_detail=tag}
 end
 local function label(t,dy,size,c,numeric)
  local a,b,e,f=extent(t,size)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w-a-e)/2*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,center_in_frame=true,liberator_issue=true}
 end
 -- Supplied Helldiver skull silhouette, merged pixel runs; drawn beneath instruments.
 local skull_runs={{21,0,2,1},{18,1,8,1},{15,2,14,1},{12,3,20,1},{9,4,26,1},{6,5,32,1},{4,6,36,2},{5,8,34,14},{5,22,5,1},{15,22,14,1},{34,22,5,1},{6,23,3,1},{16,23,12,2},{35,23,3,1},{5,24,3,1},{36,24,3,1},{4,25,4,1},{17,25,10,4},{36,25,4,1},{3,26,5,1},{36,26,5,1},{2,27,6,1},{36,27,6,1},{1,28,7,1},{36,28,7,1},{0,29,9,1},{16,29,12,1},{35,29,9,1},{1,30,9,1},{15,30,14,1},{34,30,9,1},{2,31,40,1},{2,32,19,1},{23,32,19,1},{3,33,17,1},{24,33,17,1},{4,34,16,1},{24,34,16,1},{5,35,14,1},{25,35,14,1},{6,36,14,1},{21,36,2,1},{24,36,14,1},{7,37,2,1},{13,37,18,4},{35,37,2,1},{14,41,16,2},{15,43,14,1},{17,44,10,1},{21,45,2,1}}
 for _,r in ipairs(skull_runs) do part((w-70)/2+r[1]*70/44,(mg and 31 or 23)+(46-r[2]-r[4])*72/46,r[3]*70/44,r[4]*72/46,yellow,mg and .075 or .105,'skull-watermark') end
 -- The weapon's yellow receiver stencil sits on a recessed graphite designation plate.
 part(7,91,w-14,14,graphite,cfg.panel_opacity*.65,'designation-plate')
 part(8,103,w-16,1.6,yellow,.9,'designation-stripe')
 label(title,93,10,yellow,false)
 -- Large rimless precision cartridge: straight brass case, shoulder, neck and silver projectile.
 local brass,bright,shade,silver={193,146,66},{237,199,113},{105,76,39},{207,221,229}
 local bx,by=(w-102)/2,76
 part(bx,by,60,14,brass,1,'amr-case')
 part(bx+5,by+11,53,2,bright,1,'amr-case-highlight')
 part(bx+5,by,53,2,shade,.9,'amr-case-shadow')
 part(bx+3,by,2,14,shade,1,'amr-extractor-groove')
 part(bx+60,by+2,5,10,brass,1,'amr-shoulder')
 part(bx+65,by+4,10,6,brass,1,'amr-neck')
 part(bx+75,by+4,15,6,silver,1,'amr-projectile')
 part(bx+90,by+5,7,4,silver,1,'amr-projectile-tip')
 part(bx+97,by+6,5,2,silver,1,'amr-projectile-tip')
 for _,dx in ipairs({8,w-11}) do
  for i=0,4 do part(dx,37+i*7,i%2==0 and 3 or 1.5,.6,steel,.45,'amr-index-rail') end
 end
 -- Recessed count window is the primary instrument; physical details remain peripheral.
 part(7,34,w-14,39,{10,16,20},cfg.panel_opacity*.4,'count-recess')
 for _,dx in ipairs({4,w-5}) do part(dx,36,1,34,steel,.35,'amr-machined-rail') end
 part(7,73,w-14,.7,steel,.5,'count-seam')
 label(string.format('%03d',tonumber(m.value) or 0),39,36,m.warning and {245,174,91} or white,true)
 -- Exact per-round inspection grid through 60; larger magazines use a labeled percentage gauge.
 local cap=m.capacity
 local valid=type(cap)=='number' and cap==cap and cap>=1 and cap<=100000 and cap%1==0
 if valid and cap<=60 then
  local columns=math.min(15,cap);local pitch=math.min(5.5,(w-26)/columns);local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,cap-1 do
   local loaded=i<(tonumber(m.value) or 0)
   part((w-gridw)/2+(i%columns)*pitch,27-math.floor(i/columns)*3,cw,1.8,loaded and yellow or steel,loaded and .85 or .2,'round-index')
   out[#out].liberator_round_slot=i+1;out[#out].liberator_round_loaded=loaded
  end
 elseif valid then
  local fraction=math.max(0,math.min(1,(tonumber(m.value) or 0)/cap))
  local columns,pitch=15,5.5;local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,columns-1 do
   local dx=(w-gridw)/2+i*pitch
   part(dx,25,cw,3,steel,.2,'capacity-gauge-background')
   local fill=math.max(0,math.min(1,fraction*columns-i))
   if fill>0 then part(dx,25,cw*fill,3,yellow,.85,'capacity-gauge-fill');out[#out].liberator_fraction=fill end
  end
  label(string.format(mg and 'BELT %03d%%' or 'MAG %03d%%',math.floor(fraction*100+.5)),18,6,steel,false)
 else
  label('MAG --',23,8,steel,false)
 end
 part(21,17,w-42,.5,steel,.3,'magazine-sill')
 label(reserve,5,10,steel,false)
 for _,dx in ipairs({3,w-6}) do for _,dy in ipairs({3,104}) do
  part(dx,dy,3,3,graphite,.8,'fastener');part(dx+.5,dy+1.2,2,.5,steel,.65,'fastener-slot')
 end end
 decorate(out,frame,scale,cfg,opacity)
 for _,v in ipairs(previous) do if v.child then out[#out+1]=v end end
 return out
end
local function sta52_candidate(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local mg=m.resource_hex=='11c27d3babb38956'
 local title='StA-52'
 local yellow,steel,white,graphite={230,68,36},{132,145,148},{232,232,217},{32,35,35}
 local w,h=124,110
 local function extent(t,size)
  if measure then local a,b,e,f=measure(t,size*scale);if e then return a/scale,b/scale,e/scale,f/scale end end
  return 0,-size*.2,#t*size*.6,size*.8
 end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'MAGS') or ('--- '..(m.reserve_kind or 'MAGS'))
 for _,t in ipairs({reserve,title}) do local a,b,e,f=extent(t,10);w=math.max(w,e-a+24) end
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c={15,18,18},a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted,weapon_theme='rifle',sta52_candidate=true,liberator_issue=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,liberator_issue=true,liberator_detail=tag}
 end
 local function label(t,dy,size,c,numeric)
  local a,b,e,f=extent(t,size)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w-a-e)/2*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,center_in_frame=true,liberator_issue=true}
 end
 -- Helghast instrument housing: segmented armor spine and recessed industrial vents.
 for _,dx in ipairs({3,w-9}) do
  part(dx,33,6,41,{44,47,46},.65,'armor-spine')
  for i=0,5 do part(dx+1,36+i*6,4,2,{9,12,12},1,'cooling-slot') end
 end
 -- A recessed gunmetal plate and split red stencil replace the Helldiver designation stripe.
 part(7,92,w-14,13,{26,29,29},.9,'designation-plate')
 part(8,103,28,2,yellow,.95,'red-designation-tab')
 part(w-36,103,28,2,yellow,.95,'red-designation-tab')
 label(title,94,10,white,false)
 -- Original respirator-inspired badge: two unmistakable orange-red lenses over a steel filter.
 local ex,ey=14,78
 part(ex,ey,29,12,{49,54,53},1,'respirator-housing')
 part(ex+2,ey+1,25,9,{11,14,14},1,'respirator-recess')
 for _,dx in ipairs({ex+3,ex+17}) do
  part(dx,ey+5,9,4,{136,35,24},1,'helghast-lens-rim')
  part(dx+1,ey+6,7,2,{255,87,39},1,'helghast-lens')
  part(dx+2,ey+7,4,1,{255,190,95},1,'helghast-lens-core')
 end
 part(ex+12,ey+1,5,5,steel,.8,'respirator-filter')
 for i=0,2 do part(ex+13,ey+1+i*1.5,3,.6,{17,20,20},1,'respirator-grille') end
 -- Polished rifle cartridge on a separate ammo inspection shelf, not a weapon silhouette.
 local bx,by=53,80
 part(bx,by,34,8,{168,136,77},1,'sta52-case')
 part(bx+3,by+6,29,1,{219,192,131},1,'sta52-case-highlight')
 part(bx+2,by,1,8,{81,70,44},1,'sta52-extractor')
 part(bx+34,by+1,4,6,{168,136,77},1,'sta52-shoulder')
 part(bx+38,by+2,6,4,{168,136,77},1,'sta52-neck')
 part(bx+44,by+2,10,4,{204,212,210},1,'sta52-projectile')
 part(bx+54,by+3,5,2,{204,212,210},1,'sta52-projectile-tip')
 -- Recessed count window is the primary instrument; physical details remain peripheral.
 part(11,34,w-22,39,{8,11,11},cfg.panel_opacity*.4,'count-recess')
 for _,dx in ipairs({11,w-12}) do part(dx,36,1,34,steel,.35,'count-rail') end
 part(7,73,w-14,.7,steel,.5,'count-seam')
 label(string.format('%03d',tonumber(m.value) or 0),39,36,m.warning and {245,174,91} or white,true)
 -- Exact per-round inspection grid through 60; larger magazines use a labeled percentage gauge.
 local cap=m.capacity
 local valid=type(cap)=='number' and cap==cap and cap>=1 and cap<=100000 and cap%1==0
 if valid and cap<=60 then
  local columns=math.min(15,cap);local pitch=math.min(5.5,(w-26)/columns);local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,cap-1 do
   local loaded=i<(tonumber(m.value) or 0)
   part((w-gridw)/2+(i%columns)*pitch,27-math.floor(i/columns)*3,cw,1.8,loaded and yellow or steel,loaded and .85 or .2,'round-index')
   out[#out].liberator_round_slot=i+1;out[#out].liberator_round_loaded=loaded
  end
 elseif valid then
  local fraction=math.max(0,math.min(1,(tonumber(m.value) or 0)/cap))
  local columns,pitch=15,5.5;local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,columns-1 do
   local dx=(w-gridw)/2+i*pitch
   part(dx,25,cw,3,steel,.2,'capacity-gauge-background')
   local fill=math.max(0,math.min(1,fraction*columns-i))
   if fill>0 then part(dx,25,cw*fill,3,yellow,.85,'capacity-gauge-fill');out[#out].liberator_fraction=fill end
  end
  label(string.format(mg and 'BELT %03d%%' or 'MAG %03d%%',math.floor(fraction*100+.5)),18,6,steel,false)
 else
  label('MAG --',23,8,steel,false)
 end
 part(21,17,w-42,.5,steel,.3,'magazine-sill')
 label(reserve,5,10,steel,false)
 for _,dx in ipairs({3,w-6}) do for _,dy in ipairs({3,104}) do
  part(dx,dy,3,3,graphite,.8,'fastener');part(dx+.5,dy+1.2,2,.5,steel,.65,'fastener-slot')
 end end
 decorate(out,frame,scale,cfg,opacity)
 for _,v in ipairs(out) do if v.decoration and not v.child then v.c=steel end end
 for _,dx in ipairs({0,w-6}) do for _,dy in ipairs({0,104}) do part(dx,dy,6,6,{74,80,78},.95,'armored-corner');part(dx+1,dy+2,4,1,yellow,.9,'corner-red-mark') end end
 for _,v in ipairs(previous) do if v.child then out[#out+1]=v end end
 return out
end
local function peacemaker_candidate(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local mg=m.resource_hex=='11c27d3babb38956'
 local title='P-2 PEACEMAKER'
 local yellow,steel,white,graphite={244,211,31},{141,159,169},{224,231,231},{25,32,36}
 local w,h=116,110
 local function extent(t,size)
  if measure then local a,b,e,f=measure(t,size*scale);if e then return a/scale,b/scale,e/scale,f/scale end end
  return 0,-size*.2,#t*size*.6,size*.8
 end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'MAGS') or ('--- '..(m.reserve_kind or 'MAGS'))
 for _,t in ipairs({reserve,title}) do local a,b,e,f=extent(t,10);w=math.max(w,e-a+24) end
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c={5,13,35},a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted,weapon_theme='rifle',liberator_issue=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,liberator_issue=true,liberator_detail=tag}
 end
 local function label(t,dy,size,c,numeric)
  local a,b,e,f=extent(t,size)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w-a-e)/2*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,center_in_frame=true,liberator_issue=true}
 end
 -- Supplied Helldiver skull silhouette, merged pixel runs; drawn beneath instruments.
 local skull_runs={{21,0,2,1},{18,1,8,1},{15,2,14,1},{12,3,20,1},{9,4,26,1},{6,5,32,1},{4,6,36,2},{5,8,34,14},{5,22,5,1},{15,22,14,1},{34,22,5,1},{6,23,3,1},{16,23,12,2},{35,23,3,1},{5,24,3,1},{36,24,3,1},{4,25,4,1},{17,25,10,4},{36,25,4,1},{3,26,5,1},{36,26,5,1},{2,27,6,1},{36,27,6,1},{1,28,7,1},{36,28,7,1},{0,29,9,1},{16,29,12,1},{35,29,9,1},{1,30,9,1},{15,30,14,1},{34,30,9,1},{2,31,40,1},{2,32,19,1},{23,32,19,1},{3,33,17,1},{24,33,17,1},{4,34,16,1},{24,34,16,1},{5,35,14,1},{25,35,14,1},{6,36,14,1},{21,36,2,1},{24,36,14,1},{7,37,2,1},{13,37,18,4},{35,37,2,1},{14,41,16,2},{15,43,14,1},{17,44,10,1},{21,45,2,1}}
 for _,r in ipairs(skull_runs) do part((w-70)/2+r[1]*70/44,(mg and 31 or 23)+(46-r[2]-r[4])*72/46,r[3]*70/44,r[4]*72/46,yellow,mg and .075 or .105,'skull-watermark') end
 -- The weapon's yellow receiver stencil sits on a recessed graphite designation plate.
 part(7,91,w-14,14,graphite,cfg.panel_opacity*.65,'designation-plate')
 part(8,103,w-16,1.6,yellow,.9,'designation-stripe')
 label(title,93,10,yellow,false)
 -- A single broad, round-nosed pistol cartridge on a polished feed shelf.
 local brass,bright,shade,silver={197,152,73},{238,202,123},{107,78,39},{213,225,230}
 local bx,by=(w-54)/2,77
 part(bx,by,36,12,brass,1,'peacemaker-case')
 part(bx+3,by+9,32,2,bright,1,'peacemaker-case-highlight')
 part(bx+3,by,32,2,shade,.85,'peacemaker-case-shadow')
 part(bx+2,by,1,12,shade,1,'peacemaker-extractor-groove')
 part(bx+36,by+1,11,10,silver,1,'peacemaker-projectile')
 part(bx+47,by+2,4,8,silver,1,'peacemaker-projectile-nose')
 part(bx+51,by+4,3,4,silver,1,'peacemaker-projectile-nose')
 part(bx+37,by+8,9,1,{248,251,248},.85,'peacemaker-projectile-highlight')
 for _,dx in ipairs({9,w-19}) do
  part(dx,78,10,2,steel,.65,'peacemaker-feed-guide')
  part(dx,86,10,2,steel,.65,'peacemaker-feed-guide')
 end
 -- Recessed count window is the primary instrument; physical details remain peripheral.
 part(7,34,w-14,39,{10,16,20},cfg.panel_opacity*.4,'count-recess')
 for _,dx in ipairs({4,w-5}) do part(dx,36,1,34,steel,.35,'peacemaker-slide-rail') end
 part(7,73,w-14,.7,steel,.5,'count-seam')
 label(string.format('%03d',tonumber(m.value) or 0),39,36,m.warning and {245,174,91} or white,true)
 -- Exact per-round inspection grid through 60; larger magazines use a labeled percentage gauge.
 local cap=m.capacity
 local valid=type(cap)=='number' and cap==cap and cap>=1 and cap<=100000 and cap%1==0
 if valid and cap<=60 then
  local columns=math.min(15,cap);local pitch=math.min(5.5,(w-26)/columns);local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,cap-1 do
   local loaded=i<(tonumber(m.value) or 0)
   part((w-gridw)/2+(i%columns)*pitch,27-math.floor(i/columns)*3,cw,1.8,loaded and yellow or steel,loaded and .85 or .2,'round-index')
   out[#out].liberator_round_slot=i+1;out[#out].liberator_round_loaded=loaded
  end
 elseif valid then
  local fraction=math.max(0,math.min(1,(tonumber(m.value) or 0)/cap))
  local columns,pitch=15,5.5;local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,columns-1 do
   local dx=(w-gridw)/2+i*pitch
   part(dx,25,cw,3,steel,.2,'capacity-gauge-background')
   local fill=math.max(0,math.min(1,fraction*columns-i))
   if fill>0 then part(dx,25,cw*fill,3,yellow,.85,'capacity-gauge-fill');out[#out].liberator_fraction=fill end
  end
  label(string.format(mg and 'BELT %03d%%' or 'MAG %03d%%',math.floor(fraction*100+.5)),18,6,steel,false)
 else
  label('MAG --',23,8,steel,false)
 end
 part(21,17,w-42,.5,steel,.3,'magazine-sill')
 label(reserve,5,10,steel,false)
 for _,dx in ipairs({3,w-6}) do for _,dy in ipairs({3,104}) do
  part(dx,dy,3,3,graphite,.8,'fastener');part(dx+.5,dy+1.2,2,.5,steel,.65,'fastener-slot')
 end end
 decorate(out,frame,scale,cfg,opacity)
 for _,v in ipairs(previous) do if v.child then out[#out+1]=v end end
 return out
end
local function epoch_candidate(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local mg=m.resource_hex=='11c27d3babb38956'
 local title='PLAS-45 EPOCH'
 local yellow,steel,white,graphite={244,211,31},{141,159,169},{224,231,231},{25,32,36}
 local w,h=124,110
 local function extent(t,size)
  if measure then local a,b,e,f=measure(t,size*scale);if e then return a/scale,b/scale,e/scale,f/scale end end
  return 0,-size*.2,#t*size*.6,size*.8
 end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'MAGS') or ('--- '..(m.reserve_kind or 'MAGS'))
 for _,t in ipairs({reserve,title}) do local a,b,e,f=extent(t,10);w=math.max(w,e-a+24) end
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c={5,13,35},a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted,weapon_theme='rifle',liberator_issue=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,liberator_issue=true,liberator_detail=tag}
 end
 local function label(t,dy,size,c,numeric)
  local a,b,e,f=extent(t,size)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w-a-e)/2*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,center_in_frame=true,liberator_issue=true}
 end
 -- Supplied Helldiver skull silhouette, merged pixel runs; drawn beneath instruments.
 local skull_runs={{21,0,2,1},{18,1,8,1},{15,2,14,1},{12,3,20,1},{9,4,26,1},{6,5,32,1},{4,6,36,2},{5,8,34,14},{5,22,5,1},{15,22,14,1},{34,22,5,1},{6,23,3,1},{16,23,12,2},{35,23,3,1},{5,24,3,1},{36,24,3,1},{4,25,4,1},{17,25,10,4},{36,25,4,1},{3,26,5,1},{36,26,5,1},{2,27,6,1},{36,27,6,1},{1,28,7,1},{36,28,7,1},{0,29,9,1},{16,29,12,1},{35,29,9,1},{1,30,9,1},{15,30,14,1},{34,30,9,1},{2,31,40,1},{2,32,19,1},{23,32,19,1},{3,33,17,1},{24,33,17,1},{4,34,16,1},{24,34,16,1},{5,35,14,1},{25,35,14,1},{6,36,14,1},{21,36,2,1},{24,36,14,1},{7,37,2,1},{13,37,18,4},{35,37,2,1},{14,41,16,2},{15,43,14,1},{17,44,10,1},{21,45,2,1}}
 for _,r in ipairs(skull_runs) do part((w-70)/2+r[1]*70/44,(mg and 31 or 23)+(46-r[2]-r[4])*72/46,r[3]*70/44,r[4]*72/46,yellow,mg and .075 or .105,'skull-watermark') end
 -- The weapon's yellow receiver stencil sits on a recessed graphite designation plate.
 part(7,91,w-14,14,graphite,cfg.panel_opacity*.65,'designation-plate')
 part(8,103,w-16,1.6,yellow,.9,'designation-stripe')
 label(title,93,10,yellow,false)
 -- Plasma containment lens and split emitter jaws; fixed artwork conveys identity only.
 local cyan,ice,dark={74,210,238},{207,245,253},{24,64,86}
 local cx=30
 part(cx-15,79,30,8,dark,.65,'containment-housing')
 for _,dx in ipairs({cx-19,cx+13}) do
  part(dx,77,6,12,steel,.75,'emitter-jaw')
  part(dx+1,79,4,8,graphite,1,'emitter-slot')
 end
 for _,r in ipairs({{-8,0,16,2},{-11,2,22,4},{-8,6,16,2}}) do
  part(cx+r[1],79+r[2],r[3],r[4],cyan,.8,'plasma-lens')
 end
 part(cx-5,82,10,2,ice,.95,'plasma-core')
 for i=0,2 do part(cx+23+i*5,81,3,.8,cyan,.7-i*.15,'emitter-trace') end
 local q=m.epoch_charge_fraction
 local valid_charge=type(q)=='number' and q==q and q>=0 and q<=1
 local ct=valid_charge and string.format('CHG %03d%%',math.floor(q*100+.5)) or 'CHG --'
 local ca,cb,ce,cf=extent(ct,7)
 out[#out+1]={type='text',text=ct,font=cfg.font,x=x+(w-8-ce)*scale,y=y+79*scale,size=7*scale,c=valid_charge and cyan or steel,a=opacity,epoch_charge_label=true}
 -- Recessed count window is the primary instrument; physical details remain peripheral.
 part(7,34,w-14,39,{10,16,20},cfg.panel_opacity*.4,'count-recess')
 for _,dx in ipairs({4,w-5}) do part(dx,36,1,34,steel,.35,'containment-rail') end
 part(7,73,w-14,.7,steel,.5,'count-seam')
 label(string.format('%03d',tonumber(m.value) or 0),39,36,m.warning and {245,174,91} or white,true)
 -- Exact per-round inspection grid through 60; larger magazines use a labeled percentage gauge.
 local cap=m.capacity
 local valid=type(cap)=='number' and cap==cap and cap>=1 and cap<=100000 and cap%1==0
 if valid and cap<=60 then
  local columns=math.min(15,cap);local pitch=math.min(5.5,(w-26)/columns);local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,cap-1 do
   local loaded=i<(tonumber(m.value) or 0)
   part((w-gridw)/2+(i%columns)*pitch,27-math.floor(i/columns)*3,cw,1.8,loaded and yellow or steel,loaded and .85 or .2,'round-index')
   out[#out].liberator_round_slot=i+1;out[#out].liberator_round_loaded=loaded
  end
 elseif valid then
  local fraction=math.max(0,math.min(1,(tonumber(m.value) or 0)/cap))
  local columns,pitch=15,5.5;local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,columns-1 do
   local dx=(w-gridw)/2+i*pitch
   part(dx,25,cw,3,steel,.2,'capacity-gauge-background')
   local fill=math.max(0,math.min(1,fraction*columns-i))
   if fill>0 then part(dx,25,cw*fill,3,yellow,.85,'capacity-gauge-fill');out[#out].liberator_fraction=fill end
  end
  label(string.format(mg and 'BELT %03d%%' or 'MAG %03d%%',math.floor(fraction*100+.5)),18,6,steel,false)
 else
  label('MAG --',23,8,steel,false)
 end
 part(21,17,w-42,.5,steel,.3,'magazine-sill')
 label(reserve,5,10,steel,false)
 for _,dx in ipairs({3,w-6}) do for _,dy in ipairs({3,104}) do
  part(dx,dy,3,3,graphite,.8,'fastener');part(dx+.5,dy+1.2,2,.5,steel,.65,'fastener-slot')
 end end
 decorate(out,frame,scale,cfg,opacity)
 for _,v in ipairs(previous) do if v.child or v.charge_meter then out[#out+1]=v end end
 return out
end
local function gl21_candidate(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local mg=m.resource_hex=='11c27d3babb38956'
 local title='GL-21'
 local yellow,steel,white,graphite={244,211,31},{141,159,169},{224,231,231},{25,32,36}
 local w,h=116,110
 local function extent(t,size)
  if measure then local a,b,e,f=measure(t,size*scale);if e then return a/scale,b/scale,e/scale,f/scale end end
  return 0,-size*.2,#t*size*.6,size*.8
 end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'MAGS') or ('--- '..(m.reserve_kind or 'MAGS'))
 for _,t in ipairs({reserve,title}) do local a,b,e,f=extent(t,10);w=math.max(w,e-a+24) end
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c={5,13,35},a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted,weapon_theme='rifle',liberator_issue=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,liberator_issue=true,liberator_detail=tag}
 end
 local function label(t,dy,size,c,numeric)
  local a,b,e,f=extent(t,size)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w-a-e)/2*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,center_in_frame=true,liberator_issue=true}
 end
 -- Supplied Helldiver skull silhouette, merged pixel runs; drawn beneath instruments.
 local skull_runs={{21,0,2,1},{18,1,8,1},{15,2,14,1},{12,3,20,1},{9,4,26,1},{6,5,32,1},{4,6,36,2},{5,8,34,14},{5,22,5,1},{15,22,14,1},{34,22,5,1},{6,23,3,1},{16,23,12,2},{35,23,3,1},{5,24,3,1},{36,24,3,1},{4,25,4,1},{17,25,10,4},{36,25,4,1},{3,26,5,1},{36,26,5,1},{2,27,6,1},{36,27,6,1},{1,28,7,1},{36,28,7,1},{0,29,9,1},{16,29,12,1},{35,29,9,1},{1,30,9,1},{15,30,14,1},{34,30,9,1},{2,31,40,1},{2,32,19,1},{23,32,19,1},{3,33,17,1},{24,33,17,1},{4,34,16,1},{24,34,16,1},{5,35,14,1},{25,35,14,1},{6,36,14,1},{21,36,2,1},{24,36,14,1},{7,37,2,1},{13,37,18,4},{35,37,2,1},{14,41,16,2},{15,43,14,1},{17,44,10,1},{21,45,2,1}}
 for _,r in ipairs(skull_runs) do part((w-70)/2+r[1]*70/44,(mg and 31 or 23)+(46-r[2]-r[4])*72/46,r[3]*70/44,r[4]*72/46,yellow,mg and .075 or .105,'skull-watermark') end
 -- The weapon's yellow receiver stencil sits on a recessed graphite designation plate.
 part(7,91,w-14,14,graphite,cfg.panel_opacity*.65,'designation-plate')
 part(8,103,w-16,1.6,yellow,.9,'designation-stripe')
 label(title,93,10,yellow,false)
 -- Wide grenade cartridge: short fluted brass case, steel rim and olive explosive body.
 local brass,bright,shade,olive={187,144,64},{232,195,111},{103,77,35},{102,120,57}
 local bx,by=(w-72)/2,76
 part(bx-1,by-1,5,16,{161,176,176},1,'gl21-rim')
 part(bx+4,by,27,14,brass,1,'gl21-case')
 part(bx+6,by+11,23,2,bright,1,'gl21-case-highlight')
 part(bx+6,by,23,2,shade,.8,'gl21-case-shadow')
 for i=0,2 do part(bx+10+i*6,by+3,1,6,shade,.35,'gl21-case-flute') end
 part(bx+31,by,5,14,{221,185,89},1,'gl21-crimp-band')
 part(bx+36,by,22,14,olive,1,'gl21-grenade-body')
 part(bx+58,by+1,6,12,olive,1,'gl21-ogive')
 part(bx+64,by+3,5,8,olive,1,'gl21-ogive')
 part(bx+69,by+5,3,4,{151,166,96},1,'gl21-fuse-cap')
 part(bx+39,by+10,17,2,{157,172,99},.8,'gl21-body-highlight')
 part(bx+42,by,3,14,{222,193,55},1,'gl21-ordnance-band')
 -- Recessed ordnance cradle supports the header without adding another data box.
 for _,dx in ipairs({bx-6,bx+77}) do part(dx,by,2,14,steel,.6,'gl21-cradle') end
 -- Recessed count window is the primary instrument; physical details remain peripheral.
 part(7,34,w-14,39,{10,16,20},cfg.panel_opacity*.4,'count-recess')
 for _,dx in ipairs({4,w-5}) do part(dx,36,1,34,steel,.35,'gl21-slide-rail') end
 part(7,73,w-14,.7,steel,.5,'count-seam')
 label(string.format('%03d',tonumber(m.value) or 0),39,36,m.warning and {245,174,91} or white,true)
 -- Exact per-round inspection grid through 60; larger magazines use a labeled percentage gauge.
 local cap=m.capacity
 local valid=type(cap)=='number' and cap==cap and cap>=1 and cap<=100000 and cap%1==0
 if valid and cap<=60 then
  local columns=math.min(15,cap);local pitch=math.min(5.5,(w-26)/columns);local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,cap-1 do
   local loaded=i<(tonumber(m.value) or 0)
   part((w-gridw)/2+(i%columns)*pitch,27-math.floor(i/columns)*3,cw,1.8,loaded and yellow or steel,loaded and .85 or .2,'round-index')
   out[#out].liberator_round_slot=i+1;out[#out].liberator_round_loaded=loaded
  end
 elseif valid then
  local fraction=math.max(0,math.min(1,(tonumber(m.value) or 0)/cap))
  local columns,pitch=15,5.5;local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,columns-1 do
   local dx=(w-gridw)/2+i*pitch
   part(dx,25,cw,3,steel,.2,'capacity-gauge-background')
   local fill=math.max(0,math.min(1,fraction*columns-i))
   if fill>0 then part(dx,25,cw*fill,3,yellow,.85,'capacity-gauge-fill');out[#out].liberator_fraction=fill end
  end
  label(string.format(mg and 'BELT %03d%%' or 'MAG %03d%%',math.floor(fraction*100+.5)),18,6,steel,false)
 else
  label('MAG --',23,8,steel,false)
 end
 part(21,17,w-42,.5,steel,.3,'magazine-sill')
 label(reserve,5,10,steel,false)
 for _,dx in ipairs({3,w-6}) do for _,dy in ipairs({3,104}) do
  part(dx,dy,3,3,graphite,.8,'fastener');part(dx+.5,dy+1.2,2,.5,steel,.65,'fastener-slot')
 end end
 decorate(out,frame,scale,cfg,opacity)
 for _,v in ipairs(previous) do if v.child then out[#out+1]=v end end
 return out
end
local function adjudicator_candidate(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];local wide=true
 local w,h=148,110
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local ink,steel,paper,accent={17,24,27},{125,148,143},{231,236,219},{210,169,73}
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c=ink,a=0,frosted=false,weapon_theme='precision'}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,liberator_detail=tag}
 end
 local function label(t,dx,dy,size,c,numeric)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+dx*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric}
 end
 -- Older service-rifle instrument: narrow steel receiver between walnut-toned cheeks.
 part(12,0,124,110,{42,49,46},cfg.panel_opacity,'parkerized-receiver')
 part(0,10,11,88,{89,55,32},cfg.panel_opacity,'left-stock-cheek')
 part(137,10,11,88,{89,55,32},cfg.panel_opacity,'right-stock-cheek')
 for _,dx in ipairs({2,139}) do
  part(dx,14,1,79,{152,102,57},.5,'wood-edge')
  for k=0,7 do part(dx+3,18+k*9,3,5,{35,32,24},.45,'stock-grain') end
 end
 part(14,107,120,2,{150,158,143},.8,'steel-top-bevel')
 part(14,1,120,2,{16,25,23},.9,'steel-bottom-bevel')
 -- Receiver nomenclature stamped above its large single ammo window.
 label('BR-14 ADJUDICATOR',20,96,8,{216,223,195},false)
 part(18,59,112,33,{13,22,21},.95,'round-counter-recess')
 part(18,90,112,1,{111,124,110},.8,'recess-lip')
 label(string.format('%03d',tonumber(m.value) or 0),31,61,33,m.warning and {231,156,86} or {225,231,204},true)
 -- Full-width ammunition specimen slot runs across the lower receiver.
 part(18,22,2,21,{111,124,110},.6,'specimen-retainer')
 part(128,22,2,21,{111,124,110},.6,'specimen-retainer')
 for _,dx in ipairs({7,138}) do for _,dy in ipairs({16,89}) do
  part(dx,dy,3,3,{20,25,22},1,'stock-screw');part(dx+.5,dy+1,2,.5,{135,136,113},.8,'slot')
 end end
 label('SERVICE BATTLE RIFLE',21,8,7,{136,153,127},false)
 -- Older long-case, broad-projectile cartridge; illustrative 8x60-inspired proportions.
 -- This is artwork, not a claim about the game's native caliber.
 local brass,bright,shade,silver={163,132,76},{212,180,113},{88,71,44},{178,183,174}
 local bx,by=24,24
 part(bx,by,57,15,brass,1,'adjudicator-case')
 part(bx+1,by,2,15,{128,104,63},1,'adjudicator-case-head')
 part(bx+4,by+1,2,13,shade,1,'adjudicator-extractor-groove')
 part(bx+7,by+12,48,2,bright,.9,'adjudicator-case-highlight')
 part(bx+7,by,48,2,shade,.85,'adjudicator-case-shadow')
 part(bx+8,by+8,45,1,{187,154,91},.65,'adjudicator-brass-midline')
 -- Sparse oxide patina and fine drawn-case marks, restrained at live HUD size.
 part(bx+16,by+3,6,1,{108,103,64},.42,'adjudicator-aged-brass')
 part(bx+39,by+9,7,1,{103,96,60},.32,'adjudicator-aged-brass')
 part(bx+10,by+3,1,6,bright,.25,'adjudicator-drawn-case')
 part(bx+57,by+2,5,11,brass,1,'adjudicator-shoulder')
 part(bx+62,by+4,9,8,brass,1,'adjudicator-neck')
 part(bx+66,by+4,1,8,shade,.65,'adjudicator-crimp')
 -- Broad jacketed projectile with a long stepped ogive and rounded point.
 part(bx+71,by+4,11,8,silver,1,'adjudicator-projectile')
 part(bx+82,by+5,7,6,silver,1,'adjudicator-ogive')
 part(bx+89,by+6,5,4,{74,124,57},1,'adjudicator-ogive')
 part(bx+94,by+7,3,2,{121,170,86},1,'adjudicator-tip')
 part(bx+72,by+10,10,1,{225,230,212},.9,'adjudicator-projectile-highlight')
 part(bx+73,by+4,9,1,{104,116,109},.65,'adjudicator-projectile-shadow')

 local cap=m.capacity;local valid=type(cap)=='number' and cap==cap and cap>=1 and cap<=100000 and cap%1==0
 local gx,gy=25,54
 if valid and cap<=60 then
  local columns=math.min(15,cap);local pitch=6.5
  for i=0,cap-1 do local loaded=i<(tonumber(m.value) or 0)
   part(gx+(i%columns)*pitch,gy-math.floor(i/columns)*2.5,pitch-2,1.5,loaded and accent or steel,loaded and .9 or .2,'round-index')
   out[#out].liberator_round_slot=i+1;out[#out].liberator_round_loaded=loaded
  end
 elseif valid then
  label(string.format('MAG %03d%%',math.floor(math.max(0,math.min(1,(tonumber(m.value) or 0)/cap))*100+.5)),gx,gy,7,steel,false)
 else label('MAG --',gx,gy,7,steel,false) end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'MAGS') or ('--- '..(m.reserve_kind or 'MAGS'))
 label(reserve,44,44,8,{202,209,179},false)
 for _,v in ipairs(previous) do if v.child then out[#out+1]=v end end
 return out
end
local function autocannon_candidate(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local mg=m.resource_hex=='11c27d3babb38956'
 local title='AC-8 / '..(m.ammo_mode or 'MODE --')
 local yellow,steel,white,graphite={244,211,31},{141,159,169},{224,231,231},{25,32,36}
 local w,h=132,118
 local function extent(t,size)
  if measure then local a,b,e,f=measure(t,size*scale);if e then return a/scale,b/scale,e/scale,f/scale end end
  return 0,-size*.2,#t*size*.6,size*.8
 end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'MAGS') or ('--- '..(m.reserve_kind or 'MAGS'))
 for _,t in ipairs({reserve,title}) do local a,b,e,f=extent(t,10);w=math.max(w,e-a+24) end
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c={31,37,42},a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted,weapon_theme='rifle',liberator_issue=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,liberator_issue=true,liberator_detail=tag}
 end
 local function label(t,dy,size,c,numeric)
  local a,b,e,f=extent(t,size)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w-a-e)/2*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,center_in_frame=true,liberator_issue=true}
 end
 -- Supplied Helldiver skull silhouette, merged pixel runs; drawn beneath instruments.
 local skull_runs={{21,0,2,1},{18,1,8,1},{15,2,14,1},{12,3,20,1},{9,4,26,1},{6,5,32,1},{4,6,36,2},{5,8,34,14},{5,22,5,1},{15,22,14,1},{34,22,5,1},{6,23,3,1},{16,23,12,2},{35,23,3,1},{5,24,3,1},{36,24,3,1},{4,25,4,1},{17,25,10,4},{36,25,4,1},{3,26,5,1},{36,26,5,1},{2,27,6,1},{36,27,6,1},{1,28,7,1},{36,28,7,1},{0,29,9,1},{16,29,12,1},{35,29,9,1},{1,30,9,1},{15,30,14,1},{34,30,9,1},{2,31,40,1},{2,32,19,1},{23,32,19,1},{3,33,17,1},{24,33,17,1},{4,34,16,1},{24,34,16,1},{5,35,14,1},{25,35,14,1},{6,36,14,1},{21,36,2,1},{24,36,14,1},{7,37,2,1},{13,37,18,4},{35,37,2,1},{14,41,16,2},{15,43,14,1},{17,44,10,1},{21,45,2,1}}
 for _,r in ipairs(skull_runs) do part((w-70)/2+r[1]*70/44,(mg and 31 or 23)+(46-r[2]-r[4])*72/46,r[3]*70/44,r[4]*72/46,yellow,mg and .075 or .105,'skull-watermark') end
 -- The weapon's yellow receiver stencil sits on a recessed graphite designation plate.
 part(7,99,w-14,14,graphite,cfg.panel_opacity*.65,'designation-plate')
 part(8,111,w-16,1.6,yellow,.9,'designation-stripe')
 label(title,101,10,yellow,false)
 -- Artillery feed assembly surrounds the accepted long-case shell motif.
 local icon=HUD.munition_art.autocannon_icon(m,HUD.fire_icons.GRENADE_PISTOL_SHELL)
 if icon then
  local factor=math.min(17/icon.h,(w-38)/icon.w)
  local bx,by=(w-icon.w*factor)/2,78
  part(bx-3,by-2,icon.w*factor+6,icon.h*factor+4,{12,18,22},.9,'autocannon-shell-tray')
  for _,r in ipairs(icon.runs) do part(bx+r[1]*factor,by+r[2]*factor,r[3]*factor,r[4]*factor,r[5] or yellow,1,'autocannon-shell') end
 end
 -- Armored feed cheeks, captive pins and linked-clip sockets.
 for _,dx in ipairs({5,w-16}) do
  part(dx,77,11,20,{75,85,87},.8,'autocannon-feed-cheek')
  part(dx+2,79,7,16,{19,28,32},1,'autocannon-feed-slot')
  for k=0,2 do part(dx+3,82+k*5,5,2,steel,.8,'autocannon-feed-lug') end
 end
 for _,dx in ipairs({4,w-9}) do
  part(dx,35,5,37,{71,82,87},.45,'autocannon-counter-armor')
  for k=0,3 do part(dx+1,38+k*9,3,2,{16,25,29},.8,'autocannon-fastener') end
 end
 -- Recessed count window is the primary instrument; physical details remain peripheral.
 part(7,34,w-14,39,{10,16,20},cfg.panel_opacity*.4,'count-recess')
 for _,dx in ipairs({4,w-5}) do part(dx,36,1,34,steel,.35,'autocannon-slide-rail') end
 part(7,73,w-14,.7,steel,.5,'count-seam')
 label(string.format('%03d',tonumber(m.value) or 0),39,36,m.warning and {245,174,91} or white,true)
 -- Exact per-round inspection grid through 60; larger magazines use a labeled percentage gauge.
 local cap=m.capacity
 local valid=type(cap)=='number' and cap==cap and cap>=1 and cap<=100000 and cap%1==0
 if valid and cap<=60 then
  local columns=math.min(15,cap);local pitch=math.min(5.5,(w-26)/columns);local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,cap-1 do
   local loaded=i<(tonumber(m.value) or 0)
   part((w-gridw)/2+(i%columns)*pitch,27-math.floor(i/columns)*3,cw,1.8,loaded and yellow or steel,loaded and .85 or .2,'round-index')
   out[#out].liberator_round_slot=i+1;out[#out].liberator_round_loaded=loaded
  end
 elseif valid then
  local fraction=math.max(0,math.min(1,(tonumber(m.value) or 0)/cap))
  local columns,pitch=15,5.5;local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,columns-1 do
   local dx=(w-gridw)/2+i*pitch
   part(dx,25,cw,3,steel,.2,'capacity-gauge-background')
   local fill=math.max(0,math.min(1,fraction*columns-i))
   if fill>0 then part(dx,25,cw*fill,3,yellow,.85,'capacity-gauge-fill');out[#out].liberator_fraction=fill end
  end
  label(string.format(mg and 'BELT %03d%%' or 'MAG %03d%%',math.floor(fraction*100+.5)),18,6,steel,false)
 else
  label('MAG --',23,8,steel,false)
 end
 part(21,17,w-42,.5,steel,.3,'magazine-sill')
 label(reserve,5,10,steel,false)
 for _,dx in ipairs({3,w-6}) do for _,dy in ipairs({3,104}) do
  part(dx,dy,3,3,graphite,.8,'fastener');part(dx+.5,dy+1.2,2,.5,steel,.65,'fastener-slot')
 end end
 -- Retain reader/layout-owned reload reminder alpha on the primary counter.
 for _,v in ipairs(previous) do if v.numeric_display and not v.child then
  for _,c in ipairs(out) do if c.numeric_display then c.a=v.a;break end end;break
 end end
 decorate(out,frame,scale,cfg,opacity)
 for _,v in ipairs(previous) do if v.child then out[#out+1]=v end end
 return out
end
local function stim_candidate(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local mg=m.resource_hex=='11c27d3babb38956'
 local title='P-11 STIM'
 local yellow,steel,white,graphite={244,211,31},{141,159,169},{224,231,231},{25,32,36}
 local w,h=116,110
 local function extent(t,size)
  if measure then local a,b,e,f=measure(t,size*scale);if e then return a/scale,b/scale,e/scale,f/scale end end
  return 0,-size*.2,#t*size*.6,size*.8
 end
 local reserve=m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'MAGS') or ('--- '..(m.reserve_kind or 'MAGS'))
 for _,t in ipairs({reserve,title}) do local a,b,e,f=extent(t,10);w=math.max(w,e-a+24) end
 local x,y=old.x+old.w/2-w*scale/2,old.y
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c={18,39,37},a=cfg.panel_opacity*opacity,frost_a=opacity,frosted=cfg.frosted,weapon_theme='rifle',liberator_issue=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,liberator_issue=true,liberator_detail=tag}
 end
 local function label(t,dy,size,c,numeric)
  local a,b,e,f=extent(t,size)
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(w-a-e)/2*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,center_in_frame=true,liberator_issue=true}
 end
 -- Supplied Helldiver skull silhouette, merged pixel runs; drawn beneath instruments.
 local skull_runs={{21,0,2,1},{18,1,8,1},{15,2,14,1},{12,3,20,1},{9,4,26,1},{6,5,32,1},{4,6,36,2},{5,8,34,14},{5,22,5,1},{15,22,14,1},{34,22,5,1},{6,23,3,1},{16,23,12,2},{35,23,3,1},{5,24,3,1},{36,24,3,1},{4,25,4,1},{17,25,10,4},{36,25,4,1},{3,26,5,1},{36,26,5,1},{2,27,6,1},{36,27,6,1},{1,28,7,1},{36,28,7,1},{0,29,9,1},{16,29,12,1},{35,29,9,1},{1,30,9,1},{15,30,14,1},{34,30,9,1},{2,31,40,1},{2,32,19,1},{23,32,19,1},{3,33,17,1},{24,33,17,1},{4,34,16,1},{24,34,16,1},{5,35,14,1},{25,35,14,1},{6,36,14,1},{21,36,2,1},{24,36,14,1},{7,37,2,1},{13,37,18,4},{35,37,2,1},{14,41,16,2},{15,43,14,1},{17,44,10,1},{21,45,2,1}}
 for _,r in ipairs(skull_runs) do part((w-70)/2+r[1]*70/44,(mg and 31 or 23)+(46-r[2]-r[4])*72/46,r[3]*70/44,r[4]*72/46,yellow,mg and .075 or .105,'skull-watermark') end
 -- The weapon's yellow receiver stencil sits on a recessed graphite designation plate.
 part(7,91,w-14,14,graphite,cfg.panel_opacity*.65,'designation-plate')
 part(8,103,w-16,1.6,yellow,.9,'designation-stripe')
 label(title,93,10,yellow,false)
 -- Medical injector cartridge: steel plunger, translucent ampoule, dosing marks and needle.
 local mint,glass,steelbright={105,215,178},{42,109,92},{202,224,220}
 local bx,by=(w-76)/2,78
 part(bx-3,by-2,82,15,{10,26,25},.9,'stim-injector-tray')
 part(bx,by+2,4,8,steelbright,1,'stim-plunger-cap')
 part(bx+4,by+5,9,2,steel,.9,'stim-plunger-shaft')
 part(bx+13,by,5,12,steelbright,1,'stim-ampoule-collar')
 part(bx+18,by+1,35,10,glass,.95,'stim-ampoule')
 part(bx+20,by+3,29,5,mint,.8,'stim-fluid')
 part(bx+20,by+9,31,1,{183,242,218},.8,'stim-glass-highlight')
 for k=0,4 do part(bx+22+k*6,by+1,1,3,steelbright,.75,'stim-dose-engraving') end
 part(bx+53,by+2,7,8,steelbright,1,'stim-hub')
 part(bx+60,by+4,5,4,{132,160,155},1,'stim-needle-hub')
 part(bx+65,by+5,11,1,steelbright,1,'stim-needle')
 -- Paired sterile-equipment corners and compact medical cross; no invented healing telemetry.
 for _,dx in ipairs({6,w-12}) do
  part(dx,80,6,1,mint,.65,'stim-tray-lip');part(dx,88,6,1,mint,.65,'stim-tray-lip')
 end
 part(w-14,96,2,7,mint,.9,'stim-medical-mark');part(w-16,98,6,2,mint,.9,'stim-medical-mark')
 for _,dx in ipairs({4,w-6}) do part(dx,38,2,31,{89,148,132},.35,'stim-sterile-rail') end
 -- Recessed count window is the primary instrument; physical details remain peripheral.
 part(7,34,w-14,39,{10,16,20},cfg.panel_opacity*.4,'count-recess')
 for _,dx in ipairs({4,w-5}) do part(dx,36,1,34,steel,.35,'stim-slide-rail') end
 part(7,73,w-14,.7,steel,.5,'count-seam')
 label(string.format('%03d',tonumber(m.value) or 0),39,36,m.warning and {245,174,91} or white,true)
 -- Exact per-round inspection grid through 60; larger magazines use a labeled percentage gauge.
 local cap=m.capacity
 local valid=type(cap)=='number' and cap==cap and cap>=1 and cap<=100000 and cap%1==0
 if valid and cap<=60 then
  local columns=math.min(15,cap);local pitch=math.min(5.5,(w-26)/columns);local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,cap-1 do
   local loaded=i<(tonumber(m.value) or 0)
   part((w-gridw)/2+(i%columns)*pitch,27-math.floor(i/columns)*3,cw,1.8,loaded and yellow or steel,loaded and .85 or .2,'round-index')
   out[#out].liberator_round_slot=i+1;out[#out].liberator_round_loaded=loaded
  end
 elseif valid then
  local fraction=math.max(0,math.min(1,(tonumber(m.value) or 0)/cap))
  local columns,pitch=15,5.5;local cw=pitch-1.5;local gridw=columns*pitch-1.5
  for i=0,columns-1 do
   local dx=(w-gridw)/2+i*pitch
   part(dx,25,cw,3,steel,.2,'capacity-gauge-background')
   local fill=math.max(0,math.min(1,fraction*columns-i))
   if fill>0 then part(dx,25,cw*fill,3,yellow,.85,'capacity-gauge-fill');out[#out].liberator_fraction=fill end
  end
  label(string.format(mg and 'BELT %03d%%' or 'MAG %03d%%',math.floor(fraction*100+.5)),18,6,steel,false)
 else
  label('MAG --',23,8,steel,false)
 end
 part(21,17,w-42,.5,steel,.3,'magazine-sill')
 label(reserve,5,10,steel,false)
 for _,dx in ipairs({3,w-6}) do for _,dy in ipairs({3,104}) do
  part(dx,dy,3,3,graphite,.8,'fastener');part(dx+.5,dy+1.2,2,.5,steel,.65,'fastener-slot')
 end end
 decorate(out,frame,scale,cfg,opacity)
 for _,v in ipairs(previous) do if v.child then out[#out+1]=v end end
 return out
end
-- RL-77 shares the accepted GR-8 cradle dimensions, clamps, seams and material grammar.
local function airburst_panel(previous,m,scale,cfg,opacity,measure,decorate)
 local old=previous[1];if not old then return previous end
 local w,h=132,124;local x,y=old.x,old.y
 local dark,steel,silver,rim,brass={13,18,21},{34,42,47},{212,226,230},{119,143,153},{204,159,80}
 local loaded=type(m.value)=='number' and m.value>0
 local mode=m.ammo_mode=='CLUSTER' and 'CLUSTER' or m.ammo_mode=='FLAK' and 'FLAK' or 'MODE --'
 local band=mode=='CLUSTER' and {226,200,102} or {235,144,57}
 local frame={type='panel',x=x,y=y,w=w*scale,h=h*scale,c=steel,a=cfg.panel_opacity*opacity,frosted=cfg.frosted,weapon_theme='rocket',rl77_panel=true}
 local out={frame}
 local function part(dx,dy,pw,ph,c,a,tag)
  out[#out+1]={type='rect',x=x+dx*scale,y=y+dy*scale,w=pw*scale,h=ph*scale,c=c,a=(a or 1)*opacity,rl77_panel=true,rl77_detail=tag}
 end
 local function label(t,dy,size,c,numeric,dx)
  local a,b,e,f=0,-size*.2,#t*size*.6,size*.8
  if measure then a,b,e,f=measure(t,size*scale);a,b,e,f=a/scale,b/scale,e/scale,f/scale end
  out[#out+1]={type='text',text=t,font=cfg.font,x=x+(dx and dx-a or (w-a-e)/2)*scale,y=y+dy*scale,size=size*scale,c=c,a=opacity,numeric_display=numeric,rl77_panel=true}
 end
 -- Exactly the GR-8 bolted perimeter, recessed launch bay and ribbed retaining clamps.
 part(0,0,w,1,rim,.8,'surround');part(0,h-1,w,1,rim,.8,'surround');part(0,0,1,h,rim,.8,'surround');part(w-1,0,1,h,rim,.8,'surround')
 part(10,29,2,64,rim,.4,'bay-edge');part(120,29,2,64,rim,.4,'bay-edge')
 for _,dx in ipairs({4,125}) do for _,dy in ipairs({4,117}) do part(dx,dy,3,3,dark,1,'fastener');part(dx+.5,dy+1,2,.5,silver,.6,'fastener-slot') end end
 for _,dx in ipairs({14,109}) do
  part(dx,35,9,50,{47,61,68},1,'tube-clamp');part(dx,35,9,1,rim,1,'tube-clamp')
  for k=0,5 do part(dx+2,39+k*7,5,2,dark,1,'tube-clamp-rib');part(dx+2,40+k*7,5,.5,rim,.4,'tube-clamp-rib') end
 end
 label('RL-77',109,11,silver,false);label(mode,95,10,band,false)
 if loaded then
  -- Airburst rocket illustration: finned tail, cylindrical payload body and compact ogive.
  part(54,36,24,37,{74,91,67},1,'rocket-silhouette');part(57,37,18,36,{127,143,94},1,'rocket-silhouette')
  part(58,39,3,31,{184,196,131},.8,'rocket-silhouette');part(73,39,3,31,{47,62,44},.9,'rocket-silhouette')
  part(50,34,6,10,rim,1,'rocket-silhouette');part(76,34,6,10,rim,1,'rocket-silhouette');part(54,33,24,3,silver,.65,'rocket-silhouette')
  part(54,69,24,3,band,1,'rocket-silhouette');part(57,71,18,.7,{240,223,168},.8,'rocket-silhouette')
  for k=0,8 do local width=24-k*2.5;part(66-width/2,73+k*1.8,width,2,{111-k*4,124-k*4,89-k*3},1,'rocket-silhouette') end
  part(64.5,89,3,2,silver,.8,'rocket-silhouette')
  for _,dy in ipairs({47,58}) do part(55,dy,22,.7,{50,66,44},.7,'rocket-silhouette') end
  local symbol=mode=='CLUSTER' and HUD.fire_icons.AIRBURST_CLUSTER or mode=='FLAK' and HUD.fire_icons.AIRBURST
  if symbol then for _,r in ipairs(symbol.runs) do part(60+r[1]*.6,51+r[2]*.6,r[3]*.6,r[4]*.6,band,.65,'mode-symbol') end end
 else
  -- Match GR-8's empty cradle. No spent-case or reload-stage state is inferred.
  part(49,33,34,2,rim,.3,'empty-cradle');part(49,33,2,57,rim,.3,'empty-cradle');part(81,33,2,57,rim,.3,'empty-cradle');part(49,89,34,2,rim,.3,'empty-cradle');part(58,56,16,1,rim,.2,'empty-cradle')
 end
 label(string.format('%03d',tonumber(m.value) or 0),20,10,loaded and silver or {237,111,87},true,12)
 label(loaded and 'LOADED' or 'EMPTY',21,8,loaded and brass or {237,111,87},false)
 part(9,17,114,.5,rim,.4,'reserve-rule')
 label(m.reserve~=nil and string.format('%03d %s',m.reserve,m.reserve_kind or 'RCKTS') or '--- RCKTS',5,10,silver,false)
 for k=0,3 do part(13+k*4,101,2,2,brass,.7,'header-tab');part(105+k*4,101,2,2,brass,.7,'header-tab') end
 -- Keep a suite mode child, including optional verified fire selection.
 local text=mode..(m.fire_mode and ' / '..m.fire_mode or '')
 local size=10;local a,b,e,f=0,-2,#text*6,8
 if measure then a,b,e,f=measure(text,size*scale);a,b,e,f=a/scale,b/scale,e/scale,f/scale end
 if e-a>w-12 then size=size*(w-12)/(e-a);a,b,e,f=0,-size*.2,#text*size*.6,size*.8 end
 local ch=f-b+8;local child={type='panel',child=true,rl77_panel=true,x=x,y=y-(ch+2)*scale,w=w*scale,h=ch*scale,c=steel,a=frame.a,frosted=cfg.frosted}
 out[#out+1]=child;out[#out+1]={type='text',child=true,text=text,font=cfg.font,x=x+(w-a-e)/2*scale,y=child.y+(4-b)*scale,size=size*scale,c=band,a=opacity,rl77_panel=true}
 local details={};decorate(details,child,scale,cfg,opacity);for _,v in ipairs(details) do v.child=true;out[#out+1]=v end
 return out
end
function M.apply(out,m,scale,cfg,opacity,measure,decorate,clock)
 local style=M.catalog[m.resource_hex]
 if not style then return out end
 -- All native heat gauges and identified laser variants use the preceding shared layout.
 if m.kind=='heat' or HUD.ammo_types.laser_weapons[m.resource_hex] or m.energy_icon=='LASER' then return out end
 -- Restore the preceding fuel/gas gauge; telemetry and warning zones stay in layout.lua.
 if m.label=='FUEL' or m.label=='GAS' then return out end
 if m.resource_hex=='11c27d3babb38956' and not m.mg43_flash then return support_candidate_0(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='a6a735accb4a327f' then return support_candidate_1(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='2152d5147b0ac418' then return support_candidate_2(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='2e9d0bdc48b09e60' then return support_candidate_3(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='89c5493e08ca4207' then return amr_candidate(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='cdf28be026bb7d84' then return sta52_candidate(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='05e4e5c2db6e44a2' then return peacemaker_candidate(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='e8d5f49ad7780e54' then return epoch_candidate(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='02eecd0b1fa49630' then return gl21_candidate(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='5fecab819f96a3e8' then return adjudicator_candidate(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='a8cffb316f0b5c5f' then return autocannon_candidate(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='d6b1fb05b9109353' then return stim_candidate(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='3575aabc5f1f9326' then return redeemer_candidate(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='a955c4ea6f6d4203' then return one_two_candidate(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='1a437158e1b8d2a1' then return verdict_panel(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='26e40437ea275296' then return airburst_panel(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='11c27d3babb38956' and not m.mg43_flash then return liberator_panel(out,m,scale,cfg,opacity,measure,decorate) end
 if liberator_titles[m.resource_hex] then return liberator_panel(out,m,scale,cfg,opacity,measure,decorate) end
 if m.resource_hex=='4d58c77087b774c5' then return socom_panel(out,m,scale,cfg,opacity,measure,decorate) end
 if HUD.shared_suite and HUD.shared_suite.enabled and HUD.shared_suite.eligible(m.resource_hex) then return HUD.shared_suite.compose(out,m,scale,cfg,opacity,style,measure,decorate) end
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
