-- Pull in the wezterm API
local wezterm = require("wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size = 19

config.window_background_opacity = 1.0
config.macos_window_background_blur = 10
config.native_macos_fullscreen_mode = true

-- tokyonight_night coolnight colorscheme:
config.color_scheme = "tokyonight_night"

-- i hate that opt+return minimizes the window. also messes up claude code
config.keys = {
	{ key = "Enter", mods = "ALT", action = wezterm.action.DisableDefaultAssignment },
}

-- and finally, return the configuration to wezterm
return config
