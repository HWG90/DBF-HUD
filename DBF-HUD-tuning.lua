-- Optional starter tuning. Copy into the Helldivers 2 installation root, beside bin.
-- The preview exports this format. Native menu edits save here automatically.
-- Restart to load edits, or call DBFHUD.reload_tuning() from your Lua integration.
return {
    emissive_intensity = 3,
    font = "bigblue", -- "bigblue" pixel font or "debug" original renderer
    text_color = "#C4CECA",
    background_color = "#202628",
    heat_white = "#E5E7E2",
    heat_yellow = "#E7C85C",
    heat_red = "#E16D65",
    offset_x = 62,
    offset_y = -5, -- positive is up; values use 1080p reference pixels
    scale = 1,
    opacity = 0.92,
    panel_opacity = 0.55,
    frosted = true,
    follow = 0.65,
    travel = 55,
    settle = 0.22,
    flash_hz = 2, -- complete red/yellow cycles per second
}
