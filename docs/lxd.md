# LXD

This chapter introduces LXD system containers and basic LXD VM workflows.

In this chapter you will:

- review containerization concepts
- install and initialize LXD
- launch and manage containers
- work with images, profiles, and snapshots
- create a VM with LXD
- inspect and attach LXD networks

## :material-book-open-page-variant-outline: 2.1 Containerization

Containers are isolated userspace environments that run on the same host kernel. They use Linux kernel features such as namespaces and cgroups to isolate processes, filesystems, users, and networking with much lower overhead than a full virtual machine.

Unlike full virtualization, containers do not boot their own kernel. They share the host kernel, which reduces resource usage and allows faster startup.

Two common container models are used in practice:

- application containers, which package a single service or process
- system containers, which provide a fuller operating system environment

LXD focuses on system containers. Under the hood it uses LXC, while adding a daemon, API, and management tools that make container lifecycle tasks easier.

## :material-book-open-page-variant-outline: 2.2 What Is LXD?

LXD is a system container and virtual machine manager. It provides VM-style operations such as launch, stop, snapshot, copy, and delete, but uses Linux containers for container workloads instead of hardware virtualization.

LXD is built around two main components:

- `lxd`, the system daemon that exposes the management API
- `lxc`, the CLI client used to manage local or remote LXD servers

LXD is image-based. Containers and VMs are created from images, and those images can be downloaded from local or remote image servers.

## :material-book-open-page-variant-outline: 2.3 LXD Setup Lab

!!! info
    Run this lab on `LABVM` unless a step explicitly says otherwise.
    In this lab environment, `LABVM` is reachable at `192.168.101.50`.

### :material-application-edit-outline: 2.3.1 Install LXD

Install and initialize LXD on `LABVM`.

!!! info
    This exercise installs and initializes LXD on `LABVM`. Success means the `ubuntu` user can access LXD through the `lxd` group, `lxd init --auto` completes, `lxdbr0` is configured with MTU `1450`, and the test container `noble` starts successfully.

Step 1: Make sure you are logged in to `LABVM`.

!!! note
    In this lab, the `ubuntu` user password on `LABVM` is `ubuntu`.

```bash
# Connect to LABVM over SSH.
ssh 192.168.101.50
```
??? example "Expected result"
    ```text
    ubuntu@192.168.101.50's password:
    Welcome to Ubuntu 24.04 LTS (GNU/Linux 6.8.0-*-generic x86_64)
    ubuntu@ubuntu:~$
    ```

Step 2: Set a `LABVM` prompt, then install ZFS support for LXD storage features.

!!! note
    To make it easier to distinguish `LABVM` from `LABHOST`, set a custom shell prompt on `LABVM` before continuing.

```bash
# Append a LABVM prompt to ~/.bashrc.
printf '%s\n' 'PS1="\[\e[1;32m\]\u@LABVM\[\e[0m\]:\[\e[1;34m\]\w\[\e[0m\]\\$ "' >> ~/.bashrc
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
    ubuntu@LABVM:~$
    ```

```bash
# Install the ZFS tools used by the LXD storage backend in this lab.
sudo apt -y install zfsutils-linux
```
??? example "Expected result"
    ```text
    Reading package lists... Done
    Building dependency tree... Done
    The following NEW packages will be installed:
      zfsutils-linux
    ...
    Setting up zfsutils-linux ...
    ```

LXD can use ZFS for storage pools and snapshots. ZFS is covered in more detail later in the course.

Step 3: Create the `lxd` group.

```bash
# Ensure the lxd system group exists.
sudo groupadd --system lxd
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 4: Add the `ubuntu` user to the `lxd` group.

```bash
# Add the ubuntu user to the lxd group.
sudo usermod -aG lxd ubuntu
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 5: Refresh the current shell group membership.

```bash
# Start a new shell that picks up the lxd group membership.
newgrp lxd
```
??? example "Expected result"
    ```text
    No output.
    ```

This starts a subshell with the updated group membership. If the prompt looks the same, that is normal.

You will leave this subshell near the end of the lab before you close the SSH session back to `LABHOST`.

Step 6: Install LXD as a snap.

```bash
# Install LXD from the validated 5.21 stable channel.
sudo snap install lxd --channel=5.21/stable
```
??? example "Expected result"
    ```text
    lxd (5.21/stable) 5.21.* from Canonical installed
    ```

Step 7: Initialize LXD with the default configuration.

```bash
# Initialize LXD with the default non-interactive settings.
sudo lxd init --auto
```
??? example "Expected result"
    ```text
    No output.
    ```

!!! note
    Use `lxd init` without `--auto` if you want the interactive setup flow.

Step 8: Set the LXD bridge MTU to `1450`.

```bash
# Set the default LXD bridge MTU to 1450 for this lab.
lxc network set lxdbr0 bridge.mtu=1450
```
??? example "Expected result"
    ```text
    No output.
    ```

Some LXD client versions may print a first-use hint after this command. If that happens, you can ignore it.

Step 9: Launch a new Ubuntu 24.04 container.

```bash
# Launch a container named noble from the Ubuntu 24.04 image.
lxc launch ubuntu:24.04 noble
```
??? example "Expected result"
    ```text
    Creating noble
    Starting noble
    ```

Step 10: List instances.

```bash
# List instances and confirm noble is running.
lxc list
```
??? example "Expected result"
    ```text
    +-------+---------+----------------------+------+-----------+-----------+
    | NAME  |  STATE  |         IPV4         | IPV6 |   TYPE    | SNAPSHOTS |
    +-------+---------+----------------------+------+-----------+-----------+
    | noble | RUNNING | 10.96.234.22 (eth0)  | fd42:ac23:f544:f9ac:216:3eff:fe9c:640d (eth0) | CONTAINER | 0 |
    +-------+---------+----------------------+------+-----------+-----------+
    ```

Step 11: List images in the local store.

```bash
# List cached images in the local LXD image store.
lxc image list
```
??? example "Expected result"
    ```text
    +-------+--------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    | ALIAS | FINGERPRINT  | PUBLIC |             DESCRIPTION              | ARCHITECTURE |   TYPE    |   SIZE   |         UPLOAD DATE          |
    +-------+--------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    |       | d6c393290422 | no     | ubuntu 24.04 LTS amd64 (release) (20260321) | x86_64 | CONTAINER | 267.82MiB | Apr 10, 2026 at 8:00am (UTC) |
    +-------+--------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    ```

Step 12: Create the `ubuntu` image alias.

```bash
# Create a local ubuntu alias for the downloaded image fingerprint.
lxc image alias create ubuntu <fingerprint>
```
??? example "Expected result"
    ```text
    No output.
    ```

Replace `<fingerprint>` with the actual value shown in the previous `lxc image list` output. In the example above, that value is `d6c393290422`.

The `ubuntu` alias can then be used as a shorter image reference.

!!! pied-piper "Takeaway"
    After the initial setup, make sure you remember:

    - LXD is installed as a snap in this lab
    - `lxd init --auto` gives you a quick default setup
    - once initialized, you can launch instances immediately with `lxc launch`

### :material-application-edit-outline: 2.3.2 Using A Remote LXD As An Image Server

LXD can launch instances directly from remote image servers.

!!! info
    This exercise shows how LXD launches from a remote image server and caches the image locally. Success means the `centos` container starts from `images:` and later appears in the local image store.

Step 1: Launch a CentOS Stream 9 container from the `images` remote.

```bash
# Launch a CentOS Stream 9 container from the public images remote.
lxc launch images:centos/9-Stream centos
```
??? example "Expected result"
    ```text
    Creating centos
    Starting centos
    ```

Step 2: List images available from the `images` remote.

!!! note
    Pay attention to the trailing `:` in `images:`. The colon is required when referring to a remote image server.

```bash
# List images published by the images remote.
lxc image list images:
```
??? example "Expected result"
    ```text
    +--------------------------------------+--------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    |             FINGERPRINT              |    ALIAS     | PUBLIC |             DESCRIPTION              | ARCHITECTURE |   TYPE    |   SIZE   |         UPLOAD DATE          |
    +--------------------------------------+--------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    | 3374eec53d86                         | almalinux/9 (3 more)     | yes | AlmaLinux 9 amd64 (20260410_0016)     | x86_64 | CONTAINER | 113.25MiB | Apr 10, 2026 at 12:16am (UTC) |
    | 1e979a497c10                         | alpine/3.20 (3 more)     | yes | Alpine 3.20 amd64 (20260401_0107)     | x86_64 | CONTAINER | 3.09MiB   | Apr 1, 2026 at 1:07am (UTC)   |
    | ccf0a36f7e0b                         | centos/9-Stream (3 more) | yes | CentOS 9-Stream amd64 (20260410_0402) | x86_64 | CONTAINER | 117.14MiB | Apr 10, 2026 at 4:02am (UTC)  |
    +--------------------------------------+--------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    ```

Step 3: List images in the local store.

!!! note
    Pay attention to the trailing `:` in `local:`. The colon is required when referring to the local image store as a remote.

```bash
# List images cached locally after the remote launch.
lxc image list local:
```
??? example "Expected result"
    ```text
    +-------+--------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    | ALIAS | FINGERPRINT  | PUBLIC |             DESCRIPTION              | ARCHITECTURE |   TYPE    |   SIZE   |         UPLOAD DATE          |
    +-------+--------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    | ubuntu | d6c393290422 | no   | ubuntu 24.04 LTS amd64 (release) (20260321) | x86_64 | CONTAINER | 267.82MiB | Apr 10, 2026 at 8:00am (UTC) |
    |        | ccf0a36f7e0b | no   | CentOS 9-Stream amd64 (20260410_0402) | x86_64 | CONTAINER | 117.14MiB | Apr 10, 2026 at 8:11am (UTC) |
    | ...    | ...          | ...  | ...                                  | ...          | ...       | ...       | ...                          |
    +-------+--------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    ```

!!! pied-piper "Takeaway"
    For image servers, remember:

    - `images:`, `ubuntu:`, and similar names are remotes
    - the trailing `:` matters
    - launching from a remote can also cache the image locally

### :material-application-edit-outline: 2.3.3 Creating And Using A Container

!!! info
    This exercise walks through the basic container lifecycle. Success means you can launch `first`, run commands inside it, copy files in and out, and then stop and delete it cleanly.

Step 1: Launch a container named `first`.

```bash
# Launch a container named first from the local ubuntu alias.
lxc launch ubuntu first
```
??? example "Expected result"
    ```text
    Creating first
    Starting first
    ```

Step 2: Confirm that the container is running.

```bash
# List instances and confirm first is running.
lxc list
```
??? example "Expected result"
    ```text
    +-------+---------+----------------------+------+-----------+-----------+
    | NAME  |  STATE  |         IPV4         | IPV6 |   TYPE    | SNAPSHOTS |
    +-------+---------+----------------------+------+-----------+-----------+
    | centos | RUNNING | 10.96.234.59 (eth0) | fd42:ac23:f544:f9ac:216:3eff:fe04:9c3c (eth0) | CONTAINER | 0 |
    | first  | RUNNING | 10.96.234.238 (eth0) | fd42:ac23:f544:f9ac:216:3eff:fea3:c6f4 (eth0) | CONTAINER | 0 |
    | noble  | RUNNING | 10.96.234.22 (eth0) | fd42:ac23:f544:f9ac:216:3eff:fe9c:640d (eth0) | CONTAINER | 0 |
    +-------+---------+----------------------+------+-----------+-----------+
    ```

Step 3: Open a shell inside the container.

```bash
# Open an interactive shell inside first.
lxc exec first -- /bin/bash
```
??? example "Expected result"
    ```text
    root@first:~#
    ```

Step 4: Exit the container shell.

```bash
# Leave the container shell and return to LABVM.
exit
```
??? example "Expected result"
    ```text
    exit
    ubuntu@LABVM:~$
    ```

Step 5: Run a command directly in the container.

```bash
# Refresh package metadata inside first.
lxc exec first -- apt update
```
??? example "Expected result"
    ```text
    Hit:1 http://archive.ubuntu.com/ubuntu noble InRelease
    Reading package lists... Done
    ```

Step 6: Pull a file from the container.

```bash
# Copy /etc/hosts from first to the current directory on LABVM.
lxc file pull first/etc/hosts .
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 7: Push a file into the container.

```bash
# Copy the local hosts file into /tmp inside first.
lxc file push ./hosts first/tmp/
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 8: Verify the copied file in the container.

```bash
# Verify that /tmp/hosts exists inside first.
lxc exec first -- ls -l /tmp/hosts
```
??? example "Expected result"
    ```text
    -rw-r--r-- 1 ubuntu ubuntu 221 Apr 10 08:20 /tmp/hosts
    ```

Step 9: Stop the container.

```bash
# Stop the first container before cleanup.
lxc stop first
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 10: Delete the container.

```bash
# Delete the stopped first container.
lxc delete first
```
??? example "Expected result"
    ```text
    No output.
    ```

!!! pied-piper "Takeaway"
    The basic LXD container workflow is:

    - launch with `lxc launch`
    - inspect with `lxc list`
    - enter or run commands with `lxc exec`
    - stop and delete when finished

### :material-application-edit-outline: 2.3.4 Images

!!! info
    This exercise compares the image remotes configured in LXD. Success means you can identify the difference between remote image listings such as `images:` and locally cached images under `local:`.

Step 1: List configured remotes.

```bash
# List the image remotes currently configured in LXD.
lxc remote list
```
??? example "Expected result"
    ```text
    +----------------------+---------------------------------------------------+---------------+-------------+--------+--------+--------+
    |         NAME         |                        URL                        |   PROTOCOL    |  AUTH TYPE  | PUBLIC | STATIC | GLOBAL |
    +----------------------+---------------------------------------------------+---------------+-------------+--------+--------+--------+
    | images               | https://images.lxd.canonical.com                  | simplestreams | none        | YES    | YES    | NO     |
    | local (current)      | unix://                                           | lxd           | file access | NO     | YES    | NO     |
    | ubuntu               | https://cloud-images.ubuntu.com/releases/         | simplestreams | none        | YES    | YES    | NO     |
    | ubuntu-daily         | https://cloud-images.ubuntu.com/daily/            | simplestreams | none        | YES    | YES    | NO     |
    | ubuntu-minimal       | https://cloud-images.ubuntu.com/minimal/releases/ | simplestreams | none        | YES    | YES    | NO     |
    | ubuntu-minimal-daily | https://cloud-images.ubuntu.com/minimal/daily/    | simplestreams | none        | YES    | YES    | NO     |
    +----------------------+---------------------------------------------------+---------------+-------------+--------+--------+--------+
    ```

Step 2: List images from the `images` remote.

!!! note
    Pay attention to the trailing `:` in `images:`. The colon is required when referring to a remote image server.

```bash
# List images available from the images remote.
lxc image list images:
```
??? example "Expected result"
    ```text
    +--------------------------------------+--------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    |             FINGERPRINT              |    ALIAS     | PUBLIC |             DESCRIPTION              | ARCHITECTURE |   TYPE    |   SIZE   |         UPLOAD DATE          |
    +--------------------------------------+--------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    | 3374eec53d86                         | almalinux/9 (3 more)     | yes | AlmaLinux 9 amd64 (20260410_0016)     | x86_64 | CONTAINER | 113.25MiB | Apr 10, 2026 at 12:16am (UTC) |
    | 1e979a497c10                         | alpine/3.20 (3 more)     | yes | Alpine 3.20 amd64 (20260401_0107)     | x86_64 | CONTAINER | 3.09MiB   | Apr 1, 2026 at 1:07am (UTC)   |
    | ccf0a36f7e0b                         | centos/9-Stream (3 more) | yes | CentOS 9-Stream amd64 (20260410_0402) | x86_64 | CONTAINER | 117.14MiB | Apr 10, 2026 at 4:02am (UTC)  |
    +--------------------------------------+--------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    ```

Step 3: List images in the local store.

!!! note
    Pay attention to the trailing `:` in `local:`. The colon is required when referring to the local image store as a remote.

```bash
# List images currently cached in the local image store.
lxc image list local:
```
??? example "Expected result"
    ```text
    +-------+--------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    | ALIAS | FINGERPRINT  | PUBLIC |             DESCRIPTION              | ARCHITECTURE |   TYPE    |   SIZE   |         UPLOAD DATE          |
    +-------+--------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    | ubuntu | d6c393290422 | no   | ubuntu 24.04 LTS amd64 (release) (20260321) | x86_64 | CONTAINER | 267.82MiB | Apr 10, 2026 at 8:00am (UTC) |
    |        | ccf0a36f7e0b | no   | CentOS 9-Stream amd64 (20260410_0402) | x86_64 | CONTAINER | 117.14MiB | Apr 10, 2026 at 8:11am (UTC) |
    | ...    | ...          | ...  | ...                                  | ...          | ...       | ...       | ...                          |
    +-------+--------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    ```

Step 4: List Ubuntu release images.

!!! note
    Pay attention to the trailing `:` in `ubuntu:`. The colon is required when referring to the Ubuntu image remote.

```bash
# List published release images from the ubuntu remote.
lxc image list ubuntu:
```
??? example "Expected result"
    ```text
    +--------------------------------------+----------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    |             FINGERPRINT              |     ALIAS      | PUBLIC |             DESCRIPTION              | ARCHITECTURE |   TYPE    |   SIZE   |         UPLOAD DATE          |
    +--------------------------------------+----------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    | ...                                  | 22.04          | yes    | ubuntu 22.04 LTS amd64 (release)     | x86_64       | CONTAINER | ...      | ...                          |
    | ...                                  | 24.04          | yes    | ubuntu 24.04 LTS amd64 (release)     | x86_64       | CONTAINER | ...      | ...                          |
    | ...                                  | 14.04          | yes    | ubuntu 14.04 LTS amd64 (release)     | x86_64       | CONTAINER | ...      | ...                          |
    | ...                                  | ...            | ...    | ...                                  | ...          | ...       | ...      | ...                          |
    +--------------------------------------+----------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    ```

Step 5: List daily Ubuntu images.

!!! note
    Pay attention to the trailing `:` in `ubuntu-daily:`. The colon is required when referring to the Ubuntu daily image remote.

```bash
# List published daily images from the ubuntu-daily remote.
lxc image list ubuntu-daily:
```
??? example "Expected result"
    ```text
    +--------------------------------------+----------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    |             FINGERPRINT              |     ALIAS      | PUBLIC |             DESCRIPTION              | ARCHITECTURE |   TYPE    |   SIZE   |         UPLOAD DATE          |
    +--------------------------------------+----------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    | c533845b5db1                         | b (5 more)     | yes    | ubuntu 18.04 LTS amd64 (daily)       | x86_64       | CONTAINER | 215.55MiB | Jun 7, 2023 at 12:00am (UTC)  |
    | dde688f95cc6                         | n (9 more)     | yes    | ubuntu 24.04 LTS amd64 (daily) (20260323) | x86_64 | CONTAINER | 267.82MiB | Mar 23, 2026 at 12:00am (UTC) |
    | f6039be3f0c2                         | r (7 more)     | yes    | ubuntu 26.04 LTS amd64 (daily)       | x86_64       | CONTAINER | 311.04MiB | Mar 28, 2026 at 12:00am (UTC) |
    | ...                                  | ...            | ...    | ...                                  | ...          | ...       | ...       | ...                           |
    +--------------------------------------+----------------+--------+--------------------------------------+--------------+-----------+----------+------------------------------+
    ```

### :material-application-edit-outline: 2.3.5 LXD Profiles

Profiles store reusable instance configuration.

!!! info
    This exercise introduces profiles as reusable defaults for instances. Success means you can identify the devices defined in the `default` profile and understand that instances inherit those settings.

Step 1: List all profiles.

```bash
# List the profiles currently configured in LXD.
lxc profile list
```
??? example "Expected result"
    ```text
    +---------+---------------------+---------+
    |  NAME   |     DESCRIPTION     | USED BY |
    +---------+---------------------+---------+
    | default | Default LXD profile | 2       |
    +---------+---------------------+---------+
    ```

Step 2: Open the default profile for editing.

```bash
# Open the default profile in your editor.
lxc profile edit default
```
??? example "Expected result"
    ```text
    The editor opens with content similar to:

    name: default
    description: Default LXD profile
    config: {}
    devices:
      eth0:
        name: eth0
        network: lxdbr0
        type: nic
      root:
        path: /
        pool: default
        type: disk
    ```

If you open the editor only to inspect the profile, exit without saving changes.

Step 3: Show the current profile definition.

```bash
# Show the current default profile definition.
lxc profile show default
```
??? example "Expected result"
    ```text
    name: default
    description: Default LXD profile
    config: {}
    devices:
      eth0:
        name: eth0
        network: lxdbr0
        type: nic
      root:
        path: /
        pool: default
        type: disk
    used_by:
    - /1.0/instances/noble
    - /1.0/instances/centos
    project: default
    ```

!!! pied-piper "Takeaway"
    Profiles are reusable defaults:

    - they define things like NICs, disks, and other instance settings
    - multiple instances can share the same profile
    - changing a profile changes the defaults applied to instances that use it

### :material-application-edit-outline: 2.3.6 LXD Snapshots

!!! info
    This exercise shows how to create a snapshot, restore from it, and clone a new container from it. Success means `lxc info noble` shows `my-snapshot` and the cloned container starts successfully.

Step 1: Create a snapshot of `noble`.

```bash
# Create a snapshot of noble named my-snapshot.
lxc snapshot noble my-snapshot
```
??? example "Expected result"
    ```text
    No output.
    ```

Snapshots are typically fast because the storage backend records only changed data.

Step 2: Show container information, including snapshots.

```bash
# Show noble details, including snapshot information.
lxc info noble
```
??? example "Expected result"
    ```text
    Name: noble
    Status: RUNNING
    Type: container
    Snapshots:
    +-------------+----------------------+------------+----------+
    |    NAME     |       TAKEN AT       | EXPIRES AT | STATEFUL |
    +-------------+----------------------+------------+----------+
    | my-snapshot | 2026/04/10 08:46 UTC |            | NO       |
    +-------------+----------------------+------------+----------+
    ```

Step 3: Restore the container from the snapshot.

```bash
# Restore noble from the my-snapshot snapshot.
lxc restore noble my-snapshot
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 4: Create a new container from the snapshot.

```bash
# Create a new container from the noble snapshot.
lxc copy noble/my-snapshot my-new-container-from-snapshot
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 5: Assign the default profile to the new container.

```bash
# Apply the default profile to the cloned container.
lxc profile assign my-new-container-from-snapshot default
```
??? example "Expected result"
    ```text
    Profiles default applied to my-new-container-from-snapshot
    ```

Step 6: Start the new container.

```bash
# Start the container created from the snapshot.
lxc start my-new-container-from-snapshot
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 7: List instances.

```bash
# Verify that the cloned container is present and running.
lxc list
```
??? example "Expected result"
    ```text
    +--------------------------------+---------+----------------------+------------------------------------------------+-----------+-----------+
    |              NAME              |  STATE  |         IPV4         |                      IPV6                      |   TYPE    | SNAPSHOTS |
    +--------------------------------+---------+----------------------+------------------------------------------------+-----------+-----------+
    | centos                         | RUNNING | 10.96.234.26 (eth0)  | fd42:ac23:f544:f9ac:661b:abcd:de3f:426c (eth0) | CONTAINER | 0         |
    | my-new-container-from-snapshot | RUNNING | 10.96.234.198 (eth0) | fd42:ac23:f544:f9ac:216:3eff:fe95:17d7 (eth0)  | CONTAINER | 0         |
    | noble                          | RUNNING | 10.96.234.22 (eth0)  | fd42:ac23:f544:f9ac:216:3eff:fe9c:640d (eth0)  | CONTAINER | 1         |
    +--------------------------------+---------+----------------------+------------------------------------------------+-----------+-----------+
    ```

Step 8: Stop the `centos` container.

```bash
# Stop the centos container before cleanup.
lxc stop centos
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 9: Stop the `noble` container.

```bash
# Stop the noble container before cleanup.
lxc stop noble
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 10: Stop the cloned container.

```bash
# Stop the snapshot-based container before cleanup.
lxc stop my-new-container-from-snapshot
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 11: Delete the `centos` container.

```bash
# Delete the centos container.
lxc delete centos
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 12: Delete the `noble` container.

```bash
# Delete the noble container.
lxc delete noble
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 13: Delete the cloned container.

```bash
# Delete the snapshot-based container.
lxc delete my-new-container-from-snapshot
```
??? example "Expected result"
    ```text
    No output.
    ```

!!! pied-piper "Takeaway"
    Snapshots are useful because you can:

    - save an instance state quickly
    - roll back to that state later
    - clone a new instance from a snapshot

### :material-application-edit-outline: 2.3.7 KVM VMs In LXD

LXD can manage both containers and virtual machines.

!!! info
    This exercise compares default and custom LXD VM sizing. Success means you can open a shell in each VM and confirm that `ubuntu-vm2` sees 2 vCPUs, about 2 GiB of RAM, and a 20G root disk.

Step 1: Launch a VM with the default resource settings.

!!! note
    The first VM launch may take longer than a container launch. Allow a minute or two for the image download, first boot, and initial cloud-init run.

```bash
# Launch an LXD VM named ubuntu-vm.
lxc launch ubuntu:24.04 ubuntu-vm --vm
```
??? example "Expected result"
    ```text
    Launching ubuntu-vm
    Retrieving image: Unpacking image: 100%
    ```

Step 2: Open the VM console.

!!! note
    When the console connects, expect to see the VM boot logs while the system starts.

```bash
# Open the serial console for ubuntu-vm.
lxc console ubuntu-vm
```
??? example "Expected result"
    ```text
    Console connected to ubuntu-vm
    To detach from the console, press: <ctrl>+a q
    ```

!!! warning
    This console gives you serial access to the new LXD VM, but it does not reuse the `ubuntu` / `ubuntu` credentials from `LABVM`.

    No custom cloud-init `user-data` is copied into or injected from `LABVM` when `ubuntu-vm` is created (as we haven't copied/configured any, inside LABVM). The VM therefore boots with the default image behavior instead of the Chapter 1 guest settings.

    Use the console to watch the boot process, then use `lxc shell ubuntu-vm` once the guest agent is ready.

To exit the LXD console, press `Ctrl+a q`.

Step 3: Open a shell in the VM.

```bash
# Open a shell inside ubuntu-vm once the guest agent is ready.
lxc shell ubuntu-vm
```
??? example "Expected result"
    ```text
    root@ubuntu-vm:~#
    ```

If `lxc shell ubuntu-vm` reports that the guest agent is not ready yet, wait a little longer and retry.

Step 4: Check CPU information in the VM.

```bash
# Show CPU details inside ubuntu-vm.
cat /proc/cpuinfo
```
??? example "Expected result"
    ```text
    processor   : 0
    model name  : Intel(R) Xeon(R) Gold 5120 CPU @ 2.20GHz
    ...
    ```

Step 5: Check memory in the VM.

```bash
# Show memory usage inside ubuntu-vm.
free -m
```
??? example "Expected result"
    ```text
                  total        used        free      shared  buff/cache   available
    Mem:             956         336         530          18         250         620
    Swap:             0           0           0
    ```

Step 6: Check block devices in the VM.

```bash
# List block devices inside ubuntu-vm.
lsblk
```
??? example "Expected result"
    ```text
    NAME    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
    sda       8:0    0   10G  0 disk
    sda1      8:1    0    9G  0 part /
    sda15     8:15   0  106M  0 part /boot/efi
    sda16   259:0    0  913M  0 part /boot
    ```

Step 7: Exit the VM shell.

```bash
# Leave the VM shell and return to LABVM.
exit
```
??? example "Expected result"
    ```text
    exit
    ubuntu@LABVM:~$
    ```

!!! info
    This default configuration is suitable for testing. Production settings are usually adjusted with profiles or explicit limits.

Step 8: Launch a second VM with custom limits.

```bash
# Launch a second VM with custom CPU, memory, and disk limits.
lxc launch ubuntu:24.04 ubuntu-vm2 --vm -c limits.cpu=2 -c limits.memory=2GiB -d root,size=20GiB
```
??? example "Expected result"
    ```text
    Launching ubuntu-vm2
    Retrieving image: Unpacking image: 100%
    ```

Step 9: Open a shell in the second VM.

```bash
# Open a shell inside ubuntu-vm2 once the guest agent is ready.
lxc shell ubuntu-vm2
```
??? example "Expected result"
    ```text
    root@ubuntu-vm2:~#
    ```

If the guest agent is still starting, wait and retry this command.

Step 10: Check CPU information in the second VM.

```bash
# Count the visible processors and confirm ubuntu-vm2 sees 2 vCPUs.
grep -c '^processor' /proc/cpuinfo
```
??? example "Expected result"
    ```text
    2
    ```

Step 11: Check memory in the second VM.

```bash
# Show memory usage and confirm ubuntu-vm2 sees about 2 GiB of RAM.
free -m
```
??? example "Expected result"
    ```text
                  total        used        free      shared  buff/cache   available
    Mem:            1962         332        1540          18         254        1630
    Swap:             0           0           0
    ```

Step 12: Check block devices in the second VM.

```bash
# List block devices and confirm the root disk for ubuntu-vm2 is 20G.
lsblk -d -o NAME,SIZE,TYPE
```
??? example "Expected result"
    ```text
    NAME  SIZE TYPE
    sda    20G disk
    sr0   368K rom
    ```

Step 13: Exit the second VM shell.

```bash
# Leave the VM shell and return to LABVM.
exit
```
??? example "Expected result"
    ```text
    exit
    ubuntu@LABVM:~$
    ```

Step 14: Delete the first VM.

```bash
# Force-delete ubuntu-vm during cleanup.
lxc delete ubuntu-vm --force
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 15: Delete the second VM.

```bash
# Force-delete ubuntu-vm2 during cleanup.
lxc delete ubuntu-vm2 --force
```
??? example "Expected result"
    ```text
    No output.
    ```

`--force` removes the instance even if it is still running.

!!! pied-piper "Takeaway"
    LXD can manage both kinds of workloads:

    - containers share the host kernel
    - VMs boot their own kernel
    - you use the same `lxc` tool to manage both

### :material-application-edit-outline: 2.3.8 LXD Networks

`lxd init` can create a managed bridge and attach it to the default profile.

!!! info
    This exercise shows how LXD-managed bridges are applied through profiles. Success means `noble` inherits both `eth0` and `eth1`, and `eth1` receives an IPv4 address after you request a DHCP lease.

!!! note
    As you work through the steps, pay attention to these points:

    - `lxdbr0` is the default managed bridge created during initialization
    - `brtest0` becomes a second managed bridge
    - adding `brtest0` to the `default` profile gives new instances a second NIC
    - the container only gets a usable IPv4 address on `eth1` after you request a DHCP lease

Step 1: List LXD networks.

```bash
# List the configured LXD networks and confirm the default bridge `lxdbr0` exists.
lxc network list
```
??? example "Expected result"
    ```text
    +--------+----------+---------+----------------+---------------------------+-------------+---------+---------+
    |  NAME  |   TYPE   | MANAGED |      IPV4      |           IPV6            | DESCRIPTION | USED BY |  STATE  |
    +--------+----------+---------+----------------+---------------------------+-------------+---------+---------+
    | enp1s0 | physical | NO      |                |                           |             | 0       |         |
    | lxdbr0 | bridge   | YES     | 10.96.234.1/24 | fd42:ac23:f544:f9ac::1/64 |             | 1       | CREATED |
    +--------+----------+---------+----------------+---------------------------+-------------+---------+---------+
    ```

Step 2: Show network runtime information for `lxdbr0`.

```bash
# Show runtime details for `lxdbr0` and confirm the bridge is up.
lxc network info lxdbr0
```
??? example "Expected result"
    ```text
    Name: lxdbr0
    MAC address: 00:16:3e:9f:d0:a5
    MTU: 1450
    State: up
    Type: broadcast
    ```

Step 3: Show the `lxdbr0` configuration.

```bash
# Show the managed bridge settings for `lxdbr0`, including its address range and NAT settings.
lxc network show lxdbr0
```
??? example "Expected result"
    ```text
    name: lxdbr0
    description: ""
    type: bridge
    managed: true
    status: Created
    config:
      bridge.mtu: "1450"
      ipv4.address: 10.96.234.1/24
      ipv4.nat: "true"
      ipv6.address: fd42:ac23:f544:f9ac::1/64
      ipv6.nat: "true"
    ```

Step 4: Inspect the host interface for `lxdbr0`.

```bash
# Show the host-side interface for `lxdbr0` and confirm the bridge address matches the LXD config.
ip addr show lxdbr0
```
??? example "Expected result"
    ```text
    3: lxdbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1450 qdisc noqueue state UP group default qlen 1000
        inet 10.96.234.1/24 scope global lxdbr0
        inet6 fd42:ac23:f544:f9ac::1/64 scope global
    ```

Step 5: Create a second managed bridge.

```bash
# Create a second managed bridge named `brtest0` that will later back a second NIC.
lxc network create brtest0
```
??? example "Expected result"
    ```text
    Network brtest0 created
    ```

Step 6: Show the new bridge configuration.

```bash
# Show the new bridge configuration and note its separate IPv4 and IPv6 subnets.
lxc network show brtest0
```
??? example "Expected result"
    ```text
    name: brtest0
    description: ""
    type: bridge
    managed: true
    status: Created
    config:
      ipv4.address: 10.131.118.1/24
      ipv4.nat: "true"
      ipv6.address: fd42:6d0d:48bd:9e07::1/64
      ipv6.nat: "true"
    ```

Step 7: Attach the new network to the default profile.

```bash
# Attach `brtest0` to the `default` profile so new instances inherit a second interface as `eth1`.
lxc network attach-profile brtest0 default eth1
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 8: Review the default profile.

```bash
# Confirm that the `default` profile now defines both `eth0` and `eth1`.
lxc profile show default
```
??? example "Expected result"
    ```text
    name: default
    description: Default LXD profile
    config: {}
    devices:
      eth0:
        name: eth0
        network: lxdbr0
        type: nic
      eth1:
        nictype: bridged
        parent: brtest0
        type: nic
      root:
        path: /
        pool: default
        type: disk
    used_by: []
    project: default
    ```

Step 9: Launch a new container.

```bash
# Launch a new container so it inherits the updated default profile.
lxc launch ubuntu:24.04 noble
```
??? example "Expected result"
    ```text
    Launching noble
    Retrieving image: Unpacking image: 100%
    ```

Step 10: List instances.

```bash
# Confirm that `noble` is running and notice that only `eth0` has an IPv4 address so far.
lxc list
```
??? example "Expected result"
    ```text
    +-------+---------+----------------------+-----------------------------------------------+-----------+-----------+
    | NAME  |  STATE  |         IPV4         |                     IPV6                      |   TYPE    | SNAPSHOTS |
    +-------+---------+----------------------+-----------------------------------------------+-----------+-----------+
    | noble | RUNNING | 10.96.234.221 (eth0) | fd42:ac23:f544:f9ac:216:3eff:fe26:d997 (eth0) | CONTAINER | 0         |
    |       |         |                      | fd42:6d0d:48bd:9e07:216:3eff:fe75:e9ab (eth1) |           |           |
    +-------+---------+----------------------+-----------------------------------------------+-----------+-----------+
    ```

Step 11: Show the expanded instance configuration.

```bash
# Show the fully expanded config and confirm `noble` inherited both NICs from the profile.
lxc config show --expanded noble
```
??? example "Expected result"
    ```text
    architecture: x86_64
    config:
      image.description: ubuntu 24.04 LTS amd64 (release) (20260321)
    devices:
      eth0:
        name: eth0
        network: lxdbr0
        type: nic
      eth1:
        nictype: bridged
        parent: brtest0
        type: nic
      root:
        path: /
        pool: default
        type: disk
    ```

Step 12: Refresh package metadata in the container.

```bash
# Refresh package metadata before installing the DHCP client needed for `eth1`.
lxc exec noble -- sudo apt-get update
```
??? example "Expected result"
    ```text
    Hit:1 http://archive.ubuntu.com/ubuntu noble InRelease
    Reading package lists... Done
    ```

Step 13: Install the DHCP client in the container.

```bash
# Install the DHCP client that will request an IPv4 lease for `eth1`.
lxc exec noble -- sudo apt-get install -y isc-dhcp-client
```
??? example "Expected result"
    ```text
    Reading package lists... Done
    Building dependency tree... Done
    The following NEW packages will be installed:
      isc-dhcp-client isc-dhcp-common
    ...
    Setting up isc-dhcp-client ...
    ```

Step 14: Request a DHCP lease on `eth1`.

```bash
# Request a DHCP lease on `eth1` so the second NIC receives an IPv4 address.
lxc exec noble -- dhclient eth1
```
??? example "Expected result"
    ```text
    Setting LLMNR support level "yes" for "20", but the global support level is "no".
    ```

The exact output can vary. The real success check is in the next step, where `lxc list` should show an IPv4 address on `eth1`.

Step 15: List instances again.

```bash
# Confirm that `noble` now shows addresses on both `eth0` and `eth1`.
lxc list
```
??? example "Expected result"
    ```text
    +-------+---------+-----------------------+-----------------------------------------------+-----------+-----------+
    | NAME  |  STATE  |         IPV4          |                     IPV6                      |   TYPE    | SNAPSHOTS |
    +-------+---------+-----------------------+-----------------------------------------------+-----------+-----------+
    | noble | RUNNING | 10.96.234.221 (eth0)  | fd42:ac23:f544:f9ac:216:3eff:fe26:d997 (eth0) | CONTAINER | 0         |
    |       |         | 10.131.118.236 (eth1) | fd42:6d0d:48bd:9e07:216:3eff:fe75:e9ab (eth1) |           |           |
    +-------+---------+-----------------------+-----------------------------------------------+-----------+-----------+
    ```

Step 16: Delete the container.

```bash
# Force-delete the noble container during cleanup.
lxc delete noble --force
```
??? example "Expected result"
    ```text
    No output.
    ```

Step 17: Remove LXD from `LABVM` when the lab is complete.

```bash
# Remove the LXD snap and its state from LABVM.
sudo snap remove lxd --purge
```
??? example "Expected result"
    ```text
    2026-04-10T09:38:49Z INFO Waiting for "snap.lxd.daemon.service" to stop.
    lxd removed
    ```

Step 18: Leave the `newgrp lxd` subshell.

```bash
# Leave the subshell started by newgrp.
exit
```
??? example "Expected result"
    ```text
    ubuntu@LABVM:~$
    ```

Step 19: Return to `LABHOST`.

```bash
# Exit the SSH session and return to LABHOST.
exit
```
??? example "Expected result"
    ```text
    logout
    Connection to 192.168.101.50 closed.
    ```

!!! pied-piper "Takeaway"
    LXD networking is profile-driven in this lab:

    - bridges such as `lxdbr0` and `brtest0` are managed by LXD
    - profiles decide which NICs instances receive
    - `lxc config show --expanded` shows the final instance configuration after profile inheritance
