-- Weapon/view placement. Native readers remain in pose and camera_mode.
-- Sight anchors update live; missing nodes use a stable per-view root base.
local M={}
local function finite(v)return type(v)=='number'and v==v and math.abs(v)<math.huge end
local function clamp(v,a,b)return math.max(a,math.min(b,v))end
-- Explicit recovery takes one camera snapshot. The resulting transform remains
-- weapon-local, so subsequent frames use ordinary weapon following, not a clamp.
function M.recover(p,c,commands,camera,fov,aspect,settings,current_scale)
    assert(p and type(p.matrix)=='table'and camera,'Camera and weapon pose are unavailable')
    assert(settings.anchor_mode=='world'and settings.placement_mode=='auto','Recovery requires automatic WorldGUI placement')
    assert(finite(fov)and fov>.05 and fov<3.1 and finite(aspect)and aspect>.1 and aspect<10,'Camera projection is unavailable')
    local root=p.matrix
    for _,m in ipairs({root,camera})do
        for i=1,16 do assert(finite(m[i]),'Invalid recovery pose')end
        for _,a in ipairs({1,5,9})do
            assert(math.abs(m[a]^2+m[a+1]^2+m[a+2]^2-1)<.05,'Recovery requires a rigid pose')
        end
        for _,pair in ipairs({{1,5},{1,9},{5,9}})do
            local a,b=pair[1],pair[2]
            assert(math.abs(m[a]*m[b]+m[a+1]*m[b+1]+m[a+2]*m[b+2])<.05,'Recovery requires perpendicular pose axes')
        end
    end
    local function bounds(cfg)
        local left,bottom,right,top=math.huge,math.huge,-math.huge,-math.huge
        for _,v in ipairs(HUD.world_style.prepare(commands,p,cfg))do
            local a,b,d,e=v.x,v.y,v.x+(v.w or 0),v.y+(v.h or 0)
            if v.type=='text'then
                local x,y,w,h=HUD.font.measure(v.text,v.size,v.font,true)
                a,b,d,e=v.x+x,v.y+y,v.x+w,v.y+h
            end
            if v.quad then for _,point in ipairs(v.quad)do
                a,b,d,e=math.min(a,point[1]),math.min(b,point[2]),math.max(d,point[1]),math.max(e,point[2])
            end end
            left,bottom,right,top=math.min(left,a),math.min(bottom,b),math.max(right,d),math.max(top,e)
        end
        assert(finite(left)and right>left and top>bottom,'HUD bounds are unavailable')
        return left/1000,bottom/1000,right/1000,top/1000
    end
    local l,b,r,t=bounds(c);local tan=math.tan(fov*.5);local depth=.65
    current_scale=current_scale or 1
    -- Keep the recovered face beside the crosshair with ample viewport margin.
    -- Reduce only this view's saved size if its current dimensions cannot fit.
    local factor=math.min(1,.96*depth*tan*aspect/(r-l),1.28*depth*tan/(t-b))
    local scale=clamp(current_scale*factor,.05,3)
    local fitted={};for k,v in pairs(c)do fitted[k]=v end
    fitted.scale=c.scale*scale/current_scale
    l,b,r,t=bounds(fitted)
    depth=math.max(depth,(r-l)/(.96*tan*aspect),(t-b)/(1.28*tan))
    local right=.3*depth*tan*aspect-(l+r)/2
    local up=-(b+t)/2
    local target={}
    for j=1,3 do target[j]=camera[12+j]+camera[j]*right+camera[4+j]*depth+camera[8+j]*up end
    -- Invert the actual root basis rather than assuming perfectly unit axes.
    local a,d,g=root[1],root[2],root[3]
    local b0,e,h=root[5],root[6],root[7]
    local c0,f,i=root[9],root[10],root[11]
    local det=a*(e*i-f*h)-b0*(d*i-f*g)+c0*(d*h-e*g)
    assert(det>.9 and det<1.1,'Recovery pose handedness is invalid')
    local dx,dy,dz=target[1]-p.x,target[2]-p.y,target[3]-p.z
    local x=((e*i-f*h)*dx+(c0*h-b0*i)*dy+(b0*f-c0*e)*dz)/det
    local y=((f*g-d*i)*dx+(a*i-c0*g)*dy+(c0*d-a*f)*dz)/det
    local z=((d*h-e*g)*dx+(b0*g-a*h)*dy+(a*e-b0*d)*dz)/det
    local first=p.first_person
    local base=first and {x=settings.fp_auto_side=='right'and .12 or -.12,y=.45,z=.01}or{x=.16,y=.10,z=.04}
    local global_scale=settings.scale or 1
    local offset={x=x/global_scale-base.x,y=y-.0762-base.y,z=z/global_scale-base.z,scale=scale,attach_point='root'}
    for _,axis in ipairs({'x','y','z'})do assert(finite(offset[axis])and math.abs(offset[axis])<=2,'Recovery exceeds the two-metre weapon placement range')end
    -- panel_pose applies roll, pitch, then yaw. Invert that exact convention.
    local basis=c.keep_hud_upright and HUD.pose_motion.upright(root)or root
    local function dot(a0,b1)return basis[a0]*camera[b1]+basis[a0+1]*camera[b1+1]+basis[a0+2]*camera[b1+2]end
    local pitch=math.asin(clamp(-dot(5,9),-1,1))
    local roll,yaw
    if math.abs(math.cos(pitch))>1e-6 then
        roll=math.atan2(-dot(1,9),dot(9,9));yaw=math.atan2(dot(5,1),dot(5,5))
    else roll=math.atan2(dot(9,1),dot(1,1));yaw=0 end
    offset.rotation,offset.pitch,offset.yaw=math.deg(roll),math.deg(pitch),math.deg(yaw)
    return offset,{depth=depth,target=target,margin=.08}
end
function M.apply_recovery(self,offset)
    local resource=self.weapon_pose and self.weapon_pose.resource_hex
    local editor=self.layout_editor
    assert(resource and editor,'Equipped weapon editor is unavailable')
    if not editor.active or editor.resource~=resource then
        if not editor.bind()then return false,editor.status end
    end
    editor.set_view(self.first_person)
    local view=self.first_person and('first_'..self.config.fp_auto_side)or'right'
    self.weapon_clearance[resource]=self.weapon_clearance[resource]or{}
    self.weapon_clearance[resource][view]=offset
    self.auto_mounts={};self.hybrid_scale_weapon=nil;self.hybrid_scale_depth=nil
    editor.status='HUD brought into view for this weapon/view; F7 saves, F8 restores'
    return true,editor.status
end
function M.update(self,pose,projection,latest_raw,log)
    self.profile_scale=1;self.profile_rotation=0;self.profile_pitch=0;self.profile_yaw=0
    if self.weapon_pose then
        self.weapon_pose.first_person=self.first_person
        self.weapon_pose.left_shoulder=false
        self.weapon_pose.auto_mount=nil
        self.weapon_pose.camera_facing=nil
        if self.config.placement_mode=='auto' then
            local equip=tostring(self.weapon_pose.id)..':'..tostring(self.weapon_pose.candidate)..':'..tostring(latest_raw.avatar_unit_ref)
            if self.auto_equip~=equip then self.auto_equip=equip;self.auto_mounts={};self.auto_view=nil end
            local view=self.first_person and 'first' or 'right'
            if self.auto_view~=view then self.auto_view=view;self.auto_sample_after=self.clock+.4 end
            local mount=self.auto_mounts[view]
            local sight=self.weapon_pose.sight
            if self.weapon_pose.attach_point=='root' then sight={x=0,y=0,z=0} end
            local view_parity=sight and latest_raw.energy_icon=='LASER' and not self.weapon_pose.attach_point
            self.placement_view_parity=not not view_parity
            if sight then
                -- Named anchors need neither camera settling nor cached screen seeds.
                if self.first_person and not view_parity then
                    mount={x=sight.x+(self.config.fp_auto_side=='right' and .12 or -.12),y=sight.y+.45,z=sight.z+.01}
                else
                    mount={x=sight.x+.16,y=sight.y+.10,z=sight.z+.04}
                end
            else
                -- Missing named nodes must not seed placement from the camera.
                -- Apply a stable per-view root base immediately after reload.
                if self.first_person then mount={x=-.12,y=.35,z=.22}
                else mount={x=.18,y=.05,z=.10} end
            end
            local profile=self.weapon_clearance[self.weapon_pose.resource_hex]
            local profile_view=self.first_person and ('first_'..self.config.fp_auto_side) or view
            local correction=profile and (profile[profile_view] or (view_parity and profile.right))
            local identity=tostring(self.weapon_pose.resource_hex)..':'..profile_view..':'..tostring(self.weapon_pose.attach_point)
            if identity~=self.applied_profile_identity then
                self.applied_profile_identity=identity
                log('PLACEMENT_PROFILE weapon='..tostring(self.weapon_pose.resource_hex)..' view='..profile_view..' attachment='..tostring(self.weapon_pose.attach_point)..' source='..tostring(self.camera_mode_status))
            end
            self.profile_scale=correction and correction.scale or 1
            self.profile_rotation=correction and correction.rotation or 0
            self.profile_pitch=correction and correction.pitch or 0
            self.profile_yaw=correction and correction.yaw or 0
            if mount and correction then
                mount={x=mount.x+(correction.x or 0),y=mount.y+(correction.y or 0),z=mount.z+(correction.z or 0)}
            end
            if mount then
                -- Scale clearance around the sight, not the weapon root. Keep
                -- tuned forward depth independent of the panel's size.
                local anchor=sight or {x=0,z=0}
                local scale=self.config.scale or 1
                mount={x=anchor.x+(mount.x-anchor.x)*scale,y=mount.y,
                    z=anchor.z+(mount.z-anchor.z)*scale}
            end
            local source=sight and (self.weapon_pose.sight and 'attachment' or 'root') or 'root-fallback'
            local signature=identity..':'..source..':'..tostring(mount~=nil)
            if signature~=self.applied_mount_signature then
                self.applied_mount_signature=signature
                log(string.format('PLACEMENT_MOUNT weapon=%s view=%s source=%s bone=%s correction=%.6f,%.6f,%.6f mount=%s scale=%.4f root_debug=%s',
                    tostring(self.weapon_pose.resource_hex),profile_view,source,tostring(self.weapon_pose.sight and self.weapon_pose.sight.index),
                    correction and correction.x or 0,correction and correction.y or 0,correction and correction.z or 0,
                    mount and string.format('%.6f,%.6f,%.6f',mount.x,mount.y,mount.z) or 'pending',self.profile_scale,tostring(self.config.debug_sight_root_orientation)))
            end
            self.weapon_pose.auto_mount=mount
        else
            self.auto_equip=nil;self.auto_mounts=nil
        end
    end
end
return M
