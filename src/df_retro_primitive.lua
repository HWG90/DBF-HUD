-- Isolated Designer export. Top-left coordinates; adapter may flip Y for native GUI.
-- compose(model,x,y,width,height,alpha) returns DBF-style rect/text commands.
local M={design_width=640,design_height=1320,style="16-bit",texture_free=true}
function M.compose(m,x,y,w,h,a)
 m=m or {}; x=x or 0;y=y or 0;w=w or 160;h=h or 330;a=a or 1
 local out={};local ivory={223,216,177};local gold={236,193,99}
 local function rect(px,py,pw,ph,c,op)out[#out+1]={type='rect',x=x+px*w/640,y=y+py*h/1320,w=pw*w/640,h=ph*h/1320,c=c,a=a*(op or 1)}end
 local function text(px,py,s,str,c,op)out[#out+1]={type='text',x=x+px*w/640,y=y+py*h/1320,size=s*h/1320,text=str,font='bigblue',c=c or ivory,a=a*(op or 1)}end
 -- Stepped translucent silhouette, no bitmap dependency.
 -- Feathered backing: nested non-overlapping bands, pale stepped outline.
 rect(30,30,580,1260,{37,44,40},.52)
 for i=0,3 do
  local inset=14+i*4;local bw,bh=612-i*8,1292-i*8;local op=.08+i*.09
  rect(inset,inset,4,bh,{37,44,40},op);rect(640-inset-4,inset,4,bh,{37,44,40},op)
  rect(inset+4,inset,bw-8,4,{37,44,40},op);rect(inset+4,1320-inset-4,bw-8,4,{37,44,40},op)
 end
 for i=0,5 do
  rect(20+i*4,42-i*4,4,4,ivory,.65);rect(596+i*4,18+i*4,4,4,ivory,.65)
  rect(20+i*4,1278+i*4,4,4,ivory,.65);rect(596+i*4,1298-i*4,4,4,ivory,.65)
 end
 for _,py in ipairs({42,280,500,750,980,1180})do rect(18,py,2,130,ivory,.42);rect(620,py,2,130,ivory,.42)end
 rect(48,22,540,2,ivory,.45);rect(48,1298,540,2,ivory,.45)
 -- Sliding compass reads the accepted camera heading, not a static direction.
 local ticks,heading=HUD.compass.ticks(m.heading)
 rect(56,103,528,1,ivory,.6)
 if ticks then
  for _,tick in ipairs(ticks)do
   local tx=56+528*tick.position
   rect(tx,82,1,tick.label and 20 or 10,ivory,.7)
   if tick.label and tick.position>.03 and tick.position<.97 then text(tx,60,17,tick.label);out[#out].center_x=tx*w/640 end
  end
  text(320,119,13,string.format('%03d DEG',heading));out[#out].center_x=320*w/640
  for i=0,5 do rect(314+i,106+i,12-i*2,1,gold)end
 else text(320,68,17,'---');out[#out].center_x=320*w/640 end
 text(132,165,64,'DBS-2');out[#out].center_x=320*w/640;text(113,242,24,'DOUBLE FREEDOM');out[#out].center_x=320*w/640;rect(64,284,512,1,ivory,.7)
 text(126,306,16,'10 GAUGE TACTICAL SHOTGUN');out[#out].center_x=320*w/640
 local n=type(m.value)=='number' and m.value or nil
 for side=1,2 do
  local first=#out+1
  local sx=side==1 and 112 or 372
  local loaded=n and n>=3-side;local op=n==nil and .45 or loaded and 1 or .28
  -- Identical bounds for loaded and fired states. Blue hull 73%, brass 27%.
  rect(sx,398,144,412,{18,40,70},op)
  rect(sx+7,398,130,412,{24,62,110},op)
  rect(sx+16,402,14,400,{48,95,151},op*.8)
  rect(sx+32,402,8,400,{32,78,133},op*.7)
  rect(sx+110,402,18,400,{12,31,57},op*.8)
  -- Coarse ordered highlights keep the sprite feel at low command cost.
  for row=0,11 do rect(sx+18+(row%2)*6,420+row*30,6,6,{64,122,177},op*.45);rect(sx+119-(row%2)*6,434+row*30,6,6,{8,25,48},op*.45)end
  rect(sx+8,390,128,8,{53,105,159},op)
  rect(sx+20,382,104,8,{24,66,115},op)
  rect(sx,810,144,120,{144,113,56},op)
  rect(sx+9,811,127,120,{183,147,75},op)
  rect(sx+22,813,17,116,{225,197,123},op)
  rect(sx+108,813,15,116,{133,98,42},op)
  for row=0,5 do rect(sx+40+(row%2)*6,817+row*18,6,6,{231,207,142},op*.5)end
  rect(sx-6,929,156,8,{214,183,110},op)
  rect(sx-3,937,150,5,{126,98,50},op)
  text(sx+43,548,30,'10',{8,24,43},op);text(sx+43,586,30,'GA',{8,24,43},op)
  text(sx+27,663,16,'3 1/2"',{8,24,43},op);text(sx+43,685,16,'MAG',{8,24,43},op)
  -- At the native Lua preview size 128x264, 96 px/in means +12px wide,
  -- -24px tall. Scale the whole shell about its center, preserving brass ratio.
  local fx,fy=216/156,440/560
  local cx,cy=(sx+72)*w/640,662*h/1320
  for i=first,#out do
   local v=out[i];v.shell_side=side
   v.x=cx+(v.x-cx)*fx;v.y=cy+(v.y-cy)*fy
   if v.type=='rect' then v.w=v.w*fx;v.h=v.h*fy else v.size=v.size*fy;v.shell_center_x=cx end
  end
 end
 text(74,1020,16,'RESERVE');out[#out].reserve_part='label';text(218,996,54,type(m.reserve)=='number' and string.format('%03d',math.max(0,m.reserve)) or '---');out[#out].reserve_part='value';text(430,1020,16,'SHELLS');out[#out].reserve_part='unit'
 rect(64,1082,512,1,ivory,.75)
 local mode=m.fire_mode
 for i,label in ipairs({'SEMI','VOLLEY'})do
  local bx=i==1 and 130 or 330;local active=mode==label;local op=active and 1 or .3
  rect(bx,1138,174,2,active and gold or ivory,op);rect(bx,1202,174,2,active and gold or ivory,op)
  rect(bx,1138,2,66,active and gold or ivory,op);rect(bx+172,1138,2,66,active and gold or ivory,op)
  text(bx+35,1158,24,label,active and gold or ivory,op)
  if active then for j=0,7 do rect(bx+72+j,1115+j,30-j*2,1,gold)end end
 end
 return out
end
return M