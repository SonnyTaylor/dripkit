# dripkit Qt apply module
# Sourced by dripkit, not run directly

local theme_dir="$1"
local kvantum_theme="${COLORS[kvantum_theme]:-KvFlat}"

# qt5ct
mkdir -p "$CONFIG_DIR/qt5ct"
cat > "$CONFIG_DIR/qt5ct/qt5ct.conf" << EOF
[Appearance]
style=kvantum
color_scheme_path=
custom_palette=false
icon_theme=${COLORS[icon_theme]:-Papirus-Dark}
standard_dialogs=default
EOF

# qt6ct
mkdir -p "$CONFIG_DIR/qt6ct"
cat > "$CONFIG_DIR/qt6ct/qt6ct.conf" << EOF
[Appearance]
style=kvantum
color_scheme_path=
custom_palette=false
icon_theme=${COLORS[icon_theme]:-Papirus-Dark}
standard_dialogs=default
EOF

# Kvantum
mkdir -p "$CONFIG_DIR/Kvantum"
cat > "$CONFIG_DIR/Kvantum/kvantum.kvconfig" << EOF
[General]
theme=$kvantum_theme
EOF
