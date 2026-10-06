local menu=assert(loadfile('src/menu.lua'))()
local function c(id)return {id=id,on_change=function()end}end
local debug=c('debug_hud_timing');local trial=c('render_sync_trial');local scale=c('hud_scale');local reload=c('reload_hot_panel_art')
local s={pages={{id='appearance',controls={{id='global_settings',children={c('family')}}}},{id='developer',controls={debug,trial,scale,reload}},{id='weapon_appearance',controls={}}}}
menu.group_settings(s)
assert(s.pages[1].controls[1].collapsed and s.pages[1].controls[1].children[2]==scale)
assert(s.pages[2].controls[1]==debug)
local e=s.pages[2].controls[2];assert(e.id=='developer_experimental' and e.collapsed and e.children[1]==trial and e.children[2]==reload)
print('PASS explicit global/developer/experimental classification preserves original controls')
