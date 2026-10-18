# remap coolermaster keyboard
# print = scrolllock
# pause = 

sudo pacman -S --needed keyd

sudo mkdir -p /etc/keyd
sudo tee /etc/keyd/default.conf > /dev/null << 'EOF'
[ids]
*
[main]
scrolllock = print
EOF

sudo systemctl enable --now keyd
systemctl is-active keyd

# sudo systemctl restart keyd
