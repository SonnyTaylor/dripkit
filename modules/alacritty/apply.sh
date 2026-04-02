# dripkit alacritty theme
# Sourced by dripkit, not run directly

local theme_dir="$1"
local alacritty_dir="$CONFIG_DIR/alacritty"
local main_config="$alacritty_dir/alacritty.toml"
local theme_config="$alacritty_dir/dripkit.toml"

mkdir -p "$alacritty_dir"

# Write the dripkit theme file
cat > "$theme_config" << ALACRITTY
# dripkit alacritty theme

[font]
size = 12.0

[font.normal]
family = "${COLORS[mono_font]}"
style = "Regular"

[font.bold]
family = "${COLORS[mono_font]}"
style = "Bold"

[font.italic]
family = "${COLORS[mono_font]}"
style = "Italic"

[window]
opacity = ${COLORS[terminal_opacity]}
padding = { x = 12, y = 12 }

[colors.primary]
background = "${COLORS[bg]}"
foreground = "${COLORS[fg]}"

[colors.cursor]
text = "${COLORS[bg]}"
cursor = "${COLORS[accent]}"

[colors.vi_mode_cursor]
text = "${COLORS[bg]}"
cursor = "${COLORS[accent2]}"

[colors.selection]
text = "${COLORS[bg]}"
background = "${COLORS[accent]}"

[colors.normal]
black =   "${COLORS[color0]}"
red =     "${COLORS[red]}"
green =   "${COLORS[green]}"
yellow =  "${COLORS[yellow]}"
blue =    "${COLORS[blue]}"
magenta = "${COLORS[mauve]}"
cyan =    "${COLORS[teal]}"
white =   "${COLORS[color7]}"

[colors.bright]
black =   "${COLORS[color8]}"
red =     "${COLORS[red]}"
green =   "${COLORS[green]}"
yellow =  "${COLORS[yellow]}"
blue =    "${COLORS[blue]}"
magenta = "${COLORS[mauve]}"
cyan =    "${COLORS[teal]}"
white =   "${COLORS[fg]}"
ALACRITTY

# If no main config exists, create a minimal one with import
if [[ ! -f "$main_config" ]]; then
    cat > "$main_config" << 'DEFAULT'
[general]
import = ["~/.config/alacritty/dripkit.toml"]
live_config_reload = true
DEFAULT
    return 0
fi

# Ensure dripkit.toml is imported
if ! grep -q 'dripkit\.toml' "$main_config" 2>/dev/null; then
    if grep -q '^import[[:space:]]*=' "$main_config"; then
        # Existing import line — prepend dripkit.toml to it
        sed -i 's|import[[:space:]]*=[[:space:]]*\[|import = ["~/.config/alacritty/dripkit.toml", |' "$main_config"
    elif grep -q '^\[general\]' "$main_config"; then
        # [general] exists but no import — add import line
        sed -i '/^\[general\]/a import = ["~/.config/alacritty/dripkit.toml"]' "$main_config"
    else
        # No [general] section — prepend it
        local tmp
        tmp="$(mktemp)"
        printf '[general]\nimport = ["~/.config/alacritty/dripkit.toml"]\n\n' > "$tmp"
        cat "$main_config" >> "$tmp"
        mv "$tmp" "$main_config"
    fi
fi

# Remove sections from main config that conflict with dripkit.toml
# This ensures the import actually takes effect for: fonts, colors, opacity
local tmp
tmp="$(mktemp)"
awk '
    BEGIN { skip = 0 }
    /^\[/ {
        if ($0 ~ /^\[font/ || $0 ~ /^\[colors/) {
            skip = 1
            next
        } else {
            skip = 0
        }
    }
    skip { next }
    /^[[:space:]]*opacity[[:space:]]*=/ { next }
    /^[[:space:]]*padding[[:space:]]*=/ { next }
    { print }
' "$main_config" > "$tmp"
mv "$tmp" "$main_config"
