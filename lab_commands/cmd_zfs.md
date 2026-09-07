# ZFS Lab Commands

Source: `docs/zfs.md`

## 7.2 ZFS Lab

### 7.2.1 Create ZFS Pools and Datasets

```bash
# Install the ZFS userland package.
sudo apt install -y zfsutils-linux
```

```bash
# Show the current block devices.
lsblk
```

```bash
# Remove old signatures from the lab disks.
for disk in vdb vdc vdd vde vdf vdg; do sudo wipefs -a /dev/$disk; done
```

```bash
# Create the initial mirrored pool.
sudo zpool create -f testpool mirror /dev/vdb /dev/vdc
```

```bash
# Show the pool status after creation.
sudo zpool status testpool
```

```bash
# Add one non-redundant disk to expand capacity.
sudo zpool add -f testpool /dev/vdd
```

```bash
# Add a second mirrored VDEV to the pool.
sudo zpool add testpool mirror /dev/vde /dev/vdf
```

```bash
# Show the full testpool layout after expansion.
sudo zpool status testpool
```

```bash
# Remove the testpool before the next exercise.
sudo zpool destroy testpool
```

```bash
# Create a three-disk RAIDZ pool.
sudo zpool create -f zfspool raidz /dev/vdb /dev/vdc /dev/vdd
```

```bash
# Show the status of zfspool.
sudo zpool status zfspool
```

```bash
# Create the first dataset.
sudo zfs create zfspool/mystuff
```

```bash
# Create the second dataset.
sudo zfs create zfspool/myFs2
```

```bash
# List all datasets in the pool.
sudo zfs list
```

```bash
# Show the currently mounted ZFS datasets.
mount -t zfs
```

```bash
# Show the ZFS-managed mounts.
zfs mount
```

```bash
# Create the manual mount directory.
sudo mkdir /mnt/myzfs
```

```bash
# Set mystuff to legacy mount handling.
sudo zfs set mountpoint=legacy zfspool/mystuff
```

```bash
# Mount the dataset manually.
sudo mount -t zfs zfspool/mystuff /mnt/myzfs
```

```bash
# Show ZFS-managed mounts after switching to legacy mode.
zfs mount
```

```bash
# Show all mounted ZFS filesystems, including the manual mount.
mount -t zfs
```

### 7.2.2 ZFS Compression

```bash
# Show all ZFS properties for zfspool.
sudo zfs get all zfspool
```

```bash
# Show the current compression property.
sudo zfs get compression zfspool
```

```bash
# Turn on compression for the pool.
sudo zfs set compression=on zfspool
```

```bash
# Verify that compression is enabled.
sudo zfs get compression zfspool
```

```bash
# Show the current compression ratio.
sudo zfs get compressratio zfspool
```

```bash
# Create a large zero-filled file in the dataset.
sudo dd if=/dev/zero of=/mnt/myzfs/file1 count=1024 bs=1M
```

```bash
# Confirm the test file size.
ls -lh /mnt/myzfs/file1
```

```bash
# Show the new compression ratio on the dataset that received the file.
sudo zfs get compressratio zfspool/mystuff
```

### 7.2.3 ZFS Snapshots and Rollbacks

```bash
# Create the first recursive snapshot.
sudo zfs snapshot -r zfspool/mystuff@snap1
```

```bash
# Show all snapshots on the system.
sudo zfs list -t snapshot
```

```bash
# Write a second test file after the snapshot.
sudo dd if=/dev/zero of=/mnt/myzfs/file2 count=1024 bs=1M
```

```bash
# List the dataset contents by modification time.
ls -alt /mnt/myzfs/
```

```bash
# Roll back to snap1.
sudo zfs rollback zfspool/mystuff@snap1
```

```bash
# Confirm that file2 is gone after rollback.
ls -alt /mnt/myzfs/
```

```bash
# Create the second snapshot.
sudo zfs snapshot -r zfspool/mystuff@snap2
```

```bash
# Write a third test file.
sudo dd if=/dev/zero of=/mnt/myzfs/file3 count=1024 bs=1M
```

```bash
# Review the dataset contents before deleting a file.
ls -alt /mnt/myzfs/
```

```bash
# Remove file1 before taking snap3.
sudo rm /mnt/myzfs/file1
```

```bash
# Create the third snapshot.
sudo zfs snapshot -r zfspool/mystuff@snap3
```

```bash
# Review the dataset contents after creating snap3.
ls -alt /mnt/myzfs/
```

```bash
# List the current snapshots again.
sudo zfs list -t snapshot
```

```bash
# Show differences recorded since snap3.
sudo zfs diff zfspool/mystuff@snap3
```

```bash
# Delete snap2.
sudo zfs destroy zfspool/mystuff@snap2
```

```bash
# Delete snap3.
sudo zfs destroy zfspool/mystuff@snap3
```

### 7.2.4 ZFS Clones and Quotas

```bash
# Create a writable clone from snap1.
sudo zfs clone zfspool/mystuff@snap1 zfspool/mystuff/snap1clone
```

```bash
# Show the cloned dataset.
sudo zfs list
```

```bash
# Limit the dataset to 10 GiB.
sudo zfs set quota=10G zfspool/mystuff
```

```bash
# Show the quota value.
sudo zfs get quota zfspool/mystuff
```

### 7.2.5 ZFS Send and Receive

```bash
# Create snap2 for send/receive.
sudo zfs snapshot -r zfspool/mystuff@snap2
```

```bash
# Save the snapshot stream to a file.
sudo zfs send zfspool/mystuff@snap2 > ~/mystuff-snap.zfs
```

```bash
# Restore the snapshot into a new dataset.
sudo zfs receive -F zfspool/mystuff-copy < ~/mystuff-snap.zfs
```

```bash
# Example remote send over SSH.
sudo zfs send zfspool/mystuff@snap2 | ssh remotehost sudo zfs receive -F zfspool/mystuff-copy
```

### 7.2.6 ZFS Ditto Blocks

```bash
# Store three copies of data blocks in the dataset.
sudo zfs set copies=3 zfspool/mystuff
```

```bash
# Show the copies property.
sudo zfs get copies zfspool/mystuff
```

### 7.2.7 ZFS Deduplication

```bash
# Turn on deduplication for the dataset.
sudo zfs set dedup=on zfspool/mystuff
```

```bash
# Show the dedup property.
sudo zfs get dedup zfspool/mystuff
```

### 7.2.8 ZFS Scrubbing and Fault Simulation

```bash
# Write random data into the pool.
sudo dd if=/dev/urandom of=/zfspool/random.dat bs=1M count=20
```

```bash
# Calculate the checksum of the test file.
md5sum /zfspool/random.dat
```

```bash
# Take /dev/vdd offline to simulate a failed device.
sudo zpool offline zfspool /dev/vdd
```

```bash
# Show the degraded or unavailable device state.
sudo zpool status
```

```bash
# Start a scrub on zfspool.
sudo zpool scrub zfspool
```

```bash
# Show detailed scrub progress.
sudo zpool status -v zfspool
```

```bash
# Replace the damaged device with /dev/vdg.
sudo zpool replace zfspool /dev/vdd /dev/vdg -f
```

```bash
# Confirm that the replacement is in progress or complete.
sudo zpool status -v zfspool
```

### 7.2.9 Destroy a ZFS Pool

```bash
# List ZFS filesystems.
sudo zfs list -t filesystem
```

```bash
# List ZFS snapshots.
sudo zfs list -t snapshot
```

```bash
# List ZFS volumes.
sudo zfs list -t volume
```

```bash
# List all ZFS object types.
sudo zfs list -t all
```

```bash
# Destroy the entire dataset tree recursively.
sudo zfs destroy -r zfspool
```

```bash
# Remove the zfspool storage pool.
sudo zpool destroy zfspool
```

## 7.3 ZFS RAID Lab

### 7.3.1 RAIDZ Exercises

```bash
# Create a RAIDZ pool across four disks.
sudo zpool create -f zfsraid5 raidz /dev/vdb /dev/vdc /dev/vdd /dev/vde
```

```bash
# Show the RAIDZ pool status.
sudo zpool status zfsraid5
```

```bash
# Show the dataset view of the pool.
zfs list
```

```bash
# Remove the RAIDZ pool before creating the RAIDZ2 example.
sudo zpool destroy zfsraid5
```

```bash
# Create a RAIDZ2 pool across five disks.
sudo zpool create -f zfsraid6 raidz2 /dev/vdb /dev/vdc /dev/vdd /dev/vde /dev/vdf
```

```bash
# Show the RAIDZ2 pool status.
sudo zpool status zfsraid6
```

```bash
# Show the dataset view of the RAIDZ2 pool.
zfs list
```

```bash
# Review the RAIDZ2 pool before cleanup.
sudo zpool status zfsraid6
```

```bash
# Destroy the RAIDZ2 pool.
sudo zpool destroy zfsraid6
```

### 7.3.2 Nested RAIDZ1

```bash
# Create a pool with the first RAIDZ VDEV.
sudo zpool create zfsraid60 raidz /dev/vdb /dev/vdc /dev/vdd -f
```

```bash
# Add the second RAIDZ VDEV to the pool.
sudo zpool add zfsraid60 raidz /dev/vde /dev/vdf /dev/vdg
```

```bash
# Show the nested RAIDZ layout.
sudo zpool status zfsraid60
```

```bash
# Show the dataset view of the pool.
zfs list
```

```bash
# Remove the nested RAIDZ pool.
sudo zpool destroy zfsraid60
```

### 7.3.3 RAID10 Equivalent

```bash
# Create a pool from two mirrored VDEVs.
sudo zpool create zfsraid10 mirror /dev/vdb /dev/vdc mirror /dev/vdd /dev/vde -f
```

```bash
# Show the RAID10-style pool status.
sudo zpool status zfsraid10
```

```bash
# Show the dataset view of the mirrored pool.
zfs list
```

```bash
# Write random data into the mirrored pool.
sudo dd if=/dev/urandom of=/zfsraid10/random.dat bs=1M count=20
```

```bash
# Overwrite the beginning of /dev/vde.
sudo dd if=/dev/zero of=/dev/vde bs=1M count=10
```

```bash
# Start a scrub on the mirrored pool.
sudo zpool scrub zfsraid10
```

```bash
# Show detailed status for zfsraid10.
sudo zpool status -v zfsraid10
```

```bash
# Replace /dev/vde with /dev/vdg.
sudo zpool replace zfsraid10 /dev/vde /dev/vdg -f
```

```bash
# Confirm the pool recovered after replacement.
sudo zpool status -v zfsraid10
```

```bash
# Remove the mirrored test pool.
sudo zpool destroy zfsraid10
```

### 7.3.4 File-Based Pool

```bash
# Create a 2 GiB file for a file-backed pool.
dd if=/dev/zero of="$HOME/zfsraidpool.img" bs=1M count=2048
```

```bash
# Create a pool on the file.
sudo zpool create zfsraidpool "$HOME/zfsraidpool.img"
```

```bash
# Show the file-backed pool status.
sudo zpool status zfsraidpool
```

```bash
# Show the mountpoint property.
sudo zfs get mountpoint zfsraidpool
```

```bash
# Show the dataset view of the file-backed pool.
zfs list
```

```bash
# Remove the file-backed test pool.
sudo zpool destroy zfsraidpool
```

### 7.3.5 Cache and ZIL Devices

```bash
# Create a mirrored pool for cache and log testing.
sudo zpool create zfsmirror mirror /dev/vdd /dev/vde -f
```

```bash
# Show the pool status before adding special devices.
sudo zpool status zfsmirror
```

```bash
# Add /dev/vdc as a cache device.
sudo zpool add zfsmirror cache /dev/vdc
```

```bash
# Add /dev/vdf as a log device.
sudo zpool add zfsmirror log /dev/vdf
```

```bash
# Show the pool after adding cache and log devices.
sudo zpool status
```

```bash
# Remove the cache device from the pool.
sudo zpool remove zfsmirror vdc
```

```bash
# Show the pool after removing the cache device.
sudo zpool status
```

```bash
# Remove the cache and log test pool.
sudo zpool destroy zfsmirror
```
