# dripkit bat theme
# Sourced by dripkit, not run directly

local theme_dir="$1"
local variant="${COLORS[variant]:-dark}"

# bat uses built-in themes. Pick the closest match for the palette.
local bat_theme="Catppuccin Mocha"
case "$variant" in
    dark)  bat_theme="base16" ;;
    light) bat_theme="GitHub" ;;
esac

# Check if catppuccin bat theme is installed
if bat --list-themes 2>/dev/null | grep -qi "catppuccin"; then
    case "${COLORS[name]:-}" in
        *ocha*)    bat_theme="Catppuccin Mocha" ;;
        *acchiato*) bat_theme="Catppuccin Macchiato" ;;
        *rappe*)   bat_theme="Catppuccin Frappe" ;;
        *atte*)    bat_theme="Catppuccin Latte" ;;
    esac
fi

mkdir -p "$CONFIG_DIR/bat"
cat > "$CONFIG_DIR/bat/config" << BAT
--theme="$bat_theme"
--style="numbers,changes,header"
--italic-text=always
BAT
