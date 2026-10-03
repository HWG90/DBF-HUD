-- Preview-only native rectangle artwork, using existing shell geometry and palette.
local M={};for k,v in pairs(HUD.fire_icons) do M[k]=v end
local shell={w=12,h=30,runs={}}
local function p(x,y,w,h,c) shell.runs[#shell.runs+1]={x,y,w,h,c} end
-- Broad cylindrical reflection, dark edges and a restrained central sheen.
local blues={{22,49,82},{31,70,112},{44,93,144},{58,116,173},{77,140,197},{92,157,212},{76,139,195},{55,112,169},{35,79,126},{23,53,88}}
for i,c in ipairs(blues) do p(i,11,1,17,c) end
for i,x in ipairs({2.5,4,5.5,7,8.5,9.5}) do
 local c=blues[math.min(10,math.ceil(x))]
 p(x,12,.23,15,{math.max(0,c[1]-10),math.max(0,c[2]-12),math.max(0,c[3]-13)})
 p(x+.23,12,.18,15,{c[1]+9,c[2]+10,c[3]+10})
end
-- Brass cup reflects a narrow bright strip within its rounded surface.
local metals={{94,64,29},{137,99,47},{192,151,81},{230,196,122},{247,222,171},{218,184,112},{189,149,75},{149,109,47},{108,76,30},{80,56,24}}
for i,c in ipairs(metals) do p(i,2,1,8,c) end
p(1,10,10,1,{96,73,40});p(2,10,8,.35,{231,201,134})
p(0,0,12,.65,{77,56,29});p(0,.65,12,.75,{220,187,119})
p(.5,1.4,11,.6,{157,119,61});p(2,.65,7,.3,{250,231,185})
-- Upper roll and closed crimp: restrained terraces rather than a flat blue bar.
local closed_start=#shell.runs+1
p(1,28,10,.6,{23,49,77});p(1.5,28.6,9,.8,{72,121,167})
p(2,29.4,8,.6,{102,157,204});p(4,28.7,4,.35,{125,173,216})
M.DOUBLE_FREEDOM_SHELL=shell
local spent={w=12,h=30,runs={}}
for i=1,closed_start-1 do spent.runs[#spent.runs+1]=shell.runs[i] end
local function q(x,y,w,h,c) spent.runs[#spent.runs+1]={x,y,w,h,c} end
-- Dark open mouth with rim reflection and irregular but balanced crimp petals.
q(1,27.5,10,.7,{19,39,61});q(2,28.2,8,.8,{8,18,29})
q(1,28.2,1,1.8,{42,84,129});q(10,28.2,1,1.8,{30,65,104})
q(1,29.4,1,.6,{101,156,201});q(10,29.2,1,.8,{78,130,177})
q(3,28.3,.8,1.7,{55,103,151});q(7.5,28.1,1,1.6,{77,133,180})
q(4,27.8,3,.35,{91,145,190})
M.DOUBLE_FREEDOM_SPENT=spent
return M
