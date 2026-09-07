# Advanced System Topics

!!! warning
    This chapter includes supplemental topics that are not covered during the 3-day training. Use it as reference material for enterprise use cases, debugging, logging integration, and advanced storage work. It is not part of the live lab validation track used for the earlier chapters.

In this chapter, you will:

- review time synchronization with `systemd-timesyncd` and `chrony`
- revisit traditional logging with `rsyslog`
- use `sosreport` and `apport` for diagnostics
- explore XFS administration and related tools

## :material-book-open-page-variant-outline: 11.1 Time Synchronization With chrony & timesyncd

Accurate time matters because authentication, certificates, log correlation, monitoring, and distributed systems all depend on it.

### :material-application-edit-outline: Network Time Protocol (NTP)

NTP synchronizes clocks between systems. In practice, most environments use a hierarchy of time sources and clients so systems stay aligned to a trusted upstream source.

Ubuntu uses `systemd-timesyncd` by default for lightweight time synchronization. When you need more advanced control or server capabilities, `chrony` is the usual replacement.

### :material-application-edit-outline: Network Time Security (NTS)

Standard NTP is not secure by design. NTS adds TLS-based authentication and integrity checks so time responses cannot be spoofed as easily.

The simple way to remember the difference is:

- NTP keeps clocks aligned
- NTS makes that time source easier to trust

```bash
# Check the current time synchronization state.
timedatectl status
```
??? example "Expected result"
    ```text
    Local time: ...
    System clock synchronized: yes
    NTP service: active
    ```

Useful commands:

```bash
# Check synchronization status.
timedatectl status
```
??? example "Expected result"
    ```text
    System clock synchronized: yes
    ```

```bash
# Show the current time source.
timedatectl timesync-status
```
??? example "Expected result"
    ```text
    Server: ...
    Stratum: ...
    ```

```bash
# Check the default time service.
systemctl status systemd-timesyncd
```
??? example "Expected result"
    ```text
    systemd-timesyncd.service - Network Time Synchronization
    Active: active (running)
    ```

Installing and checking `chrony`:

```bash
# Install chrony.
sudo apt install chrony -y
```
??? example "Expected result"
    ```text
    chrony is already the newest version (...)
    ```

```bash
# Check the chrony service.
systemctl status chrony
```
??? example "Expected result"
    ```text
    chrony.service - chrony, an NTP client/server
    Active: active (running)
    ```

```bash
# Show chrony synchronization tracking.
chronyc tracking
```
??? example "Expected result"
    ```text
    Reference ID    : ...
    Stratum         : ...
    Leap status     : Normal
    ```

```bash
# Show chrony sources.
chronyc sources
```
??? example "Expected result"
    ```text
    MS Name/IP address         Stratum Poll Reach LastRx Last sample
    ...
    ```

To configure `chrony` with NTS:

```bash
# Add an NTS source definition.
sudo tee /etc/chrony/sources.d/cloudflare.sources <<EOF
server time.cloudflare.com nts iburst
EOF
```
??? example "Expected result"
    ```text
    server time.cloudflare.com nts iburst
    ```

```bash
# Restart chrony after changing sources.
sudo systemctl restart chrony
```

```bash
# Check authentication data and confirm NTS use.
chronyc -N authdata
```
??? example "Expected result"
    ```text
    Name/IP address             Mode ...
    time.cloudflare.com         NTS  ...
    ```

!!! pied-piper "Takeaway"
    The main decision is simple: `systemd-timesyncd` is fine for lightweight client use, while `chrony` is the tool to reach for when you need deeper control or server features.

## :material-book-open-page-variant-outline: 11.2 Time Synchronization Lab

Run this lab on `LABVM`.

This lab shows the default time sync setup, then switches to `chrony` and verifies that it takes over from `systemd-timesyncd`.

Step 1: Check the current synchronization state.

```bash
# Show the current time synchronization status.
timedatectl status
```
??? example "Expected result"
    ```text
    System clock synchronized: yes
    NTP service: active
    ```

```bash
# Check the systemd-timesyncd service.
systemctl status systemd-timesyncd
```
??? example "Expected result"
    ```text
    systemd-timesyncd.service - Network Time Synchronization
    Active: active (running)
    ```

```bash
# Show the current time source details.
timedatectl timesync-status
```
??? example "Expected result"
    ```text
    Server: ... (ntp.ubuntu.com)
    Stratum: ...
    ```

Step 2: Check whether `chrony` is installed and install it if needed.

On some systems, `chrony` may already be installed. The goal here is to confirm which service currently owns time synchronization, not to assume the starting state.

```bash
# Check if chrony is installed.
dpkg-query --list chrony
```
??? example "Expected result"
    ```text
    No packages found matching chrony
    ```

```bash
# Install chrony.
sudo apt install -y chrony
```
??? example "Expected result"
    ```text
    Setting up chrony (...)
    ```

```bash
# Verify that chrony now appears in the package list.
dpkg-query --list chrony
```
??? example "Expected result"
    ```text
    ii  chrony  ...
    ```

Step 3: Verify that `chrony` takes over.

```bash
# Check that systemd-timesyncd is no longer active.
systemctl status systemd-timesyncd
```
??? example "Expected result"
    ```text
    systemd-timesyncd.service
    Loaded: masked
    Active: inactive (dead)
    ```

```bash
# Check the chrony service.
systemctl status chrony
```
??? example "Expected result"
    ```text
    chrony.service - chrony, an NTP client/server
    Active: active (running)
    ```

```bash
# Show chrony tracking data.
chronyc tracking
```
??? example "Expected result"
    ```text
    Reference ID    : ...
    Stratum         : ...
    Leap status     : Normal
    ```

```bash
# Show all chrony sources.
chronyc sources
```
??? example "Expected result"
    ```text
    MS Name/IP address         Stratum Poll Reach LastRx Last sample
    ...
    ```

Step 4: Reconfigure `chrony` to use NTS.

```bash
# Inspect the current chrony configuration.
cat /etc/chrony/chrony.conf
```
??? example "Expected result"
    ```text
    pool ntp.ubuntu.com iburst maxsources 4
    ...
    ```

```bash
# Add the Cloudflare NTS source file.
sudo tee /etc/chrony/sources.d/cloudflare.sources <<EOF
server time.cloudflare.com nts iburst
EOF
```
??? example "Expected result"
    ```text
    server time.cloudflare.com nts iburst
    ```

```bash
# Edit the chrony config and comment out pool lines.
sudo vim /etc/chrony/chrony.conf
```
??? example "Expected result"
    ```text
    # pool ntp.ubuntu.com iburst maxsources 4
    # pool 0.ubuntu.pool.ntp.org iburst maxsources 1
    ...
    ```

```bash
# Restart chrony.
sudo systemctl restart chrony
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Show verbose chrony source information.
chronyc sources -v
```
??? example "Expected result"
    ```text
    MS Name/IP address         Stratum Poll Reach LastRx Last sample
    ^* time.cloudflare.com     ...
    ```

```bash
# Confirm that NTS is in use.
sudo chronyc -N authdata
```
??? example "Expected result"
    ```text
    Name/IP address             Mode ...
    time.cloudflare.com         NTS  ...
    ```

!!! pied-piper "Takeaway"
    In practice, this lab teaches one core idea: only one time sync service should own the system, and after switching to `chrony` you should verify both the active sources and the security mode in use.

## :material-book-open-page-variant-outline: 11.3 Traditional Logging With rsyslog

Ubuntu uses `systemd-journald` for structured logs, but `rsyslog` is still useful when you need plain-text log files, compatibility with older tooling, or log forwarding.

By default, `rsyslog` and `journald` are separate. If you want journald to forward into rsyslog, you need to enable `ForwardToSyslog=yes` in `/etc/systemd/journald.conf`.

`rsyslog` is commonly used for:

- legacy text-based logging workflows
- log forwarding to external collectors
- compliance or forensic retention of plain-text logs

Installing and checking `rsyslog`:

```bash
# Install rsyslog if needed.
sudo apt install rsyslog -y
```
??? example "Expected result"
    ```text
    rsyslog is already the newest version (...)
    ```

```bash
# Install rsyslog documentation.
sudo apt install rsyslog-doc -y
```
??? example "Expected result"
    ```text
    Setting up rsyslog-doc (...)
    ```

```bash
# Check the rsyslog service.
sudo systemctl status rsyslog
```
??? example "Expected result"
    ```text
    rsyslog.service - System Logging Service
    Active: active (running)
    ```

```bash
# Show the rsyslogd process.
ps aux | grep rsyslogd
```
??? example "Expected result"
    ```text
    syslog ... /usr/sbin/rsyslogd -n -iNONE
    ```

```bash
# Restart rsyslog after configuration changes.
sudo systemctl restart rsyslog
```

### :material-application-edit-outline: Configuration Structure

The default main configuration file is `/etc/rsyslog.conf`, and extra configuration files live in `/etc/rsyslog.d/`.

Important parts of the configuration are:

- modules
- global directives
- filter rules

Example module configuration:

```rsyslog
module(load="imuxsock") # provides support for local system logging
module(load="imklog" permitnonkernelfacility="on")
```

Example global directives:

```rsyslog
$ActionFileDefaultTemplate RSYSLOG_TraditionalFileFormat
$FileOwner syslog
$FileGroup adm
$IncludeConfig /etc/rsyslog.d/*.conf
```

Example filter rule:

```rsyslog
daemon.* /var/log/daemon.log
```

The left side is the selector, and the right side is the action. A selector combines a facility and a priority, such as `daemon.*` or `auth.notice`.

!!! pied-piper "Takeaway"
    The main `rsyslog` mental model is selector plus action: match the messages you care about, then decide where they go.

## :material-book-open-page-variant-outline: 11.4 rsyslog Lab

Run this lab on `LABVM`.

This lab focuses on where logs live, how to inspect them quickly, and how `journald` can be forwarded into `rsyslog`.

Step 1: Review the log directory.

```bash
# Move into /var/log.
cd /var/log
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# List recent log files.
ls -lt
```
??? example "Expected result"
    ```text
    total ...
    syslog
    kern.log
    auth.log
    ...
    ```

Step 2: Search for logs containing errors.

```bash
# Search /var/log for files containing error or failed.
sudo grep -rliE "error|failed" /var/log
```
??? example "Expected result"
    ```text
    /var/log/kern.log
    /var/log/dpkg.log
    ...
    ```

Step 3: Install and verify `rsyslog`.

```bash
# Install rsyslog.
sudo apt install rsyslog -y
```
??? example "Expected result"
    ```text
    rsyslog is already the newest version (...)
    ```

```bash
# Install rsyslog documentation.
sudo apt install rsyslog-doc -y
```
??? example "Expected result"
    ```text
    Setting up rsyslog-doc (...)
    ```

```bash
# Check the rsyslog service.
sudo systemctl status rsyslog
```
??? example "Expected result"
    ```text
    rsyslog.service - System Logging Service
    Active: active (running)
    ```

Step 4: Explore the full log directory tree.

```bash
# Show the /var/log tree.
tree /var/log/
```
??? example "Expected result"
    ```text
    /var/log/
    |-- apparmor
    |-- apt
    |-- auth.log
    |-- kern.log
    |-- syslog
    ...
    ```

Step 5: Enable journald forwarding into rsyslog.

```bash
# Enable journald forwarding to syslog.
sudo sed -i 's/^#ForwardToSyslog=no/ForwardToSyslog=yes/' /etc/systemd/journald.conf
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Restart journald.
sudo systemctl restart systemd-journald
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 6: Simulate remote forwarding.

```bash
# Create a simple remote forwarding rule.
echo "*.warn @127.0.0.1:514" | sudo tee /etc/rsyslog.d/99-remote.conf
```
??? example "Expected result"
    ```text
    *.warn @127.0.0.1:514
    ```

```bash
# Restart rsyslog.
sudo systemctl restart rsyslog
```
??? example "Expected result"
    ```text
    No output.
    ```

!!! pied-piper "Takeaway"
    The practical logging workflow is: know where the logs are, identify important files quickly, and understand how logs can be forwarded or reshaped with `rsyslog` rules.

## :material-book-open-page-variant-outline: 11.5 Diagnostic Tools: sosreport & apport

When troubleshooting a complex server issue, the first priority is collecting enough context to reproduce or escalate the problem.

### :material-application-edit-outline: sosreport

`sosreport` is the standard support-collection tool for Ubuntu and enterprise support workflows. It creates an archive of logs, configuration, package data, hardware details, and more.

Use `sosreport` when you need:

- support escalation
- a postmortem archive
- a broad diagnostic snapshot of the system

### :material-application-edit-outline: apport

`apport` is more focused on bug reporting and crash collection. It is more common in developer and community debugging workflows than in production server operations.

Use `apport` when you need:

- crash information for a package or service
- structured bug reports
- Launchpad-oriented debugging workflows

!!! pied-piper "Takeaway"
    Use `sosreport` for broad system diagnostics and support cases. Use `apport` when the problem is closer to a bug-reporting workflow than a support-collection workflow.

## :material-book-open-page-variant-outline: 11.6 Sosreport and Apport Lab

Run this lab on `LABVM`.

Step 1: Check whether `sosreport` is installed and install it if needed.

```bash
# Check for sosreport.
dpkg -l | grep sosreport
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Install sosreport.
sudo apt install sosreport -y
```
??? example "Expected result"
    ```text
    Setting up sosreport (...)
    ```

Step 2: Run `sosreport`.

```bash
# Run sosreport.
sudo sos report
```
??? example "Expected result"
    ```text
    sosreport (version ...)
    Press ENTER to continue, or CTRL-C to quit.
    ...
    ```

```bash
# Review the generated report archive in /tmp.
ls -lt /tmp/
```
??? example "Expected result"
    ```text
    sosreport-...tar.xz
    ```

Step 3: Review apport configuration.

```bash
# List apport configuration files.
ls -l /etc/apport
```
??? example "Expected result"
    ```text
    total ...
    crashdb.conf
    ...
    ```

```bash
# Edit apport crash filtering.
sudo vim /etc/apport/crashdb.conf
```
??? example "Expected result"
    ```text
    'problem_types': ['Bug', 'Package'],
    ```

Commenting this line removes the filter and allows full crash interception. Uncommenting it restores the more limited behavior.

!!! pied-piper "Takeaway"
    The important diagnostic habit is to collect before you guess. `sosreport` gives you a broad support archive, while `apport` controls how crash information is captured for bug reporting.

## :material-book-open-page-variant-outline: 11.7 XFS Filesystem (Advanced)

!!! note
    XFS is a high-performance journaling filesystem that is useful for specific workloads. It is less common than `ext4` as a general Ubuntu default, but it remains important in larger storage environments.

XFS is a 64-bit journaling filesystem designed for scalability and large filesystems.

### :material-application-edit-outline: XFS Structure

An XFS filesystem can contain:

- a data section for metadata and file data
- a log section for journaled metadata updates
- a real-time section for fixed-size extent allocation in specific workloads

### :material-application-edit-outline: Key Concepts

- extents reduce fragmentation and metadata overhead
- each filesystem has a UUID
- online growth, defragmentation, and freeze operations are core XFS capabilities

### :material-application-edit-outline: Required Software

Ubuntu kernels already include XFS support. The main user-space tools come from `xfsprogs`.

Important tools:

- `mkfs.xfs`
- `xfs_repair`
- `xfs_growfs`
- `xfs_fsr`
- `xfs_freeze`
- `xfsdump`
- `xfsrestore`

### :material-application-edit-outline: Tuning Notes

Common XFS tuning ideas include:

- matching stripe settings to RAID layout with `sunit` and `swidth`
- increasing log buffers with `logbufs=8`
- spreading large numbers of files across directories for concurrency

!!! pied-piper "Takeaway"
    The XFS value proposition is scale and operational tooling. The commands that matter most are the ones for creating, growing, freezing, defragmenting, and backing up the filesystem.

## :material-book-open-page-variant-outline: 11.8 XFS Lab

Run this lab on `LABVM`.

This lab creates an XFS filesystem, mounts it, adds it to `fstab`, then explores common maintenance commands.

Step 1: Install the XFS tools.

```bash
# Install XFS tools.
sudo apt install -y xfsprogs xfsdump
```
??? example "Expected result"
    ```text
    Setting up xfsprogs (...)
    Setting up xfsdump (...)
    ```

Step 2: Create and mount the XFS filesystem.

Make sure `/dev/vdc` is the intended lab disk before you wipe it.

```bash
# Wipe any existing filesystem signatures on /dev/vdc.
sudo wipefs -a /dev/vdc
```
??? example "Expected result"
    ```text
    /dev/vdc: ...
    ```

```bash
# Create a GPT label on /dev/vdc.
sudo parted /dev/vdc mklabel gpt
```

```bash
# Create a primary partition.
sudo parted -a optimal /dev/vdc mkpart primary 1MiB 100%
```

```bash
# Create an XFS filesystem.
sudo mkfs.xfs -L "datavol" -f /dev/vdc1
```
??? example "Expected result"
    ```text
    meta-data=/dev/vdc1 ...
    ```

```bash
# Create the mount point.
sudo mkdir /media/xfsmnt
```

```bash
# Mount the filesystem.
sudo mount -t xfs /dev/vdc1 /media/xfsmnt
```

Step 3: View the mounted drive.

```bash
# Show mounted block devices.
mount | grep vd
```
??? example "Expected result"
    ```text
    /dev/vdc1 on /media/xfsmnt type xfs ...
    ```

Step 4: Add the filesystem to `fstab`.

```bash
# Edit fstab.
sudo vim /etc/fstab
```
??? example "Expected result"
    ```text
    /dev/vdc1 /media/xfsmnt xfs rw,relatime,attr2,inode64,noquota 0 0
    ```

Step 5: Unmount and verify.

```bash
# Unmount the filesystem.
sudo umount /media/xfsmnt
```

```bash
# Verify that the XFS mount is gone.
mount | grep vd
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 6: Remount from `fstab` and verify.

```bash
# Mount all filesystems from fstab.
sudo mount -a
```

```bash
# Confirm the XFS filesystem is mounted again.
mount | grep vd
```
??? example "Expected result"
    ```text
    /dev/vdc1 on /media/xfsmnt type xfs ...
    ```

### :material-application-edit-outline: Other XFS Commands

```bash
# Freeze filesystem I/O.
sudo xfs_freeze -f /media/xfsmnt
```

```bash
# Unfreeze filesystem I/O.
sudo xfs_freeze -u /media/xfsmnt
```

```bash
# Defragment the filesystem.
sudo xfs_fsr /dev/vdc1
```
??? example "Expected result"
    ```text
    ...
    ```

```bash
# Grow the mounted filesystem.
sudo xfs_growfs /media/xfsmnt
```
??? example "Expected result"
    ```text
    meta-data=/dev/vdc1 ...
    ```

```bash
# Create an XFS dump backup.
sudo xfsdump - /media/xfsmnt > /tmp/xfs.dump
```

```bash
# Restore from the XFS dump.
sudo xfsrestore - /media/xfsmnt < /tmp/xfs.dump
```

### :material-application-edit-outline: Tuning Commands

```bash
# Read the XFS man page for tuning details.
man 5 xfs
```
??? example "Expected result"
    ```text
    XFS(5) File Formats Manual
    ```

```bash
# Unmount the partition before recreating it.
sudo umount /dev/vdc1
```

```bash
# Recreate the filesystem with stripe settings.
sudo mkfs.xfs -d sunit=128 -d swidth=384 /dev/vdc1 -f
```
??? example "Expected result"
    ```text
    meta-data=/dev/vdc1 ...
    ```

```bash
# Mount the filesystem again.
sudo mount /dev/vdc1
```

```bash
# Edit fstab to add logbufs=8.
sudo vim /etc/fstab
```
??? example "Expected result"
    ```text
    /dev/vdc1 /media/xfsmnt xfs rw,relatime,attr2,inode64,noquota,logbufs=8 0 0
    ```

```bash
# Remount the filesystem.
sudo mount -o remount /media/xfsmnt
```

```bash
# Verify the current mount.
mount | grep vd
```
??? example "Expected result"
    ```text
    /dev/vdc1 on /media/xfsmnt type xfs ...
    ```

### :material-application-edit-outline: Cleanup

```bash
# Unmount the XFS filesystem.
sudo umount /media/xfsmnt
```

```bash
# Remove the XFS fstab entry.
sudo vim /etc/fstab
```
??? example "Expected result"
    ```text
    # remove /dev/vdc1 /media/xfsmnt line
    ```

!!! pied-piper "Takeaway"
    The XFS workflow is straightforward: create, mount, persist in `fstab`, then use the dedicated XFS tools for freeze, growth, defragmentation, and backup operations.
