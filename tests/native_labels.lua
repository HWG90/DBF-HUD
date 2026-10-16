-- Static native label images preserve selected font geometry/tint and fall back
-- without allocations, uploads or missing readouts when assets are unavailable.
HUD={}
for _,name in ipairs({'native_font_data','native_font_uv','font','native_label_data','native_labels'})do HUD[name]=dofile('src/'..name..'.lua')end
local L,D=HUD.native_labels,HUD.native_label_data
local current
local function close(a,b)assert(math.abs(a-b)<1e-6,tostring(current)..': '..tostring(a)..' != '..tostring(b))end
local function text(s,font)
 return {type='text',text=s,font=font or'hack',size=8.05,x=42.5,y=-10.5,c={233,196,93},a=.43,
  split_role='unit',spatial_plane='reserve',spatial_depth=.014,readout_key='unit'}
end
local frame={type='panel',split_hud=true};local count=0
for font,face in pairs(D.faces)do
 for word,label in pairs(face.labels)do
  current=font..'/'..word
  local v=text(word,font);local input={frame,v};local out=L.prepare(input,function()return true end,24)
  local q=out[2];assert(out~=input and input[2].type=='text'and q.type=='texture'and q.native_label)
  local left,bottom,right,top=HUD.font.measure(word,v.size,font,true)
  close(q.x,v.x+left);close(q.y,v.y+bottom);close(q.w,right-left);close(q.h,top-bottom)
  assert(q.c==v.c and q.a==v.a and q.texture_layer==51,'Label color/opacity/layer changed')
  assert(q.spatial_plane==v.spatial_plane and q.spatial_depth==v.spatial_depth and q.split_role==v.split_role,'Label left its plane')
  assert(q.texture_resource==face.resource and q.texture_material==D.material and q.atlas_rect==label.uv and q.texture_theme==false)
  assert(q.texture_slot==1 and q.font==font and q.text==word,'Diagnostic identity lost')
  count=count+1
 end
end
assert(count==328,'Unexpected unbounded label dictionary')
local missing={frame,text('ROUNDS')}
assert(L.prepare(missing,function(_,name)return name==D.material end,24)==missing,'Missing atlas blanked the native fallback')
assert(L.prepare(missing,function()return false end,24)==missing,'Missing material changed the native fallback')
assert(L.prepare(missing,nil,24)==missing,'Absent native API changed the fallback')
for _,v in ipairs({text('HDG 035 NE'),text('UNSAFE 1.23s'),text('36'),text('/ 35'),text('ROUNDS','jetbrainsmono')})do
 local input={frame,v};assert(L.prepare(input,function()return true end,24)==input,'Dynamic text or another font was substituted')
end
for _,flag in ipairs({'last_digit_color','numeric_display','fuel_endpoint'})do
 local v=text('ROUNDS');v[flag]=true;local input={frame,v};assert(L.prepare(input,function()return true end,24)==input,'Special text handling bypassed')
end
-- The existing image/shader budget wins. Remaining text is never dropped.
local input={frame}
for i=1,23 do input[#input+1]={type='texture',texture_slot=i}end
input[#input+1]=text('ROUNDS');input[#input+1]=text('MAGS')
local out=L.prepare(input,function()return true end,24)
assert(out[25].native_label and out[25].texture_slot==24 and out[26]==input[26],'Image budget overflow or missing text')
assert(L.prepare(out,function()return true end,24)==out,'Full image budget was rebuilt')
-- Same source vocabulary is immutable across 1000 changing headings.
local labels=D.faces.hack.labels;local n=0;for _ in pairs(labels)do n=n+1 end
for i=1,1000 do
 local h={frame,text(string.format('HDG %03d N',i%360))}
 assert(L.prepare(h,function()return true end,24)==h)
end
local after=0;for _ in pairs(labels)do after=after+1 end;assert(after==n and after==164,'Heading traffic grew label storage')
local nonsplit={{type='panel'},text('ROUNDS')};assert(L.prepare(nonsplit,function()return true end,24)==nonsplit)
print('PASS 328 native labels: exact font bounds, color/alpha, four-plane metadata, 24-image budget and bounded dynamic-text fallback')
