-- Keep only your personal input overrides here. Uncommented settings below
-- replace Omarchy's defaults.

-- Keyboard layout and options.
-- See https://wiki.hypr.land/Configuring/Basics/Variables/#input
--
-- #  ~/.config/hypr/input.lua 
hl.config({
  -- setting for botamd5
  input = {
    kb_layout = "us,th",
    kb_options = "altwin:swap_lalt_lwin,grp:alt_space_toggle",

    touchpad = {
      natural_scroll = true,
      disable_while_typing = true,
      scroll_factor = 0.5
    },
  },
})
