# dripkit

A theme framework for Hyprland. Switch your entire desktop — bar layout, colors, wallpaper, terminal, launcher, notifications, lock screen, shell prompt — with one command.

Each theme isn't just a palette swap. Themes ship unique waybar layouts, different animation styles, and distinct vibes.

## Features

- **17 modules** — themes every visible app on your desktop
- **Override system** — each theme can ship unique configs per app (custom waybar layouts, rofi styles, etc.)
- **Rofi picker** — `SUPER+T` opens a GUI theme selector with wallpaper thumbnails
- **Keybinds cheat sheet** — `SUPER+F1` shows all keybinds in a searchable overlay
- **CLI** — `dripkit apply tokyo-night` from the terminal
- **Atomic installer** — backs up configs, rolls back on failure, clean uninstall
- **AI-friendly** — clean structure that works great with Claude Code. Describe a vibe, get a rice.

## Included themes

| Theme | Vibe | Bar style |
|-------|------|-----------|
| **Catppuccin Mocha** | Soothing pastels | Three floating islands |
| **Tokyo Night** | Cyberpunk minimal | Thin HUD line at bottom |
| **Gruvbox Dark** | Warm retro cozy | Solid full-width, info-dense |
| **Nord** | Arctic clean | Bare floating text, no backgrounds |
| **Rose Pine** | Soft aesthetic | Single rounded capsule |

## What gets themed

| Module | What changes |
|--------|-------------|
| Hyprland | Borders, gaps, rounding, blur, shadows, animations, colors |
| Waybar | Full bar — layout, position, modules, CSS |
| Rofi | Launcher colors, layout, border radius |
| Alacritty | 16-color palette, font, opacity, padding |
| Starship | Prompt colors, segments, symbols |
| Fish | Syntax highlighting, autosuggestion, pager colors |
| Dunst | Notification colors, border, rounding, font |
| Hyprlock | Lock screen — background, clock, input field |
| Hyprpaper | Wallpaper |
| Wlogout | Power menu colors, hover states |
| Fastfetch | System info layout with themed icons |
| btop | System monitor color scheme |
| Cava | Audio visualizer gradient colors |
| bat | Syntax highlighting theme |
| fzf | Fuzzy finder colors |
| GTK | Theme, icons, cursor, font |
| Qt | Kvantum theme, icon theme |

## Installation

```bash
git clone https://github.com/YOUR_USERNAME/dripkit.git ~/Code/dripkit
cd ~/Code/dripkit
./install.sh
```

The installer will:
1. Check dependencies
2. Back up your existing configs
3. Wire dripkit into Hyprland, Alacritty, and Rofi
4. Add `dripkit` to your PATH
5. Apply your chosen theme

Flags:
- `./install.sh` — interactive (default)
- `./install.sh --auto` — no prompts
- `./install.sh --dry-run` — show what would change without doing it
- `./install.sh --uninstall` — restore backups and remove dripkit

## Dependencies

Required:
```bash
sudo pacman -S hyprland waybar rofi-wayland alacritty dunst hyprpaper imagemagick
```

Optional (for full theming):
```bash
sudo pacman -S hyprlock wlogout cava fastfetch btop bat fzf starship
```

## Usage

```bash
dripkit apply catppuccin-mocha    # apply a theme
dripkit list                       # list available themes
dripkit active                     # show current theme
dripkit picker                     # open rofi theme picker
```

Keybinds:
- `SUPER + T` — theme picker
- `SUPER + F1` — keybinds cheat sheet

## Creating a theme

A theme is a folder in `themes/` with two required files:

```
themes/my-theme/
├── theme.toml          # metadata
├── colors.conf         # color palette + settings
├── wallpapers/         # bundled wallpapers
└── overrides/          # optional per-module overrides
    └── waybar/
        ├── config.jsonc
        └── style.css
```

### colors.conf

Every variable here gets substituted into module templates via `{{variable_name}}`:

```conf
# Base colors
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

# Fonts
font = Fira Sans
mono_font = JetBrainsMono Nerd Font
```

Copy an existing theme's `colors.conf` as a starting point — it has all required variables.

### theme.toml

```toml
name = "My Theme"
description = "Short description"
author = "you"
variant = "dark"
wallpaper = "wallpapers/my-wallpaper.jpg"
```

Wallpaper paths are relative to the theme directory.

### Overrides

Drop full config files in `overrides/<module>/` to bypass templates. The file gets copied directly instead of rendered. This is how themes ship unique waybar layouts.

## Project structure

```
dripkit/
├── bin/
│   ├── dripkit              # main CLI
│   ├── dripkit-picker       # rofi GUI picker
│   ├── dripkit-keybinds     # keybinds cheat sheet
│   └── picker-theme.rasi    # picker styling
├── modules/                 # 17 app templates
│   ├── hyprland/     ├── waybar/
│   ├── rofi/         ├── alacritty/
│   ├── dunst/        ├── hyprlock/
│   ├── hyprpaper/    ├── wlogout/
│   ├── fastfetch/    ├── cava/
│   ├── starship/     ├── fish/
│   ├── btop/         ├── bat/
│   ├── fzf/          ├── gtk/
│   └── qt/
├── themes/
│   ├── catppuccin-mocha/
│   ├── tokyo-night/
│   ├── gruvbox-dark/
│   ├── nord/
│   └── rose-pine/
├── install.sh
└── CLAUDE.md
```

## Works great with AI

dripkit's structure is designed to be readable and modifiable by AI coding assistants:

```
> add a dracula theme to dripkit
> make the waybar show network speed
> change the accent color to pink and make gaps bigger
```

The clean file layout means Claude Code can read, understand, and modify themes without guessing.

## Contributing

PRs welcome — especially new themes and module templates.

## License

MIT
