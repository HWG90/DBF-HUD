-- Weapon/view placement. Native readers remain in pose and camera_mode.
-- Sight anchors update live; missing nodes use a stable per-view root base.
local M={}
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
