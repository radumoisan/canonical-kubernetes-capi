# Boot And System Initialization Lab Commands

Source: `docs/boot-and-system-initialization.md`

## 4.2 GRUB2 Lab

### 4.2.1 GRUB2 Configuration

```bash
# Connect to LABVM as the ubuntu user over SSH.
ssh ubuntu@192.168.101.50
```

```bash
# Display the current GRUB defaults file.
cat /etc/default/grub
```

```bash
# List GRUB menu entries from the generated configuration.
sudo awk -F\' '$1=="menuentry " {print i++ " : " $2}' /boot/grub/grub.cfg
```

```bash
# Install vim for editing GRUB settings.
sudo apt install -y vim
```

```bash
# Remove the cloud image GRUB defaults drop-in if it exists.
sudo rm -f /etc/default/grub.d/50-cloudimg-settings.cfg
```

```bash
# Edit the GRUB defaults file so the menu stays visible and remembers the last selection.
sudo vim /etc/default/grub
```

```bash
# Rebuild the generated GRUB configuration.
sudo update-grub
```

### 4.2.2 Console Connection

```bash
# Edit the GRUB defaults file and add the serial-console settings for virsh console access.
sudo vim /etc/default/grub
```

```bash
# Show only the serial-console-related GRUB settings.
grep -E '^(GRUB_CMDLINE_LINUX|GRUB_TERMINAL|GRUB_SERIAL_COMMAND)=' /etc/default/grub
```

```bash
# Rebuild the generated GRUB configuration after editing defaults.
sudo update-grub
```

```bash
# Exit the LABVM shell.
exit
```

```bash
# Attach to the LABVM serial console from the host.
virsh console ubuntu
```

```bash
# Reboot LABVM from the serial console.
sudo reboot
```

### 4.2.3 Using HWE Kernels To Test Alternate Versions

```bash
# Show the currently running kernel version.
uname -r
```

```bash
# Refresh the APT package index before installing the HWE kernel.
sudo apt update
```

```bash
# Install the Ubuntu 24.04 HWE kernel stack.
sudo apt install -y --install-recommends linux-generic-hwe-24.04
```

```bash
# Show whether the Ubuntu 24.04 HWE meta-packages are installed and which version they select.
apt-cache policy linux-generic-hwe-24.04 linux-image-generic-hwe-24.04
```

```bash
# List installed linux-image packages.
dpkg --list | grep linux-image
```

```bash
# List the current GRUB menu entries after installing another kernel.
sudo awk -F\' '$1=="menuentry " {print i++ " : " $2}' /boot/grub/grub.cfg
```

```bash
# Edit the GRUB defaults file with the default Ubuntu editor.
sudo nano /etc/default/grub
```

```bash
# Rebuild the GRUB menu after adjusting the timeout settings.
sudo update-grub
```

```bash
# Reboot LABVM to choose a different kernel from GRUB.
sudo reboot
```

```bash
# Reconnect to the LABVM serial console.
virsh console ubuntu
```

```bash
# Verify the active kernel after the reboot.
uname -r
```

```bash
# Reboot once more from the console.
sudo reboot
```

## 4.4 systemd Lab

### 4.4.1 Manage Services

```bash
# List all loaded service units.
systemctl list-units --type=service
```

```bash
# List only service units that are currently running.
systemctl list-units --type=service --state=running
```

```bash
# Search the unit list for SSH-related entries.
systemctl -a | grep ssh
```

```bash
# Stop the libvirt daemon.
sudo systemctl stop libvirtd.service
```

```bash
# Show the current status of the libvirt daemon.
sudo systemctl status libvirtd.service
```

```bash
# Start the libvirt daemon.
sudo systemctl start libvirtd.service
```

```bash
# Show the current status after restarting libvirtd.
sudo systemctl status libvirtd.service
```

```bash
# Display the libvirtd unit definition and any drop-ins.
systemctl cat libvirtd.service
```

```bash
# Show the dependency tree for libvirtd.
systemctl list-dependencies libvirtd.service
```

```bash
# Display detailed key-value properties for libvirtd.
systemctl show libvirtd.service
```

```bash
# List units that are currently in a failed state.
systemctl --failed
```

```bash
# Show boot-time service startup delays.
systemd-analyze blame
```

### 4.4.2 Logging

```bash
# Display the full journal.
sudo journalctl
```

```bash
# Display journal entries from the current boot.
sudo journalctl -b
```

```bash
# Display journal entries from the previous boot.
journalctl -b -1
```

```bash
# Display journal entries from two boots ago.
journalctl -b -2
```

```bash
# List the boots stored in the journal.
journalctl --list-boots
```

```bash
# Display kernel log messages from the current boot.
sudo journalctl -k
```

```bash
# Display kernel log messages from two boots ago.
sudo journalctl -k -b -2
```

```bash
# Filter kernel logs for AppArmor denials.
sudo journalctl -k -b | grep 'apparmor="DENIED"'
```

```bash
# Display journal entries for ssh.service.
sudo journalctl -u ssh.service
```

```bash
# Display journal entries for libvirtd.service.
sudo journalctl -u libvirtd.service
```

```bash
# Create the directory used for persistent journal storage.
sudo mkdir -p /var/log/journal
```

```bash
# Restart journald after enabling persistent log storage.
sudo systemctl restart systemd-journald
```

### 4.4.3 Create A Custom Service

```bash
# Connect to LABVM as the ubuntu user over SSH.
ssh ubuntu@192.168.101.50
```

```bash
# Create the script file used by the custom service.
touch ~/service.sh
```

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

```bash
# Mark the service script as executable.
sudo chmod +x ~/service.sh
```

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

```bash
# Set the unit file mode.
sudo chmod 644 /etc/systemd/system/myservice.service
```

```bash
# Start the custom service immediately.
sudo systemctl start myservice.service
```

```bash
# Enable the custom service at boot.
sudo systemctl enable myservice.service
```

```bash
# Show the service status and recent log lines.
sudo systemctl status myservice.service
```

```bash
# Show journal entries for the custom service.
sudo journalctl -u myservice.service
```

```bash
# Stop the custom service.
sudo systemctl stop myservice.service
```

```bash
# Disable the custom service so it no longer starts at boot.
sudo systemctl disable myservice.service
```

## 4.6 On Demand And Scheduled Tasks Lab

### Part 1: systemd Timers (Preferred Method)

```bash
# List all timers currently known to systemd.
systemctl list-timers
```

```bash
# Schedule a one-time command that creates a marker file.
sudo systemd-run --on-active=1 /bin/touch /tmp/has_ran_from_systemd
```

```bash
# Confirm that the transient timer created the marker file.
ls -l /tmp/has_ran_from_systemd
```

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

```bash
# Enable and start the path unit.
sudo systemctl enable --now mywatch.path
```

```bash
# Create the watched file to trigger the path unit.
touch /tmp/watchme
```

```bash
# Verify that the path-triggered service ran.
cat /tmp/watched.log
```

### Part 2: Legacy Tools - at And batch

```bash
# Install the at daemon and client tools.
sudo apt install -y at
```

```bash
# Open an interactive at prompt for two minutes from now.
at now+2minutes
```

```bash
# Queue a command that creates a marker file in one minute.
echo "touch /tmp/has_ran_from_atd" | at now+1minute
```

```bash
# List pending at jobs.
atq
```

```bash
# Check whether the marker files created by at are present.
ls -l /tmp/has_ran_from_at*
```

```bash
# Create the script file for the at -f example.
touch ~/job.sh
```

```bash
# Write a script that removes the earlier marker file.
sudo tee ~/job.sh <<'EOF'
#!/bin/bash

sudo rm /tmp/has_ran_from_atd
EOF
```

```bash
# Mark the at job script as executable.
chmod +x ~/job.sh
```

```bash
# Queue the saved job script to run in one minute.
at now+1minute -f ~/job.sh
```

```bash
# Check whether the earlier at marker file has been removed.
ls -l /tmp/
```

```bash
# Queue a command that runs when system load is low enough.
echo "touch /tmp/has_ran_from_batch" | batch
```

```bash
# Confirm the marker file created by batch.
ls -l /tmp/
```

```bash
# Show the atd start command and look for a custom -l load threshold.
systemctl show -p ExecStart atd.service
```
