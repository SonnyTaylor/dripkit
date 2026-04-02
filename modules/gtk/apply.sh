# dripkit GTK apply module
# Sourced by dripkit, not run directly

local theme_dir="$1"
local gtk_theme="${COLORS[gtk_theme]:-Adwaita-dark}"
local icon_theme="${COLORS[icon_theme]:-Papirus-Dark}"
local cursor_theme="${COLORS[cursor_theme]:-Bibata-Modern-Classic}"
local font="${COLORS[font]:-Fira Sans}"

# GTK 3
mkdir -p "$CONFIG_DIR/gtk-3.0"
cat > "$CONFIG_DIR/gtk-3.0/settings.ini" << EOF
[Settings]
gtk-theme-name=$gtk_theme
gtk-icon-theme-name=$icon_theme
gtk-cursor-theme-name=$cursor_theme
gtk-font-name=$font 11
gtk-application-prefer-dark-theme=1
EOF

# GTK 4
mkdir -p "$CONFIG_DIR/gtk-4.0"
cat > "$CONFIG_DIR/gtk-4.0/settings.ini" << EOF
[Settings]
gtk-theme-name=$gtk_theme
gtk-icon-theme-name=$icon_theme
gtk-cursor-theme-name=$cursor_theme
gtk-font-name=$font 11
gtk-application-prefer-dark-theme=1
EOF

# Set via gsettings if available
if command -v gsettings &>/dev/null; then
    gsettings set org.gnome.desktop.interface gtk-theme "$gtk_theme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface icon-theme "$icon_theme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface cursor-theme "$cursor_theme" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface font-name "$font 11" 2>/dev/null || true
    gsettings set org.gnome.desktop.interface color-scheme "prefer-dark" 2>/dev/null || true
fi
