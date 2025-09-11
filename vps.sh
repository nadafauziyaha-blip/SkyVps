#!/bin/bash
set -e

echo "[+] Install Docker & Docker Compose..."
apt-get update -y
apt-get install -y docker.io docker-compose wget qemu-utils cloud-image-utils

mkdir -p ~/kvm-vps
cd ~/kvm-vps

echo "[+] Buat Dockerfile..."
cat > Dockerfile <<'EOF'
FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    qemu-kvm \
    wget \
    cloud-image-utils \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/lib/vm

# Download Ubuntu Cloud Image
RUN wget -O ubuntu.qcow2 https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Resize disk jadi 100GB
RUN qemu-img resize ubuntu.qcow2 100G

# Cloud-init config (root/root login)
RUN echo '#cloud-config\n\
password: root\n\
chpasswd: { expire: False }\n\
ssh_pwauth: True\n' > user-data

RUN cloud-localds seed.iso user-data

CMD qemu-system-x86_64 \
    -enable-kvm \
    -m 32768 \
    -smp 8 \
    -cpu host \
    -drive file=ubuntu.qcow2,format=qcow2 \
    -drive file=seed.iso,format=raw \
    -net nic -net user,hostfwd=tcp::2222-:22 \
    -nographic
EOF

echo "[+] Buat docker-compose.yml..."
cat > docker-compose.yml <<'EOF'
version: "3.9"
services:
  kvm-vps:
    build: .
    container_name: kvm-vps
    privileged: true
    devices:
      - /dev/kvm:/dev/kvm
    ports:
      - "2222:22"
    deploy:
      resources:
        limits:
          cpus: "8"
          memory: 32G
EOF

echo "[+] Build Docker image..."
docker-compose build

echo "[+] Start VPS..."
docker-compose up -d

echo "[+] VPS siap! Login SSH:"
echo "ssh root@localhost -p 2222"
echo "Password: root"
