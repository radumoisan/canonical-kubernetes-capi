# 8. Upgrading Canonical Kubernetes

This chapter upgrades the existing Canonical Kubernetes workload cluster from Kubernetes `1.35` to `1.36`. The lab uses
an in-place upgrade because its single control plane is not highly available.

!!! abstract "Lab goals"
    - Compare rollout and in-place Kubernetes upgrades.
    - Verify both clusters and discover the current target build.
    - Upgrade the control plane before the workers.
    - Upgrade workers sequentially with bounded monitoring.
    - Verify runtime versions, CAPI status, and the expected declarative-version difference.

!!! note "Validated versions"
    This workflow was validated with CAPI `v1.13.5`, Canonical Kubernetes CAPI provider `v0.6.2`, source version
    `v1.35.7`, and `1.36-classic/candidate` at `v1.36.4`. The candidate channel moves, so discover its current patch
    version before starting the upgrade.

!!! note "Expected results"
    Generated Machine names, ages, addresses, and future channel versions may differ. Tabular results are representative
    excerpts and omit unrelated dynamic columns.

!!! note "Unattended execution"
    Machine discovery, upgrade monitoring, VM restart recovery, and health checks have explicit bounds. The workflow does
    not use an editor, `watch`, a second terminal, or manual interruption.

!!! danger "No automatic rollback"
    An in-place upgrade changes Kubernetes on the existing machines. It has no generic automatic rollback. Stop after any
    failed or timed-out control-plane or worker upgrade, collect diagnostics, and investigate before retrying.

!!! warning "Review compatibility before execution"
    Review the [source upgrade notes](https://documentation.ubuntu.com/canonical-kubernetes/release-1.35/snap/reference/upgrading/),
    [Canonical Kubernetes 1.36 release notes](https://documentation.ubuntu.com/canonical-kubernetes/latest/releases/snap/1.36),
    and the target provider's supported versions before changing a Machine. Canonical Kubernetes 1.36 removes the
    `k8s-dqlite` datastore and blocks upgrades that still use it. This lab was approved and validated with the versions
    listed above and an `etcd` workload datastore; stop if the discovered environment differs.

## :material-book-open-page-variant-outline: 8.1 Rollout upgrades (reference only)

!!! warning "Reference only"
    Do not run this section in the lab environment. Rollout upgrades are recommended for highly available clusters; this
    lab has one control-plane machine. Section 8.2 contains the validated exercise.

A rollout changes the declarative CAPI version. CAPI creates machines at the target version and removes old machines after
their replacements become ready. Always upgrade the control plane before workers.

### :material-application-edit-outline: Upgrade control plane nodes

Select the management-cluster kubeconfig:

```bash
# Select the management-cluster kubeconfig.
export KUBECONFIG="$HOME/.kube/config"
```

??? example "Expected result"
    ```text
    No output.
    ```

Display the control-plane resource:

```bash
# Display the control-plane resource.
kubectl get ck8scontrolplane
```

??? example "Expected result"
    ```text
    NAME                         INITIALIZED   API SERVER AVAILABLE   VERSION   REPLICAS   READY   UPDATED
    myk8scluster-control-plane   true          true                   1.35.7    1          1       1
    ```

In a highly available environment, patch `spec.version` without opening an editor:

```bash
# Set the rollout target version on the control plane.
kubectl patch ck8scontrolplane myk8scluster-control-plane --type=merge -p '{"spec":{"version":"v1.36.4"}}'
```

??? example "Expected result"
    ```text
    ck8scontrolplane.controlplane.cluster.x-k8s.io/myk8scluster-control-plane patched
    ```

`spec.strategy.rollingUpdate.maxSurge` defaults to `1`. CAPI normally creates a replacement before deleting the old
control-plane Machine. Setting `maxSurge` to `0` removes the old Machine first and makes a single-replica control plane
unavailable during replacement.

Replace an interactive watch with a bounded rollout check:

```bash
# Wait for the control-plane rollout to report the target version and readiness.
timeout 3600s bash -c '
  until [[
    "$(kubectl get ck8scontrolplane myk8scluster-control-plane \
      -o jsonpath="{.status.version}")" == "v1.36.4" &&
    "$(kubectl get ck8scontrolplane myk8scluster-control-plane \
      -o jsonpath="{.status.readyReplicas}")" == "$(kubectl get \
        ck8scontrolplane myk8scluster-control-plane \
        -o jsonpath="{.spec.replicas}")"
  ]]; do
    sleep 15
  done
'
```

??? example "Expected result"
    ```text
    No output.
    ```

### :material-application-edit-outline: Upgrade worker nodes

Identify the worker MachineDeployment:

```bash
# Display the worker MachineDeployment.
kubectl get machinedeployment
```

??? example "Expected result"
    ```text
    NAME                       CLUSTER        AVAILABLE   DESIRED   READY   PHASE     VERSION
    myk8scluster-worker-md-0   myk8scluster   True        2         2       Running   v1.35.7
    ```

Patch the worker template only after the control-plane rollout succeeds:

```bash
# Set the rollout target version on the worker MachineDeployment.
kubectl patch machinedeployment myk8scluster-worker-md-0 --type=merge -p '{"spec":{"template":{"spec":{"version":"v1.36.4"}}}}'
```

??? example "Expected result"
    ```text
    machinedeployment.cluster.x-k8s.io/myk8scluster-worker-md-0 patched
    ```

Wait for the worker rollout without `watch`:

```bash
# Wait for all worker replicas to become ready at the target version.
timeout 3600s bash -c '
  while true; do
    desired=$(kubectl get machinedeployment myk8scluster-worker-md-0 \
      -o jsonpath="{.spec.replicas}")
    ready=$(kubectl get machinedeployment myk8scluster-worker-md-0 \
      -o jsonpath="{.status.readyReplicas}")
    if [[ "$ready" == "$desired" ]] &&
      kubectl get machines \
        -l cluster.x-k8s.io/deployment-name=myk8scluster-worker-md-0 \
        -o json |
        jq -e \
          --arg version "v1.36.4" \
          --argjson desired "$desired" \
          "(.items | length) == \$desired and
            all(.items[];
              .spec.version == \$version and
              ([.status.conditions[] | select(.type == \"Ready\")][0].status == \"True\")
            )" >/dev/null
    then
      exit 0
    fi
    sleep 15
  done
'
```

??? example "Expected result"
    ```text
    No output.
    ```

## :material-book-open-page-variant-outline: 8.2 In-place upgrades

The in-place controller refreshes the `k8s` snap on each existing machine. Upgrade and verify one machine at a time,
starting with the control plane.

### :material-application-edit-outline: Preflight checks

Confirm that both kubeconfigs are readable:

```bash
# Verify the management and workload kubeconfigs.
test -r "$HOME/.kube/config" && test -r "$HOME/.kube/myk8scluster_config" && printf "Both kubeconfigs are readable\n"
```

??? example "Expected result"
    ```text
    Both kubeconfigs are readable
    ```

Confirm both contexts explicitly so commands cannot target the wrong cluster:

```bash
# Display the management and workload contexts.
kubectl --kubeconfig="$HOME/.kube/config" config current-context &&
  kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" config current-context
```

??? example "Expected result"
    ```text
    k8s
    myk8scluster-admin@myk8scluster
    ```

Display the management node:

```bash
# Display the management-cluster node.
kubectl --kubeconfig="$HOME/.kube/config" get nodes -o wide
```

??? example "Expected result"
    ```text
    NAME           STATUS   ROLES                  VERSION   INTERNAL-IP
    cluster-ctrl   Ready    control-plane,worker   v1.35.7   10.107.242.61
    ```

Display the workload nodes and source version:

```bash
# Display the workload-cluster nodes before upgrading.
kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get nodes -o wide
```

??? example "Expected result"
    ```text
    NAME          STATUS   ROLES                  VERSION   INTERNAL-IP
    k8s-ctrl      Ready    control-plane,worker   v1.35.7   10.107.242.62
    k8s-worker1   Ready    worker                 v1.35.7   10.107.242.63
    k8s-worker2   Ready    worker                 v1.35.7   10.107.242.64
    ```

Confirm that the workload control plane uses the supported `etcd` datastore:

```bash
# Verify the workload control-plane datastore.
test "$(lxc exec k8s-ctrl -- snap services k8s |
  awk '$1 == "k8s.etcd" { print $3 }')" = "active" &&
  printf "The workload control plane uses the supported etcd datastore\n"
```

??? example "Expected result"
    ```text
    The workload control plane uses the supported etcd datastore
    ```

Verify the management API server:

```bash
# Verify management API readiness.
kubectl --kubeconfig="$HOME/.kube/config" get --raw="/readyz"
```

??? example "Expected result"
    ```text
    ok
    ```

Verify the workload API server:

```bash
# Verify workload API readiness.
kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get --raw="/readyz"
```

??? example "Expected result"
    ```text
    ok
    ```

Display the installed provider images and versions:

```bash
# Display management-cluster controller images.
kubectl --kubeconfig="$HOME/.kube/config" get deployments -A \
  -o 'custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,IMAGE:.spec.template.spec.containers[*].image' \
  --no-headers
```

??? example "Expected result"
    ```text
    cabpck-system    cabpck-bootstrap-controller-manager   ghcr.io/canonical/cluster-api-k8s/bootstrap-controller:v0.6.2,...
    cacpck-system    cacpck-controller-manager             ghcr.io/canonical/cluster-api-k8s/controlplane-controller:v0.6.2
    capi-system      capi-controller-manager               registry.k8s.io/cluster-api/cluster-api-controller:v1.13.5
    capmaas-system   capmaas-controller-manager            .../cluster-api-provider-maas-controller:v0.9.0,...
    ```

Enforce the provider versions used for this validated upgrade:

```bash
# Require the validated CAPI provider versions.
kubectl --kubeconfig="$HOME/.kube/config" get deployments -A -o json |
  jq -e '
    any(
      .items[];
      .metadata.namespace == "cabpck-system" and
        any(.spec.template.spec.containers[]; .image | endswith(":v0.6.2"))
    ) and
    any(
      .items[];
      .metadata.namespace == "cacpck-system" and
        any(.spec.template.spec.containers[]; .image | endswith(":v0.6.2"))
    ) and
    any(
      .items[];
      .metadata.namespace == "capi-system" and
        any(.spec.template.spec.containers[]; .image | endswith(":v1.13.5"))
    ) and
    any(
      .items[];
      .metadata.namespace == "capmaas-system" and
        any(.spec.template.spec.containers[]; .image | endswith(":v0.9.0"))
    )
  ' >/dev/null &&
  printf "Validated CAPI provider versions are installed\n"
```

??? example "Expected result"
    ```text
    Validated CAPI provider versions are installed
    ```

Confirm the expected CAPI topology:

```bash
# Display the cluster, control plane, worker deployment, and Machines.
kubectl --kubeconfig="$HOME/.kube/config" get clusters,ck8scontrolplanes,machinedeployments,machines
```

??? example "Expected result"
    ```text
    NAME                                   AVAILABLE   CP DESIRED   W DESIRED   PHASE
    cluster.cluster.x-k8s.io/myk8scluster  True        1            2           Provisioned

    NAME                                                                        VERSION   REPLICAS   READY
    ck8scontrolplane.controlplane.cluster.x-k8s.io/myk8scluster-control-plane   1.35.7    1          1

    NAME                                                          DESIRED   READY   PHASE     VERSION
    machinedeployment.cluster.x-k8s.io/myk8scluster-worker-md-0   2         2       Running   v1.35.7

    NAME                                                            NODE NAME     READY   PHASE     VERSION
    machine.cluster.x-k8s.io/myk8scluster-control-plane-cvgdl       k8s-ctrl      True    Running   v1.35.7
    machine.cluster.x-k8s.io/myk8scluster-worker-md-0-m8bgf-rjszd   k8s-worker1   True    Running   v1.35.7
    machine.cluster.x-k8s.io/myk8scluster-worker-md-0-m8bgf-sxbrk   k8s-worker2   True    Running   v1.35.7
    ```

Verify management-cluster Pod health:

```bash
# Verify management-cluster Pod health.
kubectl --kubeconfig="$HOME/.kube/config" get pods -A -o json |
  jq -e '
    all(
      .items[];
      .status.phase == "Succeeded" or
        (
          .status.phase == "Running" and
          (.status.containerStatuses | type == "array") and
          (.status.containerStatuses | length > 0) and
          all(.status.containerStatuses[]; .ready == true)
        )
    )
  ' >/dev/null &&
  printf "Management cluster Pods are healthy\n"
```

??? example "Expected result"
    ```text
    Management cluster Pods are healthy
    ```

Verify workload-cluster Pod health:

```bash
# Verify workload-cluster Pod health.
kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get pods -A -o json |
  jq -e '
    all(
      .items[];
      .status.phase == "Succeeded" or
        (
          .status.phase == "Running" and
          (.status.containerStatuses | type == "array") and
          (.status.containerStatuses | length > 0) and
          all(.status.containerStatuses[]; .ready == true)
        )
    )
  ' >/dev/null &&
  printf "Workload cluster Pods are healthy\n"
```

??? example "Expected result"
    ```text
    Workload cluster Pods are healthy
    ```

Display Machine readiness and existing upgrade state:

```bash
# Display Machine readiness and upgrade state.
kubectl --kubeconfig="$HOME/.kube/config" get machines \
  -l cluster.x-k8s.io/cluster-name=myk8scluster \
  -o json |
  jq -r '
    .items[] |
    [
      .metadata.name,
      .status.nodeRef.name,
      .status.phase,
      ([.status.conditions[] | select(.type == "Ready")][0].status // "Missing"),
      (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-status"] // "none"),
      (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-to"] // "none")
    ] |
    @tsv
  ' |
  sort -k2
```

??? example "Expected result"
    ```text
    myk8scluster-control-plane-cvgdl       k8s-ctrl      Running   True   none   none
    myk8scluster-worker-md-0-m8bgf-rjszd   k8s-worker1   Running   True   none   none
    myk8scluster-worker-md-0-m8bgf-sxbrk   k8s-worker2   Running   True   none   none
    ```

Enforce the expected topology, source version, readiness, and absence of previous upgrade state:

```bash
# Reject an unsafe or previously upgraded Machine topology.
kubectl --kubeconfig="$HOME/.kube/config" get machines \
  -l cluster.x-k8s.io/cluster-name=myk8scluster \
  -o json |
  jq -e '
    (.items | length == 3) and
    all(
      .items[];
      .spec.version == "v1.35.7" and
        .status.phase == "Running" and
        ([.status.conditions[] | select(.type == "Ready")][0].status == "True") and
        (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-status"] == null) and
        (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-to"] == null) and
        (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at"] == null) and
        (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-change-id"] == null)
    )
  ' >/dev/null &&
  printf "Machine topology is safe for the v1.35 to v1.36 upgrade\n"
```

??? example "Expected result"
    ```text
    Machine topology is safe for the v1.35 to v1.36 upgrade
    ```

### :material-application-edit-outline: Discover the target version

Define the target channel:

```bash
# Set the requested snap channel.
export TARGET_CHANNEL="1.36-classic/candidate"
```

??? example "Expected result"
    ```text
    No output.
    ```

Discover its current patch version and confirm the expected minor-version transition:

```bash
# Discover and validate the source and current target versions.
SOURCE_VERSION=$(kubectl --kubeconfig="$HOME/.kube/config" \
  get ck8scontrolplane myk8scluster-control-plane \
  -o jsonpath='{.spec.version}') &&
  TARGET_VERSION=$(lxc exec k8s-ctrl -- snap info k8s |
    awk -v channel="$TARGET_CHANNEL:" '$1 == channel { print $2; exit }') &&
  [[ "$SOURCE_VERSION" == v1.35.* && "$TARGET_VERSION" == v1.36.* ]] &&
  printf "Source version: %s\nTarget version: %s\n" "$SOURCE_VERSION" "$TARGET_VERSION"
```

??? example "Expected result"
    ```text
    Source version: v1.35.7
    Target version: v1.36.4
    ```

Confirm every workload node sees the same source, tracking channel, and target build:

```bash
# Display installed, tracked, and target snap versions on every workload node.
for node in k8s-ctrl k8s-worker1 k8s-worker2; do
  printf "%s\t" "$node"
  lxc exec "$node" -- snap info k8s |
    awk '
      $1 == "tracking:" { tracking=$2 }
      $1 == "installed:" { installed=$2 }
      $1 == "1.36-classic/candidate:" { target=$2 }
      END { print installed, tracking, target }
    '
done
```

??? example "Expected result"
    ```text
    k8s-ctrl      v1.35.7 1.35-classic/stable v1.36.4
    k8s-worker1   v1.35.7 1.35-classic/stable v1.36.4
    k8s-worker2   v1.35.7 1.35-classic/stable v1.36.4
    ```

### :material-application-edit-outline: Stabilize management DNS

The CAPI controllers run inside the management cluster and must resolve the workload API's private `.maas` hostname.
Configure a zone-specific forward to the MAAS DNS gateway. This command is idempotent:

```bash
# Route management-cluster .maas queries through the MAAS DNS gateway.
MAAS_DNS=$(ip -4 -o addr show lxdbr0 |
  awk '{split($4, address, "/"); print address[1]}') &&
  COREFILE=$(kubectl --kubeconfig="$HOME/.kube/config" \
    get configmap ck-dns-coredns \
    --namespace kube-system \
    -o jsonpath='{.data.Corefile}') &&
  if grep -q "^maas:53 {" <<<"$COREFILE"; then
    printf "MAAS forwarding already configured\n"
  else
    PATCHED_COREFILE=$(printf 'maas:53 {\n    errors\n    cache 30\n    forward . %s\n}\n%s' \
      "$MAAS_DNS" "$COREFILE") &&
      kubectl --kubeconfig="$HOME/.kube/config" \
        patch configmap ck-dns-coredns \
        --namespace kube-system \
        --type merge \
        -p "$(jq -nc \
          --arg corefile "$PATCHED_COREFILE" \
          '{data: {Corefile: $corefile}}')"
  fi
```

??? example "Expected result"
    ```text
    configmap/ck-dns-coredns patched
    ```

    A rerun reports:

    ```text
    MAAS forwarding already configured
    ```

Verify repeated resolution through management CoreDNS:

```bash
# Require ten consistent workload API DNS responses.
COREDNS_IP=$(kubectl --kubeconfig="$HOME/.kube/config" \
  get service coredns \
  --namespace kube-system \
  -o jsonpath='{.spec.clusterIP}') &&
  API_SERVER=$(kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" \
    config view --minify \
    -o jsonpath='{.clusters[0].cluster.server}') &&
  API_HOST=${API_SERVER#https://} &&
  API_HOST=${API_HOST%%:*} &&
  EXPECTED_IP=$(getent ahostsv4 "$API_HOST" |
    awk 'NR == 1 { print $1 }') &&
  timeout 180s bash -c '
    while true; do
      resolved=0
      for query in {1..10}; do
        [[ "$(lxc exec cluster-ctrl -- \
          dig +time=2 +tries=1 +short @"$1" "$2" A |
          sort -u)" == "$3" ]] &&
          ((resolved+=1))
      done
      if [[ "$resolved" -eq 10 ]]; then
        printf "Management DNS resolved %s consistently\n" "$2"
        exit 0
      fi
      sleep 5
    done
  ' _ "$COREDNS_IP" "$API_HOST" "$EXPECTED_IP"
```

??? example "Expected result"
    ```text
    Management DNS resolved myk8scluster-1d008f.maas consistently
    ```

!!! note "Persistent prerequisite"
    Keep the `.maas` forward after the chapter. CAPI controllers continue to need deterministic access to the workload
    API for normal reconciliation.

### :material-application-edit-outline: Define bounded helpers

Define a reusable monitor. It starts a workload VM if an upgrade reboot leaves the lab's LXD guest stopped, reports status
changes, returns `2` on an explicit failure, and returns `124` on timeout:

```bash
# Define bounded Machine upgrade monitoring with LXD restart recovery.
wait_for_machine_upgrade() {
  local machine="$1" node="$2"

  timeout 1800s bash -c '
    last=""
    while true; do
      state=$(lxc list "$2" --format csv -c s)
      if [[ "$state" == "STOPPED" ]] && lxc start "$2"; then
        printf "%s VM restarted after upgrade reboot\n" "$2"
      fi
      if ! machine_json=$(kubectl --kubeconfig="$HOME/.kube/config" \
        get machine "$1" -o json 2>/dev/null); then
        sleep 10
        continue
      fi
      status=$(jq -r \
        ".metadata.annotations[\"v1beta2.k8sd.io/in-place-upgrade-status\"] // \"pending\"" \
        <<<"$machine_json")
      if [[ "$status" != "$last" ]]; then
        printf "%s upgrade status: %s\n" "$1" "$status"
        last="$status"
      fi
      case "$status" in
        done) exit 0 ;;
        failed) exit 2 ;;
      esac
      sleep 10
    done
  ' _ "$machine" "$node"
}
```

??? example "Expected result"
    ```text
    No output.
    ```

Define a post-upgrade stabilization check. It requires the VM to remain running and the node to remain Ready at the target
version for two minutes:

```bash
# Define bounded post-upgrade node stabilization.
stabilize_node() {
  local node="$1" version="$2"

  timeout 900s bash -c '
    stable_since=0
    while true; do
      state=$(lxc list "$1" --format csv -c s)
      if [[ "$state" == "STOPPED" ]] && lxc start "$1"; then
        printf "%s VM restarted during stabilization\n" "$1"
      fi
      current_version=$(kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" \
        get node "$1" \
        -o jsonpath="{.status.nodeInfo.kubeletVersion}" 2>/dev/null || true)
      if [[ "$state" == "RUNNING" && "$current_version" == "$2" ]] &&
        kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" \
          wait --for=condition=Ready "node/$1" --timeout=10s >/dev/null 2>&1
      then
        now=$(date +%s)
        [[ "$stable_since" -ne 0 ]] || stable_since=$now
        if (( now - stable_since >= 120 )); then
          printf "%s remained Ready at %s for 120 seconds\n" "$1" "$2"
          exit 0
        fi
      else
        stable_since=0
      fi
      sleep 10
    done
  ' _ "$node" "$version"
}
```

??? example "Expected result"
    ```text
    No output.
    ```

The helpers print a VM restart line only when an upgrade reboot leaves that LXD guest stopped. Both workers required the
same successful `lxc start` recovery during validation; those individual commands are retained in the validation transcript.
The normalized helper combines that recovery primitive with the separately validated bounded status polling.

### :material-application-edit-outline: Discover Machine names

Discover Machine names from their bound node names rather than generated suffixes:

```bash
# Discover the control-plane and worker Machine names.
CONTROL_PLANE_MACHINE=$(kubectl --kubeconfig="$HOME/.kube/config" get machines \
  -l cluster.x-k8s.io/cluster-name=myk8scluster \
  -o json |
  jq -er '
    [.items[] | select(.status.nodeRef.name == "k8s-ctrl")] |
    if length == 1 then
      .[0].metadata.name
    else
      error("expected one control-plane machine")
    end
  ') &&
  WORKER1_MACHINE=$(kubectl --kubeconfig="$HOME/.kube/config" get machines \
    -l cluster.x-k8s.io/cluster-name=myk8scluster \
    -o json |
    jq -er '
      [.items[] | select(.status.nodeRef.name == "k8s-worker1")] |
      if length == 1 then
        .[0].metadata.name
      else
        error("expected one machine for k8s-worker1")
      end
    ') &&
  WORKER2_MACHINE=$(kubectl --kubeconfig="$HOME/.kube/config" get machines \
    -l cluster.x-k8s.io/cluster-name=myk8scluster \
    -o json |
    jq -er '
      [.items[] | select(.status.nodeRef.name == "k8s-worker2")] |
      if length == 1 then
        .[0].metadata.name
      else
        error("expected one machine for k8s-worker2")
      end
    ') &&
  printf "%s\n%s\n%s\n" \
    "$CONTROL_PLANE_MACHINE" "$WORKER1_MACHINE" "$WORKER2_MACHINE"
```

??? example "Expected result"
    ```text
    myk8scluster-control-plane-cvgdl
    myk8scluster-worker-md-0-m8bgf-rjszd
    myk8scluster-worker-md-0-m8bgf-sxbrk
    ```

!!! danger "Stop on monitor failure"
    Do not annotate another Machine if a monitor returns nonzero. On explicit `failed`, first collect Machine, node, event,
    and controller diagnostics. The official cancellation procedure removes both the
    `v1beta2.k8sd.io/in-place-upgrade-to` and `v1beta2.k8sd.io/in-place-upgrade-change-id` annotations to stop retries;
    cancellation does not downgrade software already installed on the node.

### :material-application-edit-outline: Upgrade the control plane

Request the control-plane upgrade:

```bash
# Request the in-place control-plane upgrade.
kubectl --kubeconfig="$HOME/.kube/config" annotate machine \
  "$CONTROL_PLANE_MACHINE" \
  "v1beta2.k8sd.io/in-place-upgrade-to=channel=$TARGET_CHANNEL"
```

??? example "Expected result"
    ```text
    machine.cluster.x-k8s.io/myk8scluster-control-plane-cvgdl annotated
    ```

Wait for controller success:

```bash
# Monitor the control-plane Machine upgrade.
wait_for_machine_upgrade "$CONTROL_PLANE_MACHINE" k8s-ctrl
```

??? example "Expected result"
    ```text
    myk8scluster-control-plane-cvgdl upgrade status: in-progress
    myk8scluster-control-plane-cvgdl upgrade status: done
    ```

Verify the release, status, and absence of transient annotations:

```bash
# Display the completed control-plane upgrade annotations.
kubectl --kubeconfig="$HOME/.kube/config" \
  get machine "$CONTROL_PLANE_MACHINE" -o json |
  jq -r '
    [
      .metadata.name,
      .metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-release"],
      .metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-status"],
      (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-to"] // "absent"),
      (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at"] // "absent"),
      (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-change-id"] // "absent")
    ] |
    @tsv
  '
```

??? example "Expected result"
    ```text
    myk8scluster-control-plane-cvgdl   channel=1.36-classic/candidate   done   absent   absent   absent
    ```

Stabilize the control-plane node before touching workers:

```bash
# Require stable control-plane readiness at the target version.
stabilize_node k8s-ctrl "$TARGET_VERSION"
```

??? example "Expected result"
    ```text
    k8s-ctrl remained Ready at v1.36.4 for 120 seconds
    ```

Confirm workload API readiness:

```bash
# Verify workload API readiness after the control-plane upgrade.
kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get --raw="/readyz"
```

??? example "Expected result"
    ```text
    ok
    ```

### :material-application-edit-outline: Upgrade the first worker

Request the first worker upgrade:

```bash
# Request the first worker upgrade.
kubectl --kubeconfig="$HOME/.kube/config" annotate machine \
  "$WORKER1_MACHINE" \
  "v1beta2.k8sd.io/in-place-upgrade-to=channel=$TARGET_CHANNEL"
```

??? example "Expected result"
    ```text
    machine.cluster.x-k8s.io/myk8scluster-worker-md-0-m8bgf-rjszd annotated
    ```

Monitor the first worker Machine upgrade:

```bash
# Monitor the first worker Machine upgrade.
wait_for_machine_upgrade "$WORKER1_MACHINE" k8s-worker1
```

??? example "Expected result"
    ```text
    myk8scluster-worker-md-0-m8bgf-rjszd upgrade status: pending
    myk8scluster-worker-md-0-m8bgf-rjszd upgrade status: in-progress
    myk8scluster-worker-md-0-m8bgf-rjszd upgrade status: done
    ```

Stabilize the first worker before continuing:

```bash
# Require stable first-worker readiness at the target version.
stabilize_node k8s-worker1 "$TARGET_VERSION"
```

??? example "Expected result"
    ```text
    k8s-worker1 remained Ready at v1.36.4 for 120 seconds
    ```

Verify all nodes remain Ready before upgrading the second worker:

```bash
# Verify cluster readiness before the second worker upgrade.
kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" wait --for=condition=Ready nodes --all --timeout=300s
```

??? example "Expected result"
    ```text
    node/k8s-ctrl condition met
    node/k8s-worker1 condition met
    node/k8s-worker2 condition met
    ```

### :material-application-edit-outline: Upgrade the second worker

Request the second worker upgrade:

```bash
# Request the second worker upgrade.
kubectl --kubeconfig="$HOME/.kube/config" annotate machine \
  "$WORKER2_MACHINE" \
  "v1beta2.k8sd.io/in-place-upgrade-to=channel=$TARGET_CHANNEL"
```

??? example "Expected result"
    ```text
    machine.cluster.x-k8s.io/myk8scluster-worker-md-0-m8bgf-sxbrk annotated
    ```

Monitor the second worker Machine upgrade:

```bash
# Monitor the second worker Machine upgrade.
wait_for_machine_upgrade "$WORKER2_MACHINE" k8s-worker2
```

??? example "Expected result"
    ```text
    myk8scluster-worker-md-0-m8bgf-sxbrk upgrade status: in-progress
    myk8scluster-worker-md-0-m8bgf-sxbrk upgrade status: done
    ```

Stabilize the second worker before final verification:

```bash
# Require stable second-worker readiness at the target version.
stabilize_node k8s-worker2 "$TARGET_VERSION"
```

??? example "Expected result"
    ```text
    k8s-worker2 remained Ready at v1.36.4 for 120 seconds
    ```

### :material-application-edit-outline: Verify the upgrade

Require the complete workload cluster to remain stable for two minutes:

```bash
# Require stable VM and node health across the workload cluster.
timeout 900s bash -c '
  stable_since=0
  while true; do
    running=$(lxc list --format csv -c ns |
      grep -Ec "^k8s-(ctrl|worker1|worker2),RUNNING$")
    node_count=$(kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" \
      get nodes --no-headers 2>/dev/null |
      wc -l)
    version_count=$(kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" \
      get nodes \
      -o jsonpath="{range .items[*]}{.status.nodeInfo.kubeletVersion}{\"\\n\"}{end}" \
      2>/dev/null |
      grep -Fxc "$1")
    if [[ "$running" -eq 3 && "$node_count" -eq 3 && "$version_count" -eq 3 ]] &&
      kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" \
        wait --for=condition=Ready nodes --all --timeout=10s >/dev/null 2>&1
    then
      now=$(date +%s)
      [[ "$stable_since" -ne 0 ]] || stable_since=$now
      if (( now - stable_since >= 120 )); then
        printf "All workload VMs and nodes remained healthy at %s for 120 seconds\n" "$1"
        exit 0
      fi
    else
      stable_since=0
    fi
    sleep 10
  done
' _ "$TARGET_VERSION"
```

??? example "Expected result"
    ```text
    All workload VMs and nodes remained healthy at v1.36.4 for 120 seconds
    ```

Display the final node state:

```bash
# Display the upgraded workload-cluster nodes.
kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get nodes -o wide
```

??? example "Expected result"
    ```text
    NAME          STATUS   ROLES                  VERSION   INTERNAL-IP     CONTAINER-RUNTIME
    k8s-ctrl      Ready    control-plane,worker   v1.36.4   10.107.242.62   containerd://2.3.3
    k8s-worker1   Ready    worker                 v1.36.4   10.107.242.63   containerd://2.3.3
    k8s-worker2   Ready    worker                 v1.36.4   10.107.242.64   containerd://2.3.3
    ```

Assert the final node count, version, and readiness:

```bash
# Verify every workload node is Ready at the validated target version.
kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get nodes -o json |
  jq -e --arg version "$TARGET_VERSION" '
    (.items | length == 3) and
    all(
      .items[];
      .status.nodeInfo.kubeletVersion == $version and
        ([.status.conditions[] | select(.type == "Ready")][0].status == "True")
    )
  ' >/dev/null &&
  printf "All workload nodes are Ready at %s\n" "$TARGET_VERSION"
```

??? example "Expected result"
    ```text
    All workload nodes are Ready at v1.36.4
    ```

Verify Kubernetes component readiness:

```bash
# Check workload Kubernetes component readiness.
kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get --raw="/readyz?verbose"
```

??? example "Expected result"
    ```text
    [+]ping ok
    [+]etcd ok
    [+]etcd-readiness ok
    [+]informer-sync ok
    ...
    readyz check passed
    ```

Verify workload Pod health:

```bash
# Verify final workload-cluster Pod health.
kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get pods -A -o json |
  jq -e '
    all(
      .items[];
      .status.phase == "Succeeded" or
        (
          .status.phase == "Running" and
          (.status.containerStatuses | type == "array") and
          (.status.containerStatuses | length > 0) and
          all(.status.containerStatuses[]; .ready == true)
        )
    )
  ' >/dev/null &&
  printf "Workload cluster Pods are healthy\n"
```

??? example "Expected result"
    ```text
    Workload cluster Pods are healthy
    ```

Confirm the installed version and tracking channel on every node:

```bash
# Display final snap versions and tracking channels.
for node in k8s-ctrl k8s-worker1 k8s-worker2; do
  printf "%s\t" "$node"
  lxc exec "$node" -- snap info k8s |
    awk '
      $1 == "tracking:" { tracking=$2 }
      $1 == "installed:" { installed=$2 }
      END { print installed, tracking }
    '
done
```

??? example "Expected result"
    ```text
    k8s-ctrl      v1.36.4 1.36-classic/candidate
    k8s-worker1   v1.36.4 1.36-classic/candidate
    k8s-worker2   v1.36.4 1.36-classic/candidate
    ```

Display final Machine upgrade state and the unchanged declarative version:

```bash
# Display runtime upgrade annotations alongside declarative Machine versions.
kubectl --kubeconfig="$HOME/.kube/config" get machines \
  -l cluster.x-k8s.io/cluster-name=myk8scluster \
  -o json |
  jq -r '
    .items |
    sort_by(.status.nodeRef.name)[] |
    [
      .metadata.name,
      .status.nodeRef.name,
      .spec.version,
      .metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-release"],
      .metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-status"],
      (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-to"] // "absent"),
      (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at"] // "absent"),
      (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-change-id"] // "absent")
    ] |
    @tsv
  '
```

??? example "Expected result"
    ```text
    myk8scluster-control-plane-cvgdl       k8s-ctrl      v1.35.7   channel=1.36-classic/candidate   done   absent   absent   absent
    myk8scluster-worker-md-0-m8bgf-rjszd   k8s-worker1   v1.35.7   channel=1.36-classic/candidate   done   absent   absent   absent
    myk8scluster-worker-md-0-m8bgf-sxbrk   k8s-worker2   v1.35.7   channel=1.36-classic/candidate   done   absent   absent   absent
    ```

Assert that every Machine completed without residual request or failure annotations:

```bash
# Verify completed Machine upgrade annotations.
kubectl --kubeconfig="$HOME/.kube/config" get machines \
  -l cluster.x-k8s.io/cluster-name=myk8scluster \
  -o json |
  jq -e \
    --arg release "channel=$TARGET_CHANNEL" \
    --arg source "$SOURCE_VERSION" '
      (.items | length == 3) and
      all(
        .items[];
        .spec.version == $source and
          .metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-release"] == $release and
          .metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-status"] == "done" and
          (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-to"] == null) and
          (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at"] == null) and
          (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-change-id"] == null)
      )
    ' >/dev/null &&
  printf "All Machine upgrades completed without residual request or failure annotations\n"
```

??? example "Expected result"
    ```text
    All Machine upgrades completed without residual request or failure annotations
    ```

Confirm the CAPI objects remain healthy while their declarative versions stay at the source version:

```bash
# Display final CAPI control-plane, worker, and Machine status.
kubectl --kubeconfig="$HOME/.kube/config" get ck8scontrolplanes,machinedeployments,machines
```

??? example "Expected result"
    ```text
    NAME                                                                        VERSION   REPLICAS   READY
    ck8scontrolplane.controlplane.cluster.x-k8s.io/myk8scluster-control-plane   1.35.7    1          1

    NAME                                                          DESIRED   READY   AVAILABLE   PHASE     VERSION
    machinedeployment.cluster.x-k8s.io/myk8scluster-worker-md-0   2         2       2           Running   v1.35.7

    NAME                                                            NODE NAME     READY   AVAILABLE   PHASE     VERSION
    machine.cluster.x-k8s.io/myk8scluster-control-plane-cvgdl       k8s-ctrl      True    True        Running   v1.35.7
    machine.cluster.x-k8s.io/myk8scluster-worker-md-0-m8bgf-rjszd   k8s-worker1   True    True        Running   v1.35.7
    machine.cluster.x-k8s.io/myk8scluster-worker-md-0-m8bgf-sxbrk   k8s-worker2   True    True        Running   v1.35.7
    ```

Verify the authoritative Cluster conditions:

```bash
# Display final Cluster availability and Machine readiness conditions.
kubectl --kubeconfig="$HOME/.kube/config" get cluster myk8scluster -o json |
  jq -r '
    [
      .status.conditions[] |
      select(
        .type == "Available" or
        .type == "ControlPlaneAvailable" or
        .type == "WorkersAvailable" or
        .type == "ControlPlaneMachinesReady" or
        .type == "WorkerMachinesReady"
      ) |
      [.type, .status]
    ] |
    sort_by(.[0])[] |
    @tsv
  '
```

??? example "Expected result"
    ```text
    Available                    True
    ControlPlaneAvailable        True
    ControlPlaneMachinesReady    True
    WorkerMachinesReady          True
    WorkersAvailable             True
    ```

Verify final management-cluster Pod health:

```bash
# Verify final management-cluster Pod health.
kubectl --kubeconfig="$HOME/.kube/config" get pods -A -o json |
  jq -e '
    all(
      .items[];
      .status.phase == "Succeeded" or
        (
          .status.phase == "Running" and
          (.status.containerStatuses | type == "array") and
          (.status.containerStatuses | length > 0) and
          all(.status.containerStatuses[]; .ready == true)
        )
    )
  ' >/dev/null &&
  printf "Management cluster Pods are healthy\n"
```

??? example "Expected result"
    ```text
    Management cluster Pods are healthy
    ```

Display the final workload VM state:

```bash
# Display final workload VM state.
lxc list --format csv -c ns | grep "^k8s-" | sort
```

??? example "Expected result"
    ```text
    k8s-ctrl,RUNNING
    k8s-worker1,RUNNING
    k8s-worker2,RUNNING
    ```

!!! note "Expected declarative difference"
    In-place upgrades do not change `CK8sControlPlane.spec.version`, `MachineDeployment.spec.template.spec.version`, or
    `Machine.spec.version`. They remain at the source version, which was `v1.35.7` during validation, while the runtime
    nodes use the discovered target version. For a highly available cluster, prefer a rollout so CAPI manages the target
    version declaratively.

!!! note "No cleanup"
    The upgraded runtime and the management CoreDNS `.maas` forward are the intended final state. This chapter creates no
    temporary workload resources to remove.

For more information, see:

* [CAPI rollout upgrade documentation](https://documentation.ubuntu.com/canonical-kubernetes/release-1.35/capi/howto/rollout-upgrades/)
* [CAPI in-place upgrade documentation](https://documentation.ubuntu.com/canonical-kubernetes/release-1.35/capi/howto/in-place-upgrades/)
* [CAPI upgrade annotations reference](https://documentation.ubuntu.com/canonical-kubernetes/release-1.35/capi/reference/annotations/)
