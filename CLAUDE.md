# dripkit — Claude Code Guide

## What is this

dripkit is a Hyprland theme framework. It applies color palettes and custom layouts across 17 desktop apps using a template + override system.

## Architecture

- `bin/dripkit` — Bash CLI. Reads `colors.conf` from a theme, substitutes `{{var}}` placeholders in module templates, writes output to `~/.config/`. Restarts affected services.
- `bin/dripkit-picker` — Rofi-based GUI picker. Generates wallpaper thumbnails with ImageMagick.
- `bin/dripkit-keybinds` — Keybinds cheat sheet. Parses live binds from `hyprctl binds -j`.
- `modules/` — 17 modules. Each has either `template.*` files (rendered via substitution) or `apply.sh` (sourced by dripkit for custom logic).
- `themes/` — 5 themes. Each has `colors.conf`, `theme.toml`, wallpapers, and optional `overrides/`.
- `install.sh` — Atomic installer with backup/restore. Flags: `--auto`, `--uninstall`, `--dry-run`.

## Modules (17)

Template-based: hyprland, waybar, rofi, alacritty, dunst, hyprlock, hyprpaper, cava, fastfetch, starship, wlogout
Script-based (apply.sh): gtk, qt, fish, btop, bat, fzf

## How the template engine works

1. Reads `key = value` pairs from `colors.conf` into a bash associative array
2. Auto-generates `_nohash` variants (strips `#` from hex colors) for apps needing bare hex
3. Reads `theme.toml` for metadata (wallpaper, name, etc.)
4. Resolves relative wallpaper paths against the theme directory
5. For each module: checks `overrides/<module>/` first (copies directly), otherwise renders `template.*` files by replacing `{{key}}` with values
6. Script modules (`apply.sh`) get sourced with theme_dir as $1 and have access to the COLORS array
7. Restarts waybar, dunst, hyprpaper after applying

## Key conventions

- Colors in `colors.conf` use `#hex` format. `_rgb` variants (no `#`) are for Hyprland's `rgba()`. `_nohash` variants are auto-generated.
- Template variables: `{{double_braces}}`
- Hyprland config → `~/.config/hypr/config/dripkit.conf` (sourced by user's config)
- Alacritty theme → `~/.config/alacritty/dripkit.toml` (imported by user's config)
- Waybar config/CSS → overwritten directly on theme change
- Fish colors → `~/.config/fish/conf.d/dripkit-colors.fish`
- fzf colors → `~/.config/fish/conf.d/dripkit-fzf.fish`
- btop theme → `~/.config/btop/themes/dripkit.theme`
- Starship → `~/.config/starship.toml`

## Target path mapping

Defined in `get_module_target()` in `bin/dripkit`:
- hyprland → `~/.config/hypr/config/dripkit.conf`
- waybar `*.css` → `~/.config/waybar/style.css`, else → `~/.config/waybar/config`
- rofi → `~/.config/rofi/dripkit.rasi`
- alacritty → `~/.config/alacritty/dripkit.toml`
- dunst → `~/.config/dunst/dunstrc`
- hyprlock → `~/.config/hypr/hyprlock.conf`
- hyprpaper → `~/.config/hypr/hyprpaper.conf`
- cava → `~/.config/cava/config`
- fastfetch → `~/.config/fastfetch/config.jsonc`
- starship → `~/.config/starship.toml`
- wlogout `*.css` → `~/.config/wlogout/style.css`, else → `~/.config/wlogout/layout`

## Adding a new theme

1. Copy `themes/catppuccin-mocha/colors.conf` as a starting point — it has all required variables
2. Create `themes/<name>/theme.toml` with name, description, author, variant, wallpaper (relative path)
3. Add wallpapers to `themes/<name>/wallpapers/`
4. Optionally add `overrides/waybar/` with `config.jsonc` + `style.css` for a unique bar layout
5. Test with `dripkit apply <name>`

## Adding a new module

1. Create `modules/<name>/template.<ext>` using `{{variables}}` OR `modules/<name>/apply.sh`
2. Add a case to `get_module_target()` in `bin/dripkit`
3. For apply.sh modules: the script gets sourced (not executed), has access to `COLORS` array and `CONFIG_DIR`

## Waybar icon notes

JetBrainsMono Nerd Font icon range: U+E000-E00A, E0A0-E0C8, E200-E2A9, E300-E3E3, E5FA-E6B8, E700-E8EF, EA60-EB4E, EB50-EC1E, ED00-EFCE, F000-F381.

Codepoints above F381 (Material Design Icons) are NOT in this font and render as boxes. When writing waybar configs with icons, use Python to embed unicode:
```python
import json
config = {"format": chr(0xf017) + " {:%H:%M}"}
with open('config.jsonc', 'w') as f:
    json.dump(config, f, ensure_ascii=False)
```

## Waybar CSS notes

Default template uses `alpha({{bg}}, 0.88)` for semi-transparent backgrounds. Do NOT use `rgba({{bg_rgb}}, 0.88)` — it produces invalid CSS like `rgba(282828, 0.88)`. GTK CSS `alpha()` function works with hex colors.

## Hyprland version notes

Targets Hyprland 0.53+ with new windowrule `match:` syntax:
- `windowrule = float on, match:class ^(app)$`
- Boolean fields need values: `float on`, `pin on`, `no_blur on`
- `border_size` not `bordersize`, `border_color` not `bordercolor`
- `match:float true/false` not `floating:1`

## Testing changes

```bash
dripkit apply catppuccin-mocha     # apply theme
grim /tmp/screenshot.png            # take screenshot
```

Display: 2880x1800 at 1.5x scale = effective 1920x1200.
