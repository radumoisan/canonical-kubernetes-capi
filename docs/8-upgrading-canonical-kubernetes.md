# :material-numeric-8-circle: 8. Upgrading Canonical Kubernetes

The installed version of Kubernetes is `1.35`, which is not the latest one. In this chapter we will learn how easy
it is to upgrade the Canonical Kubernetes cluster to a newer `1.36` version with in-place upgrades.

Another option for upgrades is the rollout upgrade. This is useful whenever the cluster is built highly available. Rollout updates means there will be new machines being deployed with the new version of Kubernetes while the old ones are getting removed, one by one. Since our deployment is non-HA, in-place upgrade is the only viable option.

Before upgrading the cluster, you should also make sure:
* your cluster is running normally
* you read the Upgrade notes to see if any caveats apply to the versions you are upgrading to/from
* you read the Release notes for the version you are upgrading to, which will alert you to any important changes to the operation of your cluster
* the new version is supported by Cluster API deployment

## :material-book-open-page-variant-outline: 8.1 Rollout upgrade Kubernetes

!!! warning "Warning"
    **This is documentation only and should NOT be applied in our environments.**

The order of upgrades should be, first, control plane nodes, second, worker nodes.

### :material-application-edit-outline: Upgrade control plane nodes

First, identify the name of your control plane CRD with:

```bash
# Select the management cluster kubeconfig.
export KUBECONFIG=~/.kube/config
```
??? example "Expected result"
    No output.

```bash
# List control plane resources.
kubectl get ck8scontrolplane
```
??? example "Expected result"
    ```text
    NAME                         INITIALIZED   API SERVER AVAILABLE   VERSION   REPLICAS   READY   UPDATED   UNAVAILABLE
    myk8scluster-control-plane   true          true                   1.35.7    1          1       1
    ```

Replace the spec.version field with the new Kubernetes version.

```bash
# Edit the control plane resource.
kubectl edit ck8scontrolplane myk8scluster-control-plane
```
??? example "Expected result"
    The control plane resource opens in the editor.

```yaml
spec:
  version: v1.36.4
```

* When a control plane upgrade is performed, a new CK8sControlPlane machine is deployed with the new configuration. Only after that machine is Ready, the old machine is deprovisioned.

* This behavior is controlled by the spec value spec.strategy.rollingUpdate.maxSurge, with the default value being set on 1.

* If spec.strategy.rollingUpdate.maxSurge is set to the value 0 when a control plane upgrade is performed, the old CK8sControlPlane machine is deprovisioned first. Then a new machine is deployed with the new configuration only after the old machine has been removed.

* spec.strategy.rollingUpdate.maxSurge set to the value 0 is preferable in hardware constrained environments, where an extra machine might not be available.

Then, watch the new machines being created while the old ones get deleted:

```bash
# Select the deployed cluster kubeconfig.
export KUBECONFIG=~/.kube/myk8scluster_config
```
??? example "Expected result"
    No output.

```bash
# Watch deployed cluster nodes.
watch kubectl get nodes -o wide
```
??? example "Expected result"
    The node list refreshes while the upgrade takes place.

### :material-application-edit-outline: Upgrade worker nodes

After upgrading the control plane, proceed with upgrading the worker nodes by updating the MachineDeployment resource. The name of the resource can be found with:

```bash
# Select the management cluster kubeconfig.
export KUBECONFIG=~/.kube/config
```
??? example "Expected result"
    No output.

```bash
# List MachineDeployment resources.
kubectl get machinedeployment
```
??? example "Expected result"
    ```text
    NAME                       CLUSTER        AVAILABLE   DESIRED   CURRENT   READY   AVAILABLE   UP-TO-DATE   PHASE     AGE     VERSION
    myk8scluster-worker-md-0   myk8scluster   True        2         2         2       2           2            Running   6h43m   v1.35.7
    ```

Next, update the MachineDeployment resource to use the new Kubernetes version:

```bash
# Edit the worker MachineDeployment resource.
kubectl edit machinedeployment myk8scluster-worker-md-0
```
??? example "Expected result"
    The MachineDeployment resource opens in the editor.

```yaml
spec:
  template:
    spec:
      version: v1.36.4
```

Lastly, watch the upgrade taking place:

```bash
# Select the deployed cluster kubeconfig.
export KUBECONFIG=~/.kube/myk8scluster_config
```
??? example "Expected result"
    No output.

```bash
# Watch deployed cluster nodes.
watch kubectl get nodes -o wide
```
??? example "Expected result"
    The node list refreshes while the upgrade takes place.

And:

```bash
# Select the management cluster kubeconfig.
export KUBECONFIG=~/.kube/config
```
??? example "Expected result"
    No output.

```bash
# Get the worker MachineDeployment resource.
kubectl get machinedeployment myk8scluster-worker-md-0
```
??? example "Expected result"
    The MachineDeployment resource is displayed.

## :material-book-open-page-variant-outline: 8.2 In-place upgrades

Since our cluster is non-HA, the only option we have is to do in-place upgrades.
Let's begin by checking our current Kubernetes version:

```bash
# Select the deployed cluster kubeconfig.
export KUBECONFIG=~/.kube/myk8scluster_config
```
??? example "Expected result"
    No output.

```bash
# List deployed cluster nodes.
kubectl get nodes -o wide
```
??? example "Expected result"
    ```text
    NAME          STATUS   ROLES                  AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION              CONTAINER-RUNTIME
    k8s-ctrl      Ready    control-plane,worker   21h   v1.35.7   10.219.64.22   <none>        Ubuntu 24.04.4 LTS   6.8.0-138-generic (amd64)   containerd://2.3.3
    k8s-worker1   Ready    worker                 21h   v1.35.7   10.219.64.23   <none>        Ubuntu 24.04.4 LTS   6.8.0-138-generic (amd64)   containerd://2.3.3
    k8s-worker2   Ready    worker                 21h   v1.35.7   10.219.64.24   <none>        Ubuntu 24.04.4 LTS   6.8.0-138-generic (amd64)   containerd://2.3.3
    ```

The order of upgrades will be the same as for rolling upgrades, first, control plane nodes, then worker nodes. To achieve this, we will need to annotate machine definitions in our management cluster. To interact with it, we need to use `~/.kube/config` kubeconfig file. Let's check our machine names first:

```bash
# Select the management cluster kubeconfig.
export KUBECONFIG=~/.kube/config
```
??? example "Expected result"
    No output.

```bash
# List cluster machines.
kubectl get machines
```
??? example "Expected result"
    ```text
    NAME                                   CLUSTER        NODE NAME     FAILURE DOMAIN   READY   AVAILABLE   UP-TO-DATE   PHASE     AGE   VERSION
    myk8scluster-control-plane-qqdlb       myk8scluster   k8s-ctrl                       True    True                     Running   21h   v1.35.7
    myk8scluster-worker-md-0-nmtpp-kblvd   myk8scluster   k8s-worker2                    True    True        True         Running   21h   v1.35.7
    myk8scluster-worker-md-0-nmtpp-sdwqw   myk8scluster   k8s-worker1                    True    True        True         Running   21h   v1.35.7
    ```

Kubernetes on both control plane and worker nodes is installed from the `k8s` snap. Currently, the channel used for the `k8s` snap is `1.35-classic/stable`. As of now, there is now `1.36-classic/stable` channel for `v1.36`, but there's a `1.36-classic/candidate` channel. That's the channel we're going to use for our upgrade. There will be a `1.36-classic/stable` channel at some point in the future.

To upgrade the control plane, we need to annotate the control plane node, in our case, from the output above, `myk8scluster-control-plane-qqdlb`:

```bash
# Select the management cluster kubeconfig.
export KUBECONFIG=~/.kube/config
```
??? example "Expected result"
    No output.

```bash
# Request an in-place control plane upgrade.
kubectl annotate machine myk8scluster-control-plane-qqdlb "v1beta2.k8sd.io/in-place-upgrade-to=channel=1.36-classic/candidate"
```
??? example "Expected result"
    The machine is annotated.

You can watch the progress of the upgrade using:

```bash
# Select the management cluster kubeconfig.
export KUBECONFIG=~/.kube/config
```
??? example "Expected result"
    No output.

```bash
# Display the control plane machine definition.
kubectl get machine myk8scluster-control-plane-qqdlb -o yaml
```
??? example "Expected result"
    The control plane machine definition, including annotations, is displayed.

You'll need to watch the annotations of that machine, especially four parameters:

??? example "Expected result"
    ```text
    v1beta2.k8sd.io/in-place-upgrade-release
    v1beta2.k8sd.io/in-place-upgrade-status
    v1beta2.k8sd.io/in-place-upgrade-to
    v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at
    ```

Upon successful upgrade, you'll see:

??? example "Expected result"
    ```text
    v1beta2.k8sd.io/in-place-upgrade-release: channel=1.36-classic/candidate
    v1beta2.k8sd.io/in-place-upgrade-status: done
    ```

The other two, `v1beta2.k8sd.io/in-place-upgrade-to` and `v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at`, will not be defined. In case something goes wrong with the upgrade, you'll see something like:

??? example "Expected result"
    ```yaml
    annotations:
      # the `upgrade-to` causes the retry to happen
      v1beta2.k8sd.io/in-place-upgrade-to: "channel=1.36-classic/candidate"
      v1beta2.k8sd.io/in-place-upgrade-status: "failed"

      # orchestrator will notice this annotation and knows that the
      # upgrade for this machine failed
      v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at: "Sat, 7 Nov
      2026 13:30:00 +0400"
    ```

In that case, issue should be investigated and upgrade retried.

Next, we will upgrade the worker nodes. Based on the output above, that would be machines named `myk8scluster-worker-md-0-nmtpp-kblvd` and `myk8scluster-worker-md-0-nmtpp-sdwqw`. So, let's annotate those, as well:

```bash
# Select the management cluster kubeconfig.
export KUBECONFIG=~/.kube/config
```
??? example "Expected result"
    No output.

```bash
# Request an in-place upgrade for the first worker.
kubectl annotate machine myk8scluster-worker-md-0-nmtpp-kblvd "v1beta2.k8sd.io/in-place-upgrade-to=channel=1.36-classic/candidate"
```
??? example "Expected result"
    The machine is annotated.

```bash
# Request an in-place upgrade for the second worker.
kubectl annotate machine myk8scluster-worker-md-0-nmtpp-sdwqw "v1beta2.k8sd.io/in-place-upgrade-to=channel=1.36-classic/candidate"
```
??? example "Expected result"
    The machine is annotated.

You can watch the progress of the upgrade using:

```bash
# Select the management cluster kubeconfig.
export KUBECONFIG=~/.kube/config
```
??? example "Expected result"
    No output.

```bash
# Display the first worker machine definition.
kubectl get machine myk8scluster-worker-md-0-nmtpp-kblvd -o yaml
```
??? example "Expected result"
    The first worker machine definition, including annotations, is displayed.

```bash
# Display the second worker machine definition.
kubectl get machine myk8scluster-worker-md-0-nmtpp-sdwqw -o yaml
```
??? example "Expected result"
    The second worker machine definition, including annotations, is displayed.

You'll need to watch the annotations of those machines, especially four parameters:

??? example "Expected result"
    ```text
    v1beta2.k8sd.io/in-place-upgrade-release
    v1beta2.k8sd.io/in-place-upgrade-status
    v1beta2.k8sd.io/in-place-upgrade-to
    v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at
    ```

Upon successful upgrade, you'll see:

??? example "Expected result"
    ```text
    v1beta2.k8sd.io/in-place-upgrade-release: channel=1.36-classic/candidate
    v1beta2.k8sd.io/in-place-upgrade-status: done
    ```

After the upgrade is done, you can verify the version of the k8s cluster on all nodes with:

```bash
# Select the deployed cluster kubeconfig.
export KUBECONFIG=~/.kube/myk8scluster_config
```
??? example "Expected result"
    No output.

```bash
# List deployed cluster nodes.
kubectl get nodes -o wide
```
??? example "Expected result"
    ```text
    NAME          STATUS   ROLES                  AGE   VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION              CONTAINER-RUNTIME
    k8s-ctrl      Ready    control-plane,worker   21h   v1.36.4   10.219.64.22   <none>        Ubuntu 24.04.4 LTS   6.8.0-138-generic (amd64)   containerd://2.3.3
    k8s-worker1   Ready    worker                 21h   v1.36.4   10.219.64.23   <none>        Ubuntu 24.04.4 LTS   6.8.0-138-generic (amd64)   containerd://2.3.3
    k8s-worker2   Ready    worker                 21h   v1.36.4   10.219.64.24   <none>        Ubuntu 24.04.4 LTS   6.8.0-138-generic (amd64)   containerd://2.3.3
    ```

As you can see, cluster nodes got updated to `v1.36.4` which is now the latest version available from the `1.36-classic/candidate` channel.
Since this was an in-place upgrade, not rolling, neither `ck8scontrolplane` or `machinedeployment` specs haven't been changed. That means, from the management cluster's point of view, it will still show the old version:

```bash
# Select the management cluster kubeconfig.
export KUBECONFIG=~/.kube/config
```
??? example "Expected result"
    No output.

```bash
# List cluster machines.
kubectl get machines
```
??? example "Expected result"
    ```text
    NAME                                   CLUSTER        NODE NAME     FAILURE DOMAIN   READY   AVAILABLE   UP-TO-DATE   PHASE     AGE   VERSION
    myk8scluster-control-plane-qqdlb       myk8scluster   k8s-ctrl                       True    True                     Running   21h   v1.35.7
    myk8scluster-worker-md-0-nmtpp-kblvd   myk8scluster   k8s-worker2                    True    True        True         Running   21h   v1.35.7
    myk8scluster-worker-md-0-nmtpp-sdwqw   myk8scluster   k8s-worker1                    True    True        True         Running   21h   v1.35.7
    ```

If your infrastructure is built highly available, it is recommended to use rolling upgrades instead of in-place upgrades.

More details here:
[https://documentation.ubuntu.com/canonical-kubernetes/release-1.35/capi/howto/rollout-upgrades/](https://documentation.ubuntu.com/canonical-kubernetes/release-1.35/capi/howto/rollout-upgrades/)
[https://documentation.ubuntu.com/canonical-kubernetes/release-1.35/capi/howto/in-place-upgrades/](https://documentation.ubuntu.com/canonical-kubernetes/release-1.35/capi/howto/in-place-upgrades/)
[https://documentation.ubuntu.com/canonical-kubernetes/release-1.35/capi/reference/annotations/](https://documentation.ubuntu.com/canonical-kubernetes/release-1.35/capi/reference/annotations/)
