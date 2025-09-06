FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install tools dasar buat QEMU + cloud-init
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

# Buat cloud-init config (root login + paket Pterodactyl)
RUN echo '#cloud-config\n\
hostname: ubuntu-vm\n\
users:\n\
  - name: root\n\
    sudo: ALL=(ALL) NOPASSWD:ALL\n\
    shell: /bin/bash\n\
    lock_passwd: false\n\
    plain_text_passwd: "root"\n\
password: root\n\
chpasswd: { expire: False }\n\
ssh_pwauth: True\n\
package_update: true\n\
package_upgrade: true\n\
packages:\n\
  - curl\n\
  - wget\n\
  - unzip\n\
  - tar\n\
  - sudo\n\
  - gnupg\n\
  - software-properties-common\n\
  - apt-transport-https\n\
  - ca-certificates\n\
  - lsb-release\n\
  - mariadb-server\n\
  - redis-server\n\
  - nginx\n\
  - php8.1\n\
  - php8.1-cli\n\
  - php8.1-gd\n\
  - php8.1-mysql\n\
  - php8.1-pdo\n\
  - php8.1-mbstring\n\
  - php8.1-tokenizer\n\
  - php8.1-bcmath\n\
  - php8.1-xml\n\
  - php8.1-fpm\n\
  - composer\n\
  - docker.io\n\
  - docker-compose\n\
  - nodejs\n\
  - npm\n\
  - openssh-server\n\
runcmd:\n\
  - hostnamectl set-hostname ubuntu-vm\n\
  - systemctl enable ssh\n\
  - systemctl start ssh\n\
  - systemctl enable mariadb\n\
  - systemctl enable redis-server\n\
  - systemctl enable nginx\n\
  - systemctl enable docker\n\
  - systemctl start mariadb\n\
  - systemctl start redis-server\n\
  - systemctl start nginx\n\
  - systemctl start docker\n' > /user-data && \
    echo "instance-id: iid-local01\nlocal-hostname: ubuntu-vm" > /meta-data && \
    cloud-localds /seed.img /user-data /meta-data

# Jalankan langsung VM dengan VNC
CMD qemu-system-x86_64 \
    -m 4096 \
    -smp 2 \
    -drive file=/ubuntu.img,if=virtio,format=qcow2 \
    -drive file=/seed.img,if=virtio,format=raw \
    -net nic -net user,hostfwd=tcp::2222-:22,hostfwd=tcp::8080-:8080,hostfwd=tcp::80-:80,hostfwd=tcp::443-:443 \
    -vnc :0
