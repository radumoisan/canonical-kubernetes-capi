# Virtualization

This chapter prepares the lab environment used in the rest of the course. Complete it before moving on.

In this chapter you will:

- set up a QEMU and KVM lab VM
- install Ubuntu in the guest
- add storage and networking resources to the VM
- use `uvtool` to create a VM from a cloud image

## :material-book-open-page-variant-outline: 1.1 What Is Virtualization?

Virtualization lets one physical machine run multiple isolated guest systems. Each guest behaves like its own computer, with its own operating system, processes, and storage, while sharing the host's hardware resources.

Virtualization is different from emulation. Emulation recreates hardware in software and is usually slower. Virtualization uses hardware support from the CPU and kernel to run guests more efficiently.

On Ubuntu, the virtualization stack commonly includes QEMU, KVM, and libvirt.

You can use several commands to check whether a system is virtualized.

```bash
# Read SMBIOS and DMI data in a human-readable format.
sudo dmidecode
```
??? quote "Reference output"
    ```text
    # dmidecode 3.5
    Getting SMBIOS data from sysfs.
    SMBIOS 2.8 present.

    Handle 0x0000, DMI type 0, 24 bytes
    BIOS Information
        Vendor: SeaBIOS
        Version: rel-1.16.2-0-gea1b7a073390-prebuilt.qemu.org
    ```

```bash
# Check kernel messages that may expose virtualization during boot.
sudo dmesg
```
??? quote "Reference output"
    ```text
    [    0.000000] Hypervisor detected: KVM
    [    0.058704] Booting paravirtualized kernel on KVM
    [    2.430778] systemd[1]: Detected virtualization kvm.
    ```

```bash
# Detect the virtualization platform with a script-friendly systemd tool.
sudo systemd-detect-virt
```
??? quote "Reference output"
    ```text
    kvm
    ```

```bash
# Identify the active virtualization platform with virt-what.
sudo virt-what
```
??? quote "Reference output"
    ```text
    kvm
    ```

!!! pied-piper "Takeaway"
    The main idea to remember is:

    - one host can run multiple isolated guests
    - KVM uses hardware acceleration
    - this is different from slower software-only emulation

## :material-book-open-page-variant-outline: 1.2 KVM Virtualization Stack

KVM provides hardware-assisted virtualization in the Linux kernel. QEMU runs in userspace and provides the virtual hardware model that the guest sees. Used together, they let a guest run with near-native performance when the host supports virtualization extensions.

Libvirt provides a consistent management API and toolset. It manages guests, networks, storage pools, and device definitions on top of QEMU and KVM.

**QEMU and KVM**

QEMU can fully emulate a machine, but software emulation is slower. With KVM available, QEMU can execute guest code directly on the host CPU and use hardware acceleration.

When used together:

- KVM handles CPU, memory, and hardware-assisted execution
- QEMU emulates devices that the guest sees
- libvirt manages guests, networks, storage pools, and device definitions

**KVM**

KVM is a kernel-based hypervisor that depends on CPU virtualization extensions. Ubuntu commonly uses it as the execution layer for virtual machines.

Common front ends are `virsh` for CLI management and `virt-manager` for GUI management. LXD can also manage VMs in newer environments.

**QEMU**

QEMU is the userspace component in the stack. It can run with KVM for hardware-assisted virtualization or fall back to software emulation through TCG when KVM is unavailable.

It also supports multiple CPU and hardware targets, which is why parts of QEMU are used across many virtualization solutions.

**qemu-img**

`qemu-img` creates, inspects, resizes, and converts disk images such as `raw` and `qcow2`.

```bash
# Inspect a disk image.
qemu-img info <image-file>
```
??? quote "Reference output"
    ```text
    image: <image-file>
    file format: qcow2
    virtual size: 10 GiB (10737418240 bytes)
    disk size: 200 KiB
    cluster_size: 65536
    ```

**libvirt**

Libvirt provides a common API and toolset for virtualization management. In libvirt terminology, a VM is called a domain.

Before using libvirt with KVM, confirm that the host has the required virtualization features.

```bash
# Install the KVM capability checker.
sudo apt install -y cpu-checker
```
??? quote "Reference output"
    ```text
    cpu-checker is already the newest version (0.7-1.3build2).
    0 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
    ```

```bash
# Check whether KVM acceleration is available.
sudo kvm-ok
```
??? quote "Reference output"
    ```text
    INFO: /dev/kvm exists
    KVM acceleration can be used
    ```

You can also validate the host configuration more broadly with `virt-host-validate`.

```bash
# Validate the host for libvirt and QEMU use.
sudo virt-host-validate
```
??? quote "Reference output"
    ```text
    QEMU: Checking for hardware virtualization                                 : PASS
    QEMU: Checking if device /dev/kvm exists                                   : PASS
    QEMU: Checking if device /dev/kvm is accessible                            : PASS
    QEMU: Checking if IOMMU is enabled                                         : WARN
    ```

Libvirt includes `virsh`, which manages domains, networks, storage pools, and devices. These resources are defined in XML and can be exported, edited, or imported.

!!! warning
    This lab expects the system libvirt connection. If `virsh uri` returns `qemu:///session` on your host, set `export LIBVIRT_DEFAULT_URI=qemu:///system` once before continuing. If you want that behavior to persist for future sessions, set `uri_default = "qemu:///system"` in `~/.config/libvirt/libvirt.conf`.

```bash
# Use the system libvirt connection for the rest of the lab.
export LIBVIRT_DEFAULT_URI=qemu:///system
```

!!! pied-piper "Takeaway"
    Remember the stack this way:

    - KVM runs the guest efficiently
    - QEMU provides the virtual hardware
    - libvirt with `virsh` manages the whole environment

## :material-book-open-page-variant-outline: 1.3 Virtualization Lab

In this lab you will build `LABVM` on `LABHOST` using libvirt and `virsh`.

- `LABHOST`: the host machine assigned to the student
- `LABVM`: the guest VM created during the lab

### :material-application-edit-outline: 1.3.1 Install A Guest VM

Start on `LABHOST`.

!!! info
    This exercise prepares `LABHOST` to manage KVM guests with libvirt. Success means `kvm-ok` reports acceleration is available, the `ubuntu` user is added to the `kvm` and `libvirt` groups, and `virsh list --all` shows no domains yet.

Step 1: Update the host first.

```bash
# Refresh package metadata and upgrade installed packages.
sudo apt update -y && sudo apt dist-upgrade -y
```
??? example "Expected result"
    ```text
    69 packages can be upgraded. Run 'apt list --upgradable' to see them.
    ...
    69 upgraded, 0 newly installed, 0 to remove and 0 not upgraded.
    ...
    Running kernel version is 6.8.0-107-generic and it is up to date.
    No services need to be restarted.
    ```

Step 2: Reboot the host.

```bash
# Reboot the host after package upgrades.
sudo reboot
```
??? example "Expected result"
    ```text
    Connection to 10.8.14.201 closed by remote host.
    Connection to 10.8.14.201 closed.
    ```

After `LABHOST` finishes rebooting, log back in and continue with Step 3.

Step 3: Install the required virtualization packages.

```bash
# Install the QEMU, KVM, and libvirt toolchain.
sudo apt-get install -y qemu-system qemu-kvm libvirt-daemon libvirt-clients bridge-utils \
  libvirt-daemon-system qemu-utils cpu-checker virt-viewer virt-manager virtinst
```
??? example "Expected result"
    ```text
    0 upgraded, 257 newly installed, 0 to remove and 0 not upgraded.
    ...
    Setting up qemu-system-x86 ...
    Setting up libvirt-daemon-system ...
    Setting up libvirt-clients ...
    Setting up virtinst ...
    Setting up virt-manager ...
    ```

Step 4: Verify that the host supports hardware virtualization.

```bash
# Confirm KVM acceleration is available.
sudo kvm-ok
```
??? example "Expected result"
    ```text
    INFO: /dev/kvm exists
    KVM acceleration can be used
    ```

Step 5: Add the `ubuntu` user to the KVM-related groups.

```bash
# Add the ubuntu user to the kvm group.
sudo usermod -aG kvm ubuntu
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Add the ubuntu user to the libvirt group.
sudo usermod -aG libvirt ubuntu
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 6: End the current session.

```bash
# End the current shell so group changes can take effect after re-login.
exit
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 7: Log back in to `LABHOST`.

```bash
# Open a new SSH session to the lab host.
ssh ubuntu@<public IP>
```
??? example "Expected result"
    ```text
    Welcome to Ubuntu 24.04 LTS (GNU/Linux 6.8.0-107-generic x86_64)
    ubuntu@playground-rdu:~$
    ```

Step 8: Confirm that no virtual machines exist yet.

!!! note
    To make the rest of the lab easier to follow, set a custom shell prompt on `LABHOST` before you continue.

```bash
# Append a LABHOST prompt to ~/.bashrc.
printf '%s\n' 'PS1="\[\e[1;32m\]\u@LABHOST\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\\$ "' >> ~/.bashrc
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Reload ~/.bashrc in the current shell.
source ~/.bashrc
```
??? example "Expected result"
    ```text
    ubuntu@LABHOST:~$
    ```

```bash
# List all libvirt domains.
virsh list --all
```
??? example "Expected result"
    ```text
     Id   Name   State
    --------------------
    ```

An empty list is expected here because you have not created `LABVM` yet.

### :material-application-edit-outline: 1.3.2 Set Up Storage Pools

Libvirt supports several storage back ends, including directory pools, filesystems, LVM, iSCSI, ZFS, RBD, and more. In this lab you will use a simple directory pool.

!!! info
    This exercise creates the directory-backed storage pool used for VM disks. Success means `vm-disks` is `active`, `Autostart` is `yes`, and `virsh pool-info vm-disks` shows the pool details.

Step 1: Create the directory that will hold VM disk images.

```bash
# Create the directory-backed libvirt storage path.
sudo mkdir -p /var/lib/libvirt/vm-disks
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 2: Define a storage pool that points to that directory.

```bash
# Define a new libvirt directory storage pool.
virsh pool-define-as --name vm-disks --type dir --target /var/lib/libvirt/vm-disks
```
??? example "Expected result"
    ```text
    Pool vm-disks defined
    ```

Step 3: Check the pool state.

```bash
# List all storage pools.
virsh pool-list --all
```
??? example "Expected result"
    ```text
     Name       State      Autostart
    ----------------------------------
     vm-disks   inactive   no
    ```

Step 4: Start the pool.

```bash
# Start the storage pool.
virsh pool-start vm-disks
```
??? example "Expected result"
    ```text
    Pool vm-disks started
    ```

Step 5: Enable pool autostart.

```bash
# Enable storage pool autostart.
virsh pool-autostart vm-disks
```
??? example "Expected result"
    ```text
    Pool vm-disks marked as autostarted
    ```

Step 6: Verify the pool again.

```bash
# Recheck the storage pool state.
virsh pool-list --all
```
??? example "Expected result"
    ```text
     Name       State    Autostart
    --------------------------------
     vm-disks   active   yes
    ```

Step 7: Review the pool details.

```bash
# Show detailed information for the storage pool.
virsh pool-info vm-disks
```
??? example "Expected result"
    ```text
    Name:           vm-disks
    UUID:           cf41cccc-3ce1-4e5f-a0e1-31d06a0ca977
    State:          running
    Persistent:     yes
    Autostart:      yes
    Capacity:       97,87 GiB
    Allocation:     8,40 GiB
    Available:      89,47 GiB
    ```

### :material-application-edit-outline: 1.3.3 Volume Operations

With the storage pool in place, you can create and manage volumes.

!!! info
    This exercise shows how libvirt tracks virtual capacity separately from allocated disk usage. Success means `sample-vol` exists in the pool and later reports a resized capacity of `10 GiB`.

Step 1: Create a `qcow2` volume.

```bash
# Create a sparse qcow2 volume in the pool.
virsh vol-create-as vm-disks sample-vol 6G --format qcow2
```
??? example "Expected result"
    ```text
    Vol sample-vol created
    ```

By default, libvirt creates sparse files, so the allocated size on disk is much smaller than the virtual capacity.

Step 2: List the volumes in the pool.

```bash
# List volumes and their allocation details.
virsh vol-list --details vm-disks
```
??? example "Expected result"
    ```text
     Name         Path                                   Type   Capacity   Allocation
    -----------------------------------------------------------------------------------
     sample-vol   /var/lib/libvirt/vm-disks/sample-vol   file   6,00 GiB   196,00 KiB
    ```

Step 3: Inspect the new volume.

```bash
# Show details for one storage volume.
virsh vol-info sample-vol vm-disks
```
??? example "Expected result"
    ```text
    Name:           sample-vol
    Type:           file
    Capacity:       6,00 GiB
    Allocation:     196,00 KiB
    ```

Step 4: Resize the volume.

```bash
# Increase the virtual size of the volume.
virsh vol-resize sample-vol --pool vm-disks --capacity 10G
```
??? example "Expected result"
    ```text
    Size of volume 'sample-vol' successfully changed to 10G
    ```

Step 5: Confirm the new size.

```bash
# Verify the resized volume details.
virsh vol-info sample-vol vm-disks
```
??? example "Expected result"
    ```text
    Name:           sample-vol
    Type:           file
    Capacity:       10,00 GiB
    Allocation:     200,00 KiB
    ```

### :material-application-edit-outline: 1.3.4 Clone Volumes

You can clone a volume directly or use copy-on-write backing files.

!!! info
    This exercise compares a full clone with a copy-on-write clone. Success means `cloned-vol` appears as an independent image and `qemu-img info --backing-chain` shows `cow-clone` using `sample-vol` as its backing file.

Step 1: Create a full clone.

```bash
# Clone the existing volume into a new file.
virsh vol-clone sample-vol cloned-vol vm-disks
```
??? example "Expected result"
    ```text
    Vol cloned-vol cloned from sample-vol
    ```

Step 2: Verify both volumes.

```bash
# List the pool volumes after cloning.
virsh vol-list --details vm-disks
```
??? example "Expected result"
    ```text
     Name         Path                                   Type   Capacity    Allocation
    ------------------------------------------------------------------------------------
     cloned-vol   /var/lib/libvirt/vm-disks/cloned-vol   file   10,00 GiB   196,00 KiB
     sample-vol   /var/lib/libvirt/vm-disks/sample-vol   file   10,00 GiB   200,00 KiB
    ```

Step 3: Create a copy-on-write clone using the original as a backing file.

```bash
# Create a qcow2 copy-on-write image backed by sample-vol.
sudo qemu-img create -f qcow2 -b /var/lib/libvirt/vm-disks/sample-vol \
  -F qcow2 /var/lib/libvirt/vm-disks/cow-clone
```
??? example "Expected result"
    ```text
    Formatting '/var/lib/libvirt/vm-disks/cow-clone', fmt=qcow2 cluster_size=65536 extended_l2=off compression_type=zlib size=10737418240 backing_file=/var/lib/libvirt/vm-disks/sample-vol backing_fmt=qcow2 lazy_refcounts=off refcount_bits=16
    ```

Step 4: Inspect the backing chain.

```bash
# Inspect the qcow2 backing file chain.
sudo qemu-img info --backing-chain /var/lib/libvirt/vm-disks/cow-clone
```
??? example "Expected result"
    ```text
    image: /var/lib/libvirt/vm-disks/cow-clone
    file format: qcow2
    virtual size: 10 GiB (10737418240 bytes)
    disk size: 196 KiB
    backing file: /var/lib/libvirt/vm-disks/sample-vol
    backing file format: qcow2
    ...
    image: /var/lib/libvirt/vm-disks/sample-vol
    file format: qcow2
    virtual size: 10 GiB (10737418240 bytes)
    disk size: 200 KiB
    ```

!!! warning
    Do not attach the backing file itself to a VM in this scenario. Changing or booting the base image can corrupt all dependent copy-on-write images.

Step 5: Refresh the pool metadata.

```bash
# Refresh the pool after creating a disk outside virsh.
virsh pool-refresh vm-disks
```
??? example "Expected result"
    ```text
    Pool vm-disks refreshed
    ```

Step 6: Verify that the new image is visible to libvirt.

```bash
# List pool volumes after the refresh.
virsh vol-list --details vm-disks
```
??? example "Expected result"
    ```text
     Name         Path                                   Type   Capacity    Allocation
    ------------------------------------------------------------------------------------
     cloned-vol   /var/lib/libvirt/vm-disks/cloned-vol   file   10,00 GiB   196,00 KiB
     cow-clone    /var/lib/libvirt/vm-disks/cow-clone    file   10,00 GiB   196,00 KiB
     sample-vol   /var/lib/libvirt/vm-disks/sample-vol   file   10,00 GiB   200,00 KiB
    ```

`virsh pool-refresh` is what makes the externally created `cow-clone` visible to libvirt.

!!! pied-piper "Takeaway"
    Remember the difference:

    - a full clone is independent
    - a qcow2 copy-on-write clone saves space
    - a copy-on-write clone depends on its backing file staying unchanged

### :material-application-edit-outline: 1.3.5 Libvirt Networks

Inspect the default libvirt network before creating a new one.

!!! info
    This exercise identifies the default libvirt NAT network that already exists on `LABHOST`. Success means you can connect the `default` network to the `virbr0` bridge and recognize the bridge address `192.168.122.1/24`.

Step 1: List the active networks.

```bash
# List currently defined libvirt networks.
virsh net-list
```
??? example "Expected result"
    ```text
     Name      State    Autostart   Persistent
    --------------------------------------------
     default   active   yes         yes
    ```

Step 2: Inspect the default network.

```bash
# Show details for the default network.
virsh net-info default
```
??? example "Expected result"
    ```text
    Name:           default
    UUID:           d2d78103-e29b-47cf-95be-e0e0d947e791
    Active:         yes
    Persistent:     yes
    Autostart:      yes
    Bridge:         virbr0
    ```

Step 3: Dump the network XML.

```bash
# Show the XML definition for the default network.
virsh net-dumpxml default
```
??? example "Expected result"
    ```xml
    <network>
      <name>default</name>
      <uuid>d2d78103-e29b-47cf-95be-e0e0d947e791</uuid>
      <forward mode='nat'>
        <nat>
          <port start='1024' end='65535'/>
        </nat>
      </forward>
      <bridge name='virbr0' stp='on' delay='0'/>
      <ip address='192.168.122.1' netmask='255.255.255.0'>
        <dhcp>
          <range start='192.168.122.2' end='192.168.122.254'/>
        </dhcp>
      </ip>
    </network>
    ```

Step 4: Inspect the bridge interface.

```bash
# Inspect the bridge backing the default libvirt network.
ip addr show virbr0
```
??? example "Expected result"
    ```text
    3: virbr0: <NO-CARRIER,BROADCAST,MULTICAST,UP> mtu 1500 qdisc noqueue state DOWN group default qlen 1000
        link/ether 52:54:00:e1:87:2e brd ff:ff:ff:ff:ff:ff
        inet 192.168.122.1/24 brd 192.168.122.255 scope global virbr0
           valid_lft forever preferred_lft forever
    ```

`virbr0` can still show `NO-CARRIER` or `state DOWN` when no guest is attached. The main check here is that the bridge exists and holds the expected `192.168.122.1/24` address.

### :material-application-edit-outline: 1.3.6 Define An Additional Libvirt Network

To define a custom NAT network, start with an XML definition.

!!! info
    This exercise creates the custom `nat-kvm-network` network used later by `LABVM`. Success means libvirt starts the network, marks it for autostart, and creates `nat-virbr2` with address `192.168.101.1/24`.

Step 1: Inspect the network XML file.

```bash
# Review the custom libvirt network definition.
cat ~/nat-kvm-network.xml
```
??? example "Expected result"
    ```xml
    <network>
        <name>nat-kvm-network</name>
        <forward mode='nat'>
            <nat>
                <port start='1024' end='65535'/>
            </nat>
        </forward>
        <bridge name='nat-virbr2'/>
        <ip address='192.168.101.1' netmask='255.255.255.0'>
        <dhcp>
            <range start='192.168.101.100' end='192.168.101.254'/>
        </dhcp>
        </ip>
    </network>
    ```

Step 2: Define the network.

```bash
# Define the custom NAT network in libvirt.
virsh net-define ~/nat-kvm-network.xml
```
??? example "Expected result"
    ```text
    Network nat-kvm-network defined from /home/ubuntu/nat-kvm-network.xml
    ```

Step 3: Start the network.

```bash
# Start the custom libvirt network.
virsh net-start nat-kvm-network
```
??? example "Expected result"
    ```text
    Network nat-kvm-network started
    ```

Step 4: Enable autostart.

```bash
# Enable network autostart.
virsh net-autostart nat-kvm-network
```
??? example "Expected result"
    ```text
    Network nat-kvm-network marked as autostarted
    ```

Step 5: Verify the bridge address.

```bash
# Check the bridge address created for the new libvirt network.
ip addr sh nat-virbr2 | grep inet
```
??? example "Expected result"
    ```text
        inet 192.168.101.1/24 brd 192.168.101.255 scope global nat-virbr2
    ```

!!! pied-piper "Takeaway"
    In libvirt, a network is a managed resource:

    - you define it in XML
    - libvirt creates the bridge
    - libvirt applies the network behavior from that definition

### :material-application-edit-outline: 1.3.7 Create The First VM

In this section, `virt-install` creates an Ubuntu 24.04 VM from a Canonical cloud image and connects it to the `nat-kvm-network` network.

The lab provides a helper script named `create_vm.sh`. Review it first.

!!! info
    This exercise builds `LABVM` from a prepared cloud image and cloud-init ISO. Success means the `ubuntu` domain appears in libvirt and its definition shows the expected disk, CD-ROM, and network attachments.

Step 1: Inspect the VM creation script.

```bash
# Review the helper script that builds the VM.
cat create_vm.sh
```
??? example "Expected result"
    ```bash
    #!/bin/bash
    
    echo "Downloading the Ubuntu Noble image"
    max_attempts=5
    attempt=1
    download_timeout=300  # 5 minutes
    
    while [ $attempt -le $max_attempts ]; do
        echo "Download attempt $attempt of $max_attempts..."
        if sudo timeout $download_timeout wget -q --timeout 30 -O /var/lib/libvirt/vm-disks/ubuntu.img https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img; then
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
    
    sudo virt-install \
        --name ubuntu \
        --ram 8192 \
        --vcpus 2 \
        --disk path=/var/lib/libvirt/vm-disks/ubuntu.img,format=qcow2,bus=virtio \
        --disk path=/var/lib/libvirt/vm-disks/cloud-init.iso,device=cdrom \
        --os-variant ubuntu24.04 \
        --network bridge=nat-virbr2,model=virtio \
        --graphics none \
        --console pty,target_type=serial \
        --import \
        --noautoconsole
    ```

The `cloud-init.iso` image provides initial configuration for the guest through `user-data`, `meta-data`, and `network-config`.

Step 2: Inspect `user-data`.

```bash
# Review the cloud-init user-data file.
cat user-data
```
??? example "Expected result"
    ```yaml
    #cloud-config
    hostname: ubuntu

    users:
      - name: ubuntu
        sudo: ALL=(ALL) NOPASSWD:ALL
        groups: sudo
        shell: /bin/bash
        lock-passwd: false
    chpasswd:
      list: |
        ubuntu:ubuntu
      expire: false
    package_update: true
    package_upgrade: true
    package_reboot_if_required: true
    packages:
      - vim
      - jq
      - qemu-utils
      - python3-swiftclient
      - libvirt-clients
      - git
      - openssh-server
      - sudo

    growpart:
      mode: auto
      devices: ['/']
      ignore_growroot_disabled: false

    resize_rootfs: true

    ssh_pwauth: true

    write_files:
      - path: /etc/ssh/sshd_config.d/99-cloud-init.conf
        content: |
          PasswordAuthentication yes
          ChallengeResponseAuthentication no
          UsePAM yes
        append: true

    runcmd:
      - systemctl restart ssh
    ```

Step 3: Inspect `meta-data`.

```bash
# Review the cloud-init meta-data file.
cat meta-data
```
??? example "Expected result"
    ```yaml
    instance-id: ubuntu-vm
    local-hostname: ubuntu
    ```

Step 4: Inspect `network-config`.

```bash
# Review the cloud-init network configuration.
cat network-config
```
??? example "Expected result"
    ```yaml
    version: 2
    ethernets:
      enp1s0:
        addresses:
          - 192.168.101.50/24
        nameservers:
          addresses:
            - 8.8.8.8
            - 1.1.1.1
        routes:
          - to: default
            via: 192.168.101.1
        renderer: networkd
        mtu: 1450
    ```

Step 5: Make the script executable.

```bash
# Make the helper script executable.
chmod +x ~/create_vm.sh
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 6: Run the script.

```bash
# Create the Ubuntu VM from the cloud image.
~/create_vm.sh
```
??? example "Expected result"
    ```text
    Downloading the Ubuntu Noble image
    Download attempt 1 of 5...
    Download successful!
    Resizing image
    Image resized.
    Copying cloud-init.iso
    Changing ownership of new files

    Starting install...
    Creating domain...
    Domain creation completed.
    ```

This step can take several minutes. The important success signal is `Domain creation completed.`

Step 7: List the defined VMs.

```bash
# List all domains after VM creation.
virsh list --all
```
??? example "Expected result"
    ```text
     Id   Name     State
    ------------------------
     1    ubuntu   running
    ```

What matters most is that the `ubuntu` domain now exists. During the first boot, its state can change briefly while cloud-init finishes guest setup.

Step 8: Review the VM definition.

```bash
# Inspect the VM XML definition.
virsh dumpxml ubuntu | less
```
??? example "Expected result"
    ```xml
    <domain type='kvm' id='1'>
      <name>ubuntu</name>
      <memory unit='KiB'>8388608</memory>
      <vcpu placement='static'>2</vcpu>
      ...
      <disk type='file' device='disk'>
        <source file='/var/lib/libvirt/vm-disks/ubuntu.img' index='2'/>
        <target dev='vda' bus='virtio'/>
      </disk>
      <disk type='file' device='cdrom'>
        <source file='/var/lib/libvirt/vm-disks/cloud-init.iso' index='1'/>
        <target dev='sda' bus='sata'/>
      </disk>
      ...
    </domain>
    ```

### :material-application-edit-outline: 1.3.8 Access The VM

After cloud-init finishes, the VM should have the `ubuntu` user and the configured static address.

!!! info
    Run Steps 1 through 4 on `LABHOST`. Step 5 switches you into `LABVM`.
    Log in to `LABVM` with username `ubuntu` and password `ubuntu`.
    Success means the VM is set to autostart, responds to ping, and accepts an SSH login.

Step 1: Enable autostart for the VM.

```bash
# Configure the VM to start automatically with the host.
virsh autostart ubuntu
```
??? example "Expected result"
    ```text
    Domain 'ubuntu' marked as autostarted
    ```

Step 2: Confirm that the VM is running.

```bash
# List running domains.
virsh list
```
??? example "Expected result"
    ```text
     Id   Name     State
    ------------------------
     1    ubuntu   running
    ```

Step 3: Open the serial console if needed.

```bash
# Connect to the VM serial console.
virsh console ubuntu
```
??? example "Expected result"
    ```text
    Connected to domain 'ubuntu'
    Escape character is ^] (Ctrl + ])

    ubuntu login:
    ```

If you open the console, leave it with `Ctrl + ]` before running the next command on `LABHOST`.

Step 4: Test network reachability.

```bash
# Verify that the guest responds on the lab network.
ping -c5 192.168.101.50
```
??? example "Expected result"
    ```text
    PING 192.168.101.50 (192.168.101.50) 56(84) bytes of data.
    64 bytes from 192.168.101.50: icmp_seq=1 ttl=64 time=0.442 ms
    64 bytes from 192.168.101.50: icmp_seq=2 ttl=64 time=0.334 ms
    64 bytes from 192.168.101.50: icmp_seq=3 ttl=64 time=0.431 ms
    64 bytes from 192.168.101.50: icmp_seq=4 ttl=64 time=0.456 ms
    64 bytes from 192.168.101.50: icmp_seq=5 ttl=64 time=0.309 ms

    --- 192.168.101.50 ping statistics ---
    5 packets transmitted, 5 received, 0% packet loss, time 4093ms
    rtt min/avg/max/mdev = 0.309/0.394/0.456/0.060 ms
    ```

Step 5: Log in to the guest.

```bash
# SSH into the guest VM.
ssh 192.168.101.50
```
??? example "Expected result"
    ```text
    ubuntu@192.168.101.50's password:
    Welcome to Ubuntu 24.04 LTS (GNU/Linux 6.8.0-*-generic x86_64)
    ubuntu@ubuntu:~$
    ```

!!! pied-piper "Takeaway"
    After first boot, check both sides:

    - `cloud-init` handles the guest's initial setup
    - `virsh` confirms the VM exists and is running
    - ping, SSH, and the console confirm the guest is actually reachable

### :material-application-edit-outline: 1.3.9 Attach Extra Disks To The VM

In this exercise, create several raw disks on `LABHOST` and attach them to `LABVM`.

!!! info
    This exercise adds six extra disks that later storage labs will use. Success means `LABVM` shows new devices `vdb` through `vdg` in both `/dev` and `lsblk`.

Step 1: Return to the host.

```bash
# Exit the guest shell and return to LABHOST.
exit
```
??? example "Expected result"
    ```text
    logout
    Connection to 192.168.101.50 closed.
    ```

Step 2: Create the raw disks.

```bash
# Create the first raw disk image.
sudo qemu-img create -f raw /var/lib/libvirt/vm-disks/test-vmdiskb.raw 10G
```
??? example "Expected result"
    ```text
    Formatting '/var/lib/libvirt/vm-disks/test-vmdiskb.raw', fmt=raw size=10737418240
    ```

```bash
# Create the second raw disk image.
sudo qemu-img create -f raw /var/lib/libvirt/vm-disks/test-vmdiskc.raw 10G
```
??? example "Expected result"
    ```text
    Formatting '/var/lib/libvirt/vm-disks/test-vmdiskc.raw', fmt=raw size=10737418240
    ```

```bash
# Create the third raw disk image.
sudo qemu-img create -f raw /var/lib/libvirt/vm-disks/test-vmdiskd.raw 10G
```
??? example "Expected result"
    ```text
    Formatting '/var/lib/libvirt/vm-disks/test-vmdiskd.raw', fmt=raw size=10737418240
    ```

```bash
# Create the fourth raw disk image.
sudo qemu-img create -f raw /var/lib/libvirt/vm-disks/test-vmdiske.raw 10G
```
??? example "Expected result"
    ```text
    Formatting '/var/lib/libvirt/vm-disks/test-vmdiske.raw', fmt=raw size=10737418240
    ```

```bash
# Create the fifth raw disk image.
sudo qemu-img create -f raw /var/lib/libvirt/vm-disks/test-vmdiskf.raw 10G
```
??? example "Expected result"
    ```text
    Formatting '/var/lib/libvirt/vm-disks/test-vmdiskf.raw', fmt=raw size=10737418240
    ```

```bash
# Create the sixth raw disk image.
sudo qemu-img create -f raw /var/lib/libvirt/vm-disks/test-vmdiskg.raw 10G
```
??? example "Expected result"
    ```text
    Formatting '/var/lib/libvirt/vm-disks/test-vmdiskg.raw', fmt=raw size=10737418240
    ```

Step 3: Refresh the pool and review the new volumes.

```bash
# Refresh the storage pool.
virsh pool-refresh vm-disks
```
??? example "Expected result"
    ```text
    Pool vm-disks refreshed
    ```

```bash
# List the pool volumes after the refresh.
virsh vol-list --details vm-disks
```
??? example "Expected result"
    ```text
     Name               Path                                         Type   Capacity     Allocation
    -------------------------------------------------------------------------------------------------
     cloned-vol         /var/lib/libvirt/vm-disks/cloned-vol         file   10,00 GiB    196,00 KiB
     cloud-init.iso     /var/lib/libvirt/vm-disks/cloud-init.iso     file   368,00 KiB   368,00 KiB
     cow-clone          /var/lib/libvirt/vm-disks/cow-clone          file   10,00 GiB    196,00 KiB
     sample-vol         /var/lib/libvirt/vm-disks/sample-vol         file   10,00 GiB    200,00 KiB
     test-vmdiskb.raw   /var/lib/libvirt/vm-disks/test-vmdiskb.raw   file   10,00 GiB    4,00 KiB
     test-vmdiskc.raw   /var/lib/libvirt/vm-disks/test-vmdiskc.raw   file   10,00 GiB    4,00 KiB
     test-vmdiskd.raw   /var/lib/libvirt/vm-disks/test-vmdiskd.raw   file   10,00 GiB    4,00 KiB
     test-vmdiske.raw   /var/lib/libvirt/vm-disks/test-vmdiske.raw   file   10,00 GiB    4,00 KiB
     test-vmdiskf.raw   /var/lib/libvirt/vm-disks/test-vmdiskf.raw   file   10,00 GiB    4,00 KiB
     test-vmdiskg.raw   /var/lib/libvirt/vm-disks/test-vmdiskg.raw   file   10,00 GiB    4,00 KiB
     ubuntu.img         /var/lib/libvirt/vm-disks/ubuntu.img         file   18,50 GiB    1,85 GiB
    ```

Step 4: Attach the disks to the running VM.

```bash
# Attach the first raw disk to the guest.
virsh attach-disk ubuntu /var/lib/libvirt/vm-disks/test-vmdiskb.raw vdb --live --config
```
??? example "Expected result"
    ```text
    Disk attached successfully
    ```

```bash
# Attach the second raw disk to the guest.
virsh attach-disk ubuntu /var/lib/libvirt/vm-disks/test-vmdiskc.raw vdc --live --config
```
??? example "Expected result"
    ```text
    Disk attached successfully
    ```

```bash
# Attach the third raw disk to the guest.
virsh attach-disk ubuntu /var/lib/libvirt/vm-disks/test-vmdiskd.raw vdd --live --config
```
??? example "Expected result"
    ```text
    Disk attached successfully
    ```

```bash
# Attach the fourth raw disk to the guest.
virsh attach-disk ubuntu /var/lib/libvirt/vm-disks/test-vmdiske.raw vde --live --config
```
??? example "Expected result"
    ```text
    Disk attached successfully
    ```

```bash
# Attach the fifth raw disk to the guest.
virsh attach-disk ubuntu /var/lib/libvirt/vm-disks/test-vmdiskf.raw vdf --live --config
```
??? example "Expected result"
    ```text
    Disk attached successfully
    ```

```bash
# Attach the sixth raw disk to the guest.
virsh attach-disk ubuntu /var/lib/libvirt/vm-disks/test-vmdiskg.raw vdg --live --config
```
??? example "Expected result"
    ```text
    Disk attached successfully
    ```

After the attach commands succeed, wait a few seconds before reconnecting if the guest does not show the new devices immediately.

Step 5: Reconnect to the guest.

```bash
# Reconnect to the guest after attaching the disks.
ssh 192.168.101.50
```
??? example "Expected result"
    ```text
    ubuntu@192.168.101.50's password:
    Welcome to Ubuntu 24.04 LTS (GNU/Linux 6.8.0-*-generic x86_64)
    ubuntu@ubuntu:~$
    ```

Step 6: Confirm that the new devices exist.

```bash
# List virtio block devices in the guest.
sudo ls -al /dev/vd*
```
??? example "Expected result"
    ```text
    brw-rw---- 1 root disk 252,  0 ... /dev/vda
    brw-rw---- 1 root disk 252, 16 ... /dev/vdb
    brw-rw---- 1 root disk 252, 32 ... /dev/vdc
    brw-rw---- 1 root disk 252, 48 ... /dev/vdd
    brw-rw---- 1 root disk 252, 64 ... /dev/vde
    brw-rw---- 1 root disk 252, 80 ... /dev/vdf
    brw-rw---- 1 root disk 252, 96 ... /dev/vdg
    ```

```bash
# List block devices in the guest.
sudo lsblk
```
??? example "Expected result"
    ```text
    NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
    vda    252:0    0 18.5G  0 disk
    vdb    252:16   0   10G  0 disk
    vdc    252:32   0   10G  0 disk
    vdd    252:48   0   10G  0 disk
    vde    252:64   0   10G  0 disk
    vdf    252:80   0   10G  0 disk
    vdg    252:96   0   10G  0 disk
    ```

!!! pied-piper "Takeaway"
    `virsh attach-disk --live --config` means:

    - attach the disk immediately
    - keep it attached after reboot
    - host image files appear inside the guest as devices like `vdb`, `vdc`, and so on

### :material-application-edit-outline: 1.3.11 UVTool Lab

`uvtool` makes it easy to sync Ubuntu cloud images and create VMs from them.

Return to `LABHOST` before starting.

!!! info
    This exercise uses `uvtool` to create a fast disposable VM from the default cloud-image feed. Success means `uvtool_vm` appears in `uvt-kvm list`, `uvt-kvm ip` returns an address, and you can log in over SSH.

Step 1: Install `uvtool`.

```bash
# Install the uvtool package.
sudo apt install -y uvtool
```
??? example "Expected result"
    ```text
    0 upgraded, 15 newly installed, 0 to remove and 0 not upgraded.
    ...
    Setting up uvtool (0~git183-0ubuntu1.24.04.1) ...
    Setting up uvtool-libvirt (0~git183-0ubuntu1.24.04.1) ...
    ...
    Running kernel seems to be up-to-date.
    No services need to be restarted.
    ```

Step 2: Sync the Noble cloud image.

```bash
# Sync the Noble amd64 cloud image to the local image store.
uvt-simplestreams-libvirt sync release=noble arch=amd64
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 3: List locally available images.

```bash
# Show the locally synced uvtool images.
uvt-simplestreams-libvirt query
```
??? example "Expected result"
    ```text
    release=noble arch=amd64 label=release (20260321)
    ```

Step 4: Create a VM from the synced image.

```bash
# Create a new VM from the Noble cloud image.
uvt-kvm create uvtool_vm release=noble --password ubuntu
```
??? example "Expected result"
    ```text
    Warning: using --password from the command line is not secure and should be used for debugging only.
    Warning: '/home/ubuntu/.ssh/id_rsa.pub' not found; instance will be started with no ssh access by default.
    ```

These warnings are expected in this lab. The first warns about passing the password on the command line, and the second means password login will be used instead of SSH key authentication.

Step 5: List the uvtool-managed VMs.

```bash
# List uvtool virtual machines.
uvt-kvm list
```
??? example "Expected result"
    ```text
     1   ubuntu      running
     2   uvtool_vm   running
    ```

Step 6: Query the VM IP address.

```bash
# Show the discovered IP for the uvtool VM.
uvt-kvm ip uvtool_vm
```
??? example "Expected result"
    ```text
    192.168.122.95
    ```

If no IP is shown yet, wait a few seconds and try again. Cloud-init may still be finishing.

Step 7: Resolve the VM IP into a shell variable.

```bash
# Resolve the uvtool VM IP into UVTIP.
export UVTIP=$(uvt-kvm ip uvtool_vm)
```
??? example "Expected result"
    ```text
    No output.
    ```

This command stores the discovered IP in your current shell so you can reuse it in the next step.

Step 8: SSH into the VM.

```bash
# Connect to the uvtool VM over SSH.
ssh "$UVTIP"
```
??? example "Expected result"
    ```text
    ubuntu@192.168.122.95:~$
    ```

Step 9: Regenerate the GRUB configuration in the guest.

```bash
# Rebuild the guest GRUB configuration.
sudo update-grub
```
??? example "Expected result"
    ```text
    Generating grub configuration file ...
    Found linux image: /boot/vmlinuz-...
    Found initrd image: /boot/initrd.img-...
    done
    ```

In this section, `update-grub` is mainly a guest administration check. It only changes the boot menu if guest-side GRUB settings were already modified.

Step 10: Reboot the guest.

```bash
# Reboot the uvtool VM.
sudo shutdown -r now
```
??? example "Expected result"
    ```text
    Connection to 192.168.122.95 closed by remote host.
    Connection to 192.168.122.95 closed.
    ```

When this SSH session closes, you are back on `LABHOST` and can open the guest console there.

Step 11: Open the console from the host.

```bash
# Connect to the uvtool VM console from the host.
virsh console uvtool_vm
```
??? example "Expected result"
    ```text
    Connected to domain 'uvtool_vm'
    Escape character is ^] (Ctrl + ])
    ```

If you open the console, leave it with `Ctrl + ]` before running the destroy command on `LABHOST`.

Step 12: Destroy the test VM when finished.

```bash
# Delete the uvtool VM.
uvt-kvm destroy uvtool_vm
```
??? example "Expected result"
    ```text
    No output.
    ```

!!! pied-piper "Takeaway"
    Use `uvtool` when you want:

    - a quick Ubuntu cloud-image VM
    - a disposable test machine
    - less manual setup than a full `virt-install` workflow
