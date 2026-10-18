sudo systemctl enable --now docker
sudo usermod -aG docker $USER
newgrp docker
docker info
ehco "require reboot to make it work with non-root"
