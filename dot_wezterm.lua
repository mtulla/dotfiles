-- Pull in the wezterm API
local wezterm = require("wezterm")
local act = wezterm.action

-- resurrect plugin
local resurrect = wezterm.plugin.require("https://github.com/MLFlexer/resurrect.wezterm")

-- This will hold the configuration.
local config = wezterm.config_builder()

-- This is where you actually apply your config choices

config.font = wezterm.font("MesloLGS Nerd Font Mono")
config.font_size = 16

config.window_background_opacity = 1.0
config.macos_window_background_blur = 10
config.native_macos_fullscreen_mode = true

-- tokyonight_night coolnight colorscheme:
config.color_scheme = "tokyonight_night"

-- Set Keybindings
config.keys = {}
-- i hate that opt+return minimizes the window. also messes up claude code
table.insert(config.keys, { key = "Enter", mods = "ALT", action = wezterm.action.DisableDefaultAssignment })

-- Move tabs left or right with Shift+Alt+{ and Shift+Alt+}
table.insert(config.keys, { key = "{", mods = "SHIFT|ALT", action = act.MoveTabRelative(-1) })
table.insert(config.keys, { key = "}", mods = "SHIFT|ALT", action = act.MoveTabRelative(1) })

-- rename tab with Ctrl+Shift+E
table.insert(config.keys, {
	key = "E",
	mods = "CTRL|SHIFT",
	action = act.PromptInputLine({
		description = "Enter new name for tab",
		action = wezterm.action_callback(function(window, pane, line)
			if line then
				window:active_tab():set_title(line)
			end
		end),
	}),
})

-- resurrecting
resurrect.state_manager.periodic_save({
	interval_seconds = 15 * 60,
	save_workspaces = true,
	save_windows = true,
	save_tabs = true,
})
wezterm.on("gui-startup", resurrect.state_manager.resurrect_on_gui_startup)

-- and finally, return the configuration to wezterm
return config
