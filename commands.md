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
