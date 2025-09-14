#!/usr/bin/env bash
set -euo pipefail

# === Konfigurasi VM ===
VM_NAME="ubuntu22"
MEM_MB=8192        # 8 GB
VCPUS=2
DISK_SIZE_GB=16
DISK_FILE="/var/lib/libvirt/images/${VM_NAME}.qcow2"
BASE_IMG="/var/lib/libvirt/images/jammy-server-cloudimg-amd64.img"
SEED_ISO="/var/lib/libvirt/images/${VM_NAME}-seed.iso"
CLOUD_IMG_URL="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
ROOT_PASS="root"
# ======================

if [ "$(id -u)" -ne 0 ]; then
  echo "❌ Jalankan script ini dengan sudo/root"
  exit 1
fi

echo "🔧 Install dependensi..."
apt-get update -y
apt-get install -y qemu-kvm libvirt-daemon-system libvirt-clients virtinst cloud-image-utils genisoimage wget

systemctl enable --now libvirtd

echo "📥 Download Ubuntu 22.04 cloud image..."
if [ ! -f "$BASE_IMG" ]; then
  wget -O "$BASE_IMG" "$CLOUD_IMG_URL"
fi

echo "💽 Membuat disk VM..."
if [ ! -f "$DISK_FILE" ]; then
  qemu-img create -f qcow2 -b "$BASE_IMG" "$DISK_FILE" "${DISK_SIZE_GB}G"
fi

echo "📝 Membuat konfigurasi cloud-init..."
WORKDIR=$(mktemp -d)

cat > "$WORKDIR/user-data" <<EOF
#cloud-config
users:
  - name: root
    lock_passwd: false
    plain_text_passwd: '${ROOT_PASS}'
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash

chpasswd:
  list: |
    root:${ROOT_PASS}
  expire: False

ssh_pwauth: true
disable_root: false
EOF

cat > "$WORKDIR/meta-data" <<EOF
instance-id: ${VM_NAME}
local-hostname: ${VM_NAME}
EOF

cloud-localds --format iso "$SEED_ISO" "$WORKDIR/user-data" "$WORKDIR/meta-data"

echo "🚀 Membuat VM ${VM_NAME}..."
virt-install \
  --name "$VM_NAME" \
  --memory "$MEM_MB" \
  --vcpus "$VCPUS" \
  --disk path="$DISK_FILE",format=qcow2 \
  --disk path="$SEED_ISO",device=cdrom \
  --os-variant ubuntu22.04 \
  --import \
  --graphics none \
  --noautoconsole \
  --network user,hostfwd=tcp::2222-:22

echo "✅ VM ${VM_NAME} selesai dibuat!"
echo ""
echo "👉 Untuk masuk ke VPS gunakan:"
echo "    ssh root@localhost -p 2222"
echo ""
echo "Username: root"
echo "Password: root"
