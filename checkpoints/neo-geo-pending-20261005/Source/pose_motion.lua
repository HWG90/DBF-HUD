-- Frame-rate independent rigid-pose smoothing; no engine userdata retained.
local M={}
local function quaternion(m)
    local a,b,c=m[1],m[6],m[11];local x,y,z,w;local t=a+b+c
    if t>0 then
        local s=math.sqrt(t+1)*2;w=s/4;x=(m[7]-m[10])/s;y=(m[9]-m[3])/s;z=(m[2]-m[5])/s
    elseif a>b and a>c then
        local s=math.sqrt(1+a-b-c)*2;w=(m[7]-m[10])/s;x=s/4;y=(m[5]+m[2])/s;z=(m[9]+m[3])/s
    elseif b>c then
        local s=math.sqrt(1+b-a-c)*2;w=(m[9]-m[3])/s;x=(m[5]+m[2])/s;y=s/4;z=(m[10]+m[7])/s
    else
        local s=math.sqrt(1+c-a-b)*2;w=(m[2]-m[5])/s;x=(m[9]+m[3])/s;y=(m[10]+m[7])/s;z=s/4
    end
    local n=math.sqrt(x*x+y*y+z*z+w*w);return {x/n,y/n,z/n,w/n}
end
local function blend(a,b,t)
    local dot=0;for i=1,4 do dot=dot+a[i]*b[i]end
    local sign=dot<0 and -1 or 1;dot=math.min(1,math.abs(dot))
    local u,v=1-t,t
    if dot<.9995 then local angle=math.acos(dot);local den=math.sin(angle);u=math.sin((1-t)*angle)/den;v=math.sin(t*angle)/den end
    local q={};local n=0;for i=1,4 do q[i]=a[i]*u+b[i]*sign*v;n=n+q[i]^2 end
    n=math.sqrt(n);for i=1,4 do q[i]=q[i]/n end;return q
end
-- Preserve forward direction while aligning the panel's up axis with world up.
function M.upright(m)
    local fx,fy,fz=m[5],m[6],m[7]
    local n=math.sqrt(fx*fx+fy*fy)
    if n<.05 then return m end -- Near vertical aim has no stable horizontal right.
    local rx,ry=fy/n,-fx/n
    return {rx,ry,0,0,fx,fy,fz,0,ry*fz,-rx*fz,rx*fy-ry*fx,0,m[13],m[14],m[15],1}
end
-- Pitch the panel's top toward the weapon's forward axis.
function M.forward_tilt(m,angle)
    local result={};for i=1,16 do result[i]=m[i] end
    local cosine,sine=math.cos(angle),math.sin(angle)
    for i=0,2 do
        result[5+i]=m[5+i]*cosine-m[9+i]*sine
        result[9+i]=m[5+i]*sine+m[9+i]*cosine
    end
    return result
end
function M.step(s,m,x,y,z,key,dt,c)
    dt=type(dt)=='number' and dt==dt and dt>=0 and dt or 1/60
    local q=quaternion(m)
    local jump=s.x and (s.x-x)^2+(s.y-y)^2+(s.z-z)^2>4
    if not s.q or s.key~=key or dt>.35 or jump then
        s.x,s.y,s.z,s.q=x,y,z,q
    else
        local a=c.world_position_smooth==0 and 1 or 1-math.exp(-dt/c.world_position_smooth)
        s.x,s.y,s.z=s.x+(x-s.x)*a,s.y+(y-s.y)*a,s.z+(z-s.z)*a
        local dx,dy,dz=s.x-x,s.y-y,s.z-z;local d=math.sqrt(dx*dx+dy*dy+dz*dz)
        if d>c.world_max_lag then local k=c.world_max_lag/d;s.x,s.y,s.z=x+dx*k,y+dy*k,z+dz*k end
        local t=c.world_rotation_smooth==0 and 1 or 1-math.exp(-dt/c.world_rotation_smooth)
        s.q=blend(s.q,q,t)
    end
    s.key=key
    local a,b,c,d=s.q[1],s.q[2],s.q[3],s.q[4]
    return {1-2*(b*b+c*c),2*(a*b+c*d),2*(a*c-b*d),0,
        2*(a*b-c*d),1-2*(a*a+c*c),2*(b*c+a*d),0,
        2*(a*c+b*d),2*(b*c-a*d),1-2*(a*a+b*b),0,s.x,s.y,s.z,1}
end
return M

