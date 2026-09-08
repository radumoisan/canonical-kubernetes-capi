# 8. Upgrading Canonical Kubernetes !heading

The cluster currently runs Kubernetes `1.35`. In this chapter, you will upgrade it to Kubernetes `1.36` by using an
in-place upgrade.

Canonical Kubernetes also supports rollout upgrades. During a rollout, CAPI creates machines that run the target
Kubernetes version and removes the old machines one at a time. Rollout upgrades are recommended for highly available
clusters. This lab uses an in-place upgrade because its control plane is not highly available.

Before upgrading, make sure that:

* the cluster is healthy
* you have reviewed the upgrade notes for the installed and target versions
* you have read the release notes for the target version
* the target version is supported by the Canonical Kubernetes CAPI provider


## 8.1 Rollout upgrade Kubernetes

**This section is for reference only. Do not run these commands in the lab environment.**

Upgrade the control plane before the worker nodes.

### Upgrade control plane nodes

First, identify the control plane resource:

```bash
# interact with the management cluster, not deployed cluster
export KUBECONFIG=~/.kube/config
kubectl get ck8scontrolplane

# output
NAME                         INITIALIZED   API SERVER AVAILABLE   VERSION   REPLICAS   READY   UPDATED   UNAVAILABLE
myk8scluster-control-plane   true          true                   1.35.7    1          1       1
```

Update `spec.version` to the target Kubernetes version:

```bash
kubectl edit ck8scontrolplane myk8scluster-control-plane
```

```yaml
spec:
  version: v1.36.4
```

* When a control plane rollout begins, CAPI creates a replacement control plane `Machine` with the new configuration.
  It deprovisions the old machine only after the replacement is ready.

* `spec.strategy.rollingUpdate.maxSurge` controls how many extra control plane machines can be created during the
  rollout. It defaults to `1`.

* When `spec.strategy.rollingUpdate.maxSurge` is `0`, CAPI deprovisions the old control plane `Machine` before creating
  its replacement.

* Setting it to `0` avoids the temporary capacity required for an extra machine, but reduces availability. A
  single-replica control plane will be unavailable during replacement.

Switch to the deployed cluster and watch the nodes while CAPI creates replacements and removes the old machines:

```bash
export KUBECONFIG=~/.kube/myk8scluster_config
watch kubectl get nodes -o wide
```

### Upgrade worker nodes

After upgrading the control plane, update the worker `MachineDeployment`. First, identify its name:


```bash
# interact with the management cluster, not deployed cluster
export KUBECONFIG=~/.kube/config
kubectl get machinedeployment

# output
NAME                       CLUSTER        AVAILABLE   DESIRED   CURRENT   READY   AVAILABLE   UP-TO-DATE   PHASE     AGE     VERSION
myk8scluster-worker-md-0   myk8scluster   True        2         2         2       2           2            Running   6h43m   v1.35.7
```

Update `spec.template.spec.version` to the target Kubernetes version:

```bash
kubectl edit machinedeployment myk8scluster-worker-md-0
```

```yaml
spec:
  template:
    spec:
      version: v1.36.4
```

Watch the worker nodes as CAPI replaces them:

```bash
export KUBECONFIG=~/.kube/myk8scluster_config
watch kubectl get nodes -o wide
```

Stop `watch` with Ctrl+C, switch back to the management cluster, and confirm the `MachineDeployment` status:

```bash
export KUBECONFIG=~/.kube/config
kubectl get machinedeployment myk8scluster-worker-md-0
```

## 8.2 In-place upgrades

The lab cluster has a single control plane node, so you will use an in-place upgrade to update the existing machines
without replacing them. Begin by checking the current Kubernetes version:

```bash
export KUBECONFIG=~/.kube/myk8scluster_config
kubectl get nodes -o wide

# output
NAME          STATUS   ROLES                  AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION              CONTAINER-RUNTIME
k8s-ctrl      Ready    control-plane,worker   21h   v1.35.7   10.219.64.22   <none>        Ubuntu 24.04.4 LTS   6.8.0-138-generic (amd64)   containerd://2.3.3
k8s-worker1   Ready    worker                 21h   v1.35.7   10.219.64.23   <none>        Ubuntu 24.04.4 LTS   6.8.0-138-generic (amd64)   containerd://2.3.3
k8s-worker2   Ready    worker                 21h   v1.35.7   10.219.64.24   <none>        Ubuntu 24.04.4 LTS   6.8.0-138-generic (amd64)   containerd://2.3.3
```

As with a rollout upgrade, upgrade the control plane before the worker nodes. Request an in-place upgrade by annotating
the corresponding `Machine` resources in the management cluster. Select the management cluster kubeconfig and list the
machine names:

```bash
export KUBECONFIG=~/.kube/config
kubectl get machines

# output
NAME                                   CLUSTER        NODE NAME     FAILURE DOMAIN   READY   AVAILABLE   UP-TO-DATE   PHASE     AGE   VERSION
myk8scluster-control-plane-qqdlb       myk8scluster   k8s-ctrl                       True    True                     Running   21h   v1.35.7
myk8scluster-worker-md-0-nmtpp-kblvd   myk8scluster   k8s-worker2                    True    True        True         Running   21h   v1.35.7
myk8scluster-worker-md-0-nmtpp-sdwqw   myk8scluster   k8s-worker1                    True    True        True         Running   21h   v1.35.7
```

Canonical Kubernetes is installed from the `k8s` snap on the control plane and worker nodes. The nodes currently track
the `1.35-classic/stable` channel. At the time of this lab, a `1.36-classic/stable` channel is not available, so the
upgrade targets `1.36-classic/candidate`.

To upgrade the control plane, annotate its `Machine` resource. From the output above, its name is
`myk8scluster-control-plane-qqdlb`:

```bash
export KUBECONFIG=~/.kube/config
kubectl annotate machine myk8scluster-control-plane-qqdlb "v1beta2.k8sd.io/in-place-upgrade-to=channel=1.36-classic/candidate"
```

Inspect the upgrade progress by displaying the `Machine` resource:

```bash
export KUBECONFIG=~/.kube/config
kubectl get machine myk8scluster-control-plane-qqdlb -o yaml
```

The upgrade controller reports progress through these four annotation keys:

```bash
v1beta2.k8sd.io/in-place-upgrade-release
v1beta2.k8sd.io/in-place-upgrade-status
v1beta2.k8sd.io/in-place-upgrade-to
v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at
```

After a successful upgrade, the release annotation records the target channel and the status is `done`:

```bash
v1beta2.k8sd.io/in-place-upgrade-release: channel=1.36-classic/candidate
v1beta2.k8sd.io/in-place-upgrade-status: done
```

The `v1beta2.k8sd.io/in-place-upgrade-to` and
`v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at` annotations should be absent after a successful upgrade. A
failed attempt resembles:

```bash
annotations:
  # the `upgrade-to` causes the retry to happen
  v1beta2.k8sd.io/in-place-upgrade-to: "channel=1.36-classic/candidate"
  v1beta2.k8sd.io/in-place-upgrade-status: "failed"

  # orchestrator will notice this annotation and knows that the 
  # upgrade for this machine failed
  v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at: "Sat, 7 Nov 
  2026 13:30:00 +0400"
```

In that case, investigate the failure before retrying the upgrade.

Next, upgrade the worker nodes. Based on the output above, their `Machine` resources are
`myk8scluster-worker-md-0-nmtpp-kblvd` and `myk8scluster-worker-md-0-nmtpp-sdwqw`. Annotate both resources:

```bash
export KUBECONFIG=~/.kube/config
kubectl annotate machine myk8scluster-worker-md-0-nmtpp-kblvd "v1beta2.k8sd.io/in-place-upgrade-to=channel=1.36-classic/candidate"
kubectl annotate machine myk8scluster-worker-md-0-nmtpp-sdwqw "v1beta2.k8sd.io/in-place-upgrade-to=channel=1.36-classic/candidate"
```

Inspect the upgrade progress by displaying both `Machine` resources:

```bash
export KUBECONFIG=~/.kube/config
kubectl get machine myk8scluster-worker-md-0-nmtpp-kblvd -o yaml
kubectl get machine myk8scluster-worker-md-0-nmtpp-sdwqw -o yaml
```

Check the same four annotation keys on both machines:

```bash
v1beta2.k8sd.io/in-place-upgrade-release
v1beta2.k8sd.io/in-place-upgrade-status
v1beta2.k8sd.io/in-place-upgrade-to
v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at
```

After each successful upgrade, the release annotation records the target channel and the status is `done`:

```bash
v1beta2.k8sd.io/in-place-upgrade-release: channel=1.36-classic/candidate
v1beta2.k8sd.io/in-place-upgrade-status: done
```

After the upgrades finish, verify the Kubernetes version reported by every node:

```bash
export KUBECONFIG=~/.kube/myk8scluster_config
kubectl get nodes -o wide

# output
NAME          STATUS   ROLES                  AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION              CONTAINER-RUNTIME
k8s-ctrl      Ready    control-plane,worker   21h   v1.36.4   10.219.64.22   <none>        Ubuntu 24.04.4 LTS   6.8.0-138-generic (amd64)   containerd://2.3.3
k8s-worker1   Ready    worker                 21h   v1.36.4   10.219.64.23   <none>        Ubuntu 24.04.4 LTS   6.8.0-138-generic (amd64)   containerd://2.3.3
k8s-worker2   Ready    worker                 21h   v1.36.4   10.219.64.24   <none>        Ubuntu 24.04.4 LTS   6.8.0-138-generic (amd64)   containerd://2.3.3
```

All nodes now report `v1.36.4` from the target `1.36-classic/candidate` channel. An in-place upgrade changes the
Kubernetes software on the existing nodes, but does not update the version fields in the `CK8sControlPlane` or
`MachineDeployment` specifications. Their `Machine` resources therefore continue to report the old declarative
version:

```bash
export KUBECONFIG=~/.kube/config
kubectl get machines
NAME                                   CLUSTER        NODE NAME     FAILURE DOMAIN   READY   AVAILABLE   UP-TO-DATE   PHASE     AGE   VERSION
myk8scluster-control-plane-qqdlb       myk8scluster   k8s-ctrl                       True    True                     Running   21h   v1.35.7
myk8scluster-worker-md-0-nmtpp-kblvd   myk8scluster   k8s-worker2                    True    True        True         Running   21h   v1.35.7
myk8scluster-worker-md-0-nmtpp-sdwqw   myk8scluster   k8s-worker1                    True    True        True         Running   21h   v1.35.7
```

For a highly available cluster, prefer rollout upgrades so that CAPI manages the target version through its declarative
specifications.

For more information, see:
[https://documentation.ubuntu.com/canonical-kubernetes/release-1.35/capi/howto/rollout-upgrades/](https://documentation.ubuntu.com/canonical-kubernetes/release-1.35/capi/howto/rollout-upgrades/)
[https://documentation.ubuntu.com/canonical-kubernetes/release-1.35/capi/howto/in-place-upgrades/](https://documentation.ubuntu.com/canonical-kubernetes/release-1.35/capi/howto/in-place-upgrades/)
[https://documentation.ubuntu.com/canonical-kubernetes/release-1.35/capi/reference/annotations/](https://documentation.ubuntu.com/canonical-kubernetes/release-1.35/capi/reference/annotations/)
