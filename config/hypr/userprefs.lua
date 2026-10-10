local colors = require("colors")

hl.config({
	general = {
		gaps_in = 4,
		gaps_out = 8,
		border_size = 0,
		["col.active_border"] = colors.accent_alpha,
		["col.inactive_border"] = colors.border_alpha,
		allow_tearing = false,
		layout = "dwindle",
	},
	group = {
		groupbar = {
			height = 16,
			indicator_gap = 8,
			["col.active"] = colors.accent_alpha,
			["col.inactive"] = colors.border_alpha,
			text_color = colors.accent_alpha,
			text_color_inactive = colors.border_alpha,
			font_size = 11,
			font_family = "Geist",
			font_weight_active = "bold",
			blur = true,
		},
	},
	decoration = {
		rounding = 32,
		rounding_power = 2,
		active_opacity = 1,
		inactive_opacity = 1,
		blur = {
			enabled = true,
			size = 6,
			passes = 4,
			new_optimizations = true,
			ignore_opacity = true,
			xray = false,
			noise = 0.0117,
			contrast = 0.8916,
			brightness = 0.8172,
			vibrancy = 0.1696,
			vibrancy_darkness = 0.0,
			popups = true,
			popups_ignorealpha = 0.2,
			input_methods = true,
			special = true,
		},
		shadow = {
			enabled = true,
			range = 8,
			render_power = 3,
			color = colors.shadow,
		},
	},
	dwindle = {
		preserve_split = true,
	},
	master = {
		new_status = "master",
	},
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		initial_workspace_tracking = 0,
	},
	cursor = {
		inactive_timeout = 5,
		warp_on_change_workspace = true,
		no_warps = false,
	},
	input = {
		kb_rules = "evdev",
		kb_model = "pc105",
		kb_layout = "us,es",
		follow_mouse = 1,
		sensitivity = 0,
		touchpad = {
			natural_scroll = true,
			tap_to_click = true,
			disable_while_typing = true,
		},
		accel_profile = "flat",
		natural_scroll = false,
		scroll_factor = 1,
		left_handed = false,
	},
	xwayland = {
		force_zero_scaling = true,
	},
	device = {
		{
			name = "epic-mouse-v1",
			sensitivity = -0.5,
		},
	},
	animations = {
		enabled = true,
	},
})
