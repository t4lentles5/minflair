-- Animations Configuration for Hyprland Lua

hl.config({
	animations = {
		enabled = true,
	},
})

-- Define curves
hl.curve("ease", { type = "bezier", points = { { 0.25, 0.1 }, { 0.25, 1.0 } } })
hl.curve("overshot", { type = "bezier", points = { { 0.13, 0.99 }, { 0.29, 1.05 } } })
hl.curve("easeInOut", { type = "bezier", points = { { 0.42, 0 }, { 0.58, 1.0 } } })
hl.curve("spring", { type = "bezier", points = { { 0.5, 1.6 }, { 0.4, 0.8 } } })

-- Define animations
hl.animation({ leaf = "windowsIn", enabled = true, speed = 4, bezier = "overshot", style = "popin 80%" })
hl.animation({ leaf = "windowsOut", enabled = true, speed = 3, bezier = "ease", style = "popin 85%" })
hl.animation({ leaf = "windowsMove", enabled = true, speed = 4, bezier = "overshot" })
hl.animation({ leaf = "fade", enabled = true, speed = 3, bezier = "ease" })
hl.animation({ leaf = "fadeDim", enabled = true, speed = 4, bezier = "ease" })
hl.animation({ leaf = "border", enabled = true, speed = 2, bezier = "ease" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 5, bezier = "overshot", style = "slide" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 5, bezier = "overshot", style = "slidevert" })
