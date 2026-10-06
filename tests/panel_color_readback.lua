HUD={native_font_data=dofile('src/native_font_data.lua')};HUD.config=dofile('src/config.lua')
local file=assert(io.open('src/runtime.lua','rb'));local source=file:read('*a');file:close()
local first=assert(source:find('    function self.panel_settings(resource)',1,true))
local last=assert(source:find('    function self.configure_panel',first,true))
local factory=assert(loadstring('return function(self,HUD,compose)\n'..source:sub(first,last-1)..'return self.panel_settings end'))()
local cfg=HUD.config.new();local weapon='72170a55a1f37ff1'
HUD.config.set_panel(cfg,weapon,{background_color='#12abef',text_color='#456789',decoration_color='#abcdef'})
local restored=HUD.config.new();local saved=assert(loadstring(HUD.config.serialize(cfg)))();HUD.config.apply(restored,saved)
local self={config=restored,clock=0,appearance_weapon=function()return weapon end,appearance_model=function()return {}end}
HUD.world_style={prepare=function(c)return c end}
local commands={{type='panel',c={0,0,0},a=0},{type='text',c={255,255,255},size=24},{type='rect',decoration=true,c={255,255,0}}}
local get=factory(self,HUD,function()return commands end)
local actual=get(weapon)
assert(actual.background_color=='#12ABEF' and actual.text_color=='#456789' and actual.decoration_color=='#ABCDEF')
assert(HUD.config.rgb(actual.background_color)[1]==18 and HUD.config.rgb(actual.background_color)[3]==239)
HUD.config.set_panel(restored,weapon,false)
local inherited=get(weapon);assert(inherited.background_color==restored.background_color,'invisible frame replaced inherited palette')
assert(commands[1].a==0 and commands[1].c[1]==0,'getter mutated accepted artwork')
print('PASS HEX persistence, explicit palette readback, invisible frame inheritance and artwork preservation')
