#!/usr/bin/env bash
set -euo pipefail

# ============================================================================
# dripkit installer
# Atomic install — preflight checks, backup, apply, verify. Rolls back on fail.
# ============================================================================

DRIPKIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$CONFIG_DIR/dripkit/backup"
LOCAL_BIN="$HOME/.local/bin"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"
BACKUP_PATH="$BACKUP_DIR/$TIMESTAMP"

# --- Flags ---
MODE="interactive"  # interactive | auto | uninstall | dry-run
DRY_RUN=false
UNINSTALL=false
for arg in "$@"; do
    case "$arg" in
        --auto)      MODE="auto" ;;
        --uninstall) UNINSTALL=true ;;
        --dry-run)   DRY_RUN=true ;;
        --help|-h)   MODE="help" ;;
    esac
done
if $UNINSTALL; then MODE="uninstall"; fi
if $DRY_RUN && [[ "$MODE" != "uninstall" ]]; then MODE="dry-run"; fi

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

info()  { echo -e "${CYAN}[dripkit]${NC} $*"; }
ok()    { echo -e "${GREEN}[dripkit]${NC} $*"; }
warn()  { echo -e "${YELLOW}[dripkit]${NC} $*"; }
err()   { echo -e "${RED}[dripkit]${NC} $*" >&2; }
dry()   { echo -e "${DIM}[dry-run]${NC} $*"; }

ask() {
    if [[ "$MODE" == "auto" ]]; then return 0; fi
    if [[ "$MODE" == "dry-run" ]]; then return 0; fi
    local prompt="$1"
    echo -en "${CYAN}[dripkit]${NC} $prompt ${DIM}[Y/n]${NC} "
    read -r response
    [[ -z "$response" || "$response" =~ ^[Yy] ]]
}

# --- Files we touch ---
MANAGED_FILES=(
    "$CONFIG_DIR/hypr/config/dripkit.conf"
    "$CONFIG_DIR/hypr/config/user-config.conf"
    "$CONFIG_DIR/hypr/hyprpaper.conf"
    "$CONFIG_DIR/hypr/hyprlock.conf"
    "$CONFIG_DIR/hypr/hypridle.conf"
    "$CONFIG_DIR/waybar/config"
    "$CONFIG_DIR/waybar/style.css"
    "$CONFIG_DIR/rofi/config.rasi"
    "$CONFIG_DIR/rofi/dripkit.rasi"
    "$CONFIG_DIR/alacritty/alacritty.toml"
    "$CONFIG_DIR/alacritty/dripkit.toml"
    "$CONFIG_DIR/dunst/dunstrc"
    "$CONFIG_DIR/gtk-3.0/settings.ini"
    "$CONFIG_DIR/gtk-4.0/settings.ini"
    "$CONFIG_DIR/qt5ct/qt5ct.conf"
    "$CONFIG_DIR/qt6ct/qt6ct.conf"
    "$CONFIG_DIR/Kvantum/kvantum.kvconfig"
)

# Files we modify (add lines to, not overwrite)
WIRED_FILES=(
    "$CONFIG_DIR/hypr/config/user-config.conf"
    "$CONFIG_DIR/alacritty/alacritty.toml"
)

# --- Dependencies ---
REQUIRED_DEPS=(hyprland waybar rofi alacritty dunst hyprpaper hyprlock hypridle cliphist wl-clipboard)
OPTIONAL_DEPS=(imagemagick wlogout brightnessctl)

# ============================================================================
# HELP
# ============================================================================

show_help() {
    echo -e "${BOLD}dripkit installer${NC}"
    echo ""
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  (none)        Interactive install (asks before each step)"
    echo "  --auto        Full automatic install, no prompts"
    echo "  --uninstall   Remove dripkit wiring and restore backups"
    echo "  --dry-run     Show what would happen without making changes"
    echo "  --help        Show this help"
    echo ""
    echo "The installer will:"
    echo "  1. Check dependencies"
    echo "  2. Backup existing configs"
    echo "  3. Wire dripkit into Hyprland, Alacritty, and Rofi configs"
    echo "  4. Add dripkit to PATH"
    echo "  5. Apply a default theme"
    echo "  6. Verify everything works"
}

# ============================================================================
# PREFLIGHT — read-only checks, reports all issues before touching anything
# ============================================================================

preflight() {
    info "Running preflight checks..."
    local errors=0

    # Check we're on a supported system
    if [[ ! -f /etc/os-release ]]; then
        err "Cannot detect OS (no /etc/os-release)"
        errors=$((errors + 1))
    fi

    # Detect package manager
    PKG_MGR=""
    if command -v pacman &>/dev/null; then
        PKG_MGR="pacman"
    elif command -v dnf &>/dev/null; then
        PKG_MGR="dnf"
    elif command -v apt &>/dev/null; then
        PKG_MGR="apt"
    elif command -v nix-env &>/dev/null; then
        PKG_MGR="nix"
    fi

    if [[ -z "$PKG_MGR" ]]; then
        warn "No supported package manager found (pacman/dnf/apt/nix)"
        warn "You'll need to install dependencies manually"
    else
        ok "Package manager: $PKG_MGR"
    fi

    # Check required dependencies
    MISSING_REQUIRED=()
    for dep in "${REQUIRED_DEPS[@]}"; do
        local cmd="$dep"
        [[ "$dep" == "hyprland" ]] && cmd="Hyprland"
        [[ "$dep" == "rofi" ]] && cmd="rofi"
        [[ "$dep" == "imagemagick" ]] && cmd="magick"
        [[ "$dep" == "wl-clipboard" ]] && cmd="wl-copy"
        if ! command -v "$cmd" &>/dev/null; then
            # Try package name directly
            if ! command -v "$dep" &>/dev/null; then
                MISSING_REQUIRED+=("$dep")
            fi
        fi
    done

    MISSING_OPTIONAL=()
    for dep in "${OPTIONAL_DEPS[@]}"; do
        local cmd="$dep"
        [[ "$dep" == "imagemagick" ]] && cmd="magick"
        if ! command -v "$cmd" &>/dev/null; then
            MISSING_OPTIONAL+=("$dep")
        fi
    done

    if [[ ${#MISSING_REQUIRED[@]} -gt 0 ]]; then
        err "Missing required dependencies: ${MISSING_REQUIRED[*]}"
        if [[ -n "$PKG_MGR" ]]; then
            case "$PKG_MGR" in
                pacman) err "  Install with: sudo pacman -S ${MISSING_REQUIRED[*]}" ;;
                dnf)    err "  Install with: sudo dnf install ${MISSING_REQUIRED[*]}" ;;
                apt)    err "  Install with: sudo apt install ${MISSING_REQUIRED[*]}" ;;
            esac
        fi
        errors=$((errors + 1))
    else
        ok "All required dependencies found"
    fi

    if [[ ${#MISSING_OPTIONAL[@]} -gt 0 ]]; then
        warn "Missing optional dependencies: ${MISSING_OPTIONAL[*]}"
        warn "  (theme picker thumbnails need imagemagick, brightness dimming needs brightnessctl)"
    fi

    # Check Hyprland is running
    if [[ -z "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        warn "Hyprland doesn't appear to be the active session"
        warn "  dripkit will still install but can't verify until you log into Hyprland"
    else
        ok "Hyprland session detected"
    fi

    # Check config directories exist
    for dir in hypr waybar rofi alacritty dunst; do
        if [[ ! -d "$CONFIG_DIR/$dir" ]]; then
            warn "Config directory missing: $CONFIG_DIR/$dir (will be created)"
        fi
    done

    # Check if already installed
    if [[ -L "$LOCAL_BIN/dripkit" ]] && [[ "$(readlink "$LOCAL_BIN/dripkit")" == "$DRIPKIT_DIR/bin/dripkit" ]]; then
        warn "dripkit is already installed (symlink exists at $LOCAL_BIN/dripkit)"
    fi

    # Check for existing dripkit wiring
    if [[ -f "$CONFIG_DIR/hypr/config/user-config.conf" ]]; then
        if grep -q "dripkit" "$CONFIG_DIR/hypr/config/user-config.conf" 2>/dev/null; then
            warn "Hyprland config already has dripkit wiring"
        fi
    fi

    if [[ -f "$CONFIG_DIR/alacritty/alacritty.toml" ]]; then
        if grep -q "dripkit" "$CONFIG_DIR/alacritty/alacritty.toml" 2>/dev/null; then
            warn "Alacritty config already has dripkit import"
        fi
    fi

    # Check write permissions
    if [[ ! -w "$CONFIG_DIR" ]]; then
        err "Cannot write to $CONFIG_DIR"
        errors=$((errors + 1))
    fi

    if [[ $errors -gt 0 ]]; then
        err "Preflight failed with $errors error(s). Fix the issues above and re-run."
        return 1
    fi

    ok "Preflight passed"
    return 0
}

# ============================================================================
# BACKUP — snapshot every config we're going to touch
# ============================================================================

do_backup() {
    info "Backing up existing configs to ${BOLD}$BACKUP_PATH${NC}"

    if [[ "$MODE" == "dry-run" ]]; then
        for f in "${MANAGED_FILES[@]}"; do
            [[ -f "$f" ]] && dry "Would backup: $f"
        done
        return 0
    fi

    mkdir -p "$BACKUP_PATH"

    local backed_up=0
    for f in "${MANAGED_FILES[@]}"; do
        if [[ -f "$f" ]]; then
            local rel="${f#$CONFIG_DIR/}"
            mkdir -p "$BACKUP_PATH/$(dirname "$rel")"
            cp "$f" "$BACKUP_PATH/$rel"
            backed_up=$((backed_up + 1))
        fi
    done

    # Save a manifest of what was backed up
    echo "$TIMESTAMP" > "$BACKUP_PATH/.manifest"
    echo "dripkit_dir=$DRIPKIT_DIR" >> "$BACKUP_PATH/.manifest"

    ok "Backed up $backed_up config file(s)"
}

# ============================================================================
# RESTORE — roll back from a backup
# ============================================================================

do_restore() {
    local restore_path="$1"

    if [[ ! -d "$restore_path" ]]; then
        err "Backup not found: $restore_path"
        return 1
    fi

    info "Restoring configs from $restore_path"

    # Restore each backed up file
    for f in $(find "$restore_path" -type f ! -name '.manifest'); do
        local rel="${f#$restore_path/}"
        local target="$CONFIG_DIR/$rel"
        mkdir -p "$(dirname "$target")"
        cp "$f" "$target"
    done

    # Remove dripkit-specific files that wouldn't have existed before
    rm -f "$CONFIG_DIR/hypr/config/dripkit.conf"
    rm -f "$CONFIG_DIR/hypr/hypridle.conf"
    rm -f "$CONFIG_DIR/alacritty/dripkit.toml"
    rm -f "$CONFIG_DIR/rofi/dripkit.rasi"

    # Remove dripkit wiring from user-config.conf
    if [[ -f "$CONFIG_DIR/hypr/config/user-config.conf" ]]; then
        sed -i '/# dripkit theme/d; /dripkit\.conf/d; /dripkit-picker/d; /Theme picker keybind/d; /dripkit-clipboard/d; /Clipboard history keybind/d' \
            "$CONFIG_DIR/hypr/config/user-config.conf"
    fi

    # Remove dripkit import from alacritty
    if [[ -f "$CONFIG_DIR/alacritty/alacritty.toml" ]]; then
        sed -i '/dripkit/d' "$CONFIG_DIR/alacritty/alacritty.toml"
    fi

    # Remove dripkit rofi config if it only contains dripkit stuff
    if [[ -f "$CONFIG_DIR/rofi/config.rasi" ]]; then
        if grep -q '@theme "dripkit"' "$CONFIG_DIR/rofi/config.rasi" 2>/dev/null; then
            rm -f "$CONFIG_DIR/rofi/config.rasi"
        fi
    fi

    ok "Configs restored"
}

# ============================================================================
# APPLY — wire dripkit into configs (atomic: prep in temp, move into place)
# ============================================================================

do_apply() {
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    trap "rm -rf '$tmp_dir'" EXIT

    info "Preparing config changes..."

    # --- 1. Create dripkit placeholder configs ---
    mkdir -p "$tmp_dir/hypr/config"
    echo "# dripkit theme — run 'dripkit apply <theme>' to populate" > "$tmp_dir/hypr/config/dripkit.conf"

    mkdir -p "$tmp_dir/alacritty"
    echo "# dripkit theme — run 'dripkit apply <theme>' to populate" > "$tmp_dir/alacritty/dripkit.toml"

    # --- 2. Wire into Hyprland user-config ---
    mkdir -p "$tmp_dir/hypr/config"
    if [[ -f "$CONFIG_DIR/hypr/config/user-config.conf" ]]; then
        cp "$CONFIG_DIR/hypr/config/user-config.conf" "$tmp_dir/hypr/config/user-config.conf"
    else
        echo "# User overrides" > "$tmp_dir/hypr/config/user-config.conf"
    fi

    # Only add if not already present
    if ! grep -q "dripkit\.conf" "$tmp_dir/hypr/config/user-config.conf" 2>/dev/null; then
        cat >> "$tmp_dir/hypr/config/user-config.conf" << 'HYPR'

# dripkit theme (applied by dripkit, overrides defaults)
source = ~/.config/hypr/config/dripkit.conf

# Theme picker keybind
bindd = $mainMod, T, Launch dripkit theme picker, exec, DRIPKIT_PICKER_PATH

# Clipboard history (unbind default togglefloating)
unbind = $mainMod, V
bindd = $mainMod, V, Open clipboard history, exec, DRIPKIT_CLIPBOARD_PATH
HYPR
        # Replace placeholders with actual paths
        sed -i "s|DRIPKIT_PICKER_PATH|$DRIPKIT_DIR/bin/dripkit-picker|" "$tmp_dir/hypr/config/user-config.conf"
        sed -i "s|DRIPKIT_CLIPBOARD_PATH|$DRIPKIT_DIR/bin/dripkit-clipboard|" "$tmp_dir/hypr/config/user-config.conf"
    fi

    # --- 3. Wire into Alacritty ---
    if [[ -f "$CONFIG_DIR/alacritty/alacritty.toml" ]]; then
        cp "$CONFIG_DIR/alacritty/alacritty.toml" "$tmp_dir/alacritty/alacritty.toml"
    else
        echo "" > "$tmp_dir/alacritty/alacritty.toml"
    fi

    if ! grep -q "dripkit" "$tmp_dir/alacritty/alacritty.toml" 2>/dev/null; then
        # Check if [general] section exists
        if grep -q '^\[general\]' "$tmp_dir/alacritty/alacritty.toml" 2>/dev/null; then
            # Add import under existing [general]
            sed -i '/^\[general\]/a import = ["~/.config/alacritty/dripkit.toml"]' "$tmp_dir/alacritty/alacritty.toml"
        else
            # Prepend [general] with import
            local existing
            existing="$(cat "$tmp_dir/alacritty/alacritty.toml")"
            cat > "$tmp_dir/alacritty/alacritty.toml" << ALAC
[general]
import = ["~/.config/alacritty/dripkit.toml"]

$existing
ALAC
        fi
    fi

    # --- 4. Create rofi config ---
    mkdir -p "$tmp_dir/rofi"
    if [[ ! -f "$CONFIG_DIR/rofi/config.rasi" ]] || ! grep -q "dripkit" "$CONFIG_DIR/rofi/config.rasi" 2>/dev/null; then
        cat > "$tmp_dir/rofi/config.rasi" << 'ROFI'
configuration {
    show-icons: true;
    icon-theme: "Papirus-Dark";
    display-drun: "Apps";
    drun-display-format: "{name}";
}

@theme "dripkit"
ROFI
    fi

    # --- 5. Validate temp files ---
    local prep_errors=0
    for f in "$tmp_dir"/hypr/config/dripkit.conf "$tmp_dir"/hypr/config/user-config.conf "$tmp_dir"/alacritty/dripkit.toml; do
        if [[ ! -f "$f" ]]; then
            err "Failed to prepare: $f"
            prep_errors=$((prep_errors + 1))
        fi
    done

    if [[ $prep_errors -gt 0 ]]; then
        err "Preparation failed. No changes made."
        return 1
    fi

    # --- 6. Move into place ---
    if [[ "$MODE" == "dry-run" ]]; then
        dry "Would write: $CONFIG_DIR/hypr/config/dripkit.conf"
        dry "Would write: $CONFIG_DIR/hypr/config/user-config.conf"
        dry "Would write: $CONFIG_DIR/alacritty/dripkit.toml"
        dry "Would write: $CONFIG_DIR/alacritty/alacritty.toml"
        dry "Would write: $CONFIG_DIR/rofi/config.rasi"
        return 0
    fi

    mkdir -p "$CONFIG_DIR/hypr/config" "$CONFIG_DIR/alacritty" "$CONFIG_DIR/rofi"

    cp "$tmp_dir/hypr/config/dripkit.conf" "$CONFIG_DIR/hypr/config/dripkit.conf"
    cp "$tmp_dir/hypr/config/user-config.conf" "$CONFIG_DIR/hypr/config/user-config.conf"
    cp "$tmp_dir/alacritty/dripkit.toml" "$CONFIG_DIR/alacritty/dripkit.toml"
    cp "$tmp_dir/alacritty/alacritty.toml" "$CONFIG_DIR/alacritty/alacritty.toml"
    [[ -f "$tmp_dir/rofi/config.rasi" ]] && cp "$tmp_dir/rofi/config.rasi" "$CONFIG_DIR/rofi/config.rasi"

    ok "Config wiring complete"

    # --- 7. Symlink to PATH ---
    mkdir -p "$LOCAL_BIN"
    if [[ ! -L "$LOCAL_BIN/dripkit" ]] || [[ "$(readlink "$LOCAL_BIN/dripkit" 2>/dev/null)" != "$DRIPKIT_DIR/bin/dripkit" ]]; then
        ln -sf "$DRIPKIT_DIR/bin/dripkit" "$LOCAL_BIN/dripkit"
        ok "Symlinked dripkit to $LOCAL_BIN/dripkit"
    else
        ok "Symlink already exists"
    fi

    # Check PATH
    if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
        warn "$LOCAL_BIN is not in your PATH"
        warn "Add to your shell config: export PATH=\"\$HOME/.local/bin:\$PATH\""
    fi
}

# ============================================================================
# VERIFY — check that everything works
# ============================================================================

do_verify() {
    info "Verifying installation..."
    local errors=0

    # Check symlink
    if [[ -x "$LOCAL_BIN/dripkit" ]]; then
        ok "dripkit CLI: OK"
    else
        err "dripkit CLI: missing or not executable"
        errors=$((errors + 1))
    fi

    # Check dripkit.conf exists
    if [[ -f "$CONFIG_DIR/hypr/config/dripkit.conf" ]]; then
        ok "Hyprland dripkit.conf: OK"
    else
        err "Hyprland dripkit.conf: missing"
        errors=$((errors + 1))
    fi

    # Check alacritty import
    if grep -q "dripkit" "$CONFIG_DIR/alacritty/alacritty.toml" 2>/dev/null; then
        ok "Alacritty import: OK"
    else
        err "Alacritty import: missing"
        errors=$((errors + 1))
    fi

    # Check rofi theme
    if [[ -f "$CONFIG_DIR/rofi/config.rasi" ]]; then
        ok "Rofi config: OK"
    else
        err "Rofi config: missing"
        errors=$((errors + 1))
    fi

    # Check Hyprland wiring
    if grep -q "dripkit" "$CONFIG_DIR/hypr/config/user-config.conf" 2>/dev/null; then
        ok "Hyprland wiring: OK"
    else
        err "Hyprland wiring: missing"
        errors=$((errors + 1))
    fi

    # Try hyprctl reload if Hyprland is running
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        if hyprctl reload &>/dev/null; then
            ok "Hyprland config reload: OK"
        else
            err "Hyprland config reload: FAILED"
            errors=$((errors + 1))
        fi
    fi

    # List available themes
    local theme_count
    theme_count=$(find "$DRIPKIT_DIR/themes" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l)
    ok "Available themes: $theme_count"

    if [[ $errors -gt 0 ]]; then
        err "Verification failed with $errors error(s)"
        return 1
    fi

    ok "All checks passed"
    return 0
}

# ============================================================================
# UNINSTALL
# ============================================================================

do_uninstall() {
    info "Uninstalling dripkit..."

    # Find most recent backup
    local latest_backup=""
    if [[ -d "$BACKUP_DIR" ]]; then
        latest_backup="$(find "$BACKUP_DIR" -mindepth 1 -maxdepth 1 -type d | sort -r | head -1)"
    fi

    if $DRY_RUN; then
        dry "Would remove symlink: $LOCAL_BIN/dripkit"
        dry "Would remove: $CONFIG_DIR/hypr/config/dripkit.conf"
        dry "Would remove: $CONFIG_DIR/hypr/hypridle.conf"
        dry "Would remove: $CONFIG_DIR/alacritty/dripkit.toml"
        dry "Would remove: $CONFIG_DIR/rofi/dripkit.rasi"
        dry "Would remove dripkit lines from user-config.conf and alacritty.toml"
        if [[ -n "$latest_backup" ]]; then
            dry "Would restore from backup: $latest_backup"
        fi
        return 0
    fi

    # Restore from backup if available
    if [[ -n "$latest_backup" ]]; then
        if ask "Restore configs from backup ($latest_backup)?"; then
            do_restore "$latest_backup"
        fi
    else
        warn "No backup found — removing dripkit files only"
        # Manual cleanup
        rm -f "$CONFIG_DIR/hypr/config/dripkit.conf"
        rm -f "$CONFIG_DIR/alacritty/dripkit.toml"
        rm -f "$CONFIG_DIR/rofi/dripkit.rasi"

        # Remove dripkit lines
        if [[ -f "$CONFIG_DIR/hypr/config/user-config.conf" ]]; then
            sed -i '/# dripkit theme/d; /dripkit\.conf/d; /dripkit-picker/d; /Theme picker keybind/d' \
                "$CONFIG_DIR/hypr/config/user-config.conf"
        fi
        if [[ -f "$CONFIG_DIR/alacritty/alacritty.toml" ]]; then
            sed -i '/dripkit/d' "$CONFIG_DIR/alacritty/alacritty.toml"
        fi
        if [[ -f "$CONFIG_DIR/rofi/config.rasi" ]]; then
            if grep -q '@theme "dripkit"' "$CONFIG_DIR/rofi/config.rasi" 2>/dev/null; then
                rm -f "$CONFIG_DIR/rofi/config.rasi"
            fi
        fi
    fi

    # Remove symlink
    rm -f "$LOCAL_BIN/dripkit"

    # Remove cache
    rm -rf "${XDG_CACHE_HOME:-$HOME/.cache}/dripkit"

    # Remove state
    rm -f "$CONFIG_DIR/dripkit/active-theme"

    ok "dripkit uninstalled"
    info "The dripkit repo at $DRIPKIT_DIR was not removed. Delete it manually if you want."

    # Reload Hyprland if running
    if [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]]; then
        hyprctl reload &>/dev/null || true
    fi
}

# ============================================================================
# MAIN
# ============================================================================

main() {
    echo ""
    echo -e "${BOLD}  dripkit installer${NC}"
    echo -e "  ${DIM}Hyprland theme framework${NC}"
    echo ""

    case "$MODE" in
        help)
            show_help
            exit 0
            ;;
        dry-run)
            info "Dry run mode — no changes will be made"
            echo ""
            preflight || exit 1
            echo ""
            do_backup
            echo ""
            do_apply
            echo ""
            info "Dry run complete. Run without --dry-run to apply."
            exit 0
            ;;
        uninstall)
            do_uninstall
            exit 0
            ;;
    esac

    # --- Preflight ---
    preflight || exit 1
    echo ""

    # --- Confirm ---
    if [[ "$MODE" == "interactive" ]]; then
        echo -e "${BOLD}The installer will:${NC}"
        echo "  1. Backup your existing configs"
        echo "  2. Wire dripkit into Hyprland, Alacritty, and Rofi"
        echo "  3. Add 'dripkit' command to $LOCAL_BIN"
        echo "  4. Apply a default theme"
        echo ""
        if ! ask "Continue?"; then
            info "Cancelled."
            exit 0
        fi
        echo ""
    fi

    # --- Backup ---
    do_backup
    echo ""

    # --- Apply ---
    do_apply
    if [[ $? -ne 0 ]]; then
        err "Installation failed during apply phase"
        if [[ -d "$BACKUP_PATH" ]]; then
            warn "Rolling back from backup..."
            do_restore "$BACKUP_PATH"
            err "Rolled back. Your original configs are restored."
        fi
        exit 1
    fi
    echo ""

    # --- Apply default theme ---
    local themes=()
    for d in "$DRIPKIT_DIR/themes"/*/; do
        [[ -f "$d/theme.toml" ]] && themes+=("$(basename "$d")")
    done

    if [[ ${#themes[@]} -gt 0 ]]; then
        local default_theme="${themes[0]}"

        if [[ "$MODE" == "interactive" ]]; then
            echo -e "${BOLD}Available themes:${NC}"
            for i in "${!themes[@]}"; do
                echo "  $((i+1)). ${themes[$i]}"
            done
            echo ""
            echo -en "${CYAN}[dripkit]${NC} Apply which theme? ${DIM}[1]${NC} "
            read -r choice
            choice="${choice:-1}"
            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le ${#themes[@]} ]]; then
                default_theme="${themes[$((choice-1))]}"
            fi
        fi

        info "Applying theme: ${BOLD}$default_theme${NC}"
        if ! "$DRIPKIT_DIR/bin/dripkit" apply "$default_theme" 2>&1; then
            err "Theme apply failed"
            if [[ -d "$BACKUP_PATH" ]]; then
                warn "Rolling back from backup..."
                do_restore "$BACKUP_PATH"
                err "Rolled back. Your original configs are restored."
            fi
            exit 1
        fi
        echo ""
    fi

    # --- Verify ---
    if ! do_verify; then
        err "Verification failed"
        if ask "Roll back to previous configs?"; then
            do_restore "$BACKUP_PATH"
            err "Rolled back. Your original configs are restored."
            exit 1
        fi
    fi
    echo ""

    # --- Done ---
    ok "Installation complete!"
    echo ""
    echo -e "  ${BOLD}Quick start:${NC}"
    echo "    dripkit list          — see available themes"
    echo "    dripkit apply <name>  — apply a theme"
    echo "    SUPER + T             — open theme picker"
    echo "    SUPER + V             — open clipboard history"
    echo ""
    echo -e "  ${BOLD}Undo:${NC}"
    echo "    ./install.sh --uninstall"
    echo ""
    echo -e "  ${DIM}Backup saved to: $BACKUP_PATH${NC}"
    echo ""
}

main
