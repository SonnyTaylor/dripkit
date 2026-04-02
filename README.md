# dripkit

A theme framework for Hyprland. Define a color palette and a wallpaper, and dripkit applies it across your entire desktop — Hyprland, waybar, rofi, alacritty, dunst, hyprlock, hyprpaper, GTK, and Qt.

Themes are simple config files. The framework does the wiring.

## Features

- **Template-based** — themes define colors, the framework renders configs for every app
- **Module system** — each app (waybar, rofi, alacritty, etc.) is a separate module. Enable or disable what you want.
- **Override system** — themes can ship custom configs for any module (e.g. a unique waybar layout per theme)
- **Rofi picker** — `SUPER+T` opens a GUI theme selector with wallpaper previews
- **CLI** — `dripkit apply tokyo-night` from the terminal
- **AI-friendly** — clean, well-structured files that are trivially easy to modify with Claude Code or any AI assistant. Describe a vibe, get a rice.

## What each theme controls

| Module | What changes |
|--------|-------------|
| Hyprland | Borders, gaps, rounding, blur, shadows, animations, colors |
| Waybar | Full bar styling — layout, colors, modules, CSS |
| Rofi | Launcher theme — colors, layout, border radius |
| Alacritty | 16-color palette, font, opacity, padding |
| Dunst | Notification colors, border, rounding, font |
| Hyprlock | Lock screen — background, clock, input field styling |
| Hyprpaper | Wallpaper |
| GTK | Theme, icons, cursor, font |
| Qt | Kvantum theme, icon theme |

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/dripkit.git ~/Code/dripkit
cd ~/Code/dripkit
./install.sh
```

## Dependencies

- Hyprland
- waybar
- rofi-wayland
- alacritty
- dunst
- hyprpaper
- hyprlock (optional)
- imagemagick (for wallpaper thumbnails in the picker)

On Arch/CachyOS:
```bash
sudo pacman -S hyprland waybar rofi-wayland alacritty dunst hyprpaper hyprlock imagemagick
```

## Usage

```bash
# Apply a theme
dripkit apply catppuccin-mocha

# List available themes
dripkit list

# Show current theme
dripkit active

# Open the rofi theme picker
dripkit picker
# or press SUPER+T
```

## Creating a theme

A theme is a folder in `themes/` with at minimum two files:

```
themes/my-theme/
├── theme.toml      # name, description, wallpaper path
├── colors.conf     # color palette + settings
├── wallpapers/     # optional wallpaper files
└── overrides/      # optional full config overrides per module
    └── waybar/
        ├── config.jsonc
        └── style.css
```

### colors.conf

Define your palette and settings. These variables get substituted into every module template:

```conf
# Colors (used in waybar CSS, rofi, alacritty, dunst)
bg = #1e1e2e
fg = #cdd6f4
accent = #89b4fa
red = #f38ba8
green = #a6e3a1
# ... full palette

# RGB variants without # (for Hyprland rgba())
accent_rgb = 89b4fa
bg_rgb = 1e1e2e

# Hyprland settings
gaps_in = 5
gaps_out = 12
rounding = 10
blur_size = 12

# Fonts
font = Fira Sans
mono_font = JetBrainsMono Nerd Font
```

### theme.toml

```toml
name = "My Theme"
description = "A cool theme"
author = "you"
variant = "dark"
wallpaper = "/path/to/wallpaper.jpg"
```

### Overrides

If the template output isn't enough for a module, drop full config files in `overrides/<module>/`. These are copied directly instead of rendering the template. Great for custom waybar layouts.

## Included themes

- **Catppuccin Mocha** — Soothing pastel theme with island-style waybar

## Project structure

```
dripkit/
├── bin/
│   ├── dripkit              # main CLI
│   ├── dripkit-picker       # rofi GUI picker
│   └── picker-theme.rasi    # picker styling
├── modules/                 # app templates
│   ├── hyprland/template.conf
│   ├── waybar/template.{config.jsonc,style.css}
│   ├── rofi/template.rasi
│   ├── alacritty/template.toml
│   ├── dunst/template.conf
│   ├── hyprlock/template.conf
│   ├── hyprpaper/template.conf
│   ├── gtk/apply.sh
│   └── qt/apply.sh
└── themes/
    └── catppuccin-mocha/
        ├── theme.toml
        ├── colors.conf
        └── overrides/waybar/
```

## Works great with AI

dripkit is designed to be easily modified by AI coding assistants. With Claude Code:

```
> add a tokyo night theme to dripkit
> make the waybar more minimal
> change the accent color to pink
```

The clean file structure means the AI can read, understand, and modify themes without guessing.

## Contributing

PRs welcome — especially new themes. See the theme creation guide above.

## License

MIT
