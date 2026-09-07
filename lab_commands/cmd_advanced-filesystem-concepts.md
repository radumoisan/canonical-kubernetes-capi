# Advanced Filesystem Concepts Lab Commands

Source: `docs/advanced-filesystem-concepts.md`

## 6.2 Filesystem Internals Lab

```bash
# Show filesystem inode usage.
df -ih
```

```bash
# Zero the beginning of /dev/vdb.
sudo dd if=/dev/zero of=/dev/vdb bs=1M count=10
```

```bash
# Create a GPT partition table on /dev/vdb.
sudo parted /dev/vdb mklabel gpt
```

```bash
# Create one ext4 partition on /dev/vdb.
sudo parted -a optimal /dev/vdb mkpart primary ext4 1 100%
```

```bash
# Format /dev/vdb1 as ext4.
sudo mkfs.ext4 /dev/vdb1
```

```bash
# Force fsck after two mounts.
sudo tune2fs -c 2 /dev/vdb1
```

```bash
# Force a filesystem check at least every two days.
sudo tune2fs -i 2d /dev/vdb1
```

```bash
# Display the full ext4 metadata summary.
sudo tune2fs -l /dev/vdb1
```

```bash
# Add acl to the filesystem default mount options.
sudo tune2fs -o acl /dev/vdb1
```

```bash
# Show the default mount options from the filesystem header.
sudo dumpe2fs -h /dev/vdb1 | grep Default
```

```bash
# Create the lab mount point.
sudo mkdir -p /mnt/fs
```

```bash
# Mount /dev/vdb1 on /mnt/fs.
sudo mount /dev/vdb1 /mnt/fs/
```

```bash
# Confirm that /dev/vdb1 is mounted.
mount | grep vdb1
```

```bash
# Hand ownership of the mount point to the ubuntu user.
sudo chown -R ubuntu:ubuntu /mnt/fs
```

```bash
# Create a test file with sample content.
echo "Hello World!" > /mnt/fs/file1.txt
```

```bash
# Unmount the filesystem before checking it.
sudo umount /dev/vdb1
```

```bash
# Run a verbose filesystem check.
sudo fsck -V /dev/vdb1
```

```bash
# Mount the filesystem again after the check.
sudo mount /dev/vdb1 /mnt/fs/
```

```bash
# Install the attr utilities.
sudo apt install -y attr
```

```bash
# Add a user-defined extended attribute to the test file.
setfattr -n user.comment -v "This is a demo file." /mnt/fs/file1.txt
```

```bash
# Display all extended attributes on the test file.
getfattr -d /mnt/fs/file1.txt
```

```bash
# Attempt to read an attribute that does not exist.
getfattr -n user.invalid /mnt/fs/file1.txt
```

```bash
# Install the ACL utilities.
sudo apt install -y acl
```

```bash
# Grant read access on the file to the nobody user.
sudo setfacl -m u:nobody:r /mnt/fs/file1.txt
```

```bash
# Show the ACL entries applied to the file.
getfacl /mnt/fs/file1.txt
```

```bash
# Remove the ACL entry for the nobody user.
sudo setfacl -x u:nobody /mnt/fs/file1.txt
```

```bash
# Unmount the lab filesystem.
sudo umount /mnt/fs
```

```bash
# Remove filesystem signatures from the lab partition.
sudo wipefs -a /dev/vdb1
```

## 6.4 `ext4` Filesystem Lab

```bash
# Create a GPT partition table on /dev/vdb.
sudo parted /dev/vdb mklabel gpt
```

```bash
# Create an ext4 partition that uses the first 80% of the disk.
sudo parted -a optimal /dev/vdb mkpart primary ext4 1MiB 80%
```

```bash
# Create the filesystem with a label and reduced reserved space.
sudo mkfs.ext4 -L ext4data -m 1 -E lazy_itable_init=1 /dev/vdb1
```

```bash
# Show the filesystem label and UUID details.
lsblk -f /dev/vdb
```

```bash
# Create the mount point used in this lab.
sudo mkdir -p /mnt/fs
```

```bash
# Mount the filesystem using its label.
sudo mount LABEL=ext4data /mnt/fs
```

```bash
# Verify the active mount.
mount | grep /mnt/fs
```

```bash
# Show the mounted filesystem size and usage.
df -h /mnt/fs
```

```bash
# Write a sample file into the filesystem.
echo "Testing ext4 advanced lab" | sudo tee /mnt/fs/info.txt
```

```bash
# Show the file metadata before reading it.
stat /mnt/fs/info.txt
```

```bash
# Read the file contents.
cat /mnt/fs/info.txt
```

```bash
# Show the metadata again so you can compare access time.
stat /mnt/fs/info.txt
```

```bash
# Unmount the filesystem before resizing the partition.
sudo umount /mnt/fs
```

```bash
# Grow partition 1 to 100% of the disk.
sudo parted /dev/vdb resizepart 1 100%
```

```bash
# Check the filesystem before resizing it.
sudo e2fsck -f /dev/vdb1
```

```bash
# Expand the filesystem to fill the resized partition.
sudo resize2fs /dev/vdb1
```

```bash
# Mount the filesystem again using its label.
sudo mount LABEL=ext4data /mnt/fs
```

```bash
# Confirm the larger filesystem size.
df -h /mnt/fs
```

```bash
# Check whether the filesystem has the journal feature.
sudo tune2fs -l /dev/vdb1 | grep has_journal
```

```bash
# Remount the filesystem with writeback journaling.
sudo mount -o remount,data=writeback /mnt/fs
```

```bash
# If remounting fails, mount again with the desired data mode.
sudo umount /mnt/fs
```

```bash
# Mount the filesystem with writeback journaling.
sudo mount -o data=writeback LABEL=ext4data /mnt/fs
```

```bash
# Show the active mount options for /mnt/fs.
mount | grep /mnt/fs
```

```bash
# Hand ownership of the mount point to the ubuntu user before the write tests.
sudo chown -R ubuntu:ubuntu /mnt/fs
```

```bash
# Write a 1 GiB test file and measure how long it takes.
time dd if=/dev/zero of=/mnt/fs/testfile bs=1M count=1024 status=progress
```

```bash
# Remount the filesystem with full data journaling.
sudo mount -o remount,data=journal /mnt/fs
```

```bash
# Unmount the filesystem before mounting it in journal mode.
sudo umount /mnt/fs
```

```bash
# Mount the filesystem with full data journaling.
sudo mount -o data=journal LABEL=ext4data /mnt/fs
```

```bash
# Show the active mount options for /mnt/fs.
mount | grep /mnt/fs
```

```bash
# Repeat the write test under journal mode using a second file.
time dd if=/dev/zero of=/mnt/fs/testfile-journal bs=1M count=1024 status=progress
```

```bash
# Remount the filesystem with ordered journaling and noatime.
sudo mount -o remount,data=ordered,noatime /mnt/fs
```

```bash
# Unmount the filesystem before mounting it with ordered mode and noatime.
sudo umount /mnt/fs
```

```bash
# Mount the filesystem with ordered journaling and noatime.
sudo mount -o data=ordered,noatime LABEL=ext4data /mnt/fs
```

```bash
# Show the file metadata before reading it again.
stat /mnt/fs/info.txt
```

```bash
# Read the file contents.
cat /mnt/fs/info.txt
```

```bash
# Check whether access time changed after the read.
stat /mnt/fs/info.txt
```

```bash
# Unmount the lab filesystem.
sudo umount /mnt/fs
```

```bash
# Remove filesystem signatures from /dev/vdb1.
sudo wipefs -a /dev/vdb1
```

## 6.6 `SETUID` and `SETGID` Lab

```bash
# Show the current mode bits on /usr/bin/passwd.
ls -l /usr/bin/passwd
```

```bash
# Remove setuid from the passwd binary.
sudo chmod u-s /usr/bin/passwd
```

```bash
# Confirm that the setuid bit is gone.
ls -l /usr/bin/passwd
```

```bash
# Run passwd without elevated privileges.
passwd
```

```bash
# Re-enable setuid on /usr/bin/passwd.
sudo chmod u+s /usr/bin/passwd
```

```bash
# Confirm that setuid is back.
ls -l /usr/bin/passwd
```

```bash
# Create an empty test file in the home directory.
touch ~/testfile
```

```bash
# Display the file mode.
ls -l ~/testfile
```

```bash
# Set the setuid bit on the file.
chmod u+s ~/testfile
```

```bash
# Show how the uppercase S appears.
ls -l ~/testfile
```

```bash
# Make the file owner-executable.
chmod u+x ~/testfile
```

```bash
# Show how lowercase s appears once execute is present.
ls -l ~/testfile
```

## 6.8 Sticky Bits Lab

```bash
# Create the test directory.
mkdir ~/teststick
```

```bash
# Make the directory world-writable.
chmod 777 ~/teststick
```

```bash
# Create three test files in the shared directory.
for ((i=1;i<=3;i++)) ; do
  touch ~/teststick/sbFile${i}
done
```

```bash
# Create the cm user.
sudo adduser cm
```

```bash
# Add cm to the ubuntu group.
sudo usermod -a -G ubuntu cm
```

```bash
# Start a shell as the cm user.
su cm
```

```bash
# Create three files owned by cm in the shared directory.
for ((i=1;i<=3;i++)) ; do
  touch /home/ubuntu/teststick/sbUserFile${i}
done
```

```bash
# Remove a file created by ubuntu.
rm /home/ubuntu/teststick/sbFile1
```

```bash
# Exit the cm shell.
exit
```

```bash
# Remove a file created by cm.
rm ~/teststick/sbUserFile1
```

```bash
# Protect the shared directory with the sticky bit.
chmod +t ~/teststick
```

```bash
# Verify that the sticky bit is now visible in the directory mode.
ls -ld ~/teststick
```

```bash
# Remove one of cm's remaining files.
rm ~/teststick/sbUserFile2
```

```bash
# Rename another file owned by cm.
mv ~/teststick/sbUserFile3 ~/teststick/sbUserFile4
```

```bash
# Start a shell as the cm user again.
su cm
```

```bash
# Try to remove a file owned by ubuntu.
rm /home/ubuntu/teststick/sbFile2
```

```bash
# Try to rename a file owned by ubuntu.
mv /home/ubuntu/teststick/sbFile3 /home/ubuntu/teststick/sbFile4
```

```bash
# Exit the cm shell.
exit
```
