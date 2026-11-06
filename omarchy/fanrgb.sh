#!/usr/bin/env bash
# fanrgb.sh - Set fan RGB lighting to Rainbow Color Cycle using OpenRGB
# Hardware target: Gigabyte RGB Fusion 2.0 (ITE IT8297) & compatible fan headers

set -euo pipefail

DEFAULT_BRIGHTNESS=100
DEFAULT_SPEED="medium"
DEFAULT_MODE="breathing"

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Set fan RGB lighting to a breathing rainbow cycle or custom mode.

Options:
  -m, --mode <mode>         Set effect mode:
                              breathing   (Breathing rainbow pulse, default)
                              color-cycle (Continuous rainbow spectrum cycle)
                              flashing    (Single-color flash; requires -c)
                              random      (Random color blinking)
                              static      (Solid color; requires -c)
                              off         (Turn off fan RGB lighting)
      --off                 Turn off fan RGB lighting (shortcut for '--mode off')
  -c, --color <hex>         Set hex color for single-color modes (e.g. FF00AA, 00FF00)
  -b, --brightness <0-100>  Set LED brightness percentage (default: ${DEFAULT_BRIGHTNESS})
  -s, --speed <slow|med|fast|1-5>
                            Set effect speed (default: ${DEFAULT_SPEED})
  -d, --device <id/name>    Target a specific OpenRGB device index or name (default: all detected)
      --install-shutdown    Install and enable user systemd service to automatically
                            turn off fan RGB when system shuts down or reboots
      --uninstall-shutdown  Disable and remove the shutdown service hook
  -l, --list                List detected RGB devices and supported modes in detail
  -h, --help                Show this help message

Examples:
  $(basename "$0")                          # Breathing rainbow cycle (default)
  $(basename "$0") -m color-cycle           # Continuous rainbow spectrum cycle
  $(basename "$0") -m breathing -c FF00FF   # Magenta breathing
  $(basename "$0") --off                    # Turn off fan RGB
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

    # Ensure ARGB header zones (D_LED1, D_LED2) are allocated with 60 LEDs
    local config_file="${XDG_CONFIG_HOME:-$HOME/.config}/OpenRGB/Configuration.json"
    if [[ ! -f "$config_file" ]] || ! grep -q '"name": "D_LED1, LED 60"' "$config_file" 2>/dev/null; then
        openrgb -d 0 -z 0 -sz 60 -z 1 -sz 60 >/dev/null 2>&1 || true
    fi
}

get_script_path() {
    local source="${BASH_SOURCE[0]}"
    while [ -h "$source" ]; do
        local dir="$(cd -P "$(dirname "$source")" && pwd)"
        source="$(readlink "$source")"
        [[ $source != /* ]] && source="$dir/$source"
    done
    cd -P "$(dirname "$source")" && pwd
}

ensure_shutdown_service() {
    # Skip service checks when turning off (e.g. during shutdown)
    if [[ "${MODE,,}" == "off" || "${MODE,,}" == "none" ]]; then
        return 0
    fi

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
ExecStop=/usr/bin/openrgb -d 0 -m static -c 000000 -b 0

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
ExecStop=/usr/bin/openrgb -d 0 -m static -c 000000 -b 0

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

get_detected_devices() {
    local devs=()
    while IFS= read -r line; do
        if [[ "$line" =~ ^([0-9]+): ]]; then
            devs+=("${BASH_REMATCH[1]}")
        fi
    done < <(openrgb --list-devices 2>/dev/null || true)

    if [[ ${#devs[@]} -eq 0 ]]; then
        devs=(0)
    fi
    echo "${devs[@]}"
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

# Build target device list (OpenRGB CLI requires -d <id> before mode/color flags)
TARGET_DEVICES=()
if [[ -n "$TARGET_DEVICE" ]]; then
    TARGET_DEVICES=("$TARGET_DEVICE")
else
    read -r -a TARGET_DEVICES <<< "$(get_detected_devices)"
fi

# Build OpenRGB command arguments
DEVICE_ARGS=()

# Determine mode flag and color handling
case "${MODE,,}" in
    off|none)
        DEVICE_ARGS+=(--mode "Static" --color "000000" --brightness 0)
        ;;
    color-cycle|colorcycle|cycle|rainbow)
        DEVICE_ARGS+=(--mode "Color Cycle")
        ;;
    breathing|breath|pulse|pulsing)
        DEVICE_ARGS+=(--mode "Breathing")
        if [[ -z "$COLOR" ]]; then
            # Breathing requires 1 color in OpenRGB; use random for dynamic rainbow breathing
            COLOR="random"
        fi
        ;;
    flashing|flash)
        DEVICE_ARGS+=(--mode "Flashing")
        ;;
    random)
        DEVICE_ARGS+=(--mode "Random")
        ;;
    static)
        DEVICE_ARGS+=(--mode "Static")
        ;;
    *)
        DEVICE_ARGS+=(--mode "$MODE")
        ;;
esac

if [[ "${MODE,,}" != "off" && "${MODE,,}" != "none" ]]; then
    # Append color if specified/required
    if [[ -n "$COLOR" ]]; then
        # Strip any leading '#' if user supplied hex color like #FF00FF
        COLOR="${COLOR#"#"}"
        DEVICE_ARGS+=(--color "$COLOR")
    fi

    if [[ -n "$BRIGHTNESS" ]]; then
        DEVICE_ARGS+=(--brightness "$BRIGHTNESS")
    fi

    if [[ -n "$SPEED_VAL" ]]; then
        DEVICE_ARGS+=(--speed "$SPEED_VAL")
    fi
fi

# Build complete CLI arguments pairing each target device with its settings
OPENRGB_CMD=()
for dev in "${TARGET_DEVICES[@]}"; do
    OPENRGB_CMD+=(-d "$dev" "${DEVICE_ARGS[@]}")
done

if [[ "${MODE,,}" == "off" || "${MODE,,}" == "none" ]]; then
    echo "Turning off fan RGB lighting..."
    echo "  Devices:    ${TARGET_DEVICES[*]}"
else
    echo "Setting fan RGB effect..."
    echo "  Mode:       $MODE"
    if [[ -n "$COLOR" ]]; then
        echo "  Color:      $COLOR"
    fi
    echo "  Brightness: ${BRIGHTNESS}%"
    echo "  Speed:      $SPEED ($SPEED_VAL)"
    echo "  Devices:    ${TARGET_DEVICES[*]}"
fi

# Apply settings via OpenRGB
if openrgb "${OPENRGB_CMD[@]}" 2>&1; then
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
