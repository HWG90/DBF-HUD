from pathlib import Path
import re,json,ctypes
P=Path(__file__).resolve().parent
s=(P/'mod.lua').read_text()
# One authoritative persisted selection mode; manual choice intentionally exits follow mode.
s=s.replace('M.defaults={','M.defaults={appearance_follow_equipped=true,',1)
s=s.replace("elseif (k=='texture_art_trial'", "elseif (k=='appearance_follow_equipped' or k=='texture_art_trial'",1)
s=s.replace('function self.appearance_weapon()return appearance_selection or (model and model.resource_hex) end', '''function self.appearance_weapon()
        if self.config.appearance_follow_equipped~=false then return model and model.resource_hex end
        return appearance_selection
    end
    function self.follow_equipped_appearance(value)
        assert(type(value)=='boolean','Follow selection must be boolean')
        if not value and not appearance_selection then appearance_selection=model and model.resource_hex end
        self.configure({appearance_follow_equipped=value})
    end''')
s=s.replace("assert(resource and HUD.weapon_names[resource],'Unknown weapon');appearance_selection=resource", "assert(resource and HUD.weapon_names[resource],'Unknown weapon');appearance_selection=resource;self.configure({appearance_follow_equipped=false})")
s=s.replace("local panel_controls={{id='appearance_weapon_select'", "local panel_controls={{id='appearance_follow_equipped',type='toggle',label='Follow equipped weapon',default=hud.config.appearance_follow_equipped~=false,on_change=function(v)hud.follow_equipped_appearance(v);hud.save_tuning();if panel_refresh then panel_refresh(true)end end},{id='appearance_weapon_select'")
s=s.replace("hud.select_appearance_weapon(hud.equipped_resource());if panel_refresh", "hud.follow_equipped_appearance(true);hud.save_tuning();if panel_refresh")
s=s.replace("if panel_guard then panel_guard()end\n        local visibility_mod", "if panel_refresh then panel_refresh(false)end;if panel_guard then panel_guard()end\n        local visibility_mod")
s=s.replace("if c.id=='appearance_weapon_select' then registered.disabled=false;", "if c.id=='appearance_follow_equipped' then registered.disabled=false;mod.values[c.id]=hud.config.appearance_follow_equipped~=false\n                        elseif c.id=='appearance_weapon_select' then registered.disabled=false;")
s=s.replace("'Equipped weapon changed; press Fetch again'", "'Weapon changed; allow appearance controls to refresh'")
s=s.replace("'Select any weapon or Fetch the equipped weapon'", "'Following equipped weapon; manual selection pins a preview'")
s=s.replace("'Select any weapon or Fetch the equipped weapon'", "'Follow equipped weapon or choose a manual preview'")
s=s.replace("'Fetch current weapon appearance'", "'Follow equipped weapon'")
s=s.replace("'Reload the equipped weapon settings, including inherited global options.'", "'Resume automatic selection and refresh inherited appearance.'")
# Remove obsolete texture-only and fixed decoration controls from this native-only design.
unused={'texture_art_trial','texture_art_variant','decoration','style_3d','frosted'}
lines=s.splitlines(True);new=[]
for line in lines:
 line=re.sub(r",\{'frosted','Frosted background \(2D\)','toggle'\}",'',line)
 if ('panel_definitions[#panel_definitions+1]=' in line or line.lstrip().startswith("{'")) and any("{'"+k+"'" in line for k in unused):
  # Preserve the table terminator when removing its final definition.
  if "{'style_3d'" in line: new.append('                }\n')
  continue
 if "{id='reload_hot_panel_art'" in line or "{id='restore_hot_panel_art'" in line:continue
 if "{id='faithful_render_status'" in line:continue
 new.append(line)
s=''.join(new)
s=s.replace("local selected=v.type=='panel' and cfg.theme_shader or ((v.df_effect_sweep or v.scanline_layer or v.effect_shader_band) and cfg.effect_shader)", "local selected=v.neo_effect_shader or (v.type=='panel' and cfg.theme_shader or ((v.df_effect_sweep or v.scanline_layer or v.effect_shader_band) and cfg.effect_shader))")
s=s.replace("selected=c.effect_shader or 'none';", "selected=v.neo_effect_shader or c.effect_shader or 'none';")
s=s.replace("(not cfg.effect_scanlines and not cfg.effect_sweep and ' [inactive: enable Scanlines or Sweep]' or '')", "''")
s=s.replace("c.description='Native 3D shader on the live readout area. HUD Texture pixels stay unchanged. Automatic preserves HUD Texture; None removes this shader carrier.'", "c.description='Optional GPU panel finish. None keeps the clean instrument backing.'")
s=s.replace("c.description='Live readout shader carrier color; HUD Texture colors are unchanged.'", "c.description='Instrument backing color; native readouts remain separate.'")
s=s.replace("Native 3D shader for existing scanline/sweep bands: enable Scanlines or Sweep. No extra geometry. None keeps normal bands.", "Optional GPU pattern on one instrument surface. None keeps the panel clean.")
# Replace the old texture-selection compose branch, retaining authoritative overrides.
a=s.index("        do return HUD.neo_panel.compose(");b=s.index('        local override=cfg.weapon_panel_overrides',a)
s=s[:a]+"        out=HUD.neo_panel.compose(out,m,x,y,scale,opacity,cfg,clock,measure,sr.Application.can_get)\n"+s[b:]
# The GPU shader lookup already accepts effect_shader_band on a single surface.
# Retain legacy animated sweep and flicker until a verified equivalent exists.
(P/'mod.lua').write_text(s)
checker=(P.parent/'install_epoch_plasma.py').read_text();exec(checker[checker.index('dll=ctypes.CDLL'):checker.index('check(after)')]);check(s)
# Export exact candidate-owned modules as editable source, not a stale source tree.
O=P/'Source';O.mkdir(exist_ok=True)
matches=list(re.finditer(r'^HUD\.([A-Za-z_][A-Za-z_0-9]*)=\(function\(\)\n',s,re.M))
for m in matches:
 limit=matches[matches.index(m)+1].start() if matches.index(m)+1<len(matches) else len(s)
 end=s.rfind('\nend)()',m.end(),limit);assert end>=m.end(),m[1]
 (O/(m[1]+'.lua')).write_text(s[m.end():end]+'\n')
report=json.loads((P/'validation.json').read_text());report.update(follow_equipped_default=True,manual_preview_preserved=True,candidate_syntax=True,source_modules=len(matches))
(P/'validation.json').write_text(json.dumps(report,indent=2))
print('Candidate syntax valid;',len(matches),'exact source modules exported; automatic selection restored')
