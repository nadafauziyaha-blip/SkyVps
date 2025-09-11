FROM ubuntu:22.04

# Install QEMU + tools
RUN apt-get update && apt-get install -y \
    qemu-kvm \
    libvirt-daemon-system \
    libvirt-clients \
    virt-manager \
    bridge-utils \
    wget \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /var/lib/vm

# Download ISO Ubuntu Server (22.04 minimal)
RUN wget -O ubuntu.iso https://releases.ubuntu.com/22.04/ubuntu-22.04.4-live-server-amd64.iso

# Buat disk 100GB
RUN qemu-img create -f qcow2 ubuntu-vm.qcow2 100G

# Jalankan VM otomatis saat container start
CMD qemu-system-x86_64 \
    -enable-kvm \
    -m 32768 \
    -smp 8 \
    -cpu host \
    -hda ubuntu-vm.qcow2 \
    -boot d \
    -cdrom ubuntu.iso \
    -vnc :0 \
    -net nic -net user,hostfwd=tcp::2222-:22
    
