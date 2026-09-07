# Storage

This chapter covers storage layout, RAID, LVM, and multipathing concepts used in the lab.

In this chapter you will:

- compare MBR and GPT partitioning
- create partitions with `parted` and `fdisk`
- build and inspect software RAID with `mdadm`
- create and extend LVM storage
- review basic Device Mapper Multipath workflows

## :material-book-open-page-variant-outline: 5.1 Partitioning

Partitioning divides a disk into one or more regions so the operating system can manage them separately. These regions are called partitions.

The partition table stores each partition's position and size. The operating system reads that table before it uses the rest of the disk.

Administrators use partition editors to create, resize, delete, and inspect partitions.

### :material-application-edit-outline: 5.1.1 Partitioning Schemes

Ubuntu commonly uses two partitioning schemes.

**MBR (Master Boot Record)** is the older layout.

- up to four primary partitions, or three primary partitions plus one extended partition
- practical disk size limit of 2 TiB
- limited metadata and no redundant partition table copies

**GPT (GUID Partition Table)** is the modern layout used with UEFI systems.

- supports up to 128 partitions by default on Linux
- supports disks larger than 2 TiB
- stores multiple partition table copies for redundancy
- includes checksums for integrity checks

GPT is the default and recommended choice for most new Ubuntu systems.

### :material-application-edit-outline: 5.1.2 Partitioning Tools

Common partitioning tools include:

- `parted`: modern partitioning tool that supports both MBR and GPT
- `fdisk`: classic command-line partitioning tool, commonly used for MBR-style workflows
- `cfdisk`: menu-driven alternative to `fdisk`
- `sfdisk`: scriptable partitioning tool for automated workflows
- `gdisk`: GPT-aware alternative to `fdisk`

Useful companion tools:

- `lsblk`: show block devices and their hierarchy
- `blkid`: show UUIDs and labels
- `wipefs`: remove old filesystem or RAID signatures from a device

!!! note
    For automated installs and scripting, `parted` and `sfdisk` are often preferred because they work well in non-interactive workflows.

!!! pied-piper "Takeaway"
    For partitioning, remember:

    - GPT is the modern default on Ubuntu
    - MBR is older and more limited
    - `parted` is the usual tool for modern scripted workflows
    - `fdisk` is still common for classic interactive MBR-style work

## :material-book-open-page-variant-outline: 5.2 Partitioning Lab

!!! info
    Run this lab on `LABVM`. Make sure the secondary disk `/dev/vdb` is attached before you begin.

### :material-application-edit-outline: 5.2.1 Using `parted` For GPT Partitions

This lab creates a GPT partition on `/dev/vdb`, formats it with `ext4`, mounts it, makes the mount persistent, and then cleans it up.

Step 1: Inspect the current disk layout.

```bash
# Show the current block device layout.
lsblk
```
??? example "Expected result"
    ```text
    NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
    vda    252:0    0   32G  0 disk
    ├─vda1 252:1    0   31G  0 part /
    └─vda2 252:2    0    1G  0 part [SWAP]
    vdb    252:16   0   10G  0 disk
    ```

Step 2: Inspect `/dev/vdb` with `parted`.

```bash
# Print the current partition table on /dev/vdb.
sudo parted /dev/vdb print
```
??? example "Expected result"
    ```text
    Error: /dev/vdb: unrecognised disk label
    Model: Virtio Block Device (virtblk)
    Disk /dev/vdb: 10.7GB
    Sector size (logical/physical): 512B/512B
    Partition Table: unknown
    ```

!!! note
    If the disk is uninitialized, `parted` may show an unknown partition table.

Step 3: Create a GPT partition table.

```bash
# Create a new GPT partition table on /dev/vdb (non-interactively).
sudo parted --script /dev/vdb mklabel gpt
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 4: Create a single aligned partition that uses the full disk.

```bash
# Create one ext4 partition from 1MiB to the end of the disk (non-interactively).
sudo parted --script /dev/vdb mkpart primary ext4 1MiB 100%
```
??? example "Expected result"
    ```text
    No output.
    ```

!!! note
    Starting at `1MiB` keeps the partition properly aligned on modern storage.

Step 5: Verify the new partition table.

```bash
# Print the partition table after creating the GPT partition.
sudo parted /dev/vdb print
```
??? example "Expected result"
    ```text
    Model: Virtio Block Device (virtblk)
    Disk /dev/vdb: 10.7GB
    Partition Table: gpt

    Number  Start   End     Size    File system  Name     Flags
     1      1049kB  10.7GB  10.7GB               primary
    ```

Step 6: Confirm the new partition is not already in use.

```bash
# Show filesystem information for the new partition.
lsblk -f /dev/vdb1
```
??? example "Expected result"
    ```text
    NAME FSTYPE FSVER LABEL UUID FSAVAIL FSUSE% MOUNTPOINTS
    vdb1
    ```

Step 7: Format the partition.

```bash
# Create an ext4 filesystem on /dev/vdb1.
sudo mkfs.ext4 /dev/vdb1
```
??? example "Expected result"
    ```text
    mke2fs 1.47.0 (...)
    Creating filesystem with ... 4k blocks and ... inodes
    Filesystem UUID: ...
    Superblock backups stored on blocks:
    ...
    ```

Step 8: Create a mount point.

```bash
# Create the mount directory used in this lab.
sudo mkdir -p /mnt/data
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 9: Mount the new filesystem.

```bash
# Mount /dev/vdb1 on /mnt/data.
sudo mount /dev/vdb1 /mnt/data
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 10: Verify the mount.

```bash
# Check the mounted filesystem usage.
df -h /mnt/data
```
??? example "Expected result"
    ```text
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/vdb1       9.8G   24K  9.3G   1% /mnt/data
    ```

Step 11: Get the partition UUID.

```bash
# Display the UUID of /dev/vdb1.
sudo blkid /dev/vdb1
```
??? example "Expected result"
    ```text
    /dev/vdb1: UUID="..." BLOCK_SIZE="4096" TYPE="ext4" PARTLABEL="primary" PARTUUID="..."
    ```

Step 12: Open `/etc/fstab`.

```bash
# Edit /etc/fstab to add a persistent mount entry.
sudo nano /etc/fstab
```
??? example "Expected result"
    ```text
    GNU nano ... /etc/fstab
    ```

Add a line like this, replacing the UUID with the value from the previous step:

```ini
UUID=<your-uuid-here>  /mnt/data  ext4  defaults  0  2
```

Step 13: Test the `fstab` entry before rebooting.

```bash
# Validate the current /etc/fstab entries.
sudo mount -a
```
??? example "Expected result"
    ```text
    No output.
    ```

!!! warning
    Always test `/etc/fstab` with `sudo mount -a` before rebooting. A bad entry can block the system from booting normally.

Step 14: Reboot the system.

```bash
# Reboot LABVM to verify the persistent mount.
sudo reboot
```
??? example "Expected result"
    ```text
    The system will reboot now!
    ```

Step 15: Verify the mount after reboot.

```bash
# Confirm that /mnt/data is mounted after reboot.
df -h /mnt/data
```
??? example "Expected result"
    ```text
    Filesystem      Size  Used Avail Use% Mounted on
    /dev/vdb1       9.8G   24K  9.3G   1% /mnt/data
    ```

Step 16: Remove the `fstab` entry during cleanup.

```bash
# Edit /etc/fstab again to remove the /mnt/data entry.
sudo nano /etc/fstab
```
??? example "Expected result"
    ```text
    GNU nano ... /etc/fstab
    ```

You can remove the line or comment it out:

```ini
# UUID=<your-uuid-here>  /mnt/data  ext4  defaults  0  2
```

Step 17: Unmount the filesystem.

```bash
# Unmount /mnt/data.
sudo umount /mnt/data
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 18: Remove the signatures from `/dev/vdb`.

```bash
# Wipe filesystem and partition-table signatures from /dev/vdb.
sudo wipefs --all /dev/vdb
```
??? example "Expected result"
    ```text
    /dev/vdb: ... bytes were erased at offset ...
    ```

!!! warning
    Double-check the device name before using `wipefs --all`.

### :material-application-edit-outline: 5.2.2 Using `fdisk` For MBR Partitions

This lab uses `fdisk` to create a simple MBR partition on `/dev/vdb`.

Step 1: Inspect the current partition table.

```bash
# List the current partition table for /dev/vdb.
sudo fdisk -l /dev/vdb
```
??? example "Expected result"
    ```text
    Disk /dev/vdb: 10 GiB, ... bytes, ... sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    ```

Step 2: Start `fdisk`.

```bash
# Open fdisk on /dev/vdb.
sudo fdisk /dev/vdb
```
??? example "Expected result"
    ```text
    Welcome to fdisk (...)
    Changes will remain in memory only, until you decide to write them.

    Command (m for help):
    ```

At the `fdisk` prompt, enter this sequence:

```text
p    # print the current partition table
n    # create a new partition
p    # choose a primary partition
1    # use partition number 1
     # press Enter to accept the default first sector
     # press Enter to accept the default last sector
p    # print the new partition table before saving
w    # write the changes to disk
```

That sequence prints the current layout, creates one primary partition with the defaults, prints the new layout, and writes the changes.

!!! note
    If you reuse the same disk after the previous `ext4` lab, `fdisk` may warn that the new partition contains an existing `ext4` signature. The partition can still be created successfully.

Step 3: Verify the new partition.

```bash
# List the updated partition table after writing the changes.
sudo fdisk -l /dev/vdb
```
??? example "Expected result"
    ```text
    Disk /dev/vdb: 10 GiB, ... bytes, ... sectors
    Disklabel type: dos

    Device     Boot Start      End  Sectors  Size Id Type
    /dev/vdb1        ...       ...     ...   ... 83 Linux
    ```

Step 4: Erase the partition table for cleanup.

```bash
# Overwrite the first 10 MiB of /dev/vdb with zeros.
sudo dd if=/dev/zero of=/dev/vdb bs=1M count=10
```
??? example "Expected result"
    ```text
    10+0 records in
    10+0 records out
    10485760 bytes (10 MB, 10 MiB) copied, ... s, ... MB/s
    ```

Step 5: Verify that the partition table is gone.

```bash
# Confirm that the old partition table is no longer present.
sudo fdisk -l /dev/vdb
```
??? example "Expected result"
    ```text
    Disk /dev/vdb: 10 GiB, ... bytes, ... sectors
    Units: sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    ```

Step 6: Enable periodic discard on SSD-backed systems.

!!! note
    `fstrim.timer` schedules `fstrim.service`, which periodically tells the storage layer which filesystem blocks are no longer in use. This is useful on SSD-backed or thin-provisioned storage because it helps reclaim unused space and maintain performance.

```bash
# Enable the fstrim timer.
sudo systemctl enable fstrim.timer
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Start the fstrim timer immediately.
sudo systemctl start fstrim.timer
```
??? example "Expected result"
    ```text
    No output.
    ```

!!! pied-piper "Takeaway"
    The basic partition workflow is:

    - create the partition table
    - create the partition
    - make a filesystem
    - mount it and test it
    - if you add it to `fstab`, always test with `mount -a` before rebooting

## :material-book-open-page-variant-outline: 5.3 RAID

RAID combines multiple disks into one logical storage device. Depending on the RAID level, the goal may be higher performance, redundancy, or both.

Common RAID levels:

- **RAID 0**: striping only, no redundancy, maximum usable capacity
- **RAID 1**: mirroring, redundancy with the capacity of one disk in each mirror pair
- **RAID 5**: striping with distributed parity, usable capacity of `(N-1)/N`
- **RAID 6**: striping with double parity, usable capacity of `(N-2)/N`
- **RAID 10**: stripe across mirrors, good performance with redundancy

Ubuntu commonly uses software RAID with `mdadm`.

!!! note
    RAID 0 provides no fault tolerance. For SSD-backed arrays, RAID 1 or RAID 10 are usually preferred over RAID 5 or RAID 6 because of lower write amplification.

There are three broad RAID approaches:

- **Hardware RAID**: handled by a dedicated controller
- **Software RAID**: handled by the kernel and `mdadm`
- **Fake RAID**: firmware-assisted RAID that depends on motherboard-specific metadata

Software RAID is the usual recommendation unless there is a clear need for a hardware controller.

### :material-application-edit-outline: 5.3.1 Managing A Software RAID

`mdadm` is the standard tool used to create, assemble, inspect, and manage Linux software RAID arrays.

Common `mdadm` modes include:

- **Assemble**: assemble an existing array
- **Build**: build a legacy array without per-device superblocks
- **Create**: create a new array with metadata on each member device
- **Manage**: add, remove, or mark devices as failed
- **Misc**: inspect or stop arrays and clear metadata
- **Monitor**: watch arrays and trigger alerts
- **Grow**: reshape or resize an array

The most common modern workflow is `create`.

```bash
# Examine RAID metadata on matching devices and save it to a file.
mdadm --examine /dev/vd[a-z]1 >> raid.status
```
??? quote "Reference output"
    ```text
    No terminal output. The metadata is appended to raid.status.
    ```

!!! note
    This example assumes virtio disk names such as `vdb1` and `vdc1`. Adjust the device pattern for your environment, for example `sd` for SCSI/SATA or `nvme` for NVMe devices.

```bash
# Search the kernel log for messages related to virtio disks.
dmesg | grep vd
```
??? quote "Reference output"
    ```text
    [    ... ] vdb: detected capacity change ...
    [    ... ] vdc: detected capacity change ...
    ```

```bash
# Compare event counters across RAID member devices.
mdadm --examine /dev/vd[a-z] | egrep 'Event|/dev/'
```
??? quote "Reference output"
    ```text
    /dev/vdb1:
        Events : ...
    /dev/vdc1:
        Events : ...
    ```

```bash
# Attempt a forced assembly of an array.
mdadm --assemble --force /dev/mdX <list of devices>
```
??? quote "Reference output"
    ```text
    mdadm: /dev/mdX has been started with ... drives.
    ```

`/proc/mdstat` shows the current RAID state from the kernel's point of view.

```bash
# Show the current software RAID status.
cat /proc/mdstat
```
??? quote "Reference output"
    ```text
    Personalities : [raid1] [raid5] [raid6]
    md0 : active raid5 vdb1[0] vdc1[1] vdd1[2] vde1[3] vdf1[4]
          ... blocks super 1.2 level 5 ... [5/5] [UUUUU]

    unused devices: <none>
    ```

### :material-application-edit-outline: 5.3.2 Software RAID Drive Failures

Two common RAID failure cases are:

- **resilience-reducing failures**: the array is degraded but still works
- **operational failures**: too many devices have failed and the array cannot run

Common array states include:

- `active`
- `degraded`
- `inactive`
- `failed`

When recovering a broken software RAID, start by preserving and inspecting the metadata before changing the array.

Important `mdstat` output elements:

- `[n/m]`: expected devices versus currently active devices
- `[UUUU_]`: `U` means the member is up; `_` means a member is missing or failed
- bitmap information: used to speed up resync after interruptions

!!! pied-piper "Takeaway"
    For Linux software RAID, remember:

    - `mdadm` creates and manages the array
    - `/proc/mdstat` shows the kernel view of array health
    - RAID improves redundancy, performance, or both depending on the level
    - RAID is not a backup

## :material-book-open-page-variant-outline: 5.4 RAID Lab

!!! info
    Run this lab on `LABVM`. This workflow assumes `/dev/vdb` through `/dev/vdf` are available for testing.

### :material-application-edit-outline: 5.4.1 Creating A RAID Setup

This lab uses `mdadm` to create and inspect a RAID 5 array.

Step 1: Install the required packages.

```bash
# Install mdadm and parted.
sudo apt install -y mdadm parted
```
??? example "Expected result"
    ```text
    Reading package lists... Done
    Building dependency tree... Done
    ...
    Setting up mdadm ...
    Setting up parted ...
    ```

Step 2: Create GPT labels on the member disks.

```bash
# Create a GPT label on /dev/vdb (non-interactively).
sudo parted --script /dev/vdb mklabel gpt
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Create a GPT label on /dev/vdc (non-interactively).
sudo parted --script /dev/vdc mklabel gpt
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Create a GPT label on /dev/vdd (non-interactively).
sudo parted --script /dev/vdd mklabel gpt
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Create a GPT label on /dev/vde (non-interactively).
sudo parted --script /dev/vde mklabel gpt
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Create a GPT label on /dev/vdf (non-interactively).
sudo parted --script /dev/vdf mklabel gpt
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 3: Create one partition on each disk.

```bash
# Create one full-disk partition on /dev/vdb (non-interactively).
sudo parted -a optimal /dev/vdb --script mkpart primary ext4 1MiB 100%
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Create one full-disk partition on /dev/vdc (non-interactively).
sudo parted -a optimal /dev/vdc --script mkpart primary ext4 1MiB 100%
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Create one full-disk partition on /dev/vdd (non-interactively).
sudo parted -a optimal /dev/vdd --script mkpart primary ext4 1MiB 100%
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Create one full-disk partition on /dev/vde (non-interactively).
sudo parted -a optimal /dev/vde --script mkpart primary ext4 1MiB 100%
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Create one full-disk partition on /dev/vdf (non-interactively).
sudo parted -a optimal /dev/vdf --script mkpart primary ext4 1MiB 100%
```
??? example "Expected result"
    ```text
    No output.
    ```

!!! note
    The `-a optimal` option asks `parted` to align partitions using the device's preferred topology.

Step 4: Create the RAID 5 array.

```bash
# Create a RAID 5 array at /dev/md0 from the five member partitions.
sudo mdadm --create --verbose /dev/md0 --level=5 --raid-devices=5 /dev/vd[bcdef]1
```
??? example "Expected result"
    ```text
    mdadm: layout defaults to left-symmetric
    mdadm: array /dev/md0 started.
    ```

Step 5: Watch the creation status.

```bash
# Watch the RAID creation progress.
watch cat /proc/mdstat
```
??? example "Expected result"
    ```text
    Every 2.0s: cat /proc/mdstat
    ... recovery = ...% (.../...)
    ```

Step 6: Check the current RAID status.

```bash
# Display the current RAID status.
cat /proc/mdstat
```
??? example "Expected result"
    ```text
    Personalities : [raid5]
    md0 : active raid5 vdb1[0] vdc1[1] vdd1[2] vde1[3] vdf1[4]
          ... [5/5] [UUUUU]
    ```

Step 7: Examine the member metadata.

```bash
# Examine the RAID metadata on each member partition.
sudo mdadm --examine /dev/vd[b-f]1
```
??? example "Expected result"
    ```text
    /dev/vdb1:
        Magic : a92b4efc
        Version : 1.2
        Raid Level : raid5
        ...
    ```

Step 8: Show detailed array information.

```bash
# Display detailed information about /dev/md0.
sudo mdadm --detail /dev/md0
```
??? example "Expected result"
    ```text
    /dev/md0:
            Version : 1.2
      Creation Time : ...
         Raid Level : raid5
         Array Size : ...
         State : clean
    ```

Step 9: Search for related kernel messages.

```bash
# Search the kernel log for virtio disk messages.
sudo dmesg | grep vd
```
??? example "Expected result"
    ```text
    [    ... ] vdb: ...
    [    ... ] md0: ...
    ```

Step 10: Open the `mdadm` manual for further tuning details.

```bash
# Open the mdadm manual page.
man mdadm
```
??? example "Expected result"
    ```text
    MDADM(8) ...
    ```

### :material-application-edit-outline: 5.4.2 Removing A RAID

Removing a RAID array cleanly prevents `mdadm` from trying to reassemble it later from leftover metadata.

Step 1: Stop the array.

```bash
# Stop the active RAID array.
sudo mdadm --stop /dev/md0
```
??? example "Expected result"
    ```text
    mdadm: stopped /dev/md0
    ```

Step 2: Clear the superblock on `/dev/vdb1`.

```bash
# Remove RAID metadata from /dev/vdb1.
sudo mdadm --zero-superblock /dev/vdb1
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Remove RAID metadata from /dev/vdc1.
sudo mdadm --zero-superblock /dev/vdc1
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Remove RAID metadata from /dev/vdd1.
sudo mdadm --zero-superblock /dev/vdd1
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Remove RAID metadata from /dev/vde1.
sudo mdadm --zero-superblock /dev/vde1
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Remove RAID metadata from /dev/vdf1.
sudo mdadm --zero-superblock /dev/vdf1
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 3: Check whether the array is referenced in `mdadm.conf`.

```bash
# Show ARRAY lines from the mdadm configuration.
grep ARRAY /etc/mdadm/mdadm.conf
```
??? example "Expected result"
    ```text
    ARRAY /dev/md0 metadata=1.2 UUID=...
    ```

Step 4: Edit the configuration file if needed.

```bash
# Edit the mdadm configuration file.
sudo nano /etc/mdadm/mdadm.conf
```
??? example "Expected result"
    ```text
    GNU nano ... /etc/mdadm/mdadm.conf
    ```

If an `ARRAY` entry for `/dev/md0` is present, remove it or comment it out.

```bash
# Example alerting directive shown in mdadm.conf.
grep '^MAILADDR' /etc/mdadm/mdadm.conf
```
??? example "Expected result"
    ```text
    MAILADDR root
    ```

!!! pied-piper "Takeaway"
    The practical RAID workflow is:

    - prepare the member disks
    - create the array with `mdadm`
    - monitor it with `/proc/mdstat` and `mdadm --detail`
    - when cleaning up, stop the array and clear leftover superblocks

## :material-book-open-page-variant-outline: 5.5 Advanced LVM

LVM adds a management layer between block devices and the filesystems that use them.

Instead of working only with fixed partitions, LVM organizes storage in three layers:

- **physical volumes (PVs)**: disks or partitions prepared for LVM
- **volume groups (VGs)**: storage pools built from one or more PVs
- **logical volumes (LVs)**: named storage volumes created from a VG

This lets you treat several devices as one pool and carve out storage from that pool as needed.

Advantages of LVM:

- named logical volumes instead of numbered partitions
- logical volumes can span multiple disks
- logical volumes do not need to be physically contiguous on disk
- storage can be extended later with less disruption

LVM can also sit on top of software RAID. A common design is to build redundancy with `mdadm` first and then place LVM on the resulting RAID device.

It is usually a good idea to leave some free space in a VG so you can grow LVs later, create snapshots, or move data if the PV layout changes.

Basic LVM workflow:

```bash
# Initialize a disk as an LVM physical volume.
pvcreate /dev/vdx
```
??? quote "Reference output"
    ```text
    Physical volume "/dev/vdx" successfully created.
    ```

```bash
# Create a volume group named my_vg.
vgcreate my_vg /dev/vdx
```
??? quote "Reference output"
    ```text
    Volume group "my_vg" successfully created
    ```

```bash
# Create a 10 GB logical volume named my_lv.
lvcreate --name my_lv --size 10GB my_vg
```
??? quote "Reference output"
    ```text
    Logical volume "my_lv" created.
    ```

Inspect the resulting PV, VG, and LV:

```bash
# Show the current physical volumes.
pvs
```
??? quote "Reference output"
    ```text
    PV         VG    Fmt  Attr PSize   PFree
    /dev/vdx   my_vg lvm2 a--  <...g   <...g
    ```

```bash
# Show the current volume groups.
vgs
```
??? quote "Reference output"
    ```text
    VG    #PV #LV #SN Attr   VSize   VFree
    my_vg   1   1   0 wz--n- <...g   <...g
    ```

```bash
# Show the current logical volumes.
lvs
```
??? quote "Reference output"
    ```text
    LV    VG    Attr       LSize
    my_lv my_vg -wi-a----- 10.00g
    ```

You can size an LV in bytes, MiB/GiB, extents, or percentages such as `20%FREE`. LVM also supports different LV layouts including linear, striped, mirrored, and RAID-backed variants.

```bash
# Extend the volume group with another physical volume.
vgextend my_vg /dev/vdy
```
??? quote "Reference output"
    ```text
    Volume group "my_vg" successfully extended
    ```

```bash
# Extend the logical volume by 20 GB.
lvextend -L +20GB /dev/my_vg/my_lv
```
??? quote "Reference output"
    ```text
    Size of logical volume my_vg/my_lv changed from ... to ...
    ```

!!! note
    `lvextend` increases the LV size only. If the LV already contains a filesystem, you usually need a separate filesystem resize step as well unless you use `lvextend -r`.

```bash
# Verify the updated VG free space and LV size.
vgs && lvs
```
??? quote "Reference output"
    ```text
    VG    #PV #LV #SN Attr   VSize   VFree
    my_vg   2   1   0 wz--n- <...g   <...g

    LV    VG    Attr       LSize
    my_lv my_vg -wi-a----- 30.00g
    ```

```bash
# Convert a linear LV into a mirror.
lvconvert -m +1 my_vg/my_lv
```
??? quote "Reference output"
    ```text
    Logical volume my_vg/my_lv converted.
    ```

This requires enough free extents on another PV so LVM has somewhere to place the mirror image.

```bash
# Convert the mirrored LV back to linear.
lvconvert -m 0 my_vg/my_lv
```
??? quote "Reference output"
    ```text
    Logical volume my_vg/my_lv converted.
    ```

```bash
# Move data away from a physical volume.
pvmove /dev/vdy
```
??? quote "Reference output"
    ```text
    /dev/vdy: Moved: ...
    ```

```bash
# Move only the extents that belong to a specific logical volume.
pvmove -n my_lv /dev/vdx /dev/vdy
```
??? quote "Reference output"
    ```text
    /dev/...: Moved: ...
    ```

Use `pvmove` when you need to evacuate a PV for maintenance or replacement. With `-n`, LVM moves only the extents that belong to the named logical volume.

```bash
# Show which physical volumes now hold the logical volume extents.
lvs -o +devices
```
??? quote "Reference output"
    ```text
    LV    VG    Attr       LSize   Devices
    my_lv my_vg -wi-a----- 30.00g /dev/vdy(...)
    ```

!!! pied-piper "Takeaway"
    Keep the LVM layers straight:

    - PV = the disk or partition prepared for LVM
    - VG = the storage pool built from PVs
    - LV = the usable volume you create from the VG

    Think of LVM as a flexible storage pool on top of block devices.

## :material-book-open-page-variant-outline: 5.6 Advanced LVM Lab

!!! info
    Run this lab on `LABVM`. This workflow uses `/dev/vdb`, `/dev/vdc`, and later `/dev/vdd`.

Step 1: Install LVM.

```bash
# Install the LVM tools.
sudo apt install -y lvm2
```
??? example "Expected result"
    ```text
    Reading package lists... Done
    Building dependency tree... Done
    ...
    Setting up lvm2 ...
    ```

Step 2: Create a GPT partition on `/dev/vdb`.

```bash
# Create a GPT label on /dev/vdb (non-interactively).
sudo parted --script /dev/vdb mklabel gpt
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Create one partition on /dev/vdb (non-interactively).
sudo parted --script /dev/vdb mkpart primary ext4 1MiB 100%
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 3: Create a GPT partition on `/dev/vdc`.

```bash
# Create a GPT label on /dev/vdc (non-interactively).
sudo parted --script /dev/vdc mklabel gpt
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Create one partition on /dev/vdc (non-interactively).
sudo parted --script /dev/vdc mkpart primary ext4 1MiB 100%
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 4: Create the physical volumes and list them.

```bash
# Create an LVM physical volume on /dev/vdb1.
sudo pvcreate /dev/vdb1
```
??? example "Expected result"
    ```text
    Physical volume "/dev/vdb1" successfully created.
    ```

```bash
# Create an LVM physical volume on /dev/vdc1.
sudo pvcreate /dev/vdc1
```
??? example "Expected result"
    ```text
    Physical volume "/dev/vdc1" successfully created.
    ```

```bash
# List physical volumes with backing device information.
sudo pvs -o +devices
```
??? example "Expected result"
    ```text
    PV         VG Fmt  Attr PSize  PFree  Devices
    /dev/vdb1     lvm2 ---  ...    ...
    /dev/vdc1     lvm2 ---  ...    ...
    ```

!!! note
    On some systems, the `Devices` column may be empty at this stage even though the PVs were created successfully.

Step 5: Create the volume group and list it.

```bash
# Create a volume group named my_vg.
sudo vgcreate my_vg /dev/vdb1 /dev/vdc1
```
??? example "Expected result"
    ```text
    Volume group "my_vg" successfully created
    ```

```bash
# List volume groups.
sudo vgs
```
??? example "Expected result"
    ```text
    VG    #PV #LV #SN Attr   VSize  VFree
    my_vg   2   0   0 wz--n- ...    ...
    ```

Step 6: Create the logical volume and list it.

```bash
# Create a 1 GB logical volume named my_lv.
sudo lvcreate -n my_lv -L 1GB my_vg
```
??? example "Expected result"
    ```text
    Logical volume "my_lv" created.
    ```

```bash
# List logical volumes.
sudo lvs
```
??? example "Expected result"
    ```text
    LV    VG    Attr       LSize
    my_lv my_vg -wi-a----- 1.00g
    ```

Step 7: Prepare a filesystem for the later resize steps.

```bash
# Create an ext4 filesystem on the new logical volume.
sudo mkfs.ext4 /dev/my_vg/my_lv
```
??? example "Expected result"
    ```text
    mke2fs 1.47.0 (...)
    Filesystem UUID: ...
    ```

```bash
# Create the mount point used in this lab.
sudo mkdir -p /mnt/data
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Mount the logical volume.
sudo mount /dev/my_vg/my_lv /mnt/data
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 8: Convert the logical volume into a mirror.

```bash
# Convert my_lv into a mirrored logical volume.
sudo lvconvert -m +1 my_vg/my_lv
```
??? example "Expected result"
    ```text
    Are you sure you want to convert linear LV my_vg/my_lv to raid1 with 2 images enhancing resilience? [y/n]: y
    Logical volume my_vg/my_lv successfully converted.
    ```

Step 9: Inspect the logical volume and physical volume usage.

```bash
# Show detailed information about the logical volume.
sudo lvdisplay /dev/my_vg/my_lv
```
??? example "Expected result"
    ```text
    --- Logical volume ---
    LV Path                /dev/my_vg/my_lv
    LV Name                my_lv
    ...
    ```

```bash
# Show physical volume usage.
sudo pvs
```
??? example "Expected result"
    ```text
    PV         VG    Fmt  Attr PSize PFree
    /dev/vdb1  my_vg lvm2 a--  ...   ...
    /dev/vdc1  my_vg lvm2 a--  ...   ...
    ```

Step 10: Convert the logical volume back to linear.

```bash
# Convert the mirrored LV back to a linear LV.
sudo lvconvert -m 0 my_vg/my_lv
```
??? example "Expected result"
    ```text
    Are you sure you want to convert raid1 LV my_vg/my_lv to type linear losing all resilience? [y/n]: y
    Logical volume my_vg/my_lv successfully converted.
    ```

```bash
# Check physical volume usage again.
sudo pvs
```
??? example "Expected result"
    ```text
    PV         VG    Fmt  Attr PSize PFree
    /dev/vdb1  my_vg lvm2 a--  ...   ...
    /dev/vdc1  my_vg lvm2 a--  ...   ...
    ```

Step 11: Check which devices back the logical volume.

```bash
# Show logical volumes with backing device information.
sudo lvs -o +devices
```
??? example "Expected result"
    ```text
    LV    VG    Attr       LSize Devices
    my_lv my_vg -wi-a----- 1.00g /dev/vdb1(...)
    ```

```bash
# Show detailed segment mapping for the logical volume.
sudo lvs --segments /dev/my_vg/my_lv
```
??? example "Expected result"
    ```text
    LV    VG    Attr       #Str Type   SSize
    my_lv my_vg -wi-a-----    1 linear 1.00g
    ```

```bash
# Show how each physical volume is used.
sudo pvdisplay -m
```
??? example "Expected result"
    ```text
    --- Physical volume ---
    PV Name               /dev/vdb1
    ...
    ```

```bash
# Show the block device view of the LVM layout.
sudo lsblk
```
??? example "Expected result"
    ```text
    NAME           MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
    vdb            ...
    └─vdb1         ...           part
      └─my_vg-my_lv ...         lvm  /mnt/data
    ```

Step 12: Move the logical volume to the other physical volume.

```bash
# Move my_lv from /dev/vdb1 to /dev/vdc1.
sudo pvmove -n my_lv /dev/vdb1 /dev/vdc1
```
??? example "Expected result"
    ```text
    /dev/vdb1: Moved: ...
    ```

Step 13: Verify that the move completed.

```bash
# Show the logical volume backing devices after pvmove.
sudo lvs -o +devices
```
??? example "Expected result"
    ```text
    LV    VG    Attr       LSize Devices
    my_lv my_vg -wi-a----- 1.00g /dev/vdc1(...)
    ```

Step 14: Remove the now-free PV from the VG.

```bash
# Remove /dev/vdb1 from the volume group.
sudo vgreduce my_vg /dev/vdb1
```
??? example "Expected result"
    ```text
    Removed "/dev/vdb1" from volume group "my_vg"
    ```

Step 15: Extend the LV and resize the filesystem.

```bash
# Extend the logical volume by 1 GiB and grow the filesystem.
sudo lvextend -r -L +1G /dev/my_vg/my_lv
```
??? example "Expected result"
    ```text
    Size of logical volume my_vg/my_lv changed from 1.00 GiB to 2.00 GiB.
    File system ext4 on /dev/mapper/my_vg-my_lv is mounted on /mnt/data; on-line resizing required
    resize2fs ...
    ```

Step 16: Verify the larger filesystem and volume sizes.

```bash
# Check the mounted filesystem size.
df -h /mnt/data/
```
??? example "Expected result"
    ```text
    Filesystem               Size  Used Avail Use% Mounted on
    /dev/mapper/my_vg-my_lv  2.0G  ...  ...   ...  /mnt/data
    ```

```bash
# List logical volumes after the resize.
sudo lvs
```
??? example "Expected result"
    ```text
    LV    VG    Attr       LSize
    my_lv my_vg -wi-a----- 2.00g
    ```

```bash
# List volume groups after the resize.
sudo vgs
```
??? example "Expected result"
    ```text
    VG    #PV #LV #SN Attr   VSize VFree
    my_vg   1   1   0 wz--n- ...   ...
    ```

Step 17: Prepare `/dev/vdd` and add it to the VG.

```bash
# Create a GPT label on /dev/vdd (non-interactively).
sudo parted --script /dev/vdd mklabel gpt
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Create one partition on /dev/vdd (non-interactively).
sudo parted --script /dev/vdd mkpart primary ext4 1MiB 100%
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Create an LVM physical volume on /dev/vdd1.
sudo pvcreate /dev/vdd1
```
??? example "Expected result"
    ```text
    Physical volume "/dev/vdd1" successfully created.
    ```

```bash
# Extend the volume group with /dev/vdd1.
sudo vgextend my_vg /dev/vdd1
```
??? example "Expected result"
    ```text
    Volume group "my_vg" successfully extended
    ```

```bash
# Check the updated volume group layout.
sudo vgs
```
??? example "Expected result"
    ```text
    VG    #PV #LV #SN Attr   VSize VFree
    my_vg   2   1   0 wz--n- ...   ...
    ```

Step 18: Extend the LV again using the newly added space.

```bash
# Extend the logical volume by another 1 GiB and grow the filesystem.
sudo lvextend -r -L +1G /dev/my_vg/my_lv
```
??? example "Expected result"
    ```text
    Size of logical volume my_vg/my_lv changed from 2.00 GiB to 3.00 GiB.
    resize2fs ...
    ```

```bash
# Verify the mounted filesystem size again.
df -h /mnt/data/
```
??? example "Expected result"
    ```text
    Filesystem               Size  Used Avail Use% Mounted on
    /dev/mapper/my_vg-my_lv  3.0G  ...  ...   ...  /mnt/data
    ```

Step 19: Unmount the filesystem during cleanup.

```bash
# Unmount the logical volume from /mnt/data.
sudo umount /mnt/data
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 20: Deactivate and remove the LVM objects.

!!! note
    The commands in this cleanup step may prompt for confirmation depending on the current LV state.

```bash
# Deactivate the volume group.
sudo vgchange -an my_vg
```
??? example "Expected result"
    ```text
    0 logical volume(s) in volume group "my_vg" now active
    ```

```bash
# Remove the logical volume.
sudo lvremove my_vg/my_lv
```
??? example "Expected result"
    ```text
    Do you really want to remove logical volume my_vg/my_lv? [y/n]: y
    Logical volume "my_lv" successfully removed.
    ```

```bash
# Remove the volume group.
sudo vgremove my_vg
```
??? example "Expected result"
    ```text
    Volume group "my_vg" successfully removed
    ```

```bash
# Remove the physical volume metadata.
sudo pvremove /dev/vdb1 /dev/vdc1 /dev/vdd1
```
??? example "Expected result"
    ```text
    Labels on physical volume "/dev/vdb1" successfully wiped.
    Labels on physical volume "/dev/vdc1" successfully wiped.
    Labels on physical volume "/dev/vdd1" successfully wiped.
    ```

!!! pied-piper "Takeaway"
    The practical LVM workflow is:

    - create PVs
    - create a VG
    - create an LV
    - make a filesystem on the LV
    - extend the LV and filesystem as the VG grows

## :material-book-open-page-variant-outline: 5.7 Device Mapper Multipathing

Device Mapper Multipathing (DM-Multipath) solves a specific storage problem: a server may be able to reach the same storage device through more than one physical path.

Those paths might go through different HBAs, cables, switches, or storage controllers, but they still lead to the same backend disk or LUN.

Without multipathing, Linux can show those paths as separate block devices even though they are not separate disks. That creates two risks:

- you may mistake several paths for several independent disks
- I/O may stop if the active path fails

DM-Multipath groups those paths into one logical device and keeps track of which physical paths belong together.

This provides:

- **path redundancy**: fail over to another path if one path fails
- **improved performance**: distribute I/O across multiple active paths when supported

!!! note
    Multipathing solves path failure problems. It does not replace RAID. RAID protects against disk failure patterns, while multipath protects against path failure between the server and the storage.

Practical example:

- a server is connected to the same SAN LUN through two Fibre Channel paths
- Linux may see those paths as `/dev/sda` and `/dev/sdb`
- without multipath, those names look like two disks even though they point to the same storage
- with DM-Multipath, Linux exposes one logical device such as `mpatha`
- if one path fails, I/O can continue through the remaining path

Student takeaway: when you see several devices with the same size and the same WWID, do not assume they are separate disks. They may just be separate paths to the same storage.

```bash
# Show the current block device layout.
lsblk
```
??? quote "Reference output"
    ```text
    NAME   MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
    sda      8:0    0  100G  0 disk
    sdb      8:16   0  100G  0 disk
    ```

In a real multipath environment, entries like `sda` and `sdb` may be two paths to the same storage rather than two different disks.

```bash
# List multipath devices.
sudo multipath -ll
```
??? quote "Reference output"
    ```text
    mpatha (3600508b400105e210000900000490000) dm-0 IBM,2810XIV
    size=100G features='1 queue_if_no_path' hwhandler='0' wp=rw
    |-+- policy='round-robin 0' prio=1 status=active
    | `- 0:0:0:0 sda 8:0  active ready running
    `-+- policy='round-robin 0' prio=1 status=enabled
      `- 1:0:0:0 sdb 8:16 active ready running
    ```

!!! note
    In this VM-based lab, `sudo multipath -ll` may return no output because the guest does not have multiple paths to the same storage device.

DM-Multipath decides which paths belong together by using the device's WWID.

The WWID is the stable identity of the storage device. If device names change across reboots, the WWID still lets multipath recognize that the paths lead to the same backend storage.

```bash
# Display the WWID for a SCSI device.
sudo /lib/udev/scsi_id --whitelisted --device=/dev/sdX
```
??? quote "Reference output"
    ```text
    3600508b400105e210000900000490000
    ```

!!! note
    This WWID example applies to SCSI devices such as `/dev/sdX`. On virtio-backed VMs that use `/dev/vdX`, the command may return no output.

!!! pied-piper "Takeaway"
    Multipathing means:

    - several device nodes may be several paths to the same storage
    - DM-Multipath groups those paths into one logical device
    - multipath protects against path failure, not disk failure

## :material-book-open-page-variant-outline: 5.8 Device Mapper Multipathing Lab

!!! info
    This lab is mostly a tool walkthrough. In a real environment, multipath is used with SAN or iSCSI storage that exposes multiple paths to the same LUN.

    In this VM lab, the tools are present, but `sudo multipath -ll` may still show no devices because there is no true multipath storage backend.

Step 1: Install the multipath tools.

```bash
# Install the multipath tools.
sudo apt install -y multipath-tools
```
??? example "Expected result"
    ```text
    Reading package lists... Done
    Building dependency tree... Done
    ...
    Setting up multipath-tools ...
    ```

Step 2: Reload the multipath configuration and rescan devices.

```bash
# Reload multipath configuration and rescan for devices.
sudo multipath -r
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 3: List the discovered multipath devices.

```bash
# Show the currently discovered multipath devices.
sudo multipath -ll
```
??? example "Expected result"
    ```text
    No output.
    ```

!!! pied-piper "Takeaway"
    In this lab, the important point is:

    - the tools work even if the VM has no real multipath storage to show
    - in a real SAN environment, `multipath -ll` would group multiple physical paths under one logical device
