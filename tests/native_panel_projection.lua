-- Pure native-corner projection math; no engine calls.
local N=dofile('src/projection.lua');local Scene=dofile('src/screen_scene.lua')
local function map(rows,x,y)
 local w=rows[7]*x+rows[8]*y+rows[9]
 return (rows[1]*x+rows[2]*y+rows[3])/w,(rows[4]*x+rows[5]*y+rows[6])/w
end
local function near(a,b)assert(math.abs(a-b)<1e-8,string.format('Expected %.12g, got %.12g',b,a))end
-- Recorded live sample: the engine returns 4K pixels, never normalized XY.
local xy=assert(N.native_coordinate_map(3840,2160))
assert(xy.space=='output_pixels')
local normalized=N.normalize_native_point({x=1731.082520,y=853.674622,depth=1.511504},xy)
near(normalized.x*1920,865.541260);near(normalized.y*1080,426.837311)
near(normalized.depth,1.511504)
-- A viewport change must derive a new scale; no cached 4K division for 1440p.
local resized=assert(N.native_coordinate_map(2560,1440))
assert(resized.space=='output_pixels'and resized.sx~=xy.sx)
local p=N.normalize_native_point({x=1154.0550133333,y=569.1164146667},resized)
near(p.x,normalized.x);near(p.y,normalized.y)
assert(N.native_coordinate_map(0,2160)==nil)
assert(N.native_coordinate_map(math.huge,2160)==nil)
local unit={{0,0},{1,0},{1,1},{0,1}}
local function check(forward)
 local points={};for i,p in ipairs(unit)do local x,y=map(forward,p[1],p[2]);points[i]={x=x,y=y}end
 local rows=assert(N.native_panel_inverse(points),'Valid projected quad rejected')
 near(math.max(math.abs(rows[7]),math.abs(rows[8]),math.abs(rows[9])),1)
 for i,p in ipairs(points)do local u,v=map(rows,p.x,p.y);near(u,unit[i][1]);near(v,unit[i][2])end
 for _,p in ipairs({{.2,.3},{.5,.5},{.8,.1},{.05,.95}})do local x,y=map(forward,p[1],p[2]);local u,v=map(rows,x,y);near(u,p[1]);near(v,p[2])end
 local atlas={32/256,32/512,174/256,304/512};local cropped=Scene.atlas_rows(rows,atlas)
 for _,p in ipairs({{0,0},{1,1},{.37,.61}})do local x,y=map(forward,p[1],p[2]);local u,v=map(cropped,x,y);near(u,atlas[1]+atlas[3]*p[1]);near(v,atlas[2]+atlas[4]*p[2])end
 -- Input tables and inverse rows stay untouched by either composition step.
 for i,p in ipairs(unit)do local x,y=map(forward,p[1],p[2]);near(points[i].x,x);near(points[i].y,y)end
 for i=7,9 do assert(cropped[i]==rows[i])end
 return rows
end
check({.55,.05,.16,.03,.62,.1,.35,-.12,1}) -- tilted perspective quad
check({.6,0,.15,0,.5,.2,0,0,1}) -- affine
check({.32,-.18,.4,.18,.32,.2,0,0,1}) -- rotated affine
check({-.5,.04,.8,.02,.5,.2,.08,.15,1}) -- reversed orientation remains valid
local array=assert(N.native_panel_inverse({{.1,.2},{.8,.2},{.8,.9},{.1,.9}}));local u,v=map(array,.45,.55);near(u,.5);near(v,.5)
local invalid={
 {{0,0},{1,0},{2,0},{3,0}}, -- collinear
 {{0,0},{1,0},{1,0},{0,1}}, -- repeated corner
 {{0,0},{1,1},{1,0},{0,1}}, -- crossed
 {{0,0},{1,0},{.2,.2},{0,1}}, -- concave
 {{0,0},{1e-14,0},{1e-14,1e-14},{0,1e-14}}, -- ill conditioned
 {{0,0},{math.huge,0},{1,1},{0,1}},
 {{0,0},{0/0,0},{1,1},{0,1}},
 {{0,0},{1e7+1,0},{1,1},{0,1}},
 {{0,0},{1,0},{1,1}},
 {{0,0},false,{1,1},{0,1}}
}
for _,points in ipairs(invalid)do assert(N.native_panel_inverse(points)==nil,'Invalid quad accepted')end
assert(N.native_panel_inverse(nil)==nil and N.native_panel_inverse(false)==nil)
print('PASS native panel inverse: perspective corners/interior, affine/rotated/reversed orientation, object/array points, normalized denominator, atlas-row composition, input preservation, singular/nonfinite/unstable refusal')
