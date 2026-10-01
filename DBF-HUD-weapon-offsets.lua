-- Place beside DBF-HUD-tuning.lua in the Helldivers 2 game folder.
-- Reload DBF-HUD in MDL (or restart the game) after editing this file.
-- Auto placement only. Values are additional weapon-local metres:
-- X right, Y forward, Z up. Negative Y moves back toward the shooter.
-- Views: right, left, first_left, first_right. Missing views add no correction.
-- Menu saves do not overwrite this file. An empty return table disables all profiles.
return {
    ['be70ee0d8d44028e'] = { right = { x = -0.0508, z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- Halo SMG: six inches down in all views
    ['f0338468dcdb6a6c'] = { right = { x = -0.0254, z = -0.1524 }, first_left = { x = -0.0254, z = -0.1524 }, first_right = { x = -0.0254, z = -0.1524 } }, -- Sensor: one inch left, six down in all views
    ['e6d932be83729076'] = { right = { z = -0.1524 }, first_left = { z = -0.0889 }, first_right = { z = -0.0889 } }, -- Deadeye: third-person six inches down; first-person 3.5 inches down
    ['d54b9505c0f72873'] = { first_left = { x = 0.0508 }, first_right = { x = -0.1892 } }, -- laser_cannon: first-person left override
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
    ['968211c0033dce64'] = { right = { z = -0.1524 } }, -- assault_rifle: third-person six inches down
    ['43cb1033961a2276'] = { right = { z = -0.1524 } }, -- assault_rifle_ap: third-person six inches down
    ['cf5f176e0e322be1'] = { right = { z = -0.1524 } }, -- assault_rifle_exp: third-person six inches down
    ['ab2a2b390c539f18'] = { right = { z = -0.1524 } }, -- assault_rifle_explosive: third-person six inches down
    ['a955c4ea6f6d4203'] = { right = { z = -0.1524 } }, -- assault_rifle_grenadier: third-person six inches down
    ['cdf28be026bb7d84'] = { right = { z = -0.1524 } }, -- assault_rifle_helghast: third-person six inches down
    ['bc29613666df696b'] = { right = { z = -0.1524 } }, -- assault_rifle_karbin: third-person six inches down
    ['84354339522c932d'] = { right = { z = -0.1524 } }, -- assault_rifle_large_calibre_01: third-person six inches down
    ['4dbd74f49c8ffc13'] = { right = { z = -0.1524 } }, -- assault_rifle_nacho: third-person six inches down
    ['a7ee1ebf58fcdf1f'] = { right = { z = -0.1524 } }, -- assault_rifle_patriot: third-person six inches down
    ['0c197bbd8d2c725b'] = { right = { z = -0.1524 } }, -- assault_rifle_penetrator: third-person six inches down
    ['ce063aa33d95a812'] = { right = { z = -0.1524 } }, -- assault_rifle_rico: third-person six inches down
    ['a8a91eb54892b6b2'] = { right = { z = -0.1524 } }, -- assault_rifle_risk: third-person six inches down
    ['708ea298c82093d0'] = { right = { z = -0.1524 } }, -- assault_rifle_whisper: third-person six inches down
    ['5fecab819f96a3e8'] = { right = { z = -0.1524 } }, -- battle_rifle: third-person six inches down
    ['0f83639ab8c86165'] = { right = { z = -0.1524 } }, -- battle_rifle_ceremonial: third-person six inches down
    ['7b75e5132ffd4ca6'] = { right = { z = -0.1524 } }, -- bolt_action_rifle: third-person six inches down
    ['80f1a156d9fa1e36'] = { right = { z = -0.1524 } }, -- jet_rifle: third-person six inches down
    ['b6aff2195568767f'] = { right = { z = -0.1524 } }, -- jet_rifle_phoenix: third-person six inches down
    ['8dc91f277c6096ee'] = { right = { z = -0.1524 } }, -- jet_rifle_phoenix: third-person six inches down
    ['7e3145a5baa4b948'] = { right = { z = -0.1524 } }, -- laser_rifle_charge: third-person six inches down
    ['8645f167b3c813a2'] = { right = { z = -0.1524 } }, -- laser_rifle_long: third-person six inches down
    ['295beb26dc4f8ff1'] = { right = { z = -0.1524 } }, -- laser_rifle_long_hotshot: third-person six inches down
    ['2df1cfb9ed77e06c'] = { right = { z = -0.1524 } }, -- marksman_rifle: third-person six inches down
    ['e5796355a8fd67e0'] = { right = { z = -0.1524 } }, -- marksman_rifle_drake: third-person six inches down
    ['1abbff60d26ba391'] = { right = { z = -0.1524 } }, -- marksman_rifle_shark: third-person six inches down
    ['03e67a19b07c6523'] = { right = { z = -0.1524 } }, -- marksman_rifle_vigilance: third-person six inches down
    ['4c786785c79d44e7'] = { right = { z = -0.1524 } }, -- marksman_rifle_vigilance_burst: third-person six inches down
    ['6e68194b95d60145'] = { right = { z = -0.1524 } }, -- marksman_rifle_vigilance_counter_sniper: third-person six inches down
    ['eea5e3cef1e12c14'] = { right = { z = -0.1524 } }, -- plasma_rifle: third-person six inches down
    ['fb3a19078694708a'] = { right = { z = -0.1524 } }, -- plasma_rifle_charge: third-person six inches down
    ['efdcef306cea63fe'] = { right = { z = -0.1524 } }, -- plasma_rifle_charge: third-person six inches down
    ['30061f91af477f5e'] = { right = { z = -0.1524 } }, -- sniper_rifle_helghast: third-person six inches down
}
