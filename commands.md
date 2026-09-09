# CAPI Commands Tracker

Record only successfully executed Kubernetes CAPI training commands run by an agent, including during live interactive training.
Preserve plaintext secret literals that are part of the training command, but omit external connection-wrapper credentials.

## Session History

### 2026-09-08 - Chapter 1 validation

Install MAAS from the documented stable channel.

```bash
sudo snap install maas --channel=3.6/stable
```

??? example "Expected result"
    `maas (3.6/stable) 3.6.5-17655-g.474ecb517 from Canonical installed`

Install the MAAS test database from the documented stable channel.

```bash
sudo snap install maas-test-db --channel=3.6/stable
```

??? example "Expected result"
    `maas-test-db (3.6/stable) 16.6-34-g.9c27046 from Canonical installed`

Install LXD from the documented stable channel.

```bash
sudo snap install lxd --channel=5.21/stable
```

??? example "Expected result"
    `lxd (5.21/stable) 5.21.7-1018661 from Canonical installed`

Initialize LXD using automatic defaults.

```bash
sudo lxd init --auto
```

??? example "Expected result"
    `No output.`

Disable IPv6 addressing on the LXD bridge.

```bash
sudo lxc network set lxdbr0 ipv6.address none
```

??? example "Expected result"
    `No output.`

Remove IPv6 NAT from the LXD bridge.

```bash
sudo lxc network unset lxdbr0 ipv6.nat
```

??? example "Expected result"
    `No output.`

Disable LXD DNS management on the bridge.

```bash
sudo lxc network set lxdbr0 dns.mode=none
```

??? example "Expected result"
    `No output.`

Disable LXD IPv4 DHCP on the bridge.

```bash
sudo lxc network set lxdbr0 ipv4.dhcp=false
```

??? example "Expected result"
    `No output.`

Bind the LXD HTTPS API to localhost.

```bash
sudo lxc config set core.https_address 127.0.0.1:8443
```

??? example "Expected result"
    `No output.`

Persistently disable IPv6 through sysctl.

```bash
sudo tee -a /etc/sysctl.conf <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
```

??? example "Expected result"
    `net.ipv6.conf.all.disable_ipv6 = 1`

    `net.ipv6.conf.default.disable_ipv6 = 1`

Apply the persistent sysctl configuration.

```bash
sudo sysctl -p
```

??? example "Expected result"
    `net.ipv6.conf.all.disable_ipv6 = 1`

    `net.ipv6.conf.default.disable_ipv6 = 1`

Disable IPv6 globally at runtime.

```bash
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
```

??? example "Expected result"
    `net.ipv6.conf.all.disable_ipv6 = 1`

Disable IPv6 by default at runtime.

```bash
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
```

??? example "Expected result"
    `net.ipv6.conf.default.disable_ipv6 = 1`

Select the host IP and initialize the MAAS region and rack controller.

```bash
IP_ADDRESS=$(hostname -I | awk '{print $1}')
sudo maas init region+rack --database-uri maas-test-db:/// --maas-url http://${IP_ADDRESS}:5240/MAAS
```

??? example "Expected result"
    `MAAS has been set up.`

Create the MAAS administrator.

```bash
sudo maas createadmin --username=admin --password=ubuntu --email=admin@example.com
```

??? example "Expected result"
    `No output.`

Save the MAAS API key.

```bash
sudo maas apikey --username=admin > ~/maas-apikey
```

??? example "Expected result"
    `No output.`

Log in to MAAS.

```bash
maas login deployprofile http://${IP_ADDRESS}:5240/MAAS - < ~/maas-apikey
```

??? example "Expected result"
    `You are now logged in to the MAAS server at http://10.156.0.5:5240/MAAS/api/2.0/ with the profile name 'deployprofile'.`

Import MAAS boot resources.

```bash
maas deployprofile boot-resources import
```

??? example "Expected result"
    `Import of boot resources started`

Register the local LXD host.

```bash
maas deployprofile vm-hosts create type=lxd power_address=https://127.0.0.1:8443 project=default name=localhost
```

??? example "Expected result"
    `"type": "lxd"`

    `"name": "localhost"`

    `"id": 1`

Save the LXD host certificate.

```bash
maas deployprofile vm-host parameters 1 | jq -r '.certificate' > /tmp/maas.crt
```

??? example "Expected result"
    `No output.`

Trust the MAAS certificate in LXD.

```bash
sudo lxc config trust add /tmp/maas.crt
```

??? example "Expected result"
    `No output.`

Refresh the LXD host in MAAS.

```bash
maas deployprofile vm-host refresh 1
```

??? example "Expected result"
    `"type": "lxd"`

    `"name": "localhost"`

    `"version": "5.21.7"`

    `"id": 1`

Generate an SSH key pair.

```bash
ssh-keygen -t rsa -N "" -q -f ~/.ssh/id_rsa
```

??? example "Expected result"
    `No output.`

Add the SSH public key to MAAS.

```bash
maas deployprofile sshkeys create key="`cat ~/.ssh/id_rsa.pub`"
```

??? example "Expected result"
    `"key": "ssh-rsa ... ubuntu@radumoisan.cloudbase.internal"`

    `"id": 1`

Detect the LXD network CIDR.

```bash
PROFILE="deployprofile"
NETWORK="lxdbr0"

# Extract IPv4 CIDR and normalize to x.x.x.0/24
CIDR_RAW=$(lxc network show "$NETWORK" | awk '/ipv4.address:/ {print $2}')
BASE_IP=$(echo "$CIDR_RAW" | cut -d'/' -f1)
PREFIX=$(echo "$CIDR_RAW" | cut -d'/' -f2)

# Normalize to network address (assumes /24 as in your example)
NET_PREFIX=$(echo "$BASE_IP" | awk -F. '{print $1"."$2"."$3}')
CIDR="${NET_PREFIX}.0/${PREFIX}"

echo "Detected CIDR: $CIDR"
```

??? example "Expected result"
    `Detected CIDR: 10.107.242.0/24`

Get the matching MAAS subnet ID.

```bash
SUBNET_ID=$(maas "$PROFILE" subnets read \
  | jq -r ".[] | select(.cidr==\"$CIDR\") | .id")

if [[ -z "$SUBNET_ID" ]]; then
  echo "ERROR: No subnet found for CIDR $CIDR"
  exit 1
fi

echo "Subnet ID: $SUBNET_ID"
```

??? example "Expected result"
    `Subnet ID: 2`

Create the reserved MAAS IP range.

```bash
RES_START="${NET_PREFIX}.1"
RES_END="${NET_PREFIX}.50"
DYN_START="${NET_PREFIX}.51"
DYN_END="${NET_PREFIX}.60"

maas "$PROFILE" ipranges create \
  type=reserved \
  start_ip="$RES_START" \
  end_ip="$RES_END" \
  comment="Reserved range from script"
```

??? example "Expected result"
    `"type": "reserved"`

    `"start_ip": "10.107.242.1"`

    `"end_ip": "10.107.242.50"`

    `"id": 1`

Create the dynamic MAAS IP range.

```bash
maas "$PROFILE" ipranges create \
  type=dynamic \
  start_ip="$DYN_START" \
  end_ip="$DYN_END" \
  comment="Dynamic range from script"
```

??? example "Expected result"
    `"type": "dynamic"`

    `"start_ip": "10.107.242.51"`

    `"end_ip": "10.107.242.60"`

    `"id": 2`

Set the subnet gateway and DNS servers.

```bash
maas "$PROFILE" subnet update "$SUBNET_ID" \
  gateway_ip="$BASE_IP" \
  dns_servers="1.1.1.1 1.0.0.1"
```

??? example "Expected result"
    `"gateway_ip": "10.107.242.1"`

    `"dns_servers": ["1.1.1.1", "1.0.0.1"]`

Enable DHCP on the MAAS VLAN.

```bash
VLAN_JSON=$(maas "$PROFILE" subnet read "$SUBNET_ID")
FABRIC_ID=$(echo "$VLAN_JSON" | jq -r '.vlan.fabric_id')
VID=$(echo "$VLAN_JSON" | jq -r '.vlan.vid')

PRIMARY_RACK=$(maas "$PROFILE" rack-controllers read | jq -r '.[0].system_id')

echo "Using rack controller: $PRIMARY_RACK"

maas "$PROFILE" vlan update "$FABRIC_ID" "$VID" \
  primary_rack="$PRIMARY_RACK" \
  dhcp_on=true
```

??? example "Expected result"
    `"dhcp_on": true`

    `"primary_rack": "yhc4bf"`

    `"fabric_id": 1`

    `"vid": 0`

Set the MAAS upstream DNS server.

```bash
maas "$PROFILE" maas set-config name=upstream_dns value="1.1.1.1"
```

??? example "Expected result"
    `OK`

Configure systemd-resolved to use the local MAAS DNS server.

```bash
sudo mkdir -p /etc/systemd/resolved.conf.d && \
DNS=$(ip -4 -o addr show lxdbr0 | awk '{print $4}' | cut -d/ -f1) && \
sudo tee /etc/systemd/resolved.conf.d/90-maas.conf >/dev/null <<EOF
[Resolve]
DNS=$DNS
FallbackDNS=
Domains=~.
EOF
sudo systemctl restart systemd-resolved
```

??? example "Expected result"
    `No output.`

Set the VM CPU overcommit ratio.

```bash
maas deployprofile vm-host update 1 cpu_over_commit_ratio=2
```

??? example "Expected result"
    `"cpu_over_commit_ratio": 2.0`

Create the management VM.

```bash
maas deployprofile vm-host compose 1 cores=2 memory=4096 storage="1:40(default)" hostname=cluster-ctrl architecture="amd64/generic" interfaces=eth0:subnet=$SUBNET_ID
```

??? example "Expected result"
    `"system_id": "hgwgkf"`

    `"resource_uri": "/MAAS/api/2.0/machines/hgwgkf/"`

Create the Kubernetes control-plane VM.

```bash
maas deployprofile vm-host compose 1 cores=4 memory=8192 storage="1:80(default)" hostname=k8s-ctrl architecture="amd64/generic" interfaces=eth0:subnet=$SUBNET_ID
```

??? example "Expected result"
    `"system_id": "r7mpbc"`

    `"resource_uri": "/MAAS/api/2.0/machines/r7mpbc/"`

Create the first Kubernetes worker VM.

```bash
maas deployprofile vm-host compose 1 cores=4 memory=8192 storage="1:80(default)" hostname=k8s-worker1 architecture="amd64/generic" interfaces=eth0:subnet=$SUBNET_ID
```

??? example "Expected result"
    `"system_id": "gfyma6"`

    `"resource_uri": "/MAAS/api/2.0/machines/gfyma6/"`

Create the second Kubernetes worker VM.

```bash
maas deployprofile vm-host compose 1 cores=4 memory=8192 storage="1:80(default)" hostname=k8s-worker2 architecture="amd64/generic" interfaces=eth0:subnet=$SUBNET_ID
```

??? example "Expected result"
    `"system_id": "h3xmm8"`

    `"resource_uri": "/MAAS/api/2.0/machines/h3xmm8/"`

Tag the commissioned machines.

```bash
maas "$PROFILE" machines read \
| jq -r '.[] | "\(.hostname) \(.system_id)"' \
| while read -r HOST ID; do
    echo "Processing $HOST ($ID)"

    case "$HOST" in
        k8s-worker1|k8s-worker2)
            TAG="k8s-worker"
            ;;
        *)
            TAG="$HOST"
            ;;
    esac

    maas "$PROFILE" tags create name="$TAG" 2>/dev/null || true
    maas "$PROFILE" tag update-nodes "$TAG" add="$ID"
done
```

??? example "Expected result"
    `"added": 1`

    `"removed": 0`

Get the management machine system ID.

```bash
CLUSTERCTL_SYSTEM_ID=$(maas "$PROFILE" machines read \
  | jq -r '.[] | select(.tag_names[] == "cluster-ctrl") | .system_id')
```

??? example "Expected result"
    `No output.`

Deploy Ubuntu Noble to the management machine.

```bash
maas "$PROFILE" machine deploy "$CLUSTERCTL_SYSTEM_ID" distro_series="ubuntu/noble"
```

??? example "Expected result"
    `"hostname": "cluster-ctrl"`

    `"distro_series": "noble"`

    `"status_name": "Deploying"`

Get the management machine IP address.

```bash
CLUSTERCTL_IP=$(maas "$PROFILE" machine read "$CLUSTERCTL_SYSTEM_ID" \
  | jq -r '.interface_set[].links[].ip_address // empty' \
  | head -n1)
```

??? example "Expected result"
    `No output.`

Install Canonical Kubernetes on the management machine.

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$CLUSTERCTL_IP "sudo snap install k8s --classic --channel=1.35-classic/stable"
```

??? example "Expected result"
    `k8s (1.35-classic/stable) v1.35.7 from Canonical installed`

Bootstrap Canonical Kubernetes on the management machine.

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$CLUSTERCTL_IP "sudo k8s bootstrap && sudo k8s status --wait-ready"
```

??? example "Expected result"
    `cluster status:           ready`

    `control plane nodes:      10.107.242.61:6400 (voter)`

    `network:                  enabled`

    `dns:                      enabled at 10.152.183.91`

Create the management cluster kubeconfig.

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$CLUSTERCTL_IP "mkdir -p ~/.kube/ && sudo k8s config > ~/.kube/config"
```

??? example "Expected result"
    `No output.`

Download clusterctl to the management machine.

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$CLUSTERCTL_IP "curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.13.5/clusterctl-linux-amd64 -o clusterctl"
```

??? example "Expected result"
    `100 32.7M  100 32.7M`

Install clusterctl on the management machine.

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$CLUSTERCTL_IP "sudo install -o root -g root -m 0755 clusterctl /usr/local/bin/clusterctl"
```

??? example "Expected result"
    `No output.`

Set the variables used to generate the Cluster API manifest.

```bash
IP_ADDRESS=$(hostname -I | awk '{print $2}')
MAAS_API_KEY=$(cat ~/maas-apikey)
MAAS_ENDPOINT="http://${IP_ADDRESS}:5240/MAAS"
MAAS_DNS_DOMAIN="maas"
CONTROL_PLANE_MACHINE_TAGS="k8s-ctrl"
WORKER_MACHINE_TAGS="k8s-worker"
CHANNEL="1.35-classic/stable"
CONTROL_PLANE_MACHINE_IMAGE="ubuntu/noble"
CONTROL_PLANE_MACHINE_MINCPU=4
CONTROL_PLANE_MACHINE_MINMEMORY=8192
CONTROL_PLANE_MACHINE_COUNT=1
KUBERNETES_VERSION="1.35.7"
WORKER_MACHINE_IMAGE="ubuntu/noble"
WORKER_MACHINE_MINCPU=4
WORKER_MACHINE_MINMEMORY=8192
WORKER_MACHINE_COUNT=2

CAPI_VERSION="v1.13.5"
CK8S_PROVIDER_VERSION="v0.6.2"
MAAS_PROVIDER_VERSION="v0.9.0"
```

??? example "Expected result"
    `No output.`

Initialize the providers and generate the Cluster API manifest remotely.

```bash
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$CLUSTERCTL_IP << EOF
export MAAS_API_KEY=$MAAS_API_KEY
export MAAS_ENDPOINT=$MAAS_ENDPOINT
export MAAS_DNS_DOMAIN=$MAAS_DNS_DOMAIN
export CONTROL_PLANE_MACHINE_TAGS=$CONTROL_PLANE_MACHINE_TAGS
export WORKER_MACHINE_TAGS=$WORKER_MACHINE_TAGS
export CHANNEL=$CHANNEL
export CONTROL_PLANE_MACHINE_IMAGE=$CONTROL_PLANE_MACHINE_IMAGE
export CONTROL_PLANE_MACHINE_MINCPU=$CONTROL_PLANE_MACHINE_MINCPU
export CONTROL_PLANE_MACHINE_MINMEMORY=$CONTROL_PLANE_MACHINE_MINMEMORY
export CONTROL_PLANE_MACHINE_COUNT=$CONTROL_PLANE_MACHINE_COUNT
export KUBERNETES_VERSION=$KUBERNETES_VERSION
export WORKER_MACHINE_IMAGE=$WORKER_MACHINE_IMAGE
export WORKER_MACHINE_MINCPU=$WORKER_MACHINE_MINCPU
export WORKER_MACHINE_MINMEMORY=$WORKER_MACHINE_MINMEMORY
export WORKER_MACHINE_COUNT=$WORKER_MACHINE_COUNT

clusterctl init \
  --core "cluster-api:${CAPI_VERSION}" \
  --bootstrap "canonical-kubernetes:${CK8S_PROVIDER_VERSION}" \
  --control-plane "canonical-kubernetes:${CK8S_PROVIDER_VERSION}" \
  --infrastructure "maas:${MAAS_PROVIDER_VERSION}"

git clone https://github.com/canonical/cluster-api-k8s
cd cluster-api-k8s
export CLUSTER_NAME=myk8scluster
clusterctl generate cluster \${CLUSTER_NAME} --from ./templates/maas/cluster-template.yaml --list-variables
clusterctl generate cluster \${CLUSTER_NAME} --from ./templates/maas/cluster-template.yaml > cluster.yaml
EOF
```

??? example "Expected result"
    `No output.`

Connect to the management machine.

```bash
ssh $CLUSTERCTL_IP
```

??? example "Expected result"
    `ubuntu@cluster-ctrl:~$`

Enter the Cluster API provider directory.

```bash
cd cluster-api-k8s
```

??? example "Expected result"
    `No output.`

Apply the generated cluster template.

```bash
sudo k8s kubectl apply -f cluster.yaml
```

??? example "Expected result"
    `cluster.cluster.x-k8s.io/myk8scluster created`

    `maascluster.infrastructure.cluster.x-k8s.io/myk8scluster created`

    `ck8scontrolplane.controlplane.cluster.x-k8s.io/myk8scluster-control-plane created`

    `maasmachinetemplate.infrastructure.cluster.x-k8s.io/myk8scluster-control-plane created`

    `machinedeployment.cluster.x-k8s.io/myk8scluster-worker-md-0 created`

    `maasmachinetemplate.infrastructure.cluster.x-k8s.io/myk8scluster-md-0 created`

    `ck8sconfigtemplate.bootstrap.cluster.x-k8s.io/myk8scluster-md-0 created`

Watch the CAPI Cluster and Machine status.

```bash
watch "sudo k8s kubectl get clusters; sudo k8s kubectl get machines"
```

??? example "Expected result"
    `myk8scluster   True   1   0   1   2   2   2   Provisioned`

    `myk8scluster-control-plane-cvgdl       myk8scluster   k8s-ctrl      True   True   Running`

    `myk8scluster-worker-md-0-m8bgf-rjszd   myk8scluster   k8s-worker1   True   True   True   Running`

    `myk8scluster-worker-md-0-m8bgf-sxbrk   myk8scluster   k8s-worker2   True   True   True   Running`

Watch the detailed CAPI cluster conditions.

```bash
watch clusterctl describe cluster myk8scluster
```

??? example "Expected result"
    `Cluster/myk8scluster                                          3/3   2   3   3   True   Available`

    `ClusterInfrastructure - MaasCluster/myk8scluster                                 True   InfoReported`

    `ControlPlane - CK8sControlPlane/myk8scluster-control-plane   1/1       1   1   True   NoReasonReported`

    `MachineDeployment/myk8scluster-worker-md-0                   2/2   2   2   2   True   Available`

Exit the management machine.

```bash
exit
```

??? example "Expected result"
    `No output.`

Create the local kubectl configuration directory.

```bash
mkdir -p ~/.kube
```

??? example "Expected result"
    `No output.`

Connect to the management machine for kubeconfig generation.

```bash
ssh $CLUSTERCTL_IP
```

??? example "Expected result"
    `ubuntu@cluster-ctrl:~$`

Generate the workload cluster kubeconfig on cluster-ctrl.

```bash
clusterctl get kubeconfig myk8scluster > ~/.kube/myk8scluster_config
```

??? example "Expected result"
    `No output.`

Exit cluster-ctrl after generating the workload kubeconfig.

```bash
exit
```

??? example "Expected result"
    `Connection to 10.107.242.61 closed.`

Copy the workload cluster kubeconfig to the outer lab VM.

```bash
scp $CLUSTERCTL_IP:~/.kube/myk8scluster_config ~/.kube/
```

??? example "Expected result"
    `myk8scluster_config  100%`

Copy the management cluster kubeconfig to the outer lab VM.

```bash
scp $CLUSTERCTL_IP:~/.kube/config ~/.kube/
```

??? example "Expected result"
    `config  100%`

Install kubectl on the outer lab VM.

```bash
sudo snap install kubectl --channel=1.35/stable --classic
```

??? example "Expected result"
    `kubectl (1.35/stable) 1.35.7 from Canonical installed`

Select the management cluster kubeconfig.

```bash
export KUBECONFIG=~/.kube/config
```

??? example "Expected result"
    `No output.`

Inspect the management cluster.

```bash
kubectl get nodes
```

??? example "Expected result"
    `cluster-ctrl   Ready   control-plane,worker   123m   v1.35.7`

Select the workload cluster kubeconfig.

```bash
export KUBECONFIG=~/.kube/myk8scluster_config
```

??? example "Expected result"
    `No output.`

Inspect the workload cluster.

```bash
kubectl get nodes
```

??? example "Expected result"
    `k8s-ctrl      Ready   control-plane,worker   87m   v1.35.7`

    `k8s-worker1   Ready   worker                 77m   v1.35.7`

    `k8s-worker2   Ready   worker                 77m   v1.35.7`

List all workload cluster pods.

```bash
kubectl get pods -A -o wide
```

??? example "Expected result"
    All 18 `kube-system` and `metallb-system` Pods report `Running`.

Enable kubectl command completion.

```bash
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
```

??? example "Expected result"
    `No output.`

Make the kubectl completion file readable.

```bash
sudo chmod a+r /etc/bash_completion.d/kubectl
```

??? example "Expected result"
    `No output.`

Log out of the lab machine.

```bash
exit
```

??? example "Expected result"
    `Connection to 34.89.137.65 closed.`

Reconnect to the lab machine.

```bash
ssh ubuntu@34.89.137.65
```

??? example "Expected result"
    `ubuntu@radumoisan:~$`

Select the deployed cluster kubeconfig after reconnecting.

```bash
export KUBECONFIG=~/.kube/myk8scluster_config
```

??? example "Expected result"
    `No output.`

Query cluster information.

```bash
kubectl cluster-info
```

??? example "Expected result"
    `Kubernetes control plane is running at https://myk8scluster-1d008f.maas:6443`

    `CoreDNS is running at https://myk8scluster-1d008f.maas:6443/api/v1/namespaces/kube-system/services/coredns:udp-53/proxy`

Check Kubernetes component readiness.

```bash
kubectl get --raw='/readyz?verbose'
```

??? example "Expected result"
    Every readiness check reports `ok`, ending with `readyz check passed`.

List deployed cluster nodes after reconnecting.

```bash
kubectl get nodes
```

??? example "Expected result"
    `k8s-ctrl      Ready   control-plane,worker   123m   v1.35.7`

    `k8s-worker1   Ready   worker                 113m   v1.35.7`

    `k8s-worker2   Ready   worker                 113m   v1.35.7`

Describe the workload control-plane node.

```bash
kubectl describe node k8s-ctrl
```

??? example "Expected result"
    `k8s-ctrl` reports `Ready=True`, Kubernetes `v1.35.7`, and no events.

Show current node resource usage.

```bash
kubectl top nodes
```

??? example "Expected result"
    `k8s-ctrl      225m   5%   1731Mi   22%`

    `k8s-worker1   90m    2%   1000Mi   12%`

    `k8s-worker2   88m    2%   1024Mi   13%`

Show current pod resource usage.

```bash
kubectl top pods --all-namespaces
```

??? example "Expected result"
    Resource usage is reported for all 18 `kube-system` and `metallb-system` Pods.

List all pods at the start of Section 1.3.

```bash
kubectl get pods -o wide --all-namespaces
```

??? example "Expected result"
    All 18 `kube-system` and `metallb-system` Pods report `Running`.

List all namespaces.

```bash
kubectl get namespaces
```

??? example "Expected result"
    `cilium-secrets`, `default`, `kube-node-lease`, `kube-public`, `kube-system`, and `metallb-system` report `Active`.

Select the workload kubeconfig for application resources.

```bash
export KUBECONFIG=~/.kube/myk8scluster_config
```

??? example "Expected result"
    `No output.`

Create the nginx pod.

```bash
kubectl create -f ~/resources/nginx-pod.yaml
```

??? example "Expected result"
    `pod/nginx created`

List the nginx pod.

```bash
kubectl get pods -o wide
```

??? example "Expected result"
    `nginx   1/1   Running   0   58s   10.1.1.204   k8s-worker1   <none>   <none>`

Describe the nginx pod.

```bash
kubectl describe pod nginx
```

??? example "Expected result"
    `nginx` reports `Running`, `Ready=True`, zero restarts, and successful pull/start events.

Delete the nginx pod.

```bash
kubectl delete pod nginx
```

??? example "Expected result"
    `pod "nginx" deleted from default namespace`

Select the workload kubeconfig for the Redis volume example.

```bash
export KUBECONFIG=~/.kube/myk8scluster_config
```

??? example "Expected result"
    `No output.`

Create the Redis volume pod.

```bash
kubectl create -f ~/resources/redis-volume-pod.yaml
```

??? example "Expected result"
    `pod/redis created`

Describe the Redis pod.

```bash
kubectl describe pod redis
```

??? example "Expected result"
    `redis` reports `Running`, with `redis-storage` mounted at `/data/redis` as an `EmptyDir` volume.

Display the multi-container pod definition.

```bash
cat ~/resources/multi-container-pod.yaml
```

??? example "Expected result"
    The `two-containers` manifest defines `nginx-container`, `debian-container`, and the `shared-data` `emptyDir` volume.

Delete the Redis pod.

```bash
kubectl delete pod redis
```

??? example "Expected result"
    `pod "redis" deleted from default namespace`

### 2026-09-08 - Chapter 2 validation

Select the workload cluster kubeconfig.

```bash
export KUBECONFIG=~/.kube/myk8scluster_config
```

??? example "Expected result"
    ```text
    No output.
    ```

Verify the selected Kubernetes context.

```bash
kubectl config current-context
```

??? example "Expected result"
    ```text
    myk8scluster-admin@myk8scluster
    ```

Display the LXD bridge address.

```bash
ip add sh dev lxdbr0
```

??? example "Expected result"
    ```text
    3: lxdbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
        link/ether 00:16:3e:47:9e:4b brd ff:ff:ff:ff:ff:ff
        inet 10.107.242.1/24 scope global lxdbr0
           valid_lft forever preferred_lft forever
    ```

Create the MetalLB IP address pool manifest.

```bash
install -m 600 /dev/stdin ~/metallb.yaml
```

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: lb-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.107.242.10-10.107.242.40
```

??? example "Expected result"
    ```text
    No output.
    ```

Apply the MetalLB IP address pool.

```bash
kubectl apply -f metallb.yaml
```

??? example "Expected result"
    ```text
    ipaddresspool.metallb.io/lb-pool created
    ```

List MetalLB IP address pools.

```bash
kubectl get IPAddressPool -n metallb-system
```

??? example "Expected result"
    ```text
    NAME      AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
    lb-pool   true          false             ["10.107.242.10-10.107.242.40"]
    ```

Describe the MetalLB IP address pool.

```bash
kubectl describe IPAddressPool -n metallb-system lb-pool
```

??? example "Expected result"
    ```text
    Name:         lb-pool
    Namespace:    metallb-system
    API Version:  metallb.io/v1beta1
    Kind:         IPAddressPool
    Spec:
      Addresses:
        10.107.242.10-10.107.242.40
      Auto Assign:       true
      Avoid Buggy I Ps:  false
    Status:
      assignedIPv4:   1
      availableIPv4:  30
    Events:           <none>
    ```

Create the MetalLB L2 advertisement manifest.

```bash
cat > ~/metallb-l2advertisement.yaml
```

```yaml
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: lb-pool
  namespace: metallb-system
spec:
  ipAddressPools:
  - lb-pool
```

??? example "Expected result"
    ```text
    No output.
    ```

Apply the MetalLB L2 advertisement.

```bash
kubectl apply -f metallb-l2advertisement.yaml
```

??? example "Expected result"
    ```text
    l2advertisement.metallb.io/lb-pool created
    ```

Verify the cilium-ingress EndpointSlice Service label.

```bash
kubectl get endpointslice -n kube-system \
  -l kubernetes.io/service-name=cilium-ingress \
  --show-labels
```

??? example "Expected result"
    ```text
    NAME                   ADDRESSTYPE   PORTS   ENDPOINTS         AGE     LABELS
    cilium-ingress-qwp8x   IPv4          9999    192.192.192.192   3h28m   app.kubernetes.io/managed-by=Helm,endpointslice.kubernetes.io/managed-by=endpointslicemirroring-controller.k8s.io,kubernetes.io/service-name=cilium-ingress
    ```

List services in all namespaces.

```bash
kubectl get svc --all-namespaces
```

??? example "Expected result"
    ```text
    NAMESPACE        NAME                                TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                      AGE
    default          kubernetes                          ClusterIP      10.152.0.1       <none>          443/TCP                      3h29m
    kube-system      cilium-ingress                      LoadBalancer   10.152.181.41    10.107.242.10   80:31285/TCP,443:30697/TCP   3h28m
    kube-system      ck-storage-rawfile-csi-controller   ClusterIP      None             <none>          <none>                       3h29m
    kube-system      ck-storage-rawfile-csi-node         ClusterIP      10.152.43.17     <none>          9100/TCP                     3h29m
    kube-system      coredns                             ClusterIP      10.152.17.81     <none>          53/UDP,53/TCP                3h29m
    kube-system      hubble-peer                         ClusterIP      10.152.53.109    <none>          443/TCP                      3h29m
    kube-system      metrics-server                      ClusterIP      10.152.210.241   <none>          443/TCP                      3h29m
    metallb-system   metallb-webhook-service             ClusterIP      10.152.84.215    <none>          443/TCP                      3h29m
    ```

Display the nginx pod definition.

```bash
cat ~/resources/nginx-pod.yaml
```

??? example "Expected result"
    ```text
    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
          - containerPort: 80
    ```

Create the nginx pod.

```bash
kubectl create -f ~/resources/nginx-pod.yaml
```

??? example "Expected result"
    ```text
    pod/nginx created
    ```

Wait for the nginx pod to become Ready.

```bash
kubectl wait --for=condition=Ready pod/nginx --timeout=180s
```

??? example "Expected result"
    ```text
    pod/nginx condition met
    ```

Display the nginx service definition.

```bash
cat ~/resources/nginx-service.yaml
```

??? example "Expected result"
    ```text
    apiVersion: v1
    kind: Service
    metadata:
      name: nginx
    spec:
      ports:
      - port: 8080
        targetPort: 80
      selector:
        app: nginx
    ```

Create the nginx service.

```bash
kubectl create -f ~/resources/nginx-service.yaml
```

??? example "Expected result"
    ```text
    service/nginx created
    ```

List services with selectors.

```bash
kubectl get svc -o wide
```

??? example "Expected result"
    ```text
    NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE     SELECTOR
    kubernetes   ClusterIP   10.152.0.1      <none>        443/TCP    3h32m   <none>
    nginx        ClusterIP   10.152.46.161   <none>        8080/TCP   26s     app=nginx
    ```

Enter the k8s-ctrl node shell.

```bash
lxc shell k8s-ctrl
```

??? example "Expected result"
    ```text
    root@k8s-ctrl:~#
    ```

Install pandoc on the k8s-ctrl node.

```bash
apt install -y pandoc
```

??? example "Expected result"
    ```text
    Setting up pandoc (3.1.3+ds-2) ...
    ```

Probe nginx from the k8s-ctrl node.

```bash
curl -s 10.152.46.161:8080 | pandoc -f html -t plain
```

??? example "Expected result"
    ```text
    Welcome to nginx!

    If you see this page, nginx is successfully installed and working.
    Further configuration is required for the web server, reverse proxy, API
    gateway, load balancer, content cache, or other features.

    For online documentation and support please refer to nginx.org.
    To engage with the community please visit community.nginx.org.
    For enterprise grade support, professional services, additional security
    features and capabilities please refer to f5.com/nginx.

    Thank you for using nginx.
    ```

Exit the k8s-ctrl node.

```bash
exit
```

??? example "Expected result"
    ```text
    ubuntu@radumoisan:~$
    ```

Enter the k8s-worker1 node shell.

```bash
lxc shell k8s-worker1
```

??? example "Expected result"
    ```text
    root@k8s-worker1:~#
    ```

Install pandoc on the k8s-worker1 node.

```bash
apt install -y pandoc
```

??? example "Expected result"
    ```text
    Setting up pandoc (3.1.3+ds-2) ...
    ```

Probe nginx from the k8s-worker1 node.

```bash
curl -s 10.152.46.161:8080 | pandoc -f html -t plain
```

??? example "Expected result"
    ```text
    Welcome to nginx!

    If you see this page, nginx is successfully installed and working.
    Further configuration is required for the web server, reverse proxy, API
    gateway, load balancer, content cache, or other features.

    For online documentation and support please refer to nginx.org.
    To engage with the community please visit community.nginx.org.
    For enterprise grade support, professional services, additional security
    features and capabilities please refer to f5.com/nginx.

    Thank you for using nginx.
    ```

Exit the k8s-worker1 node.

```bash
exit
```

??? example "Expected result"
    ```text
    ubuntu@radumoisan:~$
    ```

List the CoreDNS Pods.

```bash
kubectl get pods -n kube-system | { head -n 1; grep "coredns"; }
```

??? example "Expected result"
    ```text
    NAME                                  READY   STATUS    RESTARTS   AGE
    coredns-c4fd9db5c-t5f84               1/1     Running   0          3h36m
    coredns-c4fd9db5c-ww2bj               1/1     Running   0          3h36m
    ```

Create and enter the shell pod.

```bash
kubectl run shell -i --tty --image ubuntu -- /bin/bash
```

??? example "Expected result"
    ```text
    All commands and output from this session will be recorded in container logs, including credentials and sensitive information passed through the command prompt.
    If you don't see a command prompt, try pressing enter.
    root@shell:/#
    ```

Exit the shell pod.

```bash
exit
```

??? example "Expected result"
    ```text
    ubuntu@radumoisan:~$
    ```

Wait for the shell pod to become Ready again.

```bash
kubectl wait --for=condition=Ready pod/shell --timeout=180s
```

??? example "Expected result"
    ```text
    pod/shell condition met
    ```

Reconnect to the shell pod.

```bash
kubectl exec -it shell -- /bin/bash
```

??? example "Expected result"
    ```text
    root@shell:/#
    ```

Update package information in the shell pod.

```bash
apt update
```

??? example "Expected result"
    ```text
    Fetched 26.0 MB in 4s (7026 kB/s)
    24 packages can be upgraded. Run 'apt list --upgradable' to see them.
    ```

Install curl and pandoc in the shell pod.

```bash
apt install curl pandoc -y
```

??? example "Expected result"
    ```text
    Setting up pandoc (3.7.0.2+ds-1) ...
    Setting up curl (8.18.0-1ubuntu2.4) ...
    Processing triggers for ca-certificates (20260601~26.04.1) ...
    ```

Probe nginx using service discovery.

```bash
curl -s nginx:8080 | pandoc -f html -t plain
```

??? example "Expected result"
    ```text
    Welcome to nginx!

    If you see this page, nginx is successfully installed and working.
    Further configuration is required for the web server, reverse proxy, API
    gateway, load balancer, content cache, or other features.

    For online documentation and support please refer to nginx.org.
    To engage with the community please visit community.nginx.org.
    For enterprise grade support, professional services, additional security
    features and capabilities please refer to f5.com/nginx.

    Thank you for using nginx.
    ```

Exit the shell pod.

```bash
exit
```

??? example "Expected result"
    ```text
    ubuntu@radumoisan:~$
    ```

List services with selectors after the service-discovery test.

```bash
kubectl get svc -o wide
```

??? example "Expected result"
    ```text
    NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE   SELECTOR
    kubernetes   ClusterIP   10.152.0.1      <none>        443/TCP    4h    <none>
    nginx        ClusterIP   10.152.46.161   <none>        8080/TCP   27m   app=nginx
    ```

Display the NodePort service definition.

```bash
cat ~/resources/nodeport-service.yaml
```

??? example "Expected result"
    ```text
    apiVersion: v1
    kind: Service
    metadata:
      name: nginx-nodeport
    spec:
      type: NodePort
      ports:
      - port: 8080
        targetPort: 80
        nodePort: 30111
      selector:
        app: nginx
    ```

Create the NodePort service.

```bash
kubectl create -f ~/resources/nodeport-service.yaml
```

??? example "Expected result"
    ```text
    service/nginx-nodeport created
    ```

List services with selectors.

```bash
kubectl get svc -o wide
```

??? example "Expected result"
    ```text
    NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE    SELECTOR
    kubernetes       ClusterIP   10.152.0.1       <none>        443/TCP          4h3m   <none>
    nginx            ClusterIP   10.152.46.161    <none>        8080/TCP         31m    app=nginx
    nginx-nodeport   NodePort    10.152.132.179   <none>        8080:30111/TCP   29s    app=nginx
    ```

Install pandoc on the student machine before the NodePort client test.

```bash
sudo apt update && sudo apt install -y pandoc
```

??? example "Expected result"
    ```text
    6 packages can be upgraded. Run 'apt list --upgradable' to see them.
    The following NEW packages will be installed:
      liblua5.4-0 pandoc pandoc-data
    Setting up pandoc (3.1.3+ds-2) ...
    Processing triggers for man-db (2.12.0-4build2) ...
    ```

List NodePort client node IP addresses.

```bash
lxc list -c n,4
```

??? example "Expected result"
    ```text
    +--------------+--------------------------+
    |     NAME     |           IPV4           |
    +--------------+--------------------------+
    | cluster-ctrl | 10.107.242.61 (eth0)     |
    |              | 10.1.0.36 (cilium_host)  |
    +--------------+--------------------------+
    | k8s-ctrl     | 10.107.242.62 (eth0)     |
    |              | 10.1.0.173 (cilium_host) |
    +--------------+--------------------------+
    | k8s-worker1  | 10.107.242.63 (eth0)     |
    |              | 10.1.1.85 (cilium_host)  |
    +--------------+--------------------------+
    | k8s-worker2  | 10.107.242.64 (eth0)     |
    |              | 10.1.2.216 (cilium_host) |
    +--------------+--------------------------+
    ```

Probe nginx through the NodePort from the student machine.

```bash
curl -s 10.107.242.64:30111 | pandoc -f html -t plain
```

??? example "Expected result"
    ```text
    Welcome to nginx!

    If you see this page, nginx is successfully installed and working.
    Further configuration is required for the web server, reverse proxy, API
    gateway, load balancer, content cache, or other features.

    For online documentation and support please refer to nginx.org.
    To engage with the community please visit community.nginx.org.
    For enterprise grade support, professional services, additional security
    features and capabilities please refer to f5.com/nginx.

    Thank you for using nginx.
    ```

Display the LoadBalancer service definition.

```bash
cat ~/resources/loadbalancer-service.yaml
```

??? example "Expected result"
    ```text
    apiVersion: v1
    kind: Service
    metadata:
      name: nginx-loadbalancer
    spec:
      type: LoadBalancer
      ports:
      - port: 8080
        targetPort: 80
      selector:
        app: nginx
    ```

Create the LoadBalancer service.

```bash
kubectl create -f ~/resources/loadbalancer-service.yaml
```

??? example "Expected result"
    ```text
    service/nginx-loadbalancer created
    ```

List services.

```bash
kubectl get svc
```

??? example "Expected result"
    ```text
    NAME                 TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)          AGE
    kubernetes           ClusterIP      10.152.0.1       <none>          443/TCP          4h10m
    nginx                ClusterIP      10.152.46.161    <none>          8080/TCP         38m
    nginx-loadbalancer   LoadBalancer   10.152.20.193    10.107.242.11   8080:30364/TCP   30s
    nginx-nodeport       NodePort       10.152.132.179   <none>          8080:30111/TCP   7m20s
    ```

Probe nginx through the LoadBalancer.

```bash
curl -s 10.107.242.11:8080 | pandoc -f html -t plain
```

??? example "Expected result"
    ```text
    Welcome to nginx!

    If you see this page, nginx is successfully installed and working.
    Further configuration is required for the web server, reverse proxy, API
    gateway, load balancer, content cache, or other features.

    For online documentation and support please refer to nginx.org.
    To engage with the community please visit community.nginx.org.
    For enterprise grade support, professional services, additional security
    features and capabilities please refer to f5.com/nginx.

    Thank you for using nginx.
    ```

Delete the nginx services.

```bash
kubectl delete svc nginx nginx-loadbalancer nginx-nodeport
```

??? example "Expected result"
    ```text
    service "nginx" deleted from default namespace
    service "nginx-loadbalancer" deleted from default namespace
    service "nginx-nodeport" deleted from default namespace
    ```

Delete the nginx and shell pods.

```bash
kubectl delete pod nginx shell
```

??? example "Expected result"
    ```text
    pod "nginx" deleted from default namespace
    pod "shell" deleted from default namespace
    ```

Check Cilium Pod readiness before creating the red and blue application resources.

```bash
kubectl get pods -A -o wide | awk 'NR==1 || tolower($0) ~ /cilium/'
```

??? example "Expected result"
    ```text
    NAMESPACE        NAME                                  READY   STATUS    RESTARTS   AGE     IP              NODE          NOMINATED NODE   READINESS GATES
    kube-system      cilium-2k597                          1/1     Running   0          4h18m   10.107.242.62   k8s-ctrl      <none>           <none>
    kube-system      cilium-lxtbw                          1/1     Running   0          4h8m    10.107.242.63   k8s-worker1   <none>           <none>
    kube-system      cilium-operator-77968f785f-gpmlz      1/1     Running   0          4h18m   10.107.242.62   k8s-ctrl      <none>           <none>
    kube-system      cilium-z74j9                          1/1     Running   0          4h8m    10.107.242.64   k8s-worker2   <none>           <none>
    ```

List Cilium services before creating the red and blue application resources.

```bash
kubectl get svc -A |  awk 'NR==1 || tolower($0) ~ /cilium/'
```

??? example "Expected result"
    ```text
    NAMESPACE        NAME                                TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                      AGE
    kube-system      cilium-ingress                      LoadBalancer   10.152.181.41    10.107.242.10   80:31285/TCP,443:30697/TCP   4h19m
    ```

Display the red microservice manifest before creating application resources.

```bash
cat ~/resources/red-app.yaml
```

??? example "Expected result"
    ```text
    kind: Pod
    apiVersion: v1
    metadata:
      name: red-app
      labels:
        app: red
    spec:
      containers:
        - name: red-app
          image: hashicorp/http-echo
          args:
            - "-text=red-microservice"
    ---
    kind: Service
    apiVersion: v1
    metadata:
      name: red-service
    spec:
      selector:
        app: red
      ports:
        - port: 5678
    ```

Display the Ingress manifest before creating application resources.

```bash
cat ~/resources/ingress.yaml
```

??? example "Expected result"
    ```text
    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: bluered-ingress
      annotations:
        ingress.kubernetes.io/rewrite-target: /
    spec:
      ingressClassName: cilium
      rules:
      - http:
          paths:
            - path: /blue
              pathType: Prefix
              backend:
                service:
                  name: blue-service
                  port:
                    number: 5678
            - path: /red
              pathType: Prefix
              backend:
                service:
                  name: red-service
                  port:
                    number: 5678
    ```

Create the blue microservice objects.

```bash
kubectl create -f ~/resources/blue-app.yaml
```

??? example "Expected result"
    ```text
    pod/blue-app created
    service/blue-service created
    ```

Wait for the blue microservice pod to become Ready.

```bash
kubectl wait --for=condition=Ready pod/blue-app --timeout=180s
```

??? example "Expected result"
    ```text
    pod/blue-app condition met
    ```

Create the red microservice objects.

```bash
kubectl create -f ~/resources/red-app.yaml
```

??? example "Expected result"
    ```text
    pod/red-app created
    service/red-service created
    ```

Wait for the red microservice pod to become Ready.

```bash
kubectl wait --for=condition=Ready pod/red-app --timeout=180s
```

??? example "Expected result"
    ```text
    pod/red-app condition met
    ```

Create the Ingress object.

```bash
kubectl create -f ~/resources/ingress.yaml
```

??? example "Expected result"
    ```text
    ingress.networking.k8s.io/bluered-ingress created
    ```

List Ingress resources.

```bash
kubectl get ingress
```

??? example "Expected result"
    ```text
    NAME              CLASS    HOSTS   ADDRESS         PORTS   AGE
    bluered-ingress   cilium   *       10.107.242.10   80      28s
    ```

Probe the blue microservice through the Ingress.

```bash
curl -s http://10.107.242.10/blue
```

??? example "Expected result"
    ```text
    blue-microservice
    ```

Probe the red microservice through the Ingress.

```bash
curl -s http://10.107.242.10/red
```

??? example "Expected result"
    ```text
    red-microservice
    ```

Delete the blue microservice objects.

```bash
kubectl delete -f ~/resources/blue-app.yaml
```

??? example "Expected result"
    ```text
    pod "blue-app" deleted from default namespace
    service "blue-service" deleted from default namespace
    ```

Delete the red microservice objects.

```bash
kubectl delete -f ~/resources/red-app.yaml
```

??? example "Expected result"
    ```text
    pod "red-app" deleted from default namespace
    service "red-service" deleted from default namespace
    ```

Delete the Ingress object.

```bash
kubectl delete -f ~/resources/ingress.yaml
```

??? example "Expected result"
    ```text
    ingress.networking.k8s.io "bluered-ingress" deleted from default namespace
    ```

### 2026-09-08 - Chapter 3 validation

Select the workload cluster kubeconfig.

```bash
export KUBECONFIG=~/.kube/myk8scluster_config
```

??? example "Expected result"
    ```text
    No output.
    ```

Display the active Kubernetes context.

```bash
kubectl config current-context
```

??? example "Expected result"
    ```text
    myk8scluster-admin@myk8scluster
    ```

Display the ReplicaSet definition.

```bash
cat ~/resources/nginx-rs.yaml
```

??? example "Expected result"
    ```text
    apiVersion: apps/v1
    kind: ReplicaSet
    metadata:
      name: nginx-rs
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - name: nginx
            image: nginx:latest
            ports:
            - containerPort: 80
    ```

Create the ReplicaSet.

```bash
kubectl create -f ~/resources/nginx-rs.yaml
```

??? example "Expected result"
    ```text
    replicaset.apps/nginx-rs created
    ```

Wait for the ReplicaSet to report three Ready replicas.

```bash
kubectl wait --for=jsonpath='{.status.readyReplicas}'=3 replicaset/nginx-rs --timeout=180s
```

??? example "Expected result"
    ```text
    replicaset.apps/nginx-rs condition met
    ```

List the ReplicaSet.

```bash
kubectl get rs nginx-rs -o wide
```

??? example "Expected result"
    ```text
    NAME       DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES         SELECTOR
    nginx-rs   3         3         3       55s   nginx        nginx:latest   app=nginx
    ```

Describe the ReplicaSet.

```bash
kubectl describe rs nginx-rs
```

??? example "Expected result"
    ```text
    Name:         nginx-rs
    Namespace:    default
    Selector:     app=nginx
    Labels:       <none>
    Annotations:  <none>
    Replicas:     3 current / 3 desired
    Pods Status:  3 Running / 0 Waiting / 0 Succeeded / 0 Failed
    Pod Template:
      Labels:  app=nginx
      Containers:
       nginx:
        Image:         nginx:latest
        Port:          80/TCP
        Host Port:     0/TCP
        Environment:   <none>
        Mounts:        <none>
      Volumes:         <none>
      Node-Selectors:  <none>
      Tolerations:     <none>
    Events:
      Type    Reason            Age   From                   Message
      ----    ------            ----  ----                   -------
      Normal  SuccessfulCreate  79s   replicaset-controller  Created pod: nginx-rs-vgmmg
      Normal  SuccessfulCreate  79s   replicaset-controller  Created pod: nginx-rs-t98pg
      Normal  SuccessfulCreate  79s   replicaset-controller  Created pod: nginx-rs-qd655
    ```

List the ReplicaSet pods.

```bash
kubectl get pods
```

??? example "Expected result"
    ```text
    NAME             READY   STATUS    RESTARTS   AGE
    nginx-rs-qd655   1/1     Running   0          119s
    nginx-rs-t98pg   1/1     Running   0          119s
    nginx-rs-vgmmg   1/1     Running   0          119s
    ```

Create the LoadBalancer service.

```bash
kubectl create -f ~/resources/loadbalancer-service.yaml
```

??? example "Expected result"
    ```text
    service/nginx-loadbalancer created
    ```

Wait for the LoadBalancer service to receive an IP address.

```bash
kubectl wait --for=jsonpath='{.status.loadBalancer.ingress[0].ip}' service/nginx-loadbalancer --timeout=180s
```

??? example "Expected result"
    ```text
    service/nginx-loadbalancer condition met
    ```

List the LoadBalancer service.

```bash
kubectl get svc nginx-loadbalancer
```

??? example "Expected result"
    ```text
    NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)          AGE
    nginx-loadbalancer   LoadBalancer   10.152.159.80   10.107.242.11   8080:30600/TCP   57s
    ```

Probe nginx through the LoadBalancer.

```bash
curl -s 10.107.242.11:8080 | pandoc -f html -t plain
```

??? example "Expected result"
    ```text
    Welcome to nginx!

    If you see this page, nginx is successfully installed and working.
    Further configuration is required for the web server, reverse proxy, API
    gateway, load balancer, content cache, or other features.

    For online documentation and support please refer to nginx.org.
    To engage with the community please visit community.nginx.org.
    For enterprise grade support, professional services, additional security
    features and capabilities please refer to f5.com/nginx.

    Thank you for using nginx.
    ```

List the ReplicaSet pods before inspecting their logs.

```bash
kubectl get pods
```

??? example "Expected result"
    ```text
    NAME             READY   STATUS    RESTARTS   AGE
    nginx-rs-qd655   1/1     Running   0          4m27s
    nginx-rs-t98pg   1/1     Running   0          4m27s
    nginx-rs-vgmmg   1/1     Running   0          4m27s
    ```

View prefixed logs from all ReplicaSet pods.

```bash
kubectl logs -l app=nginx --prefix=true
```

??? example "Expected result"
    ```text
    [pod/nginx-rs-qd655/nginx] 10.1.0.173 - - [08/Sep/2026:15:33:46 +0000] "GET / HTTP/1.1" 200 896 "-" "curl/8.5.0" "-"
    [pod/nginx-rs-t98pg/nginx] 2026/09/08 15:29:58 [notice] 1#1: nginx/1.31.5
    [pod/nginx-rs-vgmmg/nginx] 2026/09/08 15:29:51 [notice] 1#1: nginx/1.31.5
    ```

List the ReplicaSet pods before deleting one.

```bash
kubectl get pods
```

??? example "Expected result"
    ```text
    NAME             READY   STATUS    RESTARTS   AGE
    nginx-rs-qd655   1/1     Running   0          6m9s
    nginx-rs-t98pg   1/1     Running   0          6m9s
    nginx-rs-vgmmg   1/1     Running   0          6m9s
    ```

Delete one ReplicaSet pod.

```bash
kubectl delete pod nginx-rs-qd655
```

??? example "Expected result"
    ```text
    pod "nginx-rs-qd655" deleted from default namespace
    ```

Wait for the ReplicaSet to restore three Ready replicas.

```bash
kubectl wait --for=jsonpath='{.status.readyReplicas}'=3 replicaset/nginx-rs --timeout=180s
```

??? example "Expected result"
    ```text
    replicaset.apps/nginx-rs condition met
    ```

List the ReplicaSet pods after self-healing.

```bash
kubectl get pods
```

??? example "Expected result"
    ```text
    NAME             READY   STATUS    RESTARTS   AGE
    nginx-rs-t98pg   1/1     Running   0          7m30s
    nginx-rs-vgmmg   1/1     Running   0          7m30s
    nginx-rs-x26xp   1/1     Running   0          52s
    ```

Delete the ReplicaSet.

```bash
kubectl delete rs nginx-rs
```

??? example "Expected result"
    ```text
    replicaset.apps "nginx-rs" deleted from default namespace
    ```

Delete the LoadBalancer service.

```bash
kubectl delete svc nginx-loadbalancer
```

??? example "Expected result"
    ```text
    service "nginx-loadbalancer" deleted from default namespace
    ```

Check for remaining nginx ReplicaSets and Pods.

```bash
kubectl get rs,pod -l app=nginx -o name
```

??? example "Expected result"
    ```text
    No output.
    ```

Check for the deleted LoadBalancer service.

```bash
kubectl get svc nginx-loadbalancer -o name --ignore-not-found
```

??? example "Expected result"
    ```text
    No output.
    ```

Display the Deployment definition.

```bash
cat ~/resources/nginx-deploy.yaml
```

??? example "Expected result"
    ```text
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-deploy
      labels:
        app: nginx
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - name: nginx
            image: nginx:1.28
            ports:
            - containerPort: 80
    ```

Create the Deployment.

```bash
kubectl create -f ~/resources/nginx-deploy.yaml
```

??? example "Expected result"
    ```text
    deployment.apps/nginx-deploy created
    ```

Wait for the Deployment rollout to complete.

```bash
kubectl rollout status deploy nginx-deploy --timeout=180s
```

??? example "Expected result"
    ```text
    deployment "nginx-deploy" successfully rolled out
    ```

List the Deployment.

```bash
kubectl get deploy nginx-deploy -o wide
```

??? example "Expected result"
    ```text
    NAME           READY   UP-TO-DATE   AVAILABLE   AGE    CONTAINERS   IMAGES       SELECTOR
    nginx-deploy   3/3     3            3           101s   nginx        nginx:1.28   app=nginx
    ```

Describe the Deployment before updating it.

```bash
kubectl describe deploy nginx-deploy
```

??? example "Expected result"
    ```text
    Name:                   nginx-deploy
    Namespace:              default
    CreationTimestamp:      Tue, 08 Sep 2026 15:42:35 +0000
    Labels:                 app=nginx
    Annotations:            deployment.kubernetes.io/revision: 1
    Selector:               app=nginx
    Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
    StrategyType:           RollingUpdate
    MinReadySeconds:        0
    RollingUpdateStrategy:  25% max unavailable, 25% max surge
    Pod Template:
      Labels:  app=nginx
      Containers:
       nginx:
        Image:         nginx:1.28
        Port:          80/TCP
        Host Port:     0/TCP
        Environment:   <none>
        Mounts:        <none>
      Volumes:         <none>
      Node-Selectors:  <none>
      Tolerations:     <none>
    Conditions:
      Type           Status  Reason
      ----           ------  ------
      Available      True    MinimumReplicasAvailable
      Progressing    True    NewReplicaSetAvailable
    OldReplicaSets:  <none>
    NewReplicaSet:   nginx-deploy-65dfbbb4d7 (3/3 replicas created)
    Events:
      Type    Reason             Age   From                   Message
      ----    ------             ----  ----                   -------
      Normal  ScalingReplicaSet  2m8s  deployment-controller  Scaled up replica set nginx-deploy-65dfbbb4d7 from 0 to 3
    ```

List the Deployment pods before updating the image.

```bash
kubectl get pods
```

??? example "Expected result"
    ```text
    NAME                            READY   STATUS    RESTARTS   AGE
    nginx-deploy-65dfbbb4d7-2l7ss   1/1     Running   0          2m57s
    nginx-deploy-65dfbbb4d7-8l7dt   1/1     Running   0          2m57s
    nginx-deploy-65dfbbb4d7-ctln7   1/1     Running   0          2m57s
    ```

Update the Deployment nginx image.

```bash
kubectl set image deploy nginx-deploy nginx=nginx:1.29
```

??? example "Expected result"
    ```text
    deployment.apps/nginx-deploy image updated
    ```

Wait for the updated Deployment rollout to complete.

```bash
kubectl rollout status deploy nginx-deploy --timeout=180s
```

??? example "Expected result"
    ```text
    Waiting for deployment "nginx-deploy" rollout to finish: 1 old replicas are pending termination...
    Waiting for deployment "nginx-deploy" rollout to finish: 1 old replicas are pending termination...
    deployment "nginx-deploy" successfully rolled out
    ```

List Deployments after updating the image.

```bash
kubectl get deploy -o wide
```

??? example "Expected result"
    ```text
    NAME           READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES       SELECTOR
    nginx-deploy   3/3     3            3           4m36s   nginx        nginx:1.29   app=nginx
    ```

List the Deployment pods after updating the image.

```bash
kubectl get pods
```

??? example "Expected result"
    ```text
    NAME                            READY   STATUS    RESTARTS   AGE
    nginx-deploy-86c8cd48f6-9s9q7   1/1     Running   0          73s
    nginx-deploy-86c8cd48f6-mk992   1/1     Running   0          91s
    nginx-deploy-86c8cd48f6-xxzgj   1/1     Running   0          82s
    ```

Describe the Deployment after updating the image.

```bash
kubectl describe deploy nginx-deploy
```

??? example "Expected result"
    ```text
    Name:                   nginx-deploy
    Namespace:              default
    CreationTimestamp:      Tue, 08 Sep 2026 15:42:35 +0000
    Labels:                 app=nginx
    Annotations:            deployment.kubernetes.io/revision: 2
    Selector:               app=nginx
    Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
    StrategyType:           RollingUpdate
    MinReadySeconds:        0
    RollingUpdateStrategy:  25% max unavailable, 25% max surge
    Pod Template:
      Labels:  app=nginx
      Containers:
       nginx:
        Image:         nginx:1.29
        Port:          80/TCP
        Host Port:     0/TCP
        Environment:   <none>
        Mounts:        <none>
      Volumes:         <none>
      Node-Selectors:  <none>
      Tolerations:     <none>
    Conditions:
      Type           Status  Reason
      ----           ------  ------
      Available      True    MinimumReplicasAvailable
      Progressing    True    NewReplicaSetAvailable
    OldReplicaSets:  nginx-deploy-65dfbbb4d7 (0/0 replicas created)
    NewReplicaSet:   nginx-deploy-86c8cd48f6 (3/3 replicas created)
    Events:
      Type    Reason             Age    From                   Message
      ----    ------             ----   ----                   -------
      Normal  ScalingReplicaSet  5m41s  deployment-controller  Scaled up replica set nginx-deploy-65dfbbb4d7 from 0 to 3
      Normal  ScalingReplicaSet  2m6s   deployment-controller  Scaled up replica set nginx-deploy-86c8cd48f6 from 0 to 1
      Normal  ScalingReplicaSet  117s   deployment-controller  Scaled down replica set nginx-deploy-65dfbbb4d7 from 3 to 2
      Normal  ScalingReplicaSet  117s   deployment-controller  Scaled up replica set nginx-deploy-86c8cd48f6 from 1 to 2
      Normal  ScalingReplicaSet  108s   deployment-controller  Scaled down replica set nginx-deploy-65dfbbb4d7 from 2 to 1
      Normal  ScalingReplicaSet  108s   deployment-controller  Scaled up replica set nginx-deploy-86c8cd48f6 from 2 to 3
      Normal  ScalingReplicaSet  98s    deployment-controller  Scaled down replica set nginx-deploy-65dfbbb4d7 from 1 to 0
    ```

List the Deployment revision history.

```bash
kubectl rollout history deploy nginx-deploy
```

??? example "Expected result"
    ```text
    deployment.apps/nginx-deploy
    REVISION  CHANGE-CAUSE
    1         <none>
    2         <none>
    ```

Inspect Deployment revision 1.

```bash
kubectl rollout history deploy nginx-deploy --revision=1
```

??? example "Expected result"
    ```text
    deployment.apps/nginx-deploy with revision #1
    Pod Template:
      Labels:	app=nginx
      pod-template-hash=65dfbbb4d7
      Containers:
       nginx:
        Image:	nginx:1.28
        Port:	80/TCP
        Host Port:	0/TCP
        Environment:	<none>
        Mounts:	<none>
      Volumes:	<none>
      Node-Selectors:	<none>
      Tolerations:	<none>
    ```

Inspect Deployment revision 2.

```bash
kubectl rollout history deploy nginx-deploy --revision=2
```

??? example "Expected result"
    ```text
    deployment.apps/nginx-deploy with revision #2
    Pod Template:
      Labels:	app=nginx
      pod-template-hash=86c8cd48f6
      Containers:
       nginx:
        Image:	nginx:1.29
        Port:	80/TCP
        Host Port:	0/TCP
        Environment:	<none>
        Mounts:	<none>
      Volumes:	<none>
      Node-Selectors:	<none>
      Tolerations:	<none>
    ```

Roll back the Deployment to revision 1.

```bash
kubectl rollout undo deploy nginx-deploy --to-revision=1
```

??? example "Expected result"
    ```text
    deployment.apps/nginx-deploy rolled back
    ```

Wait for the rolled-back Deployment to become available.

```bash
kubectl rollout status deploy nginx-deploy --timeout=180s
```

??? example "Expected result"
    ```text
    deployment "nginx-deploy" successfully rolled out
    ```

Describe the rolled-back Deployment.

```bash
kubectl describe deploy nginx-deploy
```

??? example "Expected result"
    ```text
    Name:                   nginx-deploy
    Namespace:              default
    CreationTimestamp:      Tue, 08 Sep 2026 15:42:35 +0000
    Labels:                 app=nginx
    Annotations:            deployment.kubernetes.io/revision: 3
    Selector:               app=nginx
    Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
    StrategyType:           RollingUpdate
    MinReadySeconds:        0
    RollingUpdateStrategy:  25% max unavailable, 25% max surge
    Pod Template:
      Labels:  app=nginx
      Containers:
       nginx:
        Image:         nginx:1.28
        Port:          80/TCP
        Host Port:     0/TCP
        Environment:   <none>
        Mounts:        <none>
      Volumes:         <none>
      Node-Selectors:  <none>
      Tolerations:     <none>
    Conditions:
      Type           Status  Reason
      ----           ------  ------
      Available      True    MinimumReplicasAvailable
      Progressing    True    NewReplicaSetAvailable
    OldReplicaSets:  nginx-deploy-86c8cd48f6 (0/0 replicas created)
    NewReplicaSet:   nginx-deploy-65dfbbb4d7 (3/3 replicas created)
    Events:
      Type    Reason             Age                From                   Message
      ----    ------             ----               ----                   -------
      Normal  ScalingReplicaSet  9m54s              deployment-controller  Scaled up replica set nginx-deploy-65dfbbb4d7 from 0 to 3
      Normal  ScalingReplicaSet  6m19s              deployment-controller  Scaled up replica set nginx-deploy-86c8cd48f6 from 0 to 1
      Normal  ScalingReplicaSet  6m10s              deployment-controller  Scaled down replica set nginx-deploy-65dfbbb4d7 from 3 to 2
      Normal  ScalingReplicaSet  6m10s              deployment-controller  Scaled up replica set nginx-deploy-86c8cd48f6 from 1 to 2
      Normal  ScalingReplicaSet  6m1s               deployment-controller  Scaled down replica set nginx-deploy-65dfbbb4d7 from 2 to 1
      Normal  ScalingReplicaSet  6m1s               deployment-controller  Scaled up replica set nginx-deploy-86c8cd48f6 from 2 to 3
      Normal  ScalingReplicaSet  5m51s              deployment-controller  Scaled down replica set nginx-deploy-65dfbbb4d7 from 1 to 0
      Normal  ScalingReplicaSet  52s                deployment-controller  Scaled up replica set nginx-deploy-65dfbbb4d7 from 0 to 1
      Normal  ScalingReplicaSet  50s                deployment-controller  Scaled down replica set nginx-deploy-86c8cd48f6 from 3 to 2
      Normal  ScalingReplicaSet  46s (x4 over 50s)  deployment-controller  (combined from similar events): Scaled down replica set nginx-deploy-86c8cd48f6 from 1 to 0
    ```

List the ReplicaSets after the rollback.

```bash
kubectl get rs
```

??? example "Expected result"
    ```text
    NAME                      DESIRED   CURRENT   READY   AGE
    nginx-deploy-65dfbbb4d7   3         3         3       11m
    nginx-deploy-86c8cd48f6   0         0         0       8m12s
    ```

Delete the Deployment.

```bash
kubectl delete deploy nginx-deploy
```

??? example "Expected result"
    ```text
    deployment.apps "nginx-deploy" deleted from default namespace
    ```

Check for remaining nginx Deployments, ReplicaSets, and Pods.

```bash
kubectl get deploy,rs,pod -l app=nginx -o name
```

??? example "Expected result"
    ```text
    No output.
    ```

### 2026-09-08 - Chapter 4 validation

Select the workload cluster kubeconfig.

```bash
# Select the workload cluster kubeconfig.
export KUBECONFIG=~/.kube/myk8scluster_config
```

??? example "Expected result"
    ```text
    No output.
    ```

Display the active Kubernetes context.

```bash
# Display the active Kubernetes context.
kubectl config current-context
```

??? example "Expected result"
    ```text
    myk8scluster-admin@myk8scluster
    ```

Display the multi-container Pod definition.

```bash
# Display the multi-container Pod definition.
cat ~/resources/multi-container-pod.yaml
```

??? example "Expected result"
    ```text
    apiVersion: v1
    kind: Pod
    metadata:
      name: two-containers
      labels:
        app: two-containers
    spec:
      restartPolicy: Never
      volumes:
      - name: shared-data
        emptyDir: {}
      containers:
      - name: nginx-container
        image: nginx:latest
        volumeMounts:
        - name: shared-data
          mountPath: /usr/share/nginx/html
      - name: debian-container
        image: debian
        volumeMounts:
        - name: shared-data
          mountPath: /pod-data
        command: ["/bin/sh"]
        args: ["-c", "echo Hello from the debian container > /pod-data/index.html; sleep 900000"]
    ```

Create the multi-container Pod.

```bash
# Create the multi-container Pod.
kubectl create -f ~/resources/multi-container-pod.yaml
```

??? example "Expected result"
    ```text
    pod/two-containers created
    ```

Wait for the multi-container Pod to become ready.

```bash
# Wait for the multi-container Pod to become ready.
kubectl wait --for=condition=Ready pod/two-containers --timeout=180s
```

??? example "Expected result"
    ```text
    pod/two-containers condition met
    ```

Create the multi-container Service.

```bash
# Create the multi-container Service.
kubectl create -f ~/resources/multi-container-pod-service.yaml
```

??? example "Expected result"
    ```text
    service/two-containers-svc created
    ```

Wait for a ready Service endpoint.

```bash
# Wait for a ready Service endpoint.
kubectl wait --for=jsonpath='{.endpoints[0].conditions.ready}'=true endpointslice -l kubernetes.io/service-name=two-containers-svc --timeout=180s
```

??? example "Expected result"
    ```text
    endpointslice.discovery.k8s.io/two-containers-svc-gf2wd condition met
    ```

Display the multi-container Service.

```bash
# Display the multi-container Service.
kubectl get svc two-containers-svc
```

??? example "Expected result"
    ```text
    NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
    two-containers-svc   ClusterIP   10.152.82.178   <none>        8080/TCP   0s
    ```

Save the Service ClusterIP.

```bash
# Save the Service ClusterIP.
CLUSTER_IP=$(kubectl get svc two-containers-svc -o jsonpath='{.spec.clusterIP}')
```

??? example "Expected result"
    ```text
    No output.
    ```

Display the Service ClusterIP.

```bash
# Display the Service ClusterIP.
printf "%s\n" "$CLUSTER_IP"
```

??? example "Expected result"
    ```text
    10.152.82.178
    ```

Probe the Service from the node.

```bash
# Probe the Service from the node.
lxc exec k8s-worker1 -- curl -fsS "http://$CLUSTER_IP:8080"
```

??? example "Expected result"
    ```text
    Hello from the debian container
    ```

Delete the multi-container Service.

```bash
# Delete the multi-container Service.
kubectl delete svc two-containers-svc --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    service "two-containers-svc" deleted from default namespace
    ```

Delete the multi-container Pod.

```bash
# Delete the multi-container Pod.
kubectl delete pod two-containers --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    pod "two-containers" deleted from default namespace
    ```

Check for the deleted multi-container Service.

```bash
# Check for the deleted multi-container Service.
kubectl get svc two-containers-svc -o name --ignore-not-found
```

??? example "Expected result"
    ```text
    No output.
    ```

Check for the deleted multi-container Pod.

```bash
# Check for the deleted multi-container Pod.
kubectl get pod two-containers -o name --ignore-not-found
```

??? example "Expected result"
    ```text
    No output.
    ```

Create a ConfigMap with literal values.

```bash
# Create a ConfigMap with literal values.
kubectl create configmap test-configmap --from-literal=val1=dan --from-literal=val2=bill --from-literal=val3=ben
```

??? example "Expected result"
    ```text
    configmap/test-configmap created
    ```

Describe the ConfigMap.

```bash
# Describe the ConfigMap.
kubectl describe configmap test-configmap
```

??? example "Expected result"
    ```text
    Name:         test-configmap
    Namespace:    default
    Labels:       <none>
    Annotations:  <none>

    Data
    ====
    val1:
    ----
    dan

    val2:
    ----
    bill

    val3:
    ----
    ben


    BinaryData
    ====

    Events:  <none>
    ```

Create the ConfigMap Pod.

```bash
# Create the ConfigMap Pod.
kubectl create -f ~/resources/pod-with-configmap.yaml
```

??? example "Expected result"
    ```text
    pod/configmap-pod created
    ```

Wait for the ConfigMap Pod to become ready.

```bash
# Wait for the ConfigMap Pod to become ready.
kubectl wait --for=condition=Ready pod/configmap-pod --timeout=180s
```

??? example "Expected result"
    ```text
    pod/configmap-pod condition met
    ```

Display ConfigMap environment variables in the Pod.

```bash
# Display ConfigMap environment variables in the Pod.
kubectl exec configmap-pod -- env | grep "^CONFIG_DATA_" | sort
```

??? example "Expected result"
    ```text
    CONFIG_DATA_val1=dan
    CONFIG_DATA_val2=bill
    CONFIG_DATA_val3=ben
    ```

Delete the ConfigMap Pod.

```bash
# Delete the ConfigMap Pod.
kubectl delete pod configmap-pod --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    pod "configmap-pod" deleted from default namespace
    ```

Delete the ConfigMap.

```bash
# Delete the ConfigMap.
kubectl delete configmap test-configmap --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    configmap "test-configmap" deleted from default namespace
    ```

Check for the deleted ConfigMap Pod.

```bash
# Check for the deleted ConfigMap Pod.
kubectl get pod configmap-pod -o name --ignore-not-found
```

??? example "Expected result"
    ```text
    No output.
    ```

Check for the deleted ConfigMap.

```bash
# Check for the deleted ConfigMap.
kubectl get configmap test-configmap -o name --ignore-not-found
```

??? example "Expected result"
    ```text
    No output.
    ```

Create the Secret with username and password values.

```bash
# Create the Secret with username and password values.
kubectl create secret generic bob-secret --from-literal=username="bob" --from-literal=password="Passw0rd"
```

??? example "Expected result"
    ```text
    secret/bob-secret created
    ```

Display the Secret.

```bash
# Display the Secret.
kubectl get secret bob-secret
```

??? example "Expected result"
    ```text
    NAME         TYPE     DATA   AGE
    bob-secret   Opaque   2      0s
    ```

Describe the Secret.

```bash
# Describe the Secret.
kubectl describe secret bob-secret
```

??? example "Expected result"
    ```text
    Name:         bob-secret
    Namespace:    default
    Labels:       <none>
    Annotations:  <none>

    Type:  Opaque

    Data
    ====
    password:  8 bytes
    username:  3 bytes
    ```

Display the Secret manifest.

```bash
# Display the Secret manifest.
kubectl get secret bob-secret -o yaml
```

??? example "Expected result"
    ```yaml
    apiVersion: v1
    data:
      password: UGFzc3cwcmQ=
      username: Ym9i
    kind: Secret
    metadata:
      creationTimestamp: "2026-09-08T16:25:10Z"
      name: bob-secret
      namespace: default
      resourceVersion: "62468"
      uid: b644add5-a0dd-43b9-b725-7e4b1ca63933
    type: Opaque
    ```

Display the Pod definition that consumes the Secret.

```bash
# Display the Pod definition that consumes the Secret.
cat ~/resources/pod-with-secrets.yaml
```

??? example "Expected result"
    ```text
    apiVersion: v1
    kind: Pod
    metadata:
      name: pod-with-secrets
    spec:
      containers:
      - name: container-with-secrets
        image: nginx:latest
        env:
        - name: SECRET_USERNAME
          valueFrom:
            secretKeyRef:
              name: bob-secret
              key: username
        - name: SECRET_PASSWORD
          valueFrom:
            secretKeyRef:
              name: bob-secret
              key: password
    ```

Create the Pod with Secret environment variables.

```bash
# Create the Pod with Secret environment variables.
kubectl create -f ~/resources/pod-with-secrets.yaml
```

??? example "Expected result"
    ```text
    pod/pod-with-secrets created
    ```

Wait for the Secret Pod to become ready.

```bash
# Wait for the Secret Pod to become ready.
kubectl wait --for=condition=Ready pod/pod-with-secrets --timeout=180s
```

??? example "Expected result"
    ```text
    pod/pod-with-secrets condition met
    ```

Display Secret environment variables in the Pod.

```bash
# Display Secret environment variables in the Pod.
kubectl exec pod-with-secrets -- env | grep "^SECRET_" | sort
```

??? example "Expected result"
    ```text
    SECRET_PASSWORD=Passw0rd
    SECRET_USERNAME=bob
    ```

Delete the Secret Pod.

```bash
# Delete the Secret Pod.
kubectl delete pod pod-with-secrets --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    pod "pod-with-secrets" deleted from default namespace
    ```

Delete the Secret.

```bash
# Delete the Secret.
kubectl delete secret bob-secret --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    secret "bob-secret" deleted from default namespace
    ```

Check for the deleted Secret Pod.

```bash
# Check for the deleted Secret Pod.
kubectl get pod pod-with-secrets -o name --ignore-not-found
```

??? example "Expected result"
    ```text
    No output.
    ```

Check for the deleted Secret.

```bash
# Check for the deleted Secret.
kubectl get secret bob-secret -o name --ignore-not-found
```

??? example "Expected result"
    ```text
    No output.
    ```

List StorageClasses.

```bash
# List StorageClasses.
kubectl get sc
```

??? example "Expected result"
    ```text
    NAME                            PROVISIONER              RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
    csi-rawfile-default (default)   rawfile.csi.openebs.io   Delete          WaitForFirstConsumer   false                  6h28m
    ```

Describe the default StorageClass.

```bash
# Describe the default StorageClass.
kubectl describe sc csi-rawfile-default
```

??? example "Expected result"
    ```text
    Name:                  csi-rawfile-default
    IsDefaultClass:        Yes
    Annotations:           meta.helm.sh/release-name=ck-storage,meta.helm.sh/release-namespace=kube-system,storageclass.kubernetes.io/is-default-class=true
    Provisioner:           rawfile.csi.openebs.io
    Parameters:            <none>
    AllowVolumeExpansion:  False
    MountOptions:          <none>
    ReclaimPolicy:         Delete
    VolumeBindingMode:     WaitForFirstConsumer
    Events:                <none>
    ```

Create the PersistentVolumeClaim.

```bash
# Create the PersistentVolumeClaim.
kubectl create -f ~/resources/hostpath-pvc.yaml
```

??? example "Expected result"
    ```text
    persistentvolumeclaim/hostpath-pvc created
    ```

Display the pending PersistentVolumeClaim.

```bash
# Display the pending PersistentVolumeClaim.
kubectl get pvc hostpath-pvc
```

??? example "Expected result"
    ```text
    NAME           STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS          VOLUMEATTRIBUTESCLASS   AGE
    hostpath-pvc   Pending                                      csi-rawfile-default   <unset>                 1s
    ```

Describe the pending PersistentVolumeClaim.

```bash
# Describe the pending PersistentVolumeClaim.
kubectl describe pvc hostpath-pvc
```

??? example "Expected result"
    ```text
    Name:          hostpath-pvc
    Namespace:     default
    StorageClass:  csi-rawfile-default
    Status:        Pending
    Volume:
    Labels:        <none>
    Annotations:   <none>
    Finalizers:    [kubernetes.io/pvc-protection]
    Capacity:
    Access Modes:
    VolumeMode:    Filesystem
    Used By:       <none>
    Events:
      Type    Reason                Age   From                         Message
      ----    ------                ----  ----                         -------
      Normal  WaitForFirstConsumer  1s    persistentvolume-controller  waiting for first consumer to be created before binding
    ```

Display PersistentVolumes before creating a consumer.

```bash
# Display PersistentVolumes before creating a consumer.
kubectl get pv
```

??? example "Expected result"
    ```text
    No resources found
    ```

Create the busybox Pod with the PersistentVolumeClaim.

```bash
# Create the busybox Pod with the PersistentVolumeClaim.
kubectl create -f ~/resources/busybox-with-pv.yaml
```

??? example "Expected result"
    ```text
    pod/busybox created
    ```

Wait for the PersistentVolumeClaim to become bound.

```bash
# Wait for the PersistentVolumeClaim to become bound.
kubectl wait --for=jsonpath='{.status.phase}'=Bound pvc/hostpath-pvc --timeout=180s
```

??? example "Expected result"
    ```text
    persistentvolumeclaim/hostpath-pvc condition met
    ```

Wait for the busybox Pod to become ready.

```bash
# Wait for the busybox Pod to become ready.
kubectl wait --for=condition=Ready pod/busybox --timeout=180s
```

??? example "Expected result"
    ```text
    pod/busybox condition met
    ```

Display the bound PersistentVolumeClaim.

```bash
# Display the bound PersistentVolumeClaim.
kubectl get pvc hostpath-pvc
```

??? example "Expected result"
    ```text
    NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS          VOLUMEATTRIBUTESCLASS   AGE
    hostpath-pvc   Bound    pvc-d9a10756-3433-4237-840e-17181b4417b0   10Gi       RWO            csi-rawfile-default   <unset>                 37s
    ```

Save the generated PersistentVolume name.

```bash
# Save the generated PersistentVolume name.
PV_NAME=$(kubectl get pvc hostpath-pvc -o jsonpath='{.spec.volumeName}')
```

??? example "Expected result"
    ```text
    No output.
    ```

Display the generated PersistentVolume name.

```bash
# Display the generated PersistentVolume name.
printf "%s\n" "$PV_NAME"
```

??? example "Expected result"
    ```text
    pvc-d9a10756-3433-4237-840e-17181b4417b0
    ```

Display the generated PersistentVolume.

```bash
# Display the generated PersistentVolume.
kubectl get pv "$PV_NAME"
```

??? example "Expected result"
    ```text
    NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                  STORAGECLASS          VOLUMEATTRIBUTESCLASS   REASON   AGE
    pvc-d9a10756-3433-4237-840e-17181b4417b0   10Gi       RWO            Delete           Bound    default/hostpath-pvc   csi-rawfile-default   <unset>                          6s
    ```

Display the PersistentVolume mount.

```bash
# Display the PersistentVolume mount.
kubectl exec busybox -- mount | grep " on /pv "
```

??? example "Expected result"
    ```text
    /dev/loop3 on /pv type ext4 (rw,relatime)
    ```

Create a file on the PersistentVolume.

```bash
# Create a file on the PersistentVolume.
kubectl exec busybox -- touch /pv/hello-world.txt
```

??? example "Expected result"
    ```text
    No output.
    ```

Write text to the PersistentVolume file.

```bash
# Write text to the PersistentVolume file.
kubectl exec busybox -- sh -c "echo 'Hello world from busybox pod!' > /pv/hello-world.txt"
```

??? example "Expected result"
    ```text
    No output.
    ```

Display the PersistentVolume file.

```bash
# Display the PersistentVolume file.
kubectl exec busybox -- cat /pv/hello-world.txt
```

??? example "Expected result"
    ```text
    Hello world from busybox pod!
    ```

Delete the busybox Pod.

```bash
# Delete the busybox Pod.
kubectl delete pod busybox --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    pod "busybox" deleted from default namespace
    ```

Create the nginx Pod with the PersistentVolumeClaim.

```bash
# Create the nginx Pod with the PersistentVolumeClaim.
kubectl create -f ~/resources/nginx-with-pv.yaml
```

??? example "Expected result"
    ```text
    pod/nginx created
    ```

Wait for the nginx Pod to become ready.

```bash
# Wait for the nginx Pod to become ready.
kubectl wait --for=condition=Ready pod/nginx --timeout=180s
```

??? example "Expected result"
    ```text
    pod/nginx condition met
    ```

List the PersistentVolume file from the replacement Pod.

```bash
# List the PersistentVolume file from the replacement Pod.
kubectl exec nginx -- ls -l /pv/hello-world.txt
```

??? example "Expected result"
    ```text
    -rw-r--r-- 1 root root 30 Sep  8 16:26 /pv/hello-world.txt
    ```

Display the PersistentVolume file from the replacement Pod.

```bash
# Display the PersistentVolume file from the replacement Pod.
kubectl exec nginx -- cat /pv/hello-world.txt
```

??? example "Expected result"
    ```text
    Hello world from busybox pod!
    ```

Refresh the generated PersistentVolume name before cleanup.

```bash
# Refresh the generated PersistentVolume name before cleanup.
PV_NAME=$(kubectl get pvc hostpath-pvc -o jsonpath='{.spec.volumeName}')
```

??? example "Expected result"
    ```text
    No output.
    ```

Delete the nginx Pod.

```bash
# Delete the nginx Pod.
kubectl delete pod nginx --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    pod "nginx" deleted from default namespace
    ```

Delete the PersistentVolumeClaim.

```bash
# Delete the PersistentVolumeClaim.
kubectl delete pvc hostpath-pvc --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    persistentvolumeclaim "hostpath-pvc" deleted from default namespace
    ```

Wait for the generated PersistentVolume to be deleted.

```bash
# Wait for the generated PersistentVolume to be deleted.
kubectl wait --for=delete "pv/$PV_NAME" --timeout=180s
```

??? example "Expected result"
    ```text
    No output.
    ```

Check for the deleted nginx Pod.

```bash
# Check for the deleted nginx Pod.
kubectl get pod nginx -o name --ignore-not-found
```

??? example "Expected result"
    ```text
    No output.
    ```

Check for the deleted PersistentVolumeClaim.

```bash
# Check for the deleted PersistentVolumeClaim.
kubectl get pvc hostpath-pvc -o name --ignore-not-found
```

??? example "Expected result"
    ```text
    No output.
    ```

Check for the deleted PersistentVolume.

```bash
# Check for the deleted PersistentVolume.
kubectl get pv "$PV_NAME" -o name --ignore-not-found
```

??? example "Expected result"
    ```text
    No output.
    ```

### 2026-09-08 - Chapter 5 validation

Select the workload cluster kubeconfig.

```bash
# Select the workload cluster kubeconfig.
export KUBECONFIG=~/.kube/myk8scluster_config
```

??? example "Expected result"
    ```text
    No output.
    ```

Display the active Kubernetes context.

```bash
# Display the active Kubernetes context.
kubectl config current-context
```

??? example "Expected result"
    ```text
    myk8scluster-admin@myk8scluster
    ```

Display current node resource usage.

```bash
# Display current node resource usage.
kubectl top nodes
```

??? example "Expected result"
    ```text
    NAME          CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)
    k8s-ctrl      191m         4%       1824Mi          23%
    k8s-worker1   90m          2%       1067Mi          13%
    k8s-worker2   96m          2%       1093Mi          13%
    ```

Create the nginx Deployment.

```bash
# Create the nginx Deployment.
kubectl create deployment nginx-hpa --image=nginx
```

??? example "Expected result"
    ```text
    deployment.apps/nginx-hpa created
    ```

Expose the nginx Deployment on port 80.

```bash
# Expose the nginx Deployment on port 80.
kubectl expose deployment nginx-hpa --port=80
```

??? example "Expected result"
    ```text
    service/nginx-hpa exposed
    ```

Set the nginx container CPU request.

```bash
# Set the nginx container CPU request.
kubectl set resources deployment nginx-hpa --requests=cpu=100m
```

??? example "Expected result"
    ```text
    deployment.apps/nginx-hpa resource requirements updated
    ```

Wait for the nginx Deployment rollout.

```bash
# Wait for the nginx Deployment rollout.
kubectl rollout status deployment/nginx-hpa --timeout=180s
```

??? example "Expected result"
    ```text
    deployment "nginx-hpa" successfully rolled out
    ```

Wait for a ready nginx Service endpoint.

```bash
# Wait for a ready nginx Service endpoint.
kubectl wait --for=jsonpath='{.endpoints[0].conditions.ready}'=true endpointslice -l kubernetes.io/service-name=nginx-hpa --timeout=180s
```

??? example "Expected result"
    ```text
    endpointslice.discovery.k8s.io/nginx-hpa-9fr9v condition met
    ```

Display the nginx Deployment.

```bash
# Display the nginx Deployment.
kubectl get deployment nginx-hpa
```

??? example "Expected result"
    ```text
    NAME        READY   UP-TO-DATE   AVAILABLE   AGE
    nginx-hpa   1/1     1            1           70s
    ```

Display the nginx Service.

```bash
# Display the nginx Service.
kubectl get service nginx-hpa
```

??? example "Expected result"
    ```text
    NAME        TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
    nginx-hpa   ClusterIP   10.152.124.160   <none>        80/TCP    60s
    ```

Display the nginx container CPU request.

```bash
# Display the nginx container CPU request.
kubectl get deployment nginx-hpa -o jsonpath='{.spec.template.spec.containers[0].resources.requests.cpu}{"\n"}'
```

??? example "Expected result"
    ```text
    100m
    ```

Create the nginx HorizontalPodAutoscaler.

```bash
# Create the nginx HorizontalPodAutoscaler.
kubectl autoscale deployment nginx-hpa --cpu 30% --min=1 --max=5
```

??? example "Expected result"
    ```text
    horizontalpodautoscaler.autoscaling/nginx-hpa autoscaled
    ```

Wait for the HPA metric to become active.

```bash
# Wait for the HPA metric to become active.
kubectl wait --for=condition=ScalingActive hpa/nginx-hpa --timeout=180s
```

??? example "Expected result"
    ```text
    horizontalpodautoscaler.autoscaling/nginx-hpa condition met
    ```

Display the HPA replica bounds and CPU target.

```bash
# Display the HPA replica bounds and CPU target.
kubectl get hpa nginx-hpa -o jsonpath='{.spec.minReplicas}{"\t"}{.spec.maxReplicas}{"\t"}{.spec.metrics[0].resource.target.averageUtilization}{"%\n"}'
```

??? example "Expected result"
    ```text
    1    5    30%
    ```

Display the initial HPA status.

```bash
# Display the initial HPA status.
kubectl get hpa nginx-hpa
```

??? example "Expected result"
    ```text
    NAME        REFERENCE              TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
    nginx-hpa   Deployment/nginx-hpa   cpu: 0%/30%   1         5         1          44s
    ```

Start bounded load against the nginx Service.

```bash
# Start bounded load against the nginx Service.
kubectl run load-generator --image=busybox --restart=Never -- /bin/sh -c 'for worker in 1 2 3 4; do timeout 360 sh -c "while true; do wget -q -O /dev/null http://nginx-hpa; done" & done; wait'
```

??? example "Expected result"
    ```text
    pod/load-generator created
    ```

Wait for the load-generator Pod.

```bash
# Wait for the load-generator Pod.
kubectl wait --for=condition=Ready pod/load-generator --timeout=180s
```

??? example "Expected result"
    ```text
    pod/load-generator condition met
    ```

Wait for the HPA to scale above one replica.

```bash
# Wait for the HPA to scale above one replica.
timeout 300 bash -c 'until replicas=$(kubectl get hpa nginx-hpa -o jsonpath="{.status.currentReplicas}"); [[ "$replicas" =~ ^[2-5]$ ]]; do sleep 10; done'
```

??? example "Expected result"
    ```text
    No output.
    ```

Wait for multiple nginx Pods to become ready.

```bash
# Wait for multiple nginx Pods to become ready.
timeout 180 bash -c 'until replicas=$(kubectl get deployment nginx-hpa -o jsonpath="{.status.readyReplicas}"); [[ "$replicas" =~ ^[2-5]$ ]]; do sleep 5; done'
```

??? example "Expected result"
    ```text
    No output.
    ```

Display the HPA after scale-up.

```bash
# Display the HPA after scale-up.
kubectl get hpa nginx-hpa
```

??? example "Expected result"
    ```text
    NAME        REFERENCE              TARGETS        MINPODS   MAXPODS   REPLICAS   AGE
    nginx-hpa   Deployment/nginx-hpa   cpu: 37%/30%   1         5         5          3m15s
    ```

Display the scaled nginx Pods.

```bash
# Display the scaled nginx Pods.
kubectl get pods -l app=nginx-hpa
```

??? example "Expected result"
    ```text
    NAME                         READY   STATUS    RESTARTS   AGE
    nginx-hpa-7698f65fcb-49m27   1/1     Running   0          4m23s
    nginx-hpa-7698f65fcb-fq8qs   1/1     Running   0          75s
    nginx-hpa-7698f65fcb-prwvp   1/1     Running   0          60s
    nginx-hpa-7698f65fcb-pv7n5   1/1     Running   0          75s
    nginx-hpa-7698f65fcb-xjhwq   1/1     Running   0          75s
    ```

Display the load-generator Pod.

```bash
# Display the load-generator Pod.
kubectl get pod load-generator
```

??? example "Expected result"
    ```text
    NAME             READY   STATUS    RESTARTS   AGE
    load-generator   1/1     Running   0          104s
    ```

Stop and delete the load-generator Pod.

```bash
# Stop and delete the load-generator Pod.
kubectl delete pod load-generator --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    pod "load-generator" deleted from default namespace
    ```

Wait for the HPA and Deployment to scale down to one replica.

```bash
# Wait for the HPA and Deployment to scale down to one replica.
timeout 600 bash -c 'until [[ "$(kubectl get hpa nginx-hpa -o jsonpath="{.status.currentReplicas}")" == "1" && "$(kubectl get deployment nginx-hpa -o jsonpath="{.status.readyReplicas}")" == "1" ]]; do sleep 15; done'
```

??? example "Expected result"
    ```text
    No output.
    ```

Display the HPA after scale-down.

```bash
# Display the HPA after scale-down.
kubectl get hpa nginx-hpa
```

??? example "Expected result"
    ```text
    NAME        REFERENCE              TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
    nginx-hpa   Deployment/nginx-hpa   cpu: 0%/30%   1         5         1          10m
    ```

Display the Deployment after scale-down.

```bash
# Display the Deployment after scale-down.
kubectl get deployment nginx-hpa
```

??? example "Expected result"
    ```text
    NAME        READY   UP-TO-DATE   AVAILABLE   AGE
    nginx-hpa   1/1     1            1           11m
    ```

Display the nginx Pod after scale-down.

```bash
# Display the nginx Pod after scale-down.
kubectl get pods -l app=nginx-hpa
```

??? example "Expected result"
    ```text
    NAME                         READY   STATUS    RESTARTS   AGE
    nginx-hpa-7698f65fcb-pv7n5   1/1     Running   0          8m21s
    ```

Describe the nginx HorizontalPodAutoscaler.

```bash
# Describe the nginx HorizontalPodAutoscaler.
kubectl describe hpa nginx-hpa
```

??? example "Expected result"
    ```text
    Name:                                                  nginx-hpa
    Namespace:                                             default
    Labels:                                                <none>
    Annotations:                                           <none>
    CreationTimestamp:                                     Tue, 08 Sep 2026 17:14:16 +0000
    Reference:                                             Deployment/nginx-hpa
    Metrics:                                               ( current / target )
      resource cpu on pods  (as a percentage of request):  0% (0) / 30%
    Min replicas:                                          1
    Max replicas:                                          5
    Deployment pods:                                       1 current / 1 desired
    Conditions:
      Type            Status  Reason            Message
      ----            ------  ------            -------
      AbleToScale     True    ReadyForNewScale  recommended size matches current size
      ScalingActive   True    ValidMetricFound  the HPA was able to successfully calculate a replica count from cpu resource utilization (percentage of request)
      ScalingLimited  True    TooFewReplicas    the desired replica count is less than the minimum replica count
    Events:
      Type    Reason             Age    From                       Message
      ----    ------             ----   ----                       -------
      Normal  SuccessfulRescale  8m21s  horizontal-pod-autoscaler  New size: 4; reason: cpu resource utilization (percentage of request) above target
      Normal  SuccessfulRescale  8m6s   horizontal-pod-autoscaler  New size: 5; reason:
      Normal  SuccessfulRescale  66s    horizontal-pod-autoscaler  New size: 4; reason: All metrics below target
      Normal  SuccessfulRescale  51s    horizontal-pod-autoscaler  New size: 1; reason: All metrics below target
    ```

Display events for the nginx HorizontalPodAutoscaler.

```bash
# Display events for the nginx HorizontalPodAutoscaler.
kubectl events --for hpa/nginx-hpa
```

??? example "Expected result"
    ```text
    LAST SEEN   TYPE     REASON              OBJECT                              MESSAGE
    8m21s       Normal   SuccessfulRescale   HorizontalPodAutoscaler/nginx-hpa   New size: 4; reason: cpu resource utilization (percentage of request) above target
    8m6s        Normal   SuccessfulRescale   HorizontalPodAutoscaler/nginx-hpa   New size: 5; reason:
    66s         Normal   SuccessfulRescale   HorizontalPodAutoscaler/nginx-hpa   New size: 4; reason: All metrics below target
    51s         Normal   SuccessfulRescale   HorizontalPodAutoscaler/nginx-hpa   New size: 1; reason: All metrics below target
    ```

Delete the nginx HorizontalPodAutoscaler.

```bash
# Delete the nginx HorizontalPodAutoscaler.
kubectl delete hpa nginx-hpa --ignore-not-found --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    horizontalpodautoscaler.autoscaling "nginx-hpa" deleted from default namespace
    ```

Delete the nginx Deployment.

```bash
# Delete the nginx Deployment.
kubectl delete deployment nginx-hpa --ignore-not-found --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    deployment.apps "nginx-hpa" deleted from default namespace
    ```

Delete the nginx Service.

```bash
# Delete the nginx Service.
kubectl delete service nginx-hpa --ignore-not-found --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    service "nginx-hpa" deleted from default namespace
    ```

Check for remaining Chapter 5 resources.

```bash
# Check for remaining Chapter 5 resources.
kubectl get deployment/nginx-hpa service/nginx-hpa horizontalpodautoscaler/nginx-hpa pod/load-generator -o name --ignore-not-found
```

??? example "Expected result"
    ```text
    No output.
    ```

Check for remaining nginx ReplicaSets and Pods.

```bash
# Check for remaining nginx ReplicaSets and Pods.
kubectl get replicaset,pod -l app=nginx-hpa -o name
```

??? example "Expected result"
    ```text
    No output.
    ```

Wait for all cluster nodes to remain ready.

```bash
# Wait for all cluster nodes to remain ready.
kubectl wait --for=condition=Ready nodes --all --timeout=180s
```

??? example "Expected result"
    ```text
    node/k8s-ctrl condition met
    node/k8s-worker1 condition met
    node/k8s-worker2 condition met
    ```

Display the final cluster node status.

```bash
# Display the final cluster node status.
kubectl get nodes
```

??? example "Expected result"
    ```text
    NAME          STATUS   ROLES                  AGE     VERSION
    k8s-ctrl      Ready    control-plane,worker   7h28m   v1.35.7
    k8s-worker1   Ready    worker                 7h17m   v1.35.7
    k8s-worker2   Ready    worker                 7h17m   v1.35.7
    ```

### 2026-09-08 - Chapter 6 validation

Select the workload cluster kubeconfig.

```bash
# Select the workload cluster kubeconfig.
export KUBECONFIG=~/.kube/myk8scluster_config
```

??? example "Expected result"
    ```text
    No output.
    ```

Display the active Kubernetes context.

```bash
# Display the active Kubernetes context.
kubectl config current-context
```

??? example "Expected result"
    ```text
    myk8scluster-admin@myk8scluster
    ```

List namespaces.

```bash
# List namespaces.
kubectl get namespace
```

??? example "Expected result"
    ```text
    NAME              STATUS   AGE
    cilium-secrets    Active   7h48m
    default           Active   7h48m
    kube-node-lease   Active   7h48m
    kube-public       Active   7h48m
    kube-system       Active   7h48m
    metallb-system    Active   7h48m
    ```

List ServiceAccounts in the default namespace.

```bash
# List ServiceAccounts in the default namespace.
kubectl get sa
```

??? example "Expected result"
    ```text
    NAME      AGE
    default   7h48m
    ```

List ServiceAccounts in all namespaces.

```bash
# List ServiceAccounts in all namespaces.
kubectl get sa --all-namespaces
```

??? example "Expected result"
    ```text
    NAMESPACE         NAME                                          AGE
    cilium-secrets    default                                       7h48m
    default           default                                       7h48m
    kube-node-lease   default                                       7h48m
    kube-public       default                                       7h48m
    kube-system       attachdetach-controller                       7h48m
    kube-system       certificate-controller                        7h48m
    kube-system       cilium                                        7h48m
    kube-system       cilium-operator                               7h48m
    kube-system       ck-storage-rawfile-csi-driver                 7h48m
    kube-system       clusterrole-aggregation-controller            7h48m
    kube-system       coredns                                       7h48m
    kube-system       cronjob-controller                            7h48m
    kube-system       daemon-set-controller                         7h48m
    kube-system       default                                       7h48m
    kube-system       deployment-controller                         7h48m
    kube-system       disruption-controller                         7h48m
    kube-system       endpoint-controller                           7h48m
    kube-system       endpointslice-controller                      7h48m
    kube-system       endpointslicemirroring-controller             7h48m
    kube-system       ephemeral-volume-controller                   7h48m
    kube-system       expand-controller                             7h48m
    kube-system       generic-garbage-collector                     7h48m
    kube-system       horizontal-pod-autoscaler                     7h48m
    kube-system       job-controller                                7h48m
    kube-system       legacy-service-account-token-cleaner          7h48m
    kube-system       metrics-server                                7h48m
    kube-system       namespace-controller                          7h48m
    kube-system       node-controller                               7h48m
    kube-system       persistent-volume-binder                      7h48m
    kube-system       pod-garbage-collector                         7h48m
    kube-system       pv-protection-controller                      7h48m
    kube-system       pvc-protection-controller                     7h48m
    kube-system       replicaset-controller                         7h48m
    kube-system       replication-controller                        7h48m
    kube-system       resource-claim-controller                     7h48m
    kube-system       resourcequota-controller                      7h48m
    kube-system       root-ca-cert-publisher                        7h48m
    kube-system       service-account-controller                    7h48m
    kube-system       service-cidrs-controller                      7h48m
    kube-system       statefulset-controller                        7h48m
    kube-system       ttl-after-finished-controller                 7h48m
    kube-system       ttl-controller                                7h48m
    kube-system       validatingadmissionpolicy-status-controller   7h48m
    kube-system       volumeattributesclass-protection-controller   7h48m
    metallb-system    default                                       7h48m
    metallb-system    metallb-controller                            7h48m
    metallb-system    metallb-speaker                               7h48m
    ```

Describe the default ServiceAccount.

```bash
# Describe the default ServiceAccount.
kubectl describe sa default
```

??? example "Expected result"
    ```text
    Name:                default
    Namespace:           default
    Labels:              <none>
    Annotations:         <none>
    Image pull secrets:  <none>
    Events:              <none>
    ```

Display the token Secret definition.

```bash
# Display the token Secret definition.
cat ~/resources/service-account-token.yaml
```

??? example "Expected result"
    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: default-serviceaccount-secret
      annotations:
        kubernetes.io/service-account.name: default
    type: kubernetes.io/service-account-token
    ```

Create the default ServiceAccount token Secret.

```bash
# Create the default ServiceAccount token Secret.
kubectl create -f ~/resources/service-account-token.yaml
```

??? example "Expected result"
    ```text
    secret/default-serviceaccount-secret created
    ```

Wait for token data to be generated.

```bash
# Wait for token data to be generated.
kubectl wait --for=jsonpath='{.data.token}' secret/default-serviceaccount-secret --timeout=120s
```

??? example "Expected result"
    ```text
    secret/default-serviceaccount-secret condition met
    ```

Display the token Secret summary without its credential data.

```bash
# Display the token Secret summary.
kubectl get secret default-serviceaccount-secret
```

??? example "Expected result"
    ```text
    NAME                            TYPE                                  DATA   AGE
    default-serviceaccount-secret   kubernetes.io/service-account-token   3      115s
    ```

Display the ServiceAccount named by the Secret annotation.

```bash
# Display the ServiceAccount named by the Secret annotation.
kubectl get secret default-serviceaccount-secret -o jsonpath='{.metadata.annotations.kubernetes\.io/service-account\.name}{"\n"}'
```

??? example "Expected result"
    ```text
    default
    ```

Display the curl Pod definition.

```bash
# Display the curl Pod definition.
cat ~/resources/curl-pod.yaml
```

??? example "Expected result"
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: curl
    spec:
      containers:
      - name: curl
        image: alpine
        command: ["sleep", "999999"]
    ```

Create the curl Pod.

```bash
# Create the curl Pod.
kubectl create -f ~/resources/curl-pod.yaml
```

??? example "Expected result"
    ```text
    pod/curl created
    ```

Wait for the curl Pod.

```bash
# Wait for the curl Pod.
kubectl wait --for=condition=Ready pod/curl --timeout=180s
```

??? example "Expected result"
    ```text
    pod/curl condition met
    ```

Display the Pod's ServiceAccount name.

```bash
# Display the Pod's ServiceAccount name.
kubectl get pod curl -o jsonpath='{.spec.serviceAccountName}{"\n"}'
```

??? example "Expected result"
    ```text
    default
    ```

Describe the curl Pod.

```bash
# Describe the curl Pod.
kubectl describe pod curl
```

??? example "Expected result"
    ```text
    Name:             curl
    Namespace:        default
    Service Account:  default
    Node:             k8s-worker1/10.107.242.63
    Status:           Running
    IP:               10.1.1.78
    ...
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-pn4fl (ro)
    ...
    Volumes:
      kube-api-access-pn4fl:
        Type:                    Projected (a volume that contains injected data from multiple sources)
        TokenExpirationSeconds:  3607
        ConfigMapName:           kube-root-ca.crt
        Optional:                false
        DownwardAPI:             true
    ```

List the mounted ServiceAccount files.

```bash
# List the mounted ServiceAccount files.
timeout 30 kubectl exec curl -- ls -l /var/run/secrets/kubernetes.io/serviceaccount/
```

??? example "Expected result"
    ```text
    total 0
    lrwxrwxrwx    1 root     root            13 Sep  8 17:47 ca.crt -> ..data/ca.crt
    lrwxrwxrwx    1 root     root            16 Sep  8 17:47 namespace -> ..data/namespace
    lrwxrwxrwx    1 root     root            12 Sep  8 17:47 token -> ..data/token
    ```

Install curl in the Pod.

```bash
# Install curl in the Pod.
timeout 180 kubectl exec curl -- apk add --no-cache curl
```

??? example "Expected result"
    ```text
    (1/9) Installing brotli-libs (1.2.0-r1)
    (2/9) Installing c-ares (1.34.8-r0)
    (3/9) Installing libunistring (1.4.2-r0)
    (4/9) Installing libidn2 (2.3.8-r0)
    (5/9) Installing nghttp2-libs (1.69.0-r0)
    (6/9) Installing libpsl (0.21.5-r3)
    (7/9) Installing zstd-libs (1.5.7-r2)
    (8/9) Installing libcurl (8.22.0-r0)
    (9/9) Installing curl (8.22.0-r0)
    Executing busybox-1.37.0-r31.trigger
    OK: 13.1 MiB in 25 packages
    ```

Verify authenticated API root discovery.

```bash
# Verify authenticated API root discovery.
timeout 60 kubectl exec curl -- sh -ec 'TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token); code=$(curl --silent --show-error --connect-timeout 10 --max-time 30 --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $TOKEN" -o /tmp/api.json -w "%{http_code}" https://kubernetes/api); test "$code" = 200; grep -q APIVersions /tmp/api.json; printf "/api: HTTP %s (APIVersions)\n" "$code"'
```

??? example "Expected result"
    ```text
    /api: HTTP 200 (APIVersions)
    ```

Verify authenticated core API discovery.

```bash
# Verify authenticated core API discovery.
timeout 60 kubectl exec curl -- sh -ec 'TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token); code=$(curl --silent --show-error --connect-timeout 10 --max-time 30 --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $TOKEN" -o /tmp/api-v1.json -w "%{http_code}" https://kubernetes/api/v1); test "$code" = 200; grep -q APIResourceList /tmp/api-v1.json; printf "/api/v1: HTTP %s (APIResourceList)\n" "$code"'
```

??? example "Expected result"
    ```text
    /api/v1: HTTP 200 (APIResourceList)
    ```

Delete the curl Pod.

```bash
# Delete the curl Pod.
kubectl delete pod curl --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    pod "curl" deleted from default namespace
    ```

Delete the token Secret.

```bash
# Delete the token Secret.
kubectl delete secret default-serviceaccount-secret --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    secret "default-serviceaccount-secret" deleted from default namespace
    ```

Display the API server authorization mode.

```bash
# Display the API server authorization mode.
timeout 30 lxc exec k8s-ctrl -- sh -c 'ps auxww | grep "[k]ube-apiserver"' | grep -o -- '--authorization-mode=[^ ]*'
```

??? example "Expected result"
    ```text
    --authorization-mode=Node,RBAC
    ```

Display the standard access ClusterRoles.

```bash
# Display the standard access ClusterRoles.
kubectl get clusterroles admin edit view cluster-admin
```

??? example "Expected result"
    ```text
    NAME            CREATED AT
    admin           2026-09-08T09:57:34Z
    edit            2026-09-08T09:57:34Z
    view            2026-09-08T09:57:34Z
    cluster-admin   2026-09-08T09:57:34Z
    ```

Display the student ServiceAccount definition.

```bash
# Display the student ServiceAccount definition.
cat ~/resources/student-sa.yaml
```

??? example "Expected result"
    ```yaml
    apiVersion: v1
    kind: ServiceAccount
    metadata:
     name: student-sa
     namespace: default
    ```

Create the student ServiceAccount.

```bash
# Create the student ServiceAccount.
kubectl create -f ~/resources/student-sa.yaml
```

??? example "Expected result"
    ```text
    serviceaccount/student-sa created
    ```

Display the pod-reader Role definition.

```bash
# Display the pod-reader Role definition.
cat ~/resources/pod-reader-role.yaml
```

??? example "Expected result"
    ```yaml
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      namespace: default
      name: pod-reader
    rules:
    - apiGroups: [""]
      resources: ["pods"]
      verbs: ["get", "watch", "list"]
    ```

Create the pod-reader Role.

```bash
# Create the pod-reader Role.
kubectl create -f ~/resources/pod-reader-role.yaml
```

??? example "Expected result"
    ```text
    role.rbac.authorization.k8s.io/pod-reader created
    ```

Display the pod-reader RoleBinding definition.

```bash
# Display the pod-reader RoleBinding definition.
cat ~/resources/pod-reader-rb.yaml
```

??? example "Expected result"
    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: read-pods
      namespace: default
    subjects:
    - kind: ServiceAccount
      name: student-sa
    roleRef:
      kind: Role #this must be Role or ClusterRole
      name: pod-reader # this must match the name of the Role or ClusterRole you wish to bind to
      apiGroup: rbac.authorization.k8s.io
    ```

Create the pod-reader RoleBinding.

```bash
# Create the pod-reader RoleBinding.
kubectl create -f ~/resources/pod-reader-rb.yaml
```

??? example "Expected result"
    ```text
    rolebinding.rbac.authorization.k8s.io/read-pods created
    ```

Describe the read-pods RoleBinding.

```bash
# Describe the read-pods RoleBinding.
kubectl describe rolebinding read-pods
```

??? example "Expected result"
    ```text
    Name:         read-pods
    Labels:       <none>
    Annotations:  <none>
    Role:
      Kind:  Role
      Name:  pod-reader
    Subjects:
      Kind            Name        Namespace
      ----            ----        ---------
      ServiceAccount  student-sa
    ```

Check the granted Pod permission.

```bash
# Check the granted Pod permission.
kubectl auth can-i list pods --as=system:serviceaccount:default:student-sa -n default
```

??? example "Expected result"
    ```text
    yes
    ```

Check the denied Secret permission.

```bash
# Check the denied Secret permission.
result=$(kubectl auth can-i list secrets --as=system:serviceaccount:default:student-sa -n default 2>/dev/null || true); test "$result" = no; printf '%s\n' "$result"
```

??? example "Expected result"
    ```text
    no
    ```

Display the curl Pod definition with the student ServiceAccount.

```bash
# Display the curl Pod definition with the student ServiceAccount.
cat ~/resources/curl-pod-with-sa.yaml
```

??? example "Expected result"
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: curl
    spec:
      serviceAccountName: student-sa
      containers:
      - name: curl
        image: alpine
        command: ["sleep", "999999"]
    ```

Create the curl Pod with the student ServiceAccount.

```bash
# Create the curl Pod with the student ServiceAccount.
kubectl create -f ~/resources/curl-pod-with-sa.yaml
```

??? example "Expected result"
    ```text
    pod/curl created
    ```

Wait for the curl Pod.

```bash
# Wait for the curl Pod.
kubectl wait --for=condition=Ready pod/curl --timeout=180s
```

??? example "Expected result"
    ```text
    pod/curl condition met
    ```

Display the Pod's ServiceAccount name.

```bash
# Display the Pod's ServiceAccount name.
kubectl get pod curl -o jsonpath='{.spec.serviceAccountName}{"\n"}'
```

??? example "Expected result"
    ```text
    student-sa
    ```

Install curl in the Pod.

```bash
# Install curl in the Pod.
timeout 180 kubectl exec curl -- apk add --no-cache curl
```

??? example "Expected result"
    ```text
    (1/9) Installing brotli-libs (1.2.0-r1)
    (2/9) Installing c-ares (1.34.8-r0)
    (3/9) Installing libunistring (1.4.2-r0)
    (4/9) Installing libidn2 (2.3.8-r0)
    (5/9) Installing nghttp2-libs (1.69.0-r0)
    (6/9) Installing libpsl (0.21.5-r3)
    (7/9) Installing zstd-libs (1.5.7-r2)
    (8/9) Installing libcurl (8.22.0-r0)
    (9/9) Installing curl (8.22.0-r0)
    Executing busybox-1.37.0-r31.trigger
    OK: 13.1 MiB in 25 packages
    ```

Verify the allowed Pod request.

```bash
# Verify the allowed Pod request.
timeout 60 kubectl exec curl -- sh -ec 'TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token); code=$(curl --silent --show-error --connect-timeout 10 --max-time 30 --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $TOKEN" -o /tmp/pods.json -w "%{http_code}" https://kubernetes/api/v1/namespaces/default/pods); test "$code" = 200; grep -q PodList /tmp/pods.json; grep -q curl /tmp/pods.json; printf "pods: HTTP %s (PodList includes curl)\n" "$code"'
```

??? example "Expected result"
    ```text
    pods: HTTP 200 (PodList includes curl)
    ```

Verify the denied Secret request.

```bash
# Verify the denied Secret request.
timeout 60 kubectl exec curl -- sh -ec 'TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token); code=$(curl --silent --show-error --connect-timeout 10 --max-time 30 --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $TOKEN" -o /tmp/secrets.json -w "%{http_code}" https://kubernetes/api/v1/namespaces/default/secrets); test "$code" = 403; grep -q Forbidden /tmp/secrets.json; grep -q system:serviceaccount:default:student-sa /tmp/secrets.json; printf "secrets: HTTP %s (Forbidden for system:serviceaccount:default:student-sa)\n" "$code"'
```

??? example "Expected result"
    ```text
    secrets: HTTP 403 (Forbidden for system:serviceaccount:default:student-sa)
    ```

Delete the curl Pod.

```bash
# Delete the curl Pod.
kubectl delete pod curl --ignore-not-found --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    pod "curl" deleted from default namespace
    ```

Delete the read-pods RoleBinding.

```bash
# Delete the read-pods RoleBinding.
kubectl delete rolebinding read-pods --ignore-not-found --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    rolebinding.rbac.authorization.k8s.io "read-pods" deleted from default namespace
    ```

Delete the pod-reader Role.

```bash
# Delete the pod-reader Role.
kubectl delete role pod-reader --ignore-not-found --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    role.rbac.authorization.k8s.io "pod-reader" deleted from default namespace
    ```

Delete the student ServiceAccount.

```bash
# Delete the student ServiceAccount.
kubectl delete serviceaccount student-sa --ignore-not-found --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    serviceaccount "student-sa" deleted from default namespace
    ```

Check for remaining Chapter 6 resources.

```bash
# Check for remaining Chapter 6 resources.
kubectl get secret/default-serviceaccount-secret pod/curl serviceaccount/student-sa role.rbac.authorization.k8s.io/pod-reader rolebinding.rbac.authorization.k8s.io/read-pods -o name --ignore-not-found
```

??? example "Expected result"
    ```text
    No output.
    ```

Display the default ServiceAccount after cleanup.

```bash
# Display the default ServiceAccount after cleanup.
kubectl get sa default
```

??? example "Expected result"
    ```text
    NAME      AGE
    default   7h59m
    ```

Wait for all cluster nodes to remain ready.

```bash
# Wait for all cluster nodes to remain ready.
kubectl wait --for=condition=Ready nodes --all --timeout=180s
```

??? example "Expected result"
    ```text
    node/k8s-ctrl condition met
    node/k8s-worker1 condition met
    node/k8s-worker2 condition met
    ```

Display the final cluster node status.

```bash
# Display the final cluster node status.
kubectl get nodes
```

??? example "Expected result"
    ```text
    NAME          STATUS   ROLES                  AGE     VERSION
    k8s-ctrl      Ready    control-plane,worker   7h59m   v1.35.7
    k8s-worker1   Ready    worker                 7h48m   v1.35.7
    k8s-worker2   Ready    worker                 7h48m   v1.35.7
    ```

### :material-application-edit-outline: 2026-09-09 - Chapter 7 Helm validation

Tabular results below are representative excerpts; generated fields and unrelated dynamic columns are omitted.

The validated commands below retain their executed outer timeouts. The documentation uses larger outer bounds so Helm has
additional time to complete rollback after its internal timeout.

Select the workload-cluster kubeconfig.

```bash
# Select the workload-cluster kubeconfig.
export KUBECONFIG="$HOME/.kube/myk8scluster_config"
```

??? example "Expected result"
    ```text
    No output.
    ```

Confirm the active context.

```bash
# Display the active workload-cluster context.
kubectl config current-context
```

??? example "Expected result"
    ```text
    myk8scluster-admin@myk8scluster
    ```

Install Helm with a bounded command.

```bash
# Install the Helm client with a five-minute bound.
timeout 300s sudo snap install helm --channel=latest/stable --classic
```

??? example "Expected result"
    ```text
    helm 4.2.4 from Snapcrafters* installed
    ```

Display the installed version.

```bash
# Display the Helm client version.
helm version --short
```

??? example "Expected result"
    ```text
    v4.2.4+g3900f43
    ```

Reject collisions before creating Chapter 7 resources.

```bash
# Reject Chapter 7 release, resource, and local-directory collisions.
timeout 60s sh -c 'test -z "$(helm repo list -o json | jq -r ".[] | select(.name == \"stable\" or .name == \"bitnami\" or .name == \"headlamp\") | .name")" && test -z "$(helm list --all-namespaces --filter "^(my-wordpress-blog|web-app-stateless|web-app-stateful|headlamp)$" -q)" && test -z "$(kubectl get deployment,statefulset,service,serviceaccount,secret,pvc --all-namespaces -o name | grep -E "(my-wordpress-blog|web-app-stateless|web-app-stateful|headlamp)" || true)" && test -z "$(kubectl get secret/oidc --namespace kube-system --ignore-not-found -o name)" && test -z "$(kubectl get clusterrolebinding/headlamp-admin --ignore-not-found -o name)" && for path in "$HOME/kubernetes-tools" "$HOME/web-app" "$HOME/web-app-stateful"; do test ! -e "$path" || { printf "Collision: %s\n" "$path"; exit 1; }; done && printf "No Chapter 7 collisions detected\n"'
```

??? example "Expected result"
    ```text
    No Chapter 7 collisions detected
    ```

Add the archived stable repository.

```bash
# Add the archived stable chart repository.
timeout 60s helm repo add stable https://charts.helm.sh/stable
```

??? example "Expected result"
    ```text
    "stable" has been added to your repositories
    ```

List the configured repository.

```bash
# List configured chart repositories.
helm repo list
```

??? example "Expected result"
    ```text
    NAME     URL
    stable   https://charts.helm.sh/stable
    ```

Refresh the stable repository.

```bash
# Refresh the stable repository metadata.
timeout 180s helm repo update stable
```

??? example "Expected result"
    ```text
    ...Successfully got an update from the "stable" chart repository
    Update Complete.
    ```

Search for the deprecated WordPress chart.

```bash
# Search for the deprecated WordPress chart.
helm search repo stable/wordpress
```

??? example "Expected result"
    ```text
    NAME               CHART VERSION   APP VERSION   DESCRIPTION
    stable/wordpress   9.0.3           5.3.2         DEPRECATED Web publishing platform...
    ```

Add the Bitnami repository.

```bash
# Add the Bitnami chart repository.
timeout 60s helm repo add bitnami https://charts.bitnami.com/bitnami
```

??? example "Expected result"
    ```text
    "bitnami" has been added to your repositories
    ```

Refresh the Bitnami repository.

```bash
# Refresh the Bitnami repository metadata.
timeout 180s helm repo update bitnami
```

??? example "Expected result"
    ```text
    ...Successfully got an update from the "bitnami" chart repository
    Update Complete.
    ```

Confirm the pinned WordPress chart.

```bash
# Search for the pinned WordPress chart version.
helm search repo bitnami/wordpress --version 30.0.12
```

??? example "Expected result"
    ```text
    NAME                CHART VERSION   APP VERSION   DESCRIPTION
    bitnami/wordpress   30.0.12         6.9.4         WordPress is the world's most popular blogging...
    ```

Inspect chart metadata.

```bash
# Display metadata for the pinned WordPress chart.
timeout 60s helm show chart bitnami/wordpress --version 30.0.12
```

??? example "Expected result"
    ```yaml
    apiVersion: v2
    appVersion: 6.9.4
    name: wordpress
    version: 30.0.12
    ```

Save all chart information.

```bash
# Save all WordPress chart information and report its size.
timeout 60s helm show all bitnami/wordpress --version 30.0.12 >/tmp/wordpress-chart-all.txt && wc -l /tmp/wordpress-chart-all.txt
```

??? example "Expected result"
    ```text
    2429 /tmp/wordpress-chart-all.txt
    ```

Save the default values.

```bash
# Save the WordPress default values and report their size.
timeout 60s helm show values bitnami/wordpress --version 30.0.12 >/tmp/wordpress-values.yaml && wc -l /tmp/wordpress-values.yaml
```

??? example "Expected result"
    ```text
    1452 /tmp/wordpress-values.yaml
    ```

Render the WordPress release.

```bash
# Render the WordPress release and summarize its resource kinds.
timeout 120s helm template my-wordpress-blog bitnami/wordpress \
  --version 30.0.12 \
  --namespace default \
  --set wordpressUsername=admin \
  --set wordpressPassword=password \
  --set mariadb.auth.rootPassword=secretpassword \
  --set persistence.size=1Gi \
  --set mariadb.primary.persistence.size=1Gi \
  >/tmp/my-wordpress-blog.yaml && grep "^kind:" /tmp/my-wordpress-blog.yaml | sort | uniq -c
```

??? example "Expected result"
    ```text
          1 kind: ConfigMap
          1 kind: Deployment
          2 kind: NetworkPolicy
          1 kind: PersistentVolumeClaim
          2 kind: PodDisruptionBudget
          2 kind: Secret
          3 kind: Service
          2 kind: ServiceAccount
          1 kind: StatefulSet
    ```

Install the WordPress release.

```bash
# Install the WordPress release with bounded readiness and rollback.
timeout 960s helm install my-wordpress-blog bitnami/wordpress \
  --version 30.0.12 \
  --namespace default \
  --set wordpressUsername=admin \
  --set wordpressPassword=password \
  --set mariadb.auth.rootPassword=secretpassword \
  --set persistence.size=1Gi \
  --set mariadb.primary.persistence.size=1Gi \
  --wait \
  --wait-for-jobs \
  --timeout 15m \
  --rollback-on-failure
```

??? example "Expected result"
    ```text
    NAME: my-wordpress-blog
    NAMESPACE: default
    STATUS: deployed
    DESCRIPTION: Install complete
    CHART VERSION: 30.0.12
    APP VERSION: 6.9.4
    ```

Inspect the release.

```bash
# Display WordPress release status.
helm status my-wordpress-blog --namespace default
```

??? example "Expected result"
    ```text
    NAME: my-wordpress-blog
    NAMESPACE: default
    STATUS: deployed
    my-wordpress-blog            Deployment 1/1
    my-wordpress-blog-mariadb   StatefulSet 1/1
    ```

List the release.

```bash
# List the WordPress release.
helm list --namespace default --filter "^my-wordpress-blog$"
```

??? example "Expected result"
    ```text
    NAME                NAMESPACE   REVISION   STATUS     CHART              APP VERSION
    my-wordpress-blog   default     1          deployed   wordpress-30.0.12   6.9.4
    ```

Wait for both release Pods.

```bash
# Wait for the WordPress and MariaDB Pods.
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=my-wordpress-blog --timeout=600s
```

??? example "Expected result"
    ```text
    pod/my-wordpress-blog-8646dfbc9d-df5xg condition met
    pod/my-wordpress-blog-mariadb-0 condition met
    ```

Display the Pods.

```bash
# Display the WordPress release Pods.
kubectl get pods -l app.kubernetes.io/instance=my-wordpress-blog -o wide
```

??? example "Expected result"
    ```text
    NAME                                  READY   STATUS    NODE
    my-wordpress-blog-8646dfbc9d-df5xg   1/1     Running   k8s-worker1
    my-wordpress-blog-mariadb-0           1/1     Running   k8s-worker2
    ```

Display the Services.

```bash
# Display the WordPress release Services.
kubectl get service my-wordpress-blog my-wordpress-blog-mariadb my-wordpress-blog-mariadb-headless
```

??? example "Expected result"
    ```text
    NAME                                  TYPE           EXTERNAL-IP      PORT(S)
    my-wordpress-blog                     LoadBalancer   10.107.242.11   80:32232/TCP,443:30657/TCP
    my-wordpress-blog-mariadb             ClusterIP      <none>          3306/TCP
    my-wordpress-blog-mariadb-headless    ClusterIP      <none>          3306/TCP
    ```

Display the claims.

```bash
# Display the WordPress release claims.
kubectl get pvc -l app.kubernetes.io/instance=my-wordpress-blog
```

??? example "Expected result"
    ```text
    NAME                                  STATUS   CAPACITY   ACCESS MODES   STORAGECLASS
    data-my-wordpress-blog-mariadb-0      Bound    1Gi        RWO            csi-rawfile-default
    my-wordpress-blog                     Bound    1Gi        RWO            csi-rawfile-default
    ```

Check the credential without decoding it.

```bash
# Verify that the generated WordPress credential is present.
test -n "$(kubectl get secret my-wordpress-blog -o jsonpath='{.data.wordpress-password}')" && printf "WordPress credential is present\n"
```

??? example "Expected result"
    ```text
    WordPress credential is present
    ```

Wait for the LoadBalancer address.

```bash
# Wait for the WordPress LoadBalancer address.
kubectl wait --for=jsonpath='{.status.loadBalancer.ingress[0].ip}' service/my-wordpress-blog --timeout=180s
```

??? example "Expected result"
    ```text
    service/my-wordpress-blog condition met
    ```

Test external HTTP access.

```bash
# Verify the WordPress LoadBalancer endpoint.
WORDPRESS_IP=$(kubectl get service my-wordpress-blog -o jsonpath='{.status.loadBalancer.ingress[0].ip}') && curl --silent --show-error --location --output /dev/null --write-out "HTTP %{http_code}\n" --max-time 30 "http://$WORDPRESS_IP/"
```

??? example "Expected result"
    ```text
    HTTP 200
    ```

Uninstall WordPress.

```bash
# Uninstall the WordPress release with a bounded wait.
timeout 360s helm uninstall my-wordpress-blog --namespace default --wait --timeout 5m
```

??? example "Expected result"
    ```text
    release "my-wordpress-blog" uninstalled
    ```

Delete the retained claim.

```bash
# Delete retained WordPress release claims.
kubectl delete pvc -l app.kubernetes.io/instance=my-wordpress-blog --ignore-not-found --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    persistentvolumeclaim "data-my-wordpress-blog-mariadb-0" deleted from default namespace
    ```

Verify cleanup.

```bash
# Verify complete WordPress release cleanup.
test -z "$(helm list --namespace default --filter '^my-wordpress-blog$' -q)" && test -z "$(kubectl get deployment,statefulset,pod,service,serviceaccount,secret,configmap,networkpolicy,poddisruptionbudget,pvc -l app.kubernetes.io/instance=my-wordpress-blog -o name)" && test -z "$(kubectl get pv -o json | jq -r '.items[] | select(.spec.claimRef.namespace == "default" and (.spec.claimRef.name | contains("my-wordpress-blog"))) | .metadata.name')" && printf "WordPress cleanup verified\n"
```

??? example "Expected result"
    ```text
    WordPress cleanup verified
    ```

Clone and pin the application source.

```bash
# Clone and pin the Kubernetes tools source tree.
timeout 180s git clone https://github.com/cloudbase/kubernetes-tools.git "$HOME/kubernetes-tools" && git -C "$HOME/kubernetes-tools" checkout 713c0fcbb51c4b31e65a0fce8a767c6ebd3c4b56 && git -C "$HOME/kubernetes-tools" rev-parse HEAD
```

??? example "Expected result"
    ```text
    Cloning into '/home/ubuntu/kubernetes-tools'...
    HEAD is now at 713c0fc Update values.yaml
    713c0fcbb51c4b31e65a0fce8a767c6ebd3c4b56
    ```

Create the stateless chart.

```bash
# Create the stateless web application chart.
helm create "$HOME/web-app"
```

??? example "Expected result"
    ```text
    Creating /home/ubuntu/web-app
    ```

Update and inspect its values.

```bash
# Set three replicas and the public application image non-interactively.
LC_ALL=C perl -0pi -e 's/^replicaCount: .*$/replicaCount: 3/m; s|^  repository: .*$|  repository: pvradu/web-app|m; s/^  tag: .*$/  tag: "v1"/m' "$HOME/web-app/values.yaml" && grep -A 8 '^replicaCount:' "$HOME/web-app/values.yaml"
```

??? example "Expected result"
    ```yaml
    replicaCount: 3

    image:
      repository: pvradu/web-app
      pullPolicy: IfNotPresent
      tag: "v1"
    ```

Lint the chart.

```bash
# Lint the stateless web application chart.
helm lint "$HOME/web-app"
```

??? example "Expected result"
    ```text
    ==> Linting /home/ubuntu/web-app
    [INFO] Chart.yaml: icon is recommended

    1 chart(s) linted, 0 chart(s) failed
    ```

Render the chart.

```bash
# Render and summarize the stateless chart resources.
helm template web-app-stateless "$HOME/web-app" --namespace default >/tmp/web-app-stateless.yaml && grep '^kind:' /tmp/web-app-stateless.yaml | sort | uniq -c
```

??? example "Expected result"
    ```text
          1 kind: Deployment
          1 kind: Pod
          1 kind: Service
          1 kind: ServiceAccount
    ```

Package the chart.

```bash
# Package the stateless chart in its working directory.
helm package "$HOME/web-app" --destination "$HOME/web-app"
```

??? example "Expected result"
    ```text
    Successfully packaged chart and saved it to: /home/ubuntu/web-app/web-app-0.1.0.tgz
    ```

Install the stateless release.

```bash
# Install the stateless web application release.
timeout 660s helm install web-app-stateless "$HOME/web-app/web-app-0.1.0.tgz" --namespace default --wait --timeout 10m --rollback-on-failure
```

??? example "Expected result"
    ```text
    NAME: web-app-stateless
    NAMESPACE: default
    STATUS: deployed
    DESCRIPTION: Install complete
    ```

Inspect the stateless release.

```bash
# Display the stateless release status.
helm status web-app-stateless --namespace default
```

??? example "Expected result"
    ```text
    NAME: web-app-stateless
    NAMESPACE: default
    STATUS: deployed
    web-app-stateless   Deployment 3/3
    ```

Wait for and display all replicas.

```bash
# Wait for and display all stateless application Pods.
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=web-app-stateless --timeout=300s && kubectl get pods -l app.kubernetes.io/instance=web-app-stateless -o custom-columns=NAME:.metadata.name,READY:.status.containerStatuses[0].ready,IMAGE:.spec.containers[0].image,NODE:.spec.nodeName --no-headers
```

??? example "Expected result"
    ```text
    pod/web-app-stateless-5cc59678f-9j5wv condition met
    pod/web-app-stateless-5cc59678f-d8x9d condition met
    pod/web-app-stateless-5cc59678f-tfd8s condition met
    web-app-stateless-5cc59678f-9j5wv   true   pvradu/web-app:v1   k8s-worker2
    web-app-stateless-5cc59678f-d8x9d   true   pvradu/web-app:v1   k8s-ctrl
    web-app-stateless-5cc59678f-tfd8s   true   pvradu/web-app:v1   k8s-worker1
    ```

Display the Service.

```bash
# Display the stateless application Service.
kubectl get service web-app-stateless
```

??? example "Expected result"
    ```text
    NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)
    web-app-stateless     ClusterIP   10.152.130.53   <none>        80/TCP
    ```

Display the Service endpoints.

```bash
# Display the Pods behind the stateless Service.
kubectl get endpointslice -l kubernetes.io/service-name=web-app-stateless -o jsonpath='{range .items[*].endpoints[*]}{.targetRef.name}{"\n"}{end}' | sort
```

??? example "Expected result"
    ```text
    web-app-stateless-5cc59678f-9j5wv
    web-app-stateless-5cc59678f-d8x9d
    web-app-stateless-5cc59678f-tfd8s
    ```

Query the application through the API Service proxy.

```bash
# Query the stateless Service through the Kubernetes API proxy endpoint.
timeout 30s kubectl get --raw /api/v1/namespaces/default/services/http:web-app-stateless:80/proxy/
```

??? example "Expected result"
    ```text
    This app is running in pod web-app-stateless-5cc59678f-9j5wv
    ```

Uninstall the stateless release.

```bash
# Uninstall the stateless release with a bounded wait.
timeout 360s helm uninstall web-app-stateless --namespace default --wait --timeout 5m
```

??? example "Expected result"
    ```text
    release "web-app-stateless" uninstalled
    ```

Verify stateless cleanup.

```bash
# Verify stateless release cleanup.
timeout 180s sh -c 'while test -n "$(kubectl get deployment,pod,service,serviceaccount -l app.kubernetes.io/instance=web-app-stateless -o name)"; do sleep 3; done' && printf "Stateless release cleanup verified\n"
```

??? example "Expected result"
    ```text
    Stateless release cleanup verified
    ```

Assemble the stateful chart.

```bash
# Assemble the stateful web application chart.
mkdir "$HOME/web-app-stateful" && cp -R "$HOME/kubernetes-tools/web-app-stateful/chart/." "$HOME/web-app-stateful/"
```

??? example "Expected result"
    ```text
    No output.
    ```

Lint the stateful chart.

```bash
# Lint the stateful web application chart.
helm lint "$HOME/web-app-stateful"
```

??? example "Expected result"
    ```text
    ==> Linting /home/ubuntu/web-app-stateful
    [INFO] Chart.yaml: icon is recommended

    1 chart(s) linted, 0 chart(s) failed
    ```

Render the stateful chart.

```bash
# Render and summarize the stateful chart resources.
helm template web-app-stateful "$HOME/web-app-stateful" --namespace default >/tmp/web-app-stateful.yaml && grep '^kind:' /tmp/web-app-stateful.yaml | sort | uniq -c
```

??? example "Expected result"
    ```text
          1 kind: Service
          1 kind: StatefulSet
    ```

Package the stateful chart.

```bash
# Package the stateful chart in its working directory.
helm package "$HOME/web-app-stateful" --destination "$HOME/web-app-stateful"
```

??? example "Expected result"
    ```text
    Successfully packaged chart and saved it to: /home/ubuntu/web-app-stateful/web-app-stateful-0.1.0.tgz
    ```

Install the stateful release.

```bash
# Install the stateful web application release.
timeout 660s helm install web-app-stateful "$HOME/web-app-stateful/web-app-stateful-0.1.0.tgz" --namespace default --wait --timeout 10m --rollback-on-failure
```

??? example "Expected result"
    ```text
    NAME: web-app-stateful
    NAMESPACE: default
    STATUS: deployed
    DESCRIPTION: Install complete
    ```

Inspect the stateful release.

```bash
# Display the stateful release status.
helm status web-app-stateful --namespace default
```

??? example "Expected result"
    ```text
    NAME: web-app-stateful
    NAMESPACE: default
    STATUS: deployed
    web-app-stateful   StatefulSet 2/2
    ```

Display the StatefulSet.

```bash
# Display the stateful application controller.
kubectl get statefulset web-app-stateful
```

??? example "Expected result"
    ```text
    NAME                 READY   AGE
    web-app-stateful     2/2     50s
    ```

Display the stateful Pods.

```bash
# Display the stateful application Pods.
kubectl get pods -l app=web-app-stateful -o wide
```

??? example "Expected result"
    ```text
    NAME                   READY   STATUS    NODE
    web-app-stateful-0     1/1     Running   k8s-worker1
    web-app-stateful-1     1/1     Running   k8s-worker2
    ```

Display the headless Service.

```bash
# Display the stateful application's headless Service.
kubectl get service web-app-stateful
```

??? example "Expected result"
    ```text
    NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)
    web-app-stateful     ClusterIP   None         <none>        80/TCP
    ```

Display stateful storage.

```bash
# Display stateful application claims and storage details.
kubectl get pvc -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.status.capacity.storage,ACCESS-MODES:.status.accessModes[*],STORAGECLASS:.spec.storageClassName --no-headers | grep '^data-web-app-stateful-'
```

??? example "Expected result"
    ```text
    data-web-app-stateful-0   Bound   1Gi   ReadWriteOnce   csi-rawfile-default
    data-web-app-stateful-1   Bound   1Gi   ReadWriteOnce   csi-rawfile-default
    ```

Query the first Pod.

```bash
# Query the first stateful Pod through the API proxy.
timeout 30s kubectl get --raw /api/v1/namespaces/default/pods/web-app-stateful-0/proxy/
```

??? example "Expected result"
    ```text
    You've hit web-app-stateful-0
    Data stored on this pod: No data posted yet
    ```

Query the second Pod.

```bash
# Query the second stateful Pod through the API proxy.
timeout 30s kubectl get --raw /api/v1/namespaces/default/pods/web-app-stateful-1/proxy/
```

??? example "Expected result"
    ```text
    You've hit web-app-stateful-1
    Data stored on this pod: No data posted yet
    ```

Write data to the second Pod.

```bash
# Store a training value in the second stateful Pod.
printf "Hey there!" | timeout 30s kubectl create --raw /api/v1/namespaces/default/pods/web-app-stateful-1/proxy/ -f -
```

??? example "Expected result"
    ```text
    Data stored on pod web-app-stateful-1
    ```

Read the stored data.

```bash
# Verify the value stored by the second stateful Pod.
timeout 30s kubectl get --raw /api/v1/namespaces/default/pods/web-app-stateful-1/proxy/
```

??? example "Expected result"
    ```text
    You've hit web-app-stateful-1
    Data stored on this pod: Hey there!
    ```

Delete and recreate the Pod.

```bash
# Recreate the second Pod and verify that its UID changed.
OLD_UID=$(kubectl get pod web-app-stateful-1 -o jsonpath='{.metadata.uid}') && kubectl delete pod web-app-stateful-1 --wait=true --timeout=180s && kubectl wait --for=condition=Ready pod/web-app-stateful-1 --timeout=300s && NEW_UID=$(kubectl get pod web-app-stateful-1 -o jsonpath='{.metadata.uid}') && test "$OLD_UID" != "$NEW_UID" && printf "Pod recreated with a new UID\n"
```

??? example "Expected result"
    ```text
    pod "web-app-stateful-1" deleted from default namespace
    pod/web-app-stateful-1 condition met
    Pod recreated with a new UID
    ```

Verify the persisted data.

```bash
# Verify data persistence after Pod replacement.
timeout 30s kubectl get --raw /api/v1/namespaces/default/pods/web-app-stateful-1/proxy/
```

??? example "Expected result"
    ```text
    You've hit web-app-stateful-1
    Data stored on this pod: Hey there!
    ```

Display claims and backing volumes.

```bash
# Display stateful claims and their associated persistent volumes.
kubectl get pvc data-web-app-stateful-0 data-web-app-stateful-1 && kubectl get pv -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,CLAIM:.spec.claimRef.name,STORAGECLASS:.spec.storageClassName | grep 'data-web-app-stateful'
```

??? example "Expected result"
    ```text
    NAME                       STATUS   CAPACITY   STORAGECLASS
    data-web-app-stateful-0    Bound    1Gi        csi-rawfile-default
    data-web-app-stateful-1    Bound    1Gi        csi-rawfile-default
    pvc-92aa8221-...            Bound    data-web-app-stateful-1   csi-rawfile-default
    pvc-a44c36b2-...            Bound    data-web-app-stateful-0   csi-rawfile-default
    ```

Uninstall the stateful release.

```bash
# Uninstall the stateful release with a bounded wait.
timeout 360s helm uninstall web-app-stateful --namespace default --wait --timeout 5m
```

??? example "Expected result"
    ```text
    release "web-app-stateful" uninstalled
    ```

Display retained claims.

```bash
# Display the retained StatefulSet claims.
kubectl get pvc data-web-app-stateful-0 data-web-app-stateful-1
```

??? example "Expected result"
    ```text
    NAME                       STATUS   CAPACITY   ACCESS MODES   STORAGECLASS
    data-web-app-stateful-0    Bound    1Gi        RWO            csi-rawfile-default
    data-web-app-stateful-1    Bound    1Gi        RWO            csi-rawfile-default
    ```

Delete retained claims.

```bash
# Delete the retained stateful application claims.
kubectl delete pvc data-web-app-stateful-0 data-web-app-stateful-1 --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    persistentvolumeclaim "data-web-app-stateful-0" deleted from default namespace
    persistentvolumeclaim "data-web-app-stateful-1" deleted from default namespace
    ```

Verify stateful cleanup.

```bash
# Verify complete stateful release cleanup.
timeout 180s sh -c 'while kubectl get pv -o jsonpath="{range .items[*]}{.spec.claimRef.name}{\"\\n\"}{end}" | grep -q "^data-web-app-stateful-"; do sleep 3; done' && test -z "$(kubectl get statefulset,pod,service -l release=web-app-stateful -o name)" && printf "Stateful release cleanup verified\n"
```

??? example "Expected result"
    ```text
    Stateful release cleanup verified
    ```

Add the Headlamp repository.

```bash
# Add the Headlamp chart repository.
timeout 60s helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
```

??? example "Expected result"
    ```text
    "headlamp" has been added to your repositories
    ```

Refresh the Headlamp repository.

```bash
# Refresh the Headlamp repository metadata.
timeout 180s helm repo update headlamp
```

??? example "Expected result"
    ```text
    ...Successfully got an update from the "headlamp" chart repository
    Update Complete.
    ```

Confirm the pinned chart.

```bash
# Search for the pinned Headlamp chart version.
helm search repo headlamp/headlamp --version 0.45.0
```

??? example "Expected result"
    ```text
    NAME                CHART VERSION   APP VERSION   DESCRIPTION
    headlamp/headlamp   0.45.0          0.45.0        Headlamp is an easy-to-use and extensible Kubernetes web UI.
    ```

Validate the rendered resources.

```bash
# Validate the rendered Headlamp resources against the API server.
timeout 180s sh -c 'helm template headlamp headlamp/headlamp --version 0.45.0 --namespace kube-system --set replicaCount=3 --set service.type=LoadBalancer | kubectl apply --request-timeout=60s --dry-run=server -f -'
```

??? example "Expected result"
    ```text
    serviceaccount/headlamp created (server dry run)
    secret/oidc created (server dry run)
    clusterrolebinding.rbac.authorization.k8s.io/headlamp-admin created (server dry run)
    service/headlamp created (server dry run)
    deployment.apps/headlamp created (server dry run)
    ```

Install Headlamp.

```bash
# Install Headlamp with three replicas and a LoadBalancer.
timeout 660s helm install headlamp headlamp/headlamp --version 0.45.0 --namespace kube-system --set replicaCount=3 --set service.type=LoadBalancer --wait --timeout 10m --rollback-on-failure
```

??? example "Expected result"
    ```text
    NAME: headlamp
    NAMESPACE: kube-system
    STATUS: deployed
    DESCRIPTION: Install complete
    ```

Inspect Headlamp.

```bash
# Display the Headlamp release status.
helm status headlamp --namespace kube-system
```

??? example "Expected result"
    ```text
    NAME: headlamp
    NAMESPACE: kube-system
    STATUS: deployed
    headlamp   Deployment 3/3
    headlamp   LoadBalancer 10.107.242.11
    ```

Wait for and display the Headlamp Pods.

```bash
# Wait for and display the Headlamp Pods.
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/name=headlamp --namespace kube-system --timeout=300s && kubectl get pods -l app.kubernetes.io/name=headlamp --namespace kube-system -o custom-columns=NAME:.metadata.name,READY:.status.containerStatuses[0].ready,IMAGE:.spec.containers[0].image,NODE:.spec.nodeName --no-headers
```

??? example "Expected result"
    ```text
    pod/headlamp-78c9db77c6-68bzw condition met
    pod/headlamp-78c9db77c6-7phdk condition met
    pod/headlamp-78c9db77c6-flbv8 condition met
    headlamp-78c9db77c6-68bzw   true   ghcr.io/headlamp-k8s/headlamp:v0.45.0   k8s-ctrl
    headlamp-78c9db77c6-7phdk   true   ghcr.io/headlamp-k8s/headlamp:v0.45.0   k8s-worker1
    headlamp-78c9db77c6-flbv8   true   ghcr.io/headlamp-k8s/headlamp:v0.45.0   k8s-worker2
    ```

Wait for and display the Service.

```bash
# Wait for and display the Headlamp LoadBalancer Service.
kubectl wait --for=jsonpath='{.status.loadBalancer.ingress[0].ip}' service/headlamp --namespace kube-system --timeout=180s && kubectl get service headlamp --namespace kube-system
```

??? example "Expected result"
    ```text
    service/headlamp condition met
    NAME       TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)
    headlamp   LoadBalancer   10.152.63.84   10.107.242.11   80:30764/TCP
    ```

Test the Headlamp endpoint.

```bash
# Verify the Headlamp LoadBalancer endpoint.
HEADLAMP_IP=$(kubectl get service headlamp --namespace kube-system -o jsonpath='{.status.loadBalancer.ingress[0].ip}') && curl --silent --show-error --output /dev/null --write-out "HTTP %{http_code}\n" --max-time 30 "http://$HEADLAMP_IP/"
```

??? example "Expected result"
    ```text
    HTTP 200
    ```

Confirm cluster-admin authorization.

```bash
# Verify the Headlamp ServiceAccount cluster-admin authorization.
kubectl auth can-i "*" "*" --as=system:serviceaccount:kube-system:headlamp
```

??? example "Expected result"
    ```text
    yes
    ```

Validate a short-lived token without printing it.

```bash
# Validate a short-lived Headlamp token without exposing it.
HEADLAMP_TOKEN=$(kubectl create token headlamp --namespace kube-system --duration=10m) && test "$(printf "%s" "$HEADLAMP_TOKEN" | awk -F. '{print NF}')" -eq 3 && printf "Short-lived Headlamp token generated\n" && unset HEADLAMP_TOKEN
```

??? example "Expected result"
    ```text
    Short-lived Headlamp token generated
    ```

Uninstall Headlamp.

```bash
# Uninstall Headlamp with a bounded wait.
timeout 360s helm uninstall headlamp --namespace kube-system --wait --timeout 5m
```

??? example "Expected result"
    ```text
    release "headlamp" uninstalled
    ```

Verify Headlamp cleanup.

```bash
# Verify complete Headlamp cleanup.
timeout 180s sh -c 'while test -n "$(kubectl get deployment/headlamp service/headlamp serviceaccount/headlamp secret/oidc --namespace kube-system --ignore-not-found -o name)$(kubectl get clusterrolebinding/headlamp-admin --ignore-not-found -o name)"; do sleep 3; done' && printf "Headlamp cleanup verified\n"
```

??? example "Expected result"
    ```text
    Headlamp cleanup verified
    ```

Remove local artifacts.

```bash
# Remove the Chapter 7 repository aliases created by this workflow.
helm repo remove stable bitnami headlamp
```

??? example "Expected result"
    ```text
    "stable" has been removed from your repositories
    "bitnami" has been removed from your repositories
    "headlamp" has been removed from your repositories
    ```

```bash
# Remove Chapter 7 local artifacts.
rm -rf -- "$HOME/kubernetes-tools" "$HOME/web-app" "$HOME/web-app-stateful" && rm -f -- /tmp/wordpress-chart-all.txt /tmp/wordpress-values.yaml /tmp/my-wordpress-blog.yaml /tmp/web-app-stateless.yaml /tmp/web-app-stateful.yaml /tmp/headlamp.yaml
```

??? example "Expected result"
    ```text
    No output.
    ```

Verify final cleanup.

```bash
# Verify final Chapter 7 cleanup.
test -z "$(helm repo list -o json | jq -r '.[] | select(.name == "stable" or .name == "bitnami" or .name == "headlamp") | .name')" && test -z "$(helm list --all-namespaces --filter '^(my-wordpress-blog|web-app-stateless|web-app-stateful|headlamp)$' -q)" && test -z "$(kubectl get deployment,statefulset,pod,service,serviceaccount,secret,configmap,networkpolicy,poddisruptionbudget,pvc --all-namespaces -o name | grep -E '(my-wordpress-blog|web-app-stateless|web-app-stateful|headlamp)' || true)" && test -z "$(kubectl get secret/oidc --namespace kube-system --ignore-not-found -o name)" && test -z "$(kubectl get clusterrolebinding/headlamp-admin --ignore-not-found -o name)" && test -z "$(kubectl get pv -o jsonpath='{range .items[*]}{.spec.claimRef.name}{"\n"}{end}' | grep -E '(my-wordpress-blog|web-app-stateful)' || true)" && test ! -e "$HOME/kubernetes-tools" && test ! -e "$HOME/web-app" && test ! -e "$HOME/web-app-stateful" && printf "Chapter 7 cleanup verified\n"
```

??? example "Expected result"
    ```text
    Chapter 7 cleanup verified
    ```

Confirm node readiness.

```bash
# Confirm final node readiness.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
```

??? example "Expected result"
    ```text
    node/k8s-ctrl condition met
    node/k8s-worker1 condition met
    node/k8s-worker2 condition met
    ```

Display the final nodes.

```bash
# Display the final cluster node status.
kubectl get nodes
```

??? example "Expected result"
    ```text
    NAME          STATUS   ROLES                  AGE   VERSION
    k8s-ctrl      Ready    control-plane,worker   19h   v1.35.7
    k8s-worker1   Ready    worker                 19h   v1.35.7
    k8s-worker2   Ready    worker                 19h   v1.35.7
    ```

### :material-application-edit-outline: 2026-09-09 - Chapter 8 upgrade validation

Generated names, ages, and unrelated dynamic columns are omitted from representative results.

The first monitor for the second worker timed out after its upgrade reboot left the LXD VM stopped. Failed monitors and
diagnostic commands are not part of this successful training-command transcript. Successful VM restart recovery is included
below, and the normalized lab integrates it into bounded monitoring. A management CoreDNS `.maas` forward was then added so
the provider could reliably reach the workload API and complete the existing request without reapplying its annotation.

Verify both kubeconfigs.

```bash
# Verify the management and workload kubeconfigs.
test -r "$HOME/.kube/config" && test -r "$HOME/.kube/myk8scluster_config" && printf "Both kubeconfigs are readable\n"
```

??? example "Expected result"
    ```text
    Both kubeconfigs are readable
    ```

Display both contexts.

```bash
# Display the management and workload contexts.
kubectl --kubeconfig="$HOME/.kube/config" config current-context && kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" config current-context
```

??? example "Expected result"
    ```text
    k8s
    myk8scluster-admin@myk8scluster
    ```

Display the management node.

```bash
# Display the management-cluster node.
kubectl --kubeconfig="$HOME/.kube/config" get nodes -o wide
```

??? example "Expected result"
    ```text
    NAME           STATUS   ROLES                  VERSION   INTERNAL-IP
    cluster-ctrl   Ready    control-plane,worker   v1.35.7   10.107.242.61
    ```

Display the workload nodes before upgrading.

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

Verify the workload datastore.

```bash
# Verify the workload control-plane datastore.
test "$(lxc exec k8s-ctrl -- snap services k8s | awk '$1 == "k8s.etcd" { print $3 }')" = "active" && printf "The workload control plane uses the supported etcd datastore\n"
```

??? example "Expected result"
    ```text
    The workload control plane uses the supported etcd datastore
    ```

Verify the management API.

```bash
# Verify management API readiness.
kubectl --kubeconfig="$HOME/.kube/config" get --raw="/readyz"
```

??? example "Expected result"
    ```text
    ok
    ```

Verify the workload API.

```bash
# Verify workload API readiness.
kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get --raw="/readyz"
```

??? example "Expected result"
    ```text
    ok
    ```

Display provider versions.

```bash
# Display management-cluster controller images.
kubectl --kubeconfig="$HOME/.kube/config" get deployments -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,IMAGE:.spec.template.spec.containers[*].image --no-headers
```

??? example "Expected result"
    ```text
    cabpck-system    cabpck-bootstrap-controller-manager   ghcr.io/canonical/cluster-api-k8s/bootstrap-controller:v0.6.2,...
    cacpck-system    cacpck-controller-manager             ghcr.io/canonical/cluster-api-k8s/controlplane-controller:v0.6.2
    capi-system      capi-controller-manager               registry.k8s.io/cluster-api/cluster-api-controller:v1.13.5
    capmaas-system   capmaas-controller-manager            .../cluster-api-provider-maas-controller:v0.9.0,...
    ```

Enforce the validated provider versions.

```bash
# Require the validated CAPI provider versions.
kubectl --kubeconfig="$HOME/.kube/config" get deployments -A -o json | jq -e 'any(.items[]; .metadata.namespace == "cabpck-system" and any(.spec.template.spec.containers[]; .image | endswith(":v0.6.2"))) and any(.items[]; .metadata.namespace == "cacpck-system" and any(.spec.template.spec.containers[]; .image | endswith(":v0.6.2"))) and any(.items[]; .metadata.namespace == "capi-system" and any(.spec.template.spec.containers[]; .image | endswith(":v1.13.5"))) and any(.items[]; .metadata.namespace == "capmaas-system" and any(.spec.template.spec.containers[]; .image | endswith(":v0.9.0")))' >/dev/null && printf "Validated CAPI provider versions are installed\n"
```

??? example "Expected result"
    ```text
    Validated CAPI provider versions are installed
    ```

Display the CAPI topology.

```bash
# Display the cluster, control plane, worker deployment, and Machines.
kubectl --kubeconfig="$HOME/.kube/config" get clusters,ck8scontrolplanes,machinedeployments,machines
```

??? example "Expected result"
    ```text
    myk8scluster                                  True   1   2   Provisioned
    myk8scluster-control-plane    true   true    1.35.7   1   1   1
    myk8scluster-worker-md-0      True   2       2        2   Running   v1.35.7
    myk8scluster-control-plane-cvgdl       k8s-ctrl      True   True   Running   v1.35.7
    myk8scluster-worker-md-0-m8bgf-rjszd   k8s-worker1   True   True   Running   v1.35.7
    myk8scluster-worker-md-0-m8bgf-sxbrk   k8s-worker2   True   True   Running   v1.35.7
    ```

Verify management Pod health.

```bash
# Verify management-cluster Pod health.
kubectl --kubeconfig="$HOME/.kube/config" get pods -A -o json | jq -e 'all(.items[]; .status.phase == "Succeeded" or (.status.phase == "Running" and (.status.containerStatuses | type == "array") and (.status.containerStatuses | length > 0) and all(.status.containerStatuses[]; .ready == true)))' >/dev/null && printf "Management cluster Pods are healthy\n"
```

??? example "Expected result"
    ```text
    Management cluster Pods are healthy
    ```

Verify workload Pod health.

```bash
# Verify workload-cluster Pod health.
kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get pods -A -o json | jq -e 'all(.items[]; .status.phase == "Succeeded" or (.status.phase == "Running" and (.status.containerStatuses | type == "array") and (.status.containerStatuses | length > 0) and all(.status.containerStatuses[]; .ready == true)))' >/dev/null && printf "Workload cluster Pods are healthy\n"
```

??? example "Expected result"
    ```text
    Workload cluster Pods are healthy
    ```

Display Machine readiness and upgrade state.

```bash
# Display Machine readiness and upgrade state.
kubectl --kubeconfig="$HOME/.kube/config" get machines -l cluster.x-k8s.io/cluster-name=myk8scluster -o json | jq -r '.items[] | [.metadata.name, .status.nodeRef.name, .status.phase, ([.status.conditions[] | select(.type == "Ready")][0].status // "Missing"), (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-status"] // "none"), (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-to"] // "none")] | @tsv' | sort -k2
```

??? example "Expected result"
    ```text
    myk8scluster-control-plane-cvgdl       k8s-ctrl      Running   True   none   none
    myk8scluster-worker-md-0-m8bgf-rjszd   k8s-worker1   Running   True   none   none
    myk8scluster-worker-md-0-m8bgf-sxbrk   k8s-worker2   Running   True   none   none
    ```

Display installed, tracked, and target snap versions.

```bash
# Display source, tracking, and target snap versions on every workload node.
for node in k8s-ctrl k8s-worker1 k8s-worker2; do printf "%s\t" "$node"; lxc exec "$node" -- snap info k8s | awk '$1 == "tracking:" { tracking=$2 } $1 == "installed:" { installed=$2 } $1 == "1.36-classic/candidate:" { target=$2 } END { print installed, tracking, target }'; done
```

??? example "Expected result"
    ```text
    k8s-ctrl      v1.35.7 1.35-classic/stable v1.36.4
    k8s-worker1   v1.35.7 1.35-classic/stable v1.36.4
    k8s-worker2   v1.35.7 1.35-classic/stable v1.36.4
    ```

Request the control-plane upgrade.

```bash
# Discover and request the in-place control-plane upgrade.
CONTROL_PLANE_MACHINE=$(kubectl --kubeconfig="$HOME/.kube/config" get machines -l cluster.x-k8s.io/cluster-name=myk8scluster -o json | jq -er '[.items[] | select(.status.nodeRef.name == "k8s-ctrl")] | if length == 1 then .[0].metadata.name else error("expected one control-plane machine") end') && kubectl --kubeconfig="$HOME/.kube/config" annotate machine "$CONTROL_PLANE_MACHINE" "v1beta2.k8sd.io/in-place-upgrade-to=channel=1.36-classic/candidate"
```

??? example "Expected result"
    ```text
    machine.cluster.x-k8s.io/myk8scluster-control-plane-cvgdl annotated
    ```

Monitor the control-plane upgrade.

```bash
# Monitor the control-plane Machine upgrade.
CONTROL_PLANE_MACHINE=$(kubectl --kubeconfig="$HOME/.kube/config" get machines -l cluster.x-k8s.io/cluster-name=myk8scluster -o json | jq -er '[.items[] | select(.status.nodeRef.name == "k8s-ctrl")][0].metadata.name') && timeout 1800s bash -c 'set -euo pipefail; last=""; while true; do status=$(kubectl --kubeconfig="$HOME/.kube/config" get machine "$1" -o json | jq -r ".metadata.annotations[\"v1beta2.k8sd.io/in-place-upgrade-status\"] // \"pending\""); if [[ "$status" != "$last" ]]; then printf "%s upgrade status: %s\n" "$1" "$status"; last="$status"; fi; case "$status" in done) exit 0 ;; failed) exit 2 ;; esac; sleep 10; done' _ "$CONTROL_PLANE_MACHINE"
```

??? example "Expected result"
    ```text
    myk8scluster-control-plane-cvgdl upgrade status: in-progress
    myk8scluster-control-plane-cvgdl upgrade status: done
    ```

Display the completed control-plane annotations.

```bash
# Display the completed control-plane upgrade annotations.
CONTROL_PLANE_MACHINE=$(kubectl --kubeconfig="$HOME/.kube/config" get machines -l cluster.x-k8s.io/cluster-name=myk8scluster -o json | jq -er '[.items[] | select(.status.nodeRef.name == "k8s-ctrl")][0].metadata.name') && kubectl --kubeconfig="$HOME/.kube/config" get machine "$CONTROL_PLANE_MACHINE" -o json | jq -r '[.metadata.name, .metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-release"], .metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-status"], (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-to"] // "absent"), (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at"] // "absent"), (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-change-id"] // "absent")] | @tsv'
```

??? example "Expected result"
    ```text
    myk8scluster-control-plane-cvgdl   channel=1.36-classic/candidate   done   absent   absent   absent
    ```

Verify the control-plane node.

```bash
# Verify control-plane readiness and runtime version.
kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" wait --for=condition=Ready node/k8s-ctrl --timeout=600s && test "$(kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get node k8s-ctrl -o jsonpath='{.status.nodeInfo.kubeletVersion}')" = "v1.36.4" && printf "k8s-ctrl is Ready at v1.36.4\n"
```

??? example "Expected result"
    ```text
    node/k8s-ctrl condition met
    k8s-ctrl is Ready at v1.36.4
    ```

Request the first worker upgrade.

```bash
# Discover and request the first worker upgrade.
WORKER_MACHINE=$(kubectl --kubeconfig="$HOME/.kube/config" get machines -l cluster.x-k8s.io/cluster-name=myk8scluster -o json | jq -er '[.items[] | select(.status.nodeRef.name == "k8s-worker1")] | if length == 1 then .[0].metadata.name else error("expected one machine for k8s-worker1") end') && kubectl --kubeconfig="$HOME/.kube/config" annotate machine "$WORKER_MACHINE" "v1beta2.k8sd.io/in-place-upgrade-to=channel=1.36-classic/candidate"
```

??? example "Expected result"
    ```text
    machine.cluster.x-k8s.io/myk8scluster-worker-md-0-m8bgf-rjszd annotated
    ```

Monitor the first worker upgrade.

```bash
# Monitor the first worker Machine upgrade.
WORKER_MACHINE=$(kubectl --kubeconfig="$HOME/.kube/config" get machines -l cluster.x-k8s.io/cluster-name=myk8scluster -o json | jq -er '[.items[] | select(.status.nodeRef.name == "k8s-worker1")][0].metadata.name') && timeout 1800s bash -c 'set -euo pipefail; last=""; while true; do status=$(kubectl --kubeconfig="$HOME/.kube/config" get machine "$1" -o json | jq -r ".metadata.annotations[\"v1beta2.k8sd.io/in-place-upgrade-status\"] // \"pending\""); if [[ "$status" != "$last" ]]; then printf "%s upgrade status: %s\n" "$1" "$status"; last="$status"; fi; case "$status" in done) exit 0 ;; failed) exit 2 ;; esac; sleep 10; done' _ "$WORKER_MACHINE"
```

??? example "Expected result"
    ```text
    myk8scluster-worker-md-0-m8bgf-rjszd upgrade status: pending
    myk8scluster-worker-md-0-m8bgf-rjszd upgrade status: in-progress
    myk8scluster-worker-md-0-m8bgf-rjszd upgrade status: done
    ```

Display the completed first-worker annotations.

```bash
# Display the completed first-worker upgrade annotations.
WORKER_MACHINE=$(kubectl --kubeconfig="$HOME/.kube/config" get machines -l cluster.x-k8s.io/cluster-name=myk8scluster -o json | jq -er '[.items[] | select(.status.nodeRef.name == "k8s-worker1")][0].metadata.name') && kubectl --kubeconfig="$HOME/.kube/config" get machine "$WORKER_MACHINE" -o json | jq -r '[.metadata.name, .metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-release"], .metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-status"], (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-to"] // "absent"), (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at"] // "absent"), (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-change-id"] // "absent")] | @tsv'
```

??? example "Expected result"
    ```text
    myk8scluster-worker-md-0-m8bgf-rjszd   channel=1.36-classic/candidate   done   absent   absent   absent
    ```

Verify the first worker.

```bash
# Verify first-worker readiness and runtime version.
kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" wait --for=condition=Ready node/k8s-worker1 --timeout=600s && test "$(kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get node k8s-worker1 -o jsonpath='{.status.nodeInfo.kubeletVersion}')" = "v1.36.4" && printf "k8s-worker1 is Ready at v1.36.4\n"
```

??? example "Expected result"
    ```text
    node/k8s-worker1 condition met
    k8s-worker1 is Ready at v1.36.4
    ```

Verify all nodes before the second worker.

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

Request the second worker upgrade.

```bash
# Discover and request the second worker upgrade.
WORKER_MACHINE=$(kubectl --kubeconfig="$HOME/.kube/config" get machines -l cluster.x-k8s.io/cluster-name=myk8scluster -o json | jq -er '[.items[] | select(.status.nodeRef.name == "k8s-worker2")] | if length == 1 then .[0].metadata.name else error("expected one machine for k8s-worker2") end') && kubectl --kubeconfig="$HOME/.kube/config" annotate machine "$WORKER_MACHINE" "v1beta2.k8sd.io/in-place-upgrade-to=channel=1.36-classic/candidate"
```

??? example "Expected result"
    ```text
    machine.cluster.x-k8s.io/myk8scluster-worker-md-0-m8bgf-sxbrk annotated
    ```

Restart the second worker after its upgrade reboot left the lab VM stopped.

```bash
# Restart the stopped second-worker VM.
timeout 120s lxc start k8s-worker2
```

??? example "Expected result"
    ```text
    No output.
    ```

Configure deterministic management DNS.

```bash
# Route management-cluster .maas queries through the MAAS DNS gateway.
MAAS_DNS=$(ip -4 -o addr show lxdbr0 | awk '{split($4, address, "/"); print address[1]}') && COREFILE=$(kubectl --kubeconfig="$HOME/.kube/config" get configmap ck-dns-coredns --namespace kube-system -o jsonpath='{.data.Corefile}') && if grep -q "^maas:53 {" <<<"$COREFILE"; then printf "MAAS forwarding already configured\n"; else PATCHED_COREFILE=$(printf 'maas:53 {\n    errors\n    cache 30\n    forward . %s\n}\n%s' "$MAAS_DNS" "$COREFILE") && kubectl --kubeconfig="$HOME/.kube/config" patch configmap ck-dns-coredns --namespace kube-system --type merge -p "$(jq -nc --arg corefile "$PATCHED_COREFILE" '{data: {Corefile: $corefile}}')"; fi
```

??? example "Expected result"
    ```text
    configmap/ck-dns-coredns patched
    ```

Verify management-cluster workload API resolution.

```bash
# Require ten consistent workload API DNS responses.
COREDNS_IP=$(kubectl --kubeconfig="$HOME/.kube/config" get service coredns --namespace kube-system -o jsonpath='{.spec.clusterIP}') && API_SERVER=$(kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" config view --minify -o jsonpath='{.clusters[0].cluster.server}') && API_HOST=${API_SERVER#https://} && API_HOST=${API_HOST%%:*} && EXPECTED_IP=$(getent ahostsv4 "$API_HOST" | awk 'NR == 1 { print $1 }') && timeout 180s bash -c 'while true; do resolved=0; for query in {1..10}; do [[ "$(lxc exec cluster-ctrl -- dig +time=2 +tries=1 +short @"$1" "$2" A | sort -u)" == "$3" ]] && ((resolved+=1)); done; if [[ "$resolved" -eq 10 ]]; then printf "Management DNS resolved %s consistently\n" "$2"; exit 0; fi; sleep 5; done' _ "$COREDNS_IP" "$API_HOST" "$EXPECTED_IP"
```

??? example "Expected result"
    ```text
    Management DNS resolved myk8scluster-1d008f.maas consistently
    ```

Resume monitoring the existing second-worker request.

```bash
# Monitor the second worker Machine upgrade.
WORKER_MACHINE=$(kubectl --kubeconfig="$HOME/.kube/config" get machines -l cluster.x-k8s.io/cluster-name=myk8scluster -o json | jq -er '[.items[] | select(.status.nodeRef.name == "k8s-worker2")][0].metadata.name') && timeout 600s bash -c 'last=""; while true; do if ! machine_json=$(kubectl --kubeconfig="$HOME/.kube/config" get machine "$1" -o json 2>/dev/null); then sleep 10; continue; fi; status=$(jq -r ".metadata.annotations[\"v1beta2.k8sd.io/in-place-upgrade-status\"] // \"pending\"" <<<"$machine_json"); if [[ "$status" != "$last" ]]; then printf "%s upgrade status: %s\n" "$1" "$status"; last="$status"; fi; case "$status" in done) exit 0 ;; failed) exit 2 ;; esac; sleep 10; done' _ "$WORKER_MACHINE"
```

??? example "Expected result"
    ```text
    myk8scluster-worker-md-0-m8bgf-sxbrk upgrade status: done
    ```

Display the completed second-worker annotations.

```bash
# Display the completed second-worker upgrade annotations.
WORKER_MACHINE=$(kubectl --kubeconfig="$HOME/.kube/config" get machines -l cluster.x-k8s.io/cluster-name=myk8scluster -o json | jq -er '[.items[] | select(.status.nodeRef.name == "k8s-worker2")][0].metadata.name') && kubectl --kubeconfig="$HOME/.kube/config" get machine "$WORKER_MACHINE" -o json | jq -r '[.metadata.name, .metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-release"], .metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-status"], (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-to"] // "absent"), (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at"] // "absent"), (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-change-id"] // "absent")] | @tsv'
```

??? example "Expected result"
    ```text
    myk8scluster-worker-md-0-m8bgf-sxbrk   channel=1.36-classic/candidate   done   absent   absent   absent
    ```

Verify the second worker.

```bash
# Verify second-worker readiness and runtime version.
kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" wait --for=condition=Ready node/k8s-worker2 --timeout=600s && test "$(kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get node k8s-worker2 -o jsonpath='{.status.nodeInfo.kubeletVersion}')" = "v1.36.4" && printf "k8s-worker2 is Ready at v1.36.4\n"
```

??? example "Expected result"
    ```text
    node/k8s-worker2 condition met
    k8s-worker2 is Ready at v1.36.4
    ```

Restart the first worker after its delayed upgrade shutdown.

```bash
# Restart the stopped first-worker VM.
lxc start k8s-worker1
```

??? example "Expected result"
    ```text
    No output.
    ```

Require a final stabilization window.

```bash
# Require stable VM and node health across the workload cluster.
timeout 900s bash -c 'stable_since=0; while true; do running=$(lxc list --format csv -c ns | grep -Ec "^k8s-(ctrl|worker1|worker2),RUNNING$"); node_count=$(kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get nodes --no-headers 2>/dev/null | wc -l); version_count=$(kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get nodes -o jsonpath="{range .items[*]}{.status.nodeInfo.kubeletVersion}{\"\\n\"}{end}" 2>/dev/null | grep -cx "v1.36.4"); if [[ "$running" -eq 3 && "$node_count" -eq 3 && "$version_count" -eq 3 ]] && kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" wait --for=condition=Ready nodes --all --timeout=10s >/dev/null 2>&1; then now=$(date +%s); [[ "$stable_since" -ne 0 ]] || stable_since=$now; if (( now - stable_since >= 120 )); then printf "All workload VMs and nodes remained healthy at v1.36.4 for 120 seconds\n"; exit 0; fi; else stable_since=0; fi; sleep 10; done'
```

??? example "Expected result"
    ```text
    All workload VMs and nodes remained healthy at v1.36.4 for 120 seconds
    ```

Display the final workload nodes.

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

Assert the final workload node state.

```bash
# Verify every workload node is Ready at the validated target version.
kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get nodes -o json | jq -e '(.items | length == 3) and all(.items[]; .status.nodeInfo.kubeletVersion == "v1.36.4" and ([.status.conditions[] | select(.type == "Ready")][0].status == "True"))' >/dev/null && printf "All workload nodes are Ready at v1.36.4\n"
```

??? example "Expected result"
    ```text
    All workload nodes are Ready at v1.36.4
    ```

Verify workload Pod health after the upgrade.

```bash
# Verify final workload-cluster Pod health.
kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get pods -A -o json | jq -e 'all(.items[]; .status.phase == "Succeeded" or (.status.phase == "Running" and (.status.containerStatuses | type == "array") and (.status.containerStatuses | length > 0) and all(.status.containerStatuses[]; .ready == true)))' >/dev/null && printf "Workload cluster Pods are healthy\n"
```

??? example "Expected result"
    ```text
    Workload cluster Pods are healthy
    ```

Display final snap versions and channels.

```bash
# Display final snap versions and tracking channels.
for node in k8s-ctrl k8s-worker1 k8s-worker2; do printf "%s\t" "$node"; lxc exec "$node" -- snap info k8s | awk '$1 == "tracking:" { tracking=$2 } $1 == "installed:" { installed=$2 } END { print installed, tracking }'; done
```

??? example "Expected result"
    ```text
    k8s-ctrl      v1.36.4 1.36-classic/candidate
    k8s-worker1   v1.36.4 1.36-classic/candidate
    k8s-worker2   v1.36.4 1.36-classic/candidate
    ```

Display runtime and declarative Machine state.

```bash
# Display runtime upgrade annotations alongside declarative Machine versions.
kubectl --kubeconfig="$HOME/.kube/config" get machines -l cluster.x-k8s.io/cluster-name=myk8scluster -o json | jq -r '.items | sort_by(.status.nodeRef.name)[] | [.metadata.name, .status.nodeRef.name, .spec.version, .metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-release"], .metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-status"], (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-to"] // "absent"), (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at"] // "absent"), (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-change-id"] // "absent")] | @tsv'
```

??? example "Expected result"
    ```text
    myk8scluster-control-plane-cvgdl       k8s-ctrl      v1.35.7   channel=1.36-classic/candidate   done   absent   absent   absent
    myk8scluster-worker-md-0-m8bgf-rjszd   k8s-worker1   v1.35.7   channel=1.36-classic/candidate   done   absent   absent   absent
    myk8scluster-worker-md-0-m8bgf-sxbrk   k8s-worker2   v1.35.7   channel=1.36-classic/candidate   done   absent   absent   absent
    ```

Assert final Machine annotations.

```bash
# Verify completed Machine upgrade annotations.
kubectl --kubeconfig="$HOME/.kube/config" get machines -l cluster.x-k8s.io/cluster-name=myk8scluster -o json | jq -e '(.items | length == 3) and all(.items[]; .metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-release"] == "channel=1.36-classic/candidate" and .metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-status"] == "done" and (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-to"] == null) and (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-last-failed-attempt-at"] == null) and (.metadata.annotations["v1beta2.k8sd.io/in-place-upgrade-change-id"] == null))' >/dev/null && printf "All Machine upgrades completed without residual request or failure annotations\n"
```

??? example "Expected result"
    ```text
    All Machine upgrades completed without residual request or failure annotations
    ```

Display final CAPI state.

```bash
# Display final CAPI control-plane, worker, and Machine status.
kubectl --kubeconfig="$HOME/.kube/config" get ck8scontrolplanes,machinedeployments,machines
```

??? example "Expected result"
    ```text
    myk8scluster-control-plane            true   true   1.35.7   1   1   1
    myk8scluster-worker-md-0              True   2      2        2   Running   v1.35.7
    myk8scluster-control-plane-cvgdl       k8s-ctrl      True   True   Running   v1.35.7
    myk8scluster-worker-md-0-m8bgf-rjszd   k8s-worker1   True   True   Running   v1.35.7
    myk8scluster-worker-md-0-m8bgf-sxbrk   k8s-worker2   True   True   Running   v1.35.7
    ```

Display final Cluster conditions.

```bash
# Display final Cluster availability and Machine readiness conditions.
kubectl --kubeconfig="$HOME/.kube/config" get cluster myk8scluster -o json | jq -r '[.status.conditions[] | select(.type == "Available" or .type == "ControlPlaneAvailable" or .type == "WorkersAvailable" or .type == "ControlPlaneMachinesReady" or .type == "WorkerMachinesReady") | [.type, .status]] | sort_by(.[0])[] | @tsv'
```

??? example "Expected result"
    ```text
    Available                    True
    ControlPlaneAvailable        True
    ControlPlaneMachinesReady    True
    WorkerMachinesReady          True
    WorkersAvailable             True
    ```

Verify final management Pod health.

```bash
# Verify final management-cluster Pod health.
kubectl --kubeconfig="$HOME/.kube/config" get pods -A -o json | jq -e 'all(.items[]; .status.phase == "Succeeded" or (.status.phase == "Running" and (.status.containerStatuses | type == "array") and (.status.containerStatuses | length > 0) and all(.status.containerStatuses[]; .ready == true)))' >/dev/null && printf "Management cluster Pods are healthy\n"
```

??? example "Expected result"
    ```text
    Management cluster Pods are healthy
    ```

Display final workload VM state.

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

Verify both APIs after the upgrade.

```bash
# Verify final management and workload API readiness.
kubectl --kubeconfig="$HOME/.kube/config" get --raw="/readyz" && kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get --raw="/readyz"
```

??? example "Expected result"
    ```text
    okok
    ```

Smoke-check the normalized monitor's completed-state path.

```bash
# Smoke-check the normalized Machine monitor after completion.
wait_for_machine_upgrade() { local machine="$1" node="$2"; timeout 1800s bash -c 'last=""; while true; do state=$(lxc list "$2" --format csv -c s); if [[ "$state" == "STOPPED" ]] && lxc start "$2"; then printf "%s VM restarted after upgrade reboot\n" "$2"; fi; if ! machine_json=$(kubectl --kubeconfig="$HOME/.kube/config" get machine "$1" -o json 2>/dev/null); then sleep 10; continue; fi; status=$(jq -r ".metadata.annotations[\"v1beta2.k8sd.io/in-place-upgrade-status\"] // \"pending\"" <<<"$machine_json"); if [[ "$status" != "$last" ]]; then printf "%s upgrade status: %s\n" "$1" "$status"; last="$status"; fi; case "$status" in done) exit 0 ;; failed) exit 2 ;; esac; sleep 10; done' _ "$machine" "$node"; }; WORKER2_MACHINE=$(kubectl --kubeconfig="$HOME/.kube/config" get machines -l cluster.x-k8s.io/cluster-name=myk8scluster -o json | jq -er '[.items[] | select(.status.nodeRef.name == "k8s-worker2")][0].metadata.name') && wait_for_machine_upgrade "$WORKER2_MACHINE" k8s-worker2
```

??? example "Expected result"
    ```text
    myk8scluster-worker-md-0-m8bgf-sxbrk upgrade status: done
    ```

Validate the normalized stabilization helper.

```bash
# Validate the normalized post-upgrade stabilization helper.
stabilize_node() { local node="$1" version="$2"; timeout 900s bash -c 'stable_since=0; while true; do state=$(lxc list "$1" --format csv -c s); if [[ "$state" == "STOPPED" ]] && lxc start "$1"; then printf "%s VM restarted during stabilization\n" "$1"; fi; current_version=$(kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" get node "$1" -o jsonpath="{.status.nodeInfo.kubeletVersion}" 2>/dev/null || true); if [[ "$state" == "RUNNING" && "$current_version" == "$2" ]] && kubectl --kubeconfig="$HOME/.kube/myk8scluster_config" wait --for=condition=Ready "node/$1" --timeout=10s >/dev/null 2>&1; then now=$(date +%s); [[ "$stable_since" -ne 0 ]] || stable_since=$now; if (( now - stable_since >= 120 )); then printf "%s remained Ready at %s for 120 seconds\n" "$1" "$2"; exit 0; fi; else stable_since=0; fi; sleep 10; done' _ "$node" "$version"; }; stabilize_node k8s-worker2 v1.36.4
```

??? example "Expected result"
    ```text
    k8s-worker2 remained Ready at v1.36.4 for 120 seconds
    ```
