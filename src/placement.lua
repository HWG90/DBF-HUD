-- Weapon/view placement. Native readers remain in pose and camera_mode.
-- Sight anchors update live; only the legacy root fallback caches a screen seed.
local M={}
function M.update(self,pose,projection,latest_raw,log)
    self.profile_scale=1
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
            elseif not mount and projection.camera_matrix and self.clock>=self.auto_sample_after then
                mount=HUD.projection.auto_mount(projection.camera_matrix,self.weapon_pose,
                    projection.camera_fov,projection.camera_aspect,projection.camera_near)
                -- Keep the seed close to the gun; no model-clearance claim yet.
                mount.x=math.max(-.8,math.min(.8,mount.x))
                mount.y=math.max(-.15,math.min(.4,mount.y))
                mount.z=math.max(-.2,math.min(.4,mount.z))
                local side=self.first_person and -1 or 1
                mount.x=side*math.max(.13,math.min(.18,math.abs(mount.x)+.05))
                mount.y=math.max(-.05,math.min(.10,mount.y*.4))
                mount.z=math.max(.03,math.min(.10,mount.z*.4))
                if self.first_person then mount.x=-.12;mount.y=.35;mount.z=.22 end
                self.auto_mounts[view]=mount
            end
            local profile=self.weapon_clearance[self.weapon_pose.resource_hex]
            local profile_view=view_parity and 'right' or (self.first_person and ('first_'..self.config.fp_auto_side) or view)
            local correction=profile and profile[profile_view]
            self.profile_scale=correction and correction.scale or 1
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
            self.weapon_pose.auto_mount=mount
        else
            self.auto_equip=nil;self.auto_mounts=nil
        end
    end
end
return M
