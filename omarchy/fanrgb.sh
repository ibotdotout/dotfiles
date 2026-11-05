#!/usr/bin/env bash
# fanrgb.sh - Set fan RGB lighting to Breathing/Pulsing Rainbow using OpenRGB
# Hardware target: Gigabyte RGB Fusion 2.0 (ITE IT8297) & compatible fan headers

set -euo pipefail

DEFAULT_BRIGHTNESS=100
DEFAULT_SPEED="medium"
DEFAULT_MODE="breathing"

show_help() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Set fan RGB lighting to a breathing/pulsing rainbow color cycle.

Options:
  -b, --brightness <0-100>  Set LED brightness percentage (default: ${DEFAULT_BRIGHTNESS})
  -s, --speed <slow|med|fast|1-5>
                            Set effect speed (default: ${DEFAULT_SPEED})
  -m, --mode <mode>         Set specific mode: breathing, color-cycle, pulse
                            (default: ${DEFAULT_MODE})
  -d, --device <id/name>    Target a specific OpenRGB device index or name
  -l, --list                List detected RGB devices and available modes
  -h, --help                Show this help message

Examples:
  $(basename "$0")
  $(basename "$0") --brightness 80 --speed fast
  $(basename "$0") --mode color-cycle
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
TARGET_DEVICE=""
LIST_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -b|--brightness)
            BRIGHTNESS="$2"
            shift 2
            ;;
        -s|--speed)
            SPEED="$2"
            shift 2
            ;;
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -d|--device)
            TARGET_DEVICE="$2"
            shift 2
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

if [ "$LIST_ONLY" = true ]; then
    echo "=== Detected RGB Devices ==="
    openrgb --list-devices
    exit 0
fi

# Normalize speed
SPEED_VAL=$(map_speed_value "$SPEED")

# Build OpenRGB command arguments
OPENRGB_ARGS=()

# Determine mode flag
case "${MODE,,}" in
    breathing|breath)
        OPENRGB_ARGS+=(--mode breathing)
        ;;
    color-cycle|colorcycle|cycle)
        OPENRGB_ARGS+=(--mode "Color Cycle")
        ;;
    pulse|pulsing)
        OPENRGB_ARGS+=(--mode pulsating)
        ;;
    rainbow)
        OPENRGB_ARGS+=(--mode rainbow)
        ;;
    *)
        OPENRGB_ARGS+=(--mode "$MODE")
        ;;
esac

if [[ -n "$TARGET_DEVICE" ]]; then
    OPENRGB_ARGS+=(--device "$TARGET_DEVICE")
fi

if [[ -n "$BRIGHTNESS" ]]; then
    OPENRGB_ARGS+=(--brightness "$BRIGHTNESS")
fi

if [[ -n "$SPEED_VAL" ]]; then
    OPENRGB_ARGS+=(--speed "$SPEED_VAL")
fi

echo "Setting fan RGB effect..."
echo "  Mode:       $MODE"
echo "  Brightness: ${BRIGHTNESS}%"
echo "  Speed:      $SPEED ($SPEED_VAL)"
if [[ -n "$TARGET_DEVICE" ]]; then
    echo "  Device:     $TARGET_DEVICE"
else
    echo "  Device:     All detected devices"
fi

# Apply settings via OpenRGB
if openrgb "${OPENRGB_ARGS[@]}" 2>&1; then
    echo "Successfully updated fan RGB lighting."
else
    EXIT_CODE=$?
    echo "" >&2
    echo "Notice: OpenRGB returned exit code $EXIT_CODE." >&2
    echo "If devices were not detected or permission was denied, verify that:" >&2
    echo " 1. OpenRGB udev rules are loaded (/usr/lib/udev/rules.d/60-openrgb.rules)." >&2
    echo " 2. Your user is in the 'i2c' group (if SMBus is needed): sudo usermod -aG i2c $USER" >&2
    echo " 3. You can inspect connected devices using: $(basename "$0") --list" >&2
    exit $EXIT_CODE
fi
