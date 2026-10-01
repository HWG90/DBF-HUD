-- Weapon/view placement. Native readers remain in pose and camera_mode.
-- Sight anchors update live; only the legacy root fallback caches a screen seed.
local M={}
function M.update(self,pose,projection,latest_raw,log)
    if self.weapon_pose then
        self.weapon_pose.first_person=self.first_person
        self.weapon_pose.left_shoulder=self.left_shoulder
        self.weapon_pose.auto_mount=nil
        self.weapon_pose.camera_facing=nil
        if self.config.placement_mode=='auto' then
            local equip=tostring(self.weapon_pose.id)..':'..tostring(self.weapon_pose.candidate)..':'..tostring(latest_raw.avatar_unit_ref)
            if self.auto_equip~=equip then self.auto_equip=equip;self.auto_mounts={};self.auto_view=nil end
            local view=self.first_person and 'first' or (self.left_shoulder and 'left' or 'right')
            if self.auto_view~=view then self.auto_view=view;self.auto_sample_after=self.clock+.4 end
            local mount=self.auto_mounts[view]
            local sight=self.weapon_pose.sight
            if sight then
                -- Named anchors need neither camera settling nor cached screen seeds.
                if self.first_person then
                    mount={x=sight.x+(self.config.fp_auto_side=='right' and .12 or -.12),y=sight.y+.45,z=sight.z+.01}
                elseif self.left_shoulder then
                    mount={x=sight.x+.16,y=sight.y-.25,z=sight.z+.12}
                    if self.weapon_pose.resource_hex=='05e4e5c2db6e44a2' then
                        mount.x=mount.x+.05;mount.y=mount.y-.08
                    end
                    local player=pose.shoulder(latest_raw)
                    if self.config.debug_logging and self.clock>=(self.next_shoulder_log or 0) then
                        log('SHOULDER_ANCHOR '..tostring(pose.shoulder_status));self.next_shoulder_log=self.clock+1
                    end
                    if player then
                        local shoulder_owner=tostring(player.id)..':'..tostring(player.candidate)
                        if self.shoulder_owner~=shoulder_owner then
                            self.shoulder_owner=shoulder_owner;self.shoulder_rest=player.sight
                        end
                        -- Character-relative anchor is sampled once per avatar;
                        -- bone animation no longer drives the mounted position.
                        local a=self.shoulder_rest;local pm=player.matrix;local wm=self.weapon_pose.matrix
                        local delta={}
                        for j=1,3 do
                            delta[j]=pm[12+j]+pm[j]*a.x+pm[4+j]*a.y+pm[8+j]*a.z-wm[12+j]
                            local basis=projection.camera_matrix or pm
                            delta[j]=delta[j]+basis[j]*.06-basis[4+j]*.20+basis[8+j]*.12
                        end
                        for axis,k in ipairs({1,5,9}) do
                            local v=0;for j=1,3 do v=v+delta[j]*wm[k+j-1] end
                            mount[({'x','y','z'})[axis]]=v
                        end
                        self.weapon_pose.camera_facing=projection.camera_matrix
                    end
                else
                    mount={x=sight.x+.16,y=sight.y+.10,z=sight.z+.04}
                end
            elseif not mount and projection.camera_matrix and self.clock>=self.auto_sample_after then
                mount=HUD.projection.auto_mount(projection.camera_matrix,self.weapon_pose,
                    projection.camera_fov,projection.camera_aspect,projection.camera_near)
                -- Keep the seed close to the gun; no model-clearance claim yet.
                mount.x=math.max(-.8,math.min(.8,mount.x))
                mount.y=math.max(-.15,math.min(.4,mount.y))
                mount.z=math.max(-.2,math.min(.4,mount.z))
                local side=(self.first_person or self.left_shoulder) and -1 or 1
                mount.x=side*math.max(.13,math.min(.18,math.abs(mount.x)+.05))
                if self.left_shoulder and not self.first_person then mount.x=mount.x-.40 end
                mount.y=math.max(-.05,math.min(.10,mount.y*.4))
                mount.z=math.max(.03,math.min(.10,mount.z*.4))
                if self.left_shoulder and not self.first_person then mount.y=mount.y-.15;mount.z=mount.z+.08 end
                if self.first_person then mount.x=-.12;mount.y=.35;mount.z=.22 end
                self.auto_mounts[view]=mount
            end
            local profile=self.weapon_clearance[self.weapon_pose.resource_hex]
            local profile_view=self.first_person and ('first_'..self.config.fp_auto_side) or view
            local correction=profile and profile[profile_view]
            if mount and correction then
                mount={x=mount.x+(correction.x or 0),y=mount.y+(correction.y or 0),z=mount.z+(correction.z or 0)}
            end
            self.weapon_pose.auto_mount=mount
        else
            self.auto_equip=nil;self.auto_mounts=nil
        end
    end
end
return M
