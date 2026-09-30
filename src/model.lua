-- Normalize providers into one presentation contract; unknown is never zero.
local M={}
local function count(x)
    if type(x)=='number' and x==x and x>=0 and x<=100000 then return math.floor(x) end
end
function M.normalize(raw)
    if not raw then return nil end
    local m={id=raw.id,unit_ref=raw.unit_ref,avatar_unit_ref=raw.avatar_unit_ref,resource_hex=raw.resource_hex,kind=raw.kind,reserve=count(raw.reserve),reserve_kind=raw.reserve_kind,
        alternate=raw.alternate, lowered=raw.lowered, label=raw.label or 'AMMO'}
    if raw.kind=='heat' then
        if type(raw.heat)~='number' or raw.heat~=raw.heat or raw.heat<0 or raw.heat>1 then return nil end
        m.value=math.floor(raw.heat*100+0.5); m.fraction=raw.heat
        m.label='HEAT'; m.suffix='%'
        m.state=raw.locked and 'VENT' or (raw.heat>=0.85 and 'HOT' or 'READY')
        m.warning=raw.locked or raw.heat>=0.85
    elseif raw.kind=='infinite' then
        m.value='--'; m.label='ENERGY'; m.state='READY'; m.fraction=1
    else
        m.value=count(raw.rounds)
        if not m.value then return nil end
        m.capacity=count(raw.capacity)
        if m.capacity and m.capacity>0 then m.fraction=math.min(1,m.value/m.capacity) end
        m.state=m.value==0 and (raw.reloadable==false and 'SPENT' or 'EMPTY') or 'READY'
        m.warning=m.value==0 or (m.fraction and m.fraction<=0.2) or false
    end
    return m
end
return M
