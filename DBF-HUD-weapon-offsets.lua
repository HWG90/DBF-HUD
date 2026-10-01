-- Place beside DBF-HUD-tuning.lua in the Helldivers 2 game folder.
-- Reload DBF-HUD in MDL (or restart the game) after editing this file.
-- Auto placement only. Values are additional weapon-local metres:
-- X right, Y forward, Z up. Negative Y moves back toward the shooter.
-- Views: right, left, first_left, first_right. Missing views add no correction.
-- Menu saves do not overwrite this file. An empty return table disables all profiles.
return {
    ['be70ee0d8d44028e'] = { right = { x = -0.0508, z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- Halo SMG: six inches down in all views
    ['f0338468dcdb6a6c'] = { right = { x = -0.0254, z = -0.1524 }, first_left = { x = -0.0254, z = -0.1524 }, first_right = { x = -0.0254, z = -0.1524 } }, -- Sensor: one inch left, six down in all views
    ['e6d932be83729076'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- Deadeye: third-person six inches down; first-person six inches down
    ['d54b9505c0f72873'] = { first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = -0.1892, z = -0.1524 } }, -- laser_cannon: first-person left override
    ['3575aabc5f1f9326'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- automatic_pistol
    ['0b882808c6f498e8'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- caustic_dart_gun
    ['416d053372c4e433'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- energy_revolver
    ['3f92ba65ef65cca9'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- flamer_pistol
    ['52e4334e6a128caf'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- grenade_pistol
    ['e91f569c2ad8af01'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- hornet_pistol
    ['7b06196e90154c88'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- laser_pistol
    ['1a437158e1b8d2a1'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- magnum_pistol
    ['c780bcd79547da0f'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- pistol_broomhandle
    ['9eb160830321bfd6'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- pistol_cricket
    ['4d58c77087b774c5'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- pistol_nacho
    ['dbb6c961c59fadc1'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- pistol_shark
    ['aa69a60d74a3ec54'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- plasma_pistol
    ['8d3d52a3b2f19402'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- revolver_pistol
    ['bde1f2534280300d'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- revolver_pistol_long
    ['cf8934ff6567a42d'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- smart_pistol
    ['05e4e5c2db6e44a2'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- standard_pistol
    ['d6b1fb05b9109353'] = { right = { x = 0.0762, z = -0.1524 }, first_left = { x = 0.0508, z = -0.1524 }, first_right = { x = 0.0508, z = -0.1524 } }, -- stim_pistol
    ['25aa2fd4643cf4ee'] = { -- Spear (catalog asset identity; not yet visually tested)
        right = { x = 0.1524 },
        first_right = { x = -0.24 }, -- Keep first person on the left.
    },
    ['9f80d67a12a7e40f'] = { -- Recoilless rifle
        right = { x = 0.1524 },
        first_right = { x = -0.24 }, -- Mirror the default +0.12 mount to -0.12 (left).
    },
    ['27ee1ed8f6fb6356'] = { -- Scythe
        right = { x = 0.0762, y = 0.1270, z = -0.1524 },
    },
    ['a8cffb316f0b5c5f'] = { -- Autocannon
        right = { x = 0.12, y = -0.08, z = 0.10 },
        first_right = { x = -0.24 }, -- Keep first person on the left, like the recoilless.
    },
    ['968211c0033dce64'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle: third-person six inches down
    ['43cb1033961a2276'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle_ap: third-person six inches down
    ['cf5f176e0e322be1'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle_exp: third-person six inches down
    ['ab2a2b390c539f18'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle_explosive: third-person six inches down
    ['a955c4ea6f6d4203'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle_grenadier: third-person six inches down
    ['cdf28be026bb7d84'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle_helghast: third-person six inches down
    ['bc29613666df696b'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle_karbin: third-person six inches down
    ['84354339522c932d'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle_large_calibre_01: third-person six inches down
    ['4dbd74f49c8ffc13'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle_nacho: third-person six inches down
    ['a7ee1ebf58fcdf1f'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle_patriot: third-person six inches down
    ['0c197bbd8d2c725b'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle_penetrator: third-person six inches down
    ['ce063aa33d95a812'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle_rico: third-person six inches down
    ['a8a91eb54892b6b2'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle_risk: third-person six inches down
    ['708ea298c82093d0'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle_whisper: third-person six inches down
    ['5fecab819f96a3e8'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- battle_rifle: third-person six inches down
    ['0f83639ab8c86165'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- battle_rifle_ceremonial: third-person six inches down
    ['7b75e5132ffd4ca6'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- bolt_action_rifle: third-person six inches down
    ['80f1a156d9fa1e36'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- jet_rifle: third-person six inches down
    ['b6aff2195568767f'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- jet_rifle_phoenix: third-person six inches down
    ['8dc91f277c6096ee'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- jet_rifle_phoenix: third-person six inches down
    ['7e3145a5baa4b948'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- laser_rifle_charge: third-person six inches down
    ['8645f167b3c813a2'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- laser_rifle_long: third-person six inches down
    ['295beb26dc4f8ff1'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- laser_rifle_long_hotshot: third-person six inches down
    ['2df1cfb9ed77e06c'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- marksman_rifle: third-person six inches down
    ['e5796355a8fd67e0'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- marksman_rifle_drake: third-person six inches down
    ['1abbff60d26ba391'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- marksman_rifle_shark: third-person six inches down
    ['03e67a19b07c6523'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- marksman_rifle_vigilance: third-person six inches down
    ['4c786785c79d44e7'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- marksman_rifle_vigilance_burst: third-person six inches down
    ['6e68194b95d60145'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- marksman_rifle_vigilance_counter_sniper: third-person six inches down
    ['eea5e3cef1e12c14'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- plasma_rifle: third-person six inches down
    ['fb3a19078694708a'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- plasma_rifle_charge: third-person six inches down
    ['efdcef306cea63fe'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- plasma_rifle_charge: third-person six inches down
    ['30061f91af477f5e'] = { right = { z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- sniper_rifle_helghast: third-person six inches down
    ['006e44327bb953fe'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- pump_grenade_launcher
    ['02cd7321cd8445f5'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- Verified auxiliary grenade entity on the equipped rifle.
    ['02eecd0b1fa49630'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- grenade_launcher
    ['05d8d8c073b9d502'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- pump_shotgun_plasma
    ['07419ebc09a1a7c5'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- railgun
    ['076dd5d4f4360204'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- arc_shotgun
    ['0807aea5217e4767'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- personal_defense_weapon
    ['11c27d3babb38956'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- machinegun
    ['11ec8e2296a3d662'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- pump_shotgun_02
    ['16051937941bb709'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- smg_rhino
    ['186ea95de7306b1a'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- smg_solvent
    ['2152d5147b0ac418'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- heavy_mg
    ['2383b0439f0bc465'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle_rico
    ['25aa2fd4643cf4ee'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- faf_missile_launcher
    ['26df5aa208ce216e'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- railgun
    ['26e40437ea275296'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- air_burst_rocket_launcher
    ['27ee1ed8f6fb6356'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- laser_rifle
    ['2b28e17ffed05f7c'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- triple_barrel_breakshotgun
    ['2e9d0bdc48b09e60'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- railgun
    ['35a61296619cc47e'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- laser_pulse_cannon
    ['3828e2051aa9e897'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- harpoon_gun
    ['39ab99895147a3bf'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- flamethrower
    ['3c86e871923f3970'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- laser_shotgun
    ['41eac4a03987faa0'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- pump_shotgun
    ['43a58cb89cfa197c'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- minigun
    ['43b2d7766120203b'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- chemgun
    ['46183b50961d1328'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_shotgun
    ['46427f2630a80d88'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- faf_missile_launcher_helghast
    ['4ba41b6f9f405cc2'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- smg_helghast
    ['4e310b1fe4c52b52'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- pump_shotgun_02
    ['4e4a613eb9bf5c24'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- personal_defense_weapon
    ['4f749e2ee26f532d'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- pump_shotgun
    ['4fb0f8c02f55c82b'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- flamethrower_ripley
    ['53eebe75cd6e26df'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- pump_shotgun_slug
    ['5990123d142b16cb'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- laser_guided_missile_launcher
    ['5ebaea70c0d060b9'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_shotgun
    ['6228d0242bde56b6'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_shotgun_sprayandpray
    ['644d748f359de03e'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- railgun
    ['692eb345969d368e'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- lat_oneshot
    ['6cfcc7f8801a0266'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- energy_weapon_shark
    ['6dfa768b4e2401a7'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- railgun
    ['719f42b7d137789c'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- jet_rifle_phoenix
    ['72170a55a1f37ff1'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- shotgun_double_freedom
    ['7617642765ac38c7'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- expendable_massive_rocket_launcher
    ['78a8185f63a70795'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- heavy_flamethrower
    ['7c47244d3b030884'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- railgun
    ['8039834a4b7489b9'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle_penetrator
    ['80932fa0ed6901d3'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- lat_oneshot
    ['8666e5f49f440d44'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- faf_missile_launcher
    ['88c2d09ad85a7c9f'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- belt_fed_grenade_launcher
    ['89c5493e08ca4207'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- sniper_rifle
    ['8a307bd1811a5fe9'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- smg_flamer
    ['8a35c1dc19f41870'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- bolt_action_rifle
    ['90ddc374f4e3d756'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- shotgun_nacho
    ['945f7e132049b514'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- railgun
    ['94bd931b5fb4ee95'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- smg_rhino
    ['9571ca51f0daf35b'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- smg_defender
    ['96de9cd50f7306e6'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- arc_thrower
    ['9b0a7b78126c2fec'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- missile_launcher
    ['9f80d67a12a7e40f'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- recoilless_rifle
    ['a6a735accb4a327f'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- lmg_stalwart
    ['a8cffb316f0b5c5f'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- automatic_cannon
    ['a9e574cd953d3b3a'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- faf_missile_helghast
    ['b16c9d490aa59b77'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- expendable_machinegun
    ['b2b5e0d185605f9e'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- expendable_napalm_launcher
    ['bcc2177439d231be'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- pump_shotgun
    ['bf9504e95c0103a1'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- battle_rifle_ceremonial
    ['bfe35746f5084222'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_rifle_karbin
    ['c0a9ee8ce12f682a'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- railgun
    ['c12a34f375bd5a87'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_shotgun_incendiary
    ['c4232a0e62166d91'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- personal_defense_weapon_pepper
    ['c85f576d5e086147'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- laser_smg_blaster
    ['cc786f6491fe7e65'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- faf_missile_launcher_helghast
    ['cdf733b0106a23c3'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- assault_shotgun_incendiary
    ['d323de60855898ac'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- pump_shotgun_dragon
    ['dcd1c835407ef7ba'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- pump_shotgun_trench
    ['df8decb6b6538265'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- railgun
    ['e8d5f49ad7780e54'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- plasma_blaster
    ['e8ffad77b73c221c'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- railgun
    ['f49227a0630a3f7f'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- crossbow_greyfax
    ['f992ce97577c8a7f'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- volley_gun
    ['fe3b29b2cfa63f9b'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- grenade_launcher_tactical
    ['ffc18b2ce10ca381'] = { first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- battle_rifle
}
