# Ubuntu Server Advanced 

This is a combination student manual lab guide. It is intended to augment the delivery of the  **Ubuntu Server Advanced** training.

All chapters are structured in three sections:
* introduction to the concepts (theory)
* lab exercises to help you understand the theory
* lab solutions for your reference

Please follow along with the class and notify your facilitator if you require assistance.

# Table Of Contents

# 1. Virtualization !heading

**Description:**

The purpose of this lab is to prepare the ground for the next chapters in this
course. It is mandatory to successfully complete this lab in order to continue
the next chapters.

In this section you will learn to:
* Setup your lab QEMU+KVM virtual machine
* Complete an Ubuntu Linux installation process
* Add extra hardware to the VM


## 1.1 What is virtualization?

Virtualization refers to the partitioning of one physical server into several virtual servers or machines. These machines act like real computers with operating systems and can interact independently with other devices, applications, data, and users as though they are separate physical resources. The virtual machines or guests share the resources of the host computer. The machines are isolated from each other such that, if one crashes, it can’t affect the others. 

There are two kinds of virtual machines: system VMs and process VMs (like the Java Virtual Machine). Emulation refers to recreating hardware purely in software whereas virtualization involves interacting with the host hardware (known as hardware assist) to accomplish the same thing. **virt-what** is a tool available in the universe repository that can detect if the system is running in a virtual machine.. 

A hypervisor, or virtual machine manager, is the program that creates and runs virtual machines. The hypervisor controls the host processor and resources, and allocates them to each virtual machine. Virtualization can also be used to combine multiple physical resources into a single virtual resource as in storage virtualization. With storage virtualization multiple network storage resources are combined into what appears as a single storage device. On Linux, QEMU+KVM are the leading stack with libvirt for management. 

There are a few tools to determine if a machine is virtual:

```bash
sudo dmidecode 
sudo dmesg 
sudo systemd-detect-virt 
sudo virt-what
```

**dmidecode** is a tool for dumping a computer’s DMI (also called SMBIOS) table contents in a human-readable format. This table contains a description of the system’s hardware components, as well as other useful pieces of information such as serial numbers and BIOS revision. 

**dmesg** is used to examine or control the kernel console ring buffer. The default action is to display all messages from the kernel console ring buffer. 

**systemd-detect-virt** returns *0* if a virtualization technology is detected
(whether container or VM), non-zero otherwise. It prints the identifier of the tech
to standard output (STDOUT). The latter behaviour can be suppressed with the *-q*
option, which is convenient for scripting. It works with nested virtualisation as
well (see the man page).

**virt-what** is a small shell script that detects if it is running in a virtual machine and identifies the virtualization technology in use. It works by inspecting various system files and interfaces such as CPUID, DMI, and Xen interfaces. It outputs the name of the virtualization platform (e.g., kvm, xen, vmware, hyperv) or returns nothing if no virtualization is detected. It’s especially useful in scripts for VM-aware configuration.


## 1.2 KVM Virtualization Stack

The graphic below portrays a KVM virtualization stack. Each virtual machine (VM) is a normal Linux process. Qemu is a device emulator. And, libvirt provides the manageability. 

![KVM Virtualization Stack](./images/kvm-stack.png)


### QEMU+KVM

QEMU can be used to emulate another machine although there is a performance penalty.
KVM stands for Kernel-based Virtual Machine and provides access to host machine
hardware via the kernel. It provides near-native performance.

When working alone, QEMU emulates both CPU and hardware. When working together, KVM arbitrates access to the CPU, memory and real hardware, while QEMU can emulate other hardware resources to be presented to the guest. In that sense a hard disk could be a real Host disk or NVME drive passed through, or a file that is only presented to the guest as a disk.


### What is KVM?

**KVM** is a hypervisor which provides near-native speeds by running directly on the hardware using processor extensions. KVM is a hypervisor that runs inside an operating system. It requires a processor with hardware virtualization extensions. KVM can virtualize x86_64, i386 (also known as x86_32), ARM64, PowerPC, and S390 on those specific architectures. It is the most commonly used hypervisor in OpenStack and it is used by many cloud vendors. 

**Ubuntu** uses **KVM** as the back-end virtualization technology primarily for servers and libvirt as its toolkit or API. Libvirt front ends for managing VMs include virt-manager (GUI) and virsh (CLI). Newer versions of LXD can also manage virtual machines.

**KVM** allows a userspace host to set up the guest VM’s address space. The host must also supply a firmware image (usually a custom BIOS when emulating PCs) that the guest can use to bootstrap into its main OS.

### What is QEMU?

**QEMU** is short for Quick Emulator. It is a userspace host. QEMU uses KVM when available to virtualize guests at near-native speeds by executing the guest code directly on the host CPU. Otherwise it falls back to software-only emulation, this functionality is known in QEMU as the TCG or Tiny Code Generator. It is a generic software emulator/simulator, capable of simulating a variety of different hardware.

Parts of **QEMU** are also used as the building blocks for many other virtualization solutions. For example, QEMU in Ubuntu can emulate arm, mips, ppc, sparc, x86, and more. 

**QEMU** is not exclusive to the KVM hypervisor, it can also be used in conjunction with the **Xen** or other hypervisors to provide BIOS emulation for the bootstrap phase of the guest operating systems. 

### Qemu-img

**qemu-img** is a disk image utility that lets you create disk images of many types (RAW,
QCOW2, VMDK) to serve as storage for virtual machines. It lets you convert between
different image types including importing and exporting images from the CEPH
distributed storage system.

It can query images for information with
```bash
qemu-img info
```

### libvirt

The **libvirt** suite is used to interface with different virtualization technologies. It is used to manage QEMU+KVM virtual machines, which it calls domains. 

Before getting started with libvirt it is best to make sure your hardware supports the necessary virtualization extensions for KVM. Running the following command checks to see if you have the needed processor features active to run KVM VMs: 


```bash
sudo apt install -y cpu-checker
sudo kvm-ok
```

Also you can use *virt-host-validate* to check if the host is configured in a suitable way to run libvirt hypervisor drivers.

```bash
sudo virt-host-validate
```

**libvirt** includes the **virsh** command set, allowing the creation and
manipulation of machines, networks, storage pools and devices. These are defined
using XML files which can be exported, imported or edited on the fly.


## 1.3 Virtualization Lab

![kvm stack 2](./images/kvm-stack2.png)


### 1.3.1 Installing a Guest VM

In this lab you will setup the virtual machine (VM) you will use for the course:
`LABVM` on `LABHOST`.

We will use libvirt/virsh for this task, later on we will see that LXD can be used as an alternative.

 * LABHOST - the assigned lab host that the student logs in to.
 * LABVM - the virtual machine set up by the student and used for the class.

<!-- end list -->

1. From `LABHOST`, begin everything with an update.

```bash
sudo apt update -y && sudo apt dist-upgrade -y
```

Reboot the instance.

```bash
sudo reboot
```

> Log back in after the reboot

2. Install the packages needed for VM creation, that are not part of standard Ubuntu.

```bash
sudo apt-get install -y qemu-system qemu-kvm libvirt-daemon libvirt-clients bridge-utils \
  libvirt-daemon-system qemu-utils cpu-checker virt-viewer virt-manager virtinst
```

3. See if your `LABHOST` supports virtualization.

```bash
sudo kvm-ok
```

4. Add your user into the two virtualization groups.

```bash
sudo usermod -aG kvm ubuntu
sudo usermod -aG libvirt ubuntu
```

You must logout and login to activate the new groups (to use virsh without sudo).
> Log out / Log in

```bash
exit
```

Log back in with your public IP:

```bash
ssh ubuntu@<public IP>
```

5. List the virtual machines already existing (there should be none).

```bash
virsh list --all
```

### 1.3.2 Setting up storage pools

Libvirt is capable of working with a number of storage back-ends:

 * Directory pool
 * Filesystem pool
 * Network filesystem pool
 * Logical volume pool
 * Disk pool
 * iSCSI pool
 * SCSI pool
 * Multipath pool
 * RBD pool
 * Sheepdog pool 
 * Gluster pool 
 * ZFS pool 
 * Vstorage pool 

For now we will be focusing on the `Directory` storage pool. So let's add a new pool.

1. Create a directory that will host our images:

```bash
sudo mkdir -p /var/lib/libvirt/vm-disks
```

2. Define a pool with this directory as a target:

```bash
virsh pool-define-as --name vm-disks --type dir --target /var/lib/libvirt/vm-disks
```

3. Let's check that the pool has been created:

```bash
virsh pool-list --all

# output
 Name                 State      Autostart 
-------------------------------------------
 vm-disks             inactive   no        
```

4. We have a pool, but it's inactive. We need to start it:

```bash
virsh pool-start vm-disks
```

5. And we need to make sure that it starts automatically on boot:

```bash
virsh pool-autostart vm-disks
```

6. Let's check again:

```bash
virsh pool-list --all

# output
 Name                 State      Autostart 
-------------------------------------------
 vm-disks             active     yes       
```

Great. We have a pool that is active and will start automatically after reboot. We should be able to create disks as needed and fetch information about the pool at will:

```bash
virsh pool-info vm-disks

# output
Name:           vm-disks
UUID:           90e61766-0e23-4477-8f7b-a4aa26fc8ab2
State:          running
Persistent:     yes
Autostart:      yes
Capacity:       76.45 GiB
Allocation:     4.22 GiB
Available:      72.23 GiB
```

This should suffice for our needs in this lab.

### 1.3.3 Volume operations

Now that we have a storage pool, we can create, delete, resize and get information about volumes in that pool.


1. Create a new volume

```bash
virsh vol-create-as vm-disks sample-vol 6G --format qcow2
```

This will create a new `qcow2` volume called `sample-vol` with a maximum size of `6GB`. By default libvirt creates sparse files and does not pre-allocate disk space. It is worth mentioning that there is a `vol-create` command as well, that takes a `xml` file as an argument.

2. Let's check that we have the volume:

```bash
virsh vol-list --details vm-disks

# output
 Name        Path                                  Type  Capacity  Allocation
------------------------------------------------------------------------------
 sample-vol  /var/lib/libvirt/vm-disks/sample-vol  file  6.00 GiB  196.00 KiB

```

3. The volume has been created. We can also get some info about that volume in particular:

```bash
virsh vol-info sample-vol vm-disks

# output
Name:           sample-vol
Type:           file
Capacity:       6.00 GiB
Allocation:     196.00 KiB
```

4. Resize the volume:

```bash
virsh vol-resize sample-vol --pool vm-disks --capacity 10G
```

5. Check if the size of the disks has been updated:

```bash
virsh vol-info sample-vol vm-disks

# output
Name:           sample-vol
Type:           file
Capacity:       10.00 GiB
Allocation:     200.00 KiB
```

### 1.3.4 Cloning volumes

1. Clone the `sample-vol`.

```bash
virsh vol-clone sample-vol cloned-vol vm-disks
```

2. This will create a 1:1 clone of the original volume. So we will get two identical disks:

```bash
virsh vol-list --details vm-disks

# output
 Name        Path                                  Type   Capacity  Allocation
-------------------------------------------------------------------------------
 cloned-vol  /var/lib/libvirt/vm-disks/cloned-vol  file  10.00 GiB  196.00 KiB
 sample-vol  /var/lib/libvirt/vm-disks/sample-vol  file  10.00 GiB  200.00 KiB

```

3. Alternatively, to save up on space, you can leverage the `qcow2` `copy-on-write` functionality, and use the original volume as a backing file to create a new volume.

```bash
sudo qemu-img create -f qcow2 -b /var/lib/libvirt/vm-disks/sample-vol \
  -F qcow2 /var/lib/libvirt/vm-disks/cow-clone
```

4. Let's check the resulting image:

```bash
sudo qemu-img info --backing-chain /var/lib/libvirt/vm-disks/cow-clone

# output
image: /var/lib/libvirt/vm-disks/cow-clone
file format: qcow2
virtual size: 10 GiB (10737418240 bytes)
disk size: 196 KiB
cluster_size: 65536
backing file: /var/lib/libvirt/vm-disks/sample-vol
backing file format: qcow2
Format specific information:
    compat: 1.1
    compression type: zlib
    lazy refcounts: false
    refcount bits: 16
    corrupt: false
    extended l2: false
Child node '/file':
    filename: /var/lib/libvirt/vm-disks/cow-clone
    protocol type: file
    file length: 192 KiB (197120 bytes)
    disk size: 196 KiB

image: /var/lib/libvirt/vm-disks/sample-vol
file format: qcow2
virtual size: 10 GiB (10737418240 bytes)
disk size: 200 KiB
cluster_size: 65536
Format specific information:
    compat: 0.10
    compression type: zlib
    refcount bits: 16
Child node '/file':
    filename: /var/lib/libvirt/vm-disks/sample-vol
    protocol type: file
    file length: 256 KiB (262656 bytes)
    disk size: 200 KiB
```

As we can see, there is now a `COW` image with a backing file pointing to our original image.

**IMPORTANT NOTE**: In this scenario, booting or modifying the original image will corrupt all other disks that use it as a backing file. Take great care to never attach a backing file to a virtual machine.

5. Since disk was created outside `virsh`, we need to refresh the information:

```bash
virsh pool-refresh vm-disks
```

6. Let's check out volume pool to see if the new image is registered:

```bash
virsh vol-list --details vm-disks
# output
 Name        Path                                  Type   Capacity  Allocation
-------------------------------------------------------------------------------
 cloned-vol  /var/lib/libvirt/vm-disks/cloned-vol  file  10.00 GiB  196.00 KiB
 cow-clone   /var/lib/libvirt/vm-disks/cow-clone   file  10.00 GiB  196.00 KiB
 sample-vol  /var/lib/libvirt/vm-disks/sample-vol  file  10.00 GiB  200.00 KiB
```


### 1.3.5 Libvirt networks


1. List the existing `default` network.

```bash
virsh net-list
```

2. Get additional info on the `default` network.

```bash
virsh net-info default
```

3. Get the default network definition.

```bash
virsh net-dumpxml default
```

4. As can be seen from `bridge name='virbr0'`, the network is bound to the
`virbr0` bridge. Inspect it.

```bash
ip addr show virbr0
```



### 1.3.6 Define additional networks in libvirt

Defining a new network in libvirt is a bit more involved. It requires you to create an XML file that describes the network. Let's create an XML file for a new DHCP enabled NAT network. Although a default network exists, we’ll define an additional one to illustrate the process:

1. Inspect the `nat-kvm-network.xml` network file definition:


```bash
cat ~/nat-kvm-network.xml
```

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

2. Using this file we can create the network:

```bash
virsh net-define ~/nat-kvm-network.xml
```

3. Start the network:

```bash
virsh net-start nat-kvm-network
```

4. Set the network to start automatically on boot:

```bash
virsh net-autostart nat-kvm-network
```

5. Creating a new network will start a new bridge configured with the IP address in the XML:

```bash
ip addr sh nat-virbr2|grep inet
# output
inet 192.168.101.1/24 brd 192.168.101.255 scope global nat-virbr2
```

### 1.3.7 Creating the first VM

It's time to put it all together. In the following example we will use `virt-install` to create an Ubuntu 24.04 virtual machine using a Canonical-provided OS disk image. We will connect the VM to the `nat-kvm-network` network defined in libvirt.

For simplicity's sake and to be able to reuse this later if need be, you’ll find a script named `create_vm.sh` in the home directory. Open it in a text editor to inspect its contents.

1. Inspect current scripts and configurations:

```bash
cat create_vm.sh

# output
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
```

A CD-ROM image (cloud-init.iso) is mounted to provide initial configuration to the VM. That ISO file contains 3 files: user-data, meta-data and network-config. These will be passed as metadata to the cloud-init process running on your machine and configure it accordingly. Let's check the files:

```bash
cat user-data

# output
#cloud-config
hostname: ubuntu
manage_etc_hosts: true

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

########################################
cat meta-data

# output
instance-id: ubuntu-vm
local-hostname: ubuntu

########################################
cat network-config

# output
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

########################################
```

2. Use the `create_vm.sh` script to create the VM.

```bash
cd ~; chmod +x ./create_vm.sh
```

```bash
./create_vm.sh
```

> Once the installation is complete, the VM will shut down.

3. List the VMs.

```bash
virsh list --all
```

4. Info about the VM can also be obtained.

```bash
virsh dumpxml ubuntu | less
```


### 1.3.8 Accessing the VM


Once machine has completed cloud-init, it will automatically have `ubuntu` user set and IP address that we can use. Let’s make sure VM auto-starts with the OS: 

1. Time to boot the VM:

```bash
virsh autostart ubuntu
```

2. List the VMs.

```bash
virsh list
```

3. The virtual machine really is a machine, you could even check its boot console with:

```bash
virsh console ubuntu

# to exit press CTRL + ]
```

4. Wait for a few seconds for cloud-init to finish, and see if you can reach the VM:

```bash
ping -c5 192.168.101.50
# output
PING 192.168.101.50 (192.168.101.50) 56(84) bytes of data.
64 bytes from 192.168.101.50: icmp_seq=1 ttl=64 time=0.337 ms
64 bytes from 192.168.101.50: icmp_seq=2 ttl=64 time=0.156 ms
64 bytes from 192.168.101.50: icmp_seq=3 ttl=64 time=0.185 ms

--- 192.168.101.50 ping statistics ---
3 packets transmitted, 3 received, 0% packet loss, time 1998ms
rtt min/avg/max/mdev = 0.156/0.226/0.337/0.079 ms
```

5. Log in the `LABVM`:

> Username: ubuntu

> Password: ubuntu

```bash
ssh 192.168.101.50
```


### 1.3.9 Attaching extra disks to the VM

Attaching an extra disk can be easily done via `virsh`. Up until this point we have talked about `qcow2` images. In the following example we will create  simple RAW images and attach them to the VM. We will then partition it and format the partition.

1. Go back to your `LABHOST`:

```bash
exit
```

2. On your `LABHOST`, create the disks we're going to attach to `LABVM`:

```bash
sudo qemu-img create -f raw /var/lib/libvirt/vm-disks/test-vmdiskb.raw 10G
sudo qemu-img create -f raw /var/lib/libvirt/vm-disks/test-vmdiskc.raw 10G
sudo qemu-img create -f raw /var/lib/libvirt/vm-disks/test-vmdiskd.raw 10G
sudo qemu-img create -f raw /var/lib/libvirt/vm-disks/test-vmdiske.raw 10G
sudo qemu-img create -f raw /var/lib/libvirt/vm-disks/test-vmdiskf.raw 10G
sudo qemu-img create -f raw /var/lib/libvirt/vm-disks/test-vmdiskg.raw 10G
```

3. Now let's refresh the pool:

```bash
virsh pool-refresh vm-disks
virsh vol-list --details vm-disks
```

4. And we can now attach the disks to the `LABVM`:

```bash
virsh attach-disk ubuntu /var/lib/libvirt/vm-disks/test-vmdiskb.raw vdb --live --config
virsh attach-disk ubuntu /var/lib/libvirt/vm-disks/test-vmdiskc.raw vdc --live --config
virsh attach-disk ubuntu /var/lib/libvirt/vm-disks/test-vmdiskd.raw vdd --live --config
virsh attach-disk ubuntu /var/lib/libvirt/vm-disks/test-vmdiske.raw vde --live --config
virsh attach-disk ubuntu /var/lib/libvirt/vm-disks/test-vmdiskf.raw vdf --live --config
virsh attach-disk ubuntu /var/lib/libvirt/vm-disks/test-vmdiskg.raw vdg --live --config
```

> Wait a few seconds and log back in.

```bash
ssh 192.168.101.50
```

5. List the disks.

```bash
sudo ls -al /dev/vd*

sudo lsblk
```

### 1.3.11 UVTool Lab

Starting with 14.04 LTS, a tool called `uvtool` greatly facilitates the task of
generating virtual machines (VM) using cloud images. `uvtool` provides a simple
mechanism to synchronize cloud-images locally and use them to create new VMs in
minutes.

Make sure you are on the `LABHOST`.

1. Install the necessary software.

```bash
sudo apt install -y uvtool
```

2. Filter to use one specific image.

```bash
uvt-simplestreams-libvirt sync release=noble arch=amd64
```

3. List the available images (local).

```bash
uvt-simplestreams-libvirt query
```

4. Specify a release or image while creating a VM.

```bash
uvt-kvm create uvtool_vm release=noble --password ubuntu
```

5. List the VMs (you should have two now). Use virsh or uvt-kvm.

```bash
uvt-kvm list
```
> Wait until the VM is ready. It finds and adds the IP address to the host. 

6. View the IP address of the VM.

```bash
uvt-kvm ip uvtool_vm
```

If you get a message like: `uvt-kvm: error: no IP address found for libvirt machine 'uvtool_vm'`, wait a few seconds and try again.

7. SSH to the node using the IP (user=ubuntu).

```bash
export UVTIP=`uvt-kvm ip uvtool_vm`
ssh $UVTIP
```

8. Apply the change to the boot parameters.

```bash
sudo update-grub
```

9. Reboot the VM for the change to be applied.

```bash
sudo shutdown -r now
```

10. Connect to the VM through the console.

```bash
virsh console uvtool_vm
```

11. Exit the console with `ctrl+]` and delete the virtual machine.

```bash
uvt-kvm destroy uvtool_vm
```


# 2. LXD !heading

**Description:**

In this section you will learn to:
* Define LXD
* Setup and manage a container

## 2.1 Containerization

**Containers** are isolated userspace environments running on the same host kernel, allowing multiple independent systems to coexist with minimal overhead. By using Linux kernel features like namespaces and cgroups, containers can isolate processes, filesystems, users, and networking. Depending on how they are configured, containers can act as lightweight wrappers around a single process (**application containers**, e.g., Docker), or as full system environments (**system containers**, e.g., LXD), resembling virtual machines.

Unlike full virtualization (where each VM runs its own kernel and OS), containers share the host kernel. This results in lower resource usage and faster startup times — making it possible to run many more containers than VMs on the same hardware.

There are two broad types of containers:

* **Application containers** (e.g., Docker): focused on encapsulating a single process or service.
* **System containers** (e.g., LXD): emulate a full Linux OS environment, suitable for running multiple services or legacy apps.

System containers typically rely on **LXC** (Linux Containers), which provides the low-level userspace tools and APIs to interface with the kernel’s containment features. **LXD** builds on top of LXC, offering a more user-friendly daemon and REST API for managing system containers at scale. 

## 2.2 What is LXD?

LXD is a pure-container hypervisor that runs unmodified Linux operating systems and applications with VM-style operations at incredible speed and density. LXD is an enhancement of the existing LXC Linux container hypervisor with its own toolset. The goal is to provide an interface that is similar to a virtual machine. However, it uses Linux containers instead of hardware virtualization. LXC-based containers are easier to use through the addition of a backend daemon supporting REST API and a CLI client that works with both the local daemon and remote daemons via the REST API. LXD uses a RESTful API to communicate with clients, either over HTTPS (for remote connections) or a Unix socket (for local operations). Once LXD is installed, an image is required. Containers are instantiated from these images and can be reused or customized. 
 

LXD is comprised of the following components:

 * A system-wide daemon (lxd) which exports a REST API locally (and if enabled, over the network).
 * A command line client (lxc) which is a simple tool to manage containers: connect multiple container hosts, provide a network overview of all containers, and create and move containers.

LXD is image based. A number of remote image stores are already available. Images will be downloaded to the local LXD store when a container is first launched. At its simplest, LXD is a daemon which provides a REST API to drive LXC containers. Its main goal is to provide a user experience that’s similar to that of virtual machines but using Linux containers rather than hardware virtualization. 


## 2.3 LXD Setup LAB

### 2.3.1 Install LXD

Traditionally, LXD used to get installed from the default repository, or from a PPA. With the arrival of snaps we can now install LXD as a snap. We must clean any LXD version that may have been pre-installed on the system.

Run the following commands on the `ubuntu` `LABVM`.

1. Make sure you are logged to the `LABVM` machine:

```bash
ssh 192.168.101.50
```

2. Install ZFS support:

```bash
sudo apt -y install zfsutils-linux
```
> **Note:** We’ll explore ZFS in more detail later in this course. For now, we’re enabling ZFS support so LXD can use it as a backend for snapshots and storage pools.


3. Create lxd group and add ourselves to it: 

```bash
sudo groupadd --system lxd 
sudo usermod -G lxd -a $USER 
newgrp lxd
```

4. And install LXD 5.21 as a snap: 

```bash
sudo snap install lxd --channel=5.21/stable
```

5. Initialize LXD: 

```bash
sudo lxd init --auto
```

**NOTE**: This will initialize LXD with the default values. If you wish to use the interactive mode, don't use `--auto`.

1. Set the LXD bridge MTU to 1450 : 

```bash
lxc network set lxdbr0 bridge.mtu=1450 
```

7.  Launch a new container:

```bash
lxc launch ubuntu:24.04 noble
```

```bash
lxc list
# or 
lxc ls 
```

8. Afterwards, rename the new image with `ubuntu` as alias (use `lxc image list` to get the image fingerprint)

```bash
lxc image list
```

```bash
lxc image alias create ubuntu <fingerprint>
```

This will use Ubuntu 24.04 container image whenever selecting `ubuntu` image.


### 2.3.2 Using a remote LXD as an image server

1. When using a remote image server, add it as a remote and use it:

```bash
lxc launch images:centos/9-Stream centos
```

2. An image list can be obtained with:

```bash
# Colon is required
lxc image list images:
```

```bash
# Check local store for downloaded images
lxc image list local:
```


### 2.3.3 Creating and using a container

1. Create the `first` container with:

```bash
lxc launch ubuntu first
```

2. That will create and start a new Ubuntu container. Confirm it with:

```bash
lxc list
```

3. The container here is called `first`. Once the container is running, get a shell inside it with:

```bash
lxc exec first -- /bin/bash 
# or 
lxc shell first 
```

4. Exit the container and get back to your host:

```bash
exit
```

5. Or run a command directly:

```bash
lxc exec first -- apt update
```

6. To pull a file from the container, use:

```bash
lxc file pull first/etc/hosts .
```

7. To push one, use:

```bash
lxc file push ./hosts first/tmp/
```

8. Verify the remote file:

```bash
lxc exec first -- ls -l /tmp/hosts
```

9. To stop the container:

```bash
lxc stop first
```

10. And to remove it entirely:

```bash
lxc delete first
```

### 2.3.4 Images

1. A few key image servers come preloaded.

```bash
lxc remote list

# output
+----------------------+---------------------------------------------------+---------------+-------------+--------+--------+--------+
|         NAME         |                        URL                        |   PROTOCOL    |  AUTH TYPE  | PUBLIC | STATIC | GLOBAL |
+----------------------+---------------------------------------------------+---------------+-------------+--------+--------+--------+
| images               | https://images.lxd.canonical.com                  | simplestreams | none        | YES    | NO     | NO     |
+----------------------+---------------------------------------------------+---------------+-------------+--------+--------+--------+
| local (current)      | unix://                                           | lxd           | file access | NO     | YES    | NO     |
+----------------------+---------------------------------------------------+---------------+-------------+--------+--------+--------+
| ubuntu               | https://cloud-images.ubuntu.com/releases/         | simplestreams | none        | YES    | YES    | NO     |
+----------------------+---------------------------------------------------+---------------+-------------+--------+--------+--------+
| ubuntu-daily         | https://cloud-images.ubuntu.com/daily/            | simplestreams | none        | YES    | YES    | NO     |
+----------------------+---------------------------------------------------+---------------+-------------+--------+--------+--------+
| ubuntu-minimal       | https://cloud-images.ubuntu.com/minimal/releases/ | simplestreams | none        | YES    | YES    | NO     |
+----------------------+---------------------------------------------------+---------------+-------------+--------+--------+--------+
| ubuntu-minimal-daily | https://cloud-images.ubuntu.com/minimal/daily/    | simplestreams | none        | YES    | YES    | NO     |
+----------------------+---------------------------------------------------+---------------+-------------+--------+--------+--------+
```

2. The following lists all the images on the `images` servers. The colon is required.

```bash
lxc image list images:
lxc image list local:
lxc image list ubuntu:
lxc image list ubuntu-daily:
```


### 2.3.5 LXD profiles

LXD profiles are used to store pre-defined configurations for containers. You can think of it as a configuration template you can apply to new containers. When creating a container you can associate one or more profiles that will get applied in the order they are specified.

1. To list all profiles:

```bash
lxc profile list
```

2. To edit a profile, run the following command but don't make any changes for now:

```bash
lxc profile edit default
```

3. To show a profile:

```bash
lxc profile show default
```


### 2.3.6 LXD snapshots

1. Creating a snapshot:

```bash
lxc snapshot noble my-snapshot
```

> This operation is usually instant, thanks to ZFS’s copy-on-write snapshot mechanism, that we'll discuss later on.


2. Use this to see information about the container, including snapshots:

```bash
lxc info noble
```

3. Restoring a machine from a previous snapshot:

```bash
lxc restore noble my-snapshot
```

4. Creating a new container from a snapshot is fast and easy. You simply have to run:

```bash
lxc copy noble/my-snapshot my-new-container-from-snapshot
```

5. You should now have a new container. We need to apply a profile to it:

```bash
# you can also add multiple profiles by separating them with
# with a comma: default,test-profile

lxc profile assign my-new-container-from-snapshot default
```

6. And we can now start it:

```bash
lxc start my-new-container-from-snapshot
```

```bash
lxc list
```

7. Stop and delete all the containers you have created so far.
`lxc list`, `lxc stop` and `lxc delete` will help you with this task.

```bash
lxc stop centos
lxc stop noble
lxc stop my-new-container-from-snapshot
```

```bash
lxc delete centos
lxc delete noble
lxc delete my-new-container-from-snapshot
```
### 2.3.7 KVM VMs in LXD

Right out of the box, LXD comes with KVM support. To launch a KVM VM, use:

```bash
lxc launch ubuntu:24.04 ubuntu-vm --vm
```

If you're interested in the install process and what's happening on the VM console, run:

```bash
lxc console ubuntu-vm
```

To exit the console, type the following sequence:

```bash
Ctrl+a q
```

By default, it will create a VM with 1 vCPU, 1GB of memory and 10GB of disk. You can check them with:

```bash
lxc shell ubuntu-vm
cat /proc/cpuinfo
free -m
lsblk
exit
```
This default configuration is suitable for testing. Production grade VMs can be tuned via profile or CLI options.

Limits can be adjusted with:

```bash
lxc launch ubuntu:24.04 ubuntu-vm2 --vm -c limits.cpu=2 -c limits.memory=2GiB -d root,size=20GiB
```

Use the same commands to check new limits for the VM:

```bash
lxc shell ubuntu-vm2
cat /proc/cpuinfo
free -m
lsblk
exit
```

Now, let's do some cleanup:

```bash
lxc delete ubuntu-vm --force
lxc delete ubuntu-vm2 --force
```

`--force` will be able to delete the VM (or container) even if it's not stopped first.

### 2.3.8 LXD networks

Right out of the box, LXD comes with no network defined at all. `lxd init` will offer to 
set one up for you and attach it to all new containers by default. 

1. We already did the init in section 2.3.1, so let’s take a look at the networks. 

```bash
lxc network list
```

2. `lxdbr0` is the network created during the init phase. Get info on the network.

```bash
lxc network info lxdbr0
```

```bash
lxc network show lxdbr0
```


3. That network is in fact Linux Bridge with `NAT`. You can see this by inspecting the interface.

```bash
ip addr | grep lxdbr0
# output
10: lxdbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    inet 10.233.0.1/24 scope global lxdbr0
```

4. To create a new network with a random IPv4 subnet and NAT enabled, just run:

```bash
lxc network create brtest0
```

5. Check the newly created network.

```bash
lxc network show brtest0
```

6. You can associate this new network with a profile, so that any containers using the profile will automatically be connected to it.

```bash
lxc network attach-profile brtest0 default eth1
```

7. Inspect the `default` profile to see if the new network was added:

```bash
lxc profile show default
```

8. Create a new container.

```bash
lxc launch ubuntu:24.04 noble
```

9. List the container to see if it has two interfaces.

```bash
lxc list
```

```bash
lxc config show --expanded noble
```

> Or you can attach this network to an existing container and inspect it afterwards.

```bash
# lxc network attach brtest0 noble eth1
```

10. Force eth1 to take an IP from DHCP provided by LXD:

```bash
lxc exec noble -- sudo apt-get update 
lxc exec noble -- sudo apt-get install -y isc-dhcp-client 
lxc exec noble -- dhclient eth1 
```

```bash
lxc ls
```

11. Stop and delete the container.

```bash
lxc delete noble --force
```

12. Delete `LXD`.

```bash
sudo snap remove lxd --purge
```

13. Exit back to `LABHOST`:

```bash
exit
```

# 3. OpenSSH !heading

**Description:**

In this section you will learn to:

* Describe key OpenSSH features
* Perform OpenSSH server configuration
* Use OpenSSH client tools
* Perform SSH key management

## 3.1 What is OpenSSH?

The OpenSSH client is included in Ubuntu by default. Secure Shell (ssh) allows you to connect to a different computer and execute commands despite the fact that you are not physically sitting in front of it. SSH grants terminal access to the computer. It is intended to provide secure encrypted communications between two untrusted hosts over an insecure network.

SSH connects and logs into the specified hostname (with an optional user name). The user must prove their identity to the remote machine using a password, a key, or a token. Using a cryptographic key is the recommended method. 

Connecting to a remote host: 

```bash
ssh user@<remote_host>
```

Installing the OpenSSH server on a host:

```bash
sudo apt install -y openssh-server
```
> **Note:** The OpenSSH client is installed by default on Ubuntu. The server must be explicitly installed.

You can configure it by editing the **sshd_config** file in the **/etc/ssh** directory. **sshd_config** is the configuration file for the OpenSSH server. **ssh_config** is the configuration file for the OpenSSH client.
*Make sure not to get them mixed-up.*

### Examples

First, make a backup of your **sshd_config** file by copying it to your home
directory, or by making a read-only copy in **/etc/ssh**.

To make the copy:

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.factory-defaults
sudo chmod a-w /etc/ssh/sshd_config.factory-defaults
```

Creating a read-only backup in **/etc/ssh** means you'll always be able to find a
known, good configuration when you need it. Once you've backed up your
**sshd_config** file, you can make changes with any text editor, for example:

```bash
sudo nano /etc/ssh/sshd_config
```

This command opens the standard text editor in Ubuntu. Once you've made your changes,
you can apply them by saving the file then doing:

```bash
sudo systemctl restart sshd
```

Configuring OpenSSH means striking a balance between security and ease-of-use.
Ubuntu's default configuration tries to be as secure as possible without making
it impossible to use in common use cases. Consider the changes you can make,
and how they affect the balance between security and ease-of-use. You should
decide what balance is right for your specific situation.

For a comprehensive list of available options, their meanings and defaults,
please see the **sshd_config(5)** manual page:

```bash
man 5 sshd_config
```

## 3.2 SSH Keys

SSH keys allow authentication between two hosts without the need of a password.
Public key authentication is more secure than password authentication. This is
particularly important if the computer is visible on the internet.

Key-based authentication uses two keys, one "public" key that anyone is allowed to
see, and another "private" key that only the owner is allowed to see. Each key is
a large number with special mathematical properties. The private key is kept on the
computer you log in from, while the public key is stored in the **authorized_keys**
file on all the computers you want to log in to. Usually such keys are located in the
**~/.ssh/** folder.

When you log in to a computer, the SSH server uses your public key to “encrypt” messages in a way that can only be “decrypted” by your private key - using this SSH key pair it creates a session key that encrypts the ongoing traffic of a connection. As an extra security measure, it is recommended to store the private key in a passphrase-protected format. If your computer is stolen or broken into, you should have enough time to disable your old public key before the thieves break the passphrase and start using your key. 


### 3.2.1 Key-Based SSH Logins

Key-based authentication is considered one of the most secure out of several modes of authentication usable with OpenSSH, such as plain passwords and Kerberos tickets. Key-based authentication has several advantages over password authentication. For example, the key values are significantly more difficult to brute-force or guess, than plain passwords, provided an ample key length. Other authentication methods are only used in very specific situations. SSH can use either **“RSA”** (Rivest-Shamir-Adleman), **“DSA”** (Digital Signature Algorithm) keys or, more recently, Elliptic Curve keys. Both **RSA** and **DSA** were considered state-of-the-art algorithms when SSH was invented, but **DSA** has come to be seen as less secure in recent years.  While **RSA** used to be the default choice for new SSH keys, recent releases now favor elliptic curve (EC) keys as the default — such as **ED25519** — which offer comparable or better security with significantly lower computational overhead.

To securely communicate using key-based authentication, one needs to:
* create a key pair
* securely store the private key on the computer one wants to log in from
* store the public key on the computer one wants to log in to

For enhanced security, private keys can be stored in **hardware-backed devices** like **FIDO2-compatible security keys** (e.g., YubiKey), which protect the key material from extraction and support biometric or PIN-based access. This approach greatly reduces the risk of key theft or misuse.

Note: Kerberos is an alternative authentication protocol that uses a ticket-based system to prove identity without sending passwords. It leverages symmetric-key cryptography and a trusted third party (KDC). As long as the ticket is valid, users can access services without reauthenticating.

### 3.2.2 Generating Keys

Using **key-based logins** with SSH is generally more secure than using password authentication. This section explains how to generate a public/private key pair and use it to log into your Ubuntu system via OpenSSH.

To generate a key pair using the **recommended default algorithm** (usually **ED25519** on modern systems), simply run:

```bash
ssh-keygen
```

The system will select the most secure default algorithm supported by your OpenSSH version and configuration. During the process, you’ll be prompted for a passphrase.  It is highly recommended to set one to protect your private key.

If you specifically need an **RSA** key (for example, for compatibility with older systems), you can explicitly use:

```bash
ssh-keygen -t rsa
```

By default, the key files are saved in:

* `~/.ssh/id_ed25519` (or `id_rsa`) — the private key

* `~/.ssh/id_ed25519.pub` (or `id_rsa.pub`) — the public key

To install your public key on a remote server, use:

```bash
ssh-copy-id username@remotehost 
```

This appends your public key to `~/.ssh/authorized_keys` on the target system, enabling passwordless login.

If you want to understand how SSH chooses which key to use, or why a particular login attempt fails, you can add the `-v` (verbose) flag to your SSH command:

```bash
ssh -v username@remotehost
```

This will print detailed information about each step of the SSH connection process — including:

* Which config files (`~/.ssh/config, /etc/ssh/ssh_config`) are read
* Which host key algorithms are offered and selected
* Which private keys are tried (you’ll see entries like Offering public key: ...)
* Whether a key was accepted or rejected by the server


Example output snippet:

```bash
debug1: Offering public key: /home/user/.ssh/id_ed25519
debug1: Offering public key: /home/user/.ssh/id_rsa
debug1: Server accepts key: pkalg ssh-ed25519
```
You can also increase verbosity with `-vv` or `-vvv` for even more detail — useful when debugging tricky authentication issues.
SSH may try multiple keys, depending on what’s in your `~/.ssh` directory and agent, until the server accepts one or rejects them all.


## 3.3 SSH Tools

### 3.3.1 ssh-agent

**ssh-agent** is a key management tool used for public key authentication. It holds keys and certificates in memory, unencrypted, and ready for use by SSH. It is included in the OpenSSH client package. The **ssh-agent** is started at the beginning of a login session, and all other windows or programs are started as clients to the **ssh-agent** program. Through use of environment variables the agent can be located and automatically used for authentication when logging in to other machines using SSH. 

On Ubuntu systems, especially when using the default GNOME desktop environment, **ssh-agent** is automatically started at login. In most cases, private keys located in your `~/.ssh/` directory (such as `id_ed25519` or `id_rsa`) are also automatically added to the agent, thanks to integration with GNOME Keyring.

If a key is protected with a passphrase, Ubuntu will prompt you to unlock it using a graphical dialog — and optionally let you cache it for the duration of your session. This allows secure, convenient authentication to SSH servers without manually running **ssh-add**.

If not automatically added, you can manually load your keys using `ssh-add`:

```bash
ssh-add ~/.ssh/id_ed25519
```

You’ll be prompted for your passphrase once. After that, the agent keeps the key in memory for the rest of the session. To view the keys currently held by the agent:

```bash
ssh-add -l
```

By default, ssh-add looks for the following files:

```bash
~/.ssh/id_rsa
~/.ssh/id_dsa
~/.ssh/id_ecdsa
~/.ssh/id_ed25519
~/.ssh/identity
```

Your private key never leaves your local system. Even when accessing remote systems, the agent can forward its authentication socket securely over SSH, enabling access to keys without copying them. This ensures authentication data stays local, and passphrases are never transmitted over the network.

You can also manually start the agent in a shell session with:

```bash
eval $(ssh-agent)
ssh-add
ssh-add -l
```

To remove all identities from the agent (useful for clean-up or debugging)
```bash
ssh-add -D
```

### 3.3.2 Importing and Copying SSH Keys

Ubuntu provides a few handy utilities to streamline the management and distribution of SSH public keys.  We previously discussed `ssh-copy-id`, which copies a local public key to a remote system’s authorized_keys file.

Another helpful tool is:

**`ssh-import-id`**

The `ssh-import-id` tool allows you to import public keys from online identity providers. It’s especially useful on fresh Ubuntu installs or cloud instances where you want to quickly pull your key from a trusted source.

Common usage examples:

```bash
ssh-import-id gh:your-github-username
ssh-import-id lp:your-launchpad-username
```

This will fetch the public SSH keys you’ve published on GitHub or Launchpad and add them to your local ~/.ssh/authorized_keys — making it ideal for automated setups or cloud-init workflows.

**NOTE:** You can preconfigure ssh-import-id in Ubuntu cloud images using cloud-init for automated provisioning.


### 3.3.3 Using rsync with ssh

We can use SSH with rsync for data transfer, ensuring your data is being transferred securely. 

To copy a file from a remote server locally: 

```bash
rsync -azvPe ssh user@10.10.10.10:/path-to/file.txt /tmp/
```

To copy a file from the local machine to a remote location:

```bash
rsync -azvPe ssh file.txt user@10.10.10.10:/pathto/backups/
```

## 3.4 OpenSSH Server Configuration

The main configuration file for the OpenSSH server daemon on Ubuntu is:

```bash
/etc/ssh/sshd_config
```

This file controls how the SSH server behaves — including authentication methods, login permissions, and networking options.

Don’t confuse it with `/etc/ssh/ssh_config`, which configures the OpenSSH client (which is used by the OpenSSH client when connecting to other systems).

By default, the **SSH** daemon listens on **port 22**, but this can be changed for obscurity or port-based firewall rules:

```bash
Port 2222
```

### 3.4.1 SSH Hardening Recommendations

To increase the security of your SSH server, consider adjusting the following settings in `sshd_config`:

* Limit which users can log in:

```bash
AllowUsers alice bob
```

This prevents unauthorized or poorly secured accounts from accessing the system.

* Disable SSH login as root:

```bash
PermitRootLogin no
```

This reduces the attack surface, as root is a common brute-force target.

* Require SSH keys instead of passwords:

```bash
PasswordAuthentication no
```

This enforces stronger authentication and eliminates password guessing.

* Prevent login with empty passwords:


```bash
PermitEmptyPasswords no
```

This is the default behavior on Ubuntu, but it’s good practice to make it explicit.

* Restrict which interfaces SSH listens on:

```bash
ListenAddress 192.168.1.100
```

By default, SSH binds to all interfaces. This setting can be used to limit exposure to specific networks.


* Always test changes in a second terminal before restarting SSH:
  
```bash
sudo systemctl restart ssh
```

A mistake in `sshd_config` could lock you out of your system, especially if you’re working over **SSH**.

## 3.5 SSH Client Configuration Files

SSH supports both user-specific and system-wide configuration files to simplify and customize connections.

* User configuration:

`~/.ssh/config` which applies only to the current user. Commonly used to define shortcuts for frequent connections.

* System configuration:

`/etc/ssh/ssh_config` which applies system-wide to all users (client behavior). Rarely edited in day-to-day SSH use.

Each block in the SSH config file can define settings like hostname, port, user, and key path, which are automatically applied when you use ```ssh <host-alias>```.

Here’s an example that works without overrides, assuming you’re using the default ubuntu user and standard SSH key path (~/.ssh/id_ed25519 or ~/.ssh/id_rsa):

```bash
Host labvm
  HostName 192.168.101.50
```
With this, running:

```bash
ssh labvm
```

is equivalent to:

```bash
ssh ubuntu@192.168.101.50
```
### 3.5.1 Typical Use Cases

There are cases where you might want to customize connection behavior:

* You use a different username on the target host:

```bash
User myadmin
```

* You authenticate with a non-default key:

```bash
IdentityFile ~/.ssh/id_custom
```

* You use a non-standard port:

```bash
Port 2222
```

These changes are especially useful when managing connections to multiple servers with varying access methods.

## 3.6 Port forwarding

### 3.6.1 Local port forwarding

This specifies that the given port on the local (client) host is to be forwarded to the given host and port on the remote side. 

For example, imagine you need to securely access a service that is only available inside a partner or internal network — such as a database or web dashboard — and it’s not directly reachable from your current location. In this case, you can create a secure **SSH** tunnel through a server that can reach the target service, and forward the connection locally. This allows you to interact with the service as if it were running on your own machine.

Another common use case is when a service on the remote server does not natively support encrypted connections. In such cases, local port forwarding can be used to wrap that traffic inside an encrypted SSH tunnel.

The local port forwarding command template looks like this:

```bash
ssh -L local_port:remote_address:remote_port username@ssh_server
```

![local port forward](./images/local_port_forward.png)

Let’s consider an example with a PostgreSQL database on a remote server. There is no way the client can connect directly to this database but can access the server via SSH. So with SSH local port forwarding, the client connects to the remote server and commands SSH to forward the client’s local port 5432 to the server’s local port 5432. Thus, when a client process connects to the port 5432 of the client, SSH forwards the connection to the local port 5432 of the remote server, running PostgreSQL. 

![local port forward](./images/local-port-forward.png)

### 3.6.2 Remote port forwarding

This specifies that the given port on the remote (server) host is to be forwarded to the given host and port on the local side. 

Let’s take an example. Someone is developing a web application on their local machine, but they want to show it to someone outside their local network. This is just an example to showcase the feature, generally it is not recommended to let others access your system - for this example you’d usually prefer to push to a hosting service or cloud instance. They do not have a public IP, and NAT is not a solution in this case. The solution here is to do remote port forwarding on another server that is publicly accessible. 

```bash
ssh -R remote_port:remote_address:local_port username@ssh_server
```

First he needs to specify the port on which the remote server will listen, which in
this case is `9000`. Next follows `localhost` for the local machine, and the local
port `3000`.

![remote port forward](./images/remote_port_forward.png)

### 3.6.3 SSH Jump Hosts and ProxyJump

In many environments, direct SSH access to a remote host may not be possible due to security policies or network segmentation. Instead, you may be required to connect through an intermediate machine — often referred to as a jump host or bastion host that has access to the internal system.

To simplify this, **OpenSSH** supports the use of jump hosts via the -J option (`ProxyJump`), which transparently routes your SSH connection through one or more intermediary hosts.

While local and remote port forwarding focus on securely accessing individual ports or services, using a jump host with `ProxyJump` provides a cleaner and more scalable way to route entire SSH sessions through intermediary servers, especially when direct access to the target host is restricted.

Let’s take an example: you are working from a local machine (LABHOST) and want to access a remote internal server (`INTERNALVM`), but it can only be accessed via another server (LABVM).

`ssh -J ubuntu@LABVM ubuntu@INTERNALVM`

This command first connects to LABVM and then automatically jumps to `INTERNALVM`, maintaining a secure connection end-to-end. No manual login chaining is required.

If you frequently use the same jump setup, you can define it in your SSH client config file (`~/.ssh/config`) like so:

```bash
Host internalvm
  HostName 192.168.100.50
  User ubuntu
  ProxyJump ubuntu@192.168.101.50
```

Now you can connect with a single, simplified command:

```bash
ssh internalvm
```

This approach is often used to:

* Access private servers in cloud or data center environments
* Securely reach systems behind NAT or firewalls
* Standardize multi-hop SSH connections
* This is especially useful in enterprise environments where jump/bastion hosts are required for compliance or segmentation.

**Note:** The older `ProxyCommand` method (e.g., `ssh -o ProxyCommand="ssh -W %h:%p user@jump"`) was used before `OpenSSH 7.5.` `ProxyJump` is now the recommended and easier alternative.

**Advanced:** OpenSSH also supports multiple jump hosts (`ssh -J jump1,jump2 target`) and conditional logic using `Match exec` in your config file, though those are beyond the scope of this guide.


## 3.7 SSH Lab

In this lab you will work with OpenSSH. The following variables, used in the lab, are
defined as follows:

`LABHOST` - the assigned lab host that the student logs in to.
`LABVM` - the virtual machine set up by the student and used for the class.
`INTERNALVM` - the internal virtual machine accesible only from `LABVM`.


### 3.7.1 SSH Key Generation

1. From the `LABHOST` machine, we will connect to the `LABVM` without password by importing the ssh keys:

```bash
export LABHOSTIP=192.168.101.1
export LABVMIP=192.168.101.50
export INTERNALVMIP=192.168.101.51
echo "LABHOSTIP=192.168.101.1" >> ~/.bashrc
echo "LABVMIP=192.168.101.50" >> ~/.bashrc
echo "INTERNALVMIP=192.168.101.51" >> ~/.bashrc
export USER=ubuntu
```

2. Generate the local keys.

```bash
ssh-keygen
```

> Use the default options by hitting ENTER.

3. List the keys in `~/.ssh/`:

```bash
ls -al ~/.ssh/
```

### 3.7.2 sshd, ssh-agent, ssh-add, ssh-import-id and ssh-copy-id

`ssh-add` keeps your private keys safe.

`ssh-import-id` imports public keys from specified ssh servers and adds them
to the local `authorized_keys` file.

`ssh-copy-id` does what `ssh-import-id` does but in reverse, it copies a local
public identity to a remote server's `authorized_keys` file.


1. Copy the public key on the remote `LABVM` machine with the `ssh-copy-id` command, password is `ubuntu`:

```bash
ssh-copy-id ubuntu@$LABVMIP
```

```bash
ssh $LABVMIP
```

> This can also be done manually by copy/pasting the public key  `~/.ssh/id_rsa.pub` or `~/.ssh/id_ed25519.pub` from `LABHOST` to `LABVM` in `~/.ssh/authorized_keys`.


2. Go back on the `LABHOST`:

```bash
exit
```

3. Check if `sshd` is running.

```bash
systemctl status ssh
```

4. Check if `ssh-agent` is running, if not, start it:

```bash
ps -el | grep ssh-agent
```

```bash
# start the agent
eval $(ssh-agent)
```

**Note:** On a typical Ubuntu Desktop system, `ssh-agent` is automatically started as part of the graphical session (via GNOME Keyring). You only need to start it manually like this (`eval $(ssh-agent)`) when working in environments like **VMs, headless servers, or terminal-only sessions** where no graphical session is present.

5. Add your key to `ssh-agent`.

```bash
ssh-add ~/.ssh/id_rsa
```

> The private key may be protected by a passphrase. If this is the case,
the user needs to insert the passphrase in this step. This will 
decrypt the private key which is then stored in memory by the agent.

6. List the key.

```bash
ssh-add -l
```


### 3.7.3 Using SSH User Configuration to Connect with a Custom Identity

Connection information can be stored in a `config` file. This is similar
to creating an alias for a connection.

1. On the `LABVM`, create a new user:

```bash
sudo adduser myadmin
```

(Optional: Add the user to sudo group if needed.)

```bash
sudo usermod -aG sudo myadmin
```

2. On the `LABHOST`, generate a new **SSH** key pair:

```bash
ssh-keygen -t ed25519 -f ~/.ssh/id_custom
```

3. Copy the public key to the new user on `LABVM`:

```bash
ssh-copy-id -i ~/.ssh/id_custom.pub myadmin@$LABVMIP
```

4. Create the **SSH** config file:

```bash
touch ~/.ssh/config
chmod 600 ~/.ssh/config
```

5. Add a new host alias with custom settings:

```bash
tee -a ~/.ssh/config <<EOF
Host labvm
  HostName $LABVMIP
  User myadmin
  IdentityFile ~/.ssh/id_custom
EOF
```

6. Connect using the alias:

```bash
ssh labvm
```

7. Exit back to `LABHOST`:

```BASH
exit
```

### 3.7.4 Local port forwarding LAB

Forward port 443 on `LABVM` to `www.ubuntu.com` port 443 through `LABHOST` . Privileged ports up to 1024, will need `sudo` to bind them. Leave this connected, while testing. 

![local port forward](./images/local_port_forward.png)


1. On the `LABHOST` create the tunnel to `LABVM`.

```bash
sudo ssh -L 443:www.ubuntu.com:443 ubuntu@$LABVMIP
```


2. Open another terminal to `LABHOST` and install elinks browser.

```bash
sudo apt install -y elinks
```

3. Open the terminal browser to check if `www.ubuntu.com` was forwarded.

```bash
elinks https://127.0.0.1:443
```

> Close the browser with `q`.

4. Try another port. On the first terminal. where the tunnel was
initiated, close the existing connection and redo it on port `9000`.

```bash
exit
```

```bash
sudo ssh -L 9000:www.ubuntu.com:443 ubuntu@$LABVMIP
```

5. On the second terminal, open the browser again but on the new port.

```bash
elinks https://127.0.0.1:9000
```

> Close the browser with `q`.

6. On the first terminal where the SSH connection was made, close the connection.

```bash
exit
```


### 3.7.5 Remote port forwarding LAB

Remote port forwarding is useful when you need to expose a local service — such as an internal tool or staging environment — to a remote machine that cannot normally reach it directly. This allows the remote system to access local resources securely over an encrypted SSH tunnel, such as for testing or administrative access in controlled environments.

![remote port forward](./images/remote_port_forward.png)


1. Install `apache2` on `LABHOST` and create a `test.txt` file in
`/var/www/html` folder with the contents `LABHOST`.

```bash
sudo apt install -y apache2
```

```bash
cd /var/www/html
```

```bash
sudo touch test.txt
```

```bash
sudo sh -c 'echo LABHOST > /var/www/html/test.txt'
```

```bash
sudo sed -i 's/80/8080/' /etc/apache2/ports.conf
```

```bash
sudo systemctl restart apache2
```

2. Open an SSH tunnel from `LABHOST` to `LABVM` and remotely forward port `8080`:

```bash
sudo ssh -R 8080:localhost:8080 ubuntu@$LABVMIP
```

3. From `LABVM` use `curl` to fetch the test page from `http://localhost/test.txt` on port 8080:

```bash
sudo apt install -y curl net-tools
curl -v http://localhost:8080/test.txt
```

4. On the first terminal where the SSH connection was made, close the connection to exit back to `LABHOST`

```bash
exit
```

```bash
cd ~
```

### 3.7.6 SSH Jump Host Access with ProxyJump.

3.7.6 SSH Jump Host Access with ProxyJump

In this lab, you will simulate accessing a private internal VM (`INTERNALVM`) through a jump host (`LABVM`). This is a common scenario in production environments where internal systems are not directly reachable from your workstation or jump-off point (`LABHOST`).

Note: Even though `LABHOST` might be able to reach `INTERNALVM` in this lab environment, we assume for the purpose of this exercise that access is restricted, and `LABVM` is the only system allowed to connect to `INTERNALVM`.

⸻

1. On `LABVM`, create a new internal VM:

```bash
sudo cp /var/lib/libvirt/vm-disks/ubuntu.img /var/lib/libvirt/vm-disks/internalvm.img
sudo cp /home/ubuntu/cloud-init-internal.iso /var/lib/libvirt/vm-disks/

sudo virt-install \
  --name internalvm \
  --ram 1024 \
  --vcpus 1 \
  --disk path=/var/lib/libvirt/vm-disks/internalvm.img,format=qcow2,bus=virtio \
  --disk path=/var/lib/libvirt/vm-disks/cloud-init-internal.iso,device=cdrom \
  --os-variant ubuntu24.04 \
  --network bridge=nat-virbr2,model=virtio \
  --graphics none \
  --console pty,target_type=serial \
  --import \
  --noautoconsole
```

Wait for the VM to boot. You can monitor with virsh console internalvm.

2. From `LABVM`, confirm you can SSH into `INTERNALVM`:

```bash
ssh ubuntu@$INTERNALVMIP
```

3. From `LABHOST`, use ProxyJump to SSH into `INTERNALVM` via `LABVM`:

```bash
ssh -J ubuntu@$LABVMIP ubuntu@$INTERNALVMIP
```

4. (Optional) Configure the jump in your `LABHOST`'s SSH client config:

```bash
tee -a ~/.ssh/config <<EOF
Host internalvm
  HostName $INTERNALVMIP
  User ubuntu
  ProxyJump ubuntu@$LABVMIP
EOF

chmod 600 ~/.ssh/config
```

5. Now, from `LABHOST` connect using the shortcut:

```bash
ssh internalvm
```

Once logged in you'll be at `INTERNALVM` prompt.

```bash
ubuntu@internalvm:~$
```

6. Exit back to `LABHOST`:

```bash
exit
```


# 4. Boot and System Initialization !heading

`Description:`

In this section you will learn to:
* Understand the GRUB2 bootloader and boot configuration
* Recognize LVM root setups during boot
* Manage services and units with systemd
* Troubleshoot startup and service issues
* Schedule tasks using systemd timers and legacy tools
* Work with Hardware Enablement (HWE) kernels

## 4.1 What is GRUB2?

Modern Ubuntu systems typically use **UEFI firmware** in combination with **GPT** (**GUID Partition Table**) disk layout. In this setup, the UEFI firmware reads the **EFI System Partition** (**ESP**), which contains the bootloader, usually **GRUB2**. GRUB2 is then responsible for presenting the boot menu, loading the kernel and initrd, and starting the operating system.

In **older BIOS-based systems**, the **MBR** (**Master Boot Record**) is used to store the initial bootloader code. If nothing is written to the MBR, the BIOS cannot locate a bootable system. Legacy operating systems and GRUB in BIOS mode, write initial boot code to the MBR to enable booting from the disk.

`GRUB2`, the default boot loader and manager for Ubuntu, loads before any operating system. It supports both BIOS/MBR and UEFI/GPT systems, and is capable of booting multiple OSes. GRUB2 loads its modular components as needed, based on configuration and environment.

 Menu display behavior is generally determined by settings in `/etc/default/grub`.

As the system starts, GRUB2 either presents a boot menu and waits for user input or automatically boots into a default operating system kernel. GRUB2 is a complete rewrite of the original GRUB, with increased flexibility, better scripting support, and enhanced platform compatibility.

**GRUB2 Features**

* Scripting support (including conditional logic and functions)
* Dynamic module loading
* Rescue mode
* Support for custom menus, themes, and graphical boot interfaces
* Boot ISO images directly from disk
* Non-x86 platform support (e.g., ARM64)
* Full support for UUIDs

**GRUB2 and LVM Root Setups**

Ubuntu systems can be installed using **LVM** (**Logical Volume Manager**) to manage the root (`/`) filesystem. In these cases, GRUB2 needs to be able to read from logical volumes in order to locate the kernel and initrd. GRUB handles this by loading the `lvm.mod` module at boot time, which allows it to read LVM metadata and access `/boot` and `/` if they reside on logical volumes.

When using full LVM setups, it is generally recommended to keep `/boot` on a non-LVM partition, but GRUB2 is capable of booting even from LVM-based root filesystems as long as the necessary modules are included in the configuration.

GRUB2 Configuration Structure:

* `/etc/default/grub` – Default menu and boot parameters
* `/etc/grub.d/` – Scripts used to build the final GRUB menu
* `/boot/grub/grub.cfg` – Generated menu configuration used at boot

**NOTE:** Do not edit this file directly; it is regenerated.

Changes should be made in `/etc/default/grub` or in `/etc/grub.d/`. After making changes, run:

```bash
sudo update-grub
```
This command reads the configuration from both `/etc/default/grub` and the scripts in `/etc/grub.d/`, then generates the updated `/boot/grub/grub.cfg` file.

GRUB2 Configuration Workflow:

1. You modify settings in `/etc/default/grub` or `/etc/grub.d/*`
2. Run `sudo update-grub`
2. GRUB regenerates `/boot/grub/grub.cfg` with your changes

## 4.2 GRUB2 LAB

### 4.2.1 GRUB2 Configuration

Make sure to run the following exercises from `LABVM`.

In this lab you will work with the `GRUB2`  boot loader.

1. See the help at the top of the file `/etc/default/grub`.

```bash
ssh labvm
info -f grub -n 'Simple configuration'
```

2. Check what is in the `/etc/default/grub` file:

```bash
cat /etc/default/grub
```


3. Check all the menu entries that are available for boot.

```bash
sudo awk -F\' '$1=="menuentry " {print i++ " : " $2}' /boot/grub/grub.cfg

# output
0 : Ubuntu
```

> In my case there is only one menu entry, so I can boot only one kernel.

> Note that depending on the time, you may have more than one entry.


4. The current booted kernel can also be set as default. This is useful
if you want to always boot a specific kernel version, even if there are newer
versions.

```bash
sudo apt install -y vim
```

**NOTE**: The default editor in Ubuntu is nano, however, you can use other text editors such as `vim`.

```bash
sudo rm /etc/default/grub.d/50-cloudimg-settings.cfg
sudo vim /etc/default/grub
```

> Change `GRUB_DEFAULT` to the following

> Add `GRUB_SAVEDEFAULT="true"`

> On boot, usually `GRUB` menu is either not displayed or displayed for 5
seconds. You can change both settings - to always display for `X` seconds.
Set `GRUB` timeout to 10 seconds

> Turn on the `GRUB` menu display

```ini
GRUB_DEFAULT="saved"
GRUB_SAVEDEFAULT="true"
GRUB_TIMEOUT=10
GRUB_TIMEOUT_STYLE="menu"
```

> The menu display is controlled by this option. Common values are `menu` or `hidden`.


1. Update `GRUB` to reflect the latest changes.

```bash
sudo update-grub
```


### 4.2.2 Console Connection

Right now there is no way for us to see the GRUB menu on the libvirt console.
Let's change that.

1. The default connection is local display. Change it to serial. This way
we are able to see the serial console with `libvirt`.

```bash
sudo tee /etc/default/grub <<EOF
GRUB_DEFAULT="saved"
GRUB_SAVEDEFAULT="true"
GRUB_TIMEOUT_STYLE="menu"
GRUB_TIMEOUT=10
GRUB_RECORDFAIL_TIMEOUT=\$GRUB_TIMEOUT
GRUB_DISABLE_SUBMENU=y
GRUB_DISTRIBUTOR=`lsb_release -i -s 2> /dev/null || echo Debian`
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
GRUB_CMDLINE_LINUX="console=tty0 console=ttyS0,115200n8 rootdelay=60"
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"
GRUB_GFXMODE='auto'
EOF
```

2. Take a look at the current GRUB config.

```bash
sudo cat /etc/default/grub
```

3.  Update `GRUB` to reflect the latest changes.

```bash
sudo update-grub
```

4. Log out of `LABVM` back to `LABHOST`.

```bash
exit
```

5. Connect to the `LABVM` via the console and log in. Username and password
are `ubuntu`.

```bash
virsh console ubuntu
# output
Connected to domain ubuntu
Escape character is ^]

ubuntu login: ubuntu
Password: ubuntu
```

6. From the `LABVM` console, reboot and observe the console and the `GRUB` menu.

```bash
sudo reboot
```

**NOTE**: Hit `ENTER` when prompted `Press any key to continue...`.


### 4.2.3 Using HWE Kernels to Test Alternate Versions

Ubuntu LTS releases provide two supported kernel tracks:

* **General Availability (GA)** kernel: The default, stable kernel version that ships with the LTS release. This kernel receives security and bugfix updates but does not change major versions.
* **Hardware Enablement (HWE)** kernel: A newer kernel from a non-LTS release that has been backported to the current LTS. It provides improved hardware support and features, especially useful for newer devices.

This lab demonstrates how to install and boot into the HWE kernel to compare multiple supported kernel versions via the GRUB boot menu.

**Note:** This is a supported and safe way to test newer kernel versions, without manually downloading .deb files or using unsupported kernels from the Ubuntu Mainline PPA repository. The Mainline PPA provides upstream Linux kernel builds maintained by Canonical for testing purposes. These kernels are **not officially supported**, receive no security updates, and are **not integrated with the Ubuntu kernel stack**. They are intended for developers, hardware debugging, and regression testing only.

Make sure you are on the `LABVM`.

1. Check the currently running kernel version:

```bash
uname -r
```

This should show something like `6.8.0-XX-generic`, which is the default GA kernel on Ubuntu 24.04.

2. Install the HWE kernel:

```bash
sudo apt update
sudo apt install --install-recommends linux-generic-hwe-24.04
```
This will install the latest HWE kernel available for Ubuntu 24.04. The system will now have **two bootable kernel versions**.

3.  List installed kernel packages:

```bash
dpkg --list | grep linux-image
```
You should see two different kernel versions — one GA, one HWE.

4. Check the menu entries, you should see more than one.

```bash
sudo awk -F\' '$1=="menuentry " {print i++ " : " $2}' /boot/grub/grub.cfg
```
5. Modify GRUB settings to allow kernel selection:
   
```bash
sudo nano /etc/default/grub
`````
In this case, we are using nano, the default editor in Ubuntu.

```bash
GRUB_DEFAULT="saved"
GRUB_SAVEDEFAULT="true"
GRUB_TIMEOUT=10
GRUB_TIMEOUT_STYLE="menu"
```
If you made changes, update GRUB:

```bash
sudo update-grub
```

6. Reboot and choose the kernel from the GRUB menu:

```bash
sudo reboot
```
During boot, press a key when prompted to display the GRUB menu. Select your desired kernel version from the list.


7. Connect to the `LABVM` via the console and log in. Username and password
are `ubuntu`.

```bash
virsh console ubuntu
# output
Connected to domain ubuntu
Escape character is ^]

ubuntu login: ubuntu
Password: ubuntu
```
confirm which kernel is now running:
```bash
uname -r
```
You can observe the new kernel loading from the console

8. From the `LABVM` console, reboot and observe the console and the `GRUB` menu.

```bash
sudo reboot
```

Type `Ctrl + ]` to exit.

NOTE: If you want to know more about the HWE release cycle and supported kernel versions check [Ubuntu Kernel Lifecycle](https://ubuntu.com/kernel/lifecycle)

## 4.3 Advanced systemd Usage

`systemd` is a system and service manager for Linux operating systems. It provides aggressive parallelization capabilities, uses socket and D-Bus activation for starting services, offers on-demand starting of daemons, keeps track of processes using Linux control groups, maintains mount and automount points, and implements an elaborate transactional dependency based service control logic. It also includes a logging daemon utilities to control basic system configuration like the hostname, date, and locale. 

`systemd` manages various aspects of system state, including logged-in users, containers, virtual machines, system accounts, and runtime directories.

It also includes daemons for managing network configuration, time synchronization, log forwarding, and name resolution. 

`systemd` is the default init process. When run as the first process on boot (as PID 1), it acts as the init system that brings up and maintains userspace services. 

When run as a system instance, `systemd` interprets the configuration file `/etc/systemd/system.conf` and the files in the /etc/systemd/system.conf.d directory. When run as a user instance, systemd interprets the configuration file `user.conf` and the files in `user.conf.d` directories. 

`systemd` unit files built into packages are found in `/lib/systemd/system/<unitname>.service`, but can be overridden by creating override files in `/etc/systemd/system/<unitname>.service.d/` directory. The file names have to end in `.conf` extension. 

Another option to edit such overrides more comfortably is:

```shell
sudo systemctl edit <foo>
```
This opens a drop-in override file for the service under `/etc/systemd/system/<foo>.service.d/`, allowing customizations without editing the base unit.

You can view the full, merged content of a unit file including any overrides using:

```bash
systemctl cat <foo>
```
This is especially useful for inspecting how a unit is built and which parts have been customized.

### 4.3.1 Systemd Units

Units are the representation of system resources that can be managed by
systemd. They are similar to services but encompass much more. Units can
be used to abstract services, network resources, devices, filesystem mounts,
and isolated resource pools.

Unit types include:
	* *.service – System services
	* *.socket – Socket-activated services
	* *.mount – Filesystem mount points
	* *.timer – Scheduled tasks
	* *.target – Grouping and dependency management

You can find detailed descriptions of each unit type in:
	* [systemd.service(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.service.html)
	* [systemd.timer(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.timer.html)
	* [systemd.mount(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.mount.html)
	* [systemd.target(5)](https://www.freedesktop.org/software/systemd/man/latest/systemd.target.html)

NOTE: For a full reference on unit file types and syntax, see the official documentation: [systemd.unit(5) man page](https://www.freedesktop.org/software/systemd/man/latest/systemd.unit.html)

Units are separated into component units according to function which makes it easy to enable, disable, or extend functionality without modifying the core behavior of a unit. 

Example Systemd Unit File 

The following example defines a service **foo**, in a file named `/lib/systemd/system/foo` service: 

```ini
[Unit]
Description=Unit that runs the foo daemon
Documentation=man:foo(1 )
[Service]
Type=forking
Environment=statedir=/var/cache/foo
ExecStartPre=/usr/bin/mkdir -p ${statedir}
ExecStart=/usr/bin/foo-daemon --arg1 "hello world" --statedir ${statedir}
[Install]
WantedBy=multi-user.target
```
> `ExecStartPre` runs before the main command and is useful for setup tasks.

You can explore how a unit relates to other components in the system using:

```bash
systemctl list-dependencies <unit>
```

This command displays the **unit dependency tree**, listing other units it either requires (must have) or wants (optional but desirable).

* Requires= means the unit **cannot start** without the dependency.
* Wants= means the dependency is desirable but **not mandatory**.

For example:

```bash
systemctl list-dependencies libvirtd.service
```
This shows all systemd units `libvirtd.service` depends on such as sockets, D-Bus interfaces, or networking targets.

You can add `--reverse` to see which units depend on the given one:

```bash
systemctl list-dependencies --reverse libvirtd.service
```
### 4.3.2 Managing Units with systemctl

Once a unit file (such as a service) exists, you can control its behavior using `systemctl`:

| Command                         | Description                                           |
|----------------------------------|-------------------------------------------------------|
| `sudo systemctl start <unit>`         | Starts the unit immediately (but not on reboot)       |
| `sudo systemctl stop <unit>`          | Stops the running unit                                |
| `sudo systemctl restart <unit>`       | Restarts the unit if running, or starts it if stopped |
| `sudo systemctl reload <unit>`        | Reloads the unit’s config without stopping it (if supported) |
| `sudo systemctl enable <unit>`        | Enables the unit to start automatically at boot       |
| `sudo systemctl disable <unit>`       | Prevents the unit from starting at boot               |
| `sudo systemctl status <unit>`        | Shows status, recent logs, and active state info      |
| `sudo systemctl is-enabled <unit>`    | Checks whether the unit is enabled to start at boot   |

> Use `enable` to persist across reboots, and `--now` to activate immediately:
> 
> ```bash
> sudo systemctl enable --now myservice.service
> ```

### 4.3.3 Logging

`systemd-journald` is the component responsible for collecting, managing, and persisting log data from services, the kernel, and various subsystems in Ubuntu.

Unlike older systems that relied solely on `rsyslog` and text-based `/var/log/*` files, `journald` collects logs in a structured binary format, allowing rich querying, filtering, and boot-based separation of log history.

By default, journal logs are stored in memory and persist only until reboot. This behavior is due to journald using `/run/log/journal/` by default. To persist logs across reboots, create `/var/log/journal`.

The `journalctl` tool allows filtering logs by `time`, `service`, `severity`, and `boot` session as we’ll see in the lab that follows.

### 4.3.4 Troubleshooting systemd

To print a list of all running units, ordered by the time they took to initialize, you can run the following command. This information may be used to optimize boot-up times. Note that the output might be misleading at first as the initialization of one service might be slow simply because it waits for the initialization of another service to complete. 

```bash
systemd-analyze blame
```

To print an SVG graphic detailing which system services have been started at what time, 
highlighting the time they spent on initialization: 

```bash
systemd-analyze plot > plot.svg
```

which would look like this

![systemd initialization graph](./images/systemd-initialization.png)

To enable permanent storage for logs enter:

```bash
sudo mkdir -p /var/log/journal
sudo killall -USR1 systemd-journald
```

## 4.4 systemd LAB

Make sure you are on the `LABHOST`.

### 4.4.1 Manage services

1. List all units that are services.

```bash
systemctl list-units --type=service
```

2. List only the running services.

```bash
systemctl list-units --type=service --state=running
```

3. You can also look for services that contain a specific name. 

```bash
systemctl -a | grep ssh
```

4. Stop the `libvirtd.service` service. (This will disconnect your LABVM.)

```bash
sudo systemctl stop libvirtd.service
```

5. View the current status of the `libvirtd.service`.

```bash
sudo systemctl status libvirtd.service
```

6. Start the `libvirtd.service` process.

```bash
sudo systemctl start libvirtd.service
```

7. Show the current status of the `libvirtd.service`.

```bash
sudo systemctl status libvirtd.service
```


8. Inspect the configuration of the `libvirt` service.

```bash
systemctl cat libvirtd.service
```

9. List the dependencies of `libvirt`.

```bash
systemctl list-dependencies libvirtd.service
```

> As can be seen, the dependencies are listed as `Wants` or
`Requires` in the unit config.


10. Show all the low-level information about the unit.

```bash
systemctl show libvirtd.service
```

11. Shows a list of systemd units (typically services) that have failed to start or run properly.
    
```bash
systemctl --failed
```

12.  Which services are CPU hogs?

```bash
systemd-analyze blame
```

### 4.4.2 Logging

The `systemd` component that collects and manages journal entries (logs) from system components is
called `journald`. 


1. View all available logs across all boots:

```bash
sudo journalctl
```
This displays everything journald has ever collected. Use with care on systems with large logs.


2. Show logs only from current boot.

```bash
sudo journalctl -b
```
You can also view logs from previous boots using a numeric argument:

```bash
journalctl -b -1    # Previous boot
journalctl -b -2    # Two boots ago
```
To see a list of all boots recorded:

```bash
journalctl --list-boots
```

3. View only kernel messages from the current boot:

```bash
sudo journalctl -k
```

```bash
sudo journalctl -k -b -2 # kernel messages from two boots ago
```

4. Optional filters: Find denied AppArmor actions (security events):

```bash
sudo journalctl -k -b | grep 'apparmor="DENIED"'
```


5. View logs from a specific service (unit):

```bash
sudo journalctl -u ssh.service
sudo journalctl -u libvirtd.service
```
These commands show logs generated by the specified unit, across all boots. You can combine this with `-b` or `--since` to limit the timeframe.

6. To make journal logs persist across reboots:

```bash
sudo mkdir -p /var/log/journal
sudo systemctl restart systemd-journald
```
This creates persistent storage and ensures logs are retained between boots.

**Note on sudo:** By default, unprivileged users can only view logs from their own sessions. To view full system logs, especially kernel logs or services running as root, you may need to prefix `journalctl` with sudo, or ensure your user is part of the `systemd-journal` group.


### 4.4.2 Create a custom service

In this lab we will create a simple systemd service.

Make sure you are on the `LABVM` machine.

1. Connect to the `LABVM` if you are not there yet.

```bash
ssh 192.168.101.50
```

2. Create the script that will be our service and make it executable.


```bash
touch ~/service.sh
```

```bash
sudo tee ~/service.sh <<'EOF'
#!/bin/bash

DATE=$(date '+%Y-%m-%d %H:%M:%S')
echo "Service started at ${DATE}"

while :
do
  echo "Service is running...";
  sleep 30;
done
EOF
```

```bash
sudo chmod +x ~/service.sh
```

3. Create the unit config file to define it.

```bash
sudo tee /etc/systemd/system/myservice.service <<EOF
[Unit]
Description=This is an example of a simple systemd service.

[Service]
Type=simple
ExecStart=/bin/bash /home/ubuntu/service.sh

[Install]
WantedBy=multi-user.target
EOF
```

4. Give the file permissions.

```bash
sudo chmod 644 /etc/systemd/system/myservice.service
```

5. Start and enable the service.

```bash
sudo systemctl start myservice.service
```

```bash
sudo systemctl enable myservice.service
```

6. Check the status of the service.

```bash
sudo systemctl status myservice.service
```

7. Check the service logs.

```bash
sudo journalctl -u myservice.service
```

8. Stop the service.

```bash
sudo systemctl stop myservice.service
```

9. Disable the service.

```bash
sudo systemctl disable myservice.service
```
**Note:** Custom systemd service unit files should be created under /etc/systemd/system/.
This directory is intended for user-defined or manually managed units. In contrast, /lib/systemd/system/ is reserved for unit files installed by system packages. Keeping your custom units in /etc ensures they are not overwritten or affected by system updates, and helps maintain a clear separation between system-provided and user-defined configurations.

## 4.5 On Demand Processes

In modern Ubuntu systems, **systemd timers** are the preferred method for scheduling tasks whether they’re recurring (like cron) or one-time (like at). Timers are native to systemd and integrate seamlessly with other units and logging tools like journalctl.

A timer unit triggers a corresponding service unit at a scheduled time or under specific conditions. This is ideal for:

* Running scripts or jobs at boot
* Scheduling weekly/monthly tasks
* Delaying services until idle

Example: Run a job every week

`/etc/systemd/system/foo.timer`

```ini
[Unit]
Description=Run foo weekly

[Timer]
OnCalendar=weekly
Persistent=true

[Install]
WantedBy=timers.target
```

`/etc/systemd/system/foo.service`

```ini
[Unit]
Description=Job that does something

[Service]
ExecStart=/usr/local/bin/foo-script.sh
```
> Enable the timer:

```bash
sudo systemctl enable --now foo.timer
````

> View all timers:
```bash
systemctl list-timers
```

Timers like `OnCalendar=` and `OnBootSec=` allow time-based execution. But systemd also supports event-based activation, reacting to conditions like:

* File or directory changes (`PathExists=`, `PathModified=`)
* Network availability
* Device presence
* User logins

This makes it ideal for on-demand process activation even outside of regular time-based scheduling.

**Legacy Tools: at, batch, and cro**

While systemd timers are preferred, Ubuntu also includes traditional tools for scheduled jobs:

* at: run a one-time job at a specified time
* batch: run a job when system load permits
* atq: view pending jobs
* atrm: remove scheduled jobs

For example:

```bash
at 4pm + 3 days
```

Use these tools when systemd timers are not available or for simple quick scheduling tasks.


## 4.6 On Demand and Scheduled tasks LAB

 **Part 1: Systemd Timers (Preferred Method)**

>Modern Ubuntu systems use systemd timers to schedule tasks, either one-time or recurring. These integrate with `journald`, allow unit composition, and support powerful scheduling options.

Make sure to run the following exercises from the `ubuntu` `LABVM`.


1.	List current system timers:

```bash
systemctl list-timers
```

2.	Schedule a one-time job using systemd-run:

```bash
sudo systemd-run --on-active=1 /bin/touch /tmp/has_ran_from_systemd
```

3. Create a weekly.timer + weekly.service combo as shown previously.

**React to a File Being Created**

1. Create the path unit `/etc/systemd/system/mywatch.path`
   
```ini
[Unit]
Description=Watch for file creation in /tmp/watchme

[Path]
PathExists=/tmp/watchme
Unit=mywatch.service

[Install]
WantedBy=multi-user.target
```

2. Create the corresponding service `/etc/systemd/system/mywatch.service`
   
```ini
[Unit]
Description=Triggered when /tmp/watchme is created

[Service]
Type=oneshot
ExecStart=/bin/echo "The file appeared!" > /tmp/watched.log
```

3. Enable the path-based trigger

```bash
sudo systemctl enable --now mywatch.path
```

Now, whenever `/tmp/watchme` is created, the service will run and write to `/tmp/watched.log`.


** Part 2: Legacy Tools – at and batch**

1. Install the required programs:

```bash
sudo apt install -y at
```

2. One way to schedule jobs is to enter the `at` shell. Create a job
for 9AM, the next day.

```bash
at 09:00

# output
warning: commands will be executed using /bin/sh
at>
```

3. Jobs can also be scheduled outside the `at` shell. This can be done with the `echo` command.
Schedule a command to run in 1 minute from now.
 
```bash
echo "touch /tmp/has_ran_from_atd" | at now+1minute
```

4. List all scheduled jobs by `atd`.

```bash
atq
```

**NOTE**: wait one minute and check if the file was created.

```bash
ls -l /tmp/
```

5. Jobs can also work with scripts. Create a script and make it executable.

```bash
touch ~/job.sh
```

```bash
sudo tee ~/job.sh <<EOF
#!/bin/bash

sudo rm /tmp/has_ran_from_atd
EOF
```

6. Schedule the script to run in 1 minute.

```bash
at now+1minute -f ~/job.sh
```

**NOTE**: wait one minute and check if the file was deleted.

```bash
ls -l /tmp/
```

7.  `batch` works the same way but it will execute the job only when the
system load allows this. By default, this is below `1.5`.

```bash
echo "touch /tmp/has_ran_from_batch" | batch
```

8. Because the load averages should be almost 0, the job should run
right away. Check if the file was created.

```bash
ls -l /tmp/
```


# 5. Storage !heading

`Description:`

In this section you will learn about:
* Partitioning
* Filesystems
* Managing RAID devices with **mdadm**
* Managing the Linux Logical Volume Manager


## 5.1 Partitioning


Disk **partitioning** or disk *slicing* is the creation of one or more regions
on a hard disk or other secondary storage, so that an operating system can
manage information in each region separately. These regions are called
partitions. It is typically the first step of preparing a newly manufactured
disk, before any files or directories have been created. The disk stores the
information about the partitions' locations and sizes in an area known as the
partition table that the operating system reads before any other part of the
disk. Each partition then appears in the operating system as a distinct
"logical" disk that uses part of the actual disk. System administrators use a
program called a partition editor to create, resize, delete, and manipulate
the partitions.

### 5.1.1 Partitioning schemes

Ubuntu supports two main partitioning schemes:

**MBR (Master Boot Record)**: An older scheme with several limitations:

* Maximum of **four primary partitions** (or three primary + one extended).
* Limited to **2 TiB** maximum disk size.
* No redundancy or partition metadata.
  
**GPT (GUID Partition Table):** The modern standard used with **UEFI** systems:

* Supports **up to 128 partitions** (by default on Linux).
* Handles disks **larger than 2 TiB**.
* Stores multiple copies of the partition table for **redundancy**.
* Includes checksums for **data integrity**.

GPT is the **default and recommended** scheme for most new Ubuntu installations, offering greater flexibility, robustness, and compatibility with modern hardware.

### 5.1.2 Partitioning Tools

* `parted` - A flexible and modern partitioning tool. Supports both **MBR** and **GPT**.
`gparted` is its GUI frontend, often used in desktop or live environments.
* `fdisk` - A classic command-line partition manager for **MBR** partitions.
* `cfdisk` - A menu-driven alternative to `fdisk`, suitable for those who prefer a guided interface.
* `sfdisk` - A scriptable version of `fdisk`, ideal for automated deployments or custom install scripts.
* `gdisk` - A GPT-aware alternative to `fdisk`, useful when managing **UEFI/GPT**-based systems.

Additional tools helpful when working with disks and partitions:

* `lsblk` - Displays block devices and their hierarchy. Useful for understanding disk layout.
* `blkid` - Shows UUIDs and filesystem labels. Handy when updating `/etc/fstab` or troubleshooting mounts.
* `wipefs` - Removes filesystem or **RAID** signatures from a device. Useful when reusing disks to avoid conflicts.

> For scripting `cloud-init` or automated installs (e.g., **MAAS**, PXE boot environments), `sfdisk` and `parted` are commonly used due to their non-interactive and predictable behavior.

## 5.2 Partitioning LAB

### 5.2.1 Using `parted` for GPT partitions

Make sure you are on `LABVM` and that the secondary disk `/dev/vdb` is attached.

In this lab, we will:

1. Create a GPT partition table using parted
2. Create a new partition
3. Format it with ext4
4. Mount it and verify usage
5. Make it persistent via `/etc/fstab`
6. Reboot and verify
7. Clean up
   
1. Inspect the disk

```bash
lsblk
sudo parted /dev/vdb print
```
If the disk is uninitialized, the `print` command may show an error or empty output.

2. Use `parted` to create a GPT partition on `/dev/vdb` on `LABVM`:

```bash
sudo parted /dev/vdb
```

Inside `parted`:

```bash
(parted) mklabel gpt
Warning: this will erase all data on the disk. Proceed? Yes
```

3. Create a new primary partition (ext4, full disk)
   
```bash
(parted) mkpart primary ext4 1MiB 100%
```
> 1MiB ensures proper alignment; 100% uses all remaining space.

Then verify:

```bash
(parted) print
```
And exit:

```bash
(parted) quit
```

4. Format the new partition

```bash
lsblk -f /dev/vdb1 #it's a good practice to verify it's not already in use. (Not the case here)
sudo mkfs.ext4 /dev/vdb1
```

5. Mount the partition and check usage

```bash
sudo mkdir /mnt/data
sudo mount /dev/vdb1 /mnt/data
df -h /mnt/data
```
You should now see the mounted partition available at /mnt/data.

6. (Optional) Make the mount persistent
   
Get the partition’s **UUID**:

```bash
sudo blkid /dev/vdb1
```
Then edit `/etc/fstab`:

```bash
sudo nano /etc/fstab
```
Add this line (replace the UUID accordingly):

```ini
UUID=<your-uuid-here>  /mnt/data  ext4  defaults  0  2
```

7. Reboot and verify the partition mounts automatically
> If /etc/fstab has incorrect entries, your system may fail to boot. Always test with:

```bash
sudo mount -a
```

Then:

```bash
sudo reboot
```

After reboot:

```bash
df -h /mnt/data
```

8. Clean up
    
Remove the added entry in `/etc/fstab`:

```bash
sudo nano /etc/fstab
```

Comment or remove the line:

```ini
#UUID=<your-uuid-here>  /mnt/data  ext4  defaults  0  2
```

Unmount and wipe the partition table:

```bash
sudo umount /mnt/data
sudo wipefs  --all /dev/vdb
```
> Make absolutely sure `/dev/vdb` is the correct device before wiping.

> Note: In the next chapter we will discuss `ext4` in greater detail.

### 5.2.2 Using `fdisk` for MBR partitions

Make sure you are on `LABVM`.

1. Use `fdisk` to list the partition tables on `/dev/vdb` on `LABVM`:

```bash
sudo fdisk -l /dev/vdb
```

2. Use `fdisk` to create a primary partition on `/dev/vdb` on `LABVM`:

```bash
sudo fdisk /dev/vdb
```

This will open an interactive shell in fdisk:

Print the partition table with `p`, should be empty:

```bash
Command (m for help): p
Disk /dev/vdb: 192.5 KiB, 197120 bytes, 385 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x18d30887
```

Create a new partition with `n`:
```bash
Command (m for help): n
Partition type
   p   primary (0 primary, 0 extended, 4 free)
   e   extended (container for logical partitions)
Select (default p): p
Partition number (1-4, default 1):
First sector (1-384, default 1):
Last sector, +sectors or +size{K,M,G,T,P} (1-384, default 384):

Created a new partition 1 of type 'Linux' and of size 192 KiB.
```

Print the partition table again:
```bash
Command (m for help): p
Disk /dev/vdb: 192.5 KiB, 197120 bytes, 385 sectors
Units: sectors of 1 * 512 = 512 bytes
Sector size (logical/physical): 512 bytes / 512 bytes
I/O size (minimum/optimal): 512 bytes / 512 bytes
Disklabel type: dos
Disk identifier: 0x18d30887

Device     Boot Start   End Sectors  Size Id Type
/dev/vdb1           1   384     384  192K 83 Linux
```

Finally, make the changes persistent with `w`:
```bash
Command (m for help): w
The partition table has been altered.
Calling ioctl() to re-read partition table.
Syncing disks.
```
*Note:* fisk will create a partition table by default


3. Verify partition is there and then clean up `/dev/vdb`:

```bash
sudo fdisk -l /dev/vdb
sudo dd if=/dev/zero of=/dev/vdb bs=1M count=10
sudo fdisk -l /dev/vdb
```

> This will erase the partition table of the device `/dev/vdb`. Make sure you are running this command on the correct machine and the correct device.

> **Note:** If you’re using SSDs, enable periodic discard/TRIM support to maintain performance:
```bash
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer
```

## 5.3 RAID

RAID (redundant arrays of independent disks) is a method of using multiple
hard drives to act as one. There are many purposes of RAID:
1. Span a filesystem across multiple disk drives.
2. Improve performance by striping data across multiple drives.
3. Prevent data loss in case of drive failure.

RAID allows systems to keep functioning even if some parts fail. A RAID
combines physical disks into one logical disk for the purpose of redundancy.
Data is distributed across the drives. The RAID levels balance reliability,
availability, performance, and capacity in different configurations
depending on need. RAID levels greater than RAID 0 provide protection against
unrecoverable sector read errors, as well as against failures of whole
physical drives.

The most commonly used RAID configurations are:
* **RAID 0** - is also known as a stripe set or striped volume because it
  distributes data evenly across two or more disks without parity information,
  redundancy, or fault tolerance. With this configuration, if one drive fails,
  the entire array fails and the data is lost. This level is used for
  applications that require speed at the expense of reliability.
  > Read and write throughput scale linearly with the number of disks (N), with 100% of total capacity usable. No redundancy.
* **RAID 1** - creates an exact copy or mirror data set on two or more disks.
  Data is mirrored on all disks in the array with no parity, striping, or
  spanning across multiple disks. The capacity of the array is that of the
  smallest disk. It can read from both concurrently, hence reads are fast. But writes need to be completed on both disks. The configuration is used when read performance and
  reliability outweighs write performance or capacity.
  > Read performance can scale up to N (mirrors can be read in parallel); write performance is similar to a single disk. Usable capacity is 50%.
* **RAID 5** - requires 3 disks and uses block-level striping with distributed
  parity requiring all drives in the array but one to function. If a drive
  fails, reads can be calculated from the distributed parity without lost data.
  > Read performance scales close to N−1 disks; write performance is ~30–50% slower than RAID 0 due to parity overhead. Usable capacity is (N−1)/N.
* **RAID 6** - requires 4 disks and uses block-level striping with distributed
  double parity. This configuration can tolerate the loss of at most two
  drives. If a drive fails, reads can be calculated from the distributed parity
  without lost data or loss of redundancy.
  > Read performance scales up to N−2 disks; write performance is ~40–60% slower than RAID 0 due to dual parity. Usable capacity is (N−2)/N.
* **RAID 10** - also known as a stripe of mirrors, combines the features of RAID 1 and RAID 0 by mirroring data across pairs of disks and then striping across those mirrors. It requires an even number of disks (minimum four) and provides both redundancy and improved performance. If a disk fails, its mirror keeps the data accessible. Multiple disk failures can be tolerated as long as no mirror pair is lost entirely.
  > Read and write performance scale with the number of mirror pairs (N/2), offering throughput near that of RAID 0 with redundancy. Usable capacity is 50% of total disk space.  

**Note:** For SSDs, RAID 5/6 is generally discouraged due to high write amplification. RAID 1 or 10 are preferred for redundancy with minimal performance impact. You can compare configurations using: [raid-calculator.com](https://www.raid-calculator.com/default.aspx)

There are three ways to create a RAID:
1. **Hardware RAID**: uses a special hardware controller to manage the RAID.
   Hardware RAID is generally faster, and does not place a load on the CPU.
   These controllers typically have a dedicated processor and RAM on the
   controller for processing the RAID algorithms. The on-disk metadata and
   processing is hidden from the operating system by the controller. In order
   to use hardware RAID the OS must have support for the hardware RAID
   controller. Additionally, controller-specific monitoring software may also
   be needed. Ubuntu has drivers for many such controllers in the kernel, and
   has some support for monitoring available in the archives. If monitoring
   software for a controller is not available in the archives users should
   contact the hardware vendor.

2. **Software RAID**: Uses the main CPU and RAM for all calculations used in
   the RAID array. The metadata used to manage the array is placed on the block
   devices in the array, and is managed by the kernel and **mdadm**. RAID
   monitoring is supported by **mdadm**, when run with the `--monitor` flag.

3. **FakeRaid** aka *Motherboard RAID* is used when a hardware RAID is too
   expensive. It is a version of software RAID that is configured via the
   motherboard BIOS or firmware. As such, FakeRaids can typically be used for
   booting from GRUB. However, the metadata used in FakeRaid is dependent on
   the motherboard manufacturer, and may not be fully supported by the kernel
   and **mdadm**. As such, your results may vary when using FakeRaid with
   Ubuntu. The recommendation is to use **mdadm** software raid unless absolutely
   necessary.



### 5.3.1 Managing a software RAID

#### mdadm

**mdadm** is the standard RAID management tool. It is available in the Ubuntu
distribution.  **mdadm** has 7 major modes of operation:

#### Assemble

Assemble the parts of a previously created array into an active array.
Components can be specified or searched for. mdadm checks that the components
do form a true array, and can, on request, adjust superblock information so
as to assemble a faulty array.

#### Build

Build a legacy array without per-device superblocks.

#### Create

Create a new array with per-device superblocks. This metadata is stored on each device and describes the array layout, making it easier to detect, reassemble, or recover the array in case of a device failure.

**Note: ** This is the preferred method for most modern setups.

#### Manage

Used for doing things to specific components of an array such as adding new
spares and removing faulty devices.

#### Misc

Allows operations on independent devices such as examine MD superblocks,
erasing old superblocks and stopping active arrays.

#### Follow or Monitor

Monitor one or more MD devices and configure event notification and actions
for the array. This is only meaningful for RAID 1, 5, 6. RAID 0 or linear never have missing, spare, or failed drives, so
there is nothing to monitor.


#### Grow

Grow (or shrink) an array, or otherwise reshape it in some way. Currently
supported growth options including changing the active size of component
devices in RAID level 1/5/6 and changing the number of active devices in
RAID1.


### 5.3.2 Software RAID Drive Failures

There are two types of failures in RAID systems:

* **Resilience-reducing failures:** for example, a single disk failing in a RAID 1 or RAID 5. The array continues operating in a degraded state, but is at risk if another failure occurs.

**Operational failures:** when too many devices fail and the RAID can no longer function. In this case, the array will not activate and is considered broken or failed.

In **mdadm** and general **RAID** terminology, common array states include:

* **active:** The array is functioning normally with all expected devices

* **degraded:** One or more devices have failed, but the array is still running

* **inactive:** The array is defined but not started, or was stopped

* **failed:** The array cannot operate due to insufficient working components

These states are important when diagnosing and recovering from failures. For example, a degraded array can often be rebuilt, while a failed array may require forced assembly or partial reconstruction.

To recover a broken **RAID**, the most important step is to preserve and inspect the RAID metadata, stored in the superblocks of each device.

```bash
mdadm --examine /dev/vd[*]1 >> raid.status
```

This command collects the metadata for each device in the array and saves it to `raid.status` for review.

If the array fails to assemble automatically, check the kernel log for clues:

```bash
dmesg | grep vd
```

Replace `vd` with your actual device prefix. This might be `sd` (SCSI/SATA), `vd` (virtio), or `nvme` (NVMe SSDs), depending on the storage type in use. On cloud VMs or virtualization environments like KVM, `vda`, `vdb`, etc., are commonly used.

To manually compare metadata across devices, especially the event counts, use:

```bash
mdadm --examine /dev/vd[a-z] | egrep 'Event|/dev/'
```

This filters for lines showing each device and its associated Event count, a number that increases every time the array is modified. Devices with the highest matching count are typically the most up-to-date, allowing you to spot out-of-sync devices that may be fallen behind in the array's change history.

If you're working with `/dev/sdX` or `/dev/nvmeXn1`, adjust the device glob (`/dev/vd[a-z]`) accordingly.

A common reason why `mdadm` fails to auto-assemble an array is a mismatch in event counts: one or more devices might be lagging behind and `mdadm` avoids assembling an inconsistent array that could risk data loss. 

As a rule of thumb, if the event count differs by fewer than 50, the data is often still consistent and recoverable. However, this depends on the workload, context, and your risk tolerance. It's best to proceed with caution and first test assembly in **read-only** or **degraded** mode.

To attempt a forced assembly:

```bash
mdadm --assemble --force /dev/mdX <list of devices>
```

**Understanding /proc/mdstat**

The `/proc/mdstat` file shows a real-time snapshot of the kernel’s current RAID status:

```bash
$ cat /proc/mdstat
Personalities : [raid1] [raid6] [raid5] [raid4]
md_d0 : active raid5 vde1[0] vdf1[4] vdb1[5] vdd1[2] vdc1[1]
  1250241792 blocks super 1.2 level 5, 64k chunk, algorithm 2 [5/5] [UUUUU]
  bitmap: 0/10 pages [0KB], 1 6384KB chunk

unused devices: <none>
```

> *Note:* Visit [kernel RAID documentation](https://docs.kernel.org/admin-guide/md.html)) for more examples and
> detailed explanations.

**Key elements in the command's output:**

* **Personalities**: The RAID levels supported by the kernel either compiled in or loaded as modules. Examples:

```bash
[raid0] [raid1] [raid4] [raid5] [raid6] [linear] [multipath] [faulty]
```
> `[faulty]` is a diagnostic personality used for simulating failures.

**md_d0**: This is the device name (`/dev/md_d0`). Its status is active, meaning the array is started and in use.
* It is a RAID 5 array with 5 component devices.
* Each device is followed by a number in brackets, that corresponds to the role number inside the array:

```bash
vde1[0] vdf1[4] vdb1[5] vdd1[2] vdc1[1]
```
> These numbers denote the logical order/position in the array, not the physical device order.

A number **greater than** or **equal to the number of devices** (e.g., [5] in a 5-device RAID) typically indicates a **spare device**.

> **Note:** In this example, there’s no device [3] that role likely belonged to a failed disk. Device [5] may be a hot spare that has already taken over [3]’s role after a resync operation.


**Interpreting `[n/m]` and `[UUUUU]`**

 * `[n/m]`: Shows expected/active devices. If `m < n`, the array is degraded.
 * `[UUUUU]`: Each **U** means the device is Up. An _ indicates a missing/failed disk.

In the example we have:

```bash
[5/5] [UUUUU]
```
* First number (5) = expected number of devices
* Second number (5) = current number of active devices

In this case the array is **active** but if the output were different (i.e. [4/5]) we would be facing a degraded array without full redundancy.

**Bitmap**

The bitmap tracks which blocks were changed while the array was degraded or syncing. This allows faster resync after interruptions.

```bash
bitmap: 0/10 pages [0KB], 1 6384KB chunk
```

In this example:

* 10 bitmap pages are allocated, but 0 are in use — the array is fully synced.
* 6384KB chunk indicates the block size used for tracking.

**What is Resync and Role Swapping?**

When a failed device is replaced, the spare enters the array with a temporary high-numbered role (e.g., [5]). The kernel then resyncs data onto it from the remaining healthy disks to restore redundancy.

Once resync is complete:

* The spare inherits the role number of the failed disk (e.g., [3])
* The failed disk is removed

Until the resync is finished, the array remains in a degraded state, and protection against further failure is reduced.


## 5.4 RAID LAB

### 5.4.1 Creating a RAID setup

In this lab, we’re using RAID 5 with 5 drives, where 4 are active and 1 acts as a hot spare, to demonstrate how RAID handles drive failure and automatic rebuild.

In real-world deployments with 5 disks, RAID 6 is often recommended instead of RAID 5 + spare, as it offers double parity and can tolerate two drive failures.

The boot/OS is installed on sda1

1. Install software needed for this lab.

```bash
sudo apt install -y mdadm parted
```

2. Format all disks as gpt.

```bash
sudo parted /dev/vdb mklabel gpt
sudo parted /dev/vdc mklabel gpt
sudo parted /dev/vdd mklabel gpt
sudo parted /dev/vde mklabel gpt
sudo parted /dev/vdf mklabel gpt
```

3. Create the partition on drive `vdb` and then clone it to the other 4 drives.
Cloning saves partition information on all of the drives.

```bash
sudo parted -a optimal /dev/vdb mkpart primary ext4 1 100%
sudo parted -a optimal /dev/vdc mkpart primary ext4 1 100%
sudo parted -a optimal /dev/vdd mkpart primary ext4 1 100%
sudo parted -a optimal /dev/vde mkpart primary ext4 1 100%
sudo parted -a optimal /dev/vdf mkpart primary ext4 1 100%
```

> -a optimal: Use optimum alignment as given by the disk topology 
> information. This aligns to a multiple of the physical block size 
> in a way that avoids reading two sectors for one I/O operation - thereby avoiding a  performance impact.


5. Create the `RAID5` array with 5 drives. One drive is treated as a spare.

```bash
sudo mdadm --create --verbose /dev/md0 --level=5 \
  --raid-devices=5 /dev/vd[bcdef]1
```

6. Watch and wait for the `RAID5` creation status. The creation might take a some time.

```bash
watch cat /proc/mdstat
```

7. On completion check the RAID status.

```bash
cat /proc/mdstat
```

8. Examine the RAID disk with the **mdadm** command and look for events.

```bash
sudo mdadm --examine /dev/vd[b-f]1
```

9. Examine RAID device details:

```bash
sudo mdadm --detail /dev/md0
```

10. Check for errors in RAID creation with dmesg.

```bash
sudo dmesg | grep vd
```

11. More tuning may be needed to configure the RAID to your taste - look up other RAID documentation using **mdadm --help** or view the manual page:

```bash
man mdadm
```

### 5.4.2 Removing a RAID

Removing a RAID array isn’t inherently _technically difficult_, but it **requires care** to ensure no metadata is left behind that could cause problems during future disk reuse or automatic array assembly. Failure to properly stop and clean all array components may result in unexpected behavior, such as mdadm trying to reassemble the array on reboot.

To properly remove a RAID:

1. Stop the RAID.

This deactivates the RAID device and unmounts it if it was in use.

```bash
sudo mdadm --stop /dev/md0
```

2. Wipe the RAID metadata from each device

This is often referred to as “zeroing out” the superblock. The **superblock** is a small section of metadata written by mdadm to each component device of the array. It stores the array’s UUID, member role, state, and more. If not cleared, the device may still be recognized as part of a (possibly broken) array.

```bash
sudo mdadm --zero-superblock /dev/vdb1
sudo mdadm --zero-superblock /dev/vdc1
sudo mdadm --zero-superblock /dev/vdd1
sudo mdadm --zero-superblock /dev/vde1
sudo mdadm --zero-superblock /dev/vdf1
```
 **Note:** If a device was part of a degraded or previously failed array, mdadm may still detect it on future boots if the superblock isn’t removed.

3. Clean up the configuration file

During array creation or scan operations, the system may automatically populate the `/etc/mdadm/mdadm.conf` file (or `/etc/mdadm/mdadm.d/*.conf` in newer systems) with definitions of active arrays.

While it might seem safe to delete this file in the lab (since no other arrays exist), it’s better to just remove the specific ARRAY line.

```bash
grep ARRAY /etc/mdadm/mdadm.conf
```
If present, manually remove or comment out only the line that defines `/dev/md0` in `/etc/mdadm/mdadm.conf`.

```bash
sudo nano /etc/mdadm/mdadm.conf
```

Or, if you’re using an include directory like `/etc/mdadm/mdadm.d/`, clean up the relevant file there.

**Note:** While reviewing mdadm.conf, note the MAILADDR directive:

```bash
MAILADDR root
```
> This allows `mdadm` to send alerts if a device fails or the array enters a degraded state. Always ensure alerting is configured properly by this or other means.

**Note:** While software RAID is flexible and useful for learning, lab setups, or cloud/virtual environments, hardware RAID is often preferred in production for its performance benefits, caching support, and improved fault isolation. When using SSDs, avoid RAID levels with high write amplification (like RAID 5/6). Prefer RAID 1 or 10, and ensure TRIM support is enabled.

## 5.5 Advanced LVM

![Linux Logical Volume  Manager](./images/lvm.png)

**Logical Volume Manager (LVM)** provides a flexible alternative to traditional disk partitioning. Instead of dividing a disk into fixed partitions, LVM uses **volume groups (VGs)**, storage pools composed of one or more **physical volumes (PVs)**. **Logical volumes (LVs)** are then created from these pools and typically formatted with a filesystem such as `ext4` for use by the operating system.

Logical volumes:

* Are named (rather than numbered)
* Can span multiple disks
* Do not need to be physically contiguous

> **Note:** It’s recommended to leave free space in volume groups. This allows for logical volume expansion, snapshot creation, and data migration if volume layout changes are required.

**LVM** can also be used on top of **MD (Multiple Device) RAID**, combining MD’s redundancy (e.g. mirroring, striping) with LVM’s flexibility.

**Configuring LVM**

To begin using LVM, you must first allocate storage and dedicate it to LVM by initializing one or more physical volumes (PVs). 
It’s recommended to create PVs directly on entire disks:

```bash
pvcreate /dev/vdx
```

Once you have one or more PVs created, you can group them into a volume group.

```bash
vgcreate my_vg /dev/vdx
```

You can then create a logical volume by specifying its size in either storage
units (bytes, KB, MB, GB...), extents or percentage (20%FREE). You can specify
volume type (linear, striped, mirror, raid, cache) and additional parameters
for each specific type during volume creation.

```bash
lvcreate --name my_lv --size 10GB my_vg
```

If you run low on space in a filesystem, you can extend it by first increasing the size of the underlying logical volume. You do that by first increasing the underlying logical volume.

If you don't have enough free extents in the current volume group you might
need to add extra PVs.

```bash
vgextend my_vg /dev/vdy
lvextend -L +20GB /dev/my_vg/my_lv
```

Once a volume group contains multiple PVs, you can improve data redundancy by converting a linear LV into a mirror:

```bash
lvconvert -m +1 my_vg/my_lv (from linear to mirror)
lvconvert -m 0 my_vg/my_lv (from mirror back to linear)
```
> **Note:** LVM supports mirroring, allowing a logical volume to be duplicated across two physical volumes. This provides redundancy similar to RAID1: if one disk fails, data remains accessible on the mirror.


You might need to move data off a physical volume, for example, when replacing an old or failing disk. In such cases, LVM allows you to migrate the data online using the **pvmove** command without unmounting or disrupting service.

```bash
pvmove /dev/vdy
pvmove -n my_vg/my_lv
```


## 5.6 Advanced LVM LAB


1. Install LVM.

```bash
sudo apt install -y lvm2
```

2. Create two PVs; one on `/dev/vdb` and the other on `/dev/vdc`, then list them.

```bash
sudo parted /dev/vdb
(parted) mklabel gpt
(parted) mkpart primary ext4 1MiB 100%
(parted) quit

sudo parted /dev/vdc
(parted) mklabel gpt
(parted) mkpart primary ext4 1MiB 100%
(parted) quit
```

```bash
sudo pvcreate /dev/vdb1
sudo pvcreate /dev/vdc1
sudo pvs -o +devices
```

3. Create a volume group called `my_vg` on top of the two volumes and list it.

```bash
sudo vgcreate my_vg /dev/vdb1 /dev/vdc1
sudo vgs
```

4. Create a volume called `my_lv`, 1GB in size in the new VG and list it.

```bash
sudo lvcreate -n my_lv -L 1GB my_vg
sudo lvs
```

5. Convert the volume into a mirrored volume.

```bash
sudo lvconvert -m +1 my_vg/my_lv
```


6. Display the LV and check if it uses space on both PVs.

```bash
sudo lvdisplay /dev/my_vg/my_lv
sudo pvs
```

7. Convert the volume back into a regular volume and check PV usage:

```bash
sudo lvconvert -m 0 my_vg/my_lv
sudo pvs
```


8. Check which physical volumes back a logical volume

You can approach this from two angles:

* From the LV side: See which devices an LV uses.
* From the PV side: See which LVs a PV contributes to.

From the LV perspective:

```bash
sudo lvs -o +devices
```
> Shows LVs along with the physical volumes they use.

```bash
sudo lvs --segments /dev/my_vg/my_lv
```
> Displays detailed segment-to-device mapping for an LV.

From the PV perspective:

```bash
sudo pvdisplay -m
```
> Shows how each PV is used, including the LVs and extents.

Block-level overview:

```bash
sudo lsblk
```
> Displays a tree of block devices and their logical volume relationships.


9. Move the volume to the other PV.

```bash
sudo pvmove -n my_lv /dev/vdb1 /dev/vdc1
```

10. Check that the LV was moved.

```bash
sudo lvs -o +devices
```

11. Remove the newly freed PV from the volume group.

```bash
sudo vgreduce my_vg /dev/vdb1
```

12. Extend the logical volume by 1GB and resize the filesystem automatically.

```bash
sudo lvextend -r -L +1G /dev/my_vg/my_lv
```

> The `-r` flag resizes the filesystem together with the LV.

Check that the change applied:

```bash
df -h /mnt/data/
sudo lvs
sudo vgs
```

13. Add a new disk `/dev/vdd` to the volume group and extend storage further.

```bash
sudo parted /dev/vdd
(parted) mklabel gpt
(parted) mkpart primary ext4 1MiB 100%
(parted) quit
```

```bash
sudo pvcreate /dev/vdd1
sudo vgextend my_vg /dev/vdd1
sudo vgs
```

You can now allocate more space from the new PV:

```bash
sudo lvextend -r -L +1G /dev/my_vg/my_lv
df -h /mnt/data/
```

> You’ve now dynamically grown both the VG and LV without downtime, the main advantage of LVM.

14. Remove the logical volume and the volume group.

```bash
sudo vgchange -an my_vg
sudo lvremove my_vg/my_lv
sudo vgremove my_vg
udo pvremove /dev/vdb1 /dev/vdc1 /dev/vdd1
```


## 5.7 Device Mapper Multipathing

**Device Mapper Multipathing (DM-Multipath)** enables Linux systems to use multiple physical I/O paths between a server and a storage device, such as an iSCSI or Fibre Channel SAN, as a single logical block device. These paths may use different cables, switches, or controllers, but all lead to the same underlying storage.

By aggregating these connections, DM-Multipath provides:

	**1.	Path Redundancy**
In an active/passive setup, only one path is active at a time. If an I/O path (cable, switch, or controller) fails, DM-Multipath automatically fails over to a backup path, ensuring continued access.

	**2.	Improved Performance**
In an active/active configuration, DM-Multipath distributes I/O across available paths (e.g. using round-robin scheduling), increasing throughput and balancing load.

> **Note:** DM-Multipath provides path-level redundancy. In properly designed environments, it is used alongside redundant storage systems with multiple controllers, fabrics, and RAID-backed disk arrays to ensure both path and device-level fault tolerance.

**Identifying Multipath Devices**

Without multipathing, each I/O path appears as a separate device, even when they point to the same disk. DM-Multipath consolidates these into a single logical device.

You can inspect the relationship using:

```bash
lsblk
```

Example (before multipath is active):

```bash
sda      8:0    0   100G  0 disk
sdb      8:16   0   100G  0 disk   # duplicate path to same disk
```

After multipath is enabled:

```bash
sudo multipath -ll
```

Example output:

```bash
mpatha (3600508b400105e210000900000490000) dm-0 IBM,2810XIV
size=100G features='1 queue_if_no_path' hwhandler='0' wp=rw
|-+- policy='round-robin 0' prio=1 status=active
| `- 0:0:0:0 sda 8:0  active ready running
`-+- policy='round-robin 0' prio=1 status=enabled
  `- 1:0:0:0 sdb 8:16 active ready running
  ```

**The Role of WWIDs**

Each storage device includes a **World Wide Identifier (WWID)**, a globally unique string assigned by the storage system. DM-Multipath uses the WWID to determine which devices are redundant paths to the same underlying storage.

To view a device’s WWID:

```bash
sudo /lib/udev/scsi_id --whitelisted --device=/dev/sdX
```
In `multipath -ll` output, the `WWID` appears in parentheses next to the multipath device name. This ensures consistent path grouping, even if device names change across reboots.

For additional background on multipath concepts and how it works in Ubuntu, see the [Ubuntu Server documentation on Multipath](https://documentation.ubuntu.com/server/explanation/multipath/).

## 5.8 Device Mapper Multipathing LAB

**Note:** In a real world environment, DM-Multipath is used with storage backends such as SAN or iSCSI targets that expose multiple paths to the same logical unit (LUN). In this lab, we are simply exploring the tool using standalone block devices, the behavior won’t fully reflect true multipath setups, but the commands and output will still help you get familiar with how multipath works.

1. Install the multipath tools

```bash
sudo apt install -y multipath-tools
```
This package includes the multipath utility, the multipathd daemon, and related tools for managing multipath devices.


2. Discover all paths and aggregate them

```bash
sudo multipath -r
```
This reloads the multipath configuration and triggers a rescan for newly available devices. It’s useful right after installation or when new paths are added.

3. List the discovered devices.

```bash
sudo multipath -ll
```


# 6. Advanced Filesystem Concepts !heading

`Description:`

In this chapter, you will deepen your understanding of how Linux filesystems are structured, managed, and repaired. You will explore the underlying components like inodes and superblocks, how metadata is organized, and how to manipulate filesystems using both ext4-native and general tools. You'll also learn about advanced permission mechanisms and how to safely use them.


You will learn to:

* Describe how data is organized on disk
* Perform filesystem advanced management 
* Manage extended and file attributes and permissions
* Choose the right filesystem for your needs


## 6.1 Filesystem Internals

### 6.1.1 Inodes

An **inode** (index node) is a fundamental data structure in most Unix-style filesystems. It stores metadata about a file or directory, such as:

* File type (regular file, directory, etc.)
* Permissions and ownership (UID/GID)
* Size
* Timestamps (creation, modification, access)
* Disk block pointers (where the file’s data is actually stored)

Inodes do not store:
* The file name
* The file’s path

Instead, directory entries link filenames to inodes. Each file or directory has a unique inode number, which can be seen with `ls -i`.

All inodes are stored in the **inode table**, a fixed structure created when the filesystem is formatted (e.g., during `mkfs.ext4`). The inode table’s location and size are recorded in the filesystem’s **superblock**.

In the case of a directory, its inode points to a block that contains a list of filenames and their associated inode numbers.

The figure below illustrates a directory structure.
![Directory Structure](./images/folders.png)

To view the inode of a file:

```bash
ls -i filename
```

To find and sort directories by number of contained files:

```bash
find / -xdev -printf '%h\n' | sort | uniq -c | sort -k 1 -n
```

The next figure shows that structure represented using inodes:

![Inodes](./images/inodes.png)

Reading the drawing: Start at inode 2 (root), which maps to a directory. It contains entries pointing to other inodes. In this case, dir_1 points to inode 10, and file_a to inode 12. Inode 12 then points to the file’s data blocks.

> **Note:** The link count represents how many directory entries refer to the same inode. This is important when managing hard links and deleting files.
> 
> All directory inodes (except the root) have entries for the current directory (`.`) and the parent directory (`..`).

### 6.1.2 Superblocks

The **superblock** is a high-level metadata structure that defines essential filesystem characteristics, including:

* Filesystem type (e.g., `ext4`)

* Total size and block count

* Inode count and inode table location

* Supported features (journaling, extended attributes, etc.)

* Filesystem state and timestamps

Because of its importance, most filesystems store multiple backup copies of the superblock in predefined locations. If the primary superblock becomes corrupted (e.g., due to disk errors), recovery tools like `fsck` can use these backups to restore functionality.

**Viewing Superblock Backups**

Use `dumpe2fs` to list backup superblocks:

```bash
sudo dumpe2fs /dev/<partition> | grep -i superblock
```

**Viewing and Modifying Superblock Parameters**

Use `tune2fs` to inspect and change certain filesystem-level settings:

Display general superblock info:

```bash
sudo tune2fs -l /dev/vdb1
```

Display or change the volume label:

```bash
sudo tune2fs -l /dev/vdb1 | grep volume
sudo tune2fs -L myhome /dev/vdb1
```

Note: `tune2fs` works with `ext2`, `ext3`, and `ext4` filesystems only.

These tools are critical for maintenance, inspection, and manual recovery in advanced administrative scenarios.

### 6.1.3 Extended Attributes

Extended attributes (`xattrs`) are filesystem features that allow users and applications to associate files with metadata beyond the standard attributes like permissions, ownership, and timestamps. These attributes are not interpreted by the filesystem itself and can include things like user comments, application-specific flags, or security labels.

By contrast, regular attributes (such as `chmod` permissions or modification times) are strictly defined and used directly by the operating system.

Examples of extended attributes include:

* `user.comment` – a user-defined tag or note

* `security.selinux` – used by SELinux for file labeling

* Access Control Lists (ACLs) for more granular permission control

These attributes are stored outside of the inode in a separate block and require support from both the filesystem and mount options.

The presence of `user_xattr` in mount options enables support for extended user attributes:

```bash
sudo dumpe2fs -h /dev/vdb1 | grep Default
# output
Default mount options:    user_xattr acl
```

* `user_xattr` enables extended user attributes

* `acl` enables POSIX Access Control Lists

> Note: Not all filesystems or mount configurations support extended attributes. Ensure the filesystem is mounted with the `user_xattr` option where necessary.

**Immutable and Append-Only Attributes (chattr, lsattr)**

In addition to extended attributes, Linux supports special low level file attributes like immutable, append only, and undeletable flags. These are managed via `chattr` and viewed using `lsattr`. These flags operate below traditional permission models and are particularly useful in hardening files.

Examples:

```bash
sudo chattr +i /mnt/fs/file1.txt   # Make the file immutable
sudo chattr +a /mnt/fs/file1.txt   # Allow appending only
lsattr /mnt/fs/file1.txt           # View attributes
```

To remove these attributes:

```bash
sudo chattr -i /mnt/fs/file1.txt
```

These attributes are invisible to `ls -l` and require superuser privileges to modify.

### 6.1.4 POSIX ACLs

Access Control Lists (ACLs) provide fine-grained permission control beyond the traditional owner/group/other model. They allow specific permissions to be granted to additional users or groups.

To enable ACLs, the filesystem must be mounted with the acl option (which is often the default in modern distributions).

To display ACLs:

```bash
getfacl filename
```

To set an ACL for a specific user:

```bash
setfacl -m u:username:rwx filename
```

To remove all ACL entries from a file:

```bash
setfacl -b filename
```

ACLs are particularly useful in collaborative environments where traditional UNIX permissions are too limiting.

> **Note:** For a deeper dive into Access Control Lists (ACLs), including default ACLs, masks, group entries, and inheritance, refer to Chapter 9 – Security.

## 6.2 Filesystem Internals Lab

Run the following commands on the `LABVM` machine.

> In this lab you will work with `tune2fs` to view the superblock.
> You need to use `sudo` to run `tune2fs` commands.

1. Run the command to view the inode info.

```bash
df -ih
```

2. Create a partition and a filesystem on `/dev/vdb1`.

```bash
sudo dd if=/dev/zero of=/dev/vdb bs=1M count=10
sudo dd if=/dev/zero of=/dev/vdc bs=1M count=10
sudo dd if=/dev/zero of=/dev/vdd bs=1M count=10
sudo dd if=/dev/zero of=/dev/vde bs=1M count=10
sudo dd if=/dev/zero of=/dev/vdf bs=1M count=10
```

```bash
sudo parted /dev/vdb mklabel gpt
```

```bash
sudo parted -a optimal /dev/vdb mkpart primary ext4 1 100%
```

```bash
sudo mkfs.ext4 /dev/vdb1
```

3. Set the mount count to 2 max. This specifies how many mounts will execute
before running `fsck`.

```bash
sudo tune2fs -c 2 /dev/vdb1
```

> `-c` represents the number of mounts after which the filesystem will be checked

The `fsck` (File System Consistency Check) Linux utility checks filesystems for errors or outstanding
issues. The tool is used to fix potential errors and generate reports.

4. Run `tune2fs -i`. This command specifies how often to run it, after days/weeks/months.
Use `2d` for 2 days.

```bash
sudo tune2fs -i 2d /dev/vdb1
```

5. Run `tune2fs -l` on `vdb1`.

```bash
sudo tune2fs -l /dev/vdb1
```

> This allows you to see all information on a drive, including superblock
> information. An example is shown below:
> ```
> Inode count: 524288
> Free blocks: 1725279
> Free inodes: 463362
> Mount count: 2
> Maximum mount count: -1
> Last checked: Sun Nov 20 23:12:52 2020
> First inode: 11
> Inode size: 256
> ```

6. The default mount options can be also set in the filesystem superblock using
the `tune2fs` utility.

```bash
sudo tune2fs -o acl /dev/vdb1
```

7. Check the `vdb1` partition.

```bash
sudo dumpe2fs -h /dev/vdb1 | grep Default
# output
Default mount options:    user_xattr acl
Default directory hash:   half_md4
```

> `user_xattr` enables support for extended user attributes.

> `acl` enables POSIX ACLs.


8. Mount `vdb1` on `/mnt/fs` and write a file to it.

```bash
sudo mkdir /mnt/fs
```

```bash
sudo mount /dev/vdb1 /mnt/fs/
```

```bash
mount | grep vdb1
```

```bash
sudo chown -R ubuntu:ubuntu /mnt/fs
```

```bash
touch /mnt/fs/file1.txt; echo "Hello World!" > /mnt/fs/file1.txt
```

9. Unmount the filesystem and run `fsck` in it.

```bash
sudo umount /dev/vdb1
```

```bash
sudo fsck -V /dev/vdb1
```

mount it again:

```bash
sudo mount /dev/vdb1 /mnt/fs/
```


10.  Set and View Extended Attributes

Install `attr` utilities if not already available:

```bash
sudo apt install -y attr
```

Set a custom extended attribute on the file:

```bash
setfattr -n user.comment -v "This is a demo file." /mnt/fs/file1.txt
```

Verify the attribute:
```bash
getfattr -d /mnt/fs/file1.txt
```
You should see output like:

```bash
getfattr: Removing leading '/' from absolute path names
# file: mnt/fs/file1.txt
user.comment="This is a demo file."
```
Attempt to read a non-existing attribute:

```bash
getfattr -n user.invalid /mnt/fs/file1.txt
```

11. Set and Inspect POSIX ACLs

Install ACL tools (if not already available):

```bash
sudo apt install -y acl
```

Assign read access to a secondary user (e.g., nobody):

```bash
sudo setfacl -m u:nobody:r /mnt/fs/file1.txt
```

Inspect ACLs applied to the file:

```bash
getfacl /mnt/fs/file1.txt
```

You should see output like:

```bash
# file: file1.txt
# owner: ubuntu
# group: ubuntu
user::rw-
user:nobody:r--
group::rw-
mask::rw-
other::r--
```
Remove the ACL rule for the user:
```bash
sudo setfacl -x u:nobody /mnt/fs/file1.txt
```
12. Clean Up (Optional)

Unmount and optionally wipe the partition:

```bash
sudo umount /mnt/fs
sudo wipefs -a /dev/vdb1
```

## 6.3 The ext4 Filesystem

**ext4 (Fourth Extended Filesystem)** is the default filesystem in Ubuntu. It builds on `ext3`, offering improved performance, scalability, and reliability. It is widely used in production systems due to its stability and broad compatibility.

Key Features of `ext4`
* **Journaling:** Tracks changes before committing them, reducing corruption risk after crashes.
* **Extents:** Improves performance and reduces fragmentation by managing file blocks in ranges (extents) instead of individually.
* **Delayed Allocation:** Improves performance by deferring block allocation until data is written.
* **Backward Compatibility:** Can mount `ext3` and `ext2` filesystems.
* **Online resizing:** Ext4 can grow an existing filesystem while mounted.

ext4-specific Tools
* mkfs.ext4: Format a partition with ext4
* tune2fs: Adjust ext4 parameters, e.g. mount count, labels
* e2label: Set or get the volume label
* e2fsck: Check and repair ext2/ext3/ext4 filesystems
* resize2fs: Resize ext4 partitions (grow or shrink)

### 6.3.1 Journaling Modes and Mount Behavior

The ext4 filesystem provides configurable journaling modes, allowing you to balance performance and data integrity depending on your use case.

**Journaling Modes**

You can specify the journaling behavior with the `data=` mount option:

|Mode|Description|
|-|-|
|journal|Journals both file **data** and **metadata**. Highest reliability, slowest.|
|ordered| Journals only metadata. Ensures data is written before metadata updates. (Default)|
|writeback| Journals only metadata, but allows data to be written after metadata. Fastest, least safe.|

You can change the journaling mode temporarily with:

```bash
sudo mount -o remount,data=writeback /mount/point
```
To make it permanent, update the `/etc/fstab` options.

**Access Time Updates:** `atime`, `noatime`, `relatime`

By default, the filesystem records when files were last accessed using the `atime` field. This can introduce performance overhead.

|Option|Behavior|
|-|-|
|atime|Updates atime on every read. High I/O overhead.|
|noatime|Disables atime updates. Boosts performance.|
|relatime|(Default) Updates atime only if the previous value is older than mtime or ctime.|

You can configure this via:

```bash
sudo mount -o remount,noatime /mount/point
```
Or persist it in `/etc/fstab`.


### 6.3.2 Common Tasks

Create an ext4 filesystem:

```bash
sudo mkfs.ext4 /dev/vdb1
```

Label it:

```bash
sudo e2label /dev/vdb1 mydata
```

Resize it (after growing partition or LVM):

```bash
sudo resize2fs /dev/vdb1
```

Check and repair:

```bash
sudo e2fsck -f /dev/vdb1
```

View current filesystem settings:

```bash
sudo tune2fs -l /dev/vdb1
```

### 6.3.2 Other Filesystem Options

Ubuntu supports other filesystems such as:
	•	XFS – High-performance journaling filesystem optimized for scalability
	•	btrfs – Copy-on-write filesystem with advanced snapshotting
	•	F2FS – Flash-friendly filesystem designed for SSDs
	•	vfat/exFAT/NTFS – For interoperability with Windows

ZFS, a robust filesystem with built-in volume management, snapshots, and integrity checking, is covered in a dedicated chapter later in this course.

## 6.4 EXT4 Filesystem lab

Run the following commands on the `LABVM` machine.

> In this lab, you will work with an `ext4` filesystem, exploring advanced formatting options, journaling behavior, performance tuning, and resizing the filesystem.

**1. Prepare the disk and create the partition**

We will reuse the `/dev/vdb` disk but this time format only 80% of it initially to simulate a resize scenario later.

```bash
sudo parted /dev/vdb mklabel gpt
sudo parted -a optimal /dev/vdb mkpart primary ext4 1MiB 80%
```

**2. Format the partition with advanced ext4 options**
  
```bash
sudo mkfs.ext4 -L ext4data -m 1 -E lazy_itable_init=1 /dev/vdb1
```

> * `-L ext4data`: Sets a volume label
> `-m 1`: Reserves only 1% of the filesystem for root (default is 5%)
> `-E lazy_itable_init=1`: Speeds up formatting by deferring inode table zeroing

**3. Mount using the label**

Before mounting validate the new label with:
```bash
lsblk -f /dev/vdb
```

Now mount the newly created filesystem to the common mount point `/mnt/fs`.

```bash
sudo mkdir -p /mnt/fs
sudo mount LABEL=ext4data /mnt/fs
mount | grep /mnt/fs
```

**4. View available space**

```bash
df -h /mnt/fs
```

**5. Add a test file and validate persistence**

```bash
echo "Testing ext4 advanced lab" | sudo tee /mnt/fs/info.txt
```

**6. Inspect time creation, access and modification of the file so we can compare later**

```bash
stat /mnt/fs/info.txt
cat /mnt/fs/info.txt
stat /mnt/fs/info.txt
```

1. Extend the partition to full size (100%)

```bash
sudo umount /mnt/fs
sudo parted /dev/vdb resizepart 1 100%
```

8. Grow the filesystem to match the new size

```bash
sudo e2fsck -f /dev/vdb1
sudo resize2fs /dev/vdb1
```
9. Remount and validate size

```bash
sudo mount LABEL=ext4data /mnt/fs
df -h /mnt/fs
```

**Journaling and Access Time Behavior**

Let’s test how different mount options affect ext4 behavior and performance.

0. Confirm journaling feature exists:

```bash
sudo tune2fs -l /dev/vdb1 | grep has_journal
```

1. Set journaling mode to writeback:

```bash
sudo mount -o remount,data=writeback /mnt/fs
```

2. Verify mount options:

```bash
mount | grep /mnt/fs
```

3. Write data and measure performance:

```bash
time dd if=/dev/zero of=/mnt/fs/testfile bs=1M count=1024 status=progress
# output
1024+0 records in
1024+0 records out
1073741824 bytes (1.1 GB, 1.0 GiB) copied, 0.289749 s, 3.7 GB/s

real 0m0.627s
user 0m0.000s
sys 0m0.568s
```

4. Change to safer journaling mode:

```bash
sudo mount -o remount,data=journal /mnt/fs
```

Tip: If it failed, manually unmount it and then mount it again.

1. Re-run write test and compare performance.


6. Now Inspect access time behavior, with the 'noatime' and 'relatime' mount options

First remount the filesystem with `noatime` 

```bash
sudo mount -o remount,data=ordered,noatime /mnt/fs
```

now let's see the file's access time information
```bash
stat /mnt/fs/info.txt
cat /mnt/fs/info.txt
stat /mnt/fs/info.txt  # See if atime changes
```

and validate if `atime` changed or not.

Compare with the output in the previous exercise.

7. Clean Up (Optional)

Unmount and optionally wipe the partition:

```bash
sudo umount /mnt/fs
sudo wipefs -a /dev/vdb1
```

## 6.5 The SETUID and SETGID Bits

> **Note:** The use of `setuid` and `setgid` should be handled with care. These bits grant privilege escalation to commands, increasing the system’s attack surface. When possible, prefer modern alternatives such as sudo, capabilities (`setcap`), or sandboxing mechanisms.

A process has two different ways to classify its `UID`: the **real** UID and the **effective** UID. The real UID belongs to the user account that starts the process. The effective UID is that of the user account whose privileges attach to the process. For the most part, the real and effective UIDs are the same.

The `SETUID` and `SETGID` permissions allow you to alter that behavior. This is primarily used to elevate the privileges of the current user for a specific task.

**What Are SETUID and SETGID?**

* `setuid` (set user ID) and `setgid` (set group ID) are permission bits that, when applied to an executable file, allow it to run with the privileges of the file owner (`setuid`) or group (`setgid`) rather than the user executing it.

* `setgid` on directories has a special role: any files or subdirectories created inside will inherit the group of the directory, which is useful for collaborative spaces (e.g., `/srv/shared`).

> `setuid` has no effect when set on directories as it only works on executables.


**Viewing SETUID/SETGID**

To view whether a file has SETUID and SETGID execute the following command:

```bash
ls -l
# output
-rwSrw-r-- 1 michelle michelle 0 Oct 1 0 1 4:30 file1
-rw-rwsr-- 1 michelle michelle 0 Oct 1 0 1 4:30 file2
```
* `S` in the user field of `file1` means `setuid` bit is set, but no execute permission for owner.
* `s` in the group field of `file2` means `setgid` bit is set and execute permission is also present.

Other files that might have these bits set: **at**, **chage**, **chsh**, **crontab**,
**sudo**, **ping**, **mount**.

You can check system binaries that rely on `setuid` or `setgid` for privilege elevation using:

```bash
ls -l $(which at) $(which chage) $(which chsh) $(which crontab) $(which sudo) $(which ping) $(which mount)
-rwxr-sr-x 1 root shadow   63640 Feb  6  2024 /usr/bin/chage
-rwsr-xr-x 1 root root     36360 Feb  6  2024 /usr/bin/chsh
-rwxr-sr-x 1 root crontab  35208 Mar 23  2022 /usr/bin/crontab
-rwsr-xr-x 1 root root     39072 Apr  9  2024 /usr/bin/mount
-rwxr-xr-x 1 root root     72344 Feb  4  2022 /usr/bin/ping
-rwsr-xr-x 1 root root    215944 Apr  3  2023 /usr/bin/sudo
```

**Setting or Removing SETUID/SETGID**

To add the SETUID or SETGID in Symbolic mode:

```bash
chmod u+s /path/filename
chmod g+s /path/filename
```

To remove them:

```bash
chmod u-s /path/filename
chmod g-s /path/filename
```

To add the SETUID or SETGID in Octal mode (also known as numeric form of permissions):

```bash
chmod 4777 file1
chmod 2764 file2
chmod 6764 file3
```

To remove them:

```bash
chmod 0644 file1
```

> In octal mode, special bits are prefixed as a **4th digit**:
* 4 = `setuid`
* 2 = `setgid`
* 1 = `sticky`

> **Note:** In octal mode, the digit 1 sets the **sticky bit**, which is typically used on directories like `/tmp` to allow all users to create files, but only the file’s owner (or root) can delete or rename them.

**Finding Files with SETUID or SETGID**

To find all files on the system with *setuid* or *setgid* bits set:

```bash
sudo find / -type f -perm /6000 -exec ls -l {} \;
```
> **Note:** The `/` in `-perm /6000` enables bitwise matching, meaning it will match files with any of the specified bits (`setuid`, `setgid`) set. This is often referred to as the short form of permission matching.

In summary, special permissions in octal form:

These can be used with chmod to set multiple special bits at once:

| Octal | Special | rwx (user/group/other) |
|-|-|
| 4755 | setuid | rwxr-xr-x |
 2755 | setgid | rwxr-sr-x |
 1755 | sticky | rwxr-xr-t |

## 6.6 SETUID and SETGID LAB

Make sure you are on `LABVM`.

> In this lab, you will explore how `setuid` and `setgid` affect file permissions and process privileges.

1. Check current permissions of **passwd** command.

```bash
ls -lt /usr/bin/passwd
# output
-rwsr-xr-x 1 root root 68208 May 28 02:37 /usr/bin/passwd
```

> **Note:** the `s` in the user permission field. This indicates the `setuid bit` is set and execute permission is present. This allows the binary to run with the permissions of the file owner (root), even when executed by regular users.

2. Remove SETUID from passwd.

```bash
sudo chmod u-s /usr/bin/passwd
```

3. Check permissions again.

```bash
ls -lt /usr/bin/passwd
```

4. Try running **passwd** as a regular user to change your own password.

```bash
passwd
```

> It should fail, because `/etc/passwd` and `/etc/shadow` require elevated privileges, which `passwd` no longer has.


5. Restore SETUID permissions.

```bash
sudo chmod u+s /usr/bin/passwd
ls -lt /usr/bin/passwd
```

6. Create a new file and check its default permissions

```bash
touch ~/testfile
ls -l ~/testfile
# output
-rw-rw-r-- 1 ubuntu ubuntu 0 Oct 29 07:29 /home/ubuntu/testfile
```
> Notice that there are no executable permissions

7. Set the `setuid` bit and verify the change.

```bash
chmod u+s ~/testfile
ls -l ~/testfile
# output
-rwSrw-r-- 1 ubuntu ubuntu 0 Oct 29 07:29 /home/ubuntu/testfile
```

> `S` means the `setuid` bit is set, but **execute permission is missing** for the file owner. This file is not executable yet.

8. Add execute permissions and list the permissions.

```bash
chmod u+x ~/testfile 
ls -l ~/testfile
# output
-rwsrw-r-- 1 ubuntu ubuntu 0 Oct 29 07:29 /home/ubuntu/testfile
```
> Now that the file is executable, the lowercase `s` confirms both the `setuid` bit and execute permission are set for the owner.

## 6.7 Sticky Bits

The **sticky bit** applies only to **directories**, not files. It is typically used on world-writable directories like `/tmp`. Without it, any user could delete or rename files created by others in such directories.

When the sticky bit is set, only the file’s **owner** or root can delete or rename it, regardless of directory write permissions. This enhances multi-user security.

To add or remove the sticky bit:

```bash
chmod +t <directory>
chmod -t <directory>
```

To view it the results, use ls -ld:

```bash
drwxrwxr-t 2 michelle michelle 4096 Oct 7 1 8:26 mydir2
```
In the output:

* A lowercase `t` means sticky bit and execute bit for “others” are set.
* An uppercase `T` means sticky bit is set, but the execute bit is **not**.

The sticky bit is especially useful in directories with open write access (e.g., `rwxrwxrwt`). Without it, any user could delete files they don’t own.


**Understanding Sticky Bit Behavior in Group-Writable Directories**

By default, in a directory with permissions like:

```bash
drwxrwx---  group-owned-dir
```
All group members can **create**, **delete**, and **rename** each other’s files.

However, when the **sticky bit** is added:

```bash
drwxrwx--T  sticky-dir
```

Only the file **owner** (or root) can delete or rename files, even if the directory is writable by the group.

> This is useful in shared group directories where collaboration is needed, but accidental or malicious file deletions must be avoided.

To set the sticky bit concurrently with **suid** and **sgid** use:
```bash
chmod 1777 directory_name # sticky only
chmod 2775 directory_name # setgid for group inheritance
```
**Special Permission Bits Summary**

The following table summarizes how special permission bits appear in `ls -l` and `ls -ld` output:

Pattern | &nbsp; | Description
--- | --- | ---
-S-- | &nbsp; | SUID is set, but user (owner) execute permission is not set.
-s-- | &nbsp; | SUID and user execute permission are set both.
--S- | &nbsp; | SGID is set, but group execute permission is not set.
--s- | &nbsp; | SGID and group execute permission are set both.
---T | &nbsp; | Sticky bit is set, but other execute permission is not set.
---t | &nbsp; | Sticky bit and other execute permissions are both set.


## 6.8 Sticky Bits Lab

Run the following commands on the `LABVM` machine.

1. Make a directory and set world-writable permissions (777). The next steps will be
executed inside that directory.

```bash
mkdir ~/teststick
```

```bash
chmod 777 ~/teststick
```

> In this directory anyone can add/delete any file

2. Create 3 files called `sbFile1`, `sbFile2`, and `sbFile3` in the newly created directory.

```bash
for ((i=1;i<=3;i++)) ; do
  touch ~/teststick/sbFile${i}
done
```

3. Create another user called `cm`, use `ubuntu` as the password.

```bash
sudo adduser cm

sudo usermod -a -G ubuntu cm
```

4. Login as `cm` user and create 3 files called `sbUserFile1`, `sbUserFile2`, and
`sbUserFile3`.

```bash
su cm
```

```bash
for ((i=1;i<=3;i++)) ; do
  touch /home/ubuntu/teststick/sbUserFile${i}
done
```

5. As the current user (`cm`), delete the `ubuntu` user's file.

```bash
rm /home/ubuntu/teststick/sbFile1
```

> This works.

6. As `ubuntu`, remove the `cm` user's file.

```bash
exit
```

```bash
rm ~/teststick/sbUserFile1
```

> This works.

7. Now set the sticky bit on the directory.

```bash
chmod +t ~/teststick
```

8. Still as `ubuntu`, try to delete or move `sbUserFile2`.

```bash
rm ~/teststick/sbUserFile2
```

```bash
mv ~/teststick/sbUserFile3 ~/teststick/sbUserFile4
```

> Works since `ubuntu` is the owner of the directory.


9. As the `cm` user, try to delete or move one of the `ubuntu` user files.

```bash
su cm
```

```bash
rm /home/ubuntu/teststick/sbFile2
```

```bash
mv /home/ubuntu/teststick/sbFile3 /home/ubuntu/teststick/sbFile4
```

> Operation not permitted.


10. Log back in as the `ubuntu` user.

```bash
exit
```

# 7. ZFS !heading

**Description**:

ZFS is a widely used filesystem in Ubuntu-based container and storage environments due to its robustness and advanced features like snapshots, compression, and built-in volume management.

In this chapter, you will:

* Understand the architecture and core concepts of ZFS
* Explore and configure ZFS virtual devices (VDEVs) and zpools
* Learn how to tune ZFS using properties such as compression and quotas
* Create and manage snapshots and clones
* Perform scrubbing, send/receive operations, and explore RAID-like setups using ZFS
* Compare ZFS with other filesystems (e.g., ext4/XFS) to make informed design choices

## 7.1 ZFS Overview

ZFS is a modern filesystem that also functions as a volume manager, combining features traditionally handled by separate tools like LVM and ext4/XFS. It is widely used in container environments such as LXD due to its built-in snapshotting, copy-on-write, and data integrity features. ZFS allows pooling multiple drives into a single logical volume (called a zpool), offering flexibility and redundancy. It is supported only on 64-bit architectures.

Here’s a comparison to help decide when to use each:

| Feature| ZFS | ext4/XFS |
|-|-|-|
| Architecture | Combined volume manager + filesystem | Traditional filesystem only |
| Snapshots | Native, cheap, fast |Not natively supported |
| Copy-on-Write (CoW) | Yes |No |
| Compression | Built-in (lz4, gzip, zstd) | Not supported |
| Deduplication | Optional (high RAM usage) | Not supported |
| Journaling | ZIL (intent log) | Journaling |
| Simplicity & Overhead | Complex, high memory usage | Lightweight |
| Suitable for Low-resource | Not ideal | Yes |
| Tunability | Highly tunable | Limited |

There is no one-size-fits-all filesystem — ZFS shines with advanced features and robustness, while ext4/XFS excel in performance with lower overhead.



To install ZFS, use:

```bash
sudo apt install -y zfsutils-linux
```

Features:
* Simplified administration with `zpool` and `zfs` commands
* Snapshots (retains a data copy as of a specific point in time)
* Copy-on-write (COW) cloning (write-able copies of snapshots that store only
  changes from the original)
* Continuous integrity checking against data corruption
* Automatic repair
* Efficient data compression
* Deduplication (eliminates duplicate copies of repeating data)
* Partitioning is replaced by ZFS storage pools that can span multiple disks


### 7.1.1 ZFS Architecture and components

![ZFS Architecture](./images/zfs-architecture.png)

#### Understanding Pools, Datasets, and Volumes

ZFS organizes storage using three main concepts:

|Term|Description|Example|
|-|-|-|
|**Zpool**|A collection of one or more storage devices managed as a single unit|`pool-test`|
|**Dataset**|A mountable ZFS filesystem with tunable properties like compression|`pool-test/mystuff`|
|**Volume**|A virtual block device (`zvol`), useful for VMs, containers, or iSCSI|`pool-test/myvolume`|

If you want to store files directly and mount it like a directory use a dataset, if you want to attach a raw block device to a VM or container use a volume.

#### Common Dataset Properties

| Property | Description | Example |
|-|-|-|
| `compression` | Enable transparent compression (e.g., lz4, gzip, zstd) | `zfs set compression=lz4 pool/ds` |
| `atime` | Track file access time (`on` by default) | `zfs set atime=off pool/ds` |
| `mountpoint` | Filesystem mount path | `zfs set mountpoint=/data pool/ds` |
| `recordsize` | Preferred block size (important for DBs and VMs) | `zfs set recordsize=16K pool/ds` |
| `quota` | Max space a dataset (and children) can use | `zfs set quota=10G pool/ds` |
| `reservation` | Reserve space to ensure availability even if pool fills | `zfs set reservation=2G pool/ds` |
| `readonly` | Prevent any write access | `zfs set readonly=on pool/ds` |
| `copies` | Store multiple data copies on different parts of disk (not RAID) | `zfs set copies=2 pool/ds` |


#### ZFS Pools and Underlying Structures

**ZFS Virtual Devices (VDEVs)**

A **VDEV** (Virtual Device) is a building block of a ZFS storage pool (*zpool*). Each VDEV may contain one or more physical or logical storage devices. ZFS stripes data across all VDEVs in a pool.

ZFS organizes storage into **pools** (*zpools*), which are flexible containers composed of one or more devices. These devices can be raw disks, partitions, or preallocated files. Internally, ZFS groups these devices into *virtual devices* (VDEVs), which define how data is distributed and protected within the pool.

While you don’t typically interact with VDEVs directly, understanding their structure helps in designing for redundancy and performance.

The most common VDEV layouts include:

**Common layouts we’ll explore in this course:**
* **Single device** – a basic pool from one file or disk (no redundancy)  
* **Mirror** – RAID1-style duplication across devices  
* **RAIDZ1/2/3** – parity-based protection (like RAID5/6)  
* **Striped mirrors (RAID10)** – performance and redundancy combined

> In this training, we’ll build pools using mirrors and RAIDZ to understand redundancy and fault tolerance.  

**Other advanced configurations (not covered in depth):**
* **Hot Spare** – a standby disk that replaces failed ones automatically  
* **Cache (L2ARC)** – speeds up reads with a fast SSD  
* **Log (ZIL)** – a separate write log device for sync workloads

#### RAIDZ Levels in ZFS

ZFS offers **RAID-Z**, a family of parity-based redundancy levels that protect against disk failure, similar to traditional RAID-5 and RAID-6, but with no write hole, thanks to ZFS’s copy-on-write design.

| **Level** | **Redundancy** | **Minimum Disks** | **Description** |
| - | - | - |- |
| RAIDZ1 | 1 disk failure | 3 | Like RAID-5: stores 1 parity block for every group of data blocks.
| RAIDZ2 | 2 disk failures | 4 | Like RAID-6:  2 parity blocks per stripe. Used when failure of two disks must be tolerated.|
| RAIDZ3 | 3 disk failures | 5 | Triple-parity: very rare, but useful for archival-grade or cold storage environments.| 


> For further exploration of advanced tuning and pool designs, see:  
> * [OpenZFS Tuning and Performance Guide](https://openzfs.github.io/openzfs-docs/Performance%20and%20Tuning/Workload%20Tuning.html)


**ZFS Pools**

![zfs](./images/zfs.png)

ZFS filesystems are built on top of virtual storage pools called **zpools**. A *zpool* is constructed from one or more virtual devices (VDEVs), which in turn are built from block devices — such as entire drives (recommended), drive partitions, or even preallocated files (primarily for testing).

Using whole disks is the recommended setup for production environments, as it simplifies administration and ensures optimal alignment and performance.

Block devices within a VDEV can be arranged for redundancy (e.g., mirrors or RAIDZ) or configured for special purposes such as read caching (L2ARC), write logging (ZIL), or hot spares. One or more ZFS filesystems (datasets) can then be created on top of a pool.

**Creating a zpool with a dataset and a volume**

In the following example, a basic non-redundant pool named **pool-test** is created from 3 devices:
```bash
sudo zpool create pool-test /dev/vdb /dev/vdc /dev/vdd
```

Striping is performed dynamically, by default this creates a zero redundancy _RAID0_ pool.
> *Note:* To make your life easier when managing many devices, refer to them using any of the `/dev/disk/by-*/` labels. For example by-id which is the serial numbers of the drives.

Check the status of the pool with the following command:

```bash
sudo zpool status pool-test
#output
  pool: pool-test
 state: ONLINE
config:
  NAME        STATE     READ WRITE CKSUM
  pool-test   ONLINE       0     0     0
    vdb       ONLINE       0     0     0
    vdc       ONLINE       0     0     0
    vdd       ONLINE       0     0     0

errors: No known data errors
```
Explanation of this zpool status output:

* `pool: pool-test` Confirms the name of the pool.
* `state: ONLINE` The pool is healthy and fully operational.
* `config:` This section shows the hierarchy of the pool and its underlying devices.
   * `pool-test` The top-level pool.
   * `vdb`, `vdc`, `vdd` These are the physical devices that make up the pool’s single VDEV, and they are all ONLINE.
   * `errors: No known data errors` The pool is currently free of known data integrity issues.



Creating a Dataset (filesystem):

```bash
sudo zfs create pool-test/mystuff
```

You can see it with `mount`:

```bash
mount -t zfs
#output
pool-test on /pool-test type zfs (rw,xattr,noacl,casesensitive)
pool-test/mystuff on /pool-test/mystuff type zfs (rw,xattr,noacl,casesensitive)
```

Creating a Volume (block device):

```bash
sudo zfs create -V 10G pool-test/myvolume
ls -lh /dev/zvol/pool-test/myvolume
#output
lrwxrwxrwx 1 root root 9 May 31 13:10 /dev/zvol/pool-test/myvolume -> ../../zd0
```
> A volume (zvol) is not automatically formatted or mounted — it appears as a raw block device and can be used with tools like mkfs, LVM, or attached to VMs.

List the volume with `lsblk`:

```bash
lsblk /dev/zd0
#output
NAME MAJ:MIN RM SIZE RO TYPE MOUNTPOINTS
zd0  230:0    0   1G  0 disk
```

and finally you can list all of them with:

```bash
zfs list
#output
NAME                 USED  AVAIL     REFER  MOUNTPOINT
pool-test           1.03G  26.6G       24K  /pool-test
pool-test/mystuff     24K  26.6G       24K  /pool-test/mystuff
pool-test/myvolume  1.03G  27.6G       12K  -
```
> Notice that the volume `pool-test/myvolume` does not have a mountpoint, because it is a block device, not a file system.

ZFS treats both datasets and volumes as child objects of the pool, but their behavior is quite different. For example, datasets get automatically mounted, while volumes appear as raw block devices and require manual formatting or partitioning.

To destroy a zpool:

```bash
sudo zpool destroy pool-test
```

**Creating a 2×2 Mirrored zpool Example**

In the following example, a mirrored zpool named **mypool** is created with two VDEVs, each being a mirror of two disks.

1. Create the first mirror VDEV:
  
```bash
sudo zpool create mypool mirror /dev/vdc /dev/vdd
```

2.	Add a second mirror VDEV to the same pool:

```bash
sudo zpool add mypool mirror /dev/vde /dev/vdf -f
```

3.	Check the status of the pool:

```bash
sudo zpool status mypool
```

The output is shown below.

```bash
pool: mypool
state: ONLINE
  scan: none requested
config:
  NAME        STATE   READ WRITE CKSUM
  mypool      ONLINE     0     0     0
    mirror-0  ONLINE     0     0     0
      sdc     ONLINE     0     0     0
      sdd     ONLINE     0     0     0
    mirror-1  ONLINE     0     0     0
      sde     ONLINE     0     0     0
      sdf     ONLINE     0     0     0

errors: No known data errors
```

Explanation of zpool status:

* `mypool` is the name of the pool.
* `mirror-0` and `mirror-1` are the two mirrored VDEVs in the pool.
* Each mirror contains two physical devices that duplicate the same data for redundancy.
* All devices are in the `ONLINE` state and no errors have been detected.

This layout is often called a **RAID10 equivalent**: striping across two mirrored sets, combining performance with redundancy.

There are many ways to arrange VDEVs to match different performance and redundancy goals.

For example, you can create:
* Non-redundant striped pools (RAID0-like)
* Mirrored pools (RAID1-like)
* RAIDZ configurations (RAID5/6-like)
* Striped mirrors (RAID10-like)
* Pools with special-purpose VDEVs like cache, log, or spare devices

We'll explore some of these configurations in the upcoming sections.

**Creating a File-Based Zpool Example**

ZFS pools can also be created from regular files, which is useful for testing or demonstration purposes.

1. Create a 2GB preallocated file:
```bash
dd if=/dev/zero of=example.img bs=1M count=2048
```

2.	Use it as a virtual device to create a pool:
```bash
sudo zpool create pool-test /home/user/example.img
```

3.	Check the status:

```bash
sudo zpool status
# output
  pool: pool-test
 state: ONLINE
config:
  NAME                        STATE     READ WRITE CKSUM
  pool-test                   ONLINE       0     0     0
    /home/user/example.img    ONLINE       0     0     0

errors: No known data errors
```
> **Note: **File-based zpools are not recommended for production use due to their dependency on the underlying file system’s integrity and performance.

### 7.1.2 ZFS Scrubbing

ZFS scrubbing is the process of reading all data in the pool and verifying checksums to detect and automatically repair silent data corruption (bit rot). It’s a preventive maintenance task.

It works like a **filesystem-level consistency scan**:
* Detects bit rot or corruption
* Automatically repairs data if redundancy (e.g. mirror, raidz) exists
* Verifies that all data matches its checksum

You can trigger a manual scrub using:

```bash
sudo zpool scrub pool-test
```
To monitor the progress and results of a scrub:

```bash
sudo zpool status -v pool-test
# output
  scan: scrub in progress since Tue May 27 14:05:27 2025
        1.58G scanned at 125M/s, 256K issued at 22.0K/s, 1.58G total
        0 errors detected
```
ZFS automatically attempts recovery if checksum mismatches are found.

> It’s a good practice to scrub pools periodically even if no errors are reported, to detect latent issues early.

On Ubuntu systems, ZFS scrubbing is scheduled automatically using a cron job:

```bash
cat /etc/cron.d/zfsutils-linux
#output
# Scrub the second Sunday of every month.
24 0 8-14 * * root if [ $(date +\%w) -eq 0 ] && [ -x /usr/lib/zfs-linux/scrub ]; then /usr/lib/zfs-linux/scrub; fi
```
> You can customize this cron entry for more frequent or specific scrub intervals.

Additionally, ZFS also schedules TRIM on the first Sunday of the month for SSDs.

```bash
# TRIM the first Sunday of every month.
24 0 1-7 * * root if [ $(date +\%w) -eq 0 ] && [ -x /usr/lib/zfs-linux/trim ]; then /usr/lib/zfs-linux/trim; fi
```

TRIM is a command that helps SSDs manage unused blocks more efficiently. When files are deleted, TRIM informs the SSD that those blocks are no longer in use, allowing the drive to optimize wear leveling and garbage collection.  

> In ZFS, TRIM helps maintain SSD performance and longevity over time.


### 7.1.3 Configuring and Tuning ZFS

A **dataset** in ZFS is a file system or volume created from a zpool. Each dataset can have its own properties, such as compression, mount point, quotas, or snapshot settings. This allows for fine-grained configuration per use case.

You can view and modify these properties using `zfs get` and `zfs set`.

You can see a list of all options that can be set:

```bash
zfs get all pool-test
```

#### Setting a Dataset Quota

The `quota` property limits the total space a dataset and its descendants can consume.  
> A descendant is any child dataset, like `pool/mystuff/blog` being a descendant of `pool/mystuff`.

This is a **hard limit**, it applies to the dataset itself, its child file systems, and snapshots.  

Note: For ZFS volumes, use the `volsize` property instead of `quota`.

To set a 10 GB quota:

```bash
sudo zfs set quota=10G pool-test/mystuff
```

Verify the setting:

```bash
sudo zfs get quota pool-test/mystuff
#output
NAME               PROPERTY  VALUE  SOURCE
pool-test/mystuff  quota     10G    local
```


> Quotas differ: use `quota` on datasets, `volsize` on volumes.

**Access Time (atime)**

By default, ZFS updates the access time of files each time they’re read (atime=on), which may cause unnecessary write operations. Disabling it can improve performance:

```bash
sudo zfs set atime=off pool-test/mystuff
```

**compression** - Controls the compression algorithm used for this dataset and
is described in the next section.


### 7.1.4 ZFS Compression

Data can be compressed automatically with ZFS. With the speed of modern CPUs
this is a useful option as reduced data size means less data to physically read
and write and hence potentially higher bandwidth I/O.

ZFS supports the following compression algorithms:

|Algorithm|Notes|
|-|-|
|**lz4** (default)|Fast and efficient. Best general-purpose option.|
|**zstd**|Great compression ratio, especially for log/archive data.|
|**gzip-N**|Tunable compression (gzip-1 = fast, gzip-9 = best ratio).|
|**lzjb**|Legacy default — slower and less effective than lz4.|
|**zle**|Zero-length encoding, useful for sparse datasets.|


To turn on compression:

```bash
sudo zfs set compression=on pool-test
```

This property automatically inherits to the descendants 
```bash
sudo zfs get compression pool-test/mystuff
NAME               PROPERTY     VALUE           SOURCE
pool-test/mystuff  compression  on              inherited from pool-test
```

To enable compression with a specific algorithm (e.g. zstd):

```bash
sudo zfs set compression=zstd pool-test/mystuff
```

Check the active compression:
```bash
sudo zfs get compression pool-test/mystuff
# output
NAME                PROPERTY     VALUE     SOURCE
pool-test/mystuff   compression  zstd      local
```

After copying some files the compression level can be checked like this:

```bash
sudo zfs get compressratio pool-test/mystuff
#output
NAME               PROPERTY       VALUE  SOURCE
pool-test/mystuff  compressratio  11.53x  -
```

> NOTE: `lz4` is the default algorithm enabled with `compression=on`, usually there's no need to change it


### 7.1.5 ZFS Snapshots

ZFS snapshots are lightweight, read-only copies of a dataset or volume at a given point in time. They’re instantaneous and use no additional space initially, only changes after the snapshot consume extra space (via copy-on-write).

You can use snapshots to:
* Save the state of a dataset before major changes
* Recover accidentally deleted files
* Roll back to a known good state

#### Creating a Snapshot

To snapshot the `pool-test/mystuff` dataset:

```bash
sudo zfs snapshot -r pool-test/mystuff@snap1
```
The -r flag makes recursive snapshots of the dataset and any descendants.

**Viewing Snapshots**

List all snapshots on the system:

```bash
sudo zfs list -t snapshot
# output
NAME                          USED  AVAIL  REFER  MOUNTPOINT
pool-test/mystuff@snap1         0B    -      1.5G   -
```

**Exploring Snapshot Contents**

Snapshots are accessible via a hidden `.zfs/snapshot` directory inside the dataset:

```bash
ls /pool-test/mystuff/.zfs/snapshot/snap1
```
You can browse or copy files directly from here without rolling back.

**Simulating File Deletion and Rollback**

Simulate an accident by destroying all the files and then rollback:

```bash
sudo rm -rf /pool-test/mystuff/*
# dataset should be empty
ls -lah /pool-test/mystuff/
sudo zfs rollback pool-test/mystuff@snap1
# dataset should include deleted files
ls -lah /pool-test/mystuff/
```
> Rollback destroys all changes made to the dataset **after** the snapshot was taken.

Check that files have been restored:

```bash
ls -lah /pool-test/mystuff/
```

**Destroying a Snapshot**

To remove the snapshot:

```bash
sudo zfs destroy pool-test/mystuff@snap1
```

ZFS snapshots can be replicated or archived using `zfs send` and `zfs receive` commonly used for backups or remote sync.

### 7.1.6 ZFS Clones

![ZFS Clones](./images/zfs_clone.png)

A **ZFS clone** is a writable copy of a snapshot. It starts with the same data as the snapshot but can diverge as changes are made. Clones are ideal for testing, development, or fast provisioning scenarios like spinning up container filesystems or VM images.

Clones are **space-efficient** thanks to ZFS’s **copy-on-write** model: no data is copied until it changes.
However, the original **snapshot cannot be destroyed** as long as any clones depend on it.

Assuming `pool-test/mystuff@snap1` exists, then create a clone from the snapshot:

```bash
sudo zfs clone pool-test/mystuff@snap1 pool-test/mystuff/snap1clone
```

It can be verified with:

```bash
sudo zfs list
#output
NAME                           USED  AVAIL     REFER  MOUNTPOINT
pool-test                     1.03G  26.6G       24K  /pool-test
pool-test/mystuff              292K  10.0G      278K  /pool-test/mystuff
pool-test/mystuff/snap1clone     0B  10.0G      264K  /pool-test/mystuff/snap1clone
pool-test/myvolume            1.03G  27.6G       12K  -
```
> **Tip:** Clones can be treated just like any dataset — you can set mountpoints, enable compression, or even snapshot them.

**Common Use Cases for ZFS Clones**

|Use Case|Description|
|-|-|
|CI/CD Pipelines|Quickly spin up disposable test environments during automated build/test cycles.|
|Testing Software Updates|Safely trial upgrades or config changes on a copy of live data without impacting production.|
|Version Control for Environments|Clone a known-good snapshot to develop against a stable, repeatable baseline.|
|VM/Container Provisioning|Clone a base image (e.g. LXD, libvirt, or rootfs) to rapidly deploy multiple lightweight instances.|
|Database Dev/Test|Create a writable copy of production or staging DB snapshots for safe dev/testing without full duplication.|

> ZFS clones are perfect when you need to test, develop, or deploy against real data — but don’t want to risk breaking the original. 
> They save time, space, and make rollback trivial.

### 7.1.7 ZFS Send and Receive

ZFS provides a powerful method for backing up and replicating data: the **send/receive** feature.

* `zfs send` serializes a snapshot into a stream, which can be saved to a file or piped across the network (e.g., via ssh).
* `zfs receive` takes that stream and reconstructs the snapshot, restoring it into another ZFS pool or dataset.

This enables:

* **Local backups** (e.g. `zfs send > backup.zfs`)
* **Remote replication** (e.g. `zfs send | ssh host zfs receive`)
* **Incremental backups** using `zfs send -i` (only changes since last snapshot)

> Send/receive works only with snapshots and is frequently used in production backup workflows, disaster recovery, or syncing environments across systems.

### 7.1.8 Redundancy Enhancements: Deduplication & Ditto Blocks

ZFS offers advanced features to reduce space usage and protect metadata integrity: **deduplication** and **ditto blocks**.

---

#### Deduplication

**Dedup** (deduplication) means identical data blocks are stored only once. ZFS keeps a reference rather than storing duplicate content.

* **Pros:** Can save space in high duplication workloads (e.g., VM images)
* **Cons:** Requires large amounts of RAM and CPU; may **reduce performance** if not carefully tuned

> The deduplication table (DDT) lives in memory and consumes ~320 bytes per deduplicated block. If it grows too large, performance degrades sharply.

To enable dedup on a dataset:

```bash
sudo zfs set dedup=on pool-test/mystuff
```
> Avoid enabling dedup without first testing, it is rarely worth it outside niche cases.

#### Ditto Blocks

ZFS stores redundant copies of internal metadata automatically. These are called ditto blocks.

* Default: 2 copies of file metadata (dnodes, indirect blocks), 3 for critical FS metadata
* Helps ensure resilience even if only one disk is used
* Spreads copies across devices or locations on disk

Useful for single-disk pools or when additional metadata protection is needed.

You can control the number of copies:

```bash
sudo zfs set copies=2 pool-test/mystuff
```
### 7.1.9 Mounting ZFS Datasets

ZFS automatically mounts datasets based on their `mountpoint` property, no need to manually edit `/etc/fstab`.

You can verify mountpoints with:

```bash
zfs get mountpoint pool-test/mystuff
```

And check mounted datasets:

```bash
mount -t zfs
```

  **Automatic Mounting (Default)**

By default, datasets mount at:

`/<pool>/<dataset>`

You can change the mountpoint:

```bash
sudo zfs set mountpoint=/mnt/docs pool-test/docs
```

**Legacy Mounting Mode**

To manage mounting manually (via /etc/fstab), use legacy mode:

```bash
sudo zfs set mountpoint=legacy pool-test/legacydocs
```

This is useful if:
* You rely on legacy init systems or backup tools
* You want full control over mount timing and order

The most common use case is ZFS root filesystems (where `/` resides on ZFS).

### 7.1.10 ZFS Pool and Dataset Lifecycle

ZFS provides robust tools to manage the full lifecycle of pools and datasets including listing, exporting, importing, and destruction.

#### List Pools and Datasets

Show current pools:

```bash
zpool list
```

List all datasets (filesystems and volumes):

```bash
zfs list
```

Get detailed pool status:

```bash
zpool status
```

#### Destroying Datasets

To permanently delete a dataset (filesystem or volume):

```bash
sudo zfs destroy pool-test/mystuff
```
> **This is irreversible**: there’s no recycle bin.

You can also destroy snapshots:

```bash
sudo zfs destroy pool-test/mystuff@snap1
```
> Reminder: Snapshots can’t be destroyed while clones depend on them.

#### Exporting and Importing Pools

When physically moving disks (e.g., from one server to another), export the pool first:

```bash
sudo zpool export pool-test
```

Then on the destination system (after connecting the disks), run:

```bash
sudo zpool import
# or to import a specific pool:
sudo zpool import pool-test
```

If a pool is imported but not auto-mounted, check:

```bash
sudo zfs mount -a
```

## 7.1.11 ZFS Recap: What You’ve Learned

In this section, you’ve learned how ZFS stands apart from traditional filesystems by combining a volume manager and a powerful, resilient filesystem.

You now understand:

* How **zpools**, **VDEVs**, **datasets**, and **volumes** are structured  
* The role of **snapshots**, **clones**, and **send/receive** for backups and testing  
* When to enable features like **compression**, **deduplication**, and **copy redundancy**  
* How to set properties like `atime`, `recordsize`, `quota`, and `mountpoint`  
* Safe ways to **destroy**, **export**, and **import** pools and datasets  
* How to tune performance and integrity with tools like **scrub**, **TRIM**, and **ditto blocks**



## 7.2 ZFS Lab

In the following labs, you’ll apply what you’ve learned by:

* Creating mirrored and RAIDZ pools  
* Experimenting with compression and quotas  
* Sending snapshots across the wire  
* Cloning datasets and simulating rollback scenarios  
* Destroying (carefully!) and rebuilding pools

Run the following exercises on the `LABVM` machine.

### 7.2.1 Create ZFS Pools and Datasets

1.	Install the zfsutils-linux package.

```bash
sudo apt install -y zfsutils-linux
```

2.	Identify available devices (e.g., vdb, vdc, vdd, etc.) and wipe any existing partitions.

> Use **lsblk** to see devices and then:

```bash
# Wipe any existing filesystem/partition signatures from the disks
for disk in vdb vdc vdd vde vdf vdg; do sudo wipefs -a /dev/$disk; done
```
* **Note:** ZFS works best with full raw disks (e.g. /dev/vdb) and does not require partitions.

3. Create and expand a simple mirror ZFS pool

```bash
sudo zpool create -f testpool mirror /dev/vdb /dev/vdc
```

Check status:
```bash
sudo zpool status testpool
```

4. Add a non-redundant device:

```bash
sudo zpool add testpool /dev/vdd
```
> Note: This device is not mirrored, it expands capacity but introduces a potential single point of failure.

5. Add a second mirror VDEV:

```bash
sudo zpool add testpool mirror /dev/vde /dev/vdf
```

6. Check the updated pool status:

```bash
sudo zpool status testpool
```

You should now see:

* One mirrored VDEV (vdb + vdc)
* One single-disk (vdd) VDEV
* One mirrored VDEV (vde + vdf)

> Discuss the trade-offs of adding single disks vs mirrored or RAIDZ VDEVs

7. Clean up the test pool before the next exercise:

```bash
sudo zpool destroy testpool
```

8. Create a RAID-Z1 pool.

```bash
sudo zpool create -f zfspool raidz /dev/vdb /dev/vdc /dev/vdd
```
> Use `-f` to force creation. This is useful if there is already a filesystem on the disk.

9.	Verify pool status.

```bash
sudo zpool status zfspool
```

10.	Create datasets.

```bash
sudo zfs create zfspool/mystuff
sudo zfs create zfspool/myFs2
```

11.	Verify datasets and mountpoints.

```bash
sudo zfs list
mount -t zfs
```

You can also check mount status with the `zfs mount` command.

12.	Change mountpoint of a dataset (legacy mode).

```bash
sudo mkdir /mnt/myzfs
sudo zfs set mountpoint=legacy zfspool/mystuff
sudo mount -t zfs zfspool/mystuff /mnt/myzfs
```

13. Check the mounts.

```bash
zfs mount
```

```bash
mount -t zfs
```

### 7.2.2 ZFS Compression

1. See all ZFS pools options.

```bash
sudo zfs get all zfspool
```

And check default compression option

```bash
sudo zfs get compression zfspool
```

2. Enable compression (lz4 is the default).

```bash
sudo zfs set compression=on zfspool
sudo zfs get compression zfspool
```

3.	Check compression ratio.

```bash
sudo zfs get compressratio zfspool
```

3.	Create a file to the ZFS dataset and check compression ratio again.


```bash
sudo dd if=/dev/zero of=/mnt/myzfs/file1 count=1024 bs=1M 
ls -lh /mnt/myzfs/file1
sudo zfs get compressratio zfspool
```

> Notice the difference.  Try copying a JPEG or MP3 files (already compressed) into the dataset and check the ratio again.

### 7.2.3 ZFS Snapshots and Rollbacks

1.	Take a snapshot.

```bash
sudo zfs snapshot -r zfspool/mystuff@snap1
```

2. View all snapshots.

```bash
sudo zfs list -t snapshot
```

3.	Create another file.

```bash
sudo dd if=/dev/zero of=/mnt/myzfs/file2 count=1024 bs=1M
ls -alt /mnt/myzfs/
```

4. Rollback and see that file2 is lost and file1 is still there.

```bash
sudo zfs rollback zfspool/mystuff@snap1
ls -alt /mnt/myzfs/
```

5. Repeat the exercise with new files and additional snapshots and use the command `zfs diff` for Snapshot Changes.

```bash
sudo zfs snapshot -r zfspool/mystuff@snap2
sudo dd if=/dev/zero of=/mnt/myzfs/file3 count=1024 bs=1M
ls -alt /mnt/myzfs/
sudo rm /mnt/myzfs/file1
sudo zfs snapshot -r zfspool/mystuff@snap3
ls -alt /mnt/myzfs/
```

6. List snapshots and run `zfs diff snapshot_name`:
   
```bash
sudo zfs list -t snapshot
sudo zfs diff zfspool/mystuff@snap3
```

7. Delete created snapshots for upcoming exercises:

```bash
 sudo zfs destroy zfspool/mystuff@snap2
sudo zfs destroy zfspool/mystuff@snap3
```

### 7.2.4 ZFS Clones and Quotas
	
1.	Clone a dataset.

```bash
sudo zfs clone zfspool/mystuff@snap1 zfspool/mystuff/snap1clone
```
> Snapshots use `@`, clones use `/`.

```bash
sudo zfs list
```

2.	Set quota.

```bash
sudo zfs set quota=10G zfspool/mystuff
sudo zfs get quota zfspool/mystuff
```

### 7.2.5 ZFS Send and Receive
	
1.	Create a snapshot.

```bash
sudo zfs snapshot -r zfspool/mystuff@snap2
```

2.	Backup to a file.

```bash
sudo zfs send zfspool/mystuff@snap2 > ~/mystuff-snap.zfs
```

3.	Restore into a new dataset.

```bash
sudo zfs receive -F zfspool/mystuff-copy < ~/mystuff-snap.zfs
```

> The backup file can be transferred to other systems, with `ssh` or any other means.
> Provided the remote machine has zfsutils-linux installed and a pool with the same name, you can use the following command to send a snapshot to a remote host using SSH:

```bash
sudo zfs send zfspool/mystuff@snap2 | ssh remotehost sudo zfs receive -F zfspool/mystuff-copy
```



### 7.2.6 ZFS Ditto Blocks

1.	Enable metadata redundancy.

```bash
sudo zfs set copies=3 zfspool/mystuff
```

2. Show the attribute.

```bash
sudo zfs get copies zfspool/mystuff
```

### 7.2.7 ZFS Deduplication
	
1.	Enable dedup (use cautiously).

```bash
sudo zfs set dedup=on zfspool/mystuff
```

2. Show the attribute.

```bash
sudo zfs get dedup zfspool/mystuff
```

### 7.2.8 ZFS Scrubbing and Fault Simulation

1.	Simulate write, corruption, and scrub.

```bash
sudo dd if=/dev/urandom of=/zfspool/random.dat bs=1M count=20
md5sum /zfspool/random.dat
sudo dd if=/dev/zero of=/dev/vdd bs=1M count=10  #This destroys the contents of /dev/vdd

2. Check the status of the pool

```bash
sudo zpool status
```
The device should be marked as `UNAVAIL` or `DEGRADED`

3. To initiate an explicit data integrity check on a pool use the `zfs scrub` command.

```bash
sudo zpool scrub zfspool
```

4. Check the progress

```bash
sudo zpool status -v zfspool
```
> You can stop or pause the scrub process with `zpool scrub -s`or `zpool scrub -p` commands

5. You can replace the faulty disk as well.

```bash
sudo zpool replace zfspool /dev/vdd /dev/vdg -f
sudo zpool status -v zfspool
```

### 7.2.9 Destroy a ZFS Pool

1. List datasets (filesystems), snapshots, pools and volumes

```bash
sudo zfs list -t filesystem
sudo zfs list -t snapshot
sudo zfs list -t volume
sudo zfs list -t all
```

2. Delete all datasets, snapshots and volumes inside the pool

```bash
sudo zfs destroy -r zfspool  
```

3. Delete the pool itself
  
```bash
sudo zpool destroy zfspool
```

## 7.3 ZFS RAID Lab

**RAIDZ exercises**

1.	Create RAIDZ1 pool.

```bash
sudo zpool create -f zfsraid5 raidz /dev/vdb /dev/vdc /dev/vdd /dev/vde
```
> Note: In case of error wipe the disks and try again.


2. Check the pool status.

```bash
sudo zpool status zfsraid5
```

> Check the pool size.

```bash
zfs list
```

3.	Create RAIDZ2 pool.

```bash
sudo zpool create -f zfsraid6 raidz2 /dev/vdb /dev/vdc /dev/vdd /dev/vde /dev/vdf
```

4. Check the pool status.

```bash
sudo zpool status zfsraid6
```

> Check the pool size.

```bash
zfs list
```

5.	Verify and destroy after exploration.

```bash
sudo zpool status zfsraid5
sudo zpool status zfsraid6
sudo zpool destroy zfsraid5
sudo zpool destroy zfsraid6
```

**Nested RAIDZ1**

1. Create a pool with 3 VDEVS, each being a `RAIDZ1`.

```bash
# Create first RAIDZ1 VDEV (3 disks)
sudo zpool create zfsraid60 raidz /dev/vdb /dev/vdc /dev/vdd -f
```

```bash
# Add second RAIDZ1 VDEV (3 disks)
sudo zpool add zfsraid60 raidz /dev/vde /dev/vdf /dev/vdg
```
> Now zfsraid60 is a RAIDZ1+RAIDZ1 nested configuration, known as RAID60.

2. Check the pool status.

```bash
sudo zpool status zfsraid60
```

> Check the pool size.

```bash
zfs list
```

3. Destroy the pool.

```bash
sudo zpool destroy zfsraid60
```


**RAID10 Equivalent**

1.	Create 2x2 striped mirrors.

```bash
sudo zpool create zfsraid10 mirror /dev/vdb /dev/vdc mirror /dev/vdd /dev/vde -f
```
> This should give the best performance. Why do you think this is the case?

2. Check the pool status.

```bash
sudo zpool status zfsraid10
```
> Check the pool size.

```bash
zfs list
```

3. Try to corrupt the pool. Write a file to it.

```bash
sudo dd if=/dev/urandom of=/zfsraid10/random.dat bs=1M count=20
```

```bash
sudo dd if=/dev/zero of=/dev/vde bs=1M count=10
```

4. Initiate the scrub.

```bash
sudo zpool scrub zfsraid10
```

5. Check the status of the pool.

```bash
sudo zpool status -v zfsraid10
```

6. Errors were corrected due to redundancy. Replace the `vde` disk with a new, unused disk, `vdg`.

```bash
sudo zpool replace zfsraid10 /dev/vde /dev/vdg -f
```

7. Check the pool status.

```bash
sudo zpool status -v zfsraid10
```

8. Destroy the pool.

```bash
sudo zpool destroy zfsraid10
```

**File-Based Pool (for testing)**

1. Create a single file-based zpool called `zfsraidpool`.

```bash
sudo dd if=/dev/zero of=zfsraidpool.qcow2 bs=1M count=2048
```

```bash
sudo zpool create zfsraidpool /home/$USER/zfsraidpool.qcow2
```

2. Check status and mountpoint.

```bash
sudo zpool status zfsraidpool
```

3. Get the mountpoint.


```bash
sudo zfs get mountpoint zfsraidpool
```

> Check the pool size.

```bash
zfs list
```

4. Destroy the pool.

```bash
sudo zpool destroy zfsraidpool
```

**Cache and ZIL Devices**


1. Create a zpool containing a VDEV of 2 drives in a mirror.

```bash
sudo zpool create zfsmirror mirror /dev/vdd /dev/vde -f
```

2. Check the pool status.

```bash
sudo zpool status zfsmirror
```

3. Add a read cache drive to the pool `zfsmirror`.

```bash
sudo zpool add zfsmirror cache /dev/vdc
```

4. Add an intent log drive to the pool `zfsmirror`.

```bash
sudo zpool add zfsmirror log /dev/vdf
```

5. Check the pool status.

```bash
sudo zpool status
```

6. The read cache can also be removed.

```bash
sudo zpool remove zfsmirror vdc
```

7. Check the pool status.

```bash
sudo zpool status
```

8. Destroy the pool.

```bash
sudo zpool destroy zfsmirror
```

# 8. Advanced Networking Concepts !heading

`Description:`

In this section you will learn to:
* Explain and configure Netplan
* Explain and configure VLANs and trunking
* Explain and configure a linux bridge
* Explain and configure a bond

## 8.1 Netplan

### 8.1.1 Netplan general overview

Netplan is a utility for easily configuring networking on an Ubuntu Linux
system. You define a YAML file describing the required network interfaces and their configuration. From this description, Netplan will generate all the necessary configuration for your chosen renderer tool.

Netplan was added to Ubuntu in the 17.10 (Artful) release and became the
default network configuration renderer for Ubuntu from 18.04 LTS (Bionic) onwards.

Netplan reads network configuration from `/etc/netplan/*.yaml` which are
written by administrators, installers, cloud image instantiations, or other
OS deployments. All installers only generate such a file, no longer uses
`/etc/network/interfaces` any more. There is also a `netplan` command line tool
to drive some operations.

During early boot, Netplan generates backend-specific configuration files in
`/run` to hand off control of devices to a particular networking daemon.

Netplan is currently able to render to these supported networking daemon backends:
* NetworkManager 
* systemd-networkd

> Wifi and WWAN get managed by NetworkManager.<br/>
> Any other configured devices get handled by networkd by default, unless explicitly
> marked as managed by a specific manager (NetworkManager).<br/>
> Devices that are not covered by the network config do not get touched at all.

![Netplan Rendering](./images/netplan.png)

See the official documentation at [netplan.io](https://netplan.io/) for more information.

## General Configuration Structure


The top-level node is a `network:` mapping that contains `version: 2` , and then device
definitions grouped by their type, such as **ethernets:**, **wifis:**, or **bridges:**.
These are the types that our renderer can understand and are supported by the backends.

Each type block contains device definitions as a map where the keys (called *configuration
IDs*) are defined in the following section.

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      addresses:
        - 10.10.10.2/24
      nameservers:
        search: [mydomain, otherdomain]
        addresses: [10.10.10.1, 1.1.1.1]
      routes: 
        - to: default
          via: 10.10.10.1
```


### 8.1.2 Device Configuration IDs

The keys under each per-device-type section (like **ethernets:**) are called
**ID**s. They must be unique throughout the entire set of configuration files. Their
primary purpose is to serve as anchor names for composite devices, for example to enumerate
the members of a bridge that is currently being defined.

There are two physically/structurally different classes of device definitions, and the *ID*
field has a different interpretation for each:

**Physical devices**

> Examples: ethernet, wifi

These can dynamically come and go between reboots and even during runtime (hotplugging).
In the generic case, they can be selected by `match:` rules on desired properties, such as
name/name pattern, MAC address, driver, or device paths. These rules may apply to one device or many, depending on how specific the criteria are.

With specific knowledge (taken from the admin, a gadget snap, etc.), or by using unique
properties such as *path* or *MAC*, match rules can be written so that they only match
one device. Then the **set-name:** property can be used to give that device a more
user-friendly name than the default from udev's ifnames. 

> See [systemd.net-naming-scheme](https://www.freedesktop.org/software/systemd/man/latest/systemd.net-naming-scheme.html) for details.

It is valid to specify no match rules at all. In this case, the ID field is simply the
interface name to be matched. This is mostly useful in simpler configurations.

**Virtual devices**

> Examples: veth, bridge, bond

These are fully under the control of the config file(s) and the network stack. I.e. these
devices are being _created_ instead of _matched_. Thus **match:** and **set-name:** are not
applicable for these, and the *ID* field is the name of the created virtual device.



## Examples:

All cards on second PCI bus:

```bash
match:
  name: enp2*
```

Fixed MAC address:

```bash
match:
  macaddress: 11:22:33:AA:BB:FF
```
First card of driver *ixgbe*:

```bash
match:
  driver: ixgbe
  name: en*s0
```

### 8.1.3 Netplan Commands

* `generate` Runs during early boot, reads the config, and renders files to control the backend
* `apply` Applies the current Netplan configuration to a  running system.
* `try` Similar to *generate* but asks for confirmation otherwise rolls back configuration


**Linux Bridges**

A bridge is a means to connect two Ethernet networks together through software to create one larger Ethernet network. It can also filter and direct traffic.

Packets are forwarded based on Ethernet address (like a switch), rather than IP address (like a router). Since forwarding is done at Layer 2 (Data Link layer), all protocols can
pass transparently through a bridge. The bridge examines the MAC address of incoming packets and decides whether or not to forward them. This improves efficiency and reduces collisions.

A Layer 2 (L2) bridge behaves like a virtual switch operating at the data link layer.

> For more advanced bridging and network virtualization setups, see:
> * [What is Open vSwitch (OVS)](https://ubuntu.com/blog/data-centre-networking-what-is-ovs)

> * [What is OVN (Open Virtual Network)](https://ubuntu.com/blog/data-centre-networking-what-is-ovn)

**Sample Bridge Configuration**


```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    ens1p0:
      dhcp4: no
    ens1p1:
      dhcp4: no
  bridges:
    br0:
      interfaces:
        - ens1p0
        - ens1p1
      addresses:
        - 192.168.100.10/24
      gateway4: 192.168.100.1
      nameservers:
        addresses:
          - 8.8.8.8
          - 1.1.1.1
```

This *netplan* bridge configuration sets up a Layer 2 bridge between *ens1p0* and *ens1p1* Ethernet interfaces. It uses the *networkd* renderer and configures an IPv4 address on
the bridge.

You can manage bridges using the `brctl` command part of the **bridge-utils** packages.

## VLANs and Trunking

![vlan](./images/vlan.png)

Virtual Local Area Networks (VLANs) are used to divide a physical network into several
broadcast domains. They provide logical separation of network traffic.

Packets on a VLAN are **tagged** using IEEE 802.1Q encapsulation. A tag includes:

1. **VLAN ID (VID)** — 1 to 4094 (note: 0 and 4095 are reserved). VLAN *1* is most commonly used for management. 

2. **Priority value** — for traffic classification, including expedited routing.

There are two ways a machine connects to a switch carrying VLANs:

* **Untagged (access) port:** switch handles VLAN assignment, machine sees plain Ethernet.

* **Tagged (trunk) port:** machine sees 802.1Q encapsulated frames, used to access multiple VLANs.

Tagged ports, typically used by routers and servers, enable access to multiple VLANs and allow VLANs to span across switches or connect to VLAN aware endpoints.

> For more information and examples:
> 
> * [Single NIC host with VLANs](https://netplan.readthedocs.io/en/stable/single-nic-vm-host-with-vlans/)
> * [Netplan Examples](https://people.ubuntu.com/~slyon/netplan-docs/examples)


> VLAN tagging support requires the `8021q` kernel module. On Ubuntu, it is shipped by default.
> Use the following to verify:
```bash
lsmod | grep 8021q
modinfo 8021q
```

**Sample VLAN Trunking Configuration**

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    mainif:
      match:
        macaddress: "de:ad:be:ef:ca:fe"
      set-name: mainif
      addresses: [ "10.3.0.5/23" ]
      nameservers:
        addresses: [ "8.8.8.8", "8.8.4.4" ]
        search: [ example.com ]
      routes:
        - to: default
          via: 10.3.0.1
  vlans:
    vlan15:
      id: 15
      link: mainif
      addresses: [ "10.3.99.5/24" ]
    vlan10:
      id: 10
      link: mainif
      addresses: [ "10.3.98.5/24" ]
      nameservers:
        addresses: [ "127.0.0.1" ]
        search: [ domain1.example.com, domain2.example.com ]
```

This *netplan* configuration sets up two VLAN interfaces (`vlan10` and `vlan15`) on top of the physical interface `mainif`, which is matched by its MAC address and renamed accordingly. The configuration assigns static IPv4 addresses to each VLAN interface and also configures DNS and routing. This setup enables the system to participate in multiple VLANs over a single physical interface using 802.1Q tagging.


## Network Interface Bonding

![bonding](./images/bonding.png)


Bonding, or link aggregation, means combining several network interfaces (NICs) into a
single link. This provides either high-availability, load-balancing, better throughput,
or a combination of these.

A system with multiple interfaces may be configured to use bonding. It is an L2
aggregation of multiple interfaces (physical or virtual) into a single logical
network interface.

### Bond Modes:

|Mode|Description|
|-|-|
|active-backup|One active NIC, others standby|
|balance-rr|Round-robin load balancing|
|802.3ad|Dynamic link aggregation (LACP)|

Depending on the mode selected, when interfaces are aggregated into a bond, they may
provide redundancy for each other, allow increased total network throughput (by
sending data from different connections over multiple interfaces at once), or both.

You can configure bonding in Netplan or directly via CLI tools like `ip link`.

```bash
sudo ip link add bond0 type bond mode active-backup miimon 100
``` 

**Sample Bonding Configuration**

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0: {}
    enp2s0: {}
  bonds:
    bond0:
      dhcp4: yes
      interfaces:
        - enp1s0
        - enp2s0
      parameters:
        mode: active-backup
        primary: enp1s0
        mii-monitor-interval: 100
```

This *netplan* bond configuration creates a Linux bond named **bond0** from Ethernet
interfaces *enp1s0* and *enp2s0*. The primary interface is configured to be *enp1s0* and
the aggregation mode is set to *active-backup*.

The IP address of the *bond0* virtual interface is configured dynamically by DHCP.

**Note on Interface Naming:**
Interface names like ens1p0, ens1p1, enp1s0, enp3s0, and ens1p0 follow the predictable network interface naming scheme:

```bash
enp<bus number>s<slot/function>
```

So enp3s0 means:
* en: Ethernet
* p3: on PCI bus 3
* s0: slot/function 0


## 8.2 Netplan Lab

### 8.2.1 General configuration Lab

Run the following commands on the `LABVM` machine.

In this lab, you will configure a static IP address using Netplan.


1. First, get the gateway and the static IP address for `enp1s0`. The IP
should be `192.168.101.50` and the gateway `192.168.101.1`.

```bash
ip addr
```

```bash
ip route
```

2. Take a look at the current network configuration, as you can see, the networking 
configuration is set to DHCP:

```bash
sudo cat /etc/netplan/50-cloud-init.yaml
```

3. Observe the rendered backend configuration, in this case using `systemd-networkd` as a backend:

```bash
sudo cat /var/run/systemd/network/10-netplan-enp1s0.network
```
Expected output includes:
```bash
# output
[Match]
Name=enp1s0

[Link]
MTUBytes=1450

[Network]
LinkLocalAddressing=ipv6
Address=192.168.101.50/24
DNS=8.8.8.8
DNS=1.1.1.1

[Route]
Destination=0.0.0.0/0
Gateway=192.168.101.1
```

4. Edit `/etc/netplan/50-cloud-init.yaml` and configure static addressing:

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      addresses:
        - 192.168.101.50/24
      nameservers:
        addresses: [8.8.8.8, 1.1.1.1]
      routes:
        - to: default
          via: 192.168.101.1
      mtu: 1450
```
> Don't forget to create a backup before editing the file.

5. Apply the configuration with rollback safety:

> **netplan try** takes a configuration, applies it, and automatically rolls it back
if the user does not confirm the configuration within a time limit.

> This is especially useful on remote systems, as it prevents administrators from being locked out in the case of a network configuration error.

```bash
sudo netplan try
```

6. If successful, finalize the changes:

```bash
sudo netplan apply
```


### 8.2.2 VLAN Lab

Run the following commands on the `LABVM` machine.

In this lab, you will manually configure VLAN interfaces using `ip` commands, then replicate the setup using Netplan for persistence.

1. Check if the `8021q` kernel module - which provides VLAN tagging support - is loaded by default:

```bash
lsmod | grep 8021q
```
> It shouldn't.

2. Create a VLAN interface on `enp1s0` for `VLAN 42`.
 
```bash
sudo ip link add link enp1s0 name enp1s0.42 type vlan id 42
```

3. To check the VLAN interface was created, and what VLAN ID it will use, run
`ip link show` with the `-d` switch (for 'details').

```bash
ip -d link show enp1s0.42
```

4. Assign an IP address to the VLAN interface.

```bash
sudo ip addr add 192.168.42.42/24 brd 192.168.42.255 dev enp1s0.42
```

5. Check the IP address was correctly assigned with `ip addr show`.

```bash
ip addr show dev enp1s0.42
```

6. Bring up the VLAN interface.

```bash
sudo ip link set dev enp1s0.42 up
```

7. Check the VLAN interface is up.

```bash
ip addr show enp1s0.42
```

8. The `8021q` module must load as soon as you create the VLAN interface.

```bash
lsmod | grep 8021q
```

```bash
modinfo 8021q
```

```bash
dmesg |grep 8021q
```


9. Trunking is when you add more than 1 VLAN on the same underlying path.
Create a VLAN interface on enp1s0 for VLAN 100.

> You will add a secondary VLAN to the enp1s0 interface using `ip link add`

```bash
sudo ip link add link enp1s0 name enp1s0.100 type vlan id 100
```

```bash
sudo ip link set dev enp1s0.100 up
```

```bash
ip -d link show enp1s0.100
```

```bash
sudo ip addr add 192.168.100.42/24 brd + dev enp1s0.100
```

```bash
ip addr show dev enp1s0.100
```

10. List all the interfaces to see the big picture.

```bash
ip addr
```

11. Make the modifications persistent by editing `/etc/netplan/50-cloud-init.yaml`, and adding the `vlans` part.

```bash
sudo vim /etc/netplan/50-cloud-init.yaml
```

> Make the modifications.

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      addresses:
      - "192.168.101.50/24"
      nameservers:
        addresses:
        - 8.8.8.8
        - 1.1.1.1
      routes:
      - to: "default"
        via: "192.168.101.1"
      mtu: 1450
  vlans:
    vlan42:
      id: 42
      link: enp1s0
      addresses: [192.168.42.42/24]
    vlan100:
      id: 100
      link: enp1s0
      addresses: [192.168.100.42/24]
```

12. Try the new config file before applying it, press `ENTER` when prompted:

```bash
sudo netplan try
```

13. Finally, if the above command succeeded, apply the modifications:

```bash
sudo netplan apply
```

**Note:**
Legacy tools like `ifconfig`, `netstat`, and `arp` (from `net-tools`) have been replaced by modern equivalents in `iproute2`:
	•	`ip addr`, `ip route`, `ip neigh`
	•	`ss` for socket and connection info
Use these newer tools in modern Ubuntu systems.

### 8.2.3 Bonding and Bridging Lab

Make sure you are on `LABVM`.

In this lab, you will use dummy network interfaces to simulate physical devices and experiment with bonding and bridging configurations. This is helpful for environments where you lack additional physical NICs.


1. Make sure that you have the dummy kernel module loaded. If the dummy module is not
loaded, run the command to load it.

```bash
sudo lsmod | grep dummy
```

```bash
sudo modprobe dummy
```

```bash
sudo lsmod | grep dummy
```

2. With the driver now loaded you can create whatever dummy network interfaces you
like. And confirm it.

```bash
sudo ip link add dummy0 type dummy
```

```bash
sudo ip link set name ens10 dev dummy0
```

```bash
ip link show ens10
```

3. You can change the MAC address.

```bash
sudo ip link set dev ens10 address 00:22:22:ff:ff:ff
```

4. You can create aliases on top of `ens10`.

```bash
ip link show ens10
```

```bash
sudo ip addr add 192.168.100.199/24 brd + dev ens10 label ens10:0
```

```bash
ip addr show ens10
```

```bash
ip a | grep -w inet
```

5. Remove the test interface.

```bash
sudo ip addr del 192.168.100.199/24 brd + dev ens10 label ens10:0
```

```bash
sudo ip link delete ens10 type dummy
```

```bash
sudo rmmod dummy
```

## Bonding


1. Create two dummy interfaces to be used in the bond.

```bash
sudo ip link add ens10 type dummy
```

```bash
sudo ip link add ens11 type dummy
```

2. Create a bond interface and set its mode to `active-backup`.

```bash
sudo ip link add bond0 type bond mode active-backup miimon 100
```

3. Enslave the two interfaces to the bond.

```bash
sudo ip link set dev ens10 master bond0 state up
```

```bash
sudo ip link set dev ens11 master bond0 state up
```

4. Set an IP address on the bond.

```bash
sudo ip link set dev bond0 state up
```

```bash
sudo ip addr add dev bond0 172.16.0.14/24
```

5. To see the changes.

```bash
ip -d addr show bond0
```

6. Remove the bond interface.

> *Note:* do not remove the dummy interfaces as you will need them in the next
exercise

```bash
sudo ip link del bond0
```


## Bridges

1. Install the `bridge-utils` package.

```bash
sudo apt install -y bridge-utils
```

2. Create a Linux bridge.

```bash
sudo brctl addbr br0
```

```bash
sudo brctl show
```

```bash
sudo ip link show
```

3. Add the two interfaces from the bonding exercise to the bridge.

```bash
sudo brctl addif br0 ens10
```

```bash
sudo brctl addif br0 ens11
```

```bash
sudo brctl show
```

```bash
sudo ip link show
```

4. Set an IP address on the bridge.

```bash
sudo ip addr add dev br0 10.255.0.4/24
```

5. Inspect the bridge.

```bash
sudo ip -d addr show br0
```

6. To make the changes persistent, edit `/etc/netplan/01-netcfg.yaml`, notice 
the two new interfaces, `ens10` and `ens11`, and the bridge:

```bash
sudo vim /etc/netplan/01-netcfg.yaml
```

> Make the changes. Make sure to add the bridge and the ens interfaces.

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      addresses:
      - "192.168.101.50/24"
      nameservers:
        addresses:
        - 8.8.8.8
        - 1.1.1.1
      routes:
      - to: "default"
        via: "192.168.101.1"
      mtu: 1450
    ens10:
      dhcp4: no
    ens11:
      dhcp4: no
  vlans:
    vlan42:
      id: 42
      link: enp1s0
      addresses: [192.168.42.42/24]
    vlan100:
      id: 100
      link: enp1s0
      addresses: [192.168.100.42/24]
  bridges:
    br0:
      addresses: [10.255.0.4/24]
      interfaces: [ens10, ens11]
```

7. Apply the modifications:

```bash
sudo netplan apply
```


## Clean up

1. Clean up and remove the interfaces.

```bash
sudo brctl delif br0 ens11
```

```bash
sudo brctl delif br0 ens10
```

```bash
sudo ip link set dev br0 down
```

```bash
sudo brctl delbr br0
```

```bash
sudo ip link del ens11
```

```bash
sudo ip link del ens10
```

```bash
sudo ip link set dev enp1s0.42 down
```

```bash
sudo ip link delete enp1s0.42
```

```bash
sudo ip link set dev enp1s0.100 down
```

```bash
sudo ip link delete enp1s0.100
```

2. Edit `/etc/netplan/50-cloud-init.yaml` and remove the two new interfaces, the bridge 
and the VLANS, leave only the initial configuration.

```bash
sudo vim /etc/netplan/50-cloud-init.yaml
```

> Make the changes.

```yaml
network:
  version: 2
  renderer: networkd
  ethernets:
    enp1s0:
      addresses:
      - "192.168.101.50/24"
      nameservers:
        addresses:
        - 8.8.8.8
        - 1.1.1.1
      routes:
      - to: "default"
        via: "192.168.101.1"
      mtu: 1450
```

3. Apply the changes.

```bash
sudo netplan apply
```

# 9. Security !heading

`Description:`

In this section you will learn to:
* Define and explain PAM
* Define and use ACLs
* Define and use AppArmor
* Understand and configure host-level firewalls (UFW)
* Learn how to use Ubuntu Pro services

> **Exercise Caution:**
> Each of the technologies introduced in this section can, if misused, result
> in being unable to log in to a machine. Take great care when testing or using
> the information here on any machine with important data.

For a broader overview of Ubuntu’s security landscape, visit the official documentation at: https://documentation.ubuntu.com/server/explanation/intro-to/security/


## 9.1 Pluggable Authentication Modules (PAM)

Pluggable Authentication Module (PAM) is a system of libraries that handles low level
authentication in Ubuntu by default.  While this section focuses on PAM as Ubuntu’s core authentication framework, it’s also the entry point to powerful enterprise integrations. With modules like `pam_ldap`, `pam_krb5`, or tools like `sssd`, Ubuntu can authenticate against LDAP, Kerberos, or even Active Directory. This modular, pluggable model contrasts sharply with Windows’ centralized approach, and is a key strength of Linux in secure, scalable environments.

> **Note:** Starting with Ubuntu 24.04 LTS, the new [authd](https://ubuntu.com/blog/authd-oidc-authentication-for-ubuntu-desktop-server) service enables native integration with cloud identity providers using **OpenID Connect (OIDC)**. This allows Ubuntu systems to authenticate users via platforms like Azure AD or Google Workspace without needing local accounts or traditional directory services. `authd` complements PAM and is ideal for environments requiring centralized, cloud-based login for desktops or servers.

### PAM Library

The PAM library provides a stable general interface (Application Programming Interface - API) that privilege-granting programs (such as **login** and **su**) defer to in order to perform standard
authentication and authorization tasks.

The principal feature of the PAM approach is that the nature of the authentication
is dynamically configurable. In other words, the system administrator is free to
choose how individual service-providing applications will authenticate users. This
dynamic configuration is set by the contents of the single Linux-PAM configuration
file `/etc/pam.conf`.

Alternatively, the configuration can be set by individual configuration files
located in the `/etc/pam.d/` directory. The presence of this directory will cause
Linux-PAM to ignore `/etc/pam.conf`. Each module represents a particular
authentication mechanism, and is named *pam_xxxxx*.so.

Linux-PAM separates the tasks of authentication into four independent management
groups:

* **Account management**: check the account status and whether the user is
authorized to perform a task.

* **Authentication management**: ensure users are who they say they are.

* **Password management**: change a user's password or other credentials.

* **Session management**: perform something only during the user's current
session (maintenance of audit trails or mounting of the user's home directory).

## 9.1.1 Common PAM Modules

Here are examples of PAM modules used for each group:

| **Category** | **Example Modules** | **Description** |
|-|-|-|
| Authentication | pam_unix.so, pam_ldap.so, pam_fprintd.so | Basic Linux authentication, LDAP, fingerprint auth |
| Account management | pam_access.so, pam_time.so, pam_nologin.so | Time or location based access, deny login depending on account status |
| Password management | pam_cracklib.so, pam_pwquality.so, pam_pwhistory.so | Password strength checking |
| Session management | pam_mkhomedir.so, pam_systemd.so | Create homedir, log user sessions |

> **Note:** These modules, once installed, will be located under /lib/x86_64-linux-gnu/security/ or /lib/aarch64-linux-gnu/security/ depending on your architecture.

### 9.1.2 PAM Configuration

In the configuration file, each line represents a configuration rule to be applied.
Each configuration line has 3 fields:
* **Function type** - The function that the user application asks PAM to perform.
* **Control argument** - This determines what PAM does if the action of the current
  line is successful or fails.
* **Module** - The module that runs, determines what the line does.
An example usage for `/etc/pam.d/login` would be:

```ini
# Authenticate the user
auth required pam_unix.so

# Ensure users account and password are still active
account required pam_unix.so

# Change the users password, but at first check the strength with pam_cracklib
password required pam_cracklib.so retry=3 minlen=6 difok=3
password required pam_unix.so use_authtok nullok md5
session required pam_unix.so
```

In the example above:

* `auth` means the application is asking PAM to authenticate the user.

* `required` indicates that if the rule succeeds, PAM proceeds to additional rules, but if it fails, PAM returns failure regardless of subsequent results.

* `pam_unix.so` is the module that PAM executes to authenticate the user.


### 9.1.3 Common Settings

PAM supports reusing *common* configuration files between services. 

**Common PAM Configuration Files**

| File | Purpose |
|-|-|
| /etc/pam.d/common-auth | Handles authentication logic (e.g., password checks) |
| /etc/pam.d/common-account | Checks account validity (e.g., expired logins, login times) |
| /etc/pam.d/common-password | Controls password management (e.g., strength, hashing) |
| /etc/pam.d/common-session | Manages session setup and teardown (e.g., logs, mounts) |
| /etc/pam.d/common-session-noninteractive | Used for non-interactive session setups (e.g., cron, scripts) |


The **common authentication settings** config file `/etc/pam.d/common-auth`, for example, defines the different authentication methods used by default in all services like this:

```bash
#
# /etc/pam.d/common-auth - authentication settings common to all services
#
# This file is included from other service-specific PAM config files,
# and should contain a list of the authentication modules that define
# the central authentication scheme for use on the system
# (e.g., /etc/shadow, LDAP, Kerberos, etc.).  The default is to use the
# traditional Unix authentication mechanisms.
#
# As of pam 1.0.1-6, this file is managed by pam-auth-update by default.
# To take advantage of this, it is recommended that you configure any
# local modules either before or after the default block, and use
# pam-auth-update to manage selection of other modules.  See
# pam-auth-update(8) for details.

# here are the per-package modules (the "Primary" block)
auth    [success=1 default=ignore]      pam_unix.so nullok_secure
# here's the fallback if no module succeeds
auth    requisite                       pam_deny.so
# prime the stack with a positive return value if there isn't one already;
# this avoids us returning an error just because nothing sets a success code
# since the modules above will each just jump around
auth    required                        pam_permit.so
# and here are more per-package modules (the "Additional" block)
auth    optional                        pam_cap.so
# end of pam-auth-update config
```

These *common* files can be referenced in a service file using @<common-file>
format (a simple example for the `chsh` command):

```bash
#
# The PAM configuration file for the Shadow `chsh' service
#

# This will not allow a user to change their bash unless
# their current one is listed in /etc/bashs. This keeps
# accounts with special bashs from changing them.
auth       required   pam_bashs.so

# This allows root to change user bash without being
# prompted for a password
auth            sufficient      pam_rootok.so

# The standard Unix authentication modules, used with
# NIS (man nsswitch) as well as normal /etc/passwd and
# /etc/shadow entries.
@include common-auth
@include common-account
@include common-session
```

### 9.1.4 PAM Architecture


![PAM Architecture](./images/pam.png)


**libpam Packages**

Applications have to be written with *PAM* library support. Application
programmers can use the *PAM* API (**libpam**) to authenticate applications.
Applications interact with PAM modules based on the PAM configuration in
**/etc/pam.d**.

**libpam-cap**: POSIX 1003.1e capabilities (PAM module)<br/>
**libpam-cracklib**: PAM module to enable cracklib support<br/>
**libpam-doc**: Documentation of PAM<br/>
**libpam-modules**: Pluggable Authentication Modules for PAM<br/>
**libpam-modules-bin**: Pluggable Authentication Modules for PAM - helper
binaries<br/>
**libpam-runtime**: Runtime support for the PAM library<br/>
**libpam-systemd**: system and service manager - PAM module<br/>
**libpam0g**: Pluggable Authentication Modules library<br/>

### 9.1.5 PAM Modules discovery

To find PAM-enabled programs:

```bash
for i in /usr/{bin,sbin}/* ; do
  ldd $i 2>/dev/null | grep -q libpam 
  if [ $? == 0 ] ; then
    echo $i
  fi
done
```
Note: this may not be a 100% complete list - for example it ignores anything encapsulated like container images or snaps, but is quite a good start.

To check if a specific program uses PAM:

```bash
ldd $(which prog_name) | grep libpam
```
To list module files:
```bash
ls /lib/*/security
```
To list config files:
```bash
ls /etc/pam.d
```

Generally **/etc/pam.d** has a configuration file for each application that
requests PAM authentication. If an application calls PAM, but there is no
associated configuration file, the **other** configuration file is applied.


## 9.2 PAM LAB

In this lab you will review and explain a PAM configuration file. Use the
following configuration and explain the lines. 

> You can consult the manual page for each PAM module using `man pam_module_name`, or browse them online at https://manpages.ubuntu.com/.

```bash
auth [success=1 default=ignore] pam_unix.so nullok_secure
auth requisite pam_deny.so
auth required pam_permit.so
auth optional pam_ecryptfs.so unwrap
```

**Line 1**: This line provides standard unix authentication configured through
the */etc/nsswitch.conf* file. This means checking the */etc/passwd* and
*/etc/shadow* files. The `nullok_secure` argument passed to the *unix* module
specifies that accounts with no password are okay, as long as login information
checks out with the `/etc/securetty` file. The control field, which has
`[success=1 default=ignore]` replaces the simplified *required*, *sufficient*
etc. parameters and allows for more fine-grained control. In this instance, if
the module returns success, it skips the next *1* line. The default case, which
handles every other return value of the module, results in the line being
ignored and moving on.

**Line 2**: This line has the control value of *requisite* meaning that if it
fails, the entire configuration returns a failure immediately. It also calls on
the `pam_deny` module, which returns a failure for every call 
(meaning this will always fail). The only exception is when this line is skipped, which
happens when the first line returns successfully.

**Line 3**: This line is required and calls the `pam_permit` module, which
returns success every time. This simply resets the current *pass/fail* record
at this point to ensure that there aren't some strange values from earlier.

**Line 4**: This line is listed as optional, and calls the `pam_ecryptfs`
module with the `unwrap` option. This is used to unwrap a passphrase using the
supplied password, which will then be used for mounting a private directory.
This is only relevant if your system uses this encrypted directory feature.

Do the following exercises on the `LABVM` machine.


1. Use `man pam` for help; `man pam_unix`, shows this example file.

```bash
# Authenticate the user
auth       required   pam_unix.so
# Ensure users account and password are still active
account    required   pam_unix.so
# Change the user's password, but at first check the strength
# with pam_passwdqc(8)
password   required   pam_passwdqc.so config=/etc/passwdqc.conf
password   required   pam_unix.so use_authtok nullok yescrypt
session    required   pam_unix.so

```

2. Find modules in `/bin`, `/sbin`, `/usr/bin`, `/usr/sbin` that use PAM.

> The `ldd` command prints the shared libraries required 
by each program or shared object specified on the command line.

```bash
for i in /{bin,sbin}/* /usr/{bin,sbin}/* ; do
  ldd $i 2>/dev/null | grep -q libpam 
  if [ $? == 0 ] ; then
    echo $i
  fi
done
```

3. Check a specific program for PAM functionality.

```bash
ldd /bin/login | grep pam
```

4. See where the security modules are located, and what modules are available.

```bash
ls -l /lib/*/security
```

5. Modify PAM to restrict a minimum password length. Open 
`/etc/pam.d/common-password` and locate the line containing
`password        [success=1 default=ignore]      pam_unix.so obscure sha512`.
Add `minlen=8` to set a minimum of 8 characters passwords.

```bash
sudo vim /etc/pam.d/common-password
```

> Your line should now look like this:

```bash
password        [success=1 default=ignore]      pam_unix.so obscure sha512 minlen=8
```

6. Run `pam-auth-update` to change the settings

Before applying the change let's assign a password to the user `myadmin` (created in exercise 3.7.3 from Chapter 3)

```bash
sudo passwd myadmin
```

Now update the PAM authentication settings

```bash
sudo pam-auth-update
```

1. Using the user `myadmin`, try changing the password 

```bash
sudo su - myadmin
passwd
```
The expected output will be like this:

```bash
passwd
Changing password for myadmin.
Current password:
New password:            #trying a password with less than 8 characters
Retype new password:
You must choose a longer password.
New password:
Retype new password:
passwd: password updated successfully
```


## 9.3 Access Control Lists (ACLs)

POSIX Access Control Lists (ACLs) provide fine-grained permission control for files and directories beyond the traditional user/group/other model. ACLs allow you to define specific permissions for multiple users and groups, as well as default behaviors for new files created within a directory.

> **Note:** If you’ve already completed basic ACL configuration in Chapter 6 – Filesystems, this section builds on that foundation with more advanced and flexible usage examples.

> ACLs use the same `rwx` permission model but allow per-user and per-group entries, as well as masks to restrict effective permissions.

**Common ACL Commands**

| Command | Description |
|-|-|
| `getfacl`| View ACLs for a file or directory |
| `setfacl` | Set or modify ACL entries |
| `setfacl -x` | Remove specific ACL entries |
| `setfacl -M` | Read ACL entries from a specification file |
| `setfacl -b` | Remove all ACL entries (reset to defaults) |

## ACL Entries

ACL entries consist of a user (u), group (g), other (o) and an effective rights
mask (m). An effective rights mask defines the most restrictive level of
permissions. `setfacl` sets the permissions for a given file or directory.
`getfacl` shows the permissions for a given file or directory.

Defaults for a given object can be defined.

ACLs can be applied to users or groups but it is easier to manage groups.
Groups scale better than continuously adding or subtracting users.

The utility `getfacl` lists the ACLs for a given file or directory.

```bash
getfacl /var/www
```

The utility `setfacl` is used to add the groups *blue* and *green* to the ACL
for the directory /var/www.

```bash
sudo setfacl -m g:green:rwx /var/www/
sudo setfacl -m g:blue:rwx /var/www/
sudo getfacl /var/www/
```

The option `-x` removes groups or users from a given ACL. Below, the group
*green* is removed from the directory /var/www.

```bash
setfacl -x g:green /var/www
```


## Transfer of ACL Attributes from a Specification File

The transfer of ACL attributes from a specification file takes two steps.
In this example, the specification file is called `acl`.

1. Create a file containing the ACL to be used.

```bash
echo "g:green:rwx" > acl
```

2. Read the contents of the file into `setfacl` to set the ACL for directory
`/path/to/dir`

```bash
setfacl -M acl /path/to/dir
```

Output from `getfacl` is accepted, when reading from files using `-M` which
tells `setfacl` to modify the acl list for the specified directory.


Copying ACLs from One File or Directory to Another

To copy an ACL from *dir1* to *dir2* use the `-M` option. Output from `getfacl`
is accepted as input for `setfacl` when using `-M`.

```bash
getfacl dir1 | setfacl -b -n -M - dir2
```

`-b` clears the ACLs<br/>
`-n` do not recalculate effective rights mask<br/>
`-` to read from stdin

Or it can be done like this:

```bash
getfacl file1 | setfacl --set-file=- file2
```

## Copying an ACL into the Default ACL

Directories can have a special kind of ACL - the `default ACL`. 
The default ACL defines the access permissions that all objects under 
this directory inherit when they are created. 
A default ACL affects subdirectories as well as files.

Once the ACLs are the way they need to be, they can be set as the default.
Defaults are inherited by new files and directories created under the parent directory.

```bash
getfacl -a /path/to/dir | setfacl -d -M- /path/to/dir
```


## Adding and Removing a User

ACLs go beyond the traditional user/group/other model, allowing multiple users or groups with distinct permissions.

Add user *ubuntu* with `rwx` to the ACL for the file named `coolcode`:

```bash
setfacl -m u:ubuntu:rwx coolcode
```

To reset to defaults:

```bash
setfacl -x u:ubuntu: coolcode
```

## ACL with Groups and Other

Use `g` for *groups* and use `o` for *other*.

```bash
setfacl -m g:devops:rwx coolcode
setfacl -x o:r coolcode
```

## ACL Masking

Use `m` for *mask*, list only available permissions:

```bash
setfacl -m m:r-x coolcode
```

This limits everyone. The group may have `rwx`, the mask permits only `r-x`. For
example, the group with `rw-`, with this mask, ends up with `r--`.


## 9.4 ACL Lab

### 9.4.1 Adding, removing and transferring permissions 

Make sure you are on `LABVM`.

In this lab use will apply your knowledge of ACLs.

1. Install the `acl` package.

```bash
sudo apt install -y acl
```

2. Look at the example and determine what the output indicates from the `getfacl`
command. Which groups have what access?

```bash
# file:program
# owner: ubuntu
# group: students
user::rw-
group::rw-
other::r--
group:qa:rwx
group:uat:rwx
mask::rwx
```

3. The utility `getfacl` lists the ACLs for a given file or directory. Check
current ACL settings (`getfacl`) on a directory and file.

```bash
mkdir ~/testpermissions
```

```bash
touch ~/testpermissions/coolcode
```

```bash
getfacl ~/testpermissions/
```

```bash
getfacl ~/.bashrc
```

4. Add groups called `green`, `blue` and `devops`. Also add a normal user `cm`.

```bash
sudo addgroup devops
```

```bash
sudo addgroup blue
```

```bash
sudo addgroup green
```


## Model 1: ACL with Groups and Other

1. Set (add) permissions for the `devops` group.

```bash
cd testpermissions
```

```bash
setfacl -m g:devops:rwx ./coolcode
```

```bash
getfacl ./coolcode
```

2. Add the groups `blue` and `green` to the ACL for the directory `testpermissions`.

```bash
setfacl -m g:green:rwx ~/testpermissions
```

```bash
setfacl -m g:blue:rwx ~/testpermissions
```

3. Check the permissions.

```bash
getfacl ~/testpermissions/
```

4. Add group `greep` to the ACL of the `coolcode` file.


```bash
setfacl -m g:green:rwx ./coolcode
```

5. Check the permissions.

```bash
getfacl ./coolcode
```

6. The option `-x` removes groups or users from a given ACL. Remove the group 
`green` from the directory `testpermissions`.

```bash
setfacl -x g:green ~/testpermissions
```

```bash
getfacl ~/testpermissions
```

7. Add permissions for `others`.

```bash
cd ~/testpermissions
```

```bash
setfacl -m o:rwx ./coolcode
```

```bash
getfacl ./coolcode
```

8. Remove permissions for `others`.

```bash
setfacl -m o:--- ./coolcode
```

```bash
getfacl ./coolcode
```


## Model 2: ACLs are not restricted to the user, group, other.


You can add multiple users and groups with permissions specific to each.

1. Add user `ubuntu` with `rwx` to the ACL for a file named `coolcode`.

```bash
cd ~/testpermissions
```

```bash
getfacl ./coolcode
```

```bash
setfacl -m u:ubuntu:rwx ./coolcode
```

2. Remove permissions for `groups`.

```bash
setfacl -m g::--- ./coolcode
```

```bash
getfacl ./coolcode
```

3. Remove permissions for `green`.

```bash
setfacl -m g:green:--- ./coolcode
```

```bash
getfacl ./coolcode
```

4. Create a file containing the ACL to be used.

> Transfer of ACL attributes. Transfer takes two steps. In this example, the
specification file is called *acl*.

```bash
echo "g:green:rwx" > acl
```

5. Read the contents of the file into `setfacl` to set the ACL for a directory
`-M` tells `setfacl` to modify the ACL list for the specified directory.

```bash
mkdir dirtwo
```

```bash
setfacl -M acl dirtwo
```

```bash
getfacl dirtwo
```


6. Copy an ACL from one directory to another with the `-M` option.
See that permissions change (`green` is gone, `blue` is added)<br/>
**-b** clear ACLs<br/>
**-n** do not recalculate effective rights mask<br/>
**-** read from stdin

```bash
getfacl ../testpermissions | setfacl -b -n -M - dirtwo
```

```bash
getfacl dirtwo
```


7. Notice the `+` mark on the files that have ACLs.

```bash
ls -l

# output
-rw-rwx---+ 1 ubuntu ubuntu    0 Oct 30 16:58 coolcode
```

8. Reset all permissions to default.

```bash
setfacl -b ./coolcode
```


### 9.4.2 Default ACLs and masking 

1. Copying an ACL into the Default ACL. Once the ACLs are the way they need
to be, they can be set as the default. Defaults are inherited, so a new
directory will inherit the defaults of the parent directory.

```bash
getfacl -a dirtwo | setfacl -d -M- /home/ubuntu
```

2. Recursively reset ACLs for the `testpermissions` directory.

```bash
setfacl -R -b ~/testpermissions
```

```bash
getfacl ~/testpermissions
```

3. ACL masking. The mask indicates the permissions allowed 
for users (other than the owner) and for groups. The mask is a 
quick way to change permissions on all the users and groups.

> Users may have `rw-` read write permissions. But if there is a mask 
> with `r--` read permission is in place, then the user will only 
> have read permissions.

```bash
setfacl -m m:r-x ./coolcode
```

```bash
getfacl ./coolcode
```

4. Grant user `cm` `rwx` permissions of the `coolcode` file.

```bash
setfacl -m u:cm:rwx ./coolcode
```

5. Change to the `cm` user and write some text to the `coolcode` file.

```bash
su cm
```

```bash
echo "I am testing" > ./coolcode
```

6. This worked.

```bash
cat ./coolcode

# output
I am testing
```

7. Exit back to the `ubuntu` user.

```bash
exit
```

8. Remove all permissions for the `cm` user.

```bash
setfacl -m u:cm:--- ./coolcode
```

9. Log back in as `cm` user and try to change the `coolcode` file again.

```bash
su cm
```

```bash
echo "test2" >> ./coolcode

# output
bash: coolcode: Permission denied
```

10. Exit back to the `ubuntu` user.

```bash
exit
```


## 9.5 AppArmor

AppArmor is a Mandatory Access Control (MAC) system which is a kernel Linux
security module (LSM) enhancement to confine programs to a limited set of
resources. AppArmor's security model is to bind access control attributes to
programs rather than to users. AppArmor confinement is provided via profiles
loaded into the kernel, typically on boot. 

AppArmor profiles can be in one of two modes: 

* *Enforcement mode*: Profiles loaded in enforcement mode
will result in enforcement of the policy defined in the profile as well as
reporting policy violation attempts (either via syslog or auditd). 

* *Complain mode*. Profiles in complain mode will not enforce policy but instead report policy violation attempts. *Complain*  mode logs violations to  */var/log/syslog*  (or `auditd` if enabled). This mode is convenient for developing profiles.

**AppArmor** is path-based, meaning its security profiles apply to specific filesystem paths or executables. If you change the name or move the file to a different location, the profile no longer applies. AppArmor is widely adopted in Debian-based distributions and has a lower barrier to entry thanks to its simplicity and straightforward configuration.

Another popular Mandatory Access Control (MAC) system used primarily in non–Debian-based distributions is **SELinux**. It uses a label-based access control model, where security labels are attached to files or processes regardless of their name or path. SELinux offers very fine-grained policies but has a steeper learning curve and more complex policy management.

AppArmor has been part of the mainline Linux kernel since version 2.6.36. Additional AppArmor functionality is being added into the mainline kernel by AppArmor, Ubuntu and other developers.

AppArmor confinement in Ubuntu is application specific with profiles available
for specific binaries. With each release, more and more profiles are shipped
by default, with more planned.

If a profile is not available for an application, users may create a profile
and add it to **/etc/apparmor.d*. If a profile is not defined for a particular
binary, the binary is not confined.

To list profiles installed on the system execute:
```bash
sudo apparmor_status
```

## AppArmor Parser

`apparmor_parser` is used as a general tool to compile, and manage AppArmor
policy, including loading new *apparmor.d* profiles into the Linux kernel.

AppArmor profiles restrict the operations available to processes.

The profiles are loaded into the Linux kernel by the `apparmor_parser`
program. The profiles may be specified by file name or a directory name
containing a set of profiles. If a directory is specified then the
`apparmor_parser` will try to do a profile load for each file in the
directory that is not a *dot file*, or explicitly blacklisted (*.dpkg-new,
*.dpkg-old, *.dpkg-dist, *-dpkg-bak, *.rpmnew, *.rpmsave, *orig, *.rej,
*~). The `apparmor_parser` will fall back to taking input from standard
input if a profile or directory is not supplied.


## AppArmor Profiles

Profiles are stored in `/etc/apparmor.d/`. They are named after the full
path to the executable they profile, replacing `/` with `.` . For example
`/etc/apparmor.d/bin.ping` is the profile for `ping` in `/bin`.

> **Note:** The `bin.ping` profile is part of the `apparmor-profiles` package. To use it, install the package with `sudo apt install apparmor-profiles`.

There are two main types of entries used in profiles:

1. Path Entries determine what files an application can access.
2. Capability entries determine what privileges a process can use.

The following example is the profile for ping, located in
`/etc/apparmor.d/bin.ping`.

```c
#include <tunables/global>
  /bin/ping flags=(complain) {
  #include <abstractions/base>
  #include <abstractions/consoles>
  #include <abstractions/nameservice>

  capability net_raw,
  capability setuid,
  network inet raw,

  /bin/ping mixr,
  /etc/modules.conf r,
}
```

`#include <tunables/global>` Includes the file `global` in the directory
tunables. This allows statements pertaining to multiple applications to
be placed in a common file.

`/bin/ping flags=(complain)` sets the path to the profiled program and
sets the mode to *complain*.

`capability net_raw` allows the application access to the CAP_NET_RAW
POSIX.1e capability.

`/bin/ping mixr` allows the application read and execute access to the file.

`/etc/modules.conf r`. The `r` gives the application read privileges for
`/etc/modules.conf`.

**Key Permissions and Flags**

| Flag | Description |
|-|-|
| `r` | Read access |
| `w` | Write access |
| `m` | Memory map executable |
| `ix` | Execute and inherit profile |
| `Px` | Execute under another profile |
| `Ux` | Execute unconfined |


**Properties of AppArmor profiles:**

* Profiles are simple text files.
* Comments are supported and introduced with `#`.
* Absolute paths as well as file globbing can be used when specifying file
  access.
* Access controls for capabilities and networking are present.
* AppArmor profiles are easy to read and audit.
* Specificity in rule matching, i.e. the most specific rule matches (ex.
  access to `@{HOME}/bin/bad.sh` is denied with auditing due to
  `audit deny @{HOME}/bin/** mrwkl,` even though general access to
  `@{HOME}` is permitted with `@{HOME}/** rw,`).
* Include files will include the contents of a file inline to the policy.
  They are supported to ease development and simplify profiles (i .e.
  `#include <abstractions/base>`, `#include <abstractions/nameservice>`,
  `#include <abstractions/user-tmp>`).
* Variables can be defined and manipulated outside the profile
  (`#include <tunables/global>` with *@{PROC}* and *@{HOME}*).


## Managing AppArmor Profiles

### AppArmor Status

To check AppArmor:

```bash
sudo apparmor_status
```

The command shows whether AppArmor is loaded and lists all profiles in each mode.

To reload and replace an existing profile:

```bash
sudo apparmor_parser -r /etc/apparmor.d/bin.ping
```

To add a new profile:

```bash
sudo apparmor_parser -a /etc/apparmor.d/new_profile
```

### AppArmor Changing Mode

Install additional tools:

```bash
sudo apt install apparmor-utils
```

Enforce mode:

```bash
sudo aa-enforce /path/to/bin
```

Return to complain (un-enforced) mode:

```bash
sudo aa-complain /path/to/bin
```

To disable a profile:

```bash
sudo aa-disable /etc/apparmor.d/bin.ping  # Disable profile
```
Disabled profiles are symlinked in:

```bash
ls -l /etc/apparmor.d/disable/
```

### AppArmor Changing Mode for All

Enforce mode for all configured applications:

```bash
sudo aa-enforce /etc/apparmor.d/*
```

Return to complain mode:

```bash
sudo aa-complain /etc/apparmor.d/*
```

## 9.6 AppArmor Lab

In this lab we will enable AppArmor for Firefox. We will use `LABVM` 
throughout the lab.

1. Run apparmor status. There are profiles for many commands.

```bash
sudo aa-status
# or
sudo apparmor_status
```

2. How many profiles are in complain mode? How many profiles are in enforce mode?

```bash
sudo aa-status | grep ^[0-9]
```

3. Install the apparmor utilities.

```bash
sudo apt update
```

```bash
sudo apt install apparmor-utils -y
```

4. Enable/disable the tcpdump profile and confine tcpdump with AppArmor.

Check if the profile exists and it's enforced or permissive:

```bash
sudo aa-status
```

For this exercise and just as an example, we are going to disable tcpdump's profile:

```bash
sudo aa-disable /etc/apparmor.d/usr.bin.tcpdump
sudo aa-status | grep tcpdump
```

5. Put tcpdump in complain mode:

```bash
sudo aa-complain /etc/apparmor.d/usr.bin.tcpdump
```

6. Run apparmor_status and verify that tcpdump is in complain mode:

```bash
sudo apparmor_status
```

7. Disable the tcpdump profile:

```bash
sudo aa-disable /etc/apparmor.d/usr.bin.tcpdump
```

If you check `/etc/apparmor.d/disable` folder, you'll find a symlink:

```bash
ls -la /etc/apparmor.d/disable/usr.bin.tcpdump
```

Profiles in the `disable` folder will not get automatically loaded at startup.

8. Re-enforce tcpdump profile:

```bash
sudo aa-enforce /etc/apparmor.d/usr.bin.tcpdump
sudo aa-status
```

## 9.7 Host Firewall (UFW)

The Uncomplicated Firewall (**UFW**) is the default host-level firewall utility on Ubuntu. It provides a user-friendly interface to iptables, making it easier to manage firewall rules that control inbound and outbound traffic.

**Enabling UFW**

```bash
sudo ufw enable
```

To disable the firewall:

```bash
sudo ufw disable
```

> **Warning:** Enabling UFW without first allowing SSH access on remote systems may result in getting locked out. Always verify rules before applying them remotely.

### Common UFW Commands

| Command | Description |
| `ufw status` | Show current firewall rules |
| `ufw enable` | Enable firewall enforcement |
| `ufw disable` | Disable firewall enforcement |
| `ufw allow 22` | Allow incoming SSH (port 22) |
| `ufw deny 80` | Block incoming HTTP traffic |
| `ufw delete allow 22` | Delete an existing rule |
| `ufw reset` | Remove all rules and disable firewall |

**Example Rules**

```bash
sudo ufw allow ssh
sudo ufw allow 443/tcp
sudo ufw deny from 192.168.1.100
```

**Checking Firewall Status**

```bash
sudo ufw status verbose
```
> UFW is great for simple use cases. For advanced firewall configurations, Ubuntu also supports `iptables`, `nftables`, and `firewalld`.

## 9.8 UFW Lab

In this lab you will configure and verify basic firewall rules using UFW.  Remember to use `LABVM`.

1. Check the current status of the firewall

```bash
sudo ufw status verbose
```

2. Enable the firewall (if not already enabled)

```bash
sudo ufw enable
```

3. Allow SSH access (port 22)

```bash
sudo ufw allow 22/tcp
```

Verify the rule:

```bash
sudo ufw status
```

4. Block HTTP access (port 80)

```bash
sudo ufw deny 80/tcp
```

Check again:

```bash
sudo ufw status numbered
```

5. Remove the HTTP rule

```bash
sudo ufw delete <rule-number>
```

(Use the rule number shown by ufw status numbered)

6. Deny traffic from a specific IP

```bash
sudo ufw deny from 192.168.1.100
```

7. Reset all firewall rules (use with caution)

```bash
sudo ufw reset
```

This will disable the firewall and clear all existing rules.

## 9.9 Ubuntu Pro and Extended Security Maintenance (ESM) 

`Description:`

In this section you will:
* Register a machine with Ubuntu Pro
* Enable security features such as Livepatch and USG
* Explore compliance tooling and extended maintenance updates


Ubuntu Pro is Canonical’s enterprise-grade subscription for Ubuntu systems, offering extended security maintenance (ESM), compliance tooling, and kernel livepatching, all on top of an Ubuntu LTS base.  It provides a suite of services, including advanced tooling and optional phone and ticket support, to give you confidence in the security of your Ubuntu infrastructure.

**Ubuntu Pro Feature Overview**

| Feature | What It Provides | Use Case |
|-|-|-|
| Expanded Security Maintenance (ESM) | 10 years of CVE patching for all Ubuntu packages (main + universe) | Secure legacy workloads and upgrade at your own pace |
| Livepatch | Apply kernel patches for critical/high CVEs without rebooting |  Reduce unplanned downtime and extend uptime |
| Compliance & Hardening | Certified tools for CIS, DISA-STIG, FIPS, Common Criteria | Meet regulatory and security compliance on-prem and in cloud | 
| 24/7 Support (Add-on) | Phone and ticket support for your entire stack | Troubleshoot OS, infrastructure, and app issues anytime |
| Managed Services (Add-on) | Canonical engineers operate and monitor your infrastructure | Offload ops for OpenStack, Kubernetes, LXD, Ceph, and more |

Ubuntu Pro enables enterprises to use the full Ubuntu ecosystem with long-term security coverage and confidence. Originally developed for high-security environments, it is now broadly available. On public clouds, Ubuntu Pro typically adds only 3–4% to the cost of a VM, making it a cost-effective solution for securing infrastructure. This low overhead makes it easy for IT leaders to meet compliance and security goals across their Ubuntu deployments.

Ubuntu Pro is free for personal use. It offers the full suite of Ubuntu Pro capabilities for you and any business you own on up to 5 physical machines with unlimited VMs and/or containers you can run on top.

> For a full overview of Ubuntu Pro, visit: [Ubuntu Pro Documentation](https://documentation.ubuntu.com/pro/)
> 
> For usage examples of the CLI tool (`pro`), see: [Pro Client How-To Guides](https://documentation.ubuntu.com/pro-client/en/latest/)




The following lab demonstrates how to register a system with Ubuntu Pro, enable its key services, and explore security features like Livepatch and USG.

## 9.10  Ubuntu Pro: ESM, USG, and Livepatch Lab

1. Register your host with a Ubuntu Pro subscription 

Follow the process available in [Initial account setup](https://documentation.ubuntu.com/pro/account-setup/)

Obtain a token and attach your machine

```bash
sudo pro attach <pro_token>

# output
Enabling Ubuntu Pro: ESM Infra
Ubuntu Pro: ESM Infra enabled
Enabling Livepatch
Livepatch enabled
This machine is now attached to 'Ubuntu Pro (aggregate)'

SERVICE          ENTITLED  STATUS       DESCRIPTION
esm-infra        yes       enabled      Expanded Security Maintenance for Infrastructure
livepatch        yes       enabled      Canonical Livepatch service
usg              yes       disabled     Security compliance and audit tools

NOTICES
Operation in progress: pro attach

For a list of all Ubuntu Pro services, run 'pro status --all'
Enable services with: pro enable <service>

                Account: Cloudbase Field Engineering
           Subscription: Ubuntu Pro (aggregate)
            Valid until: Fri Dec 31 23:59:59 3999 UTC
Technical support level: n/a
```

2. You can check your Pro subscription status with:

```bash
sudo pro status --all
```

This lists all available services, their current status, and whether your system is entitled to use them.

> Below is a quick summary of what these services provide:

| Service | Purpose |
|-|-|
| esm-infra | Security updates for infrastructure packages |
| esm-apps | Security updates for universe application packages |
| livepatch | Apply critical kernel patches without rebooting |
| usg | Security audit and compliance tooling (e.g., CIS/FIPS) |
| fips / fips-updates |  FIPS-certified cryptography packages (compliance use cases) |
| landscape | Centralized Ubuntu system management |
| realtime-kernel | PREEMPT_RT kernel for low-latency workloads |
| ros / ros-updates | Updates and fixes for Robot Operating System (ROS) |
| anbox-cloud | Scalable Android-in-cloud runtime environments |

3. Enable `Security compliance and audit tool` feature (usg):

```bash
sudo pro enable usg
```

4. Re-check enabled services:

```bash
sudo pro status --all

# output
SERVICE          ENTITLED  STATUS       DESCRIPTION
esm-infra        yes       enabled      Expanded Security Maintenance for Infrastructure
livepatch        yes        n/a         Canonical Livepatch service
usg              yes       enabled      Security compliance and audit tools

Enable services with: pro enable <service>

                Account: Cloudbase Field Engineering
           Subscription: Ubuntu Pro (aggregate)
            Valid until: Fri Dec 31 23:59:59 3999 UTC
Technical support level: n/a
```

Once a service is enabled (like usg or livepatch), the corresponding tools are automatically installed and ready to use.

You can confirm this by checking the installed binaries:

```bash
which usg
```

5. Run a `usg audit` in your machine:

```bash
sudo usg audit cis_level1_workstation
#output
USG will execute the following command for auditing: oscap xccdf eval --profile cis_level1_workstation --cpe /usr/share/ubuntu-scap-security-guides/current/benchmarks/ssg-ubuntu2204-cpe-dictionary.xml --results /var/lib/usg/usg-results-20250603.1414.xml    /usr/share/ubuntu-scap-security-guides/current/benchmarks/ssg-ubuntu2204-xccdf.xml
Title   Package "prelink" Must not be Installed
Rule    xccdf_org.ssgproject.content_rule_package_prelink_removed
Result  pass

Title   Install AIDE
Rule    xccdf_org.ssgproject.content_rule_package_aide_installed
Result  fail

Title   Build and Test AIDE Database
Rule    xccdf_org.ssgproject.content_rule_aide_build_database
Result  fail
...
```

6. Enable and validate other services:
   
Let's also enable Livepatch and verify it's working:

```bash
sudo pro enable livepatch
#output
One moment, checking your subscription first
Installing snapd
Updating package lists
Installing canonical-livepatch snap
Canonical livepatch enabled.
```

7. Check Livepatch status after installation

```bash
sudo canonical-livepatch status

# output
last check: 10 minutes ago
kernel: 6.8.0-55.57-generic
server check-in: succeeded
kernel state: kernel series 6.8 is covered by Livepatch
patch state: no livepatches available for kernel 6.8.0-55.57-generic
tier: stable
machine id: c1d12b87e0f54044921c986bb7f584ca
```

8. Finally, to detach your VM from the Ubuntu Pro subscription you can run

```bash
sudo pro detach
```

This will uninstall any packages that were installed by the services enabled through `pro`.

# 10. Advanced Snap Packaging and Ubuntu Core !heading

`Description:`

In this section you will learn to:

* Understand Snap confinement models and security
* Manage channels and release tracking for Snaps
* Explore Ubuntu Core as a snap-based OS architecture
* Use advanced Snap commands to inspect and manage packages

> **Note:** Snap is Canonical’s universal packaging system for Linux, used heavily in Ubuntu but less common elsewhere. 
> Snap basics are covered in Ubuntu Basic Training. See command refresher below.

| Command | Description |
|-|-|
| `snap install <package>` |  Install a Snap package |
| `snap find <term>` | Search for available Snaps |
| `snap list` | List installed Snaps |
| `snap refresh <package>` | Update Snap to the latest version|
| `snap remove <package>` | Remove an installed Snap |


Snaps are self-contained, dependency-inclusive applications designed to run across multiple Linux distributions. 
Unlike traditional packages, they are confined by default, transactional, and support multiple release channels.  
All of which we explore in this chapter.



## 10.1 Snap Internals and Confinement

Snaps are self-contained application bundles that include all necessary dependencies, making them portable and consistent across Linux distributions.

Unlike traditional `.deb` packages, snaps are confined by default and integrate securely via well-defined interfaces.


### Snap Confinement Levels

A snap's confinement level is the degree of isolation it has from your system. There are three levels of snap confinement:

**Strict** 

Used by the majority of snaps. Strictly confined snaps run fully sandboxed using AppArmor, seccomp, cgroups, and namespaces, and
consequently, cannot access your files, network, processes or any other system resource without requesting specific access via 
an interface (see below).

**Classic**

Allows access to your system's resources in much the same way traditional packages do. To safeguard against abuse, publishing a 
classic snap requires manual approval, and installation requires the `--classic` command line argument.


**Devmode**

A special mode for snap creators and developers. A devmode snap runs as a strictly confined snap with full access to system resources, and produces
debug output to identify unspecified interfaces. Installation requires the `--devmode` command line argument. Devmode snaps cannot be released to the
stable channel, do not appear in search results, and do not automatically refresh.

You can view the confinement mode for any snap using the snap info `snap info --verbose <package>` command.

```bash
snap info --verbose hello-world |grep confinement
  confinement: strict
```

### Snap Interfaces and Connections

* **Interfaces** are the mechanism Snaps use to request access to external system resources or services 
(e.g., network, home directory, camera, system-observe).

* **Connections** are the actual bindings between a snap and an interface, when a connection is active, the snap can access that capability.

**Common Interface Examples**

| Interface | Grants Access To |
|-|-|
| home | Files in the user’s home directory |
| desktop | Files in the user’s desktop directory |
| network | Outbound network access |
| network-bind | Listen to incoming connections on a network port |
| system-observe | System-level process and service info |
| removable-media | USB or other external media devices |


To see what interfaces a snap uses or needs:

```bash
snap connections lxd
#output
Interface       Plug                Slot             Notes
lxd             juju:lxd            lxd:lxd          -
lxd-support     lxd:lxd-support     :lxd-support     -
network         lxd:network         :network         -
network-bind    lxd:network-bind    :network-bind    -
system-observe  lxd:system-observe  :system-observe  -
```

## 10.2 Snap Channels and Releases

Channels are an important snap concept. They define which release of a snap is installed and tracked for updates. The stable
channel is used by default, but opting to install from a different channel is easily accomplished.

There are four standard channels named edge, beta, candidate and stable. The channels represent the risk-level users should expect
from the snaps within. Edge snaps (typically built from the latest code committed) would be riskier to use than beta releases, which are riskier than stable releases.

**Default channels:**
* **stable:** Recommended for production use
* **candidate:** Release candidate builds
* **beta:** Early testing versions
* **edge:** Built from latest code, unstable

You can view available channels for a snap:

```bash
snap info firefox
```

Here is an example of the Firefox snap:

```bash
channels:
  latest/stable:    139.0.1-1     2025-05-30 (6262) 241MB -
  latest/candidate: 139.0.1-1     2025-05-30 (6262) 241MB -
  latest/beta:      140.0b4-1     2025-06-02 (6281) 241MB -
  latest/edge:      141.0a1       2025-06-03 (6286) 273MB -
  esr/stable:       128.11.0esr-1 2025-05-27 (6203) 261MB -
  esr/candidate:    128.11.0esr-1 2025-05-19 (6203) 261MB -
  esr/beta:         ↑
  esr/edge:         ↑
```

Installing from a channel can be done on the command line:

```bash
sudo snap install firefox --channel=latest/beta
#output
firefox (beta) 140.0b4-1 from Mozilla✓ installed
```

A user who already has Firefox installed can switch channel with the snap refresh command:

```bash
sudo snap refresh firefox --channel=latest/stable
#output
firefox 139.0.1-1 from Mozilla✓ refreshed
```


## 10.3 Ubuntu Core

Ubuntu Core is a minimal, immutable version of Ubuntu, designed for IoT devices and
large container deployments. It runs solely on `snaps`. And, it's trusted by
leading Internet of Things (IoT) players, from chipset vendors to device
makers and system integrators.

Smart IoT applications include digital signage, robotics, and industrial
gateways.


**Key features:**

* Everything is a snap: kernel, OS, and apps
* Secure boot, full disk encryption, and transactional updates
* Optimized for digital signage, industrial gateways, robotics, etc.
* Supports custom app stores and enterprise management

Ubuntu Core systems are highly secure by design, with a small attack surface and strict confinement.


### Why use Ubuntu Core?

Ubuntu Core uses the same kernel, libraries and system software as classic
Ubuntu. You can develop snaps on your Ubuntu PC just like any other
application. The difference is that it has been built for the Internet of
Things.

Automatic updates ensure that critical security issues are addressed in the
field, even if a device is unattended.

Ubuntu Core is free. It can be distributed at no cost, with a custom kernel,
broad support package (BSP), and suite of apps to suit your device.

Transactional over-the-air updates *with full rollback features* cut the
costs of managing devices in the field.

You can easily deploy your own app store and curate a suite of certified apps
from an open ecosystem.

![Ubuntu Core Architecture](./images/ubuntu-core.png)

Ubuntu Core is different from classic Ubuntu distributions. It is a purposely
lightweight and transactionally updated system, with security at its heart.
The fundamental unit is the `snap`, a self-contained, isolated and protected
bit of code that performs a well-defined set of functions. Even the kernel and
core are snaps.

Ubuntu Core is small because it is a base filesystem. Apps are delivered as
snaps, alongside a free choice of container runtimes and coordination systems.
And because it has a smaller attack surface, it is much more secure.

The snap system provides a highly modular and secure way to package and run applications and even core system components. This approach is fundamental to Ubuntu Core, an OS designed for embedded devices and appliances, where the entire system is built and updated with snaps.

Here are the key snap types and their roles used in Ubuntu Core:

| **Snap Type** | 	**Role** | 
|-|-|
| gadget | Board Definition: Defines the hardware layout, bootloader, and partitioning for a specific device. (Ubuntu Core specific) |
| kernel | OS Kernel: Provides the Linux kernel, enabling transactional updates of the OS core. (Primarily Ubuntu Core) |
| core | Base OS Runtime: The foundational user-space environment and essential libraries that other snaps depend on. (Fundamental to all snaps) |
| app	| User Application: Self-contained applications or services installed by users or for specific device functions. (Common across all snap-enabled systems) |


In an Ubuntu Core system (also applies to any Ubuntu system with snap packages installed) you can view mounted snaps with

```bash
mount -t squashfs | grep snap
#output
/var/lib/snapd/snaps/core20_2585.snap on /snap/core20/2585 type squashfs (ro,nodev,relatime,errors=continue,threads=single,x-gdu.hide)
/var/lib/snapd/snaps/core20_2573.snap on /snap/core20/2573 type squashfs (ro,nodev,relatime,errors=continue,threads=single,x-gdu.hide)
/var/lib/snapd/snaps/core22_1912.snap on /snap/core22/1912 type squashfs (ro,nodev,relatime,errors=continue,threads=single,x-gdu.hide)
/var/lib/snapd/snaps/core22_1966.snap on /snap/core22/1966 type squashfs (ro,nodev,relatime,errors=continue,threads=single,x-gdu.hide)
/var/lib/snapd/snaps/lxd_31335.snap on /snap/lxd/31335 type squashfs (ro,nodev,relatime,errors=continue,threads=single,x-gdu.hide)
/var/lib/snapd/snaps/snapd_23772.snap on /snap/snapd/23772 type squashfs (ro,nodev,relatime,errors=continue,threads=single,x-gdu.hide)
/var/lib/snapd/snaps/snapd_24509.snap on /snap/snapd/24509 type squashfs (ro,nodev,relatime,errors=continue,threads=single,x-gdu.hide)
/var/lib/snapd/snaps/core24_992.snap on /snap/core24/992 type squashfs (ro,nodev,relatime,errors=continue,threads=single,x-gdu.hide)
/var/lib/snapd/snaps/juju_31167.snap on /snap/juju/31167 type squashfs (ro,nodev,relatime,errors=continue,threads=single,x-gdu.hide)
/var/lib/snapd/snaps/core_17206.snap on /snap/core/17206 type squashfs (ro,nodev,relatime,errors=continue,threads=single,x-gdu.hide)
/var/lib/snapd/snaps/hello-world_29.snap on /snap/hello-world/29 type squashfs (ro,nodev,relatime,errors=continue,threads=single,x-gdu.hide)
/var/lib/snapd/snaps/bare_5.snap on /snap/bare/5 type squashfs (ro,nodev,relatime,errors=continue,threads=single,x-gdu.hide)
/var/lib/snapd/snaps/gtk-common-themes_1535.snap on /snap/gtk-common-themes/1535 type squashfs (ro,nodev,relatime,errors=continue,threads=single,x-gdu.hide)
/var/lib/snapd/snaps/firefox_6281.snap on /snap/firefox/6281 type squashfs (ro,nodev,relatime,errors=continue,threads=single,x-gdu.hide)
/var/lib/snapd/snaps/gnome-42-2204_201.snap on /snap/gnome-42-2204/201 type squashfs (ro,nodev,relatime,errors=continue,threads=single,x-gdu.hide)
/var/lib/snapd/snaps/firefox_6262.snap on /snap/firefox/6262 type squashfs (ro,nodev,relatime,errors=continue,threads=single,x-gdu.hide)
```


## 10.4  Advanced Snap Lab.

Run the following commands on the `LABVM` machine.

In this lab we will work with Snappy.


1. Make sure snapd is installed

```bash
sudo apt update
sudo apt install -y snapd
```

2. Search for `firefox` snap package

```bash
snap find firefox
```

3. Get information about the channels available for it.

```bash
snap info --verbose firefox
```


4. Install the snap from the stable channel.

```bash
sudo snap install --channel=latest/stable firefox
```

You can verify the version installed by running:

```bash
firefox --version

which firefox
```

Path output from the `which` command points to `/snap/bin/firefox` so that file comes from a snap.

5. Let's say a bug was fixed only on the edge version of the application. Refresh the snap and change the channel:

```bash
sudo snap refresh firefox --channel=latest/edge
```

6. Verify the version again. 

```bash
firefox --version
```

7. Some snaps may have updates available. See if this is the case.

```bash
sudo snap refresh --list
```

8. Check the connections the snap `package` has.

```bash
snap connections firefox
```

9. Snap refreshes are done periodically. If you want to disable that behavior, run:

```bash
sudo snap refresh --hold firefox
```

If you run a `snap list` again, you should see `held` in the `Notes` section.
Holding can be done indefinitely or time-based.

10.  Some of the snaps installed may be system wide services.

```bash
sudo snap services
```

11.  Snaps are read only, `squashfs` type mounts. This is the source of some of the snaps security. This can actually be seen. 

```bash
sudo mount -t squashfs | grep snap
```
> Note: Even though this VM doesn’t have a GUI environment, Firefox serves as a good example because it’s a real-world, multi-interface snap with multiple channels and regular updates.

12. Cleanup

```bash
# Optional cleanup
sudo snap refresh --unhold firefox
sudo snap remove firefox
```

# 11. Advanced System Topics !heading

> **Note:** This section includes supplemental topics not covered during the 3-day training. These topics support specific enterprise use cases, debugging, logging integration, or advanced storage. You may use them to deepen your understanding or reference them for production environments.

## 11.1 Time Synchronization with chrony & timesyncd
===

> **Why it matters:**
> In modern infrastructure, time synchronization is critical for authentication, log correlation, monitoring, certificates, orchestration, and distributed systems. A time drift of even a few seconds can cause failures in Kerberos, TLS handshakes, cron jobs, and database replication. Consistent, accurate time across servers and services is a fundamental requirement in enterprise environments.

### Network Time Protocol (NTP)
---

NTP (Network Time Protocol) is a well-established Internet standard used to synchronize clocks between systems. It operates in a hierarchical structure: **stratum 0** devices (such as atomic clocks or GPS) feed **stratum 1** servers, which in turn provide time to **stratum 2 and 3 clients** across the network. Communication occurs over UDP port 123, and the protocol compensates for latency and jitter to maintain sub-second accuracy.

In enterprise environments, it’s common to designate **an internal NTP server** (often a stratum 2 or 3 server) to synchronize all machines within the network. This server may run Ubuntu, be a dedicated network appliance, or be integrated into other infrastructure such as Active Directory domain controllers in mixed-platform environments.

By centralizing time sync to an internal source, organizations ensure consistent timestamps across services, critical for authentication protocols, log correlation, monitoring, job scheduling, and distributed systems.

Ubuntu uses `systemd-timesyncd` by default for lightweight time synchronization. For environments requiring higher precision, advanced configuration, or NTP server capabilities, the `chrony` package can be used. When `chrony` is installed, it automatically disables timesyncd to avoid conflicts and takes over as the system’s time synchronization service.

### Network Time Security (NTS)

While NTP is effective, it’s **not secure by design**; attackers could spoof time responses or manipulate clock drift. **NTS (Network Time Security)**, defined in RFC8915, adds encryption and integrity validation using TLS and cookies, preventing tampering or spoofing.

Ubuntu 25.04+ now defaults to Canonical-hosted NTS-enabled NTP servers, making secure time sync easy and automatic with chrony.

Learn more: [Serve NTP with chrony](https://documentation.ubuntu.com/server/how-to/networking/serve-ntp-with-chrony/index.html)

The current status of NTP time configuration via `timedatectl` and `timesyncd`
can be checked with `timedatectl status`.

```bash
timedatectl status

# output
               Local time: Fri 2025-03-07 09:11:01 UTC
           Universal time: Fri 2025-03-07 09:11:01 UTC
                 RTC time: Fri 2025-03-07 09:11:01
                Time zone: Etc/UTC (UTC, +0000)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
```
If NTP is installed, the line "NTP synchronized" is set to yes.

**Useful commands**
```bash
timedatectl status          # Check sync status
timedatectl timesync-status # View current time server
systemctl status systemd-timesyncd # Check default service
```

**Installing chrony**

```bash
sudo apt install chrony -y
systemctl status chrony
chronyc tracking
chronyc sources
```

**To configure chrony with NTS for secure time synchronization:**

```bash
sudo tee /etc/chrony/sources.d/cloudflare.sources <<EOF
server time.cloudflare.com nts iburst
EOF

sudo systemctl restart chrony
chronyc -N authdata # -N disables DNS lookups for faster output
```
> Note: NTS requires support from the NTP server. Not all public pools support NTS, so verify the source (e.g., Cloudflare does).


## 11.2 Time Synchronization Lab
===

Make sure you are on the `LABVM`.

In this lab you will learn how to check current NTP settings and how to install and use chrony.

1. Check current status of time synchronization:

```bash
timedatectl status

# output
               Local time: Fri 2025-03-07 09:11:01 UTC
           Universal time: Fri 2025-03-07 09:11:01 UTC
                 RTC time: Fri 2025-03-07 09:11:01
                Time zone: Etc/UTC (UTC, +0000)
System clock synchronized: yes
              NTP service: active
          RTC in local TZ: no
```

By default, chrony is not installed and `systemd-timesyncd` is used. You can check the service is running with:

```bash
systemctl status systemd-timesyncd

# output
— systemd-timesyncd.service - Network Time Synchronization
     Loaded: loaded (/usr/lib/systemd/system/systemd-timesyncd.service; enabled; preset: enabled)
     Active: active (running) since Fri 2025-03-07 08:05:57 UTC; 1h 9min ago
       Docs: man:systemd-timesyncd.service(8)
   Main PID: 668 (systemd-timesyn)
     Status: "Contacted time server 185.125.190.58:123 (ntp.ubuntu.com)."
      Tasks: 2 (limit: 9429)
     Memory: 1.4M (peak: 1.9M)
        CPU: 77ms
     CGroup: /system.slice/systemd-timesyncd.service
             668 /usr/lib/systemd/systemd-timesyncd

Mar 07 08:05:57 ubuntu systemd[1]: Starting systemd-timesyncd.service - Network Time Synchronization...
Mar 07 08:05:57 ubuntu systemd[1]: Started systemd-timesyncd.service - Network Time Synchronization.
Mar 07 08:05:59 ubuntu systemd-timesyncd[668]: Network configuration changed, trying to establish connection.
Mar 07 08:06:01 ubuntu systemd-timesyncd[668]: Network configuration changed, trying to establish connection.
Mar 07 08:06:32 ubuntu systemd-timesyncd[668]: Contacted time server 185.125.190.58:123 (ntp.ubuntu.com).
Mar 07 08:06:32 ubuntu systemd-timesyncd[668]: Initial clock synchronization to Fri 2025-03-07 08:06:32.734034 UTC.
```

So, in this case, time synchronization is handled by `systemd-timesyncd`. Let's check which server is used to get the time from and more details about time synchronization on our server:

```bash
timedatectl timesync-status
       Server: 185.125.190.58 (ntp.ubuntu.com)
Poll interval: 34min 8s (min: 32s; max 34min 8s)
         Leap: normal
      Version: 4
      Stratum: 2
    Reference: 4FF33C32
    Precision: 1us (-25)
Root distance: 1.433ms (max: 5s)
       Offset: +31.323ms
        Delay: 3.987ms
       Jitter: 11.048ms
 Packet count: 8
    Frequency: +57.905ppm
```

2. Check whether chrony is installed. If not present, install it:

```bash
dpkg-query --list chrony
```

```bash
sudo apt install -y chrony
```

```bash
# ntp should appear now
dpkg-query --list chrony
```

3. Inspect current chrony configuration and see if it's actually running properly. Also, once the `chrony` package is installed, the old `systemd-timesyncd` service is disabled.

```bash
systemctl status systemd-timesyncd

# output
* systemd-timesyncd.service
     Loaded: masked (Reason: Unit systemd-timesyncd.service is masked.)
     Active: inactive (dead) since Fri 2025-03-07 09:20:17 UTC; 14s ago
   Main PID: 565 (code=exited, status=0/SUCCESS)
     Status: "Idle."
        CPU: 200ms

```

Next, check if `chrony` service is running:

```bash
systemctl status chrony

# output
— chrony.service - chrony, an NTP client/server
     Loaded: loaded (/usr/lib/systemd/system/chrony.service; enabled; preset: enabled)
     Active: active (running) since Fri 2025-03-07 09:20:17 UTC; 3min 40s ago
       Docs: man:chronyd(8)
             man:chronyc(1)
             man:chrony.conf(5)
    Process: 3321 ExecStart=/usr/lib/systemd/scripts/chronyd-starter.sh $DAEMON_OPTS (code=exited, status=0/SUCCESS)
   Main PID: 3330 (chronyd)
      Tasks: 2 (limit: 9429)
     Memory: 1.4M (peak: 2.2M)
        CPU: 63ms
     CGroup: /system.slice/chrony.service
             3330 /usr/sbin/chronyd -F 1
             3331 /usr/sbin/chronyd -F 1
```

Next, check if time is synchronized with any NTP server:

```bash
chronyc tracking

# output
Reference ID    : B97DBE39 (prod-ntp-4.ntp1.ps5.canonical.com)
Stratum         : 3
Ref time (UTC)  : Fri Mar 07 09:24:42 2025
System time     : 0.000185829 seconds fast of NTP time
Last offset     : +0.000258049 seconds
RMS offset      : 0.000952902 seconds
Frequency       : 65.335 ppm slow
Residual freq   : +0.128 ppm
Skew            : 3.314 ppm
Root delay      : 0.004664005 seconds
Root dispersion : 0.001002416 seconds
Update interval : 64.4 seconds
Leap status     : Normal
```

You can also check all servers which will be used for time synchronization with:

```bash
chronyc sources

# output
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^- alphyn.canonical.com          2   6   377    42  +2386us[+2386us] +/-   60ms
^* prod-ntp-4.ntp1.ps5.cano>     2   6   377    43  +3020ns[  -12us] +/- 2329us
^+ prod-ntp-5.ntp4.ps5.cano>     2   6   377    41   +349us[ +349us] +/- 2538us
^+ prod-ntp-3.ntp4.ps5.cano>     2   6   377    41   +327us[ +327us] +/- 2128us
^- ntp2.as200552.net             2   6   377    40  +1833us[+1833us] +/-   24ms
^- time.videxio.net              2   6   377    42   -886us[ -886us] +/-   36ms
^+ ntp2.leontp.com               1   6   377    43   -512us[ -528us] +/- 3386us
^+ pool.ntp1.cam.ac.uk           2   6   377   106   -172us[ -173us] +/- 5831us
```

Since NTP is not a very secure protocol as discussed before, let's configure `chrony` to only use NTS instead of NTP.
First, inspect current configuration of `chrony`:

```bash
cat /etc/chrony/chrony.conf

# output
...
# This will use (up to):
# - 4 sources from ntp.ubuntu.com which some are ipv6 enabled
# - 2 sources from 2.ubuntu.pool.ntp.org which is ipv6 enabled as well
# - 1 source from [01].ubuntu.pool.ntp.org each (ipv4 only atm)
# This means by default, up to 6 dual-stack and up to 2 additional IPv4-only
# sources will be used.
# At the same time it retains some protection against one of the entries being
# down (compare to just using one of the lines). See (LP: #1754358) for the
# discussion.
#
# About using servers from the NTP Pool Project in general see (LP: #104525).
# Approved by Ubuntu Technical Board on 2011-02-08.
# See http://www.pool.ntp.org/join.html for more information.
pool ntp.ubuntu.com        iburst maxsources 4
pool 0.ubuntu.pool.ntp.org iburst maxsources 1
pool 1.ubuntu.pool.ntp.org iburst maxsources 1
pool 2.ubuntu.pool.ntp.org iburst maxsources 2
...
```

Next, let's add a new sources file to the chrony configuration folder:

```bash
sudo tee /etc/chrony/sources.d/cloudflare.sources <<EOF
server time.cloudflare.com nts iburst
EOF
```

Also, you'll need to comment out all `pool` references from `/etc/chrony/chrony.conf` so the end result will look like:

```bash
...
# pool ntp.ubuntu.com        iburst maxsources 4
# pool 0.ubuntu.pool.ntp.org iburst maxsources 1
# pool 1.ubuntu.pool.ntp.org iburst maxsources 1
# pool 2.ubuntu.pool.ntp.org iburst maxsources 2
...
```

After which, you'll need to restart `chrony` service with:

```bash
  sudo systemctl restart chrony
```

Now, check current sources used for time synchronization:

```bash
chronyc sources -v

# output
  .-- Source mode  '^' = server, '=' = peer, '#' = local clock.
 / .- Source state '*' = current best, '+' = combined, '-' = not combined,
| /             'x' = may be in error, '~' = too variable, '?' = unusable.
||                                                 .- xxxx [ yyyy ] +/- zzzz
||      Reachability register (octal) -.           |  xxxx = adjusted offset,
||      Log2(Polling interval) --.      |          |  yyyy = measured offset,
||                                \     |          |  zzzz = estimated error.
||                                 |    |           \
MS Name/IP address         Stratum Poll Reach LastRx Last sample
===============================================================================
^* time.cloudflare.com           3   6   377   421    +72us[  +17us] +/- 5759us
```

To actually check is using NTS instead of NTP:

```bash
sudo chronyc -N authdata

# output
Name/IP address             Mode KeyID Type KLen Last Atmp  NAK Cook CLen
=========================================================================
time.cloudflare.com          NTS     1   30  128  348    0    0    8   64
```

## 11.3 Traditional Logging with rsyslog


Ubuntu uses `systemd-journald` for structured logging of all system and application events. At the same time, `rsyslog` is still installed by default on most Ubuntu systems, primarily to preserve compatibility with traditional logging workflows that rely on plain text log files under `/var/log`.

By default, `rsyslog` and `journald` operate independently. Integration between the two, where journald forwards messages to rsyslog, requires enabling `ForwardToSyslog=yes` in `/etc/systemd/journald.conf`. When configured, `rsyslog` reads logs via the `imuxsock` module.

`rsyslog` is a modernized continuation of the original `syslog` daemon, providing:

* Backward compatibility with `/etc/syslog.conf` format
* Modular architecture and support for advanced filtering
* Secure remote logging with TLS
* Output options including files, databases, external services
* Support for traditional logging tools that expect logs like `/var/log/syslog` or `/var/log/auth.log`

While many newer environments rely solely on `journald`, `rsyslog` remains essential when:

* Interfacing with legacy applications and tooling
* Shipping logs to external log collectors
* Maintaining text-based logs for compliance or forensics

In modern Ubuntu systems, `rsyslog` is useful for log persistence, centralization, and custom log workflows.


**Configure rsyslog**

**rsyslog** is installed by default by all Ubuntu images. If for any reason
it is not installed, it can be installed with:

```bash
sudo apt install rsyslog -y
```

An additional documentation package can be installed using:

```bash
sudo apt install rsyslog-doc -y
```

Check that it's running with:

```bash
sudo systemctl status rsyslog

# output
— rsyslog.service - System Logging Service
     Loaded: loaded (/usr/lib/systemd/system/rsyslog.service; enabled; preset: enabled)
     Active: active (running) since Fri 2025-03-07 08:06:03 UTC; 2h 26min ago
TriggeredBy: — syslog.socket
       Docs: man:rsyslogd(8)
             man:rsyslog.conf(5)
             https://www.rsyslog.com/doc/
   Main PID: 980 (rsyslogd)
      Tasks: 4 (limit: 9429)
     Memory: 3.4M (peak: 5.0M)
        CPU: 198ms
     CGroup: /system.slice/rsyslog.service
             980 /usr/sbin/rsyslogd -n -iNONE
...
```

The rsyslogd process can be seen with ps:

```bash
ps aux | grep rsyslogd

# output
syslog       980  0.0  0.0 222508  6404 ?        Ssl  08:06   0:00 /usr/sbin/rsyslogd -n -iNONE
```

After any configuration changes, a restart of the rsyslog service is required:

```shell
sudo systemctl restart rsyslog
```
The main configuration file for rsyslog by default is `/etc/rsyslog.conf`.
Additional configuration can be made in files placed in the `/etc/rsyslog.d`
directory. The rsyslog configuration typically includes the following sections: 
*modules*, *global directives*, *filter rules*, and comments for explanation (#). 
Modules and global directives are specified
in the same way: one line at a time, starting with a dollar sign ($).

**Modules**
---

The Modules section specifies the modules and plugins to be loaded. These
affect how the `rsyslogd` daemon operates and the sources it reads from
and logs to.

For example, the `imuxsock` and `imklog` modules are here by default:
* the `imuxsock` module handles logging on local system processes
* the `imklog` module handles kernel logging.

```rsyslog
module(load="imuxsock") # provides support for local system logging
module(load="imklog" permitnonkernelfacility="on")
```

Other available [modules](https://www.rsyslog.com/doc/configuration/modules/index.html#modules) and [plugins](https://www.rsyslog.com/plugins/) can be found in the rsyslog documentation and provide support for different input and output formats including different databases like MySQL and PostgreSQL.

**Global Directives**
---

Global directives are configuration options for the rsyslogd daemon. These
are specified in the same way as modules, on individual lines with a dollar
sign ($). These are outside of the scope of this documentation, but here are
some examples from a default configuration:

```rsyslog
# Use traditional timestamp format.
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
$RepeatedMsgReduction on

# Set the default permissions for all log files.
$FileOwner syslog
$FileGroup adm
$FileCreateMode 0640
$DirCreateMode 0755
$Umask 0022
$PrivDropToUser syslog
$PrivDropToGroup syslog

# Where to place spool and state files
$WorkDirectory /var/spool/rsyslog

# Include all config files in /etc/rsyslog.d/
$IncludeConfig /etc/rsyslog.d/*.conf
```


**Filter Rules**
---

A filtering rule is made up of two main sections known as a selector and
action, separated by spaces or tabs. For example:

```rsyslog
daemon.* /var/log/daemon. log
```

The selector section on the left side is further broken down into another
two keywords on either side of a period (`.`). The first is called the
facility and refers to different parts of the the operation system defined
by the traditional Syslog protocol. The second keyword is the priority,
from a list ranging from `debug` to `panic` also specified in the syslog
protocol. Use an asterisk (*) as a wildcard to match any facility or priority.

Multiple selectors can be specified in one rule using a semicolon to separate
them. Each of them will be subject to the same action. The right-hand section
of the rule is the action and determines what will be done with the messages
filtered by the selector criteria. The available actions are partly determined
by the output modules explained earlier, but most commonly, the action simply
contains the output destination of the messages caught by the filter, i.e. a
file in `/var/log`.

Examples of different facilities that can be specified as part of a filter rule:

Keyword | Description
---     | ----
kern    | Kernel messages
user    | User-level messages
daemon  | System daemon messages
auth    | Security/authorization messages

Examples of priorities:

Keyword | Description
---     | ---
emerg   | Emergency: system is unusable
alert   | Alert: action must be taken immediately
warning | Warning: warning conditions
notice  | Notice: normal but significant condition
info    | Information: information messages


## 11.4 rsyslog Lab
===

In this lab you will work with rsyslog

1. View the logfiles on the system. Example: kern.log, syslog, auth.log.

> Most logs are under `/var/log`.

```bash
cd /var/log
ls -lt
```

2. Some applications with logging (audit-trail/security) requirements may have their own subdirectories.
Example: apparmor, apt and installer.

3. Two files with errors are kern and dpkg (install and boot). Look at these errors.

```bash
sudo grep -rliE "error|failed" /var/log
```

4. Install rsyslog.

```bash
sudo apt install rsyslog -y
```

5. Get additional documentation.

```bash
sudo apt install rsyslog-doc -y
```

6. Make sure it's running.

```bash
sudo systemctl status rsyslog
```

7. Explore the `/var/log` directory.

```bash
tree /var/log/
# output
/var/log/
├── alternatives.log
├── apparmor
├── apport.log
├── apt
│   ├── history.log
│   ├── term.log
├── auth.log
├── btmp
├── cloud-init-output.log
├── cloud-init.log
├── dist-upgrade
├── dmesg
├── dmesg.0
├── dpkg.log
├── fontconfig.log
├── journal
│       ├── system.journal
│       ├── system@bf67dff5bf44404b94e9a3fc05e0d537-0000000000000a92-000636226289ebec.journal
├── kern.log
├── landscape
│   └── sysinfo.log
├── lastlog
├── libvirt
│   ├── lxc
│   ├── qemu
│   │   ├── internalvm.log
│   │   └── ubuntu.log
│   └── uml
├── openvswitch
│   ├── ovs-vswitchd.log
│   ├── ovsdb-server.log
├── syslog
├── ubuntu-advantage-apt-hook.log
├── ubuntu-advantage.log
```

8. Enable journald -> rsyslog pipeline by forwarding logs:
  
```bash
sudo sed -i 's/^#ForwardToSyslog=no/ForwardToSyslog=yes/' /etc/systemd/journald.conf
sudo systemctl restart systemd-journald
```
9. Simulate remote log forwarding:

```bash
echo "*.warn @127.0.0.1:514" | sudo tee /etc/rsyslog.d/99-remote.conf
sudo systemctl restart rsyslog
```
> This mimics forwarding logs to a remote SIEM or log aggregator. 

## 11.5 Diagnostic Tools: sosreport & apport
===

When troubleshooting complex issues on Ubuntu Server, collecting detailed logs and system metadata is critical for identifying root causes and communicating with support teams.

The primary tool for this in enterprise environments is **sosreport**, a utility that generates a complete archive of diagnostic information, including system configuration, logs, package data, hardware status, and more. It is the recommended tool when opening support cases through Ubuntu Pro or Canonical’s commercial channels.

For development-centric bug reporting, **apport** can be used to gather environment information and submit reports to Launchpad, Ubuntu’s community-driven bug tracker. While useful in desktop or upstream debugging workflows, apport is less common in production server environments.

* Use `sosreport` to escalate issues to Canonical support.
* Use `apport` for community bug tracking and developer engagement (e.g., Launchpad)


### sosreport
---

**sosreport** is the standard utility for collecting detailed diagnostic information from a running Ubuntu system. It produces a compressed tar archive containing configuration data, logs, installed packages, hardware status, network details, kernel modules, and more.

This archive can be used internally by sysadmins or sent to Canonical when opening a **support case through Ubuntu Pro**.

sosreport is modular and extensible, supporting a wide range of system components. It can optionally generate an HTML or XML summary report inside the archive for easier review.

> **Ideal for:** support escalation, postmortem investigations, compliance audits

**sosreport** generates a compressed tar archive of diagnostic information
from the running system. The archive may be stored locally or centrally for
recording or tracking purposes or may be sent to technical support representatives,
developers or system administrators to assist with technical fault-finding and
debugging.


### apport
---

**apport** is a tool designed to help end-users and developers report software bugs in Ubuntu. It automatically captures crash data, system information, and package details to assist with debugging particularly for issues affecting desktop environments or user-facing applications.

On Ubuntu Server, apport is less commonly used, but can still be valuable when reporting issues to the Ubuntu community via Launchpad. It helps ensure bug reports include sufficient detail to be actionable, reducing back-and-forth during triage.

Typical use cases include:
* Crashes in background services or scripts
* Package install/upgrade failures
* Filing structured bug reports tied to specific packages

Apport is a system which:

* intercepts crashes right when they happen the first time,
* gathers potentially useful information about the crash and the OS environment,
* can be automatically invoked for unhandled exceptions in other programming
  languages (ex. in Ubuntu this is done for Python),
* can be automatically invoked for other problems that can be automatically
  detected (ex. Ubuntu automatically detects and reports package installation/
  upgrade failures from update-manager),
* presents a UI that informs the user about the crash and instructs them on how
  to proceed,
* and is able to file non-crash bug reports about software, so that developers
  still get information about package versions, OS version etc.


### 11.6 Sosreport and Apport Lab
---

1. Check to see if `sosreport` is installed. If not, install it.

```bash
dpkg -l | grep sosreport
```

```bash
sudo apt install sosreport -y
```

2. Run `sosreport` and view the results.

> Hit `ENTER` when needed.

```bash
sudo sos report
# output
sosreport (version 4.7.2)

This command will collect system configuration and diagnostic
information from this Ubuntu system.

For more information on Canonical visit:

        Community Website  : https://www.ubuntu.com/
        Commercial Support : https://www.canonical.com

The generated archive may contain data considered sensitive and its
content should be reviewed by the originating organization before being
passed to any third party.

No changes will be made to system configuration.


Press ENTER to continue, or CTRL-C to quit.
...
```

> Review the file in `/tmp/`

3. Review some of the configuration files in the apport directory.

```bash
ls -l /etc/apport
```

4. To enable crash reporting with apport, edit `/etc/apport/crashdb.conf` and comment the line with `#`:

```python
'problem_types': ['Bug', 'Package'],
```
Change it to:

```python
#'problem_types': ['Bug', 'Package'],
```
This **removes** filtering and allows full crash interception.

To **disable** it again, remove the `#` from the line to restrict reporting to only specific types; effectively turning interception off.

## 11.7 XFS Filesystem (Advanced)

> **Note:** XFS is a high-performance journaling filesystem suitable for specific workloads. While powerful, it’s less commonly used as the default on Ubuntu systems compared to ext4 or ZFS. This section is provided for advanced users who need to work with XFS.

**Overview**

XFS is a journaled 64-bit filesystem that supports high performance, scalability, and advanced features. An XFS filesystem can reside on a regular disk partition or a logical volume.

**XFS Filesystem Structure**

An XFS filesystem has up to three parts:

* A *data section* - contains the filesystem metadata (inodes, directories,
  indirect blocks), the user file data for ordinary files, and the log area (if
  it is internal to the data section). The data section is divided into a number
  of allocation groups which controls parallelism in file and block allocation.
  Each allocation group contains several data structures. The first sector
  contains the **superblock**. Other allocation groups contain information for
  block and inode allocation within the allocation group and data structures
  to locate free blocks and inodes.
* A *log section* or journal - used to store changes to filesystem metadata while the
  filesystem is running until those changes are committed to the data section.
  It is written sequentially during normal operation and is accessed read only
  during mount. When mounting a filesystem after a crash, the log is read to
  complete operations that were in progress at the time of the crash.
* A *real-time section* - used to store the data of real-time files. It is
  divided into a number of extents of fixed size (specified at mkfs.xfs time).
  Each file in the real-time section has an extent size that is a multiple of
  the real-time section extent size.

**Key Concepts**

* **Extents:** Contiguous blocks of storage representing a file’s data. Extents reduce fragmentation and metadata overhead.
* **UUID:** Each XFS filesystem includes a UUID stored in its allocation group headers to uniquely identify it.

**Required Software**

To work with XFS filesystems on Ubuntu:

* The `xfs` kernel module must be available. It is included by default in Ubuntu kernels and loads automatically when mounting an XFS filesystem.
* The `xfsprogs` package includes all tools needed to manage XFS filesystems, including:

* `mkfs.xfs`: Format a partition with XFS
* `xfs_repair`: Check and repair XFS filesystems
* `xfs_growfs`: Grow a mounted XFS filesystem
* `xfs_fsr`: Defragment XFS filesystems
* `xfs_freeze`: Freeze/unfreeze I/O for snapshots
* `xfsdump` / `xfsrestore`: Backup and restore XFS filesystems

**XFS Features**

* Journaling for metadata
* Scalable to large filesystems (up to theoretical 8 exbibytes) and file counts
* Supports extended attributes and quotas
* Can do direct (non-cached) filesystem I/O using DMA (Direct Memory Access)
* Allows applications to reserve bandwidth to disk for a specified time due
  to guaranteed-rate I/O operations.
* Can freeze filesystem I/O during LVM snapshot using `xfs_freeze`
* Provides online defragmentation (`xfs_fsr`) and online resizing (`xfs_growfs`)
* Provides native backup/restore using `xfsdump` and `xfsrestore`


**Tuning XFS**

* Most RAID controllers supply striping information that XFS can use to
  self-optimize. For those that don't, it can be set using `mkfs` options *-sw/-su*.
* The amount of journal information in RAM can improve performance. Add *logbufs=8*
  to fstab or mount.xfs.
* Use variable block size feature: _4KB_ for a few million directory entries,
  _16KB_ or _64KB_ for larger (>10 million).
* Distribute large numbers of files in different directories to maximize concurrency
  between allocation groups


## 11.8 XFS Lab

Run the following commands on the `LABVM` machine.

1. Install the needed XFS software.

```bash
sudo apt install -y xfsprogs xfsdump
```

2. Create an `xfs` filesystem on `/dev/vdc`, create a mount point, and mount it. Use `-f` to overwrite:

```bash
sudo wipefs -a /dev/vdc #WARNING: Ensure the disk is not in use before wiping
sudo parted /dev/vdc mklabel gpt
sudo parted -a optimal /dev/vdc mkpart primary 1MiB 100%
sudo mkfs.xfs -L "datavol" -f /dev/vdc1
sudo mkdir /media/xfsmnt
sudo mount -t xfs /dev/vdc1 /media/xfsmnt
```

3. View the mounted drive.

```bash
mount | grep vd
```

4. Add the partition to `/etc/fstab` for automount as shown:

```bash
sudo vim /etc/fstab
```

> Add the following line, use any editor.

```bash
/dev/vdc1 /media/xfsmnt xfs rw,relatime,attr2,inode64,noquota 0 0
```

> Save and exit.


5. Unmount the already mounted partition and verify that it is unmounted.

```bash
sudo umount /media/xfsmnt
```

```bash
mount | grep vd
```

6. Remount the disk using `fstab` and verify that it is mounted.

```bash
sudo mount -a
```

```bash
mount | grep vd
```


**Other XFS Commands**

> You need to run the following commands as `root` or using `sudo`.

1. Freeze the filesystem IO when taking a snapshot.

```bash
# freeze
sudo xfs_freeze -f /media/xfsmnt
```

> `xfs_freeze` halts new access to the filesystem and creates a stable
> image on disk. `xfs_freeze` is intended to be used with volume managers
> and hardware RAID devices that support the creation of snapshots.

```bash
# unfreeze
sudo xfs_freeze -u /media/xfsmnt
```

2. Defrag the drive `/dev/vdc1`.

```bash
sudo xfs_fsr /dev/vdc1
```

> `xfs_fsr` improves the organization of `mounted` filesystems.
> The reorganization algorithm operates on one file at a time,
> compacting or otherwise improving the layout of the file extents
> (contiguous blocks of file data).


3. Grow the filesystem (if full).

```bash
sudo xfs_growfs /media/xfsmnt
```

> `xfs_growfs` is most often used in conjunction with logical volumes.
> However, it can also be used on a regular disk partition, for example
> if a partition has been enlarged while retaining the same starting block.


4. Backup and restore the XFS filesystem.

```bash
sudo xfsdump - /media/xfsmnt > /tmp/xfs.dump
```

```bash
sudo xfsrestore - /media/xfsmnt < /tmp/xfs.dump
```


**Tuning commands**

1. Use the man pages to search for `mkfs.xfs` and the options `sunit`
and `swidth`.

```bash
man 5 xfs
```

2. Specify stripe unit and stripe width in terms of 512 byte blocks.

```bash
sudo umount /dev/vdc1
```

```bash
sudo mkfs.xfs -d sunit=128 -d swidth=384 /dev/vdc1 -f
```

```bash
sudo mount /dev/vdc1
```

3. Improve logging with *logbufs=8*

```bash
sudo vim /etc/fstab
```

> Add `logbufs=8` to the xfs mount options and remount:
The line should look like this.

```bash
/dev/vdc1 /media/xfsmnt xfs rw,relatime,attr2,inode64,noquota,logbufs=8 0 0
```

4. Remount the volume

```bash
sudo mount -o remount /media/xfsmnt
```
5. Verify

```bash
mount | grep vd
```

**Cleanup**


1. Unmount any remaining mount point and remove the mount point from `/etc/fstab`.

```bash
sudo umount /media/xfsmnt
```

```bash
sudo vim /etc/fstab
# remove `/dev/vdc1 /media/xfsmnt` line
```

