# Advanced Snap Packaging

In this chapter, you will:

- understand Snap confinement and security models
- manage channels and release tracking for snaps
- use advanced snap commands to inspect and manage packages

!!! note
    Snap is Canonical's universal packaging system for Linux. On Ubuntu, it is used to deliver applications with built-in dependencies, confinement, and transactional updates.

Quick refresher:

| Command | Description |
| - | - |
| `snap install <package>` | Install a snap package |
| `snap find <term>` | Search for available snaps |
| `snap list` | List installed snaps |
| `snap refresh <package>` | Update a snap |
| `snap remove <package>` | Remove an installed snap |

Snaps are self-contained application bundles with their dependencies included. Compared to traditional packages, they are confined by default, transactional, and channel-aware.

## :material-book-open-page-variant-outline: 10.1 Snap Internals and Confinement

Snaps are designed to run consistently across Linux distributions. Their packaging model also makes it easier to isolate applications from the rest of the system.

### :material-application-edit-outline: Confinement Levels

A snap's confinement level answers one question: how isolated is this snap from the host system?

The quickest way to remember the three levels is:

- `strict` = sandboxed and enforced
- `classic` = basically unconfined, like a traditional package
- `devmode` = built like strict, but violations are logged instead of blocked

**Strict**

This is the default for most snaps. Strict snaps run sandboxed with AppArmor, seccomp, cgroups, and namespaces. They can only access extra resources through approved interfaces.

**Classic**

Classic confinement gives a snap broad access to system resources, closer to traditional packages. Installing a classic snap requires the `--classic` flag.

**Devmode**

Devmode is mainly for development and debugging. It is built around the strict model, but confinement violations are logged instead of blocked. Installing a devmode snap requires the `--devmode` flag.

To check a snap's confinement mode:

```bash
# Show the confinement mode for hello-world.
snap info --verbose hello-world | grep confinement
```
??? quote "Reference output"
    ```text
    confinement: strict
    ```

### :material-application-edit-outline: Interfaces and Connections

Interfaces are how snaps request access to external resources such as the network, the home directory, or removable media. Connections are the active bindings that make that access available.

The simple way to remember this is:

- interface = requested capability
- connection = granted capability

Common examples:

| Interface | Grants access to |
| - | - |
| `home` | Files in the user's home directory |
| `desktop` | Desktop-related access |
| `network` | Outbound network access |
| `network-bind` | Listening on network ports |
| `system-observe` | System process and service information |
| `removable-media` | USB and other external media |

To inspect the interfaces a snap uses:

```bash
# Show the interfaces connected to the lxd snap.
snap connections lxd
```
??? quote "Reference output"
    ```text
    Interface       Plug                Slot             Notes
    lxd             juju:lxd            lxd:lxd          -
    network         lxd:network         :network         -
    network-bind    lxd:network-bind    :network-bind    -
    ...
    ```

!!! pied-piper "Takeaway"
    The key snap security idea is confinement. Most snaps run strictly confined and gain extra access only through explicit interfaces.

## :material-book-open-page-variant-outline: 10.2 Snap Channels and Releases

Channels define which release stream a snap follows for updates. The default is usually `stable`, but you can install or refresh a snap to another channel when you need newer builds.

The four standard risk levels are:

- `stable`: recommended for production use
- `candidate`: release candidate builds
- `beta`: early testing builds
- `edge`: newest and riskiest builds

To inspect available channels for a snap:

```bash
# Show channel information for firefox.
snap info firefox
```
??? quote "Reference output"
    ```text
    channels:
      latest/stable:    ...
      latest/candidate: ...
      latest/beta:      ...
      latest/edge:      ...
    ```

To install from a specific channel:

```bash
# Install firefox from the beta channel.
sudo snap install firefox --channel=latest/beta
```
??? quote "Reference output"
    ```text
    firefox (beta) ... installed
    ```

To switch an already installed snap to another channel:

```bash
# Move firefox back to the stable channel.
sudo snap refresh firefox --channel=latest/stable
```
??? quote "Reference output"
    ```text
    firefox ... refreshed
    ```

!!! pied-piper "Takeaway"
    Channels are how snaps balance stability and freshness. Use `stable` by default, and switch to `beta` or `edge` only when you need newer builds and accept more risk.

## :material-book-open-page-variant-outline: 10.3 Advanced Snap Lab

Run this lab on `LABVM`.

!!! info
    Use Firefox as the example snap for the full workflow. By the end of the lab, confirm that you can find it, inspect its channels, install it, verify the installed command path and version, switch channels, inspect interfaces and refresh state, and remove it cleanly.

This lab focuses on the practical snap workflow: search, inspect channels, install, switch channels, inspect interfaces, review refresh behavior, and clean up.

!!! note
    If your lab machine is headless, use `firefox --version` and `which firefox` as the main verification commands. They let you inspect the installed snap without starting a graphical session.

Step 1: Make sure `snapd` is installed.

```bash
# Refresh package metadata.
sudo apt update
```
??? example "Expected result"
    ```text
    Hit:1 ...
    Reading package lists... Done
    ```

```bash
# Install snapd.
sudo apt install -y snapd
```
??? example "Expected result"
    ```text
    snapd is already the newest version (...)
    ```

Step 2: Search for the `firefox` snap.

```bash
# Search for firefox in the Snap Store.
snap find firefox
```
??? example "Expected result"
    ```text
    Name     Version   Publisher  Notes  Summary
    firefox  ...       mozilla*          Mozilla Firefox web browser
    ```

This confirms that the snap exists in the Snap Store and shows the publisher you are about to inspect and install.

Step 3: Review available channel information.

```bash
# Show detailed snap information for firefox.
snap info --verbose firefox
```
??? example "Expected result"
    ```text
    channels:
      latest/stable: ...
      latest/beta:   ...
      latest/edge:   ...
    ```

Focus on the `channels:` table. This is the command that shows which release streams are available before you choose one.

Step 4: Install Firefox from the stable channel.

```bash
# Install firefox from latest/stable.
sudo snap install --channel=latest/stable firefox
```
??? example "Expected result"
    ```text
    firefox ... installed
    ```

```bash
# Show the installed Firefox version.
firefox --version
```
??? example "Expected result"
    ```text
    Mozilla Firefox ...
    ```

On a headless VM, Firefox may print extra library or desktop-integration warnings before the version string. The version line is the main success signal.

```bash
# Show where the firefox command comes from.
which firefox
```
??? example "Expected result"
    ```text
    /snap/bin/firefox
    ```

This confirms that the command is being launched from the snap-managed path rather than from a traditional package location such as `/usr/bin`.

Step 5: Switch Firefox to a different channel.

```bash
# Refresh firefox to the edge channel.
sudo snap refresh firefox --channel=latest/edge
```
??? example "Expected result"
    ```text
    firefox (...) refreshed
    ```

This command changes the tracking channel for the installed snap. The refresh message is the main confirmation that snapd accepted the move to `latest/edge`.

Step 6: Confirm Firefox still runs after the channel change.

```bash
# Show the Firefox version after the channel change.
firefox --version
```
??? example "Expected result"
    ```text
    Mozilla Firefox ...
    ```

The same headless warnings may appear here as well.

Use this step to confirm that the installed command still works after the channel switch. The exact version may or may not change immediately, depending on which revisions are currently published.

Step 7: Check whether snaps have pending refreshes.

```bash
# List snaps with refreshes available.
sudo snap refresh --list
```
??? example "Expected result"
    ```text
    All snaps up to date.
    ```

If updates are pending, this command lists them instead.

!!! note
    This step is informational. Success means the command completes and either reports `All snaps up to date.` or lists the snaps waiting for refresh.

Step 8: Review Firefox interface connections.

```bash
# Show firefox interface connections.
snap connections firefox
```
??? example "Expected result"
    ```text
    Interface       Plug                Slot             Notes
    network         firefox:network     :network         -
    network-bind    firefox:network-bind :network-bind   -
    ...
    ```

Focus on the `firefox:` plugs and the connected system slots. The exact list can vary by snap revision and system configuration.

Step 9: Hold Firefox refreshes.

Holding can be indefinite or time-based. In this lab, the hold is indefinite until you remove it.

```bash
# Hold refreshes for firefox.
sudo snap refresh --hold firefox
```
??? example "Expected result"
    ```text
    General refreshes of "firefox" held indefinitely
    ```

```bash
# Confirm the snap state.
snap list
```
??? example "Expected result"
    ```text
    Name      Version  Rev  Tracking      Publisher  Notes
    firefox   ...      ...  latest/edge   mozilla*   held
    ```

The `held` note is the main success signal here. The `Tracking` column should still reflect the channel you selected earlier, such as `latest/edge`.

Step 10: Optional: Review snap-managed services.

```bash
# Show snap services.
sudo snap services
```
??? example "Expected result"
    ```text
    Service   Startup  Current  Notes
    canonical-livepatch.canonical-livepatchd  enabled   active    -
    lxd.daemon                                enabled   inactive  socket-activated
    ...
    ```

The listed services depend on which snaps are installed. This step is a broader snapd observation, not a Firefox-specific check, and it shows that some snaps also manage background services.

Success here means the command returns a service table, even if Firefox itself does not provide a background service.

Step 11: Review snap mount points.

```bash
# Show squashfs mounts used by snaps.
sudo mount -t squashfs | grep snap
```
??? example "Expected result"
    ```text
    /var/lib/snapd/snaps/... on /snap/... type squashfs (...)
    ```

Look for mounts from `/var/lib/snapd/snaps/` to `/snap/...` with filesystem type `squashfs`. That is the main confirmation that snaps are mounted read-only from snap image files.

Step 12: Clean up.

```bash
# Remove the hold on firefox refreshes.
sudo snap refresh --unhold firefox
```
??? example "Expected result"
    ```text
    Removed general refresh hold of "firefox"
    ```

```bash
# Remove the firefox snap.
sudo snap remove firefox
```
??? example "Expected result"
    ```text
    firefox removed (snap data snapshot saved)
    ```

!!! pied-piper "Takeaway"
    The practical snap workflow is: inspect the package, choose the right channel, verify where it is installed from, review its interfaces, control refresh behavior when needed, and clean up deliberately.
