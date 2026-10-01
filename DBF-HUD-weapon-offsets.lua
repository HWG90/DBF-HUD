-- Place beside DBF-HUD-tuning.lua in the Helldivers 2 game folder.
-- Reload DBF-HUD in MDL (or restart the game) after editing this file.
-- Auto placement only. Values are additional weapon-local metres:
-- X right, Y forward, Z up. Negative Y moves back toward the shooter.
-- Views: right, left, first_left, first_right. Missing views add no correction.
-- Menu saves do not overwrite this file. An empty return table disables all profiles.
return {
    ['27ee1ed8f6fb6356'] = { -- Scythe
        right = { x = 0.0762, y = 0.1270, z = 0 },
    },
    ['a8cffb316f0b5c5f'] = { -- Autocannon
        right = { x = 0.12, y = -0.08, z = 0.10 },
    },
}
