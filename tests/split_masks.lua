local Edge=dofile('src/edge_mask.lua');local Core=dofile('src/runtime_textures.lua')
local f=assert(io.open('assets/split-hud/manifest-additions.tsv','rb'));local manifest=f:read('*a');f:close()
local images={}
for line in manifest:gmatch('[^\r\n]+')do
 local name,w,h,file=line:match('^([^\t]+)\t(%d+)\t(%d+)\t([^\t]+)$')
 images[name]=Core.read_image('assets/split-hud/'..file,tonumber(w),tonumber(h))
end
local hard,face=images.split_hud_hard_coverage_v1,images.split_hud_face_v1
local function pixel(p,x,y)return p.rgba:byte((y*p.width+x)*4+4)end
local function make(width,curve,dither,grain)
 return Edge.split_images(Edge.settings({panel_edge_softness=width,panel_edge_curve=curve,panel_edge_dither=dither,panel_edge_grain=grain}),hard,face).images
end
local restored=make(0,1,0,2)
assert(restored.split_hud_dynamic_coverage_v1.rgba==hard.rgba,'Hard Split coverage changed')
assert(restored.split_hud_dynamic_face_v1.rgba==face.rgba,'Hard Split decoration changed')
local soft=make(7,1,40,2);local repeat_mask=make(7,1,40,2)
for name,p in pairs(soft)do
 assert(Core.validate(p)==640*322*4 and p.rgba==repeat_mask[name].rgba,'Split mask not deterministic')
 for i=1,#p.rgba,4 do assert(p.rgba:sub(i,i+2)=='\255\255\255','Dark RGB under alpha')end
end
local coverage,decoration,mask=soft.split_hud_dynamic_coverage_v1,soft.split_hud_dynamic_face_v1,soft.split_hud_dynamic_soft_v1
assert(pixel(coverage,200,120)==255 and pixel(coverage,50,120)==0,'Disconnected background filled reserve gap')
assert(pixel(coverage,550,120)==0 and pixel(coverage,220,300)==0,'Backdrop entered settings/status pods')
assert(pixel(mask,200,120)==255 and pixel(mask,20,20)==0,'Full-UV soft coordinates wrong')
local attenuated,rail_outside_backing=false,false
for y=0,321 do for x=0,639 do
 local a,b=pixel(face,x,y),pixel(decoration,x,y)
 assert(b<=a and pixel(coverage,x,y)<=pixel(hard,x,y),'Fade creates new artwork')
 if b>0 and b<a then attenuated=true end
 if a>0 and pixel(hard,x,y)==0 and b>0 then rail_outside_backing=true end
end end
assert(attenuated and rail_outside_backing,'Shared decoration was hard or clipped to backing rectangle')
local smooth=make(7,1,0,2);assert(smooth.split_hud_dynamic_coverage_v1.rgba~=coverage.rgba,'Dither has no effect')
local wider=make(20,2,100,4);assert(wider.split_hud_dynamic_coverage_v1.rgba~=coverage.rgba,'Width/curve/grain have no effect')
print('PASS Split masks: three coordinated full-UV images, exact hard restoration, stable grain, transparent pods, independent rail footprint, white RGB and mutable edge controls')
