# dripkit — Claude Code Guide

## What is this

dripkit is a Hyprland theme framework. It applies color palettes across the entire desktop (Hyprland, waybar, rofi, alacritty, dunst, hyprlock, hyprpaper, GTK, Qt) using a template system.

## Architecture

- `bin/dripkit` — Bash CLI. Reads `colors.conf` from a theme, substitutes `{{var}}` placeholders in module templates, writes output to `~/.config/`. Restarts affected services.
- `modules/` — Each subdirectory is a module (app). Contains either `template.*` files (rendered via variable substitution) or `apply.sh` (sourced by dripkit for custom logic like GTK/Qt).
- `themes/` — Each subdirectory is a theme. Must contain `colors.conf` (variables) and `theme.toml` (metadata). Can optionally contain `overrides/<module>/` with full config files that bypass templates.
- `bin/dripkit-picker` — Rofi-based GUI picker. Generates wallpaper thumbnails with ImageMagick.

## How the template engine works

1. Reads all `key = value` pairs from `themes/<name>/colors.conf` into a bash associative array
2. Also reads `themes/<name>/theme.toml` for metadata (wallpaper path, name, etc.)
3. For each module: checks for overrides first (copies directly), otherwise renders templates by replacing `{{key}}` with values
4. GTK and Qt modules use `apply.sh` scripts instead of templates
5. Restarts waybar, dunst, hyprpaper after applying

## Key conventions

- Colors in `colors.conf` use `#hex` format for CSS/config use, plus `_rgb` variants (no `#`) for Hyprland's `rgba()` function
- Template variables are `{{double_braces}}`
- Hyprland config goes to `~/.config/hypr/config/dripkit.conf` which is sourced by the user's hyprland.conf
- Alacritty theme goes to `~/.config/alacritty/dripkit.toml` which is imported by the user's config
- Waybar and rofi configs are written directly (overwritten on theme change)

## Adding a new theme

1. Create `themes/<name>/colors.conf` with the full palette (copy catppuccin-mocha as reference for all required variables)
2. Create `themes/<name>/theme.toml` with name, description, author, variant, wallpaper path
3. Optionally add `overrides/waybar/` with custom `config.jsonc` and `style.css`
4. Run `dripkit apply <name>` to test

## Adding a new module

1. Create `modules/<name>/template.<ext>` using `{{variables}}` from colors.conf
2. Add a case to `get_module_target()` in `bin/dripkit` mapping the module to its output path
3. For complex modules, use `apply.sh` instead (it gets sourced with theme_dir as $1)

## Hyprland version notes

This targets Hyprland 0.53+ which uses the new windowrule `match:` syntax:
- `windowrule = float on, match:class ^(app)$`
- Boolean fields need values: `float on`, `pin on`, `no_blur on`
- `border_size` not `bordersize`, `border_color` not `bordercolor`

## Waybar icon notes

Icons use Font Awesome codepoints in the range U+F000–F381 which are included in JetBrainsMono Nerd Font. Codepoints above F381 (Material Design Icons range) are NOT in this font and will render as boxes. Always verify icons are in range before using.

## Testing changes

After editing any template or theme file:
```bash
./bin/dripkit apply catppuccin-mocha
```
Take a screenshot to verify: `grim /tmp/screenshot.png`

The user's display is 2880x1800 at 1.5x scale = effective 1920x1200. Size UI elements accordingly.
