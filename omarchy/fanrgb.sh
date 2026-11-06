#!/usr/bin/env bash
# fanrgb.sh - Set fan RGB lighting to Rainbow Color Cycle using OpenRGB
# Hardware target: Gigabyte RGB Fusion 2.0 (ITE IT8297) & compatible fan headers

set -euo pipefail

DEFAULT_BRIGHTNESS=100
DEFAULT_SPEED="medium"
DEFAULT_MODE="color-cycle"

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Set fan RGB lighting to a rainbow color cycle or custom mode.

Options:
  -m, --mode <mode>         Set effect mode:
                              color-cycle (Rainbow spectrum cycle, default)
                              breathing   (Single-color pulse; requires --color)
                              flashing    (Single-color flash)
                              random      (Random color blinking)
                              static      (Solid color)
                              off         (Turn off fan RGB lighting)
      --off                 Turn off fan RGB lighting (shortcut for '--mode off')
  -c, --color <hex>         Set hex color for single-color modes (e.g. FF00AA, 00FF00)
                            (default for breathing: random)
  -b, --brightness <0-100>  Set LED brightness percentage (default: ${DEFAULT_BRIGHTNESS})
  -s, --speed <slow|med|fast|1-5>
                            Set effect speed (default: ${DEFAULT_SPEED})
  -d, --device <id/name>    Target a specific OpenRGB device index or name (default: 0)
      --install-shutdown    Install and enable user systemd service to automatically
                            turn off fan RGB when system shuts down or reboots
      --uninstall-shutdown  Disable and remove the shutdown service hook
  -l, --list                List detected RGB devices and supported modes in detail
  -h, --help                Show this help message

Examples:
  $(basename "$0")                          # Rainbow spectrum cycle
  $(basename "$0") --off                    # Turn off fan RGB
  $(basename "$0") --speed fast             # Faster rainbow cycle
  $(basename "$0") -m breathing -c FF00FF   # Magenta breathing
  $(basename "$0") --install-shutdown       # Ensure shutdown service hook is active
  $(basename "$0") --list                   # Show detailed device info
EOF
}

ensure_dependencies() {
    if ! command -v openrgb >/dev/null 2>&1; then
        echo "--> 'openrgb' is not installed. Installing via pacman..."
        if command -v pacman >/dev/null 2>&1; then
            sudo pacman -S --needed --noconfirm openrgb
            echo "--> Reloading udev rules for RGB devices..."
            sudo udevadm control --reload-rules && sudo udevadm trigger
            echo "--> 'openrgb' successfully installed."
        else
            echo "Error: pacman package manager not found. Please install openrgb manually." >&2
            exit 1
        fi
    fi
}

ensure_shutdown_service() {
    local service_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
    local service_file="$service_dir/fanrgb-shutdown.service"

    mkdir -p "$service_dir"
    if [[ ! -f "$service_file" ]]; then
        cat << 'EOF' > "$service_file"
[Unit]
Description=Turn off fan RGB lighting on shutdown
Documentation=https://openrgb.org

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true
ExecStop=/usr/bin/openrgb -m static -c 000000 -b 0

[Install]
WantedBy=default.target
EOF
        systemctl --user daemon-reload >/dev/null 2>&1 || true
    fi

    if command -v systemctl >/dev/null 2>&1; then
        if ! systemctl --user is-enabled fanrgb-shutdown.service >/dev/null 2>&1; then
            systemctl --user daemon-reload >/dev/null 2>&1 || true
            systemctl --user enable --now fanrgb-shutdown.service >/dev/null 2>&1 || true
            echo "--> Enabled shutdown hook (fanrgb-shutdown.service) to turn off RGB when system shuts down."
        elif ! systemctl --user is-active fanrgb-shutdown.service >/dev/null 2>&1; then
            systemctl --user start fanrgb-shutdown.service >/dev/null 2>&1 || true
        fi
    fi
}

install_shutdown_service() {
    ensure_dependencies
    local service_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
    local service_file="$service_dir/fanrgb-shutdown.service"

    mkdir -p "$service_dir"
    cat << 'EOF' > "$service_file"
[Unit]
Description=Turn off fan RGB lighting on shutdown
Documentation=https://openrgb.org

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/true
ExecStop=/usr/bin/openrgb -m static -c 000000 -b 0

[Install]
WantedBy=default.target
EOF

    systemctl --user daemon-reload
    systemctl --user enable --now fanrgb-shutdown.service
    echo "--> Successfully installed and enabled shutdown service:"
    echo "    $service_file"
    echo "--> Fan RGB will now automatically turn off when the machine shuts down or reboots."
}

uninstall_shutdown_service() {
    local service_dir="${XDG_CONFIG_HOME:-$HOME/.config}/systemd/user"
    local service_file="$service_dir/fanrgb-shutdown.service"

    if systemctl --user is-enabled fanrgb-shutdown.service >/dev/null 2>&1; then
        systemctl --user disable --now fanrgb-shutdown.service >/dev/null 2>&1 || true
    fi
    rm -f "$service_file"
    systemctl --user daemon-reload >/dev/null 2>&1 || true
    echo "--> Shutdown hook service removed."
}

map_speed_value() {
    local speed_input="$1"
    case "$speed_input" in
        slow|1) echo 1 ;;
        medium|med|2) echo 2 ;;
        fast|3) echo 3 ;;
        fastest|4|5) echo 4 ;;
        *) echo "$speed_input" ;;
    esac
}

# Parse command line options
BRIGHTNESS="$DEFAULT_BRIGHTNESS"
SPEED="$DEFAULT_SPEED"
MODE="$DEFAULT_MODE"
COLOR=""
TARGET_DEVICE=""
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        --off)
            MODE="off"
            shift
            ;;
        -c|--color)
            COLOR="$2"
            shift 2
            ;;
        -b|--brightness)
            BRIGHTNESS="$2"
            shift 2
            ;;
        -s|--speed)
            SPEED="$2"
            shift 2
            ;;
        -d|--device)
            TARGET_DEVICE="$2"
            shift 2
            ;;
        --install-shutdown|--install-service)
            install_shutdown_service
            exit 0
            ;;
        --uninstall-shutdown|--uninstall-service)
            uninstall_shutdown_service
            exit 0
            ;;
        -l|--list)
            LIST_ONLY=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            show_help
            exit 1
            ;;
    esac
done

ensure_dependencies
ensure_shutdown_service

if [ "$LIST_ONLY" = true ]; then
    echo "=== Detailed RGB Device Information ==="
    openrgb --list-detailed
    exit 0
fi

# Normalize speed
SPEED_VAL=$(map_speed_value "$SPEED")

# Build OpenRGB command arguments
OPENRGB_ARGS=()

if [[ -n "$TARGET_DEVICE" ]]; then
    OPENRGB_ARGS+=(--device "$TARGET_DEVICE")
fi

# Determine mode flag and color handling
case "${MODE,,}" in
    off|none)
        OPENRGB_ARGS+=(--mode "Static" --color "000000" --brightness 0)
        ;;
    color-cycle|colorcycle|cycle|rainbow)
        OPENRGB_ARGS+=(--mode "Color Cycle")
        ;;
    breathing|breath|pulse|pulsing)
        OPENRGB_ARGS+=(--mode "Breathing")
        if [[ -z "$COLOR" ]]; then
            # Breathing requires 1 color; default to random if not specified
            COLOR="random"
        fi
        ;;
    flashing|flash)
        OPENRGB_ARGS+=(--mode "Flashing")
        if [[ -z "$COLOR" ]]; then
            COLOR="random"
        fi
        ;;
    random)
        OPENRGB_ARGS+=(--mode "Random")
        ;;
    static)
        OPENRGB_ARGS+=(--mode "Static")
        if [[ -z "$COLOR" ]]; then
            COLOR="FFFFFF"
        fi
        ;;
    *)
        OPENRGB_ARGS+=(--mode "$MODE")
        ;;
esac

if [[ "${MODE,,}" != "off" && "${MODE,,}" != "none" ]]; then
    # Append color if specified/required
    if [[ -n "$COLOR" ]]; then
        # Strip any leading '#' if user supplied hex color like #FF00FF
        COLOR="${COLOR#"#"}"
        OPENRGB_ARGS+=(--color "$COLOR")
    fi

    if [[ -n "$BRIGHTNESS" ]]; then
        OPENRGB_ARGS+=(--brightness "$BRIGHTNESS")
    fi

    if [[ -n "$SPEED_VAL" ]]; then
        OPENRGB_ARGS+=(--speed "$SPEED_VAL")
    fi
fi

if [[ "${MODE,,}" == "off" || "${MODE,,}" == "none" ]]; then
    echo "Turning off fan RGB lighting..."
    if [[ -n "$TARGET_DEVICE" ]]; then
        echo "  Device:     $TARGET_DEVICE"
    else
        echo "  Device:     All detected devices"
    fi
else
    echo "Setting fan RGB effect..."
    echo "  Mode:       $MODE"
    if [[ -n "$COLOR" ]]; then
        echo "  Color:      $COLOR"
    fi
    echo "  Brightness: ${BRIGHTNESS}%"
    echo "  Speed:      $SPEED ($SPEED_VAL)"
    if [[ -n "$TARGET_DEVICE" ]]; then
        echo "  Device:     $TARGET_DEVICE"
    else
        echo "  Device:     All detected devices"
    fi
fi

# Apply settings via OpenRGB
if openrgb "${OPENRGB_ARGS[@]}" 2>&1; then
    if [[ "${MODE,,}" == "off" || "${MODE,,}" == "none" ]]; then
        echo "Successfully turned off fan RGB lighting."
    else
        echo "Successfully updated fan RGB lighting."
    fi
else
    EXIT_CODE=$?
    echo "" >&2
    echo "Notice: OpenRGB returned exit code $EXIT_CODE." >&2
    echo "If devices were not detected or permission was denied, verify that:" >&2
    echo " 1. OpenRGB udev rules are loaded (/usr/lib/udev/rules.d/60-openrgb.rules)." >&2
    echo " 2. Inspect connected devices using: $(basename "$0") --list" >&2
    exit $EXIT_CODE
fi
