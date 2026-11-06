#!/usr/bin/env bash
#
# enable-user-lingering.sh
#
# Enables user lingering and sets up services so Tailscale, SSH, and Herdr
# start automatically on boot without requiring a user login.
# Also configures TPM 2.0 disk auto-unlock for encrypted drives (LUKS) so
# the machine boots unattended without requiring keyboard passphrase input.
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

# 7. Configure TPM 2.0 auto-unlock for encrypted root disk (unattended boot)
echo "==> Checking disk encryption and TPM 2.0 auto-unlock status..."
ROOT_DEV=$(findmnt -no SOURCE / 2>/dev/null | sed 's/\[.*\]//' || true)
LUKS_DEV=""
if [ -n "$ROOT_DEV" ]; then
    LUKS_DEV=$(lsblk -nsrpo NAME,FSTYPE "$ROOT_DEV" 2>/dev/null | awk '$2 == "crypto_LUKS" { print $1; exit }' || true)
fi

if [ -n "$LUKS_DEV" ]; then
    LUKS_UUID=$(lsblk -dno UUID "$LUKS_DEV" 2>/dev/null || true)
    echo "    Found encrypted root drive: $LUKS_DEV (UUID: $LUKS_UUID)"

    if [ -e /dev/tpmrm0 ] && command -v systemd-cryptenroll >/dev/null 2>&1; then
        # Enroll/re-enroll TPM 2.0 token without volatile PCRs.
        # When Secure Boot is disabled or after a cold power-cut (smart plug), binding to PCR 0 or 7
        # causes 'TPM policy does not match current system state'.
        # Binding with --tpm2-pcrs="" securely seals the key to the hardware TPM 2.0 chip
        # while remaining 100% reliable across cold boot, power cut, and kernel updates.
        echo "==> Configuring TPM 2.0 token for unattended cold boot (hardware-bound, no volatile PCRs)..."
        echo "    NOTE: You will be prompted once to enter your existing disk passphrase."
        run_as_root systemd-cryptenroll "$LUKS_DEV" --wipe-slot=tpm2 2>/dev/null || true
        run_as_root systemd-cryptenroll "$LUKS_DEV" --tpm2-device=auto --tpm2-pcrs=""

        # Configure /etc/crypttab with x-initrd.attach so sd-encrypt knows to unlock it in initramfs
        echo "==> Configuring /etc/crypttab for initramfs auto-unlock..."
        if [ ! -f /etc/crypttab ] || ! grep -q "$LUKS_UUID" /etc/crypttab 2>/dev/null; then
            cat << EOF | run_as_root tee -a /etc/crypttab >/dev/null
omarchy_root UUID=$LUKS_UUID - tpm2-device=auto,x-initrd.attach
EOF
        elif ! grep -q "x-initrd.attach" /etc/crypttab 2>/dev/null; then
            run_as_root sed -i "s|.*$LUKS_UUID.*|omarchy_root UUID=$LUKS_UUID - tpm2-device=auto,x-initrd.attach|" /etc/crypttab
        fi

        # Configure mkinitcpio drop-in for systemd and sd-encrypt
        echo "==> Configuring mkinitcpio for systemd sd-encrypt..."
        cat << 'EOF' | run_as_root tee /etc/mkinitcpio.conf.d/99-tpm2-sd-encrypt.conf >/dev/null
# Generated by enable-user-lingering.sh
# Systemd initramfs hooks with TPM2 auto-unlock and Plymouth splash fallback
HOOKS=(base systemd plymouth autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck resume)
EOF

        # Ensure kernel cmdline in /etc/default/limine has rd.luks parameters
        if [ -f /etc/default/limine ]; then
            if ! grep -q "rd.luks.name" /etc/default/limine 2>/dev/null; then
                echo "==> Adding rd.luks parameters to /etc/default/limine..."
                run_as_root sed -i "/KERNEL_CMDLINE\[default\]+=/ s|\"\(.*\)\"|\"\1 rd.luks.name=$LUKS_UUID=omarchy_root rd.luks.options=tpm2-device=auto\"|" /etc/default/limine
            fi
        fi

        # Rebuild initramfs and update bootloader
        echo "==> Rebuilding initramfs and updating bootloader..."
        if command -v limine-update >/dev/null 2>&1; then
            run_as_root limine-update
        elif command -v limine-mkinitcpio >/dev/null 2>&1; then
            run_as_root limine-mkinitcpio
        else
            run_as_root mkinitcpio -P
        fi
        echo "==> TPM 2.0 auto-unlock successfully configured!"
    else
        echo "==> WARNING: Hardware TPM 2.0 (/dev/tpmrm0) not detected or systemd-cryptenroll missing. Skipping auto-unlock."
    fi
else
    echo "==> Root filesystem is not on a LUKS encrypted partition. Skipping TPM 2.0 unlock."
fi

# 8. Configure Wake-on-LAN for Ethernet interfaces
if command -v nmcli >/dev/null 2>&1; then
    WIRED_CON=$(nmcli -t -f NAME,TYPE connection show 2>/dev/null | awk -F: '$2 == "802-3-ethernet" { print $1; exit }' || true)
    if [ -n "$WIRED_CON" ]; then
        echo "==> Ensuring Wake-on-LAN (magic packet) is enabled on '$WIRED_CON'..."
        run_as_root nmcli connection modify "$WIRED_CON" 802-3-ethernet.wake-on-lan magic 2>/dev/null || true
    fi
fi

# 9. Configure automatic screen lock on boot (protect physical workstation)
AUTOSTART_FILE="$TARGET_HOME/.config/hypr/autostart.lua"
if [ -f "$AUTOSTART_FILE" ]; then
    if ! grep -q "omarchy-system-lock" "$AUTOSTART_FILE" 2>/dev/null; then
        echo "==> Configuring automatic screen lock on boot in $AUTOSTART_FILE..."
        cat << 'EOF' >> "$AUTOSTART_FILE"

-- Automatically lock screen on boot to protect the physical machine
o.exec_on_start("sleep 1 && omarchy-system-lock")
EOF
        if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
            chown "$TARGET_USER:$TARGET_USER" "$AUTOSTART_FILE"
        fi
    else
        echo "==> Automatic screen lock on boot is already configured in $AUTOSTART_FILE."
    fi
fi

# 10. Create systemd user service directory
mkdir -p "$SERVICE_DIR"

# 11. Stop any existing unmanaged herdr server instances to let systemd supervise
if pgrep -x herdr >/dev/null 2>&1 && ! run_as_user systemctl --user is-active herdr.service >/dev/null 2>&1; then
    echo "==> Stopping existing unmanaged herdr server..."
    run_as_user herdr server stop 2>/dev/null || true
    sleep 1
    if pgrep -x herdr >/dev/null 2>&1; then
        pkill -x herdr 2>/dev/null || true
        sleep 1
    fi
fi

# 12. Create herdr.service unit file
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

# 13. Reload user systemd daemon, enable and start herdr.service
echo "==> Reloading user systemd daemon and enabling herdr.service..."
run_as_user systemctl --user daemon-reload
run_as_user systemctl --user enable --now herdr.service

# 14. Verification and status display
echo ""
echo "======================================================================"
echo " ==> Verification Status:"
echo " - Lingering status    : $(loginctl show-user "$TARGET_USER" --property=Linger --value 2>/dev/null || echo 'unknown')"
echo " - tailscaled status   : $(systemctl is-active tailscaled.service 2>/dev/null || echo 'inactive')"
echo " - sshd status         : $(systemctl is-active sshd.service 2>/dev/null || echo 'inactive')"
echo " - Tailscale SSH       : $(tailscale debug prefs 2>/dev/null | jq -r 'if .RunSSH then "enabled" else "disabled" end' 2>/dev/null || echo 'unknown')"
echo " - herdr.service status: $(run_as_user systemctl --user is-active herdr.service 2>/dev/null || echo 'inactive')"
if [ -n "${LUKS_DEV:-}" ]; then
    TPM_STATUS="not enrolled"
    if run_as_root systemd-cryptenroll "$LUKS_DEV" 2>/dev/null | grep -q "tpm2"; then
        TPM_STATUS="enrolled (active)"
    fi
    echo " - TPM 2.0 Auto-Unlock : $TPM_STATUS ($LUKS_DEV)"
fi
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
echo " 1. UNATTENDED BOOT (TPM 2.0 & AUTO-LOCK):"
echo "    Your LUKS disk encryption is bound to your hardware TPM 2.0 chip."
echo "    On cold boot, the drive unlocks automatically without touching the"
echo "    physical keyboard, and the desktop immediately locks with the lock screen."
echo "    Your manual password remains active as a fallback."
echo ""
echo " 2. DIRECT SSH vs HERDR:"
echo "    The SSH connection logs into standard bash. Herdr server runs in the"
echo "    background. If your mobile app (Moshi) automatically opens Herdr,"
echo "    open the connection settings in Moshi and set 'Multiplexer/Session' to 'None'."
echo ""
echo " 3. COLD-BOOT DELAY (~25-30 SECONDS):"
echo "    On cold boot, NetworkManager takes ~5-10s to acquire DHCP/Wi-Fi, and"
echo "    Tailscale takes ~15-20s to sync its SSH security policy with the"
echo "    control plane. Connecting within the first 20 seconds will return"
echo "    'connection refused' or show offline. Wait 30 seconds after powering"
echo "    on before connecting."
echo ""
echo " 4. USERNAME REQUIREMENT:"
echo "    When connecting via SSH (standard or Tailscale SSH), specify your"
echo "    local username '$TARGET_USER':"
echo "        ssh $TARGET_USER@<tailscale-ip-or-host>"
echo "    (e.g. ssh $TARGET_USER@botamd5)"
echo "    If you omit '$TARGET_USER', the client device may attempt your remote"
echo "    identity name which will be rejected by the system."
echo ""
echo " 5. BIOS CONFIGURATION:"
echo "    Enable 'AC Power Recovery' / 'Restore on AC/Power Loss' in your"
echo "    BIOS/UEFI settings to ensure the machine powers on automatically"
echo "    when your smart plug turns power on."
echo "======================================================================"
