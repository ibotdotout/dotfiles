#!/usr/bin/env bash
# ==============================================================================
# Wi-Fi & DNS Optimization Script for Broadcom BCM43602 on Omarchy / Linux
# Generated after diagnostic analysis of DNS stalls and association reject issues.
# ==============================================================================

set -euo pipefail

# Ensure script is run with root privileges
if [ "${EUID}" -ne 0 ]; then
  echo "[-] This script requires root privileges to update systemd-resolved and network settings."
  echo "    Please run with sudo: sudo bash $0"
  exit 1
fi

echo "========================================================"
echo " Starting Wi-Fi & Network Performance Fix..."
echo "========================================================"

# ------------------------------------------------------------------------------
# 1. FIX DNS TIMEOUTS & STALLS
# ------------------------------------------------------------------------------
echo "[+] 1/4 Configuring Fast Cloudflare IPv4 DNS (removing unreachable IPv6 and TLS overhead)..."

# Ensure /etc/systemd/resolved.conf uses clean, fast Cloudflare IPv4 without TLS stalls
cat > /etc/systemd/resolved.conf << 'EOF'
[Resolve]
DNS=1.1.1.1 1.0.0.1
FallbackDNS=8.8.8.8 9.9.9.9
DNSOverTLS=no
MulticastDNS=no
LLMNR=no
EOF

# Update NetworkManager global DNS drop-in (managed by omarchy)
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
echo "[+] 2/4 Setting Wi-Fi regulatory domain to TH (Thailand) to unlock 5 GHz DFS channels..."
iw reg set TH 2>/dev/null || true

# Persist regulatory domain via systemd service
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
echo "[+] 3/4 Optimizing NetworkManager connection profile for 'bot-mesh'..."

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
# 4. CONFIGURE BROADCOM DRIVER OPTIONS (Disable buggy firmware roaming engine)
# ------------------------------------------------------------------------------
echo "[+] 4/5 Setting brcmfmac driver options (roamoff=1 to prevent mesh association drops)..."
cat > /etc/modprobe.d/brcmfmac.conf << 'EOF'
# Broadcom firmware supplicant fails WPA four-way handshake on Apple hardware (feature_disable=0x82000)
# and its internal roaming engine causes ASSOC-REJECT status 16 / drops on mesh networks (roamoff=1).
options brcmfmac feature_disable=0x82000 roamoff=1
EOF

# ------------------------------------------------------------------------------
# 5. RESTART SERVICES & REAPPLY CONFIGURATION
# ------------------------------------------------------------------------------
echo "[+] 5/5 Reloading NetworkManager and systemd-resolved..."

systemctl restart systemd-resolved
nmcli general reload conf >/dev/null 2>&1 || systemctl reload NetworkManager || true
nmcli general reload dns-full >/dev/null 2>&1 || true

# Reapply or reactivate Wi-Fi device
echo "[+] Reconnecting Wi-Fi interface (wlp3s0)..."
nmcli device reapply wlp3s0 >/dev/null 2>&1 || nmcli connection up "bot-mesh" >/dev/null 2>&1 || true

echo "========================================================"
echo " Wi-Fi & DNS optimization complete!"
echo " Current status:"
echo "--------------------------------------------------------"
resolvectl status | grep -E "Global|Current DNS Server|DNS Servers|DNSOverTLS" || true
echo "--------------------------------------------------------"
iw dev wlp3s0 link 2>/dev/null || true
echo "========================================================"
