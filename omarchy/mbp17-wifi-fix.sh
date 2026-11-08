#!/usr/bin/env bash
# ==============================================================================
# Wi-Fi & DNS Optimization Script for Broadcom BCM43602 on Omarchy / Linux
# Targets: MacBookPro14,3 (and 13,*) running brcmfmac on mesh Wi-Fi networks
# ==============================================================================

set -euo pipefail

# Ensure script is run with root privileges
if [ "${EUID}" -ne 0 ]; then
  echo "[-] This script requires root privileges to update systemd-resolved and network settings."
  echo "    Please run with sudo: sudo bash $0"
  exit 1
fi

echo "========================================================"
echo " Starting Wi-Fi, DNS & Network Resilience Optimization..."
echo "========================================================"

# ------------------------------------------------------------------------------
# 1. FIX DNS TIMEOUTS & STALLS
# ------------------------------------------------------------------------------
echo "[+] 1/6 Configuring Fast Cloudflare IPv4 DNS (eliminating unreachable IPv6 & TLS delay)..."

cat > /etc/systemd/resolved.conf << 'EOF'
[Resolve]
DNS=1.1.1.1 1.0.0.1
FallbackDNS=8.8.8.8 9.9.9.9
DNSOverTLS=no
MulticastDNS=no
LLMNR=no
EOF

NM_DNS_CONF="/etc/NetworkManager/conf.d/20-omarchy-dns.conf"
if [ -d /etc/NetworkManager/conf.d ]; then
  cat > "$NM_DNS_CONF" << 'EOF'
# Managed by omarchy-dns - Optimized IPv4 DNS
[global-dns]

[global-dns-domain-*]
servers=1.1.1.1,1.0.0.1
EOF
fi

# ------------------------------------------------------------------------------
# 2. SET REGULATORY DOMAIN (Unlocks full 5 GHz channels for Broadcom card)
# ------------------------------------------------------------------------------
echo "[+] 2/6 Setting Wi-Fi regulatory domain to TH (Thailand) to unlock 5 GHz DFS channels..."
iw reg set TH 2>/dev/null || true

cat > /etc/systemd/system/set-wifi-regdom.service << 'EOF'
[Unit]
Description=Set Wireless Regulatory Domain
After=network-pre.target
Wants=network-pre.target

[Service]
Type=oneshot
ExecStart=/usr/bin/iw reg set TH
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable set-wifi-regdom.service >/dev/null 2>&1 || true

# ------------------------------------------------------------------------------
# 3. OPTIMIZE 'bot-mesh' NETWORK PROFILE IN NETWORKMANAGER
# ------------------------------------------------------------------------------
echo "[+] 3/6 Optimizing NetworkManager connection profile for 'bot-mesh'..."

if nmcli connection show "bot-mesh" >/dev/null 2>&1; then
  # Clear existing IPv6 DNS and disable IPv6 on this connection (since upstream router doesn't route IPv6)
  nmcli connection modify "bot-mesh" ipv6.dns "" ipv6.ignore-auto-dns yes ipv6.method "disabled"

  # Pin fast IPv4 DNS
  nmcli connection modify "bot-mesh" ipv4.dns "1.1.1.1,1.0.0.1"
  nmcli connection modify "bot-mesh" ipv4.ignore-auto-dns yes

  # Ensure Wi-Fi power save remains disabled
  nmcli connection modify "bot-mesh" 802-11-wireless.powersave 2

  # Configure PMF (Protected Management Frames) compatibility for Broadcom BCM43602:
  # Value 1 = disable (prevents ASSOC-REJECT status 16 with mesh routers requiring PMF)
  nmcli connection modify "bot-mesh" 802-11-wireless-security.pmf 1

  # Allow automatic band roaming between 2.4 GHz and 5 GHz
  nmcli connection modify "bot-mesh" 802-11-wireless.band ""
else
  echo "[!] Notice: Connection profile 'bot-mesh' not found by exact name. Skipping profile modification."
fi

# ------------------------------------------------------------------------------
# 4. CONFIGURE BROADCOM DRIVER OPTIONS & APPLE NVRAM (Bugzilla 193121 Fix)
# ------------------------------------------------------------------------------
echo "[+] 4/6 Setting brcmfmac driver options (roamoff=1 to prevent mesh association drops)..."

cat > /etc/modprobe.d/brcmfmac.conf << 'EOF'
# feature_disable=0x82000: Disables firmware supplicant/authenticator to prevent WPA 4-way handshake failures
# roamoff=1: Disables Broadcom internal firmware roaming engine (which crashes on 802.11k/v/r mesh networks with
# ASSOC-REJECT status 16) and hands roaming decision authority back to Linux user-space (wpa_supplicant / NetworkManager).
options brcmfmac feature_disable=0x82000 roamoff=1
EOF

echo "[+] 5/6 Optimizing Apple Broadcom NVRAM parameters (regrev=1 unthrottles 5 GHz TX power)..."
NVRAM_TXT="/usr/lib/firmware/brcm/brcmfmac43602-pcie.txt"
DMI_TXT="/usr/lib/firmware/brcm/brcmfmac43602-pcie.Apple Inc.-MacBookPro14,3.txt"
if [ -f "$NVRAM_TXT" ]; then
  cp -n "$NVRAM_TXT" "${NVRAM_TXT}.bak" 2>/dev/null || true
  # Change regrev=245 to regrev=1 to unlock 5 GHz power limits
  sed -i 's/^regrev=245/regrev=1/' "$NVRAM_TXT"
  # Symlink DMI model name so the kernel loads it unambiguously
  ln -sf "brcmfmac43602-pcie.txt" "$DMI_TXT"
fi

# ------------------------------------------------------------------------------
# 5. KERNEL TCP KEEPALIVE SETTINGS (Prevents SSH / Tailscale WireGuard freezes)
# ------------------------------------------------------------------------------
cat > /etc/sysctl.d/99-wifi-resilience.conf << 'EOF'
# Faster detection and recovery from Wi-Fi dropouts / packet loss for SSH and WireGuard
net.ipv4.tcp_keepalive_time = 30
net.ipv4.tcp_keepalive_intvl = 10
net.ipv4.tcp_keepalive_probes = 3
EOF
sysctl --system >/dev/null 2>&1 || true

# ------------------------------------------------------------------------------
# 6. RESTART SERVICES & REAPPLY CONFIGURATION
# ------------------------------------------------------------------------------
echo "[+] 6/6 Reloading NetworkManager and systemd-resolved..."

systemctl restart systemd-resolved
nmcli general reload conf >/dev/null 2>&1 || systemctl reload NetworkManager || true
nmcli general reload dns-full >/dev/null 2>&1 || true

# Reapply or reactivate Wi-Fi device
echo "[+] Reconnecting Wi-Fi interface (wlp3s0)..."
nmcli device reapply wlp3s0 >/dev/null 2>&1 || nmcli connection up "bot-mesh" >/dev/null 2>&1 || true

echo "========================================================"
echo " Wi-Fi, Driver & DNS optimization complete!"
echo " Current status:"
echo "--------------------------------------------------------"
resolvectl status | grep -E "Global|Current DNS Server|DNS Servers|DNSOverTLS" || true
echo "--------------------------------------------------------"
iw dev wlp3s0 link 2>/dev/null || true
echo "========================================================"
echo "NOTE: A reboot is recommended to reload the brcmfmac driver module with roamoff=1"
echo "and apply the unthrottled NVRAM parameters into the wireless SoC."
