# Storage Lab Commands

Source: `docs/storage.md`

## 5.2 Partitioning Lab

### 5.2.1 Using `parted` For GPT Partitions

```bash
# Show the current block device layout.
lsblk
```

```bash
# Print the current partition table on /dev/vdb.
sudo parted /dev/vdb print
```

```bash
# Create a new GPT partition table on /dev/vdb (non-interactively).
sudo parted --script /dev/vdb mklabel gpt
```

```bash
# Create one ext4 partition from 1MiB to the end of the disk (non-interactively).
sudo parted --script /dev/vdb mkpart primary ext4 1MiB 100%
```

```bash
# Print the partition table after creating the GPT partition.
sudo parted /dev/vdb print
```

```bash
# Show filesystem information for the new partition.
lsblk -f /dev/vdb1
```

```bash
# Create an ext4 filesystem on /dev/vdb1.
sudo mkfs.ext4 /dev/vdb1
```

```bash
# Create the mount directory used in this lab.
sudo mkdir -p /mnt/data
```

```bash
# Mount /dev/vdb1 on /mnt/data.
sudo mount /dev/vdb1 /mnt/data
```

```bash
# Check the mounted filesystem usage.
df -h /mnt/data
```

```bash
# Display the UUID of /dev/vdb1.
sudo blkid /dev/vdb1
```

```bash
# Edit /etc/fstab to add a persistent mount entry.
sudo nano /etc/fstab
```

```bash
# Validate the current /etc/fstab entries.
sudo mount -a
```

```bash
# Reboot LABVM to verify the persistent mount.
sudo reboot
```

```bash
# Confirm that /mnt/data is mounted after reboot.
df -h /mnt/data
```

```bash
# Edit /etc/fstab again to remove the /mnt/data entry.
sudo nano /etc/fstab
```

```bash
# Unmount /mnt/data.
sudo umount /mnt/data
```

```bash
# Wipe filesystem and partition-table signatures from /dev/vdb.
sudo wipefs --all /dev/vdb
```

### 5.2.2 Using `fdisk` For MBR Partitions

```bash
# List the current partition table for /dev/vdb.
sudo fdisk -l /dev/vdb
```

```bash
# Open fdisk on /dev/vdb.
sudo fdisk /dev/vdb
```

```bash
# List the updated partition table after writing the changes.
sudo fdisk -l /dev/vdb
```

```bash
# Overwrite the first 10 MiB of /dev/vdb with zeros.
sudo dd if=/dev/zero of=/dev/vdb bs=1M count=10
```

```bash
# Confirm that the old partition table is no longer present.
sudo fdisk -l /dev/vdb
```

```bash
# Enable the fstrim timer.
sudo systemctl enable fstrim.timer
```

```bash
# Start the fstrim timer immediately.
sudo systemctl start fstrim.timer
```

## 5.4 RAID Lab

### 5.4.1 Creating A RAID Setup

```bash
# Install mdadm and parted.
sudo apt install -y mdadm parted
```

```bash
# Create a GPT label on /dev/vdb (non-interactively).
sudo parted --script /dev/vdb mklabel gpt
```

```bash
# Create a GPT label on /dev/vdc (non-interactively).
sudo parted --script /dev/vdc mklabel gpt
```

```bash
# Create a GPT label on /dev/vdd (non-interactively).
sudo parted --script /dev/vdd mklabel gpt
```

```bash
# Create a GPT label on /dev/vde (non-interactively).
sudo parted --script /dev/vde mklabel gpt
```

```bash
# Create a GPT label on /dev/vdf (non-interactively).
sudo parted --script /dev/vdf mklabel gpt
```

```bash
# Create one full-disk partition on /dev/vdb (non-interactively).
sudo parted -a optimal /dev/vdb --script mkpart primary ext4 1MiB 100%
```

```bash
# Create one full-disk partition on /dev/vdc (non-interactively).
sudo parted -a optimal /dev/vdc --script mkpart primary ext4 1MiB 100%
```

```bash
# Create one full-disk partition on /dev/vdd (non-interactively).
sudo parted -a optimal /dev/vdd --script mkpart primary ext4 1MiB 100%
```

```bash
# Create one full-disk partition on /dev/vde (non-interactively).
sudo parted -a optimal /dev/vde --script mkpart primary ext4 1MiB 100%
```

```bash
# Create one full-disk partition on /dev/vdf (non-interactively).
sudo parted -a optimal /dev/vdf --script mkpart primary ext4 1MiB 100%
```

```bash
# Create a RAID 5 array at /dev/md0 from the five member partitions.
sudo mdadm --create --verbose /dev/md0 --level=5 --raid-devices=5 /dev/vd[bcdef]1
```

```bash
# Watch the RAID creation progress.
watch cat /proc/mdstat
```

```bash
# Display the current RAID status.
cat /proc/mdstat
```

```bash
# Examine the RAID metadata on each member partition.
sudo mdadm --examine /dev/vd[b-f]1
```

```bash
# Display detailed information about /dev/md0.
sudo mdadm --detail /dev/md0
```

```bash
# Search the kernel log for virtio disk messages.
sudo dmesg | grep vd
```

```bash
# Open the mdadm manual page.
man mdadm
```

### 5.4.2 Removing A RAID

```bash
# Stop the active RAID array.
sudo mdadm --stop /dev/md0
```

```bash
# Remove RAID metadata from /dev/vdb1.
sudo mdadm --zero-superblock /dev/vdb1
```

```bash
# Remove RAID metadata from /dev/vdc1.
sudo mdadm --zero-superblock /dev/vdc1
```

```bash
# Remove RAID metadata from /dev/vdd1.
sudo mdadm --zero-superblock /dev/vdd1
```

```bash
# Remove RAID metadata from /dev/vde1.
sudo mdadm --zero-superblock /dev/vde1
```

```bash
# Remove RAID metadata from /dev/vdf1.
sudo mdadm --zero-superblock /dev/vdf1
```

```bash
# Show ARRAY lines from the mdadm configuration.
grep ARRAY /etc/mdadm/mdadm.conf
```

```bash
# Edit the mdadm configuration file.
sudo nano /etc/mdadm/mdadm.conf
```

```bash
# Example alerting directive shown in mdadm.conf.
grep '^MAILADDR' /etc/mdadm/mdadm.conf
```

## 5.6 Advanced LVM Lab

```bash
# Install the LVM tools.
sudo apt install -y lvm2
```

```bash
# Create a GPT label on /dev/vdb (non-interactively).
sudo parted --script /dev/vdb mklabel gpt
```

```bash
# Create one partition on /dev/vdb (non-interactively).
sudo parted --script /dev/vdb mkpart primary ext4 1MiB 100%
```

```bash
# Create a GPT label on /dev/vdc (non-interactively).
sudo parted --script /dev/vdc mklabel gpt
```

```bash
# Create one partition on /dev/vdc (non-interactively).
sudo parted --script /dev/vdc mkpart primary ext4 1MiB 100%
```

```bash
# Create an LVM physical volume on /dev/vdb1.
sudo pvcreate /dev/vdb1
```

```bash
# Create an LVM physical volume on /dev/vdc1.
sudo pvcreate /dev/vdc1
```

```bash
# List physical volumes with backing device information.
sudo pvs -o +devices
```

```bash
# Create a volume group named my_vg.
sudo vgcreate my_vg /dev/vdb1 /dev/vdc1
```

```bash
# List volume groups.
sudo vgs
```

```bash
# Create a 1 GB logical volume named my_lv.
sudo lvcreate -n my_lv -L 1GB my_vg
```

```bash
# List logical volumes.
sudo lvs
```

```bash
# Create an ext4 filesystem on the new logical volume.
sudo mkfs.ext4 /dev/my_vg/my_lv
```

```bash
# Create the mount point used in this lab.
sudo mkdir -p /mnt/data
```

```bash
# Mount the logical volume.
sudo mount /dev/my_vg/my_lv /mnt/data
```

```bash
# Convert my_lv into a mirrored logical volume.
sudo lvconvert -m +1 my_vg/my_lv
```

```bash
# Show detailed information about the logical volume.
sudo lvdisplay /dev/my_vg/my_lv
```

```bash
# Show physical volume usage.
sudo pvs
```

```bash
# Convert the mirrored LV back to a linear LV.
sudo lvconvert -m 0 my_vg/my_lv
```

```bash
# Check physical volume usage again.
sudo pvs
```

```bash
# Show logical volumes with backing device information.
sudo lvs -o +devices
```

```bash
# Show detailed segment mapping for the logical volume.
sudo lvs --segments /dev/my_vg/my_lv
```

```bash
# Show how each physical volume is used.
sudo pvdisplay -m
```

```bash
# Show the block device view of the LVM layout.
sudo lsblk
```

```bash
# Move my_lv from /dev/vdb1 to /dev/vdc1.
sudo pvmove -n my_lv /dev/vdb1 /dev/vdc1
```

```bash
# Show the logical volume backing devices after pvmove.
sudo lvs -o +devices
```

```bash
# Remove /dev/vdb1 from the volume group.
sudo vgreduce my_vg /dev/vdb1
```

```bash
# Extend the logical volume by 1 GiB and grow the filesystem.
sudo lvextend -r -L +1G /dev/my_vg/my_lv
```

```bash
# Check the mounted filesystem size.
df -h /mnt/data/
```

```bash
# List logical volumes after the resize.
sudo lvs
```

```bash
# List volume groups after the resize.
sudo vgs
```

```bash
# Create a GPT label on /dev/vdd (non-interactively).
sudo parted --script /dev/vdd mklabel gpt
```

```bash
# Create one partition on /dev/vdd (non-interactively).
sudo parted --script /dev/vdd mkpart primary ext4 1MiB 100%
```

```bash
# Create an LVM physical volume on /dev/vdd1.
sudo pvcreate /dev/vdd1
```

```bash
# Extend the volume group with /dev/vdd1.
sudo vgextend my_vg /dev/vdd1
```

```bash
# Check the updated volume group layout.
sudo vgs
```

```bash
# Extend the logical volume by another 1 GiB and grow the filesystem.
sudo lvextend -r -L +1G /dev/my_vg/my_lv
```

```bash
# Verify the mounted filesystem size again.
df -h /mnt/data/
```

```bash
# Unmount the logical volume from /mnt/data.
sudo umount /mnt/data
```

```bash
# Deactivate the volume group.
sudo vgchange -an my_vg
```

```bash
# Remove the logical volume.
sudo lvremove my_vg/my_lv
```

```bash
# Remove the volume group.
sudo vgremove my_vg
```

```bash
# Remove the physical volume metadata.
sudo pvremove /dev/vdb1 /dev/vdc1 /dev/vdd1
```

## 5.8 Device Mapper Multipathing Lab

```bash
# Install the multipath tools.
sudo apt install -y multipath-tools
```

```bash
# Reload multipath configuration and rescan for devices.
sudo multipath -r
```

```bash
# Show the currently discovered multipath devices.
sudo multipath -ll
```
