-- Exact critically damped spring; all coordinates are 1080p reference pixels.
local M = {}
local function finite(x) return type(x)=='number' and x==x and math.abs(x)<1e8 end
function M.new() return {x=0,y=0,vx=0,vy=0,ready=false} end
function M.axis(x,v,target,dt,omega)
    local delta=x-target
    local j=v+omega*delta
    local e=math.exp(-omega*dt)
    return target+(delta+j*dt)*e,(v-omega*j*dt)*e
end
function M.step(s, target, dt, cfg)
    local x,y=0,0
    if target and finite(target.x) and finite(target.y) then
        x,y=target.x*cfg.follow,target.y*cfg.follow
    end
    local radius=math.sqrt(x*x+y*y)
    if radius>cfg.travel then x,y=x*cfg.travel/radius,y*cfg.travel/radius end
    if not finite(dt) or dt<0 then dt=0 end
    if not s.ready or dt>0.35 then s.x,s.y,s.vx,s.vy=x,y,0,0; s.ready=true end
    local omega=4.75/math.max(0.04,cfg.settle)
    s.x,s.vx=M.axis(s.x,s.vx,x,dt,omega)
    s.y,s.vy=M.axis(s.y,s.vy,y,dt,omega)
    -- Moving targets can retain momentum; enforce the hard travel envelope too.
    radius=math.sqrt(s.x*s.x+s.y*s.y)
    if radius>cfg.travel then
        s.x,s.y=s.x*cfg.travel/radius,s.y*cfg.travel/radius
        local outward=(s.vx*s.x+s.vy*s.y)/(cfg.travel*cfg.travel)
        if outward>0 then s.vx,s.vy=s.vx-outward*s.x,s.vy-outward*s.y end
    end
    return s.x,s.y
end
-- Limit lag relative to the moving weapon, never relative to screen center.
function M.attach(s,target,dt,cfg)
    if not finite(dt) or dt<0 then dt=0 end
    if not s.ready or dt>.35 then s.x,s.y,s.vx,s.vy=target.x,target.y,0,0;s.ready=true end
    local omega=4.75/cfg.weapon_settle
    s.x,s.vx=M.axis(s.x,s.vx,target.x,dt,omega)
    s.y,s.vy=M.axis(s.y,s.vy,target.y,dt,omega)
    local dx,dy=s.x-target.x,s.y-target.y;local d=math.sqrt(dx*dx+dy*dy)
    if d>cfg.weapon_lag then
        s.x,s.y=target.x+dx*cfg.weapon_lag/d,target.y+dy*cfg.weapon_lag/d
        s.vx,s.vy=0,0
    end
    return s.x,s.y
end
return M
