-- Catalog-derived ammo presentation; live selector remains the source of counts.
local M={}
local projectiles={
    [1]='FLECHETTES',
    [14]='BUCKSHOT',
    [36]='HE',
    [37]='FLECHETTES',
    [47]='BUCKSHOT',
    [62]='BUCKSHOT',
    [73]='BUCKSHOT',
    [96]='FRAG',
    [115]='APHET',
    [153]='HEAT',
    [183]='FLECHETTES',
    [191]='STUN',
    [198]='BUCKSHOT',
    [199]='BUCKSHOT',
    [217]='BUCKSHOT',
    [224]='FLAK',
    [231]='HEAT',
    [232]='BUCKSHOT',
    [240]='SLUG',
    [260]='BUCKSHOT',
    [262]='BUCKSHOT',
    [284]='FLAK',
    [290]='BUCKSHOT',
    [292]='BUCKSHOT',
    [312]='FLAK',
    [317]='BUCKSHOT',
    [322]='FRAG',
    [332]='FLECHETTES',
    [350]='HE',
}
local weapons={
    ['02cd7321cd8445f5']='GRENADES', -- Verified auxiliary grenade entity on the equipped rifle.
    ['006e44327bb953fe']='GRENADES', -- pump_grenade_launcher
    ['02eecd0b1fa49630']='GRENADES', -- grenade_launcher
    ['03e67a19b07c6523']='ROUNDS', -- marksman_rifle_vigilance
    ['05d8d8c073b9d502']='SHELLS', -- pump_shotgun_plasma
    ['07419ebc09a1a7c5']='ROUNDS', -- railgun
    ['076dd5d4f4360204']='SHELLS', -- arc_shotgun
    ['0807aea5217e4767']='ROUNDS', -- personal_defense_weapon
    ['0c197bbd8d2c725b']='ROUNDS', -- assault_rifle_penetrator
    ['0f83639ab8c86165']='ROUNDS', -- battle_rifle_ceremonial
    ['11c27d3babb38956']='ROUNDS', -- machinegun
    ['11ec8e2296a3d662']='SHELLS', -- pump_shotgun_02
    ['16051937941bb709']='ROUNDS', -- smg_rhino
    ['186ea95de7306b1a']='ROUNDS', -- smg_solvent
    ['1abbff60d26ba391']='ROUNDS', -- marksman_rifle_shark
    ['2152d5147b0ac418']='ROUNDS', -- heavy_mg
    ['2383b0439f0bc465']='ROUNDS', -- assault_rifle_rico
    ['25aa2fd4643cf4ee']='ROUNDS', -- faf_missile_launcher
    ['26df5aa208ce216e']='ROUNDS', -- railgun
    ['26e40437ea275296']='ROCKETS', -- air_burst_rocket_launcher
    ['27ee1ed8f6fb6356']='ROUNDS', -- laser_rifle
    ['295beb26dc4f8ff1']='ROUNDS', -- laser_rifle_long_hotshot
    ['2b28e17ffed05f7c']='SHELLS', -- triple_barrel_breakshotgun
    ['2df1cfb9ed77e06c']='ROUNDS', -- marksman_rifle
    ['2e9d0bdc48b09e60']='ROUNDS', -- railgun
    ['30061f91af477f5e']='ROUNDS', -- sniper_rifle_helghast
    ['35a61296619cc47e']='ROUNDS', -- laser_pulse_cannon
    ['3828e2051aa9e897']='ROUNDS', -- harpoon_gun
    ['39ab99895147a3bf']='FUEL', -- flamethrower
    ['3c86e871923f3970']='SHELLS', -- laser_shotgun
    ['41eac4a03987faa0']='SHELLS', -- pump_shotgun
    ['43a58cb89cfa197c']='ROUNDS', -- minigun
    ['43b2d7766120203b']='ROUNDS', -- chemgun
    ['43cb1033961a2276']='ROUNDS', -- assault_rifle
    ['46183b50961d1328']='SHELLS', -- assault_shotgun
    ['46427f2630a80d88']='ROUNDS', -- faf_missile_launcher_helghast
    ['4ba41b6f9f405cc2']='ROUNDS', -- smg_helghast
    ['4c786785c79d44e7']='ROUNDS', -- marksman_rifle_vigilance
    ['4dbd74f49c8ffc13']='ROUNDS', -- assault_rifle_nacho
    ['4e310b1fe4c52b52']='SHELLS', -- pump_shotgun_02
    ['4e4a613eb9bf5c24']='ROUNDS', -- personal_defense_weapon
    ['4f749e2ee26f532d']='SHELLS', -- pump_shotgun
    ['4fb0f8c02f55c82b']='FUEL', -- flamethrower_ripley
    ['53eebe75cd6e26df']='SHELLS', -- pump_shotgun_slug
    ['5990123d142b16cb']='ROUNDS', -- laser_guided_missile_launcher
    ['5ebaea70c0d060b9']='SHELLS', -- assault_shotgun
    ['5fecab819f96a3e8']='ROUNDS', -- battle_rifle
    ['6228d0242bde56b6']='SHELLS', -- assault_shotgun_sprayandpray
    ['644d748f359de03e']='ROUNDS', -- railgun
    ['692eb345969d368e']='ROUNDS', -- lat_oneshot
    ['6cfcc7f8801a0266']='ROUNDS', -- energy_weapon_shark
    ['6dfa768b4e2401a7']='ROUNDS', -- railgun
    ['6e68194b95d60145']='ROUNDS', -- marksman_rifle_vigilance_counter_sniper
    ['708ea298c82093d0']='ROUNDS', -- assault_rifle_whisper
    ['719f42b7d137789c']='ROUNDS', -- jet_rifle_phoenix
    ['72170a55a1f37ff1']='SHELLS', -- shotgun_double_freedom
    ['7617642765ac38c7']='ROCKETS', -- expendable_massive_rocket_launcher
    ['78a8185f63a70795']='FUEL', -- heavy_flamethrower
    ['7b75e5132ffd4ca6']='ROUNDS', -- bolt_action_rifle
    ['7c47244d3b030884']='ROUNDS', -- railgun
    ['7e3145a5baa4b948']='ROUNDS', -- laser_rifle_charge
    ['8039834a4b7489b9']='ROUNDS', -- assault_rifle_penetrator
    ['80932fa0ed6901d3']='ROUNDS', -- lat_oneshot
    ['80f1a156d9fa1e36']='ROUNDS', -- jet_rifle
    ['84354339522c932d']='ROUNDS', -- assault_rifle_large_calibre_01
    ['8645f167b3c813a2']='ROUNDS', -- laser_rifle_long
    ['8666e5f49f440d44']='ROUNDS', -- faf_missile_launcher
    ['88c2d09ad85a7c9f']='GRENADES', -- belt_fed_grenade_launcher
    ['89c5493e08ca4207']='ROUNDS', -- sniper_rifle
    ['8a307bd1811a5fe9']='FUEL', -- smg_flamer
    ['8a35c1dc19f41870']='ROUNDS', -- bolt_action_rifle
    ['8dc91f277c6096ee']='ROUNDS', -- jet_rifle_phoenix
    ['90ddc374f4e3d756']='SHELLS', -- shotgun_nacho
    ['945f7e132049b514']='ROUNDS', -- railgun
    ['94bd931b5fb4ee95']='ROUNDS', -- smg_rhino
    ['9571ca51f0daf35b']='ROUNDS', -- smg_defender
    ['968211c0033dce64']='ROUNDS', -- assault_rifle
    ['96de9cd50f7306e6']='ROUNDS', -- arc_thrower
    ['9b0a7b78126c2fec']='ROUNDS', -- missile_launcher
    ['9f80d67a12a7e40f']='ROCKETS', -- recoilless_rifle
    ['a6a735accb4a327f']='ROUNDS', -- lmg_stalwart
    ['a7ee1ebf58fcdf1f']='ROUNDS', -- assault_rifle_patriot
    ['a8a91eb54892b6b2']='ROUNDS', -- assault_rifle_risk
    ['a8cffb316f0b5c5f']='ROUNDS', -- automatic_cannon
    ['a955c4ea6f6d4203']='ROUNDS', -- assault_rifle_grenadier
    ['a9e574cd953d3b3a']='ROUNDS', -- faf_missile_helghast
    ['ab2a2b390c539f18']='ROUNDS', -- assault_rifle_explosive
    ['b16c9d490aa59b77']='ROUNDS', -- expendable_machinegun
    ['b2b5e0d185605f9e']='ROUNDS', -- expendable_napalm_launcher
    ['b6aff2195568767f']='ROUNDS', -- jet_rifle
    ['bc29613666df696b']='ROUNDS', -- assault_rifle_karbin
    ['bcc2177439d231be']='SHELLS', -- pump_shotgun
    ['be70ee0d8d44028e']='ROUNDS', -- smg_nacho
    ['bf9504e95c0103a1']='ROUNDS', -- battle_rifle_ceremonial
    ['bfe35746f5084222']='ROUNDS', -- assault_rifle_karbin
    ['c0a9ee8ce12f682a']='ROUNDS', -- railgun
    ['c12a34f375bd5a87']='SHELLS', -- assault_shotgun_incendiary
    ['c4232a0e62166d91']='ROUNDS', -- personal_defense_weapon_pepper
    ['c85f576d5e086147']='ROUNDS', -- laser_smg_blaster
    ['cc786f6491fe7e65']='ROUNDS', -- faf_missile_launcher_helghast
    ['cdf28be026bb7d84']='ROUNDS', -- assault_rifle_helghast
    ['cdf733b0106a23c3']='SHELLS', -- assault_shotgun_incendiary
    ['ce063aa33d95a812']='ROUNDS', -- assault_rifle_rico
    ['cf5f176e0e322be1']='ROUNDS', -- assault_rifle
    ['d323de60855898ac']='SHELLS', -- pump_shotgun_dragon
    ['d54b9505c0f72873']='ROUNDS', -- laser_cannon
    ['dcd1c835407ef7ba']='SHELLS', -- pump_shotgun_trench
    ['df8decb6b6538265']='ROUNDS', -- railgun
    ['e5796355a8fd67e0']='ROUNDS', -- marksman_rifle_drake
    ['e6d932be83729076']='ROUNDS', -- lever_action_rifle_01
    ['e8d5f49ad7780e54']='ROUNDS', -- plasma_blaster
    ['e8ffad77b73c221c']='ROUNDS', -- railgun
    ['eea5e3cef1e12c14']='ROUNDS', -- plasma_rifle
    ['efdcef306cea63fe']='ROUNDS', -- plasma_rifle_charge
    ['f0338468dcdb6a6c']='ROUNDS', -- marksman_rifle_justice
    ['f49227a0630a3f7f']='ROUNDS', -- crossbow_greyfax
    ['f992ce97577c8a7f']='ROUNDS', -- volley_gun
    ['fb3a19078694708a']='ROUNDS', -- plasma_rifle
    ['fe3b29b2cfa63f9b']='GRENADES', -- grenade_launcher_tactical
    ['ffc18b2ce10ca381']='ROUNDS', -- battle_rifle
}
-- APHET/Flak values verified by a matched return sequence. Full auto adds
-- 0x1000 to this packed word independently of the programmable-ammo bit.
-- Ignore only that observed flag; unverified combinations remain unknown.
function M.autocannon_mode(control)
    if type(control)~='number' or control~=math.floor(control) or control<0 or control>0xffffffff then return nil end
    if math.floor(control/0x1000)%2==1 then control=control-0x1000 end
    return ({[0x50]='APHET',[0x54]='FLAK'})[control]
end
function M.fire_mode(control)
    -- Standard catalog modes plus native mode 8, whose setter enables the
    -- auxiliary weapon entity. Safety/charge enums remain unverified.
    return ({[1]='AUTO',[2]='SEMI',[3]='BURST',[8]='ALT'})[control]
end
function M.selectable_fire_mode(control,choices)
    if not choices then return nil end
    local seen,count={},0
    for _,value in ipairs(choices) do
        if value>0 and value<=8 and not seen[value] then seen[value]=true;count=count+1 end
    end
    if count>1 and seen[control] then return M.fire_mode(control) end
end
local lasers={['27ee1ed8f6fb6356']=true,['295beb26dc4f8ff1']=true,['35a61296619cc47e']=true,['3c86e871923f3970']=true,['7e3145a5baa4b948']=true,['8645f167b3c813a2']=true,['c85f576d5e086147']=true,['d54b9505c0f72873']=true}
function M.apply(raw)
    if raw then raw.energy_icon=lasers[raw.ammo_resource_hex or raw.resource_hex] and 'LASER' or nil end
    if not raw or raw.kind=='heat' or raw.kind=='infinite' then return raw end
    local category=weapons[raw.ammo_resource_hex or raw.resource_hex] or 'ROUNDS'
    local special=raw.projectile_type and projectiles[raw.projectile_type]
    raw.label=special or category
    if raw.resource_hex=='a8cffb316f0b5c5f' then raw.label='AMMO' end
    if raw.alternate_fire and category=='GRENADES' then raw.label='GRENADES';raw.reserve_kind='GRENADES' end
    if raw.alternate_fire and raw.ammo_resource_hex=='02cd7321cd8445f5' then raw.label='40MM HE' end
    if raw.reserve_kind=='ROUNDS' then raw.reserve_kind=category end
    -- Stoker primary ammunition is bullets; its auxiliary entity supplies fuel.
    if raw.resource_hex=='8a307bd1811a5fe9' then
        raw.label=raw.alternate_fire and 'FUEL' or 'ROUNDS'
        if not raw.alternate_fire then raw.energy_icon='SEMI' end
        if raw.alternate_fire then raw.energy_icon='NONE';raw.chamber_supported=false;raw.reserve_kind='TANKS' end
    end
    return raw
end
return M
