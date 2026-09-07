#!/bin/bash

echo "Downloading the Ubuntu Noble image"
max_attempts=5
attempt=1
download_timeout=300  # 5 minutes

while [ $attempt -le $max_attempts ]; do
    echo "Download attempt $attempt of $max_attempts..."
    if sudo timeout $download_timeout wget -q --timeout 30 -O /var/lib/libvirt/vm-disks/ubuntu.img https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img; then
        # Check if file was actually downloaded
        if [ -s /var/lib/libvirt/vm-disks/ubuntu.img ]; then
            echo "Download successful!"
            break
        else
            echo "Download appeared successful but file is empty"
        fi
    else
        echo "Download attempt $attempt failed with status $?"
        if [ $attempt -eq $max_attempts ]; then
            echo "All download attempts failed. Exiting."
            exit 1
        fi
        echo "Waiting 30 seconds before retrying..."
        sleep 30
        attempt=$((attempt + 1))
    fi
done

echo "Resizing image"
sudo qemu-img resize /var/lib/libvirt/vm-disks/ubuntu.img +15G
echo "Copying cloud-init.iso"
sudo cp /home/ubuntu/cloud-init.iso /var/lib/libvirt/vm-disks/
echo "Changing ownership of new files"
sudo bash -c 'chown libvirt-qemu:kvm /var/lib/libvirt/vm-disks/*'

sudo virt-install  \
    --name ubuntu  \
    --ram 8192  \
    --vcpus 2  \
    --disk path=/var/lib/libvirt/vm-disks/ubuntu.img,format=qcow2,bus=virtio  \
    --disk path=/var/lib/libvirt/vm-disks/cloud-init.iso,device=cdrom  \
    --os-variant ubuntu24.04  \
    --network bridge=nat-virbr2,model=virtio  \
    --graphics none  \
    --console pty,target_type=serial  \
    --import  \
    --noautoconsole