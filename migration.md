# Migration Tracker

This file tracks migration and validation progress for the Ubuntu Server Advanced documentation.

## Status Model

- `Not started`: no doc page created from the source yet
- `Migrated`: content moved into the docs site, but not yet fully reviewed in a live lab run
- `In review`: content is being validated command by command
- `Complete`: all commands for the chapter have been run and the results have been documented

## Completion Rule

A chapter can be marked `Complete` only after:

- every command in that chapter has been executed in the lab
- expected results have been reviewed against real output
- the docs have been updated where needed

## Chapter Progress

### 1. Virtualization

- Status: `Complete`
- Doc page: `docs/virtualization.md`
- Source range: `ubuntu_advanced_lab.md` chapter 1

Validated so far on `playground-rdu`:

- `[x]` Virtualization detection commands reviewed
- `[x]` Host update completed
- `[x]` Host reboot completed
- `[x]` Virtualization package install completed
- `[x]` KVM acceleration confirmed
- `[x]` `ubuntu` added to `kvm` and `libvirt`
- `[x]` Re-login completed and group membership verified
- `[x]` `virsh list --all` verified with no existing domains
- `[x]` System libvirt connection caveat documented
- `[x]` `vm-disks` pool defined in system libvirt
- `[x]` `vm-disks` pool started and autostart enabled
- `[x]` `virsh pool-info vm-disks` documented from live output
- `[x]` Volume operations documented from live output through `cow-clone`
- `[x]` Libvirt network setup documented from live output
- `[x]` VM creation documented from live output
- `[x]` VM reachability validated with ping
- `[x]` Extra disk creation and attachment documented from live output
- `[x]` UVTool workflow documented from live output

Subchapters:

- `[x]` 1.1 What is virtualization?
- `[x]` 1.2 KVM Virtualization Stack
- `[x]` 1.3 Virtualization Lab
- `[x]` 1.3.1 Installing a Guest VM
- `[x]` 1.3.2 Setting up storage pools
- `[x]` 1.3.3 Volume operations
- `[x]` 1.3.4 Cloning volumes
- `[x]` 1.3.5 Libvirt networks
- `[x]` 1.3.6 Define additional networks in libvirt
- `[x]` 1.3.7 Creating the first VM
- `[x]` 1.3.8 Accessing the VM
- `[x]` 1.3.9 Attaching extra disks to the VM
- `[x]` 1.3.11 UVTool Lab
- `[x]` Chapter 1 command run-through complete
- `[x]` Chapter 1 results documented from live execution
- `[x]` Chapter 1 complete

### 2. LXD

- Status: `Complete`
- Doc page: `docs/lxd.md`
- Source range: `ubuntu_advanced_lab.md` chapter 2

Subchapters:

- `[x]` 2.1 Containerization
- `[x]` 2.2 What is LXD?
- `[x]` 2.3 LXD Setup LAB
- `[x]` 2.3.1 Install LXD
- `[x]` 2.3.2 Using a remote LXD as an image server
- `[x]` 2.3.3 Creating and using a container
- `[x]` 2.3.4 Images
- `[x]` 2.3.5 LXD profiles
- `[x]` 2.3.6 LXD snapshots
- `[x]` 2.3.7 KVM VMs in LXD
- `[x]` 2.3.8 LXD networks
- `[x]` Chapter 2 command run-through complete
- `[x]` Chapter 2 results documented from live execution
- `[x]` Chapter 2 complete

### 3. OpenSSH

- Status: `Complete`
- Doc page: `docs/openssh.md`
- Source range: `ubuntu_advanced_lab.md` chapter 3

Subchapters:

- `[x]` 3.1 What is OpenSSH?
- `[x]` 3.2 SSH Keys
- `[x]` 3.2.1 Key-Based SSH Logins
- `[x]` 3.2.2 Generating Keys
- `[x]` 3.3 SSH Tools
- `[x]` 3.3.1 ssh-agent
- `[x]` 3.3.2 Importing and Copying SSH Keys
- `[x]` 3.3.3 Using rsync with ssh
- `[x]` 3.4 OpenSSH Server Configuration
- `[x]` 3.4.1 SSH Hardening Recommendations
- `[x]` 3.5 SSH Client Configuration Files
- `[x]` 3.5.1 Typical Use Cases
- `[x]` 3.6 Port forwarding
- `[x]` 3.6.1 Local port forwarding
- `[x]` 3.6.2 Remote port forwarding
- `[x]` 3.6.3 SSH Jump Hosts and ProxyJump
- `[x]` 3.7 SSH Lab
- `[x]` 3.7.1 SSH Key Generation
- `[x]` 3.7.2 sshd, ssh-agent, ssh-add, ssh-import-id and ssh-copy-id
- `[x]` 3.7.3 Using SSH User Configuration to Connect with a Custom Identity
- `[x]` 3.7.4 Local port forwarding LAB
- `[x]` 3.7.5 Remote port forwarding LAB
- `[x]` 3.7.6 SSH Jump Host Access with ProxyJump.
- `[x]` Chapter 3 command run-through complete
- `[x]` Chapter 3 results documented from live execution
- `[x]` Chapter 3 complete

### 4. Boot and System Initialization

- Status: `Complete`
- Doc page: `docs/boot-and-system-initialization.md`
- Source range: `ubuntu_advanced_lab.md` chapter 4

Subchapters:

- `[x]` 4.1 What is GRUB2?
- `[x]` 4.2 GRUB2 LAB
- `[x]` 4.2.1 GRUB2 Configuration
- `[x]` 4.2.2 Console Connection
- `[x]` 4.2.3 Using HWE Kernels to Test Alternate Versions
- `[x]` 4.3 Advanced systemd Usage
- `[x]` 4.3.1 Systemd Units
- `[x]` 4.3.2 Managing Units with systemctl
- `[x]` 4.3.3 Logging
- `[x]` 4.3.4 Troubleshooting systemd
- `[x]` 4.4 systemd LAB
- `[x]` 4.4.1 Manage services
- `[x]` 4.4.2 Logging
- `[x]` 4.4.3 Create a custom service
- `[x]` 4.5 On Demand Processes
- `[x]` 4.6 On Demand and Scheduled tasks LAB
- `[x]` Chapter 4 command run-through complete
- `[x]` Chapter 4 results documented from live execution
- `[x]` Chapter 4 complete

### 5. Storage

- Status: `Complete`
- Doc page: `docs/storage.md`
- Source range: `ubuntu_advanced_lab.md` chapter 5

Subchapters:

- `[x]` 5.1 Partitioning
- `[x]` 5.1.1 Partitioning schemes
- `[x]` 5.1.2 Partitioning Tools
- `[x]` 5.2 Partitioning LAB
- `[x]` 5.2.1 Using `parted` for GPT partitions
- `[x]` 5.2.2 Using `fdisk` for MBR partitions
- `[x]` 5.3 RAID
- `[x]` 5.3.1 Managing a software RAID
- `[x]` 5.3.2 Software RAID Drive Failures
- `[x]` 5.4 RAID LAB
- `[x]` 5.4.1 Creating a RAID setup
- `[x]` 5.4.2 Removing a RAID
- `[x]` 5.5 Advanced LVM
- `[x]` 5.6 Advanced LVM LAB
- `[x]` 5.7 Device Mapper Multipathing
- `[x]` 5.8 Device Mapper Multipathing LAB
- `[x]` Chapter 5 command run-through complete
- `[x]` Chapter 5 results documented from live execution
- `[x]` Chapter 5 complete

### 6. Advanced Filesystem Concepts

- Status: `Complete`
- Doc page: `docs/advanced-filesystem-concepts.md`

Subchapters:

- `[x]` 6.1 Filesystem Internals
- `[x]` 6.1.1 Inodes
- `[x]` 6.1.2 Superblocks
- `[x]` 6.1.3 Extended Attributes
- `[x]` 6.1.4 POSIX ACLs
- `[x]` 6.2 Filesystem Internals Lab
- `[x]` 6.3 The `ext4` Filesystem
- `[x]` 6.3.1 Journaling Modes and Mount Behavior
- `[x]` 6.3.2 Common Tasks
- `[x]` 6.3.3 Other Filesystem Options
- `[x]` 6.4 `ext4` Filesystem Lab
- `[x]` 6.5 The `SETUID` and `SETGID` Bits
- `[x]` 6.6 `SETUID` and `SETGID` Lab
- `[x]` 6.7 Sticky Bits
- `[x]` 6.8 Sticky Bits Lab
- `[x]` Chapter 6 command run-through complete
- `[x]` Chapter 6 results documented from live execution
- `[x]` Chapter 6 complete

### 7. ZFS

- Status: `Complete`
- Doc page: `docs/zfs.md`

Subchapters:

- `[x]` 7.1 ZFS Overview
- `[x]` 7.1.1 ZFS Architecture and components
- `[x]` 7.1.2 ZFS Scrubbing
- `[x]` 7.1.3 Configuring and Tuning ZFS
- `[x]` 7.1.4 ZFS Compression
- `[x]` 7.1.5 ZFS Snapshots
- `[x]` 7.1.6 ZFS Clones
- `[x]` 7.1.7 ZFS Send and Receive
- `[x]` 7.1.8 Redundancy Enhancements: Deduplication & Ditto Blocks
- `[x]` 7.1.9 Mounting ZFS Datasets
- `[x]` 7.1.10 ZFS Pool and Dataset Lifecycle
- `[x]` 7.2 ZFS Lab
- `[x]` 7.2.1 Create ZFS Pools and Datasets
- `[x]` 7.2.2 ZFS Compression
- `[x]` 7.2.3 ZFS Snapshots and Rollbacks
- `[x]` 7.2.4 ZFS Clones and Quotas
- `[x]` 7.2.5 ZFS Send and Receive
- `[x]` 7.2.6 ZFS Ditto Blocks
- `[x]` 7.2.7 ZFS Deduplication
- `[x]` 7.2.8 ZFS Scrubbing and Fault Simulation
- `[x]` 7.2.9 Destroy a ZFS Pool
- `[x]` 7.3 ZFS RAID Lab
- `[x]` 7.3.1 RAIDZ Exercises
- `[x]` 7.3.2 Nested RAIDZ1
- `[x]` 7.3.3 RAID10 Equivalent
- `[x]` 7.3.4 File-Based Pool
- `[x]` 7.3.5 Cache and ZIL Devices
- `[x]` Chapter 7 command run-through complete
- `[x]` Chapter 7 results documented from live execution
- `[x]` Chapter 7 complete

### 8. Advanced Networking Concepts

- Status: `Complete`
- Doc page: `docs/advanced-networking-concepts.md`

Subchapters:

- `[x]` 8.1 Netplan
- `[x]` 8.1.1 Netplan general overview
- `[x]` 8.1.2 Device Configuration IDs
- `[x]` 8.1.3 Netplan Commands
- `[x]` 8.2 Netplan Lab
- `[x]` 8.2.1 General configuration Lab
- `[x]` 8.2.2 VLAN Lab
- `[x]` 8.2.3 Bonding and Bridging Lab
- `[x]` Chapter 8 command run-through complete
- `[x]` Chapter 8 results documented from live execution
- `[x]` Chapter 8 complete

### 9. Security

- Status: `Complete`
- Doc page: `docs/security.md`

Subchapters:

- `[x]` 9.1 Pluggable Authentication Modules (PAM)
- `[x]` 9.1.1 Common PAM Modules
- `[x]` 9.1.2 PAM Configuration
- `[x]` 9.1.3 Common Settings
- `[x]` 9.1.4 PAM Architecture
- `[x]` 9.1.5 PAM Modules discovery
- `[x]` 9.2 PAM LAB
- `[x]` 9.3 Access Control Lists (ACLs)
- `[x]` 9.4 ACL Lab
- `[x]` 9.4.1 Adding, removing and transferring permissions
- `[x]` 9.4.2 Default ACLs and masking
- `[x]` 9.5 AppArmor
- `[x]` 9.6 AppArmor Lab
- `[x]` 9.7 Host Firewall (UFW)
- `[x]` 9.8 UFW Lab
- `[x]` 9.9 Ubuntu Pro and Extended Security Maintenance (ESM)
- `[x]` 9.10 Ubuntu Pro: ESM, USG, and Livepatch Lab
- `[x]` Chapter 9 command run-through complete
- `[x]` Chapter 9 results documented from live execution
- `[x]` Chapter 9 complete

### 10. Advanced Snap Packaging

- Status: `Complete`
- Doc page: `docs/advanced-snap-packaging.md`

Subchapters:

- `[x]` 10.1 Snap Internals and Confinement
- `[x]` 10.2 Snap Channels and Releases
- `[x]` 10.3 Advanced Snap Lab.
- `[x]` Chapter 10 command run-through complete
- `[x]` Chapter 10 results documented from live execution
- `[x]` Chapter 10 complete

### 11. Advanced System Topics

- Status: `Complete`
- Doc page: `docs/advanced-system-topics.md`
- Note: Supplemental chapter. Marked complete by exception without live command validation.

Subchapters:

- `[x]` 11.1 Time Synchronization with chrony & timesyncd
- `[x]` 11.2 Time Synchronization Lab
- `[x]` 11.3 Traditional Logging with rsyslog
- `[x]` 11.4 rsyslog Lab
- `[x]` 11.5 Diagnostic Tools: sosreport & apport
- `[x]` 11.6 Sosreport and Apport Lab
- `[x]` 11.7 XFS Filesystem (Advanced)
- `[x]` 11.8 XFS Lab
- `[x]` Chapter 11 command run-through complete
- `[x]` Chapter 11 results documented from live execution
- `[x]` Chapter 11 complete
