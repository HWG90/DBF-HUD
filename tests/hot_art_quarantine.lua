HUD={}
local manager=dofile('src/hot_panel_art.lua').new({}, {},'test-root')
local original=io.open
local closed=false
io.open=function(path,mode)
 assert(path=='test-root/UPLOADS-QUARANTINED.txt' and mode=='rb')
 return {read=function()return 'native ownership not verified'end,close=function()closed=true end}
end
local ok,err=pcall(manager.reload)
io.open=original
assert(not ok and tostring(err):find('quarantined') and closed)
assert(not manager.stats().pending and manager.stats().retained_resources==0)
manager.close()
print('quarantine rejects reload before native initialization or allocations')
