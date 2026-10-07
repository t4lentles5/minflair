hl.window_rule({ match = { class = "^io.github.tanaybhomia.Whisp$" }, float = true, size = "800 500", center = true })
hl.window_rule({ match = { class = "^vlc$" }, float = true })
hl.window_rule({ match = { class = "^org.gnome.Loupe$" }, float = true, size = "1200 800", center = true })
hl.window_rule({ match = { class = "^org.pulseaudio.pavucontrol$" }, float = true, size = "920 450", center = true })
hl.window_rule({ match = { class = "^blueman-manager$" }, float = true, size = "700 600", center = true })
hl.window_rule({ match = { class = "^org.gnome.Calculator$" }, float = true, size = "920 450", center = true })
hl.window_rule({ match = { class = "^kitty-floating$" }, float = true, size = "1000 600", center = true })
hl.window_rule({ match = { class = "^xdg-desktop-portal-gtk$" }, float = true, size = "900 600", center = true })
hl.window_rule({
	match = { title = "^Open File|Save As|Save File|.*wants to open.*|.*wants to save.*$" },
	float = true,
	size = "900 600",
	center = true,
})

hl.window_rule({ match = { class = "^steam$", title = "^Friends List.*$|^Lista de amigos.*$" }, float = true, size = "420 750", center = true, rounding = 16 })
hl.window_rule({ match = { class = "^steam$", title = "^Steam Settings$|^Parámetros.*$|^Settings$" }, float = true, size = "950 680", center = true, rounding = 16 })
hl.window_rule({ match = { class = "^steam$", title = "^notificationtoasts_.*$" }, float = true, rounding = 16 })
hl.window_rule({ match = { class = "^steam$", title = "^$" }, rounding = 16 })
hl.window_rule({ match = { class = "^steam$", title = "^Steam - News$|^Special Offers$|^CD key.*$|^Steam Guard.*$" }, float = true, center = true, rounding = 16 })

hl.window_rule({ match = { title = "^Select a File|Choose wallpaper|Open Folder|Library|File Upload$" }, float = true })
hl.window_rule({ match = { title = "^Minflair Settings$" }, float = true, size = "1200 750", center = true })
hl.window_rule({ match = { title = "^Minflair Keybinds Cheat Sheet$" }, float = true, size = "1100 700", center = true })
hl.window_rule({ match = { title = "^Minflair Package Manager" }, float = true, size = "1300 800", center = true })

hl.layer_rule({
	match = { namespace = "quickshell" },
	blur = true,
	xray = false,
	ignore_alpha = 0.45,
	animation = "off",
})
