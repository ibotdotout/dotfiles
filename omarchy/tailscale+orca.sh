# Tailscale
sudo pacman -S tailscale
sudo tailscale down
sudo tailscale up
tailscale ip --4
tailscale status
omarchy plugin enable omarchy.tailscale

# Tailscale https
# -- https://tailscale.com/docs/how-to/set-up-https-certificates
# -- https://tailscale.com/docs/features/tailscale-serve
#
# Tailscale send file
# sudo tailscale file cp /path/to/file target-hostname-or-ip:
# sudo tailscale file get .

# Orca
yay -S stably-orca-bin
mkdir -p ~/.local/bin
ln -sf /usr/bin/stably-orca ~/.local/bin/orca
orca #deskop
orca serve --host 0.0.0.0 --port 8080 #headless

