# dripkit fish shell colors
# Sourced by dripkit, not run directly

local theme_dir="$1"

mkdir -p "$CONFIG_DIR/fish/conf.d"
cat > "$CONFIG_DIR/fish/conf.d/dripkit-colors.fish" << FISH
# dripkit fish theme — applied by dripkit

set -U fish_color_normal ${COLORS[fg_nohash]:-cdd6f4}
set -U fish_color_command ${COLORS[blue_nohash]:-89b4fa}
set -U fish_color_keyword ${COLORS[mauve_nohash]:-cba6f7}
set -U fish_color_quote ${COLORS[green_nohash]:-a6e3a1}
set -U fish_color_redirection ${COLORS[pink_nohash]:-f5c2e7}
set -U fish_color_end ${COLORS[peach_nohash]:-fab387}
set -U fish_color_error ${COLORS[red_nohash]:-f38ba8}
set -U fish_color_param ${COLORS[fg_nohash]:-cdd6f4}
set -U fish_color_comment ${COLORS[overlay0_nohash]:-6c7086}
set -U fish_color_selection --background=${COLORS[surface1_nohash]:-45475a}
set -U fish_color_search_match --background=${COLORS[surface1_nohash]:-45475a}
set -U fish_color_operator ${COLORS[teal_nohash]:-94e2d5}
set -U fish_color_escape ${COLORS[pink_nohash]:-f5c2e7}
set -U fish_color_autosuggestion ${COLORS[overlay0_nohash]:-6c7086}
set -U fish_color_cancel ${COLORS[red_nohash]:-f38ba8}

set -U fish_pager_color_progress ${COLORS[overlay0_nohash]:-6c7086}
set -U fish_pager_color_prefix ${COLORS[accent_nohash]:-89b4fa}
set -U fish_pager_color_completion ${COLORS[fg_nohash]:-cdd6f4}
set -U fish_pager_color_description ${COLORS[overlay0_nohash]:-6c7086}
set -U fish_pager_color_selected_background --background=${COLORS[surface1_nohash]:-45475a}
FISH

# Source it immediately if fish is available
if command -v fish &>/dev/null; then
    fish -c "source $CONFIG_DIR/fish/conf.d/dripkit-colors.fish" 2>/dev/null || true
fi
