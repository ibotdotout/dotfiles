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

# 4. Configure Tailscale Operator and SSH
if command -v tailscale >/dev/null 2>&1; then
    echo "==> Configuring Tailscale operator and Tailscale SSH..."
    run_as_root tailscale set --operator="$TARGET_USER" >/dev/null 2>&1 || true
    tailscale set --ssh >/dev/null 2>&1 || run_as_root tailscale set --ssh >/dev/null 2>&1 || true
fi

# 5. Configure loose reverse path filtering (rp_filter) for Tailscale
echo "==> Configuring reverse path filtering (rp_filter=2) for Tailscale..."
cat << 'EOF' | run_as_root tee /etc/sysctl.d/99-tailscale.conf >/dev/null
net.ipv4.conf.all.rp_filter = 2
net.ipv4.conf.default.rp_filter = 2
EOF
run_as_root sysctl -p /etc/sysctl.d/99-tailscale.conf >/dev/null 2>&1 || true

# 6. Configure firewall (UFW) to permit Tailscale VPN and SSH traffic
if command -v ufw >/dev/null 2>&1; then
    echo "==> Ensuring firewall allows Tailscale interface and ports..."
    run_as_root ufw allow in on tailscale0 comment "Tailscale VPN traffic" >/dev/null 2>&1 || true
    run_as_root ufw allow 41641/udp comment "Tailscale WireGuard listen port" >/dev/null 2>&1 || true
    run_as_root ufw allow 22/tcp comment "OpenSSH port" >/dev/null 2>&1 || true
    run_as_root ufw reload >/dev/null 2>&1 || true
fi

# 7. Create systemd user service directory
mkdir -p "$SERVICE_DIR"

# 8. Stop any existing unmanaged herdr server instances to let systemd supervise
if pgrep -x herdr >/dev/null 2>&1 && ! run_as_user systemctl --user is-active herdr.service >/dev/null 2>&1; then
    echo "==> Stopping existing unmanaged herdr server..."
    run_as_user herdr server stop 2>/dev/null || true
    sleep 1
    if pgrep -x herdr >/dev/null 2>&1; then
        pkill -x herdr 2>/dev/null || true
        sleep 1
    fi
fi

# 9. Create herdr.service unit file
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

# 10. Reload user systemd daemon, enable and start herdr.service
echo "==> Reloading user systemd daemon and enabling herdr.service..."
run_as_user systemctl --user daemon-reload
run_as_user systemctl --user enable --now herdr.service

# 11. Verification and status display
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
echo " IMPORTANT NOTES FOR REMOTE UNATTENDED ACCESS:"
echo ""
echo " 1. COLD-BOOT DELAY (~25-30 SECONDS):"
echo "    On cold boot, NetworkManager takes ~5-10s to acquire DHCP/Wi-Fi, and"
echo "    Tailscale takes ~15-20s to sync its SSH security policy with the"
echo "    control plane. Connecting within the first 20 seconds will return"
echo "    'connection refused' or show offline. Wait 30 seconds after powering"
echo "    on before connecting."
echo ""
echo " 2. USERNAME REQUIREMENT:"
echo "    When connecting via SSH (standard or Tailscale SSH), specify your"
echo "    local username '$TARGET_USER':"
echo "        ssh $TARGET_USER@<tailscale-ip-or-host>"
echo "    (e.g. ssh $TARGET_USER@botamd5)"
echo "    If you omit '$TARGET_USER', the client device may attempt your remote"
echo "    identity name which will be rejected by the system."
echo ""
echo " 3. BIOS CONFIGURATION:"
echo "    Enable 'AC Power Recovery' / 'Restore on AC/Power Loss' in your"
echo "    BIOS/UEFI settings to ensure the machine powers on automatically."
echo "======================================================================"
