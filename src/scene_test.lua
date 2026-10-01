-- WorldGUI display selection; archived mesh access remains for research.
local M={}
function M.mount(p,c)
    if c.placement_mode=='auto' and p.auto_mount then return p.auto_mount.x,p.auto_mount.y,p.auto_mount.z end
    if p.first_person then return c.fp_mount_x,c.fp_mount_y,c.fp_mount_z+.2 end
    if p.left_shoulder then return c.left_mount_x,c.left_mount_y,c.left_mount_z+.2 end
    return c.mount_x,c.mount_y,c.mount_z+.2
end
function M.new(sr,log,side)
    if not side then
        local front,back=M.new(sr,log,1),M.new(sr,log,-1)
        local overlay=HUD.world_probe.new(sr,log,true)
        local depth_overlay=HUD.world_probe.new(sr,log,false)
        local active_mode
        return {
            draw=function(p,c,target,dt,aspect,commands)
                local mode=c.occlusion_mode or (c.hud_occlusion~=false and 'gui_depth' or 'gui')
                if mode=='mesh' then mode='gui_depth' end -- archived selection
                if active_mode~=mode then
                    front.release();back.release();overlay.release();depth_overlay.release()
                    active_mode=mode
                    log('HUD occlusion mode '..mode)
                end
                do
                    if not commands then overlay.release();depth_overlay.release();return end
                    local centered=HUD.world_style.prepare(commands,p,c)
                    if mode=='gui_depth' then return depth_overlay.draw(p,c,centered,dt) else return overlay.draw(p,c,centered,dt) end
                end
            end,
            release=function() overlay.release();depth_overlay.release();front.release();back.release();active_mode=nil end
        }
    end
    return HUD.archived_mesh.new(sr,log,side)
end
function M.fullbright(sr,log)return HUD.archived_mesh.fullbright(sr,log)end
return M
