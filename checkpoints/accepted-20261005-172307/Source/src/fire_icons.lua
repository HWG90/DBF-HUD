-- Masks sampled from the game fire-mode textures; rectangle rendering preserves HUD depth.
local M={
    LASER={w=17,h=24,runs={{8,0,1,15},{7,15,3,3},{8,20,1,4},{8,11,1,3},{0,16,5,1},{12,16,5,1},{3,21,2,2},{12,21,2,2},{3,11,2,2},{12,11,2,2}}},
    AUTO={w=24,h=24,runs={{0,23,18,1},{0,22,21,1},{0,21,23,1},{0,20,24,1},{0,19,23,1},{0,18,21,1},{0,17,18,1},{0,14,20,1},{0,13,22,1},{0,12,24,1},{0,11,24,1},{0,10,23,1},{0,9,20,1},{2,8,12,1},{0,6,18,1},{0,5,21,1},{0,4,23,1},{0,3,24,1},{0,2,23,1},{0,1,21,1},{0,0,18,1}}},
    SEMI={w=24,h=7,runs={{0,6,18,1},{0,5,21,1},{0,4,23,1},{0,3,24,1},{0,2,23,1},{0,1,22,1},{0,0,19,1}}},
    BURST={w=24,h=11,runs={{2,10,1,1},{0,9,1,1},{2,9,1,1},{5,9,2,1},{8,9,7,1},{0,8,1,1},{2,8,1,1},{5,8,2,1},{8,8,12,1},{0,7,1,1},{2,7,1,1},{5,7,2,1},{8,7,14,1},{0,6,1,1},{2,6,1,1},{5,6,2,1},{8,6,15,1},{0,5,1,1},{2,5,1,1},{5,5,2,1},{8,5,16,1},{0,4,1,1},{2,4,1,1},{5,4,2,1},{8,4,15,1},{0,3,1,1},{2,3,1,1},{5,3,2,1},{8,3,14,1},{0,2,1,1},{2,2,1,1},{5,2,2,1},{8,2,12,1},{0,1,1,1},{2,1,1,1},{5,1,2,1},{8,1,7,1},{2,0,1,1}}},
    ALT={w=24,h=13,runs={{0,12,2,1},{0,11,2,1},{3,11,14,1},{19,11,1,1},{0,10,2,1},{3,10,14,1},{19,10,3,1},{0,9,2,1},{3,9,14,1},{19,9,4,1},{0,8,2,1},{3,8,14,1},{19,8,5,1},{0,7,2,1},{3,7,14,1},{19,7,5,1},{0,6,2,1},{3,6,14,1},{19,6,5,1},{0,5,2,1},{3,5,14,1},{19,5,5,1},{0,4,2,1},{3,4,14,1},{19,4,5,1},{0,3,2,1},{3,3,14,1},{19,3,4,1},{0,2,2,1},{3,2,14,1},{19,2,3,1},{0,1,2,1},{3,1,14,1},{19,1,2,1},{0,0,2,1}}},
}
-- Upright ammunition symbols for weapons without fire selection.
-- Rotate only the ammunition cartridge; selectable fire-mode masks stay unchanged.
M.BULLET={w=M.SEMI.h,h=M.SEMI.w,runs={}}
for _,r in ipairs(M.SEMI.runs) do
    M.BULLET.runs[#M.BULLET.runs+1]={M.SEMI.h-r[2]-r[4],r[1],r[4],r[3]}
end
-- Three cartridges held by visible dark steel belt links.
M.LINKED_BELT={w=29,h=24,runs={}}
for _,offset in ipairs({0,11,22}) do
    for _,r in ipairs(M.BULLET.runs) do
        M.LINKED_BELT.runs[#M.LINKED_BELT.runs+1]={offset+r[1],r[2],r[3],r[4],r[2]>=18 and {190,150,100} or {218,172,78}}
    end
end
for _,offset in ipairs({0,11}) do
    for _,r in ipairs({{4,6,11,2},{4,13,11,2},{4,6,2,9},{13,6,2,9}}) do
        M.LINKED_BELT.runs[#M.LINKED_BELT.runs+1]={offset+r[1],r[2],r[3],r[4],{125,135,145}}
    end
end
-- Adjudicator: horizontal bottleneck rifle cartridges with copper projectiles.
M.RIFLE_SEMI={w=32,h=8,runs={
    {0,0,2,8,{218,172,78}},{3,1,17,6,{218,172,78}},
    {20,2,3,4,{218,172,78}},{24,2,4,4,{192,120,72}},
    {28,3,3,2,{192,120,72}},{31,3,1,1,{192,120,72}}
}}
M.RIFLE_AUTO={w=32,h=28,runs={}}
for _,offset in ipairs({0,10,20}) do
    for _,r in ipairs(M.RIFLE_SEMI.runs) do
        M.RIFLE_AUTO.runs[#M.RIFLE_AUTO.runs+1]={r[1],r[2]+offset,r[3],r[4],r[5]}
    end
end
-- Anti-Materiel Rifle: heavy bottleneck cartridge with machined brass and copper tip.
M.AMR_CARTRIDGE={w=44,h=10,runs={
    {0,0,3,10,{209,165,82}},{0,7,2,2,{255,224,154}},
    {3,1,24,8,{190,145,67}},{4,6,22,2,{237,199,117}},
    {4,1,22,2,{119,88,43}},{25,1,2,8,{245,210,134}},
    {27,2,3,6,{190,145,67}},{30,3,3,4,{209,165,82}},
    {33,3,4,4,{183,111,71}},{37,4,4,2,{183,111,71}},
    {41,4,2,2,{216,154,105}},{43,4.5,1,1,{216,154,105}},
    {33,6,4,1,{244,190,139}},{4,4,1,2,{119,88,43}}
}}
-- Compact brass pistol cartridge, medical dart and energy/tool emblems.
M.SIDEARM_CARTRIDGE={w=24,h=10,runs={{0,0,2,10,{212,173,91}},{2,1,13,8,{199,153,73}},{3,7,11,1,{247,216,142}},{14,1,1,8,{104,79,43}},{15,2,5,6,{195,126,86}},{20,3,3,4,{195,126,86}},{23,4,1,2,{227,167,119}}}}
M.ENERGY_CELL={w=28,h=14,runs={{0,3,3,8,{153,187,199}},{3,1,22,12,{55,104,119}},{5,3,18,8,{75,202,222}},{7,4,14,2,{183,247,253}},{25,3,3,8,{153,187,199}},{10,2,1,10,{32,58,73}},{17,2,1,10,{32,58,73}}}}
M.ARC_EMBLEM={w=22,h=20,runs={{11,0,3,7},{6,5,8,3},{7,6,3,8},{7,12,10,3},{14,13,3,7}}}
M.TOOL_BLADE={w=30,h=12,runs={{0,4,9,4,{119,132,139}},{8,2,2,8,{223,190,86}},{10,3,15,6,{189,206,216}},{25,4,3,4,{189,206,216}},{28,5,2,2,{233,243,247}},{11,7,13,1,{238,247,250}}}}
M.STIM_DART={w=30,h=12,runs={{0,3,4,6,{198,219,220}},{4,2,16,8,{108,222,178}},{6,7,12,1,{218,254,239}},{12,3,1,6,{41,98,79}},{20,4,4,4,{198,219,220}},{24,5,6,1,{228,244,246}}}}
M.TOOL_HATCHET={w=28,h=20,runs={{11,0,4,17,{125,139,147}},{1,12,22,7,{189,206,216}},{0,13,2,5,{228,239,242}},{22,13,5,5,{103,123,134}},{11,16,4,2,{227,193,82}}}}
M.TOOL_BATON={w=32,h=10,runs={{0,3,10,4,{104,123,139}},{9,1,2,8,{227,193,82}},{11,3,18,4,{119,168,208}},{14,2,2,6,{109,216,255}},{21,2,2,6,{109,216,255}},{29,4,3,2,{220,247,255}}}}
M.TOOL_FLAG={w=28,h=20,runs={{3,0,2,20,{183,197,204}},{5,9,22,10,{227,193,82}},{8,11,4,6,{34,40,44}},{13,14,9,1,{34,40,44}}}}
M.TOOL_PACK={w=26,h=18,runs={{1,1,24,16,{96,116,85}},{0,0,26,2,{155,173,140}},{4,3,2,12,{227,193,82}},{20,3,2,12,{227,193,82}},{10,6,6,5,{198,205,188}}}}
-- Amendment: polished medium rifle cartridge with rim, neck and copper tip.
M.AMENDMENT_CARTRIDGE={w=14,h=34,runs={
    {0,0,14,2,{218,172,78}},{1,2,12,2,{159,115,47}},
    {2,5,10,17,{218,172,78}},{3,6,2,15,{250,216,137}},
    {10,6,2,15,{159,115,47}},{3,22,8,2,{218,172,78}},
    {4,24,6,3,{218,172,78}},{4,27,6,1,{95,73,48}},
    {4,28,6,2,{192,120,72}},{5,30,4,2,{192,120,72}},
    {6,32,2,2,{192,120,72}},{5,28,1,3,{230,162,106}},
    {2,4,10,1,{255,226,153}}
}}
M.DEADEYE_CARTRIDGE={w=14,h=44.2,scale=1.5,runs={}}
for _,r in ipairs(M.AMENDMENT_CARTRIDGE.runs) do
    M.DEADEYE_CARTRIDGE.runs[#M.DEADEYE_CARTRIDGE.runs+1]={r[1],r[2]*1.3,r[3],r[4]*1.3,r[5]}
end
M.AMENDMENT_BURST={w=46,h=34,runs={}}
for _,offset in ipairs({0,16,32}) do
    for _,r in ipairs(M.AMENDMENT_CARTRIDGE.runs) do
        M.AMENDMENT_BURST.runs[#M.AMENDMENT_BURST.runs+1]={offset+r[1],r[2],r[3],r[4],r[5]}
    end
end
-- Re-Educator: slim silver dart, pointed needle and distinct rear vanes.
M.DART={w=11,h=34,runs={
    {4,2,3,24,{180,195,205}},{4,3,1,22,{240,245,250}},
    {1,0,3,7,{88,125,145}},{7,0,3,7,{88,125,145}},
    {2,7,2,3,{88,125,145}},{7,7,2,3,{88,125,145}},
    {3,0,5,2,{220,228,232}},{3,24,5,2,{105,120,130}},
    {4,26,3,4,{225,232,238}},{5,30,1,4,{245,248,250}}
}}
-- Heavy bolt cartridge: rim, straight case, shoulder and broad pointed projectile.
M.BOLT_ROUND={w=14,h=28,runs={
    {0,0,14,2},{1,2,12,2},{2,5,10,13},
    {3,18,8,2},{4,20,6,4},{5,24,4,2},{6,26,2,2}
}}
-- Outlined hull, crimped mouth and separate rim/base for barrel indicators.
M.BARREL_SHELL={w=12,h=28,runs={
    {0,0,12,2},{1,2,10,5},{1,8,10,1},
    {1,10,2,16},{9,10,2,16},
    {3,10,6,1},{3,25,6,2},{1,27,10,1},
    {4,23,1,2},{7,23,1,2}
}}
-- Approved cylindrical blue hull and brass reflections, static native rectangles.
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
M.SHELL=M.BARREL_SHELL
M.DOUBLE_SHELL={w=27,h=28,runs={}}
for _,offset in ipairs({0,15})do
    for _,r in ipairs(M.SHELL.runs)do M.DOUBLE_SHELL.runs[#M.DOUBLE_SHELL.runs+1]={r[1]+offset,r[2],r[3],r[4]} end
end
M.TRIPLE_SHELL={w=42,h=28,runs={}}
for _,offset in ipairs({0,15,30}) do
    for _,r in ipairs(M.SHELL.runs) do M.TRIPLE_SHELL.runs[#M.TRIPLE_SHELL.runs+1]={r[1]+offset,r[2],r[3],r[4]} end
end
M.ROCKET={w=11,h=24,runs={{4,21,3,2},{5,23,1,1},{3,5,5,16},{1,0,3,7},{7,0,3,7},{4,0,3,3}}}
-- Short, broad guided missile with tapered nose, casing seam and rear fins.
-- Native StratagemHammer path, cropped to its hammer silhouette.
M.HAMMER={w=48,h=19,runs={{41,18,7,1},{41,17,7,1},{41,16,7,1},{41,15,7,1},{41,14,7,1},{41,13,7,1},{40,12,8,1},{0,11,12,1},{38,11,10,1},{0,10,48,1},{0,9,48,1},{0,8,48,1},{0,7,48,1},{40,6,8,1},{41,5,7,1},{41,4,7,1},{41,3,7,1},{41,2,7,1},{41,0,7,1}}}
-- Charcoal hammer with industrial yellow bands and a small skull on its head.
do
    local icon=M.HAMMER
    for _,run in ipairs(icon.runs) do
        run[5]={91,97,103}
    end
    local yellow={245,201,48};local charcoal={68,73,78}
    local details={
        {2,8,2,4,yellow},{12,8,2,4,yellow},{38,8,2,4,yellow},
        {42,16,5,1,yellow},{42,2,5,1,yellow},
        {43,9,4,3,yellow},{44,8,2,1,yellow},{44,7,2,1,yellow},
        {43,10,1,1,charcoal},{46,10,1,1,charcoal},
        {44,6,1,1,yellow},{46,6,1,1,yellow}
    }
    for _,run in ipairs(details) do icon.runs[#icon.runs+1]=run end
end
M.SPEAR_ROCKET={w=16,h=24,runs={{7,23,2,1},{6,21,4,2},{5,19,6,2},{4,8,8,11},{3,6,10,1},{4,3,8,2},{1,0,3,7},{12,0,3,7},{5,0,6,2}}}
-- Detailed horizontal missile, with separated fins and subdued casing fill.
-- Run alpha retains the selected text color and follows the loaded-state pulse.
M.MISSILE_SIDE={w=64,h=24,runs={
    {5,1,3,1},{6,2,4,1},{7,3,5,1},{8,4,5,1},{9,5,5,1},{10,6,5,1},
    {5,22,3,1},{6,21,4,1},{7,20,5,1},{8,19,5,1},{9,18,5,1},{10,17,5,1},
    {0,10,3,4},{3,9,3,6},{6,10,3,4},
    {10,7,33,1},{10,16,33,1},{9,8,1,8},
    {11,8,31,8,nil,.28},
    {11,8,4,2},{11,14,4,2},
    {17,8,1,8,nil,.8},{38,8,1,8,nil,.8},
    {20,9,15,1,nil,.65},{20,14,15,1,nil,.45},
    {21,11,8,2,nil,.65},
    {43,8,2,8},{46,8,3,8,nil,.85},
    {49,9,3,6},{52,10,3,4},{55,11,4,2},{59,11,5,1},
    {12,6,4,1},{12,17,4,1}
}}
for _,run in ipairs(M.MISSILE_SIDE.runs) do
    if run[1]>=43 then run[5]={235,158,62}
    elseif run[1]<17 then run[5]={117,158,105}
    elseif run[1]==38 then run[5]={235,191,87}
    else run[5]={209,220,229} end
end
-- Distinct HUD silhouettes for the Recoilless Rifle's two rocket modes.
M.ROCKET_HEAT={w=11,h=24,runs={{5,22,1,2},{4,19,3,3},{3,8,5,11},{4,5,3,3},{1,0,3,7},{7,0,3,7},{4,0,3,3}}}
M.ROCKET_HE={w=11,h=24,runs={{4,22,3,2},{3,20,5,2},{2,14,7,6},{3,6,5,8},{1,0,3,7},{7,0,3,7},{4,0,3,3}}}
-- Angular flame sampled from the flamethrower stratagem icon reproduction.
M.FUEL={w=16,h=24,runs={{5,23,1,1},{5,22,2,1},{5,21,3,1},{5,20,4,1},{4,19,6,1},{4,18,7,1},{4,17,7,1},{4,16,7,1},{3,15,8,1},{2,14,9,1},{13,14,1,1},{1,13,10,1},{12,13,2,1},{0,12,15,1},{0,11,15,1},{0,10,15,1},{0,9,7,1},{8,9,8,1},{0,8,6,1},{8,8,8,1},{0,7,6,1},{9,7,7,1},{0,6,5,1},{10,6,6,1},{0,5,5,1},{10,5,5,1},{1,4,5,1},{9,4,5,1},{2,3,4,1},{9,3,4,1},{3,2,3,1},{9,2,2,1},{4,1,2,1},{9,1,1,1},{5,0,1,1}}}
-- Thermal oval from the Meltagun stratagem icon reproduction by nvigneux:
-- https://github.com/nvigneux/Helldivers-2-Stratagems-icons-svg
M.MELTA={w=48,h=7,runs={{11,6,24,1},{4,5,14,1},{28,5,14,1},{1,4,18,1},{37,4,9,1},{0,3,25,1},{41,3,7,1},{1,2,19,1},{37,2,9,1},{4,1,13,1},{28,1,14,1},{10,0,25,1}}}
do
    local source=M.MELTA
    local upright={w=source.h,h=source.w,runs={}}
    for _,r in ipairs(source.runs) do
        upright.runs[#upright.runs+1]={source.h-r[2]-r[4],r[1],r[4],r[3]}
    end
    upright.scale=1.4
    M.MELTA=upright
end
-- Projectile orb and wake from the same icon collection's Epoch stratagem.
M.PLASMA={w=32,h=16,runs={{20,15,8,1},{17,14,12,1},{14,13,8,1},{26,13,4,1},{10,12,10,1},{28,12,3,1},{10,11,10,1},{25,11,2,1},{29,11,3,1},{10,10,9,1},{25,10,3,1},{29,10,3,1},{3,9,16,1},{25,9,2,1},{30,9,2,1},{1,8,17,1},{30,8,2,1},{7,7,11,1},{21,7,2,1},{30,7,2,1},{7,6,11,1},{22,6,1,1},{25,6,1,1},{30,6,2,1},{9,5,10,1},{24,5,3,1},{30,5,2,1},{13,4,6,1},{29,4,3,1},{13,3,7,1},{28,3,3,1},{13,2,9,1},{26,2,4,1},{15,1,14,1},{18,0,9,1}}}
-- Surface pattern from the Quasar gauge material texture, low mip.
M.CHARGE_TEXTURE={w=32,h=16,runs={{1,0,5,1},{7,0,1,1},{9,0,1,1},{11,0,1,1},{13,0,1,1},{15,0,1,1},{19,0,1,1},{22,0,2,1},{1,1,1,1},{3,1,3,1},{7,1,1,1},{9,1,1,1},{13,1,1,1},{31,1,1,1},{1,2,7,1},{9,2,1,1},{11,2,1,1},{13,2,1,1},{15,2,1,1},{19,2,1,1},{22,2,2,1},{27,2,1,1},{1,3,5,1},{7,3,1,1},{10,3,1,1},{13,3,1,1},{21,3,1,1},{31,3,1,1},{0,4,7,1},{8,4,1,1},{10,4,1,1},{13,4,1,1},{15,4,1,1},{17,4,1,1},{22,4,2,1},{30,4,2,1},{0,5,6,1},{8,5,1,1},{10,5,1,1},{13,5,1,1},{16,5,2,1},{21,5,1,1},{31,5,1,1},{0,6,9,1},{10,6,2,1},{13,6,3,1},{18,6,2,1},{22,6,4,1},{27,6,1,1},{29,6,3,1},{0,7,5,1},{6,7,3,1},{11,7,2,1},{15,7,3,1},{19,7,1,1},{21,7,1,1},{24,7,2,1},{27,7,1,1},{31,7,1,1},{0,8,5,1},{6,8,2,1},{9,8,3,1},{15,8,1,1},{17,8,3,1},{23,8,1,1},{27,8,1,1},{29,8,3,1},{0,9,6,1},{7,9,3,1},{12,9,2,1},{16,9,2,1},{19,9,1,1},{21,9,1,1},{23,9,1,1},{27,9,1,1},{31,9,1,1},{0,10,8,1},{9,10,2,1},{13,10,3,1},{17,10,3,1},{21,10,1,1},{23,10,1,1},{25,10,1,1},{27,10,1,1},{29,10,3,1},{0,11,6,1},{7,11,4,1},{12,11,2,1},{15,11,3,1},{19,11,3,1},{23,11,3,1},{27,11,1,1},{31,11,1,1},{0,12,8,1},{9,12,3,1},{13,12,3,1},{17,12,3,1},{21,12,3,1},{25,12,1,1},{27,12,1,1},{29,12,1,1},{31,12,1,1},{0,13,14,1},{15,13,3,1},{19,13,3,1},{23,13,3,1},{27,13,3,1},{31,13,1,1},{0,14,8,1},{9,14,3,1},{13,14,3,1},{17,14,3,1},{21,14,3,1},{25,14,3,1},{29,14,3,1},{0,15,14,1},{15,15,3,1},{19,15,3,1},{23,15,3,1},{27,15,3,1},{31,15,1,1}}}
-- Electric grenade shape from the native De-escalator stratagem texture.
M.DEESCALATOR={w=32,h=12,runs={{0,11,4,1},{0,10,10,1},{16,10,1,1},{22,10,7,1},{0,9,10,1},{16,9,1,1},{22,9,9,1},{0,8,10,1},{15,8,2,1},{22,8,9,1},{0,7,10,1},{14,7,6,1},{22,7,10,1},{0,6,10,1},{13,6,7,1},{22,6,10,1},{0,5,10,1},{13,5,6,1},{22,5,10,1},{0,4,10,1},{12,4,6,1},{22,4,10,1},{0,3,10,1},{15,3,3,1},{22,3,9,1},{0,2,10,1},{15,2,2,1},{22,2,9,1},{0,1,10,1},{15,1,1,1},{22,1,7,1},{0,0,4,1}}}
-- Projectile shape from the native Grenade Launcher stratagem texture.
M.GL_GRENADE={w=32,h=12,runs={{0,11,4,1},{0,10,14,1},{16,10,13,1},{0,9,14,1},{16,9,15,1},{0,8,14,1},{16,8,15,1},{0,7,14,1},{16,7,16,1},{0,6,14,1},{16,6,16,1},{0,5,14,1},{16,5,16,1},{0,4,14,1},{16,4,16,1},{0,3,14,1},{16,3,15,1},{0,2,14,1},{16,2,15,1},{0,1,14,1},{16,1,13,1},{0,0,4,1}}}
-- Grenade Pistol round: rimmed brass case and rounded olive HE projectile.
M.GRENADE_PISTOL_SHELL={w=32,h=12,runs={
    {0,0,3,12,{205,154,57}},{0,2,1,8,{255,221,133}},
    {3,1,11,10,{179,130,43}},{3,8,11,2,{239,196,102}},
    {3,1,11,2,{107,78,35}},{12,1,2,10,{241,190,77}},
    {14,2,11,8,{108,128,70}},{25,3,3,6,{108,128,70}},
    {28,4,3,4,{108,128,70}},{31,5,1,2,{108,128,70}},
    {15,8,9,1,{193,207,137}},{25,7,3,1,{193,207,137}},
    {15,2,10,1,{57,72,39}},{25,3,3,1,{57,72,39}},
    {16,2,2,8,{235,180,48}},{18,3,1,6,{72,85,45}}
}}
-- Railgun projectile and electromagnetic motif from its native stratagem texture.
M.RAILGUN={w=8,h=32,runs={{0,0,1,2},{0,5,1,4},{0,12,1,2},{0,15,1,9},{1,0,1,3},{1,4,1,6},{1,11,1,3},{1,15,1,15},{2,1,1,5},{2,8,1,5},{2,15,1,16},{3,2,1,3},{3,9,1,3},{3,15,1,17},{4,2,1,3},{4,9,1,3},{4,15,1,17},{5,1,1,5},{5,8,1,5},{5,15,1,16},{6,0,1,3},{6,4,1,6},{6,11,1,3},{6,15,1,15},{7,0,1,2},{7,5,1,4},{7,12,1,2},{7,15,1,9}}}
-- Compact electromagnetic penetrator, shown horizontally in the Railgun heading.
M.RAILGUN_DISPLAY={w=36,h=12,runs={
    {1,3,23,6,{86,129,143}},{0,2,3,8,{123,184,198}},
    {3,7,20,2,{211,240,243}},{3,3,20,1,{43,74,89}},
    {6,2,2,8,{68,211,232}},{12,2,2,8,{68,211,232}},
    {18,2,2,8,{68,211,232}},{23,4,5,4,{164,211,220}},
    {28,4,3,4,{164,211,220}},{31,5,3,2,{211,240,243}},
    {34,5.5,2,1,{68,211,232}},{2,5,2,2,{27,54,67}}
}}
-- Standard grenades share the game-derived 40 mm HE projectile.
M.GRENADE=M.GL_GRENADE
-- Warhead silhouette extracted from the native Leveller stratagem texture.
M.WARHEAD={w=32,h=10,runs={{1,8,2,1},{4,8,5,1},{18,8,7,1},{1,7,2,1},{5,7,5,1},{14,7,15,1},{1,6,3,1},{5,6,26,1},{2,5,29,1},{2,4,29,1},{1,3,3,1},{5,3,5,1},{11,3,20,1},{1,2,2,1},{5,2,4,1},{16,2,11,1},{1,1,2,1},{4,1,4,1},{20,1,2,1}}}
-- Rotate the Leveller warhead tip-up.
do
    local source=M.WARHEAD
    local upright={w=source.h,h=source.w,runs={}}
    for _,r in ipairs(source.runs) do
        upright.runs[#upright.runs+1]={source.h-r[2]-r[4],r[1],r[4],r[3]}
    end
    M.WARHEAD=upright
end
-- Crossbow bolt proportions from the user's reference: long vanes, narrow shaft, small tip.
M.BOLT={w=11,h=32,runs={
    {4,0,3,29},
    {3,1,1,11},{7,1,1,11},
    {2,2,1,8},{8,2,1,8},
    {1,3,1,5},{9,3,1,5},
    {3,12,1,2},{7,12,1,2},
    {3,27,5,2},{4,29,3,2},{5,31,1,1}
}}
-- Gas puff: rounded lobes with detached wisps.
M.GAS={w=24,h=20,runs={
    {7,0,10,1},{5,1,14,2},{3,3,18,2},{2,5,20,3},{3,8,18,2},
    {5,10,15,2},{8,12,10,2},{9,14,7,2},{10,16,5,1},
    {0,11,3,2},{1,13,2,1},{21,13,3,2},{20,16,2,2},{4,17,3,2}
}}
-- Native harpoongun projectile arrowheads.
M.SPEAR={w=32,h=14,runs={{14,12,2,1},{21,12,2,1},{15,11,3,1},{22,11,3,1},{16,10,4,1},{23,10,3,1},{16,9,5,1},{24,9,4,1},{17,8,6,1},{25,8,5,1},{1,7,23,1},{27,7,4,1},{2,6,22,1},{26,6,5,1},{17,5,5,1},{25,5,4,1},{16,4,5,1},{23,4,4,1},{15,3,4,1},{22,3,4,1},{15,2,2,1},{22,2,2,1},{14,1,2,1},{21,1,2,1}}}
local spear=M.SPEAR
local upright={w=spear.h,h=spear.w,runs={}}
for _,r in ipairs(spear.runs) do upright.runs[#upright.runs+1]={spear.h-r[2]-r[4],r[1],r[4],r[3]} end
M.SPEAR=upright
-- Coyote fire selectors keep native silhouettes with orange incendiary tips.
for _,mode in ipairs({'AUTO','SEMI'}) do
    local base=M[mode]
    local icon={w=base.w,h=base.h,runs={}}
    local tip_start=base.w-7
    for _,run in ipairs(base.runs) do
        local finish=run[1]+run[3]
        local body_width=math.max(0,math.min(finish,tip_start)-run[1])
        if body_width>0 then icon.runs[#icon.runs+1]={run[1],run[2],body_width,run[4],{218,172,78}} end
        local tip_x=math.max(run[1],tip_start)
        if finish>tip_x then icon.runs[#icon.runs+1]={tip_x,run[2],finish-tip_x,run[4],{255,133,45}} end
        if run[1]<tip_start and finish>tip_start then
            icon.runs[#icon.runs+1]={tip_start-1,run[2],1,run[4],{58,48,35}}
        end
    end
    M['FIRE_'..mode]=icon
end
-- Napalm rocket with an orange flame beside the warhead.
M.NAPALM_ROCKET={w=18,h=26,runs={}}
M.AIRBURST={w=20,h=20,runs={{8,8,4,4},{9,15,2,5},{9,0,2,5},{0,9,5,2},{15,9,5,2},{3,3,3,3},{14,14,3,3},{3,14,3,3},{14,3,3,3}}}
M.AIRBURST_CLUSTER={w=20,h=20,runs={{8,9,4,8},{9,17,2,3},{1,2,4,8},{2,10,2,3},{15,2,4,8},{16,10,2,3},{6,4,2,2},{12,4,2,2},{9,1,2,2}}}
for _,run in ipairs(M.ROCKET.runs) do
    M.NAPALM_ROCKET.runs[#M.NAPALM_ROCKET.runs+1]={run[1],run[2],run[3],run[4]}
end
local flame={255,133,45}
for _,run in ipairs({{12,14,5,3},{11,17,7,3},{12,20,5,2},{13,22,3,2},{14,24,1,2},{11,20,1,3},{17,19,1,3}}) do
    M.NAPALM_ROCKET.runs[#M.NAPALM_ROCKET.runs+1]={run[1],run[2],run[3],run[4],flame}
end
return M
