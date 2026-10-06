local M={}
function M.new(hud,root)
 local last,next_poll=nil,0;local self={}
 function self.poll()
  if (hud.clock or 0)<next_poll then return end;next_poll=(hud.clock or 0)+.25
  local f=io.open(root..'/HUD-control-request.tsv','rb');if not f then return end;local line=f:read(513);f:close();if #line>512 then return end
  local nonce,op=line:match('^([%w_%-]+)\t([a-z_]+)%s*$');if not nonce or nonce==last then return end
  local method=({reload_settings=hud.reload_settings,reload_art=hud.reload_panel_art,restore_art=hud.restore_panel_art,art_status=function()
   local stats=hud.panel_art_stats();local keys={};for k in pairs(stats)do keys[#keys+1]=k end;table.sort(keys);local fields={};for _,k in ipairs(keys)do fields[#fields+1]=k..'='..tostring(stats[k])end;return true,table.concat(fields,',')
  end})[op];if not method then return end;last=nonce
  local ok,a,b=pcall(method);ok=ok and a~=false;local result=tostring(b or a);local ack=io.open(root..'/HUD-control-ack.tsv','w');if ack then ack:write(nonce..'\t'..op..'\t'..tostring(ok)..'\t'..result:gsub('[\r\n\t]',' ')..'\n');ack:close()end
 end
 return self
end
return M
