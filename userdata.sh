#!/bin/bash
set -x
#exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
export PATH="$PATH:/usr/bin"
# formateo de volumen
sudo mkfs -t xfs /dev/xvdh
# creación carpeta
sudo mkdir -p /usr/share/nginx/html
# montaje
echo "/dev/xvdh  /usr/share/nginx/html  xfs  defaults,nofail  0  2" | sudo tee -a /etc/fstab
sudo mount /dev/xvdh /usr/share/nginx/html

sudo apt update
# Instalar servidor Web
sudo apt install -y nginx
# habilita nginx
sudo systemctl enable nginx
# inicia el servidor
sudo systemctl start nginx

# firewalld
sudo apt install -y firewalld
sudo systemctl enable firewalld
sudo systemctl start firewalld
# abrir puerto
sudo firewall-cmd --zone=public --permanent  --add-service=http
# sudo firewall-cmd --permanent --add-port={80/tcp}
sudo firewall-cmd --reload