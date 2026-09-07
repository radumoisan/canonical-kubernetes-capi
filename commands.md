# Commands Tracker

This file records only training-material commands that were actually executed successfully during live lab validation.

Rules:

- Record successful commands only.
- Do not record failed commands.
- Do not record exploratory or diagnostic commands that are not part of the training material.
- Keep commands in execution order.

## Session History

### Chapter 4: Boot and System Initialization

```bash
ssh ubuntu@10.8.14.201 "systemctl cat libvirtd.service"
```

```bash
ssh ubuntu@10.8.14.201 "systemctl list-dependencies libvirtd.service"
```

```bash
ssh ubuntu@10.8.14.201 "systemctl list-dependencies --reverse libvirtd.service"
```

```bash
ssh ubuntu@10.8.14.201 "systemd-analyze blame"
```

```bash
ssh ubuntu@10.8.14.201 "systemd-analyze plot > /home/ubuntu/plot.svg"
```

```bash
ssh ubuntu@10.8.14.201 "sudo mkdir -p /var/log/journal"
```

```bash
ssh ubuntu@10.8.14.201 "sudo killall -USR1 systemd-journald"
```

```bash
ssh ubuntu@10.8.14.201 "systemctl list-units --type=service"
```

```bash
ssh ubuntu@10.8.14.201 "systemctl list-units --type=service --state=running"
```

```bash
ssh ubuntu@10.8.14.201 "systemctl -a | grep ssh"
```

```bash
ssh ubuntu@10.8.14.201 "sudo systemctl stop libvirtd.service"
```

```bash
ssh ubuntu@10.8.14.201 "sudo systemctl status libvirtd.service"
```

```bash
ssh ubuntu@10.8.14.201 "sudo systemctl start libvirtd.service"
```

```bash
ssh ubuntu@10.8.14.201 "sudo systemctl status libvirtd.service"
```

```bash
ssh ubuntu@10.8.14.201 "systemctl cat libvirtd.service"
```

```bash
ssh ubuntu@10.8.14.201 "systemctl list-dependencies libvirtd.service"
```

```bash
ssh ubuntu@10.8.14.201 "systemctl show libvirtd.service"
```

```bash
ssh ubuntu@10.8.14.201 "systemctl --failed"
```

```bash
ssh ubuntu@10.8.14.201 "systemd-analyze blame"
```

```bash
ssh ubuntu@10.8.14.201 "sudo journalctl"
```

```bash
ssh ubuntu@10.8.14.201 "sudo journalctl -b"
```

```bash
ssh ubuntu@10.8.14.201 "journalctl -b -1"
```

```bash
ssh ubuntu@10.8.14.201 "journalctl -b -2"
```

```bash
ssh ubuntu@10.8.14.201 "journalctl --list-boots"
```

```bash
ssh ubuntu@10.8.14.201 "sudo journalctl -k"
```

```bash
ssh ubuntu@10.8.14.201 "sudo journalctl -k -b -2"
```

```bash
ssh ubuntu@10.8.14.201 "sudo journalctl -k -b | grep 'apparmor=\"DENIED\"'"
```

```bash
ssh ubuntu@10.8.14.201 "sudo journalctl -u ssh.service"
```

```bash
ssh ubuntu@10.8.14.201 "sudo journalctl -u libvirtd.service"
```

```bash
ssh ubuntu@10.8.14.201 "sudo mkdir -p /var/log/journal"
```

```bash
ssh ubuntu@10.8.14.201 "sudo systemctl restart systemd-journald"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 touch ~/service.sh"
```

```bash
printf '%s\n' '#!/bin/bash' '' 'DATE=$(date '\''+%Y-%m-%d %H:%M:%S'\'')' 'echo "Service started at ${DATE}"' '' 'while :' 'do' '  echo "Service is running..."' '  sleep 30' 'done' | sshpass -p ubuntu ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'sudo tee /home/ubuntu/service.sh >/dev/null'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo chmod +x ~/service.sh"
```

```bash
printf '%s\n' '[Unit]' 'Description=This is an example of a simple systemd service.' '' '[Service]' 'Type=simple' 'ExecStart=/bin/bash /home/ubuntu/service.sh' '' '[Install]' 'WantedBy=multi-user.target' | sshpass -p ubuntu ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'sudo tee /etc/systemd/system/myservice.service >/dev/null'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo chmod 644 /etc/systemd/system/myservice.service"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo systemctl start myservice.service"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo systemctl enable myservice.service"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo systemctl status myservice.service"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo journalctl -u myservice.service"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo systemctl stop myservice.service"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo systemctl disable myservice.service"
```

```bash
ssh ubuntu@10.8.14.201 "systemctl list-timers"
```

```bash
ssh ubuntu@10.8.14.201 "sudo systemd-run --on-active=1 /bin/touch /tmp/has_ran_from_systemd"
```

```bash
ssh ubuntu@10.8.14.201 "ls -l /tmp/has_ran_from_systemd"
```

```bash
printf '%s\n' '[Unit]' 'Description=Watch for file creation in /tmp/watchme' '' '[Path]' 'PathExists=/tmp/watchme' 'Unit=mywatch.service' '' '[Install]' 'WantedBy=multi-user.target' | ssh ubuntu@10.8.14.201 'sudo tee /etc/systemd/system/mywatch.path >/dev/null'
```

```bash
printf '%s\n' '[Unit]' 'Description=Triggered when /tmp/watchme is created' '' '[Service]' 'Type=oneshot' 'ExecStart=/bin/sh -c '\''echo "The file appeared!" > /tmp/watched.log'\''' | ssh ubuntu@10.8.14.201 'sudo tee /etc/systemd/system/mywatch.service >/dev/null'
```

```bash
ssh ubuntu@10.8.14.201 "sudo systemctl enable --now mywatch.path"
```

```bash
ssh ubuntu@10.8.14.201 "touch /tmp/watchme"
```

```bash
ssh ubuntu@10.8.14.201 "cat /tmp/watched.log"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 systemctl list-timers"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo apt install -y at"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 \"echo 'touch /tmp/has_ran_from_atd' | at now+1minute\""
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 atq"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ls -l /tmp/has_ran_from_atd"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 touch ~/job.sh"
```

```bash
printf '%s\n' '#!/bin/bash' '' 'sudo rm /tmp/has_ran_from_atd' | ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'sudo tee /home/ubuntu/job.sh >/dev/null'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 chmod +x ~/job.sh"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'at now+1minute -f ~/job.sh'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ls -l /tmp/has_ran_from_atd"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 \"echo 'touch /tmp/has_ran_from_batch' | batch\""
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'ls -l /tmp/has_ran_from_batch /tmp/has_ran_from_atd'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=accept-new ubuntu@192.168.101.50 info -f grub -n 'Simple configuration'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 cat /etc/default/grub"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo apt install -y vim"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo rm /etc/default/grub.d/50-cloudimg-settings.cfg"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo update-grub"
```

```bash
printf '%s\n' 'GRUB_DEFAULT="saved"' 'GRUB_SAVEDEFAULT="true"' 'GRUB_TIMEOUT_STYLE="menu"' 'GRUB_TIMEOUT=10' 'GRUB_RECORDFAIL_TIMEOUT=$GRUB_TIMEOUT' 'GRUB_DISABLE_SUBMENU=y' 'GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`' 'GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"' 'GRUB_CMDLINE_LINUX="console=tty0 console=ttyS0,115200n8 rootdelay=60"' 'GRUB_TERMINAL="console serial"' 'GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"' "GRUB_GFXMODE='auto'" | sshpass -p ubuntu ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'sudo tee /etc/default/grub >/dev/null'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo cat /etc/default/grub"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo update-grub"
```

```bash
sudo virsh console ubuntu
```

```bash
sudo reboot
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 uname -r"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo apt update"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo apt install -y --install-recommends linux-generic-hwe-24.04"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 dpkg --list | grep linux-image"
```

```bash
sudo reboot
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 uname -r"
```

### Chapter 3: OpenSSH

```bash
ssh ubuntu@10.8.14.201 'export LABHOSTIP=192.168.101.1; export LABVMIP=192.168.101.50; export INTERNALVMIP=192.168.101.51; echo "LABHOSTIP=192.168.101.1" >> ~/.bashrc; echo "LABVMIP=192.168.101.50" >> ~/.bashrc; echo "INTERNALVMIP=192.168.101.51" >> ~/.bashrc; export USER=ubuntu'
```

```bash
ssh ubuntu@10.8.14.201 "printf '\n\n\n' | ssh-keygen"
```

```bash
ssh ubuntu@10.8.14.201 'ls -al ~/.ssh/'
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh-copy-id -o StrictHostKeyChecking=no ubuntu@192.168.101.50"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'exit'"
```

```bash
ssh ubuntu@10.8.14.201 'systemctl status ssh'
```

```bash
ssh ubuntu@10.8.14.201 'ps -el | grep ssh-agent'
```

```bash
ssh ubuntu@10.8.14.201 'eval $(ssh-agent)'
```

```bash
ssh ubuntu@10.8.14.201 'eval $(ssh-agent) && ssh-add ~/.ssh/id_ed25519'
```

```bash
ssh ubuntu@10.8.14.201 'eval $(ssh-agent) && ssh-add ~/.ssh/id_ed25519 >/dev/null && ssh-add -l'
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo adduser myadmin --disabled-password --gecos \"\"'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo usermod -aG sudo myadmin'"
```

```bash
ssh ubuntu@10.8.14.201 "printf '\n\n' | ssh-keygen -t ed25519 -f ~/.ssh/id_custom"
```

```bash
ssh ubuntu@10.8.14.201 "cat ~/.ssh/id_custom.pub | ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo install -d -m 700 -o myadmin -g myadmin /home/myadmin/.ssh && sudo tee /home/myadmin/.ssh/authorized_keys >/dev/null && sudo chown myadmin:myadmin /home/myadmin/.ssh/authorized_keys && sudo chmod 600 /home/myadmin/.ssh/authorized_keys'"
```

```bash
ssh ubuntu@10.8.14.201 'touch ~/.ssh/config && chmod 600 ~/.ssh/config'
```

```bash
ssh ubuntu@10.8.14.201 "tee -a ~/.ssh/config <<'EOF'
Host labvm
  HostName 192.168.101.50
  User myadmin
  IdentityFile ~/.ssh/id_custom
EOF"
```

```bash
ssh ubuntu@10.8.14.201 'ssh labvm'
```

```bash
ssh ubuntu@10.8.14.201 "ssh labvm 'exit'"
```

```bash
ssh ubuntu@10.8.14.201 'sudo apt install -y elinks'
```

```bash
ssh ubuntu@10.8.14.201 'timeout 20 elinks -dump https://127.0.0.1:443'
```

```bash
ssh ubuntu@10.8.14.201 'timeout 20 elinks -dump https://127.0.0.1:9000'
```

```bash
ssh ubuntu@10.8.14.201 "sudo pkill -f 'ssh -L 9000:www.ubuntu.com:443 ubuntu@192.168.101.50'"
```

```bash
ssh ubuntu@10.8.14.201 'sudo apt install -y apache2'
```

```bash
ssh ubuntu@10.8.14.201 'cd /var/www/html'
```

```bash
ssh ubuntu@10.8.14.201 'sudo touch /var/www/html/test.txt'
```

```bash
ssh ubuntu@10.8.14.201 "sudo sh -c 'echo LABHOST > /var/www/html/test.txt'"
```

```bash
ssh ubuntu@10.8.14.201 "sudo sed -i 's/80/8080/' /etc/apache2/ports.conf"
```

```bash
ssh ubuntu@10.8.14.201 'sudo systemctl restart apache2'
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo apt install -y curl net-tools'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'curl -v http://localhost:8080/test.txt'"
```

```bash
ssh ubuntu@10.8.14.201 'cd ~'
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo apt install -y qemu-system libvirt-daemon-system virtinst'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo apt install -y cloud-image-utils'"
```

```bash
ssh ubuntu@10.8.14.201 'sudo virsh blockresize ubuntu vda 32G'
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo growpart /dev/vda 1 && sudo resize2fs /dev/vda1 && df -h /'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo apt install -y sshpass'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.122.51'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -J ubuntu@192.168.101.50 -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ubuntu@192.168.122.51"
```

```bash
ssh ubuntu@10.8.14.201 "tee -a ~/.ssh/config <<'EOF'
Host internalvm
  HostName 192.168.122.51
  User ubuntu
  ProxyJump ubuntu@192.168.101.50
EOF
chmod 600 ~/.ssh/config"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null internalvm"
```

```bash
ssh ubuntu@10.8.14.201 "scp -o StrictHostKeyChecking=no /home/ubuntu/cloud-init-internal.iso ubuntu@192.168.101.50:/home/ubuntu/cloud-init-internal.iso"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd /home/ubuntu && curl -L -o noble-server-cloudimg-amd64.img https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd /home/ubuntu && cp noble-server-cloudimg-amd64.img internalvm.img'"
```

```bash
ssh ubuntu@10.8.14.201 "scp -o StrictHostKeyChecking=no /home/ubuntu/user-data-internal /home/ubuntu/meta-data-internal ubuntu@192.168.101.50:/home/ubuntu/"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 \"cat > /home/ubuntu/network-config-internal <<'EOF'
version: 2
ethernets:
  enp1s0:
    addresses:
      - 192.168.122.51/24
    routes:
      - to: default
        via: 192.168.122.1
    nameservers:
      addresses:
        - 8.8.8.8
        - 1.1.1.1
EOF
cloud-localds -N /home/ubuntu/network-config-internal /home/ubuntu/cloud-init-internal.iso /home/ubuntu/user-data-internal /home/ubuntu/meta-data-internal\""
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo mkdir -p /var/lib/libvirt/images && sudo mv /home/ubuntu/internalvm.img /home/ubuntu/cloud-init-internal.iso /var/lib/libvirt/images/'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo virt-install --connect qemu:///system --name internalvm --ram 1024 --vcpus 1 --disk path=/var/lib/libvirt/images/internalvm.img,format=qcow2,bus=virtio --disk path=/var/lib/libvirt/images/cloud-init-internal.iso,device=cdrom --os-variant ubuntu24.04 --network network=default,model=virtio --graphics none --console pty,target_type=serial --import --noautoconsole'"
```

### Chapter 2: LXD

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo apt -y install zfsutils-linux'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo usermod -aG lxd ubuntu'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo snap install lxd --channel=5.21/stable'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo lxd init --auto'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc network set lxdbr0 bridge.mtu=1450'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc launch ubuntu:24.04 noble'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc list'"
```

### Chapter 5: Storage

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'lsblk'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted /dev/vdb print'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'lsblk -f /dev/vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mkfs.ext4 /dev/vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mkdir -p /mnt/data'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mount /dev/my_vg/my_lv /mnt/data'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 \"printf 'y\n' | sudo lvconvert -m +1 my_vg/my_lv\""
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo lvdisplay /dev/my_vg/my_lv'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvs'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mount /dev/vdb1 /mnt/data'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'df -h /mnt/data'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo blkid /dev/vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 \"printf '%s\n' 'UUID=bf2df01b-54de-4ca9-9ae0-c7d5f9b65f41  /mnt/data  ext4  defaults  0  2' | sudo tee -a /etc/fstab >/dev/null\""
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mount -a'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo reboot'"
```

```bash
ssh ubuntu@10.8.14.201 "until sshpass -p ubuntu ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 ubuntu@192.168.101.50 'df -h /mnt/data'; do sleep 2; done"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo umount /mnt/data'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 \"sudo sed -i '\\#UUID=bf2df01b-54de-4ca9-9ae0-c7d5f9b65f41  /mnt/data  ext4  defaults  0  2#d' /etc/fstab\""
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo rm -rf /mnt/data'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo wipefs --all /dev/vdb'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo fdisk -l /dev/vdb'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo systemctl enable fstrim.timer'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo systemctl start fstrim.timer'"
```

### Chapter 5 RAID Lab

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo apt install -y mdadm parted'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted --script /dev/vdb mklabel gpt'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted --script /dev/vdb mkpart primary ext4 1MiB 100%'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted --script /dev/vdc mklabel gpt'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted --script /dev/vdc mkpart primary ext4 1MiB 100%'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvcreate /dev/vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvcreate /dev/vdc1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvs -o +devices'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo vgcreate my_vg /dev/vdb1 /dev/vdc1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo vgs'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo lvcreate -n my_lv -L 1GB my_vg'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo lvs'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mkfs.ext4 /dev/my_vg/my_lv'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mkdir -p /mnt/data'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted --script /dev/vdc mklabel gpt'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted --script /dev/vdd mklabel gpt'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted --script /dev/vde mklabel gpt'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted --script /dev/vdf mklabel gpt'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted -a optimal /dev/vdb --script mkpart primary ext4 1MiB 100%'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted -a optimal /dev/vdc --script mkpart primary ext4 1MiB 100%'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted -a optimal /dev/vdd --script mkpart primary ext4 1MiB 100%'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted -a optimal /dev/vde --script mkpart primary ext4 1MiB 100%'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted -a optimal /dev/vdf --script mkpart primary ext4 1MiB 100%'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mdadm --create --verbose /dev/md0 --level=5 --raid-devices=5 /dev/vdb1 /dev/vdc1 /dev/vdd1 /dev/vde1 /dev/vdf1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'cat /proc/mdstat'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mdadm --detail /dev/md0'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mdadm --examine /dev/vd[b-f]1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo dmesg | grep vd'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mdadm --stop /dev/md0'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mdadm --zero-superblock /dev/vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mdadm --zero-superblock /dev/vdc1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mdadm --zero-superblock /dev/vdd1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mdadm --zero-superblock /dev/vde1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mdadm --zero-superblock /dev/vdf1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'grep ARRAY /etc/mdadm/mdadm.conf'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 \"grep '^MAILADDR' /etc/mdadm/mdadm.conf\""
```

### Chapter 5 Advanced LVM Lab

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo apt install -y lvm2'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted --script /dev/vdb mklabel gpt'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted --script /dev/vdb mkpart primary ext4 1MiB 100%'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted --script /dev/vdc mklabel gpt'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted --script /dev/vdc mkpart primary ext4 1MiB 100%'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvcreate /dev/vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvcreate /dev/vdc1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvs -o +devices'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo vgcreate my_vg /dev/vdb1 /dev/vdc1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo vgs'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo lvcreate -n my_lv -L 1GB my_vg'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo lvs'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mkfs.ext4 /dev/my_vg/my_lv'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mkdir -p /mnt/data'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo mount /dev/my_vg/my_lv /mnt/data'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 \"printf 'y\n' | sudo lvconvert -m +1 my_vg/my_lv\""
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo lvdisplay /dev/my_vg/my_lv'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvs'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvs'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo lvs -o +devices'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo lvs --segments /dev/my_vg/my_lv'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvdisplay -m'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo lsblk'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvmove -n my_lv /dev/vdb1 /dev/vdc1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo lvs -o +devices'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo vgreduce my_vg /dev/vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo lvextend -r -L +1G /dev/my_vg/my_lv'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'df -h /mnt/data/'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo lvs'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo vgs'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted --script /dev/vdd mklabel gpt'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo parted --script /dev/vdd mkpart primary ext4 1MiB 100%'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvcreate /dev/vdd1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo vgextend my_vg /dev/vdd1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo vgs'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo lvextend -r -L +1G /dev/my_vg/my_lv'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'df -h /mnt/data/'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo umount /mnt/data'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 \"printf 'y\n' | sudo lvremove /dev/my_vg/my_lv\""
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 \"printf 'y\n' | sudo vgremove my_vg\""
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvremove /dev/vdc1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvremove /dev/vdd1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvs'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvremove /dev/vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo pvs'"
```

### Chapter 5 Multipathing

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'lsblk'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo multipath -ll'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo /lib/udev/scsi_id --whitelisted --device=/dev/vda'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo apt install -y multipath-tools'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo multipath -r'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no ubuntu@192.168.101.50 'sudo multipath -ll'"
```


```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc config show --expanded noble'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc exec noble -- sudo apt-get update'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc exec noble -- sudo apt-get install -y isc-dhcp-client'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc exec noble -- dhclient eth1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc ls'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc delete noble --force'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo snap remove lxd --purge'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc list'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc exec ubuntu-vm -- cloud-init status'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc exec ubuntu-vm -- cloud-init status --wait'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc exec ubuntu-vm -- cat /proc/cpuinfo'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc exec ubuntu-vm -- free -m'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc exec ubuntu-vm -- lsblk'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc launch ubuntu:24.04 ubuntu-vm2 --vm -c limits.cpu=2 -c limits.memory=2GiB -d root,size=20GiB'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc exec ubuntu-vm2 -- cloud-init status --wait'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc exec ubuntu-vm2 -- cat /proc/cpuinfo'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc exec ubuntu-vm2 -- free -m'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc exec ubuntu-vm2 -- lsblk'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc delete ubuntu-vm --force'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc delete ubuntu-vm2 --force'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc network list'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc network info lxdbr0'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc network show lxdbr0'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'ip addr show lxdbr0'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc network create brtest0'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc network show brtest0'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc network attach-profile brtest0 default eth1'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc profile show default'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc launch ubuntu:24.04 noble'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc info ubuntu-vm'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc list'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc stop centos'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc stop noble'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc stop my-new-container-from-snapshot'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc delete centos'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc delete noble'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc delete my-new-container-from-snapshot'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc launch ubuntu:24.04 ubuntu-vm --vm'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc list'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc profile show default'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc snapshot noble my-snapshot'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc info noble'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc restore noble my-snapshot'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc copy noble/my-snapshot my-new-container-from-snapshot'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc profile assign my-new-container-from-snapshot default'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc start my-new-container-from-snapshot'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc list'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc launch images:centos/9-Stream centos'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc image list images:'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc image list local:'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc image list ubuntu:'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc image list ubuntu-daily:'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc profile list'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc image list local:'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc exec first -- apt update'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc file pull first/etc/hosts .'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc file push ./hosts first/tmp/'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc exec first -- ls -l /tmp/hosts'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc stop first'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc delete first'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc remote list'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc image list images:'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc image list'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc image alias create ubuntu d6c393290422'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc launch ubuntu first'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh -o StrictHostKeyChecking=no 192.168.101.50 'lxc list'"
```

### Chapter 6: Advanced Filesystem Concepts

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'find / -xdev -printf '\''%h\n'\'' | sort | uniq -c | sort -k 1 -n'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'df -ih'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo dd if=/dev/zero of=/dev/vdb bs=1M count=10'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo dd if=/dev/zero of=/dev/vdc bs=1M count=10'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo dd if=/dev/zero of=/dev/vdd bs=1M count=10'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo dd if=/dev/zero of=/dev/vde bs=1M count=10; sudo dd if=/dev/zero of=/dev/vdf bs=1M count=10'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo parted /dev/vdb mklabel gpt'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo parted -a optimal /dev/vdb mkpart primary ext4 1 100%'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo mkfs.ext4 /dev/vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo tune2fs -c 2 /dev/vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo tune2fs -i 2d /dev/vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo tune2fs -l /dev/vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo tune2fs -o acl /dev/vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo dumpe2fs -h /dev/vdb1 | grep Default'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo mkdir /mnt/fs'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo mount /dev/vdb1 /mnt/fs/'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'mount | grep vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo chown -R ubuntu:ubuntu /mnt/fs'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'touch /mnt/fs/file1.txt; echo \"Hello World!\" > /mnt/fs/file1.txt'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo umount /dev/vdb1'"
```

```bash
sudo fsck -V /dev/vdb1
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo mount /dev/vdb1 /mnt/fs/'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo apt install -y attr'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'setfattr -n user.comment -v \"This is a demo file.\" /mnt/fs/file1.txt'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'getfattr -d /mnt/fs/file1.txt'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'getfattr -n user.invalid /mnt/fs/file1.txt'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo apt install -y acl'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo setfacl -m u:nobody:r /mnt/fs/file1.txt'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'getfacl /mnt/fs/file1.txt'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo setfacl -x u:nobody /mnt/fs/file1.txt'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo umount /mnt/fs; sudo wipefs -a /dev/vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo parted /dev/vdb mklabel gpt; sudo parted -a optimal /dev/vdb mkpart primary ext4 1MiB 80%'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo mkfs.ext4 -L ext4data -m 1 -E lazy_itable_init=1 /dev/vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'lsblk -f /dev/vdb'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo mkdir -p /mnt/fs; sudo mount LABEL=ext4data /mnt/fs; mount | grep /mnt/fs'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'df -h /mnt/fs'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'echo "Testing ext4 advanced lab" | sudo tee /mnt/fs/info.txt'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'stat /mnt/fs/info.txt; cat /mnt/fs/info.txt; stat /mnt/fs/info.txt'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo umount /mnt/fs; sudo parted /dev/vdb resizepart 1 100%'"
```

```bash
sudo e2fsck -f /dev/vdb1
```

```bash
sudo resize2fs /dev/vdb1
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo mount LABEL=ext4data /mnt/fs; df -h /mnt/fs'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo tune2fs -l /dev/vdb1 | grep has_journal'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'mount | grep /mnt/fs'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'time dd if=/dev/zero of=/mnt/fs/testfile bs=1M count=1024 status=progress'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'time dd if=/dev/zero of=/mnt/fs/testfile-journal bs=1M count=1024 status=progress'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'stat /mnt/fs/info.txt; cat /mnt/fs/info.txt; stat /mnt/fs/info.txt'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo umount /mnt/fs; sudo wipefs -a /dev/vdb1'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'ls -l $(which at) $(which chage) $(which chsh) $(which crontab) $(which sudo) $(which ping) $(which mount)'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo find / -type f -perm /6000 -exec ls -l {} \;'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'ls -lt /usr/bin/passwd'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo chmod u-s /usr/bin/passwd'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'ls -lt /usr/bin/passwd'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo chmod u+s /usr/bin/passwd; ls -lt /usr/bin/passwd'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'touch ~/testfile; ls -l ~/testfile'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'chmod u+s ~/testfile; ls -l ~/testfile'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'chmod u+x ~/testfile; ls -l ~/testfile'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'mkdir ~/teststick'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'chmod 777 ~/teststick'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo adduser cm'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'sudo usermod -a -G ubuntu cm'"
```

```bash
su cm
```

```bash
for ((i=1;i<=3;i++)) ; do
  touch /home/ubuntu/teststick/sbUserFile${i}
done
```

```bash
rm /home/ubuntu/teststick/sbFile1
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'rm ~/teststick/sbUserFile1'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'chmod +t ~/teststick'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'rm ~/teststick/sbUserFile2'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh ubuntu@192.168.101.50 'mv ~/teststick/sbUserFile3 ~/teststick/sbUserFile4'"
```

```bash
exit
```

### Chapter 7: ZFS

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo apt install -y zfsutils-linux"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 lsblk"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'for disk in vdb vdc vdd vde vdf vdg; do sudo wipefs -a /dev/\$disk; done'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool create -f testpool mirror /dev/vdb /dev/vdc"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status testpool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool add -f testpool /dev/vdd"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool add testpool mirror /dev/vde /dev/vdf"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status testpool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool destroy testpool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool create -f zfspool raidz /dev/vdb /dev/vdc /dev/vdd"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status zfspool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs create zfspool/mystuff"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs create zfspool/myFs2"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs list"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 mount -t zfs"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 zfs mount"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo mkdir /mnt/myzfs"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs set mountpoint=legacy zfspool/mystuff"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo mount -t zfs zfspool/mystuff /mnt/myzfs"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 zfs mount"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 mount -t zfs"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs get all zfspool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs get compression zfspool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs set compression=on zfspool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs get compression zfspool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs get compressratio zfspool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo dd if=/dev/zero of=/mnt/myzfs/file1 count=1024 bs=1M"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ls -lh /mnt/myzfs/file1"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs get compressratio zfspool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs snapshot -r zfspool/mystuff@snap1"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs list -t snapshot"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo dd if=/dev/zero of=/mnt/myzfs/file2 count=1024 bs=1M"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ls -alt /mnt/myzfs/"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs rollback zfspool/mystuff@snap1"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ls -alt /mnt/myzfs/"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs snapshot -r zfspool/mystuff@snap2"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo dd if=/dev/zero of=/mnt/myzfs/file3 count=1024 bs=1M"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ls -alt /mnt/myzfs/"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo rm /mnt/myzfs/file1"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs snapshot -r zfspool/mystuff@snap3"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ls -alt /mnt/myzfs/"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs list -t snapshot"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs diff zfspool/mystuff@snap3"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs destroy zfspool/mystuff@snap2"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs destroy zfspool/mystuff@snap3"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs clone zfspool/mystuff@snap1 zfspool/mystuff/snap1clone"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs list"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs set quota=10G zfspool/mystuff"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs get quota zfspool/mystuff"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs snapshot -r zfspool/mystuff@snap2"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'sudo zfs send zfspool/mystuff@snap2 > ~/mystuff-snap.zfs'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'sudo zfs receive -F zfspool/mystuff-copy < ~/mystuff-snap.zfs'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs set copies=3 zfspool/mystuff"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs get copies zfspool/mystuff"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs set dedup=on zfspool/mystuff"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs get dedup zfspool/mystuff"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo dd if=/dev/urandom of=/zfspool/random.dat bs=1M count=20"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 md5sum /zfspool/random.dat"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool offline zfspool /dev/vdd"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool remove zfsmirror vdc"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool scrub zfspool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status -v zfspool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool replace zfspool /dev/vdd /dev/vdg -f"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status -v zfspool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs list -t filesystem"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs list -t snapshot"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs list -t volume"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs list -t all"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs destroy -r zfspool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool destroy zfspool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool create -f zfsraid5 raidz /dev/vdb /dev/vdc /dev/vdd /dev/vde"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status zfsraid5"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 zfs list"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool destroy zfsraid5"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool create -f zfsraid6 raidz2 /dev/vdb /dev/vdc /dev/vdd /dev/vde /dev/vdf"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status zfsraid6"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 zfs list"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status zfsraid6"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool destroy zfsraid6"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool create zfsraid60 raidz /dev/vdb /dev/vdc /dev/vdd -f"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool add zfsraid60 raidz /dev/vde /dev/vdf /dev/vdg"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status zfsraid60"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 zfs list"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool destroy zfsraid60"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool create zfsraid10 mirror /dev/vdb /dev/vdc mirror /dev/vdd /dev/vde -f"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status zfsraid10"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 zfs list"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo dd if=/dev/urandom of=/zfsraid10/random.dat bs=1M count=20"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo dd if=/dev/zero of=/dev/vde bs=1M count=10"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool scrub zfsraid10"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status -v zfsraid10"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool replace zfsraid10 /dev/vde /dev/vdg -f"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status -v zfsraid10"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool destroy zfsraid10"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'dd if=/dev/zero of=\"\$HOME/zfsraidpool.qcow2\" bs=1M count=2048'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'sudo zpool create zfsraidpool /home/\$USER/zfsraidpool.qcow2'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status zfsraidpool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zfs get mountpoint zfsraidpool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 zfs list"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool destroy zfsraidpool"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool create zfsmirror mirror /dev/vdd /dev/vde -f"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status zfsmirror"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool add zfsmirror cache /dev/vdc"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool add zfsmirror log /dev/vdf"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool remove zfsmirror vdc"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool status"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo zpool destroy zfsmirror"
```

### Chapter 8: Advanced Networking Concepts

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ip addr"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ip route"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo cat /etc/netplan/50-cloud-init.yaml"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo cat /var/run/systemd/network/10-netplan-enp1s0.network"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 \"printf '\n' | sudo netplan try\""
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo netplan apply"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 lsmod | grep 8021q"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link add link enp1s0 name enp1s0.42 type vlan id 42"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ip -d link show enp1s0.42"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip addr add 192.168.42.42/24 brd 192.168.42.255 dev enp1s0.42"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ip addr show dev enp1s0.42"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link set dev enp1s0.42 up"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ip addr show enp1s0.42"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 lsmod | grep 8021q"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 modinfo 8021q"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link add link enp1s0 name enp1s0.100 type vlan id 100"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link set dev enp1s0.100 up"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ip -d link show enp1s0.100"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip addr add 192.168.100.42/24 brd + dev enp1s0.100"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ip addr show dev enp1s0.100"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ip addr"
```

```bash
printf '%s\n' 'network:' '  version: 2' '  renderer: networkd' '  ethernets:' '    enp1s0:' '      addresses:' '        - "192.168.101.50/24"' '      nameservers:' '        addresses:' '          - 8.8.8.8' '          - 1.1.1.1' '      routes:' '        - to: "default"' '          via: "192.168.101.1"' '      mtu: 1450' '  vlans:' '    vlan42:' '      id: 42' '      link: enp1s0' '      addresses: [192.168.42.42/24]' '    vlan100:' '      id: 100' '      link: enp1s0' '      addresses: [192.168.100.42/24]' | ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'sudo tee /etc/netplan/50-cloud-init.yaml >/dev/null'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 \"printf '\n' | sudo netplan try\""
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo netplan apply"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'sudo lsmod | grep dummy || true'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo modprobe dummy"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'lsmod | grep dummy || true'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link add dummy0 type dummy"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link set name ens10 dev dummy0"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ip link show ens10"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link set dev ens10 address 00:22:22:ff:ff:ff"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ip link show ens10"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip addr add 192.168.100.199/24 brd + dev ens10 label ens10:0"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ip addr show ens10"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'ip a | grep -w inet'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip addr del 192.168.100.199/24 brd + dev ens10 label ens10:0"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link delete ens10 type dummy"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo rmmod dummy"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link add ens10 type dummy"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link add ens11 type dummy"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link add bond0 type bond mode active-backup miimon 100"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link set dev ens10 master bond0 state up"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link set dev ens11 master bond0 state up"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link set dev bond0 state up"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip addr add dev bond0 172.16.0.14/24"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 ip -d addr show bond0"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link del bond0"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo apt install -y bridge-utils"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo brctl addbr br0"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo brctl show"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link show"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo brctl addif br0 ens10"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo brctl addif br0 ens11"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo brctl show"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link show"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip addr add dev br0 10.255.0.4/24"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip -d addr show br0"
```

```bash
printf '%s\n' 'network:' '  version: 2' '  renderer: networkd' '  ethernets:' '    enp1s0:' '      addresses:' '      - "192.168.101.50/24"' '      nameservers:' '        addresses:' '        - 8.8.8.8' '        - 1.1.1.1' '      routes:' '      - to: "default"' '        via: "192.168.101.1"' '      mtu: 1450' '    ens10:' '      dhcp4: no' '    ens11:' '      dhcp4: no' '  vlans:' '    vlan42:' '      id: 42' '      link: enp1s0' '      addresses: [192.168.42.42/24]' '    vlan100:' '      id: 100' '      link: enp1s0' '      addresses: [192.168.100.42/24]' '  bridges:' '    br0:' '      addresses: [10.255.0.4/24]' '      interfaces: [ens10, ens11]' | ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'sudo tee /etc/netplan/01-netcfg.yaml >/dev/null'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo netplan apply"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo brctl delif br0 ens11"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo brctl delif br0 ens10"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link set dev br0 down"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo brctl delbr br0"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link del ens11"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link del ens10"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link set dev enp1s0.42 down"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link delete enp1s0.42"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link set dev enp1s0.100 down"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo ip link delete enp1s0.100"
```

```bash
printf '%s\n' 'network:' '  version: 2' '  renderer: networkd' '  ethernets:' '    enp1s0:' '      addresses:' '      - "192.168.101.50/24"' '      nameservers:' '        addresses:' '        - 8.8.8.8' '        - 1.1.1.1' '      routes:' '      - to: "default"' '        via: "192.168.101.1"' '      mtu: 1450' | ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 'sudo tee /etc/netplan/50-cloud-init.yaml >/dev/null'"
```

```bash
ssh ubuntu@10.8.14.201 "sshpass -p ubuntu ssh ubuntu@192.168.101.50 sudo netplan apply"
```

### Chapter 9: Security

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'MANPAGER=cat man pam'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'MANPAGER=cat man pam_unix'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'for i in /{bin,sbin}/* /usr/{bin,sbin}/* ; do ldd \$i 2>/dev/null | grep -q libpam ; if [ \$? == 0 ] ; then echo \$i ; fi ; done'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'ldd /bin/login | grep pam'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'ls -l /lib/*/security'"
```

```bash
sudo passwd myadmin
```

```bash
sudo pam-auth-update
```

```bash
sudo su - myadmin
```

```bash
passwd
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo apt install -y acl'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'mkdir ~/testpermissions'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'touch ~/testpermissions/coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'getfacl ~/testpermissions/'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'getfacl ~/.bashrc'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo addgroup devops'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo addgroup blue'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo addgroup green'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && setfacl -m g:devops:rwx ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && getfacl ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'setfacl -m g:green:rwx ~/testpermissions'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'setfacl -m g:blue:rwx ~/testpermissions'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'getfacl ~/testpermissions/'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && setfacl -m g:green:rwx ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && getfacl ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'setfacl -x g:green ~/testpermissions'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'getfacl ~/testpermissions'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && setfacl -m o:rwx ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && getfacl ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && setfacl -m o:--- ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && getfacl ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && getfacl ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && setfacl -m u:ubuntu:rwx ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && setfacl -m g::--- ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && getfacl ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && setfacl -m g:green:--- ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && getfacl ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && mkdir dirtwo'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && setfacl -M aclfile dirtwo'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && getfacl dirtwo'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && getfacl ../testpermissions | setfacl -b -n -M - dirtwo'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && getfacl dirtwo'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && ls -l'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && setfacl -b ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && getfacl -a dirtwo | setfacl -d -M- /home/ubuntu'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'setfacl -R -b ~/testpermissions'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'getfacl ~/testpermissions'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && setfacl -m m:r-x ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && getfacl ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd ~/testpermissions && setfacl -m u:cm:rwx ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo -u cm -H bash -lc '\''cd /home/ubuntu/testpermissions && echo "I am testing" > ./coolcode'\'''"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd /home/ubuntu/testpermissions && cat ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'cd /home/ubuntu/testpermissions && setfacl -m u:cm:--- ./coolcode'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo aa-status'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo aa-status | grep ^[0-9]'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo apt update'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo apt install apparmor-utils -y'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo aa-status'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo aa-disable /etc/apparmor.d/usr.bin.tcpdump'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo aa-status | grep tcpdump'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo aa-complain /etc/apparmor.d/usr.bin.tcpdump'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo apparmor_status'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo aa-disable /etc/apparmor.d/usr.bin.tcpdump'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'ls -la /etc/apparmor.d/disable/usr.bin.tcpdump'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo aa-enforce /etc/apparmor.d/usr.bin.tcpdump'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo aa-status'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo ufw status verbose'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'printf '\''y\n'\'' | sudo ufw enable'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo ufw allow 22/tcp'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'printf '\''y\n'\'' | sudo ufw enable'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo ufw status'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo ufw deny 80/tcp'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo ufw status numbered'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'printf '\''y\n'\'' | sudo ufw delete 4'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'printf '\''y\n'\'' | sudo ufw delete 2'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo ufw deny from 192.168.1.100'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'printf '\''y\n'\'' | sudo ufw reset'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo pro status --all'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo pro enable usg'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo pro status --all'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'which usg'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo usg audit cis_level1_workstation'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo canonical-livepatch status'"
```

```bash
sudo pro detach
```

### Chapter 10: Advanced Snap Packaging

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo apt update'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo apt install -y snapd'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'snap find firefox'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'snap info --verbose firefox'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo snap install --channel=latest/stable firefox'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'firefox --version'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'which firefox'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo snap refresh firefox --channel=latest/edge'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'firefox --version'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo snap refresh --list'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'snap connections firefox'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo snap refresh --hold firefox'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'snap list'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo snap services'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo mount -t squashfs | grep snap'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo snap refresh --unhold firefox'"
```

```bash
ssh ubuntu@10.8.14.201 "ssh -o StrictHostKeyChecking=no 192.168.101.50 'sudo snap remove firefox'"
```

### Chapter 1: Virtualization

```bash
sudo dmidecode
```

```bash
sudo dmesg
```

```bash
sudo kvm-ok
```

```bash
sudo usermod -aG kvm ubuntu
```

```bash
sudo usermod -aG libvirt ubuntu
```

```bash
exit
```
