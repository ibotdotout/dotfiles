#!/usr/bin/env bash
#
# enable-user-lingering.sh
#
# Enables user lingering and sets up services so Tailscale, SSH, and Herdr
# start automatically on boot without requiring a user login.
#
# NOTE ON BIOS CONFIGURATION:
# For complete unattended operation (e.g. after a power outage or remote power cycle),
# remember to enable "AC Power Recovery" / "Restore on AC/Power Loss" in your BIOS/UEFI
# settings (set to "Power On" or "Last State"). This ensures the machine turns on
# automatically so Tailscale and Herdr can start without pressing the physical power button.
#

set -euo pipefail

TARGET_USER="${SUDO_USER:-$USER}"
TARGET_HOME=$(getent passwd "$TARGET_USER" | cut -d: -f6)
TARGET_UID=$(id -u "$TARGET_USER")
SERVICE_DIR="$TARGET_HOME/.config/systemd/user"
SERVICE_FILE="$SERVICE_DIR/herdr.service"

run_as_root() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
    else
        sudo "$@"
    fi
}

run_as_user() {
    if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
        sudo -u "$TARGET_USER" XDG_RUNTIME_DIR="/run/user/$TARGET_UID" "$@"
    else
        "$@"
    fi
}

echo "======================================================================"
echo " Setting up Tailscale, SSH, and Herdr for unattended boot"
echo " Target user: $TARGET_USER"
echo "======================================================================"

# 1. Enable user lingering via loginctl
CURRENT_LINGER=$(loginctl show-user "$TARGET_USER" --property=Linger --value 2>/dev/null || echo "no")
if [ "$CURRENT_LINGER" = "yes" ]; then
    echo "==> User lingering is already enabled for $TARGET_USER."
else
    echo "==> Enabling systemd user lingering for $TARGET_USER..."
    loginctl enable-linger "$TARGET_USER" 2>/dev/null || run_as_root loginctl enable-linger "$TARGET_USER"
fi

# 2. Enable and start Tailscale system service
if systemctl is-enabled tailscaled.service >/dev/null 2>&1 && systemctl is-active tailscaled.service >/dev/null 2>&1; then
    echo "==> tailscaled.service is already enabled and running."
else
    echo "==> Enabling and starting tailscaled system service..."
    run_as_root systemctl enable --now tailscaled.service
fi

# 3. Enable and start OpenSSH daemon (sshd.service)
if systemctl is-enabled sshd.service >/dev/null 2>&1 && systemctl is-active sshd.service >/dev/null 2>&1; then
    echo "==> sshd.service is already enabled and running."
else
    echo "==> Enabling and starting sshd.service..."
    run_as_root systemctl enable --now sshd.service
fi

# 4. Enable Tailscale SSH
if command -v tailscale >/dev/null 2>&1; then
    echo "==> Ensuring Tailscale SSH is enabled in Tailscale..."
    tailscale set --ssh >/dev/null 2>&1 || run_as_root tailscale set --ssh >/dev/null 2>&1 || true
fi

# 5. Create systemd user service directory
mkdir -p "$SERVICE_DIR"

# 6. Stop any existing unmanaged herdr server instances to let systemd supervise
if pgrep -x herdr >/dev/null 2>&1 && ! run_as_user systemctl --user is-active herdr.service >/dev/null 2>&1; then
    echo "==> Stopping existing unmanaged herdr server..."
    run_as_user herdr server stop 2>/dev/null || true
    sleep 1
    if pgrep -x herdr >/dev/null 2>&1; then
        pkill -x herdr 2>/dev/null || true
        sleep 1
    fi
fi

# 7. Create herdr.service unit file
echo "==> Writing $SERVICE_FILE..."
cat << 'EOF' > "$SERVICE_FILE"
[Unit]
Description=Herdr - Terminal Workspace Manager Server
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
ExecStart=/usr/bin/herdr server
Restart=on-failure
RestartSec=3
Environment="PATH=%h/.local/bin:%h/.local/share/mise/shims:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/bin"
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=default.target
EOF

# Ensure proper ownership if run with sudo
if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    chown -R "$TARGET_USER:$TARGET_USER" "$SERVICE_DIR"
fi

# 8. Reload user systemd daemon, enable and start herdr.service
echo "==> Reloading user systemd daemon and enabling herdr.service..."
run_as_user systemctl --user daemon-reload
run_as_user systemctl --user enable --now herdr.service

# 9. Verification and status display
echo ""
echo "======================================================================"
echo " ==> Verification Status:"
echo " - Lingering status    : $(loginctl show-user "$TARGET_USER" --property=Linger --value 2>/dev/null || echo 'unknown')"
echo " - tailscaled status   : $(systemctl is-active tailscaled.service 2>/dev/null || echo 'inactive')"
echo " - sshd status         : $(systemctl is-active sshd.service 2>/dev/null || echo 'inactive')"
echo " - Tailscale SSH       : $(tailscale debug prefs 2>/dev/null | jq -r 'if .RunSSH then "enabled" else "disabled" end' 2>/dev/null || echo 'unknown')"
echo " - herdr.service status: $(run_as_user systemctl --user is-active herdr.service 2>/dev/null || echo 'inactive')"
echo "======================================================================"

if command -v herdr >/dev/null 2>&1; then
    sleep 1
    echo ""
    echo "==> Herdr Server Info:"
    run_as_user herdr status server || true
fi

echo ""
echo "======================================================================"
echo " SSH USAGE NOTE:"
echo " When connecting via SSH (standard or Tailscale SSH), specify your"
echo " local username, for example:"
echo "     ssh $TARGET_USER@<tailscale-ip-or-host>"
echo " or configure 'User $TARGET_USER' in your client's ~/.ssh/config."
echo ""
echo " BIOS NOTE:"
echo " Enable 'AC Power Recovery' / 'Restore on AC/Power Loss' in your"
echo " BIOS/UEFI settings to ensure the machine powers on automatically."
echo "======================================================================"
