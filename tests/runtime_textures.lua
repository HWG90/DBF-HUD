local M=dofile('src/runtime_textures.lua')
local checks=0
local function check(value,message)assert(value,message);checks=checks+1 end
local function image(value,path)return{format='RGBA8',width=1,height=1,row_pitch=4,rgba=string.rep(value,4),path=path}end
local original=image('O');local candidate=image('C')
local store={bytes=0,resources={},claims={}}
local phase=false;local valid=true;local writes={};local allocations=0;local fail=false
local adapter={in_render_phase=function()return phase end,valid=function()return valid end,
    ready=function()return true end,
    upload=function(i,r)allocations=allocations+1;r.resource=i.rgba end,
    bind=function(_,r)writes[#writes+1]=r;if fail then fail=false;error('refresh failed after binding')end end}
local a=M.new(adapter,store);a.register('wall',{},original);a.swap('wall',candidate)
check(allocations==0 and #writes==0,'queue must not perform native work')
check(not pcall(a.step),'must reject update-phase native work');phase=true;a.step()
check(allocations==2 and writes[1]=='CCCC','original and candidate retained before binding')
a.swap('wall',candidate);a.step();check(allocations==2,'unchanged reload must not allocate')
a.restore('wall');a.step();check(writes[#writes]=='OOOO','original pixels restored')
a.swap('wall',image('D'));fail=true;a.step();check(a.targets.wall.restore,'partial setter failure must queue rollback')
a.step();check(writes[#writes]=='OOOO' and not a.targets.wall.active,'failed refresh rolled back next render')
local b=M.new(adapter,store);check(not pcall(b.register,'wall',{},original),'old owner must retain target claim')
a.close();check(a.step()==true,'cleanup completes only after restoration');b.register('wall',{},original)
b.swap('wall',candidate);b.step();valid=false;local previous=#writes;b.close()
check(b.step()==true and #writes==previous,'retired unit must never receive stale restoration')
check(#store.resources==5 and store.bytes==20,'uploaded resources retained after shutdown')
valid=true
local c=M.new(adapter,{bytes=M.max_retained_bytes-4,resources={},claims={}});c.register('limited',{},original);c.swap('limited',candidate)
previous=allocations;c.step();check(allocations==previous,'preflight must budget original and candidate atomically')
check(not pcall(M.validate,{format='RGBA8',width=1/0,height=1,row_pitch=4,rgba='1234'}),'nonfinite dimensions rejected')
check(not pcall(M.validate,{format='RGBA8',width=1,height=1,row_pitch=8,rgba='1234'}),'padded pitch rejected')
check(not pcall(M.validate,{format='RGBA8',width=1,height=1,row_pitch=4,rgba='12345'}),'extra pixels rejected')
local f=assert(os.getenv('TEMP'))..'/dbf-runtime-textures-test-'..tostring(os.time())..'.rgba';local out=assert(io.open(f,'wb'));out:write('12345');out:close()
check(not pcall(M.read_image,f,1,1),'oversized raw file rejected');os.remove(f)
check(not pcall(M.read_image,f,1e20,1),'dimensions checked before allocation or file read')
-- Persistent restoration failure retains ownership, callback and resources.
local stuck=M.new({in_render_phase=function()return true end,valid=function()return true end,
 ready=adapter.ready,upload=adapter.upload,bind=function()error('native failure')end},{bytes=0,resources={},claims={}})
stuck.register('stuck',{},original);stuck.swap('stuck',candidate);stuck.step();stuck.close()
check(stuck.step()==false and stuck.targets.stuck.active,'failed rollback cannot report complete')
print('runtime texture contracts: '..checks..' passed')
-- Native submission can remain pending across several render callbacks.
local acknowledged={};local later_writes={};local later_store={bytes=0,resources={},claims={}}
local later=M.new({in_render_phase=function()return true end,valid=function()return true end,
 upload=function(i,r)r.resource=i.rgba end,ready=function(r)return acknowledged[r]==true end,
 bind=function(_,r)later_writes[#later_writes+1]=r end},later_store)
later.register('async',{},original);later.swap('async',candidate);later.step()
assert(#later_writes==0 and #later_store.resources==2,'unacknowledged upload was published')
acknowledged[later_store.resources[1]]=true;later.step()
assert(#later_writes==0,'candidate published before its own acknowledgment')
acknowledged[later_store.resources[2]]=true;later.step()
assert(later_writes[1]=='CCCC','acknowledged candidate never published')
later.swap('async',image('D'));later.step();later.restore('async');later.step()
assert(later_writes[#later_writes]=='OOOO','restore while upload pending did not restore original')
acknowledged[later_store.resources[3]]=true;later.step()
assert(later_writes[#later_writes]=='OOOO','canceled upload resurfaced after acknowledgment')
later.swap('async',image('E'));later.step();later.close()
assert(later.step()==true and later_store.resources[4],'unpublished native source was released at cleanup')
print('PASS asynchronous acknowledgment, pending restore/cancel, and retained cleanup')
