-- Scale only live weapon text, retaining each measured visual center.
local M={}
function M.apply(commands,cfg,measure)
    local factor=cfg.font_scale or 1
    if factor==1 then return commands end
    measure=measure or HUD.font.measure
    local out={}
    for _,v in ipairs(commands)do
        if v.type=='text' and not v.font_scale_applied then
            local q={};for k,value in pairs(v)do q[k]=value end
            local l,b,r,t=measure(v.text,v.size,v.font,true)
            local cx,cy=v.x+(l+r)/2,v.y+(b+t)/2
            q.size=v.size*factor;l,b,r,t=measure(v.text,q.size,v.font,true)
            q.x,q.y=cx-(l+r)/2,cy-(b+t)/2;q.font_scale_applied=true
            out[#out+1]=q
        else out[#out+1]=v end
    end
    return out
end
return M
