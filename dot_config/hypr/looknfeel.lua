-- Change the default Omarchy look'n'feel.

-- https://wiki.hypr.land/Configuring/Basics/Variables/#general
hl.config({
  general = {
    -- No gaps between windows.
    gaps_in = 0,
    gaps_out = 0,
  },

  group = {
    insert_after_current = true,

    -- Group members are selected from the top bar instead.
    groupbar = {
      enabled = false,
    },
  },
})

-- https://wiki.hypr.land/Configuring/Basics/Variables/#decoration
-- hl.config({
--   decoration = {
--     -- Use round window corners.
--     rounding = 8,
--
--     -- Dim unfocused windows (0.0 = no dim, 1.0 = fully dimmed).
--     dim_inactive = true,
--     dim_strength = 0.15,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#animations
-- hl.config({
--   animations = {
--     -- Disable all animations.
--     enabled = false,
--   },
-- })

-- https://wiki.hypr.land/Configuring/Basics/Variables/#layout
-- hl.config({
--   layout = {
--     -- Avoid overly wide single-window layouts on wide screens.
--     single_window_aspect_ratio = { 1, 1 },
--   },
-- })

-- https://wiki.hypr.land/Configuring/Layouts/Scrolling-Layout/
-- hl.config({
--   scrolling = {
--     -- See only one column per screen instead of two.
--     column_width = 0.97,
--   },
-- })

-- >>> omaland managed block >>>
-- Written by Omaland. Safe to hand-edit: Omaland re-reads this block
-- every time it opens, and only ever rewrites what's between the fences.
hl.config({
  decoration = {
    active_opacity = 1,
    border_part_of_window = true,
    fullscreen_opacity = 1,
    inactive_opacity = 1,

    glow = {
      enabled = true,
      range = 26,
      render_power = 4,
    },

    shadow = {
      enabled = false,
      range = 44,
      render_power = 2,
      scale = 0.92,
    },
  },

  general = {
    gaps_in = 0,
    gaps_out = 1,
    layout = "dwindle",

    snap = {
      enabled = false,
    },
  },
})
-- <<< omaland managed block <<<
