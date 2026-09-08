# 1. Kubernetes Basics

Kubernetes is an open-source infrastructure for automating deployment, scaling, and management of containerized
applications. Originally built by Google, it is currently maintained by the Cloud Native Computing Foundation.

A Kubernetes cluster includes these primary components:

* control plane components:
    * **etcd**{ .component-name } distributed key-value store
    * the **API server**{ .component-name }
    * the **scheduler**{ .component-name }
    * the **controller manager**{ .component-name }
* node components:
    * the **kubelet**{ .component-name }
    * the **kube-proxy**{ .component-name } network proxy
    * a container runtime, such as **containerd**{ .component-name }

## :material-book-open-page-variant-outline: Canonical Kubernetes

The official distribution of Kubernetes on Ubuntu delivers a pure 'upstream' version of Kubernetes for organizations to
use privately, plus a few more features like key distribution and overlay networking. We work directly with Google to
align with Google's GKE offering.

Like Ubuntu itself, Canonical Kubernetes is free to use, and Canonical backs it up with enterprise support, consulting,
and management services. Canonical makes it secure and easy to deploy, operate, and upgrade.

Canonical Kubernetes works on AWS, Google Cloud, Azure and Oracle Cloud as well as private infrastructure from bare-metal
racks to VMware and OpenStack. Ubuntu is the most widely used platform for container operations, and Canonical offers the
largest ecosystem of Kubernetes partners, solutions and integration options.

## :material-book-open-page-variant-outline: 1.1 Deploy Canonical Kubernetes

This lab uses MAAS and Cluster API (CAPI) to deploy and manage a Kubernetes cluster on MAAS using LXD VMs.

First, install MAAS and LXD:

```bash
# Install MAAS.
sudo snap install maas --channel=3.6/stable
```
??? example "Expected result"
    ```text
    maas (3.6/stable) 3.6.5-17655-g.474ecb517 from Canonical installed
    ```

```bash
# Install the MAAS test database.
sudo snap install maas-test-db --channel=3.6/stable
```
??? example "Expected result"
    ```text
    maas-test-db (3.6/stable) 16.6-34-g.9c27046 from Canonical installed
    ```

```bash
# Install LXD.
sudo snap install lxd --channel=5.21/stable
```
??? example "Expected result"
    ```text
    lxd (5.21/stable) 5.21.7-1018661 from Canonical installed
    ```

Next, initialize LXD and disable IPv6:

```bash
# Initialize LXD.
sudo lxd init --auto
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Disable IPv6 on the LXD bridge.
sudo lxc network set lxdbr0 ipv6.address none
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Disable IPv6 NAT on the LXD bridge.
sudo lxc network unset lxdbr0 ipv6.nat
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Disable DNS on the LXD bridge.
sudo lxc network set lxdbr0 dns.mode=none
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Disable DHCP on the LXD bridge.
sudo lxc network set lxdbr0 ipv4.dhcp=false
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Set the LXD HTTPS address.
sudo lxc config set core.https_address 127.0.0.1:8443
```
??? example "Expected result"
    ```text
    No output.
    ```

Then, disable IPv6 system-wide:

```bash
# Configure IPv6 to be disabled system wide.
sudo tee -a /etc/sysctl.conf <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF
```
??? example "Expected result"
    ```text
    net.ipv6.conf.all.disable_ipv6 = 1
    net.ipv6.conf.default.disable_ipv6 = 1
    ```

```bash
# Reload sysctl settings.
sudo sysctl -p
```
??? example "Expected result"
    ```text
    net.ipv6.conf.all.disable_ipv6 = 1
    net.ipv6.conf.default.disable_ipv6 = 1
    ```

```bash
# Disable IPv6 for all interfaces.
sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
```
??? example "Expected result"
    ```text
    net.ipv6.conf.all.disable_ipv6 = 1
    ```

```bash
# Disable IPv6 for default interfaces.
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
```
??? example "Expected result"
    ```text
    net.ipv6.conf.default.disable_ipv6 = 1
    ```

Next, let's also initialize MAAS:

```bash
# Initialize MAAS.
IP_ADDRESS=$(hostname -I | awk '{print $1}')
sudo maas init region+rack --database-uri maas-test-db:/// --maas-url http://${IP_ADDRESS}:5240/MAAS
```
??? example "Expected result"
    ```text
    MAAS has been set up.
    ```

Now that both LXD and MAAS are installed, complete the initial MAAS setup and integrate it with LXD. The local LXD instance will be registered in MAAS as a VM host:

```bash
# Create the MAAS administrator.
sudo maas createadmin --username=admin --password=ubuntu --email=admin@example.com
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Save the MAAS API key.
sudo maas apikey --username=admin > ~/maas-apikey
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Log in to MAAS.
maas login deployprofile http://${IP_ADDRESS}:5240/MAAS - < ~/maas-apikey
```
??? example "Expected result"
    ```text
    You are now logged in to the MAAS server at http://10.156.0.5:5240/MAAS/api/2.0/ with the profile name 'deployprofile'.
    ```

```bash
# Import boot resources.
maas deployprofile boot-resources import
```
??? example "Expected result"
    ```text
    Import of boot resources started
    ```

```bash
# Register the local LXD host.
maas deployprofile vm-hosts create type=lxd power_address=https://127.0.0.1:8443 project=default name=localhost
```
??? example "Expected result"
    ```json
    {
      "type": "lxd",
      "name": "localhost",
      "id": 1
    }
    ```

```bash
# Save the LXD host certificate.
maas deployprofile vm-host parameters 1 | jq -r '.certificate' > /tmp/maas.crt
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Trust the MAAS certificate in LXD.
sudo lxc config trust add /tmp/maas.crt
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Refresh the LXD host in MAAS.
maas deployprofile vm-host refresh 1
```
??? example "Expected result"
    ```json
    {
      "type": "lxd",
      "name": "localhost",
      "version": "5.21.7",
      "id": 1
    }
    ```

```bash
# Generate an SSH key pair.
ssh-keygen -t rsa -N "" -q -f ~/.ssh/id_rsa
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Add the SSH public key to MAAS.
maas deployprofile sshkeys create key="`cat ~/.ssh/id_rsa.pub`"
```
??? example "Expected result"
    ```json
    {
      "key": "ssh-rsa ... ubuntu@radumoisan.cloudbase.internal",
      "id": 1
    }
    ```

LXD has its own network, but MAAS will handle DNS and DHCP. To configure MAAS to work with LXD's network, run:

```bash
# Detect the LXD network CIDR.
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
    ```text
    Detected CIDR: 10.107.242.0/24
    ```

```bash
# Get the matching MAAS subnet ID.
# Get subnet ID from MAAS
SUBNET_ID=$(maas "$PROFILE" subnets read \
  | jq -r ".[] | select(.cidr==\"$CIDR\") | .id")

if [[ -z "$SUBNET_ID" ]]; then
  echo "ERROR: No subnet found for CIDR $CIDR"
  exit 1
fi

echo "Subnet ID: $SUBNET_ID"
```
??? example "Expected result"
    ```text
    Subnet ID: 2
    ```

```bash
# Create the reserved MAAS IP range.
# Define ranges
RES_START="${NET_PREFIX}.1"
RES_END="${NET_PREFIX}.50"
DYN_START="${NET_PREFIX}.51"
DYN_END="${NET_PREFIX}.60"

# Create reserved range
maas "$PROFILE" ipranges create \
  type=reserved \
  start_ip="$RES_START" \
  end_ip="$RES_END" \
  comment="Reserved range from script"
```
??? example "Expected result"
    ```json
    {
      "type": "reserved",
      "start_ip": "10.107.242.1",
      "end_ip": "10.107.242.50",
      "id": 1
    }
    ```

```bash
# Create the dynamic MAAS IP range.
# Create dynamic range
maas "$PROFILE" ipranges create \
  type=dynamic \
  start_ip="$DYN_START" \
  end_ip="$DYN_END" \
  comment="Dynamic range from script"
```
??? example "Expected result"
    ```json
    {
      "type": "dynamic",
      "start_ip": "10.107.242.51",
      "end_ip": "10.107.242.60",
      "id": 2
    }
    ```

```bash
# Set the subnet gateway and DNS servers.
# Set gateway and DNS on subnet
maas "$PROFILE" subnet update "$SUBNET_ID" \
  gateway_ip="$BASE_IP" \
  dns_servers="1.1.1.1 1.0.0.1"
```
??? example "Expected result"
    ```json
    {
      "gateway_ip": "10.107.242.1",
      "dns_servers": ["1.1.1.1", "1.0.0.1"]
    }
    ```

```bash
# Enable DHCP on the MAAS VLAN.
# Get VLAN info
VLAN_JSON=$(maas "$PROFILE" subnet read "$SUBNET_ID")
FABRIC_ID=$(echo "$VLAN_JSON" | jq -r '.vlan.fabric_id')
VID=$(echo "$VLAN_JSON" | jq -r '.vlan.vid')

# Pick first rack controller (or choose explicitly)
PRIMARY_RACK=$(maas "$PROFILE" rack-controllers read | jq -r '.[0].system_id')

echo "Using rack controller: $PRIMARY_RACK"

# Enable DHCP with rack controller
maas "$PROFILE" vlan update "$FABRIC_ID" "$VID" \
  primary_rack="$PRIMARY_RACK" \
  dhcp_on=true
```
??? example "Expected result"
    ```text
    Using rack controller: yhc4bf
    "dhcp_on": true
    "primary_rack": "yhc4bf"
    "fabric_id": 1
    "vid": 0
    ```

```bash
# Set the MAAS upstream DNS server.
maas "$PROFILE" maas set-config name=upstream_dns value="1.1.1.1"
```
??? example "Expected result"
    ```text
    OK
    ```

```bash
# Configure systemd-resolved to use the local MAAS DNS server.
# also, make sure your OS uses your local IP for resolving:
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
    ```text
    No output.
    ```

Finally, let's create the VMs required by our setup:

```bash
# Set the VM CPU overcommit ratio.
maas deployprofile vm-host update 1 cpu_over_commit_ratio=2
```
??? example "Expected result"
    ```json
    {
      "cpu_over_commit_ratio": 2.0
    }
    ```

```bash
# Create the management VM.
maas deployprofile vm-host compose 1 cores=2 memory=4096 storage="1:40(default)" hostname=cluster-ctrl architecture="amd64/generic" interfaces=eth0:subnet=$SUBNET_ID
```
??? example "Expected result"
    ```json
    {
      "system_id": "hgwgkf",
      "resource_uri": "/MAAS/api/2.0/machines/hgwgkf/"
    }
    ```

```bash
# Create the Kubernetes control-plane VM.
maas deployprofile vm-host compose 1 cores=4 memory=8192 storage="1:80(default)" hostname=k8s-ctrl architecture="amd64/generic" interfaces=eth0:subnet=$SUBNET_ID
```
??? example "Expected result"
    ```json
    {
      "system_id": "r7mpbc",
      "resource_uri": "/MAAS/api/2.0/machines/r7mpbc/"
    }
    ```

```bash
# Create the first Kubernetes worker VM.
maas deployprofile vm-host compose 1 cores=4 memory=8192 storage="1:80(default)" hostname=k8s-worker1 architecture="amd64/generic" interfaces=eth0:subnet=$SUBNET_ID
```
??? example "Expected result"
    ```json
    {
      "system_id": "gfyma6",
      "resource_uri": "/MAAS/api/2.0/machines/gfyma6/"
    }
    ```

```bash
# Create the second Kubernetes worker VM.
maas deployprofile vm-host compose 1 cores=4 memory=8192 storage="1:80(default)" hostname=k8s-worker2 architecture="amd64/generic" interfaces=eth0:subnet=$SUBNET_ID
```
??? example "Expected result"
    ```json
    {
      "system_id": "h3xmm8",
      "resource_uri": "/MAAS/api/2.0/machines/h3xmm8/"
    }
    ```

VMs are created and commissioned automatically. Before proceeding, tag these machines:

```bash
# Tag the commissioned machines.
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

    # Create tag (ignore error if it already exists)
    maas "$PROFILE" tags create name="$TAG" 2>/dev/null || true

    # Assign tag to this machine
    maas "$PROFILE" tag update-nodes "$TAG" add="$ID"
done
```
??? example "Expected result"
    ```text
    Processing cluster-ctrl (hgwgkf)
    "added": 1
    "removed": 0
    ...
    Processing k8s-ctrl (r7mpbc)
    ...
    Processing k8s-worker1 (gfyma6)
    ...
    Processing k8s-worker2 (h3xmm8)
    ```

Next, deploy an operating system to the management machine. The Kubernetes management cluster will run on `cluster-ctrl` and provision workload clusters.

```bash
# Get the management machine system ID.
CLUSTERCTL_SYSTEM_ID=$(maas "$PROFILE" machines read \
  | jq -r '.[] | select(.tag_names[] == "cluster-ctrl") | .system_id')
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Deploy Ubuntu Noble to the management machine.
maas "$PROFILE" machine deploy "$CLUSTERCTL_SYSTEM_ID" distro_series="ubuntu/noble"
```
??? example "Expected result"
    ```json
    {
      "hostname": "cluster-ctrl",
      "distro_series": "noble",
      "status_name": "Deploying"
    }
    ```

After the machine is deployed with Ubuntu Noble (24.04), install and bootstrap Canonical Kubernetes as the management cluster, then install `clusterctl`:

!!! note
    The `k8s` command is the administration CLI installed by the Canonical Kubernetes snap. It manages the local cluster through commands such as `bootstrap`, `status`, and `config`.

    `k8s kubectl` runs the kubectl client bundled with Canonical Kubernetes and connects to the local management cluster. Plain `kubectl`, introduced later, connects to the cluster selected through `KUBECONFIG`.

```bash
# Get the management machine IP address.
CLUSTERCTL_IP=$(maas "$PROFILE" machine read "$CLUSTERCTL_SYSTEM_ID" \
  | jq -r '.interface_set[].links[].ip_address // empty' \
  | head -n1)
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Install Canonical Kubernetes on the management machine.
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$CLUSTERCTL_IP "sudo snap install k8s --classic --channel=1.35-classic/stable"
```
??? example "Expected result"
    ```text
    k8s (1.35-classic/stable) v1.35.7 from Canonical installed
    ```

```bash
# Bootstrap Canonical Kubernetes on the management machine.
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$CLUSTERCTL_IP "sudo k8s bootstrap && sudo k8s status --wait-ready"
```
??? example "Expected result"
    ```text
    cluster status:           ready
    control plane nodes:      10.107.242.61:6400 (voter)
    network:                  enabled
    dns:                      enabled at 10.152.183.91
    ```

```bash
# Create the management cluster kubeconfig.
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$CLUSTERCTL_IP "mkdir -p ~/.kube/ && sudo k8s config > ~/.kube/config"
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Download clusterctl to the management machine.
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$CLUSTERCTL_IP "curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.13.5/clusterctl-linux-amd64 -o clusterctl"
```
??? example "Expected result"
    ```text
      % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                     Dload  Upload   Total   Spent    Left  Speed
    100 32.7M  100 32.7M    0     0  ...
    ```

```bash
# Install clusterctl on the management machine.
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$CLUSTERCTL_IP "sudo install -o root -g root -m 0755 clusterctl /usr/local/bin/clusterctl"
```
??? example "Expected result"
    ```text
    No output.
    ```

Next, initialize the CAPI providers and generate the resource manifest for the workload cluster:

```bash
# Set the variables used to generate the Cluster API manifest.
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
    ```text
    No output.
    ```

```bash
# Initialize the providers and generate the Cluster API manifest remotely.
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

# Install the Cluster API providers in the management cluster.
# Core provider: manages common Cluster API resources.
# Bootstrap provider: generates Canonical Kubernetes node configuration.
# Control-plane provider: manages Canonical Kubernetes control-plane nodes.
# Infrastructure provider: provisions machines through MAAS.
clusterctl init \
  --core "cluster-api:${CAPI_VERSION}" \
  --bootstrap "canonical-kubernetes:${CK8S_PROVIDER_VERSION}" \
  --control-plane "canonical-kubernetes:${CK8S_PROVIDER_VERSION}" \
  --infrastructure "maas:${MAAS_PROVIDER_VERSION}"

# Download the Canonical Kubernetes Cluster API templates.
git clone https://github.com/canonical/cluster-api-k8s

# Enter the downloaded provider repository.
cd cluster-api-k8s

# Set the name used for the workload cluster resources.
export CLUSTER_NAME=myk8scluster

# Display the variables required and supported by the MAAS template.
clusterctl generate cluster \${CLUSTER_NAME} --from ./templates/maas/cluster-template.yaml --list-variables

# Render the workload-cluster resources into cluster.yaml.
clusterctl generate cluster \${CLUSTER_NAME} --from ./templates/maas/cluster-template.yaml > cluster.yaml
EOF
```
??? example "Expected result"
    ```text
    Fetching providers
    ...
    Your management cluster has been initialized successfully!
    ...
    Cloning into 'cluster-api-k8s'...
    ...
    Required Variables:
      - CHANNEL
      - CONTROL_PLANE_MACHINE_IMAGE
      - CONTROL_PLANE_MACHINE_MINCPU
      - CONTROL_PLANE_MACHINE_MINMEMORY
      - KUBERNETES_VERSION
      - MAAS_DNS_DOMAIN
      - WORKER_MACHINE_IMAGE
      - WORKER_MACHINE_MINCPU
      - WORKER_MACHINE_MINMEMORY

    Optional Variables:
      - CLUSTER_NAME                        (defaults to myk8scluster)
      - CONTROL_PLANE_MACHINE_COUNT         (defaults to 1)
      - CONTROL_PLANE_MACHINE_RESOURCEPOOL  (defaults to " ")
      - CONTROL_PLANE_MACHINE_TAGS          (defaults to " ")
      - WORKER_MACHINE_COUNT                (defaults to 0)
      - WORKER_MACHINE_RESOURCEPOOL         (defaults to " ")
      - WORKER_MACHINE_TAGS                 (defaults to " ")
    ```

Apply the generated manifest to the management cluster. The CAPI controllers will reconcile these resources and provision the workload cluster:

```bash
# Connect to the management machine.
ssh $CLUSTERCTL_IP
```
??? example "Expected result"
    ```shell
    ubuntu@cluster-ctrl:~$
    ```

```bash
# Enter the Cluster API provider directory.
cd cluster-api-k8s
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Apply the generated cluster template.
sudo k8s kubectl apply -f cluster.yaml
```
??? example "Expected result"
    ```text
    cluster.cluster.x-k8s.io/myk8scluster created
    maascluster.infrastructure.cluster.x-k8s.io/myk8scluster created
    ck8scontrolplane.controlplane.cluster.x-k8s.io/myk8scluster-control-plane created
    maasmachinetemplate.infrastructure.cluster.x-k8s.io/myk8scluster-control-plane created
    machinedeployment.cluster.x-k8s.io/myk8scluster-worker-md-0 created
    maasmachinetemplate.infrastructure.cluster.x-k8s.io/myk8scluster-md-0 created
    ck8sconfigtemplate.bootstrap.cluster.x-k8s.io/myk8scluster-md-0 created
    ```

```bash
# Verify status with:
watch "sudo k8s kubectl get clusters; sudo k8s kubectl get machines"
```
??? example "Expected result"
    ```text
    myk8scluster   True   1   0   1   2   2   2   Provisioned

    myk8scluster-control-plane-cvgdl       myk8scluster   k8s-ctrl      True   True   Running
    myk8scluster-worker-md-0-m8bgf-rjszd   myk8scluster   k8s-worker1   True   True   True   Running
    myk8scluster-worker-md-0-m8bgf-sxbrk   myk8scluster   k8s-worker2   True   True   True   Running
    ```

```bash
# and
watch clusterctl describe cluster myk8scluster
```
??? example "Expected result"
    ```text
    Cluster/myk8scluster                                          3/3   2   3   3   True   Available
    ClusterInfrastructure - MaasCluster/myk8scluster                                 True   InfoReported
    ControlPlane - CK8sControlPlane/myk8scluster-control-plane   1/1       1   1   True   NoReasonReported
    MachineDeployment/myk8scluster-worker-md-0                   2/2   2   2   2   True   Available
    ```

```bash
# Exit the management machine.
exit
```
??? example "Expected result"
    ```shell
    logout
    Connection to 10.107.242.61 closed.
    ```

## :material-book-open-page-variant-outline: 1.2 Interacting with the cluster and observability

Continue on the outer GCE lab VM. It can reach the management and workload cluster API endpoints over the MAAS-managed LXD network.

`kubectl` is the Kubernetes command-line client. A kubeconfig file contains the cluster endpoint, user credentials, context, and optional namespace that `kubectl` uses.

!!! note
    Unless a step explicitly says to run on `cluster-ctrl`, run every command in this section on the outer GCE lab VM.

    The management kubeconfig is `~/.kube/config`. The workload kubeconfig is `~/.kube/myk8scluster_config`.

Create the kubeconfig directory on the outer lab VM:

```bash
# Create the local kubectl configuration directory.
mkdir -p ~/.kube
```
??? example "Expected result"
    ```text
    No output.
    ```

Connect to `cluster-ctrl`, where `clusterctl` and the management kubeconfig are installed:

```bash
# Connect to the management machine.
ssh $CLUSTERCTL_IP
```
??? example "Expected result"
    ```shell
    ubuntu@cluster-ctrl:~$
    ```

On `cluster-ctrl`, generate the workload-cluster kubeconfig:

```bash
# Generate the workload cluster kubeconfig on cluster-ctrl.
clusterctl get kubeconfig myk8scluster > ~/.kube/myk8scluster_config
```
??? example "Expected result"
    ```text
    No output.
    ```

Return to the outer lab VM:

```bash
# Exit cluster-ctrl.
exit
```
??? example "Expected result"
    ```shell
    logout
    Connection to 10.107.242.61 closed.
    ```

The two kubeconfig files currently reside on `cluster-ctrl`. Copy them to the outer lab VM before running plain `kubectl` there:

```bash
# Copy the workload cluster kubeconfig to the outer lab VM.
scp $CLUSTERCTL_IP:~/.kube/myk8scluster_config ~/.kube/
```
??? example "Expected result"
    ```text
    myk8scluster_config  100%
    ```

```bash
# Copy the management cluster kubeconfig to the outer lab VM.
scp $CLUSTERCTL_IP:~/.kube/config ~/.kube/
```
??? example "Expected result"
    ```text
    config  100%
    ```

Install `kubectl` once on the outer lab VM:

```bash
# Install kubectl on the outer lab VM.
sudo snap install kubectl --channel=1.35/stable --classic
```
??? example "Expected result"
    ```text
    kubectl (1.35/stable) 1.35.7 from Canonical installed
    ```

Select the management kubeconfig and verify the management cluster:

```bash
# Select the management cluster kubeconfig.
export KUBECONFIG=~/.kube/config
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Inspect the management cluster.
kubectl get nodes
```
??? example "Expected result"
    ```text
    NAME           STATUS   ROLES                  AGE   VERSION
    cluster-ctrl   Ready    control-plane,worker   123m   v1.35.7
    ```

Select the workload kubeconfig and verify the workload cluster:

```bash
# Select the workload cluster kubeconfig.
export KUBECONFIG=~/.kube/myk8scluster_config
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Inspect the workload cluster.
kubectl get nodes
```
??? example "Expected result"
    ```text
    NAME          STATUS   ROLES                  AGE   VERSION
    k8s-ctrl      Ready    control-plane,worker   87m   v1.35.7
    k8s-worker1   Ready    worker                 77m   v1.35.7
    k8s-worker2   Ready    worker                 77m   v1.35.7
    ```

```bash
# List all workload cluster pods.
kubectl get pods -A -o wide
```
??? example "Expected result"
    ```text
    NAMESPACE        NAME                                  READY   STATUS    RESTARTS   AGE   IP              NODE          NOMINATED NODE   READINESS GATES
    kube-system      cilium-2k597                          1/1     Running   0          91m   10.107.242.62   k8s-ctrl      <none>           <none>
    kube-system      cilium-lxtbw                          1/1     Running   0          81m   10.107.242.63   k8s-worker1   <none>           <none>
    kube-system      cilium-operator-77968f785f-gpmlz      1/1     Running   0          91m   10.107.242.62   k8s-ctrl      <none>           <none>
    kube-system      cilium-z74j9                          1/1     Running   0          81m   10.107.242.64   k8s-worker2   <none>           <none>
    kube-system      ck-storage-rawfile-csi-controller-0   2/2     Running   0          91m   10.1.0.52       k8s-ctrl      <none>           <none>
    kube-system      ck-storage-rawfile-csi-node-9wvgv     4/4     Running   0          81m   10.1.2.152      k8s-worker2   <none>           <none>
    kube-system      ck-storage-rawfile-csi-node-k45cl     4/4     Running   0          81m   10.1.1.234      k8s-worker1   <none>           <none>
    kube-system      ck-storage-rawfile-csi-node-zxjcv     4/4     Running   0          91m   10.1.0.139      k8s-ctrl      <none>           <none>
    kube-system      coredns-c4fd9db5c-t5f84               1/1     Running   0          79m   10.1.2.87       k8s-worker2   <none>           <none>
    kube-system      coredns-c4fd9db5c-ww2bj               1/1     Running   0          79m   10.1.0.112      k8s-ctrl      <none>           <none>
    kube-system      k8sd-proxy-5kg49                      1/1     Running   0          80m   10.1.1.138      k8s-worker1   <none>           <none>
    kube-system      k8sd-proxy-7g46h                      1/1     Running   0          80m   10.1.2.91       k8s-worker2   <none>           <none>
    kube-system      k8sd-proxy-lwgnw                      1/1     Running   0          90m   10.1.0.138      k8s-ctrl      <none>           <none>
    kube-system      metrics-server-575579b55b-vnkhg       1/1     Running   0          91m   10.1.0.8        k8s-ctrl      <none>           <none>
    metallb-system   metallb-controller-7c447fcdf9-x2625   1/1     Running   0          91m   10.1.0.250      k8s-ctrl      <none>           <none>
    metallb-system   metallb-speaker-8sqg7                 1/1     Running   0          90m   10.107.242.62   k8s-ctrl      <none>           <none>
    metallb-system   metallb-speaker-h4p4v                 1/1     Running   0          80m   10.107.242.64   k8s-worker2   <none>           <none>
    metallb-system   metallb-speaker-rwz22                 1/1     Running   0          80m   10.107.242.63   k8s-worker1   <none>           <none>
    ```

A kubeconfig file can define multiple clusters, users, and contexts, allowing users to switch between clusters. For more
information about managing multiple cluster contexts, see the
[Kubernetes multi-cluster access documentation](https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters).

!!! note "Kubeconfig terminology"
    `Kubeconfig` is a generic term for a file that configures access to a cluster. The file does not need to be named
    `kubeconfig`.

For instructions on installing `kubectl` on other systems, see the
[Kubernetes tools installation guide](https://kubernetes.io/docs/tasks/tools/).

For complete command documentation, see the
[`kubectl` reference](https://kubernetes.io/docs/reference/kubectl/).

Also, let's add command autocompletion for `kubectl`:

```bash
# Enable kubectl command completion.
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Make the kubectl completion file readable.
sudo chmod a+r /etc/bash_completion.d/kubectl
```
??? example "Expected result"
    ```text
    No output.
    ```

Exit and reconnect to the outer GCE lab VM so the new shell loads kubectl completion:

```bash
# Log out of the lab machine.
exit
```
??? example "Expected result"
    ```shell
    logout
    Connection to 34.89.137.65 closed.
    ```

```bash
# Reconnect to the lab machine.
ssh ubuntu@<public IP address of your lab>
```
??? example "Expected result"
    ```shell
    ubuntu@radumoisan:~$
    ```

Query the cluster:

```bash
# Select the deployed cluster kubeconfig.
export KUBECONFIG=~/.kube/myk8scluster_config
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Query cluster information.
kubectl cluster-info
```
??? example "Expected result"
    ```text
    Kubernetes control plane is running at https://myk8scluster-1d008f.maas:6443
    CoreDNS is running at https://myk8scluster-1d008f.maas:6443/api/v1/namespaces/kube-system/services/coredns:udp-53/proxy

    To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
    ```

Query the API server's verbose readiness endpoint to check its dependencies, including etcd:

```bash
# Check Kubernetes component readiness.
kubectl get --raw='/readyz?verbose'
```
??? example "Expected result"
    ```text
    [+]ping ok
    [+]log ok
    [+]etcd ok
    [+]etcd-readiness ok
    [+]informer-sync ok
    [+]poststarthook/start-apiserver-admission-initializer ok
    [+]poststarthook/generic-apiserver-start-informers ok
    [+]poststarthook/priority-and-fairness-config-consumer ok
    [+]poststarthook/priority-and-fairness-filter ok
    [+]poststarthook/storage-object-count-tracker-hook ok
    [+]poststarthook/start-apiextensions-informers ok
    [+]poststarthook/start-apiextensions-controllers ok
    [+]poststarthook/crd-informer-synced ok
    [+]poststarthook/start-system-namespaces-controller ok
    [+]poststarthook/start-cluster-authentication-info-controller ok
    [+]poststarthook/start-kube-apiserver-identity-lease-controller ok
    [+]poststarthook/start-kube-apiserver-identity-lease-garbage-collector ok
    [+]poststarthook/start-legacy-token-tracking-controller ok
    [+]poststarthook/start-service-ip-repair-controllers ok
    [+]poststarthook/rbac/bootstrap-roles ok
    [+]poststarthook/scheduling/bootstrap-system-priority-classes ok
    [+]poststarthook/priority-and-fairness-config-producer ok
    [+]poststarthook/bootstrap-controller ok
    [+]poststarthook/start-kubernetes-service-cidr-controller ok
    [+]poststarthook/aggregator-reload-proxy-client-cert ok
    [+]poststarthook/start-kube-aggregator-informers ok
    [+]poststarthook/apiservice-status-local-available-controller ok
    [+]poststarthook/apiservice-status-remote-available-controller ok
    [+]poststarthook/apiservice-registration-controller ok
    [+]poststarthook/apiservice-discovery-controller ok
    [+]poststarthook/kube-apiserver-autoregistration ok
    [+]autoregister-completion ok
    [+]poststarthook/apiservice-openapi-controller ok
    [+]poststarthook/apiservice-openapiv3-controller ok
    [+]shutdown ok
    readyz check passed
    ```

A Kubernetes node is a machine that runs the `kubelet`. This cluster has two worker nodes and one control plane node that also runs workloads; more nodes can be added at any time:

```bash
# List deployed cluster nodes.
kubectl get nodes
```
??? example "Expected result"
    ```text
    NAME          STATUS   ROLES                  AGE   VERSION
    k8s-ctrl      Ready    control-plane,worker   123m   v1.35.7
    k8s-worker1   Ready    worker                 113m   v1.35.7
    k8s-worker2   Ready    worker                 113m   v1.35.7
    ```

You can get even more detailed information by running `kubectl get nodes -o wide`.

Additionally, check a specific node status, CPU and memory data, system information:

```bash
# Describe a specific node.
kubectl describe node <node_name>
```
??? example "Expected result"
    ```text
    Name:               k8s-ctrl
    Roles:              control-plane,worker
    Taints:             <none>
    Unschedulable:      false
      Ready                True    Tue, 08 Sep 2026 12:02:22 +0000   Tue, 08 Sep 2026 09:58:19 +0000   KubeletReady                 kubelet is posting ready status
      InternalIP:  10.107.242.62
      cpu:                4
      memory:             8110572Ki
      OS Image:                   Ubuntu 24.04.4 LTS
      Container Runtime Version:  containerd://2.1.5
      Kubelet Version:            v1.35.7
    Events:             <none>
    ```

We can check how much resources are consumed (current resource usage) on each node:

```bash
# Show current node resource usage.
kubectl top nodes
```
??? example "Expected result"
    ```text
    NAME          CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)
    k8s-ctrl      225m         5%       1731Mi          22%
    k8s-worker1   90m          2%       1000Mi          12%
    k8s-worker2   88m          2%       1024Mi          13%
    ```

Resource utilization per pod can also be inspected. You may get an error in the beginning, don't worry,
the metrics take some time to be collected, try again in a minute:

```bash
# Show current pod resource usage.
kubectl top pods --all-namespaces
```
??? example "Expected result"
    ```text
    NAMESPACE        NAME                                  CPU(cores)   MEMORY(bytes)
    kube-system      cilium-2k597                          79m          201Mi
    kube-system      cilium-lxtbw                          77m          186Mi
    kube-system      cilium-operator-77968f785f-gpmlz      9m           36Mi
    kube-system      cilium-z74j9                          77m          195Mi
    kube-system      ck-storage-rawfile-csi-controller-0   6m           42Mi
    kube-system      ck-storage-rawfile-csi-node-9wvgv     11m          69Mi
    kube-system      ck-storage-rawfile-csi-node-k45cl     10m          70Mi
    kube-system      ck-storage-rawfile-csi-node-zxjcv     9m           70Mi
    kube-system      coredns-c4fd9db5c-t5f84               3m           16Mi
    kube-system      coredns-c4fd9db5c-ww2bj               3m           17Mi
    kube-system      k8sd-proxy-5kg49                      0m           0Mi
    kube-system      k8sd-proxy-7g46h                      0m           0Mi
    kube-system      k8sd-proxy-lwgnw                      0m           0Mi
    kube-system      metrics-server-575579b55b-vnkhg       6m           27Mi
    metallb-system   metallb-controller-7c447fcdf9-x2625   4m           23Mi
    metallb-system   metallb-speaker-8sqg7                 10m          20Mi
    metallb-system   metallb-speaker-h4p4v                 11m          19Mi
    metallb-system   metallb-speaker-rwz22                 10m          19Mi
    ```

![bundle](assets/k8s_architecture.png)

## :material-book-open-page-variant-outline: 1.3 Pods and namespaces

A Pod is Kubernetes' smallest deployable unit. It contains one or more containers that share networking and can share declared volumes.

Containers within a Pod share an IP address and port space and can communicate over `localhost`. Containers in different Pods have distinct IP addresses and communicate over the network.

Using pods, applications can be designed in a highly distributed manner. Microservice architectures are common for
applications that run on Kubernetes.

Pods are ephemeral and should be treated as replaceable. A standalone Pod does not provide replica management or application high availability; controllers such as Deployments provide these capabilities.

List the pods:

```bash
# List all pods.
kubectl get pods -o wide --all-namespaces
```
??? example "Expected result"
    ```text
    NAMESPACE        NAME                                  READY   STATUS    RESTARTS   AGE    IP              NODE          NOMINATED NODE   READINESS GATES
    kube-system      cilium-2k597                          1/1     Running   0          137m   10.107.242.62   k8s-ctrl      <none>           <none>
    kube-system      cilium-lxtbw                          1/1     Running   0          127m   10.107.242.63   k8s-worker1   <none>           <none>
    kube-system      cilium-operator-77968f785f-gpmlz      1/1     Running   0          137m   10.107.242.62   k8s-ctrl      <none>           <none>
    kube-system      cilium-z74j9                          1/1     Running   0          127m   10.107.242.64   k8s-worker2   <none>           <none>
    kube-system      ck-storage-rawfile-csi-controller-0   2/2     Running   0          138m   10.1.0.52       k8s-ctrl      <none>           <none>
    kube-system      ck-storage-rawfile-csi-node-9wvgv     4/4     Running   0          127m   10.1.2.152      k8s-worker2   <none>           <none>
    kube-system      ck-storage-rawfile-csi-node-k45cl     4/4     Running   0          127m   10.1.1.234      k8s-worker1   <none>           <none>
    kube-system      ck-storage-rawfile-csi-node-zxjcv     4/4     Running   0          138m   10.1.0.139      k8s-ctrl      <none>           <none>
    kube-system      coredns-c4fd9db5c-t5f84               1/1     Running   0          125m   10.1.2.87       k8s-worker2   <none>           <none>
    kube-system      coredns-c4fd9db5c-ww2bj               1/1     Running   0          125m   10.1.0.112      k8s-ctrl      <none>           <none>
    kube-system      k8sd-proxy-5kg49                      1/1     Running   0          126m   10.1.1.138      k8s-worker1   <none>           <none>
    kube-system      k8sd-proxy-7g46h                      1/1     Running   0          126m   10.1.2.91       k8s-worker2   <none>           <none>
    kube-system      k8sd-proxy-lwgnw                      1/1     Running   0          137m   10.1.0.138      k8s-ctrl      <none>           <none>
    kube-system      metrics-server-575579b55b-vnkhg       1/1     Running   0          138m   10.1.0.8        k8s-ctrl      <none>           <none>
    metallb-system   metallb-controller-7c447fcdf9-x2625   1/1     Running   0          138m   10.1.0.250      k8s-ctrl      <none>           <none>
    metallb-system   metallb-speaker-8sqg7                 1/1     Running   0          137m   10.107.242.62   k8s-ctrl      <none>           <none>
    metallb-system   metallb-speaker-h4p4v                 1/1     Running   0          126m   10.107.242.64   k8s-worker2   <none>           <none>
    metallb-system   metallb-speaker-rwz22                 1/1     Running   0          126m   10.107.242.63   k8s-worker1   <none>           <none>
    ```

You may see multiple Pods because many cluster add-ons run in the `kube-system` namespace. Namespaces provide logical scopes for projects and resources. For example, the development team can work in a `dev` namespace, while the support team works in a `support` namespace. Resources in one namespace are distinct from resources in another, but namespaces do not provide network or security isolation by themselves.

Clusters normally include the `default` and `kube-system` namespaces, among others. List all namespaces:

```bash
# List all namespaces.
kubectl get namespaces
```
??? example "Expected result"
    ```text
    NAME              STATUS   AGE
    cilium-secrets    Active   142m
    default           Active   142m
    kube-node-lease   Active   142m
    kube-public       Active   142m
    kube-system       Active   142m
    metallb-system    Active   142m
    ```

## :material-book-open-page-variant-outline: 1.4 Work with pods and volumes

Kubernetes resources, including Pods, are represented by objects that declare a desired state. Kubernetes continually works to match the actual state to the desired state. For a standalone Pod, the `kubelet` restarts failed containers according to the Pod's `restartPolicy`. Controllers such as Deployments create replacement Pods when necessary.

![bundle](assets/pod1.png)

Take a look at this simple nginx pod definition. The definition is present in a file in `~/resources/nginx-pod.yaml`:

```yaml
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

Create the pod:

```bash
# Select the deployed cluster kubeconfig.
export KUBECONFIG=~/.kube/myk8scluster_config
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Create the nginx pod.
kubectl create -f ~/resources/nginx-pod.yaml
```
??? example "Expected result"
    ```text
    pod/nginx created
    ```

List and describe the newly created Pod. Review its status, configuration, and events, and ask the trainer about anything you do not understand:

```bash
# List the nginx pod.
kubectl get pods -o wide
```
??? example "Expected result"
    ```text
    NAME    READY   STATUS    RESTARTS   AGE   IP           NODE          NOMINATED NODE   READINESS GATES
    nginx   1/1     Running   0          58s   10.1.1.204   k8s-worker1   <none>           <none>
    ```

```bash
# Describe the nginx pod.
kubectl describe pod nginx
```
??? example "Expected result"
    ```text
    Name:             nginx
    Namespace:        default
    Node:             k8s-worker1/10.107.242.63
    Labels:           app=nginx
    Status:           Running
    IP:               10.1.1.204
        Image:          nginx:latest
        State:          Running
        Ready:          True
        Restart Count:  0
    ```

Delete the pod:

```bash
# Delete the nginx pod.
kubectl delete pod nginx
```
??? example "Expected result"
    ```text
    pod "nginx" deleted from default namespace
    ```

Container writable layers are ephemeral. Volumes allow containers in a Pod to share data and can have different lifecycles. Data that must outlive a Pod generally requires a PersistentVolume backed by suitable storage.

This lab uses these local volume types:

`emptyDir` is created when a Pod is assigned to a node and lasts for the lifetime of that Pod on that node. It is initially empty and uses storage provided by the node.

`hostPath` mounts an existing path, such as `/var/logs`, from the node's file system. It ties the Pod to that node and has security implications, so use it with care.

Here is an example of how to define an `emptyDir` volume in a Pod:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: redis
spec:
  containers:
  - name: redis
    image: redis
    volumeMounts:
    - name: redis-storage
      mountPath: /data/redis
  volumes:
  - name: redis-storage
    emptyDir: {}
```

Create the Pod from `~/resources/redis-volume-pod.yaml`, then describe it to inspect the attached volumes. Delete the Pod when finished.

```bash
# Select the deployed cluster kubeconfig.
export KUBECONFIG=~/.kube/myk8scluster_config
```
??? example "Expected result"
    ```text
    No output.
    ```

```bash
# Create the redis volume pod.
kubectl create -f ~/resources/redis-volume-pod.yaml
```
??? example "Expected result"
    ```text
    pod/redis created
    ```

```bash
# Describe the redis pod.
kubectl describe pod redis
```
??? example "Expected result"
    ```text
    Name:             redis
    Namespace:        default
    Node:             k8s-worker1/10.107.242.63
    Status:           Running
    IP:               10.1.1.69
          /data/redis from redis-storage (rw)
      redis-storage:
        Type:       EmptyDir (a temporary directory that shares a pod's lifetime)
    ```

A Pod can also contain multiple containers. Display the example definition:

```bash
# Display the multi-container pod definition.
cat ~/resources/multi-container-pod.yaml
```
??? example "Expected result"
    ```yaml
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

The `debian-container` writes the index file to a shared volume, while `nginx-container` serves that file to clients.

Finally, delete the pod:

```bash
# Delete the redis pod.
kubectl delete pod redis
```
??? example "Expected result"
    ```text
    pod "redis" deleted from default namespace
    ```

![bundle](assets/pod2.png)
