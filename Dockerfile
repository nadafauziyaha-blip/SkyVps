FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install tools
RUN apt-get update && apt-get install -y \
    qemu-system-x86 \
    qemu-utils \
    cloud-image-utils \
    wget \
    curl \
    tmate \
    && rm -rf /var/lib/apt/lists/*

# Download Ubuntu cloud image
RUN wget -O /ubuntu.img https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img

# Resize disk jadi 32GB
RUN qemu-img resize /ubuntu.img 32G

# Buat cloud-init config (root login)
RUN echo '#cloud-config\n\
hostname: docker-vm\n\
users:\n\
  - name: root\n\
    sudo: ALL=(ALL) NOPASSWD:ALL\n\
    shell: /bin/bash\n\
    lock_passwd: false\n\
    plain_text_passwd: "root"\n\
password: root\n\
chpasswd: { expire: False }\n\
ssh_pwauth: True\n' > /user-data && \
    echo "instance-id: iid-local01\nlocal-hostname: docker-vm" > /meta-data && \
    cloud-localds /seed.img /user-data /meta-data

# Jalankan langsung VM dan attach ke console
CMD qemu-system-x86_64 \
    -m 16384 \
    -smp 8 \
    -drive file=/ubuntu.img,if=virtio \
    -drive file=/seed.img,if=virtio \
    -nographic
    
