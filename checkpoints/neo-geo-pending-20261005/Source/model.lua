-- Normalize providers into one presentation contract; unknown is never zero.
local M={}
local function count(x)
    if type(x)=='number' and x==x and x>=0 and x<=100000 then return math.floor(x) end
end
function M.normalize(raw)
    if not raw then return nil end
    local m={id=raw.id,unit_ref=raw.unit_ref,avatar_unit_ref=raw.avatar_unit_ref,resource_hex=raw.resource_hex,kind=raw.kind,reserve=count(raw.reserve),reserve_kind=raw.reserve_kind,
        alternate=raw.alternate, ammo_slot=raw.ammo_slot, projectile_type=raw.projectile_type, ammo_mode=raw.ammo_mode, fire_mode=raw.fire_mode, safety_mode=raw.safety_mode, charge_fraction=raw.charge_fraction, epoch_charge_fraction=raw.epoch_charge_fraction, loyalist_charge_fraction=raw.loyalist_charge_fraction, purifier_charge_fraction=raw.purifier_charge_fraction, charge_seconds=raw.charge_seconds, charge_warning=raw.charge_warning==true, energy_icon=raw.energy_icon, ammo_icon=raw.ammo_icon, charge_ready=raw.charge_ready==true, lowered=raw.lowered, label=raw.label or 'AMMO'}
    if raw.resource_hex=='6cfcc7f8801a0266' and type(raw.melta_charge_level)=='number' and raw.melta_charge_level==raw.melta_charge_level and raw.melta_charge_level>=0 and raw.melta_charge_level<=10 then m.melta_charge_level=raw.melta_charge_level end
    if raw.rpm_selectable==true and type(raw.rpm)=='number' and raw.rpm==raw.rpm and raw.rpm>=1 and raw.rpm<=10000 then
        m.rpm=math.floor(raw.rpm+.5)
    end
    if raw.kind=='heat' then
        if type(raw.heat)~='number' or raw.heat~=raw.heat or raw.heat<0 or raw.heat>1 then return nil end
        m.value=math.floor(raw.heat*100+0.5); m.fraction=raw.heat
        m.label='HEAT'; m.suffix='%'
        m.state=raw.locked and 'VENT' or (raw.heat>=0.85 and 'HOT' or 'READY')
        m.warning=raw.locked or raw.heat>=0.85
        if raw.resource_hex=='35a61296619cc47e' and type(raw.quasar_charge_fraction)=='number' and raw.quasar_charge_fraction==raw.quasar_charge_fraction and raw.quasar_charge_fraction>=0 and raw.quasar_charge_fraction<=1 then
            m.quasar_charge_verified=true
            if not raw.locked then
                m.fraction=raw.quasar_charge_fraction;m.value=math.floor(m.fraction*100+.5)
                m.state='READY';m.warning=false
            end
        end
    elseif raw.kind=='infinite' then
        m.value='--'; m.label='ENERGY'; m.state='READY'; m.fraction=1
    else
        m.value=count(raw.rounds)
        if not m.value then return nil end
        m.capacity=count(raw.capacity)
        -- Verified reader already includes the chamber in rounds; never add or subtract it here.
        if (raw.kind=='magazine' or raw.kind=='rounds') and raw.chamber_supported==true and raw.chamber_rounds==1 and m.capacity and m.value==m.capacity+1 then m.chamber_bonus=1 end
        if m.capacity and m.capacity>0 then m.fraction=math.min(1,m.value/m.capacity) end
        m.state=m.value==0 and (raw.reloadable==false and 'SPENT' or 'EMPTY') or 'READY'
        m.warning=m.value==0 or (m.fraction and m.fraction<=0.2) or false
        if m.resource_hex=='a8cffb316f0b5c5f' then
            m.warning=m.value<=3
            m.reload_reminder=m.value<=5
        end
    end
    return m
end
return M

