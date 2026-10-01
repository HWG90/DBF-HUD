-- Place beside DBF-HUD-tuning.lua in the Helldivers 2 game folder.
-- Reload DBF-HUD in MDL (or restart the game) after editing this file.
-- Auto placement only. Values are additional weapon-local metres:
-- X right, Y forward, Z up. Negative Y moves back toward the shooter.
-- Views: right, left, first_left, first_right. Missing views add no correction.
-- Menu saves do not overwrite this file. An empty return table disables all profiles.
return {
    ['be70ee0d8d44028e'] = { right = { x = -0.0508, z = -0.1524 }, first_left = { z = -0.1524 }, first_right = { z = -0.1524 } }, -- Halo SMG: six inches down in all views
    ['f0338468dcdb6a6c'] = { right = { x = -0.0254, z = -0.1524 }, first_left = { x = -0.0254, z = -0.1524 }, first_right = { x = -0.0254, z = -0.1524 } }, -- Sensor: one inch left, six down in all views
    ['e6d932be83729076'] = { first_left = { z = -0.0889 }, first_right = { z = -0.0889 } }, -- Deadeye: first-person 3.5 inches down
    ['d54b9505c0f72873'] = { first_left = { x = 0.0508 }, first_right = { x = -0.1892 } }, -- laser_cannon: first-person left override
    ['3575aabc5f1f9326'] = { right = { x = 0.0762, z = -0.0762 } }, -- automatic_pistol
    ['0b882808c6f498e8'] = { right = { x = 0.0762, z = -0.0762 } }, -- caustic_dart_gun
    ['416d053372c4e433'] = { right = { x = 0.0762, z = -0.0762 } }, -- energy_revolver
    ['3f92ba65ef65cca9'] = { right = { x = 0.0762, z = -0.0762 } }, -- flamer_pistol
    ['52e4334e6a128caf'] = { right = { x = 0.0762, z = -0.0762 } }, -- grenade_pistol
    ['e91f569c2ad8af01'] = { right = { x = 0.0762, z = -0.0762 } }, -- hornet_pistol
    ['7b06196e90154c88'] = { right = { x = 0.0762, z = -0.0762 } }, -- laser_pistol
    ['1a437158e1b8d2a1'] = { right = { x = 0.0762, z = -0.0762 } }, -- magnum_pistol
    ['c780bcd79547da0f'] = { right = { x = 0.0762, z = -0.0762 } }, -- pistol_broomhandle
    ['9eb160830321bfd6'] = { right = { x = 0.0762, z = -0.0762 } }, -- pistol_cricket
    ['4d58c77087b774c5'] = { right = { x = 0.0762, z = -0.0762 } }, -- pistol_nacho
    ['dbb6c961c59fadc1'] = { right = { x = 0.0762, z = -0.0762 } }, -- pistol_shark
    ['aa69a60d74a3ec54'] = { right = { x = 0.0762, z = -0.0762 } }, -- plasma_pistol
    ['8d3d52a3b2f19402'] = { right = { x = 0.0762, z = -0.0762 } }, -- revolver_pistol
    ['bde1f2534280300d'] = { right = { x = 0.0762, z = -0.0762 } }, -- revolver_pistol_long
    ['cf8934ff6567a42d'] = { right = { x = 0.0762, z = -0.0762 } }, -- smart_pistol
    ['05e4e5c2db6e44a2'] = { right = { x = 0.0762, z = -0.0762 } }, -- standard_pistol
    ['d6b1fb05b9109353'] = { right = { x = 0.0762, z = -0.0762 } }, -- stim_pistol
    ['25aa2fd4643cf4ee'] = { -- Spear (catalog asset identity; not yet visually tested)
        right = { x = 0.1524 },
        first_right = { x = -0.24 }, -- Keep first person on the left.
    },
    ['9f80d67a12a7e40f'] = { -- Recoilless rifle
        right = { x = 0.1524 },
        first_right = { x = -0.24 }, -- Mirror the default +0.12 mount to -0.12 (left).
    },
    ['27ee1ed8f6fb6356'] = { -- Scythe
        right = { x = 0.0762, y = 0.1270, z = 0 },
    },
    ['a8cffb316f0b5c5f'] = { -- Autocannon
        right = { x = 0.12, y = -0.08, z = 0.10 },
    },
}
