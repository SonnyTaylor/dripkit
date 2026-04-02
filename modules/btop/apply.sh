# dripkit btop theme
# Sourced by dripkit, not run directly

local theme_dir="$1"

mkdir -p "$CONFIG_DIR/btop/themes"
cat > "$CONFIG_DIR/btop/themes/dripkit.theme" << BTOP
# dripkit btop theme

# Main background
theme[main_bg]="${COLORS[bg]}"

# Main text color
theme[main_fg]="${COLORS[fg]}"

# Title color for boxes
theme[title]="${COLORS[fg]}"

# Highlight color for keyboard shortcuts
theme[hi_fg]="${COLORS[accent]}"

# Background color of selected items
theme[selected_bg]="${COLORS[surface0]}"

# Foreground color of selected items
theme[selected_fg]="${COLORS[accent]}"

# Color of inactive/disabled text
theme[inactive_fg]="${COLORS[overlay0]}"

# Color of text appearing on top of graphs
theme[graph_text]="${COLORS[subtext0]}"

# Misc
theme[meter_bg]="${COLORS[surface0]}"
theme[proc_misc]="${COLORS[yellow]}"

# Cpu box outline color
theme[cpu_box]="${COLORS[surface1]}"

# Memory/disks box outline color
theme[mem_box]="${COLORS[surface1]}"

# Net up/down box outline color
theme[net_box]="${COLORS[surface1]}"

# Processes box outline color
theme[proc_box]="${COLORS[surface1]}"

# Box divider line and target line color
theme[div_line]="${COLORS[surface1]}"

# Temperature graph colors
theme[temp_start]="${COLORS[teal]}"
theme[temp_mid]="${COLORS[yellow]}"
theme[temp_end]="${COLORS[red]}"

# CPU graph colors
theme[cpu_start]="${COLORS[teal]}"
theme[cpu_mid]="${COLORS[blue]}"
theme[cpu_end]="${COLORS[mauve]}"

# Mem/Disk free meter
theme[free_start]="${COLORS[green]}"
theme[free_mid]="${COLORS[green]}"
theme[free_end]="${COLORS[green]}"

# Mem/Disk cached meter
theme[cached_start]="${COLORS[blue]}"
theme[cached_mid]="${COLORS[blue]}"
theme[cached_end]="${COLORS[blue]}"

# Mem/Disk available meter
theme[available_start]="${COLORS[yellow]}"
theme[available_mid]="${COLORS[yellow]}"
theme[available_end]="${COLORS[yellow]}"

# Mem/Disk used meter
theme[used_start]="${COLORS[red]}"
theme[used_mid]="${COLORS[red]}"
theme[used_end]="${COLORS[red]}"

# Download graph colors
theme[download_start]="${COLORS[teal]}"
theme[download_mid]="${COLORS[blue]}"
theme[download_end]="${COLORS[mauve]}"

# Upload graph colors
theme[upload_start]="${COLORS[green]}"
theme[upload_mid]="${COLORS[yellow]}"
theme[upload_end]="${COLORS[red]}"

# Process box color gradient for threads, mem and cpu usage
theme[process_start]="${COLORS[accent]}"
theme[process_mid]="${COLORS[mauve]}"
theme[process_end]="${COLORS[red]}"
BTOP

# Set btop to use dripkit theme
if [[ -f "$CONFIG_DIR/btop/btop.conf" ]]; then
    sed -i 's/^color_theme = .*/color_theme = "dripkit"/' "$CONFIG_DIR/btop/btop.conf"
else
    mkdir -p "$CONFIG_DIR/btop"
    echo 'color_theme = "dripkit"' > "$CONFIG_DIR/btop/btop.conf"
fi
