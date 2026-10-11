local M=dofile('src/edge_mask.lua')
local Core=dofile('src/runtime_textures.lua')
local function image(width,curve,dither,grain)return M.image(M.settings({panel_edge_softness=width,panel_edge_curve=curve,panel_edge_dither=dither,panel_edge_grain=grain}))end
local function alpha(p,x,y)return p.rgba:byte((y*p.width+x)*4+4)end
local original=image(4,1,0,1)
local started=os.clock()
for _,width in ipairs({1,4,13,24})do for _,curve in ipairs({.5,1,3})do for _,dither in ipairs({0,35,100})do for _,grain in ipairs({1,4})do
 local p=image(width,curve,dither,grain);assert(Core.validate(p)==131072)
 for y=0,p.height-1 do for x=0,p.width-1 do
  local i=(y*p.width+x)*4+1;assert(p.rgba:sub(i,i+2)=='\255\255\255','Dark transparent RGB')
  local a=alpha(p,x,y)
  if x==0 or y==0 or x==p.width-1 or y==p.height-1 then assert(a==0,'Hard boundary remains')end
  assert(a==alpha(p,p.width-1-x,y)and a==alpha(p,x,p.height-1-y),'Opposite edges differ')
  local dx=math.min(x,p.width-1-x);local dy=math.min(y,p.height-1-y)
  if math.min(dx,dy)>=p.width*width/100 then assert(a==255,'Dither damaged solid center')end
 end end
 assert(alpha(p,64,128)==255)
end end end end
for y=0,255 do for x=0,127 do
 local t=math.min(1,math.min(x,127-x,y,255-y)/(128*4/100))
 assert(alpha(original,x,y)==math.floor(255*t*t*(3-2*t)+.5),'Dither off differs from accepted 4% mask')
end end
local partial=image(13,1,35,1);local binary=image(13,1,100,1);local smooth=image(13,1,0,1)
assert(partial.rgba~=smooth.rgba and binary.rgba~=smooth.rgba and partial.rgba~=image(13,1,35,4).rgba)
assert(partial.rgba==image(13,1,35,1).rgba,'Dither is not deterministic')
for i=4,#binary.rgba,4 do local a=binary.rgba:byte(i);assert(a==0 or a==255,'Fully dithered pixels are not binary')end
local hard=image(0,3,100,4);for i=4,#hard.rgba,4 do assert(hard.rgba:byte(i)==255)end
local lighter=image(13,.5,0,1);local faster=image(13,3,0,1)
assert(alpha(lighter,6,128)>alpha(smooth,6,128)and alpha(smooth,6,128)>alpha(faster,6,128),'Fade curve direction wrong')
-- Dither retains mean transmission at each fixed distance across a complete tile.
for x=1,15 do
 local sum=0;for y=64,95 do sum=sum+alpha(binary,x,y)end
 assert(math.abs(sum/32-alpha(smooth,x,80))<=9,'Dither density differs from fade coverage')
end
local defaults=M.settings();assert(M.signature(defaults)=='4:1.0:35:1')
local sanitized=M.settings({panel_edge_softness=99,panel_edge_curve=0/0,panel_edge_dither=-5,panel_edge_grain=99})
assert(M.signature(sanitized)=='24:1.0:0:4')
local last=os.clock();for i=1,20 do image(4,1,35,1)end
print(string.format('PASS edge masks: 72 settings cases, symmetry, clear boundary/solid center, exact accepted smooth alpha, stable dither/coverage/grain/curve; image generation average %.3f ms',(os.clock()-last)*1000/20))

local export=os.getenv('DBF_HUD_EDGE_MASK_REVIEW')
if export then
 for _,v in ipairs({{'smooth-4',4,1,0,1},{'fine-4',4,1,35,1},{'dissolve-12',12,1.5,75,1},{'coarse-12',12,1,100,4}})do
  local f=assert(io.open(export..'/'..v[1]..'.rgba','wb'));f:write(image(v[2],v[3],v[4],v[5]).rgba);f:close()
 end
end
