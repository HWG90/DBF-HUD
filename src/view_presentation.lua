-- Presentation only: both views consume the same normalized weapon model.
local M={}
function M.select(native_first,aiming,override)
    if override=='practical' then return 'third','forced practical presentation' end
    if override=='weapon_specific' then return 'first','forced weapon-specific presentation' end
    if native_first==nil or aiming==nil then return 'third','camera state unavailable; practical fallback' end
    if native_first==true and aiming==true then return 'first','game first-person toggle and active aiming' end
    return 'third','game third-person/shoulder view'
end
local function number(v)
    if type(v)=='number' and v==v and v>=0 and v<100001 then return math.floor(v) end
end
local function fraction(v)
    return type(v)=='number' and v==v and v>=0 and v<=1 and v or nil
end
function M.readouts(m,cfg)
    local loaded=number(m.value)
    local label=m.kind=='heat' and (m.quasar_charge_verified and 'CHARGE' or 'HEAT') or (m.label=='FUEL' and 'FUEL' or 'LOADED')
    local value=loaded and tostring(loaded) or (m.kind=='infinite' and '--' or '?')
    if m.kind=='heat' then value=value..'%' end
    local reserve=number(m.reserve)
    local mode=m.safety_mode or m.fire_mode or m.ammo_mode or '--'
    local state=m.state or '--';local progress=m.kind=='heat' and fraction(m.fraction) or nil
    local charge=fraction(m.epoch_charge_fraction) or fraction(m.loyalist_charge_fraction) or fraction(m.purifier_charge_fraction)
    if m.safety_mode then
        local rail=HUD.layout.railgun_charge(m.safety_mode,m.charge_fraction,m.charge_seconds,cfg.railgun_release_margin_ms,m.charge_age,m.frame_delay)
        if rail then charge=rail.fraction;if rail.release or rail.limit then state='RELEASE' end end
    else charge=charge or fraction(m.charge_fraction) end
    if m.df_ejector_open==true or m.reloading==true then state='RELOADING'
    elseif charge and (charge>0 or m.charge_ready) then
        progress=charge
        if state~='RELEASE' then state=(m.charge_ready or charge>=1) and 'CHARGED' or ('CHARGE '..math.floor(charge*100+.5)..'%') end
    end
    return {loaded=value,label=label,reserve=reserve and tostring(reserve) or '?',reserve_unit=m.reserve_kind or 'RESERVE',mode=mode,state=state,progress=progress,warning=m.warning==true or state=='RELEASE'}
end
function M.compose(m,x,y,s,opacity,cfg)
    local r=M.readouts(m,cfg);local model={};for k,v in pairs(m)do model[k]=v end
    local name=(HUD.weapon_names or {})[m.resource_hex]or m.label or 'WEAPON'
    model.short_name=name:match('^%S+')or 'WEAPON';model.value_readout=r.loaded
    if m.kind=='heat' or m.kind=='infinite' then model.capacity_readout=r.label end
    model.reserve_readout=r.reserve..' '..(m.reserve_kind or 'RES')
    model.reload_status=r.state~='READY'and r.state or (m.chamber_rounds==1 and 'CHAMBERED'or nil)
    model.ammo_name=m.ammo_mode
    local semantics=m.reserve_kind=='PACK'and 'backpack_feed'or m.state=='SPENT'and 'expendable'or nil
    if m.resource_hex=='72170a55a1f37ff1' then
        semantics='double_freedom';model.shell_states={}
        for side=1,2 do
            local spent=m.df_shell_spent and m.df_shell_spent[side]
            model.shell_states[side]=spent and 'spent'or type(m.value)=='number'and m.value>=3-side and 'loaded'or 'unknown'
        end
    end
    local config={font=cfg.font,font_scale=cfg.font_scale or 1,text_color=HUD.config.rgb(cfg.text_color),accent_color=r.warning and HUD.config.rgb(cfg.heat_red)or HUD.config.rgb(cfg.decoration_color),backing_color=HUD.config.rgb(cfg.background_color),backing_opacity=cfg.third_person_opacity or .22,ammo_semantics=semantics}
    local function measure(t,size)local l,b,right=HUD.font.measure(t,size,cfg.font,true);return right-l end
    local w,h=64*s,86*s;local raw=HUD.simple_vertical.compose(model,0,0,w,h,opacity,config,measure)
    local out={{type='panel',x=x,y=y,w=w,h=h,c={0,0,0},a=0,frosted=false,presentation='third',world_reference_width=128*s}}
    for _,v in ipairs(raw)do
        if v.type=='text'then local l,b,right,top=HUD.font.measure(v.text,v.size,v.font,true);v.y=y+h-v.y-top;v.font_scale_applied=true
        else v.y=y+h-v.y-v.h end
        v.x=x+v.x;v.presentation='third';out[#out+1]=v
    end
    return out
end
return M
