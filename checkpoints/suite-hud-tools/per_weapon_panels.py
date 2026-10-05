from pathlib import Path
import zipfile,datetime,subprocess,sys
r=Path(r'C:\Users\david\Documents\Codex\2026-09-29\i\outputs\DBF-HUD')
with zipfile.ZipFile(r/'evidence'/('before-per-weapon-panels-'+datetime.datetime.now().strftime('%Y%m%d-%H%M%S')+'.zip'),'w',zipfile.ZIP_DEFLATED) as z:
 for n in ['src/config.lua','src/runtime.lua','src/menu.lua','src/mdl.lua','tests/contracts.lua','mdl/dbf_hud/mod.lua']:z.write(r/n,n)
 z.write(Path(r'C:\Users\david\AppData\Local\DBF\DBF-HUD-tuning.lua'),'saved-tuning.lua')
p=r/'src/config.lua';s=p.read_text();s=s.replace("M.defaults={mg43", "M.defaults={weapon_panels={},effect_scanline_count=21,mg43").replace('M.limits={text_opacity','M.limits={effect_scanline_count={1,80},text_opacity')
s=s.replace('t[k]=v end;return t end',"t[k]=type(v)=='table' and {} or v end;return t end")
marker='function M.is_blacklisted'
insert='''M.panel_keys={background_color=true,text_color=true,decoration_color=true,panel_opacity=true,text_opacity=true,decoration=true,frosted=true,effect_scanlines=true,effect_flicker=true,effect_sweep=true,effect_scanline_count=true,style_3d=true,font=true}
function M.effective(config,resource)
 local out={};for k,v in pairs(config)do out[k]=v end
 local overrides=(config.weapon_panels or {})[resource or '']
 if overrides then for k,v in pairs(overrides)do out[k]=v end;out.weapon_panel_overrides=overrides end
 return out
end
function M.set_panel(config,resource,values)
 assert(type(resource)=='string' and resource:match('^%x+$') and #resource==16,'Equip a verified weapon first')
 local panels={};for id,profile in pairs(config.weapon_panels or {})do panels[id]=profile end
 if values==false then panels[resource]=nil else
  local profile={};for k,v in pairs(panels[resource] or {})do profile[k]=v end
  for k,v in pairs(values)do assert(M.panel_keys[k],'Not a panel appearance setting: '..tostring(k));profile[k]=v end
  panels[resource]=profile
 end
 M.apply(config,{weapon_panels=panels})
end
'''
s=s.replace(marker,insert+marker)
s=s.replace("        if limits then assert",'''        if k=='weapon_panels' then
            assert(type(v)=='table','Weapon panels must be a table');local validated={}
            for id,profile in pairs(v)do
                assert(type(id)=='string' and #id==16 and id:match('^%x+$'),'Invalid weapon panel identity')
                assert(type(profile)=='table','Invalid weapon panel settings')
                for key in pairs(profile)do assert(M.panel_keys[key],'Invalid weapon panel setting: '..tostring(key))end
                local scratch=M.new();M.apply(scratch,profile);local result={}
                for key in pairs(profile)do result[key]=scratch[key]end;validated[id]=result
            end
            v=validated
        elseif limits then assert''')
s=s.replace("k~='occlusion_mode'", "k~='weapon_panels' and k~='occlusion_mode'")
mark="    for _,name in ipairs({'archived_mesh','research'}) do"
insert='''    out[#out+1]='    weapon_panels = {'
    local weapons={};for id in pairs(config.weapon_panels or {})do weapons[#weapons+1]=id end;table.sort(weapons)
    for _,id in ipairs(weapons)do
        out[#out+1]='        ['..string.format('%q',id)..'] = {'
        local members={};for k in pairs(config.weapon_panels[id])do members[#members+1]=k end;table.sort(members)
        for _,k in ipairs(members)do out[#out+1]='            '..k..' = '..value(config.weapon_panels[id][k])..',' end
        out[#out+1]='        },'
    end
    out[#out+1]='    },'
'''
s=s.replace(mark,insert+mark);p.write_text(s,encoding='utf-8')
p=r/'src/runtime.lua';s=p.read_text();s=s.replace("local compose=timed('layout',HUD.layout.compose)",'''local compose=timed('layout',function(m,x,y,scale,opacity,cfg,clock,measure)
        local out=HUD.layout.compose(m,x,y,scale,opacity,cfg,clock,measure)
        local override=cfg.weapon_panel_overrides
        if override then for _,v in ipairs(out)do
            if v.type=='panel' and override.background_color then v.c=HUD.config.rgb(override.background_color)end
            if v.type=='text' and override.text_color and not m.warning and v.text~='UNSAFE' then v.c=HUD.config.rgb(override.text_color)end
        end end
        return out
    end)''')
s=s.replace('local cfg={};for k,v in pairs(self.config) do cfg[k]=v end','local cfg=HUD.config.effective(self.config,model.resource_hex)')
s=s.replace('local cfg={};for k,v in pairs(self.config)do cfg[k]=v end','local cfg=HUD.config.effective(self.config,preview_model.resource_hex)')
mark='    function self.export_tuning()'
insert='''    function self.appearance_weapon()return model and model.resource_hex end
    function self.panel_settings()return HUD.config.effective(self.config,self.appearance_weapon())end
    function self.configure_panel(values,resource)
        HUD.config.set_panel(self.config,resource or self.appearance_weapon(),values)
    end
'''
s=s.replace(mark,insert+mark)
s=s.replace('local world_config={};for k,v in pairs(self.config)do world_config[k]=v end','local world_config=HUD.config.effective(self.config,model.resource_hex)')
s=s.replace('            world_config.effect_scanline_count=6\n','')
s=s.replace('alpha*aim_opacity,self.config,self.clock)','alpha*aim_opacity,HUD.config.effective(self.config,model.resource_hex),self.clock)')
p.write_text(s,encoding='utf-8')
p=r/'src/menu.lua';s=p.read_text();s=s.replace('local font_host,font_handle','local font_host,font_handle\n    local panel_weapon,panel_refresh')
mark='            font_handle=host.register('
insert='''            local panel_controls={{type='text',label='Equipped weapon appearance',id='weapon_heading'},
                {id='panel_inherit',type='button',label='Use global appearance',on_activate=function()
                    hud.configure_panel(false);hud.save_tuning();if panel_refresh then panel_refresh(true)end
                end}}
            local panel_definitions={
                {'background_color','Panel color','color'},{'text_color','Text color','color'},{'decoration_color','Decoration color','color'},
                {'panel_opacity','Panel opacity','slider',0,1,.01},{'text_opacity','Text opacity','slider',0,1,.01},
                {'effect_scanline_count','Scanline count','slider',1,80,1},
                {'effect_scanlines','Scanlines','toggle'},{'effect_flicker','Flicker','toggle'},{'effect_sweep','Sweep','toggle'},{'frosted','Frosted background','toggle'},
                {'decoration','Decorations','choice',{'None','Thin outline','Corner brackets','Helldivers HUD','Double frame'}},
                {'style_3d','Visual style','choice',styles}}
            local function panel_value(key)
                local cfg=hud.panel_settings and hud.panel_settings() or hud.config
                local v=cfg[key]
                if key=='decoration' then for i,n in ipairs(HUD.config.decorations)do if n==v then return i end end end
                if key=='style_3d' then for i,n in ipairs(HUD.config.styles)do if n==v then return i end end end
                return v
            end
            for _,def in ipairs(panel_definitions)do
                local key=def[1];local c={id='weapon_'..key,type=def[3],label=def[2],default=panel_value(key)}
                if c.type=='choice' then c.choices=def[4]elseif c.type=='slider' then c.min,c.max,c.step=def[4],def[5],def[6]end
                c.on_change=function(v)
                    if key=='decoration' then v=HUD.config.decorations[v]elseif key=='style_3d' then v=HUD.config.styles[v]end
                    assert(hud.appearance_weapon and hud.appearance_weapon()==panel_weapon,'Equipped weapon changed; reopen this control')
                    hud.configure_panel({[key]=v},panel_weapon);hud.save_tuning()
                end
                panel_controls[#panel_controls+1]=c
            end
            panel_refresh=function(force)
                local id=hud.appearance_weapon and hud.appearance_weapon()
                if not force and id==panel_weapon then return end
                panel_weapon=id
                local mod=host.mods and host.mods.dbf_hud_fonts
                if not mod then return end
                for _,c in ipairs(panel_controls)do
                    local registered=mod.controls and mod.controls[c.id]
                    if registered then
                        registered.disabled=id==nil
                        if c.id=='weapon_heading' then registered.label=id and ((HUD.weapon_names[id] or id)..' - overrides global appearance') or 'Equip a weapon to edit its appearance'
                        elseif c.id:sub(1,7)=='weapon_' then mod.values[c.id]=panel_value(c.id:sub(8)) end
                    end
                end
            end
'''
s=s.replace(mark,insert+mark)
s=s.replace("}},{id='placement',name='Placement',controls=placement_controls}","}},{id='weapon_appearance',name='Weapon Appearance',controls=panel_controls},{id='placement',name='Placement',controls=placement_controls}")
s=s.replace("font_host=host;self.status='MCM > DBF-HUD'","font_host=host;self.status='MCM > DBF-HUD';panel_refresh(true)")
s=s.replace('        if attempted then return end','        if panel_refresh then panel_refresh()end\n        if attempted then return end')
p.write_text(s,encoding='utf-8')
p=r/'src/mdl.lua';s=p.read_text().replace('20261003-DETAILED-BREECH-FIX layered brass and steel; fitted scanlines','20261003-WEAPON-PANELS per-weapon appearance; world scanline density restored');p.write_text(s,encoding='utf-8')
p=r/'tests/contracts.lua';s=p.read_text();end=s.rfind("print(string.format('%d contract tests passed'")
test='''test('weapon panel overrides isolate Double Freedom and Autocannon and persist through reload',function()
 local cfg=HUD.config.new();local df,ac='72170a55a1f37ff1','a8cffb316f0b5c5f'
 local global=HUD.config.serialize(cfg)
 HUD.config.set_panel(cfg,df,{panel_opacity=.9,background_color='#17191B',effect_scanlines=true,effect_scanline_count=31,decoration='none'})
 assert(HUD.config.effective(cfg,df).panel_opacity==.9 and HUD.config.effective(cfg,ac).panel_opacity==cfg.panel_opacity)
 assert(HUD.config.effective(cfg,ac).effect_scanline_count==21)
 local restored=HUD.config.new();HUD.config.apply(restored,assert(loadstring(HUD.config.serialize(cfg)))())
 assert(HUD.config.effective(restored,df).effect_scanline_count==31 and HUD.config.effective(restored,ac).background_color==cfg.background_color)
 local before=HUD.config.serialize(restored)
 assert(not pcall(HUD.config.set_panel,restored,df,{effect_scanline_count=100}));assert(HUD.config.serialize(restored)==before)
 assert(not pcall(HUD.config.set_panel,restored,df,{mount_x=1}))
 HUD.config.set_panel(restored,df,false);assert(HUD.config.serialize(restored)==global)
 local other=HUD.config.new();assert(next(other.weapon_panels)==nil)
end)
'''
s=s[:end]+test+s[end:];p.write_text(s,encoding='utf-8')
for name in ['tests/run.py','tools/build.py','tools/install_mdl.py']:subprocess.run([sys.executable,str(r/name)],cwd=r,check=True)
