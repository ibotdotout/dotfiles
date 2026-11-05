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
  -c, --color <hex>         Set hex color for single-color modes (e.g. FF00AA, 00FF00)
                            (default for breathing: random)
  -b, --brightness <0-100>  Set LED brightness percentage (default: ${DEFAULT_BRIGHTNESS})
  -s, --speed <slow|med|fast|1-5>
                            Set effect speed (default: ${DEFAULT_SPEED})
  -d, --device <id/name>    Target a specific OpenRGB device index or name (default: 0)
  -l, --list                List detected RGB devices and supported modes in detail
  -h, --help                Show this help message

Examples:
  $(basename "$0")                          # Rainbow spectrum cycle
  $(basename "$0") --speed fast             # Faster rainbow cycle
  $(basename "$0") -m breathing -c FF00FF   # Magenta breathing
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

# Apply settings via OpenRGB
if openrgb "${OPENRGB_ARGS[@]}" 2>&1; then
    echo "Successfully updated fan RGB lighting."
else
    EXIT_CODE=$?
    echo "" >&2
    echo "Notice: OpenRGB returned exit code $EXIT_CODE." >&2
    echo "If devices were not detected or permission was denied, verify that:" >&2
    echo " 1. OpenRGB udev rules are loaded (/usr/lib/udev/rules.d/60-openrgb.rules)." >&2
    echo " 2. Inspect connected devices using: $(basename "$0") --list" >&2
    exit $EXIT_CODE
fi
