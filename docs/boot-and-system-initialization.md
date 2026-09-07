# Boot And System Initialization

This chapter covers GRUB2 boot configuration, systemd unit management, journald logging, and scheduled task tooling used in the lab.

In this chapter you will:

- understand GRUB2 boot configuration
- recognize LVM-aware boot setups
- manage services and units with `systemd`
- troubleshoot boot and service startup issues
- create custom services and timers
- schedule tasks with `systemd`, `at`, and `batch`

## :material-book-open-page-variant-outline: 4.1 What Is GRUB2?

To understand how a modern Ubuntu system starts, it helps to think of boot as a relay race. Each stage passes control to the next until the operating system is fully loaded.

!!! info
    Background terms:

    - `GPT` (GUID Partition Table) is the modern partition layout standard. It replaces older MBR-based layouts and supports large disks and many partitions.
    - `UEFI` (Unified Extensible Firmware Interface) is the firmware on the motherboard. It replaces the older BIOS and can read filesystems such as FAT32.

**1. UEFI Firmware**

When the machine powers on, the UEFI firmware starts first.

- It reads the EFI System Partition (`ESP`).
- It finds Ubuntu's GRUB2 `.efi` loader.
- It starts GRUB2.

**2. GRUB2**

GRUB2 is Ubuntu's default bootloader. It supports both UEFI/GPT and older BIOS/MBR systems.

Its main job is to locate the operating system files and prepare the next hand-off.

- It reads its generated configuration from `grub.cfg`.
- It identifies the kernel to boot.
- It prepares the initrd.

Menu behavior is usually controlled from `/etc/default/grub`.

**3. Kernel And initrd**

GRUB2 loads two important files into memory and then transfers control.

- The kernel (`vmlinuz`) is the core of the operating system.
- The `initrd` (initial RAM disk) is a temporary filesystem that includes the drivers and tools needed to reach the real root filesystem.

After the kernel starts, it uses the initrd to find and mount the real Ubuntu root filesystem.

**4. systemd And Userspace**

Once the real root filesystem is available, the kernel starts `systemd` as PID 1.

- `systemd` starts services and targets.
- The system reaches the normal multi-user or graphical state.

!!! note
    Older systems may use BIOS and MBR instead of UEFI and GPT. The overall hand-off is similar, but the initial bootloader code is loaded from the MBR rather than from an EFI System Partition.

### :material-application-edit-outline: GRUB2 And LVM Root Setups

Ubuntu can be installed with LVM-backed root filesystems. In those cases, GRUB2 must be able to read logical volumes so it can locate the kernel and initrd at boot time. It does that by loading the `lvm.mod` module.

Keeping `/boot` on a non-LVM partition is still a common recommendation, but GRUB2 can boot systems that use LVM for `/` when the required modules are present.

### :material-application-edit-outline: GRUB2 Configuration Files

- `/etc/default/grub`: default menu behavior and kernel command-line settings
- `/etc/grub.d/`: helper scripts used to build the final menu
- `/boot/grub/grub.cfg`: generated boot menu used at startup

!!! note
    Do not edit `/boot/grub/grub.cfg` directly. Regenerate it from `/etc/default/grub` and `/etc/grub.d/`.

```bash
# Regenerate the GRUB menu configuration.
sudo update-grub
```
??? quote "Reference output"
    ```text
    Sourcing file /etc/default/grub
    Generating grub configuration file ...
    Found linux image: /boot/vmlinuz-...
    Found initrd image: /boot/initrd.img-...
    done
    ```

Typical GRUB2 workflow:

1. Edit `/etc/default/grub` or files under `/etc/grub.d/`.
2. Run `sudo update-grub`.
3. Reboot if you need to test the new boot configuration.

!!! pied-piper "Takeaway"
    The GRUB workflow is:

    - change `/etc/default/grub` or `/etc/grub.d/`
    - regenerate `/boot/grub/grub.cfg` with `update-grub`
    - reboot only when you need to test the result

## :material-book-open-page-variant-outline: 4.2 GRUB2 Lab

!!! info
    Run this lab on `LABVM` unless a step explicitly says to switch back to `LABHOST` for the libvirt console.

### :material-application-edit-outline: 4.2.1 GRUB2 Configuration

This lab reviews the active GRUB2 configuration and updates the menu behavior.

Step 1: Connect to `LABVM`.

```bash
# Connect to LABVM as the ubuntu user over SSH.
ssh ubuntu@192.168.101.50
```
??? example "Expected result"
    ```text
    ubuntu@192.168.101.50's password:
    Welcome to Ubuntu 24.04 LTS (GNU/Linux ...)
    ubuntu@ubuntu:~$
    ```

!!! note
    Use the explicit `ubuntu@192.168.101.50` form here. A local SSH alias such as `labvm` may connect as a different user.

Step 2: Inspect the current GRUB defaults.

```bash
# Display the current GRUB defaults file.
cat /etc/default/grub
```
??? example "Expected result"
    ```text
    # If you change this file, run 'update-grub' afterwards to update
    # /boot/grub/grub.cfg.
    ...
    GRUB_DEFAULT=0
    GRUB_TIMEOUT_STYLE=hidden
    GRUB_TIMEOUT=0
    GRUB_DISTRIBUTOR=`( . /etc/os-release; echo ${NAME:-Ubuntu} ) 2>/dev/null || echo Ubuntu`
    GRUB_CMDLINE_LINUX_DEFAULT="quiet splash"
    GRUB_CMDLINE_LINUX=""
    ```

Step 3: List the available boot menu entries.

```bash
# List GRUB menu entries from the generated configuration.
sudo awk -F\' '$1=="menuentry " {print i++ " : " $2}' /boot/grub/grub.cfg
```
??? example "Expected result"
    ```text
    0 : Ubuntu
    ```

!!! note
    Some systems will show more than one entry if multiple kernels are installed.

Step 4: Install `vim` (optional).

```bash
# Install vim for editing GRUB settings.
sudo apt install -y vim
```
??? example "Expected result"
    ```text
    WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

    Reading package lists...
    Building dependency tree...
    Reading state information...
    vim is already the newest version (2:9.1.0016-1ubuntu7.10).
    0 upgraded, 0 newly installed, 0 to remove and 17 not upgraded.
    ```

!!! note
    Ubuntu ships with `nano` by default. Any text editor is fine here.

Step 5: Remove the cloud image GRUB drop-in if it is present.

```bash
# Remove the cloud image GRUB defaults drop-in if it exists.
sudo rm -f /etc/default/grub.d/50-cloudimg-settings.cfg
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 6: Edit the main GRUB defaults file.

```bash
# Edit the GRUB defaults file so the menu stays visible and remembers the last selection.
sudo vim /etc/default/grub
```
??? example "Expected result"
    ```text
    "/etc/default/grub" ...
    ```

Set these values while editing:

```ini
GRUB_DEFAULT="saved"
GRUB_SAVEDEFAULT="true"
GRUB_TIMEOUT=10
GRUB_TIMEOUT_STYLE="menu"
```

These settings tell GRUB to remember the last selected entry and display the menu for 10 seconds.

Step 7: Regenerate the boot menu.

```bash
# Rebuild the generated GRUB configuration.
sudo update-grub
```
??? example "Expected result"
    ```text
    Sourcing file `/etc/default/grub'
    Generating grub configuration file ...
    Found linux image: /boot/vmlinuz-6.8.0-107-generic
    Found initrd image: /boot/initrd.img-6.8.0-107-generic
    Found linux image: /boot/vmlinuz-6.8.0-106-generic
    Found initrd image: /boot/initrd.img-6.8.0-106-generic
    Warning: os-prober will not be executed to detect other bootable partitions.
    Systems on them will not be added to the GRUB boot configuration.
    Check GRUB_DISABLE_OS_PROBER documentation entry.
    Adding boot menu entry for UEFI Firmware Settings ...
    done
    ```

!!! note
    On this VM, multiple installed kernels still produced a single top-level `0 : Ubuntu` menu entry. Additional kernels were grouped under advanced options rather than listed as separate top-level entries.

### :material-application-edit-outline: 4.2.2 Console Connection

By default, the libvirt console may not show the GRUB menu. This lab switches GRUB to a serial-capable console setup so the menu is visible from `virsh console`.

!!! note
    This section builds on the menu settings from `4.2.1`. Here you only add the serial-console-specific GRUB settings needed for `virsh console`.

Step 1: Edit `/etc/default/grub` and add the serial console settings on `LABVM`.

```bash
# Edit the GRUB defaults file and add the serial-console settings for virsh console access.
sudo vim /etc/default/grub
```
??? example "Expected result"
    ```text
    "/etc/default/grub" ...
    ```

Add or update these lines while editing:

```ini
GRUB_CMDLINE_LINUX="console=tty0 console=ttyS0,115200n8 rootdelay=60"
GRUB_TERMINAL="console serial"
GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"
```

Step 2: Confirm the file contents.

```bash
# Show only the serial-console-related GRUB settings.
grep -E '^(GRUB_CMDLINE_LINUX|GRUB_TERMINAL|GRUB_SERIAL_COMMAND)=' /etc/default/grub
```
??? example "Expected result"
    ```text
    GRUB_CMDLINE_LINUX="console=tty0 console=ttyS0,115200n8 rootdelay=60"
    GRUB_TERMINAL="console serial"
    GRUB_SERIAL_COMMAND="serial --unit=0 --speed=115200 --word=8 --parity=no --stop=1"
    ```

Step 3: Regenerate the GRUB configuration.

```bash
# Rebuild the generated GRUB configuration after editing defaults.
sudo update-grub
```
??? example "Expected result"
    ```text
    Sourcing file `/etc/default/grub'
    Generating grub configuration file ...
    Found linux image: /boot/vmlinuz-6.8.0-107-generic
    Found initrd image: /boot/initrd.img-6.8.0-107-generic
    Found linux image: /boot/vmlinuz-6.8.0-106-generic
    Found initrd image: /boot/initrd.img-6.8.0-106-generic
    Warning: os-prober will not be executed to detect other bootable partitions.
    Systems on them will not be added to the GRUB boot configuration.
    Check GRUB_DISABLE_OS_PROBER documentation entry.
    Adding boot menu entry for UEFI Firmware Settings ...
    done
    ```

Step 4: Exit `LABVM` and return to `LABHOST`.

```bash
# Exit the LABVM shell.
exit
```
??? example "Expected result"
    ```text
    logout
    Connection to 192.168.101.50 closed.
    ```

Step 5: Open the libvirt console from `LABHOST`.

```bash
# Attach to the LABVM serial console from the host.
virsh console ubuntu
```
??? example "Expected result"
    ```text
    Connected to domain 'ubuntu'
    Escape character is ^]

    ubuntu login:
    ```

Log in on the console as `ubuntu` before running the reboot command in the next step.

Step 6: Reboot from the console and watch for the GRUB menu.

```bash
# Reboot LABVM from the serial console.
sudo reboot
```
??? example "Expected result"
    ```text
    Broadcast message from root@ubuntu on pts/0 (...)

    The system will reboot now!
    ```

!!! note
    If the console shows `Press any key to continue...`, press `Enter`.

!!! success
    Success means:

    - the GRUB menu was visible during boot
    - the serial console showed the login prompt after reboot

!!! pied-piper "Takeaway"
    If the GRUB menu is not visible in `virsh console`:

    - add serial console settings in `/etc/default/grub`
    - run `sudo update-grub`
    - reboot and reconnect through the libvirt console

### :material-application-edit-outline: 4.2.3 Using HWE Kernels To Test Alternate Versions

Ubuntu LTS releases provide two supported kernel tracks:

- General Availability (GA): the default kernel series that ships with the LTS release
- Hardware Enablement (HWE): a newer supported kernel series backported from a more recent Ubuntu release

This lab installs the HWE kernel so you can compare multiple supported kernels from the GRUB menu.

!!! note
    This is the supported way to test newer Ubuntu kernel versions on an LTS release. It is different from using unsupported kernels from the Ubuntu Mainline PPA.

!!! info
    The installed HWE kernel still uses the `-generic` suffix in `uname -r` and package names such as `linux-image-6.17.0-20-generic`. In this context, `hwe` refers to the Ubuntu kernel track selected by packages such as `linux-generic-hwe-24.04`, while `generic` is the kernel flavor.

Step 1: Check the currently running kernel on `LABVM`.

```bash
# Show the currently running kernel version.
uname -r
```
??? example "Expected result"
    ```text
    6.8.0-107-generic
    ```

Step 2: Refresh package metadata.

```bash
# Refresh the APT package index before installing the HWE kernel.
sudo apt update
```
??? example "Expected result"
    ```text
    WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

    Hit:1 http://security.ubuntu.com/ubuntu noble-security InRelease
    Hit:2 http://archive.ubuntu.com/ubuntu noble InRelease
    Hit:3 http://archive.ubuntu.com/ubuntu noble-updates InRelease
    Hit:4 http://archive.ubuntu.com/ubuntu noble-backports InRelease
    ...
    Reading package lists...
    Building dependency tree...
    Reading state information...
    17 packages can be upgraded.
    ```

Step 3: Install the HWE kernel meta-package.

```bash
# Install the Ubuntu 24.04 HWE kernel stack.
sudo apt install -y --install-recommends linux-generic-hwe-24.04
```
??? example "Expected result"
    ```text
    WARNING: apt does not have a stable CLI interface. Use with caution in scripts.

    Reading package lists... Done
    Building dependency tree... Done
    Reading state information...
    The following NEW packages will be installed:
      linux-generic-hwe-24.04
      linux-image-6.17.0-20-generic
      linux-image-generic-hwe-24.04
      ...
    ...
    Need to get 861 MB of archives.
    After this operation, 1000 MB of additional disk space will be used.
     Setting up linux-image-6.17.0-20-generic ...
     Setting up linux-generic-hwe-24.04 ...
     Pending kernel upgrade
     ```

!!! note
    In this step, `linux-generic-hwe-24.04` is the HWE meta-package. It pulls in the actual bootable kernel image, which in this example is `linux-image-6.17.0-20-generic`.

    For the rest of this lab, the kernel you are looking for in GRUB and in `uname -r` is `6.17.0-20-generic`.

!!! note
    This package install can take a while and may download several hundred megabytes. The important success signals are that the `linux-generic-hwe-24.04` meta-package installs and a new `linux-image-...-generic` package appears in the output.

Step 4: Check the installed HWE meta-packages.

```bash
# Show whether the Ubuntu 24.04 HWE meta-packages are installed and which version they select.
apt-cache policy linux-generic-hwe-24.04 linux-image-generic-hwe-24.04
```
??? example "Expected result"
    ```text
    linux-generic-hwe-24.04:
      Installed: 6.17.0-20.20~24.04.1
      Candidate: 6.17.0-20.20~24.04.1
      Version table:
     *** 6.17.0-20.20~24.04.1 500
            500 http://archive.ubuntu.com/ubuntu noble-updates/main amd64 Packages
            500 http://security.ubuntu.com/ubuntu noble-security/main amd64 Packages
            100 /var/lib/dpkg/status
         6.8.0-31.31 500
            500 http://archive.ubuntu.com/ubuntu noble/main amd64 Packages
    linux-image-generic-hwe-24.04:
      Installed: 6.17.0-20.20~24.04.1
      Candidate: 6.17.0-20.20~24.04.1
      Version table:
     *** 6.17.0-20.20~24.04.1 500
            500 http://archive.ubuntu.com/ubuntu noble-updates/main amd64 Packages
            500 http://security.ubuntu.com/ubuntu noble-security/main amd64 Packages
            100 /var/lib/dpkg/status
         6.8.0-31.31 500
            500 http://archive.ubuntu.com/ubuntu noble/main amd64 Packages
    ```

!!! note
    Read this output as follows:

    - `Installed:` shows the HWE meta-package version currently installed on the system
    - `Candidate:` shows the version APT would install if you ran the command again now
    - when `Installed:` and `Candidate:` match, the system is already on the current HWE track offered by your repositories
    - the older `6.8.0-31.31` entry shown from `noble/main` is the original GA track package, not the HWE kernel you are installing here

Step 5: List installed kernel image packages.

```bash
# List installed linux-image packages.
dpkg --list | grep linux-image
```
??? example "Expected result"
    ```text
    ii  linux-image-6.17.0-20-generic         ...
    ii  linux-image-6.8.0-106-generic         ...
    ii  linux-image-6.8.0-107-generic         ...
    ii  linux-image-generic-hwe-24.04         ...
    ii  linux-image-virtual                   ...
    ```

Step 6: Check the GRUB menu entries again.

```bash
# List the current GRUB menu entries after installing another kernel.
sudo awk -F\' '$1=="menuentry " {print i++ " : " $2}' /boot/grub/grub.cfg
```
??? example "Expected result"
    ```text
    0 : Ubuntu
    ```

!!! note
    Additional kernels are usually grouped under `Advanced options for Ubuntu`, so the top-level menu may still show only `0 : Ubuntu` even after the HWE kernel is installed.

Step 7: Edit GRUB so the menu remains visible long enough for selection.

```bash
# Edit the GRUB defaults file with the default Ubuntu editor.
sudo nano /etc/default/grub
```
??? example "Expected result"
    ```text
    GNU nano ... /etc/default/grub
    ```

Use these settings if they are not already present:

```ini
GRUB_DEFAULT="saved"
GRUB_SAVEDEFAULT="true"
GRUB_TIMEOUT=10
GRUB_TIMEOUT_STYLE="menu"
```

Step 8: Regenerate the GRUB configuration if you changed the file.

```bash
# Rebuild the GRUB menu after adjusting the timeout settings.
sudo update-grub
```
??? example "Expected result"
    ```text
    Sourcing file `/etc/default/grub'
    Generating grub configuration file ...
    Found linux image: /boot/vmlinuz-6.17.0-20-generic
    Found initrd image: /boot/initrd.img-6.17.0-20-generic
    Found linux image: /boot/vmlinuz-6.8.0-107-generic
    Found initrd image: /boot/initrd.img-6.8.0-107-generic
    Found linux image: /boot/vmlinuz-6.8.0-106-generic
    Found initrd image: /boot/initrd.img-6.8.0-106-generic
    Warning: os-prober will not be executed to detect other bootable partitions.
    Systems on them will not be added to the GRUB boot configuration.
    Check GRUB_DISABLE_OS_PROBER documentation entry.
    Adding boot menu entry for UEFI Firmware Settings ...
    done
    ```

Step 9: Reboot and select a kernel from the GRUB menu.

```bash
# Reboot LABVM to choose a different kernel from GRUB.
sudo reboot
```
??? example "Expected result"
    ```text
    The system will reboot now!
    ```

After the SSH session closes, you are back on `LABHOST`. Use the libvirt console in the next step so you can watch the GRUB menu and choose the HWE kernel.

Step 10: Reattach from `LABHOST` using the libvirt console.

```bash
# Reconnect to the LABVM serial console.
virsh console ubuntu
```
??? example "Expected result"
    ```text
    Connected to domain 'ubuntu'
    Escape character is ^]

    ubuntu login:
    ```

Reconnect as soon as the SSH session closes. If the system has already booted past the GRUB menu by the time you attach, reboot once from the console and watch the next boot.

When the system finishes booting, log in on the console as `ubuntu` so you can run the next command.

Step 11: Confirm which kernel is running after boot.

```bash
# Verify the active kernel after the reboot.
uname -r
```
??? example "Expected result"
    ```text
    6.17.0-20-generic
    ```

!!! success
    You should now be running the HWE kernel.

    A good confirmation is:

    - the system boots normally after you select `6.17.0-20-generic` in GRUB
    - `uname -r` shows `6.17.0-20-generic`

Step 12: Reboot again if you want to observe the menu or switch back.

```bash
# Reboot once more from the console.
sudo reboot
```
??? example "Expected result"
    ```text
    The system will reboot now!
    ```

!!! note
    Use `Ctrl + ]` to leave the `virsh console` session.

For background on supported Ubuntu kernel tracks, see the [Ubuntu Kernel Lifecycle](https://ubuntu.com/kernel/lifecycle).

!!! pied-piper "Takeaway"
    For Ubuntu kernel tracks, remember:

    - GA is the default LTS kernel track
    - HWE is a newer supported kernel track for the same LTS release
    - installing the HWE meta-package gives you another supported kernel to test from GRUB

## :material-book-open-page-variant-outline: 4.3 Advanced systemd Usage

`systemd` is Ubuntu's init system and service manager. It is the first userspace process started by the kernel, and it is responsible for bringing the system up to its normal running state.

This chapter focuses on four common `systemd` tasks:

- start and stop services
- enable services at boot
- inspect unit configuration
- review logs and boot timing

Most of the things `systemd` manages are called units. A service is one kind of unit, but mounts, timers, sockets, and targets are units too.

Packaged unit files are usually stored under `/lib/systemd/system/`. Local overrides and custom units belong under `/etc/systemd/system/`.

When you need to change the behavior of a packaged service, prefer an override rather than editing the vendor unit directly. The `systemctl edit libvirtd.service` workflow creates or opens a drop-in file under `/etc/systemd/system/libvirtd.service.d/`.

Use `systemctl cat` to see the full merged unit definition, including vendor content and local overrides.

```bash
# Display the full merged unit definition, including drop-ins.
systemctl cat libvirtd.service
```
??? quote "Reference output"
    ```text
    # /usr/lib/systemd/system/libvirtd.service
    [Unit]
    Description=libvirt legacy monolithic daemon
    ...
    ```

### :material-application-edit-outline: 4.3.1 Systemd Units

Think of a unit as a small configuration file that tells `systemd` what to manage and how to manage it.

The unit suffix tells you what kind of object it is.

Common unit types include:

- `*.service`: system services
- `*.socket`: socket-activated services
- `*.mount`: filesystem mount points
- `*.timer`: scheduled tasks
- `*.target`: groups of related units and boot states

Most examples here use `*.service` units, but the same basic ideas apply to the others.

Example unit file:

```ini
[Unit]
Description=Unit that runs the foo daemon
Documentation=man:foo(1)
Wants=network-online.target
After=network-online.target

[Service]
Type=forking
Environment=statedir=/var/cache/foo
ExecStartPre=/usr/bin/mkdir -p ${statedir}
ExecStart=/usr/bin/foo-daemon --arg1 "hello world" --statedir ${statedir}

[Install]
WantedBy=multi-user.target
```

Interpretation:

- `[Unit]` says: "When started, this service depends on `network-online.target` and should start after it." 
- `[Service]` says: "Start `foo-daemon`, create `/var/cache/foo` first, and pass that path in as `${statedir}`." 
- `[Install]` says: "If enabled, hook this service into `multi-user.target` so it starts during normal boot." 

`ExecStartPre=` runs before the main service process and is commonly used for setup tasks.

Units can depend on other units. Use `systemctl list-dependencies` to see that relationship tree.

```bash
# Show the dependency tree for a unit.
systemctl list-dependencies libvirtd.service
```
??? quote "Reference output"
    ```text
    libvirtd.service
    ● ├─libvirtd-admin.socket
    ● ├─libvirtd-ro.socket
    ● ├─libvirtd.socket
    ● ├─system.slice
    ● ├─systemd-machined.service
    ● ├─virtlockd.socket
    ● ├─virtlogd.socket
    ● └─sysinit.target
    ...
    ```

`Requires=` means the dependency must be present for the unit to start. `Wants=` means the dependency is desirable but not strictly required.

```bash
# Show the units that depend on a given unit.
systemctl list-dependencies --reverse libvirtd.service
```
??? quote "Reference output"
    ```text
    libvirtd.service
    ● └─multi-user.target
    ●   └─graphical.target
    ```

Meaning:

- if the system boots to `graphical.target`, it also reaches `multi-user.target`
- as part of that target, `libvirtd.service` is included

### :material-application-edit-outline: 4.3.2 Managing Units With systemctl

`systemctl` is the main command used to work with units.

The easiest way to think about these commands is:

- `start`, `stop`, `restart`, and `reload` affect the current running system
- `enable` and `disable` affect what happens at boot
- `status` and `is-enabled` help you inspect the current state

| Command | Description |
| --- | --- |
| `sudo systemctl start <unit>` | Start a unit immediately |
| `sudo systemctl stop <unit>` | Stop a running unit |
| `sudo systemctl restart <unit>` | Restart a unit, or start it if it is stopped |
| `sudo systemctl reload <unit>` | Reload the unit configuration without a full restart, if supported |
| `sudo systemctl enable <unit>` | Start the unit automatically at boot |
| `sudo systemctl disable <unit>` | Prevent the unit from starting automatically at boot |
| `sudo systemctl status <unit>` | Show current state, recent logs, and process details |
| `sudo systemctl is-enabled <unit>` | Check whether the unit is enabled at boot |

`sudo systemctl enable --now myservice.service` is a useful shortcut because it enables the unit for future boots and starts it immediately.

!!! pied-piper "Takeaway"
    The easiest `systemctl` split is:

    - `start`, `stop`, `restart`, and `reload` affect the running system now
    - `enable` and `disable` affect boot behavior
    - `status`, `show`, and `cat` help you inspect what systemd is doing

### :material-application-edit-outline: 4.3.3 Logging

`systemd-journald` collects logs from services, the kernel, and other system components.

Unlike plain text logs under `/var/log`, the journal can be filtered by unit, time range, severity, and boot session.

By default, the journal may only persist logs for the current boot if it is using `/run/log/journal/`. To keep logs across reboots, create `/var/log/journal/`.

`journalctl` is the main command used to query journal data. The lab in `4.4.2` covers the most useful filters.

### :material-application-edit-outline: 4.3.4 Troubleshooting systemd

Use `systemd-analyze` when you need to inspect boot timing or identify slow-starting services.

This is most useful when a system feels slow during startup and you want to see which units took the most time.

```bash
# Show services ordered by the time they spent starting.
systemd-analyze blame
```
??? quote "Reference output"
    ```text
    30.218s apt-daily-upgrade.service
     9.941s snapd.service
     1.056s systemd-networkd-wait-online.service
     ...
      30ms libvirtd.service
    ```

The output is a good hint, but it is not always the full root cause. A slow unit may simply be waiting for another dependency.

```bash
# Generate an SVG boot timeline in the current directory.
systemd-analyze plot > plot.svg
```
??? quote "Reference output"
    ```text
    No terminal output. A file named plot.svg is created in the current directory.
    ```

Open `plot.svg` in a browser if you want a visual timeline of the boot sequence. If you run the command from your home directory on `LABHOST`, the file will usually be created as `~/plot.svg`.

To make the journal persistent across reboots, create `/var/log/journal/` and then ask `journald` to reopen its files.

## :material-book-open-page-variant-outline: 4.4 systemd Lab

!!! info
    Run this lab on `LABHOST` unless a step explicitly says to switch to `LABVM`.

### :material-application-edit-outline: 4.4.1 Manage Services

!!! info
    This exercise reviews the core `systemctl` inspection and service-management commands. Success means you can recognize the difference between loaded, running, and failed units, and you can stop and start `libvirtd.service` without losing track of its socket-activated behavior.

Step 1: List units of type `service`.

```bash
# List all loaded service units.
systemctl list-units --type=service
```
??? example "Expected result"
    ```text
    UNIT                                     LOAD   ACTIVE SUB     DESCRIPTION
    apache2.service                          loaded active running The Apache HTTP Server
    cron.service                             loaded active running Regular background program processing daemon
    libvirtd.service                         loaded active running libvirt legacy monolithic daemon
    ssh.service                              loaded active running OpenBSD Secure Shell server
    ...
    63 loaded units listed.
    ```

Step 2: Show only running services.

```bash
# List only service units that are currently running.
systemctl list-units --type=service --state=running
```
??? example "Expected result"
    ```text
    UNIT                        LOAD   ACTIVE SUB     DESCRIPTION
    dbus.service                loaded active running D-Bus System Message Bus
    libvirtd.service            loaded active running libvirt legacy monolithic daemon
    ssh.service                 loaded active running OpenBSD Secure Shell server
    ...
    25 loaded units listed.
    ```

Step 3: Search for services related to SSH.

```bash
# Search the unit list for SSH-related entries.
systemctl -a | grep ssh
```
??? example "Expected result"
    ```text
    ssh.service           loaded    active   running   OpenBSD Secure Shell server
    sshd-keygen.service   not-found inactive dead      sshd-keygen.service
    sshd.service          not-found inactive dead      sshd.service
    ssh.socket            loaded    active   running   OpenBSD Secure Shell server socket
    ```

Step 4: Stop `libvirtd.service`.

```bash
# Stop the libvirt daemon.
sudo systemctl stop libvirtd.service
```
??? example "Expected result"
    ```text
    Stopping 'libvirtd.service', but its triggering units are still active:
    libvirtd.socket, libvirtd-ro.socket, libvirtd-admin.socket
    ```

!!! warning
    Stopping `libvirtd.service` can disconnect `LABVM` from the host-side management workflow.

!!! note
    On this host, `libvirtd` is socket-activated. Stopping `libvirtd.service` does not stop its sockets, so the service can be started again automatically if one of those sockets is used.

Step 5: Check the unit state after stopping it.

```bash
# Show the current status of the libvirt daemon.
sudo systemctl status libvirtd.service
```
??? example "Expected result"
    ```text
    ○ libvirtd.service - libvirt legacy monolithic daemon
         Loaded: loaded (/usr/lib/systemd/system/libvirtd.service; enabled; preset: enabled)
         Active: inactive (dead)
    TriggeredBy: ● libvirtd.socket
                 ● libvirtd-ro.socket
                 ● libvirtd-admin.socket
    ```

Step 6: Start `libvirtd.service` again.

```bash
# Start the libvirt daemon.
sudo systemctl start libvirtd.service
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 7: Confirm it is running.

```bash
# Show the current status after restarting libvirtd.
sudo systemctl status libvirtd.service
```
??? example "Expected result"
    ```text
    ● libvirtd.service - libvirt legacy monolithic daemon
         Loaded: loaded (/usr/lib/systemd/system/libvirtd.service; enabled; preset: enabled)
         Active: active (running)
    TriggeredBy: ● libvirtd.socket
                 ● libvirtd-ro.socket
                 ● libvirtd-admin.socket
    ```

Step 8: Inspect the unit definition.

```bash
# Display the libvirtd unit definition and any drop-ins.
systemctl cat libvirtd.service
```
??? example "Expected result"
    ```text
    # /usr/lib/systemd/system/libvirtd.service
    [Unit]
    Description=libvirt legacy monolithic daemon
    ...
    ```

Step 9: List the unit dependencies.

```bash
# Show the dependency tree for libvirtd.
systemctl list-dependencies libvirtd.service
```
??? example "Expected result"
    ```text
    libvirtd.service
    ● ├─libvirtd-admin.socket
    ● ├─libvirtd-ro.socket
    ● ├─libvirtd.socket
    ● ├─system.slice
    ...
    ```

Step 10: Show the low-level unit properties.

```bash
# Display detailed key-value properties for libvirtd.
systemctl show libvirtd.service
```
??? example "Expected result"
    ```text
    Type=notify
    Id=libvirtd.service
    Names=libvirtd.service
    ActiveState=active
    SubState=running
    UnitFileState=enabled
    ...
    ```

Step 11: Show failed units.

```bash
# List units that are currently in a failed state.
systemctl --failed
```
??? example "Expected result"
    ```text
    UNIT                               LOAD   ACTIVE SUB    DESCRIPTION
    ● lxd-installer@0-30818-1000.service loaded failed failed Helper to install lxd snap on demand
    ...
    1 loaded units listed.
    ```

Step 12: Show which services took the most time during boot.

```bash
# Show boot-time service startup delays.
systemd-analyze blame
```
??? example "Expected result"
    ```text
    30.218s apt-daily-upgrade.service
     9.941s snapd.service
     1.056s systemd-networkd-wait-online.service
     ...
      39ms libvirtd.service
    ```

### :material-application-edit-outline: 4.4.2 Logging

`journald` collects system logs. These steps review common `journalctl` queries.

!!! info
    This exercise shows the most useful `journalctl` filters for day-to-day troubleshooting. Success means you can view logs by boot, by kernel messages, and by individual service unit.

Step 1: Show all available journal entries.

```bash
# Display the full journal.
sudo journalctl
```
??? example "Expected result"
    ```text
    Apr 09 11:55:20 ubuntu kernel: Linux version 6.8.0-107-generic ...
    Apr 09 11:55:20 ubuntu kernel: Command line: BOOT_IMAGE=/boot/vmlinuz-6.8.0-107-generic ...
    ...
    ```

Step 2: Show logs from the current boot only.

```bash
# Display journal entries from the current boot.
sudo journalctl -b
```
??? example "Expected result"
    ```text
    Apr 09 12:15:11 playground-rdu kernel: Linux version 6.8.0-107-generic ...
    Apr 09 12:15:11 playground-rdu kernel: Command line: BOOT_IMAGE=/boot/vmlinuz-6.8.0-107-generic ...
    ...
    ```

Step 3: Show logs from the previous boot.

```bash
# Display journal entries from the previous boot.
journalctl -b -1
```
??? example "Expected result"
    ```text
    Apr 09 11:55:20 ubuntu kernel: Linux version 6.8.0-107-generic ...
    Apr 09 11:55:20 ubuntu kernel: Command line: BOOT_IMAGE=/boot/vmlinuz-6.8.0-107-generic ...
    ...
    ```

Step 4: Show logs from two boots ago.

```bash
# Display journal entries from two boots ago.
journalctl -b -2
```
??? example "Expected result"
    ```text
    No journal boot entry found from the specified boot offset (-2).
    ```

Step 5: List the recorded boots.

```bash
# List the boots stored in the journal.
journalctl --list-boots
```
??? example "Expected result"
    ```text
    IDX BOOT ID                          FIRST ENTRY                 LAST ENTRY
     -1 17dac92429a141038bf502503f40dcf6 Thu 2026-04-09 11:55:20 UTC Thu 2026-04-09 12:14:57 UTC
      0 886745b284a54c6b863d34a4489256aa Thu 2026-04-09 12:15:11 UTC Fri 2026-04-10 18:06:18 UTC
    ```

!!! note
    The number of retained boots depends on how much journal history is available on your system. It is normal to see only the current boot (`0`) and one previous boot (`-1`) in a small lab environment.

Step 6: Show kernel messages from the current boot.

```bash
# Display kernel log messages from the current boot.
sudo journalctl -k
```
??? example "Expected result"
    ```text
    Apr 09 12:15:11 playground-rdu kernel: Linux version 6.8.0-107-generic ...
    Apr 09 12:15:11 playground-rdu kernel: Command line: BOOT_IMAGE=/boot/vmlinuz-6.8.0-107-generic ...
    ...
    ```

Step 7: Show kernel messages from two boots ago.

```bash
# Display kernel log messages from two boots ago.
sudo journalctl -k -b -2
```
??? example "Expected result"
    ```text
    No journal boot entry found from the specified boot offset (-2).
    ```

Step 8: Search for denied AppArmor events.

```bash
# Filter kernel logs for AppArmor denials.
sudo journalctl -k -b | grep 'apparmor="DENIED"'
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 9: Show logs for the SSH service.

```bash
# Display journal entries for ssh.service.
sudo journalctl -u ssh.service
```
??? example "Expected result"
    ```text
    Apr 09 12:15:15 playground-rdu systemd[1]: Started ssh.service - OpenBSD Secure Shell server.
    Apr 09 12:15:15 playground-rdu sshd[834]: Server listening on 0.0.0.0 port 22.
    Apr 09 12:15:15 playground-rdu sshd[841]: Accepted publickey for ubuntu from 10.10.0.13 ...
    ...
    ```

Step 10: Show logs for the libvirt service.

```bash
# Display journal entries for libvirtd.service.
sudo journalctl -u libvirtd.service
```
??? example "Expected result"
    ```text
    Apr 10 18:00:05 playground-rdu systemd[1]: Starting libvirtd.service - libvirt legacy monolithic daemon...
    Apr 10 18:00:05 playground-rdu systemd[1]: Started libvirtd.service - libvirt legacy monolithic daemon.
    Apr 10 18:00:06 playground-rdu dnsmasq[11358]: read /etc/hosts - 8 names
    ...
    ```

Step 11: Create the persistent journal directory (optional, if persistence is not enabled).

```bash
# Create the directory used for persistent journal storage.
sudo mkdir -p /var/log/journal
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 12: Restart `systemd-journald` so it uses persistent storage (optional, if persistence is not enabled).

```bash
# Restart journald after enabling persistent log storage.
sudo systemctl restart systemd-journald
```
??? example "Expected result"
    ```text
    No output.
    ```

!!! note
    Full system logs often require `sudo`. Unprivileged users usually only see their own session logs unless they are members of the `systemd-journal` group.

!!! pied-piper "Takeaway"
    The most useful `journalctl` filters are:

    - `-b` for a specific boot
    - `-k` for kernel messages
    - `-u <unit>` for one service
    - `--list-boots` to see which boot histories are available

### :material-application-edit-outline: 4.4.3 Create A Custom Service

This lab creates and manages a simple custom service on `LABVM`.

!!! info
    This exercise builds a simple custom service from a shell script and manages it with `systemctl`. Success means `myservice.service` starts, shows `active (running)` in `systemctl status`, and writes its log messages to the journal.

Step 1: Connect to `LABVM` if you are not already there.

```bash
# Connect to LABVM as the ubuntu user over SSH.
ssh ubuntu@192.168.101.50
```
??? example "Expected result"
    ```text
    ubuntu@192.168.101.50's password:
    Welcome to Ubuntu 24.04 LTS (GNU/Linux ...)
    ubuntu@ubuntu:~$
    ```

!!! note
    Use the explicit `ubuntu@192.168.101.50` form here so you connect as `ubuntu`.

Step 2: Create the service script file.

```bash
# Create the script file used by the custom service.
touch ~/service.sh
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 3: Write the service script contents.

```bash
# Write the service script that logs a start message and loops.
sudo tee ~/service.sh <<'EOF'
#!/bin/bash

DATE=$(date '+%Y-%m-%d %H:%M:%S')
echo "Service started at ${DATE}"

while :
do
  echo "Service is running..."
  sleep 30
done
EOF
```
??? example "Expected result"
    ```text
    #!/bin/bash

    DATE=$(date '+%Y-%m-%d %H:%M:%S')
    echo "Service started at ${DATE}"
    ...
    ```

Step 4: Make the script executable.

```bash
# Mark the service script as executable.
sudo chmod +x ~/service.sh
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 5: Create the unit file.

```bash
# Create the custom myservice unit definition.
sudo tee /etc/systemd/system/myservice.service <<'EOF'
[Unit]
Description=This is an example of a simple systemd service.

[Service]
Type=simple
ExecStart=/bin/bash /home/ubuntu/service.sh

[Install]
WantedBy=multi-user.target
EOF
```
??? example "Expected result"
    ```text
    [Unit]
    Description=This is an example of a simple systemd service.
    ...
    ```

Step 6: Apply standard permissions to the unit file.

```bash
# Set the unit file mode.
sudo chmod 644 /etc/systemd/system/myservice.service
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 7: Reload systemd so it notices the new unit.

```bash
# Reload systemd after creating the custom unit file.
sudo systemctl daemon-reload
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 8: Start the custom service.

```bash
# Start the custom service immediately.
sudo systemctl start myservice.service
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 9: Enable the service for future boots.

```bash
# Enable the custom service at boot.
sudo systemctl enable myservice.service
```
??? example "Expected result"
    ```text
    Created symlink /etc/systemd/system/multi-user.target.wants/myservice.service -> /etc/systemd/system/myservice.service.
    ```

Step 10: Review the service status.

```bash
# Show the service status and recent log lines.
sudo systemctl status myservice.service
```
??? example "Expected result"
    ```text
    ● myservice.service - This is an example of a simple systemd service.
         Loaded: loaded (/etc/systemd/system/myservice.service; enabled; preset: enabled)
         Active: active (running)
        Main PID: ... (bash)
             ...
    Apr 10 18:14:07 ubuntu bash[1908]: Service started at 2026-04-10 18:14:07
    Apr 10 18:14:07 ubuntu bash[1908]: Service is running...
    ```

Step 11: Review the service logs.

```bash
# Show journal entries for the custom service.
sudo journalctl -u myservice.service
```
??? example "Expected result"
    ```text
    Apr 10 18:14:07 ubuntu systemd[1]: Started myservice.service - This is an example of a simple systemd service..
    Apr 10 18:14:07 ubuntu bash[1908]: Service started at 2026-04-10 18:14:07
    Apr 10 18:14:07 ubuntu bash[1908]: Service is running...
    Apr 10 18:14:37 ubuntu bash[1908]: Service is running...
    ```

Step 12: Stop the service.

```bash
# Stop the custom service.
sudo systemctl stop myservice.service
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 13: Disable the service.

```bash
# Disable the custom service so it no longer starts at boot.
sudo systemctl disable myservice.service
```
??? example "Expected result"
    ```text
    Removed "/etc/systemd/system/multi-user.target.wants/myservice.service".
    ```

!!! note
    Create custom unit files under `/etc/systemd/system/`. Package-managed unit files under `/lib/systemd/system/` can be replaced by package updates.

!!! pied-piper "Takeaway"
    The custom service workflow is:

    - write the script you want to run
    - create a unit file in `/etc/systemd/system/`
    - start it with `systemctl start`
    - enable it with `systemctl enable` if it should survive reboot

## :material-book-open-page-variant-outline: 4.5 On Demand Processes

Ubuntu provides two common ways to schedule work:

- `systemd` timers: the modern and preferred method
- `at` and `batch`: older tools that are still available

For most administrative tasks on modern Ubuntu systems, prefer `systemd` timers. They support both recurring schedules and one-time execution, and they integrate cleanly with service units and the journal.

A timer does not usually run the command by itself. Instead, it triggers a matching service unit.

- the timer answers: when should this run?
- the service answers: what should run?

Typical uses include:

- running jobs on a schedule
- delaying work until after boot
- reacting to file creation or other events

Example timer unit:

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

Matching service unit:

`/etc/systemd/system/foo.service`

```ini
[Unit]
Description=Job that does something

[Service]
ExecStart=/usr/local/bin/foo-script.sh
```

In this example:

- `foo.timer` says to run weekly
- `foo.service` says which command should be executed

`systemd` can also trigger work from events such as file creation, network availability, device presence, or user login.

The hands-on timer examples are in `4.6`.

Legacy scheduling tools are still available when needed:

- `at`: run a one-time job at a specific time
- `batch`: run a job when system load is low enough
- `atq`: list queued jobs
- `atrm`: remove queued jobs

Use these mainly when you need a quick one-off scheduled job and do not need a full `systemd` unit.

!!! pied-piper "Takeaway"
    Keep the split simple:

    - a timer answers when something should run
    - a service answers what should run
    - `at` and `batch` are older tools for quick one-off jobs

## :material-book-open-page-variant-outline: 4.6 On Demand And Scheduled Tasks Lab

!!! info
    Run Part 1 on `LABHOST`. Run Part 2 on `LABVM`.

### :material-application-edit-outline: Part 1: systemd Timers (Preferred Method)

!!! info
    This exercise shows three ways `systemd` can trigger work: existing timers, transient timers from `systemd-run`, and path-triggered services. Success means you can list active timers, create a marker file with a transient timer, and trigger `mywatch.service` by creating `/tmp/watchme`.

Step 1: List the currently scheduled timers.

```bash
# List all timers currently known to systemd.
systemctl list-timers
```
??? example "Expected result"
    ```text
    NEXT                            LEFT LAST                              PASSED UNIT                           ACTIVATES
    Fri 2026-04-10 18:30:00 UTC     6min Fri 2026-04-10 18:20:11 UTC 2min 49s ago sysstat-collect.timer          sysstat-collect.service
    Fri 2026-04-10 18:45:01 UTC    22min Fri 2026-04-10 17:22:06 UTC            - fwupd-refresh.timer            fwupd-refresh.service
    ...
    apt-daily-upgrade.timer        ...     ...     ...        apt-daily-upgrade.service
    14 timers listed.
    ```

Step 2: Schedule a one-time transient job with `systemd-run`.

```bash
# Schedule a one-time command that creates a marker file.
sudo systemd-run --on-active=1 /bin/touch /tmp/has_ran_from_systemd
```
??? example "Expected result"
    ```text
    Running timer as unit: run-rf81f619e49514311954073645a8ad902.timer
    Will run service as unit: run-rf81f619e49514311954073645a8ad902.service
    ```

Wait a moment before the next step so the transient timer has time to run.

```bash
# Confirm that the transient timer created the marker file.
ls -l /tmp/has_ran_from_systemd
```
??? example "Expected result"
    ```text
    -rw-r--r-- 1 root root 0 Apr 10 18:20 /tmp/has_ran_from_systemd
    ```

The earlier example in `4.5` can also be used here to create a recurring `foo.timer` and matching `foo.service`.

Step 3: Create the path unit that watches for `/tmp/watchme`.

```bash
# Create a path unit that triggers when /tmp/watchme exists.
sudo tee /etc/systemd/system/mywatch.path <<'EOF'
[Unit]
Description=Watch for file creation in /tmp/watchme

[Path]
PathExists=/tmp/watchme
Unit=mywatch.service

[Install]
WantedBy=multi-user.target
EOF
```
??? example "Expected result"
    ```text
    [Unit]
    Description=Watch for file creation in /tmp/watchme
    ...
    ```

Step 4: Create the service that runs when the file appears.

```bash
# Create the service triggered by the watched path.
sudo tee /etc/systemd/system/mywatch.service <<'EOF'
[Unit]
Description=Triggered when /tmp/watchme is created

[Service]
Type=oneshot
ExecStart=/bin/sh -c 'echo "The file appeared!" > /tmp/watched.log'
EOF
```
??? example "Expected result"
    ```text
    [Unit]
    Description=Triggered when /tmp/watchme is created
    ...
    ```

Step 5: Reload systemd so it notices the new path and service units.

```bash
# Reload systemd after creating the path and service units.
sudo systemctl daemon-reload
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 6: Enable and start the path-based trigger.

```bash
# Enable and start the path unit.
sudo systemctl enable --now mywatch.path
```
??? example "Expected result"
    ```text
    Created symlink /etc/systemd/system/multi-user.target.wants/mywatch.path -> /etc/systemd/system/mywatch.path.
    ```

!!! note
    After the path unit is active, creating `/tmp/watchme` should trigger `mywatch.service` and write to `/tmp/watched.log`.

Step 7: Create the watched file.

```bash
# Create the watched file to trigger the path unit.
touch /tmp/watchme
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 8: Verify that the path-triggered service ran.

```bash
# Verify that the path-triggered service ran.
cat /tmp/watched.log
```
??? example "Expected result"
    ```text
    The file appeared!
    ```

### :material-application-edit-outline: Part 2: Legacy Tools - at And batch

Before starting Part 2, switch from `LABHOST` to `LABVM`.

!!! info
    This exercise demonstrates the legacy one-time scheduling tools. Success means `at` creates marker files at the requested time, `at -f` runs the saved script, and `batch` queues a job that runs when system load is low enough.

```bash
# Connect to LABVM for the legacy scheduling steps.
ssh ubuntu@192.168.101.50
```
??? example "Expected result"
    ```text
    ubuntu@192.168.101.50's password:
    Welcome to Ubuntu 24.04 LTS (GNU/Linux ...)
    ubuntu@ubuntu:~$
    ```

Step 1: Install the `at` package.

```bash
# Install the at daemon and client tools.
sudo apt install -y at
```
??? example "Expected result"
    ```text
    Reading package lists... Done
    Building dependency tree... Done
    The following NEW packages will be installed:
      at
    ...
    Setting up at ...
    ```

Step 2: Open an interactive `at` session for a near-term one-time job.

```bash
# Open an interactive at prompt for two minutes from now.
at now+2minutes
```
??? example "Expected result"
    ```text
    warning: commands will be executed using /bin/sh
    job 1 at Fri Apr 10 18:25:00 2026
    at>
    ```

!!! note
    At the `at>` prompt, type `touch /tmp/has_ran_from_at_interactive` and then press `Ctrl + D` to save the job.

Step 3: Queue a one-time command from the shell.

```bash
# Queue a command that creates a marker file in one minute.
echo "touch /tmp/has_ran_from_atd" | at now+1minute
```
??? example "Expected result"
    ```text
    warning: commands will be executed using /bin/sh
    job 1 at Fri Apr 10 18:24:00 2026
    ```

Step 4: List the queued `at` jobs.

```bash
# List pending at jobs.
atq
```
??? example "Expected result"
    ```text
    1       Fri Apr 10 18:25:00 2026 a ubuntu
    2       Fri Apr 10 18:24:00 2026 a ubuntu
    ```

!!! note
    Job numbers and scheduled times will vary. If the command runs before you check, `atq` may already be empty.

Step 5: Check `/tmp` for the created files after the scheduled time passes.

```bash
# Check whether the marker files created by at are present.
ls -l /tmp/has_ran_from_at*
```
??? example "Expected result"
    ```text
    -rw-rw-r-- 1 ubuntu ubuntu 0 Apr 10 18:24 /tmp/has_ran_from_atd
    -rw-rw-r-- 1 ubuntu ubuntu 0 Apr 10 18:25 /tmp/has_ran_from_at_interactive
    ```

Step 6: Create the script file used by a later `at -f` job.

```bash
# Create the script file for the at -f example.
touch ~/job.sh
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 7: Write the job script.

```bash
# Write a script that removes the earlier marker file.
sudo tee ~/job.sh <<'EOF'
#!/bin/bash

rm /tmp/has_ran_from_atd
EOF
```
??? example "Expected result"
    ```text
    #!/bin/bash

    rm /tmp/has_ran_from_atd
    ```

Step 8: Make the job script executable.

```bash
# Mark the at job script as executable.
chmod +x ~/job.sh
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 9: Schedule the script to run in one minute.

```bash
# Queue the saved job script to run in one minute.
at now+1minute -f ~/job.sh
```
??? example "Expected result"
    ```text
    warning: commands will be executed using /bin/sh
    job 2 at Fri Apr 10 18:27:00 2026
    ```

Step 10: Check whether the earlier marker file was removed.

```bash
# Check whether the earlier at marker file has been removed.
ls -l /tmp/has_ran_from_atd
```
??? example "Expected result"
    ```text
    ls: cannot access '/tmp/has_ran_from_atd': No such file or directory
    ```

Step 11: Submit a job with `batch`.

!!! note
    `batch` is configurable, but through `atd`, not through the `batch` command itself. By default, `batch` jobs run when the load average drops below `1.5`, unless `atd` was started with a different threshold.

```bash
# Queue a command that runs when system load is low enough.
echo "touch /tmp/has_ran_from_batch" | batch
```
??? example "Expected result"
    ```text
    warning: commands will be executed using /bin/sh
    job 3 at Fri Apr 10 18:27:00 2026
    ```

Step 12: Check `/tmp` for the `batch` marker file.

```bash
# Confirm the marker file created by batch.
ls -l /tmp/has_ran_from_batch
```
??? example "Expected result"
    ```text
    -rw-rw-r-- 1 ubuntu ubuntu 0 Apr 10 18:27 /tmp/has_ran_from_batch
    ```

Step 13: Check how `atd` was started to see whether a custom batch load threshold is set.

```bash
# Show the atd start command and look for a custom -l load threshold.
systemctl show -p ExecStart atd.service
```
??? example "Expected result"
    ```text
    ExecStart={ path=/usr/sbin/atd ; argv[]=/usr/sbin/atd -f ; ignore_errors=no ; start_time=[n/a] ; stop_time=[n/a] ; pid=0 ; code=(null) ; status=0/0 }
    ```

!!! note
    If the `ExecStart` line includes `-l <value>`, that value is the batch load-average threshold. If no `-l` option is present, `atd` is using its default threshold of `1.5`.

!!! pied-piper "Takeaway"
    For scheduled work on Ubuntu:

    - prefer `systemd` timers for modern recurring or structured jobs
    - use `systemd-run` for quick transient jobs
    - use `at` for a one-time legacy job
    - use `batch` when the job should wait for lower system load
