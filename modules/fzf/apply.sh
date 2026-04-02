# dripkit fzf colors
# Sourced by dripkit, not run directly

local theme_dir="$1"

# fzf reads colors from FZF_DEFAULT_OPTS env var
# Write a fish config that sets it
mkdir -p "$CONFIG_DIR/fish/conf.d"
cat > "$CONFIG_DIR/fish/conf.d/dripkit-fzf.fish" << FZF
# dripkit fzf colors
set -gx FZF_DEFAULT_OPTS "\
--color=bg+:${COLORS[surface0]},bg:${COLORS[bg]},spinner:${COLORS[teal]},hl:${COLORS[red]} \
--color=fg:${COLORS[fg]},header:${COLORS[red]},info:${COLORS[mauve]},pointer:${COLORS[teal]} \
--color=marker:${COLORS[teal]},fg+:${COLORS[fg]},prompt:${COLORS[mauve]},hl+:${COLORS[red]} \
--color=border:${COLORS[surface1]} \
--border=rounded \
--padding=1"
FZF
