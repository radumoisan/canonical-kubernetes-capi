# 1. Kubernetes Basics !heading

Kubernetes is an open-source infrastructure for automating deployment, scaling, and management of containerized
applications. Originally built by Google, it is currently maintained by the Cloud Native Computing Foundation.

A Kubernetes cluster includes these primary components:
  * control plane components:
    * etcd distributed key-value store
    * the API server
    * the scheduler
    * the controller manager
  * node components:
    * the kubelet
    * the kube-proxy network proxy
    * a container runtime, such as containerd

## Canonical Kubernetes

The official distribution of Kubernetes on Ubuntu delivers a pure 'upstream' version of Kubernetes for organizations to
use privately, plus a few more features like key distribution and overlay networking. We work directly with Google to
align with Google's GKE offering.

Like Ubuntu itself, Canonical Kubernetes is free to use, and Canonical backs it up with enterprise support, consulting,
and management services. Canonical makes it secure and easy to deploy, operate, and upgrade.

Canonical Kubernetes works on AWS, Google Cloud, Azure and Oracle Cloud as well as private infrastructure from bare-metal
racks to VMware and OpenStack. Ubuntu is the most widely used platform for container operations, and Canonical offers the
largest ecosystem of Kubernetes partners, solutions and integration options.


## 1.1 Deploy Canonical Kubernetes

This lab uses MAAS and Cluster API (CAPI) to deploy and manage a Kubernetes cluster on MAAS using LXD VMs.

First, install MAAS and LXD:

```bash
sudo snap install maas --channel=3.6/stable
sudo snap install maas-test-db --channel=3.6/stable
sudo snap install lxd --channel=5.21/stable
```

Next, initialize LXD and disable IPv6:

```bash
sudo lxd init --auto
sudo lxc network set lxdbr0 ipv6.address none
sudo lxc network unset lxdbr0 ipv6.nat
sudo lxc network set lxdbr0 dns.mode=none
sudo lxc network set lxdbr0 ipv4.dhcp=false
sudo lxc config set core.https_address 127.0.0.1:8443
```

Then, disable IPv6 system-wide:

```bash
sudo tee -a /etc/sysctl.conf <<EOF
net.ipv6.conf.all.disable_ipv6 = 1
net.ipv6.conf.default.disable_ipv6 = 1
EOF

sudo sysctl -p

sudo sysctl -w net.ipv6.conf.all.disable_ipv6=1
sudo sysctl -w net.ipv6.conf.default.disable_ipv6=1
```

Next, let's also initialize MAAS:

```bash
IP_ADDRESS=$(hostname -I | awk '{print $1}')
sudo maas init region+rack --database-uri maas-test-db:/// --maas-url http://${IP_ADDRESS}:5240/MAAS
```

Now that both LXD and MAAS are installed, complete the initial MAAS setup and integrate it with LXD. The local LXD instance will be registered in MAAS as a VM host:

```bash
sudo maas createadmin --username=admin --password=ubuntu --email=admin@example.com
sudo maas apikey --username=admin > ~/maas-apikey

maas login deployprofile http://${IP_ADDRESS}:5240/MAAS - < ~/maas-apikey
maas deployprofile boot-resources import

maas deployprofile vm-hosts create type=lxd power_address=https://127.0.0.1:8443 project=default name=localhost
maas deployprofile vm-host parameters 1 | jq -r '.certificate' > /tmp/maas.crt

sudo lxc config trust add /tmp/maas.crt
maas deployprofile vm-host refresh 1

ssh-keygen -t rsa -N "" -q -f ~/.ssh/id_rsa
maas deployprofile sshkeys create key="`cat ~/.ssh/id_rsa.pub`"
```

LXD has its own network, but MAAS will handle DNS and DHCP. To configure MAAS to work with LXD's network, run:

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

# Get subnet ID from MAAS
SUBNET_ID=$(maas "$PROFILE" subnets read \
  | jq -r ".[] | select(.cidr==\"$CIDR\") | .id")

if [[ -z "$SUBNET_ID" ]]; then
  echo "ERROR: No subnet found for CIDR $CIDR"
  exit 1
fi

echo "Subnet ID: $SUBNET_ID"

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

# Create dynamic range
maas "$PROFILE" ipranges create \
  type=dynamic \
  start_ip="$DYN_START" \
  end_ip="$DYN_END" \
  comment="Dynamic range from script"

# Set gateway and DNS on subnet
maas "$PROFILE" subnet update "$SUBNET_ID" \
  gateway_ip="$BASE_IP" \
  dns_servers="1.1.1.1 1.0.0.1"

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

maas "$PROFILE" maas set-config name=upstream_dns value="1.1.1.1"

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

Finally, let's create the VMs required by our setup:


```bash
maas deployprofile vm-host update 1 cpu_over_commit_ratio=2
maas deployprofile vm-host compose 1 cores=2 memory=4096 storage="1:40(default)" hostname=cluster-ctrl architecture="amd64/generic" interfaces=eth0:subnet=$SUBNET_ID
maas deployprofile vm-host compose 1 cores=4 memory=8192 storage="1:80(default)" hostname=k8s-ctrl architecture="amd64/generic" interfaces=eth0:subnet=$SUBNET_ID
maas deployprofile vm-host compose 1 cores=4 memory=8192 storage="1:80(default)" hostname=k8s-worker1 architecture="amd64/generic" interfaces=eth0:subnet=$SUBNET_ID
maas deployprofile vm-host compose 1 cores=4 memory=8192 storage="1:80(default)" hostname=k8s-worker2 architecture="amd64/generic" interfaces=eth0:subnet=$SUBNET_ID
```

VMs are created and commissioned automatically. Before proceeding, tag these machines:

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

    # Create tag (ignore error if it already exists)
    maas "$PROFILE" tags create name="$TAG" 2>/dev/null || true

    # Assign tag to this machine
    maas "$PROFILE" tag update-nodes "$TAG" add="$ID"
done
```

Next, deploy an operating system to the management machine. The Kubernetes management cluster will run on `cluster-ctrl` and provision workload clusters.

```bash
CLUSTERCTL_SYSTEM_ID=$(maas "$PROFILE" machines read \
  | jq -r '.[] | select(.tag_names[] == "cluster-ctrl") | .system_id')

maas "$PROFILE" machine deploy "$CLUSTERCTL_SYSTEM_ID" distro_series="ubuntu/noble"
```

After the machine is deployed with Ubuntu Noble (24.04), install and bootstrap Canonical Kubernetes as the management cluster, then install `clusterctl`:

**Note**: The `k8s` command is the administration CLI installed by the Canonical Kubernetes snap. It manages the local cluster through commands such as `bootstrap`, `status`, and `config`.

`k8s kubectl` runs the kubectl client bundled with Canonical Kubernetes and connects to the local management cluster. Plain `kubectl`, introduced later, connects to the cluster selected through `KUBECONFIG`.

```bash
CLUSTERCTL_IP=$(maas "$PROFILE" machine read "$CLUSTERCTL_SYSTEM_ID" \
  | jq -r '.interface_set[].links[].ip_address // empty' \
  | head -n1)

ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$CLUSTERCTL_IP "sudo snap install k8s --classic --channel=1.35-classic/stable"
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$CLUSTERCTL_IP "sudo k8s bootstrap && sudo k8s status --wait-ready"
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$CLUSTERCTL_IP "mkdir -p ~/.kube/ && sudo k8s config > ~/.kube/config"
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$CLUSTERCTL_IP "curl -L https://github.com/kubernetes-sigs/cluster-api/releases/download/v1.13.5/clusterctl-linux-amd64 -o clusterctl"
ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=no ubuntu@$CLUSTERCTL_IP "sudo install -o root -g root -m 0755 clusterctl /usr/local/bin/clusterctl"
```

Next, initialize the CAPI providers and generate the resource manifest for the workload cluster:

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

Apply the generated manifest to the management cluster. The CAPI controllers will reconcile these resources and provision the workload cluster:

```bash
ssh $CLUSTERCTL_IP
cd cluster-api-k8s
sudo k8s kubectl apply -f cluster.yaml

# Verify status with:
watch "sudo k8s kubectl get clusters; sudo k8s kubectl get machines"

# and
watch clusterctl describe cluster myk8scluster
exit
```


## 1.2 Interacting with the cluster and observability

Continue on the outer GCE lab VM. It can reach the management and workload cluster API endpoints over the MAAS-managed LXD network.

`kubectl` is the Kubernetes command-line client. A kubeconfig file contains the cluster endpoint, user credentials, context, and optional namespace that `kubectl` uses.

**Execution context**: Unless a step explicitly says to run on `cluster-ctrl`, run every command in this section on the outer GCE lab VM. The management kubeconfig is `~/.kube/config`. The workload kubeconfig is `~/.kube/myk8scluster_config`.

Create the kubeconfig directory on the outer lab VM:

```bash
mkdir -p ~/.kube
```

Connect to `cluster-ctrl`, where `clusterctl` and the management kubeconfig are installed:

```bash
ssh $CLUSTERCTL_IP
```

On `cluster-ctrl`, generate the workload-cluster kubeconfig:

```bash
clusterctl get kubeconfig myk8scluster > ~/.kube/myk8scluster_config
```

Return to the outer lab VM:

```bash
exit
```

The two kubeconfig files currently reside on `cluster-ctrl`. Copy them to the outer lab VM before running plain `kubectl` there:

```bash
scp $CLUSTERCTL_IP:~/.kube/myk8scluster_config ~/.kube/
scp $CLUSTERCTL_IP:~/.kube/config ~/.kube/
```

Install `kubectl` once on the outer lab VM:

```bash
sudo snap install kubectl --channel=1.35/stable --classic
```

Select the management kubeconfig and verify the management cluster:

```bash
export KUBECONFIG=~/.kube/config
kubectl get nodes
```

**Expected result:**

```text
NAME           STATUS   ROLES                  AGE   VERSION
cluster-ctrl   Ready    control-plane,worker   54m   v1.35.7
```

Select the workload kubeconfig and verify the workload cluster:

```bash
export KUBECONFIG=~/.kube/myk8scluster_config
kubectl get nodes
```

**Expected result:**

```text
NAME          STATUS   ROLES                  AGE   VERSION
k8s-ctrl      Ready    control-plane,worker   45m   v1.35.7
k8s-worker1   Ready    worker                 37m   v1.35.7
k8s-worker2   Ready    worker                 37m   v1.35.7
```

List all workload-cluster Pods:

```bash
kubectl get pods -A -o wide
```

A kubeconfig file can define multiple clusters, users, and contexts, allowing users to switch between clusters. For more information, see:

https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters


**Note**: `Kubeconfig` is a generic term for a file that configures access to a cluster. The file does not need to be named `kubeconfig`.


For information on how to install `kubectl` on other systems, please visit the links:

https://kubernetes.io/docs/tasks/tools/


Good documentation on `kubectl` can be found here:

https://kubernetes.io/docs/reference/kubectl/

Also, let's add command autocompletion for `kubectl`:

```bash
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
sudo chmod a+r /etc/bash_completion.d/kubectl
```

Exit and reconnect to the outer GCE lab VM so the new shell loads kubectl completion:

```bash
exit

ssh ubuntu@<public IP address of your lab>
```

Query the cluster:

```bash
export KUBECONFIG=~/.kube/myk8scluster_config
kubectl cluster-info

#output
Kubernetes control plane is running at https://<generated-control-plane-hostname>.maas:6443
CoreDNS is running at https://<generated-control-plane-hostname>.maas:6443/api/v1/namespaces/kube-system/services/coredns:udp-53/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

Query the API server's verbose readiness endpoint to check its dependencies, including etcd:

```bash
kubectl get --raw='/readyz?verbose'

# output
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
[+]poststarthook/peer-endpoint-reconciler-controller ok
[+]poststarthook/start-cluster-authentication-info-controller ok
[+]poststarthook/start-kube-apiserver-identity-lease-controller ok
[+]poststarthook/start-kube-apiserver-identity-lease-garbage-collector ok
[+]poststarthook/storage-readiness ok
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
kubectl get nodes

# output
NAME          STATUS   ROLES                  AGE   VERSION
k8s-ctrl      Ready    control-plane,worker   50m   v1.35.7
k8s-worker1   Ready    worker                 42m   v1.35.7
k8s-worker2   Ready    worker                 42m   v1.35.7
```

You can get even more detailed information by running `kubectl get nodes -o wide`.

Additionally, check a specific node status, CPU and memory data, system information:

```bash
kubectl describe node <node_name>
```

We can check how much resources are consumed (current resource usage) on each node:

```bash
kubectl top nodes

# output
NAME          CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)
k8s-ctrl      153m         3%       1948Mi          24%
k8s-worker1   89m          2%       1324Mi          16%
k8s-worker2   72m          1%       1147Mi          14%
```

Resource utilization per pod can also be inspected. You may get an error in the beginning, don't worry,
the metrics take some time to be collected, try again in a minute:

```bash
kubectl top pods --all-namespaces
```

![bundle](assets/k8s_architecture.png)


## 1.3 Pods and namespaces

A Pod is Kubernetes' smallest deployable unit. It contains one or more containers that share networking and can share declared volumes.

Containers within a Pod share an IP address and port space and can communicate over `localhost`. Containers in different Pods have distinct IP addresses and communicate over the network.

Using pods, applications can be designed in a highly distributed manner. Microservice architectures are common for
applications that run on Kubernetes.

Pods are ephemeral and should be treated as replaceable. A standalone Pod does not provide replica management or application high availability; controllers such as Deployments provide these capabilities.

List the pods:

```bash
kubectl get pods -o wide --all-namespaces
```

You may see multiple Pods because many cluster add-ons run in the `kube-system` namespace. Namespaces provide logical scopes for projects and resources. For example, the development team can work in a `dev` namespace, while the support team works in a `support` namespace. Resources in one namespace are distinct from resources in another, but namespaces do not provide network or security isolation by themselves.

Clusters normally include the `default` and `kube-system` namespaces, among others. List all namespaces:

```bash
kubectl get namespaces
```

## 1.4 Work with pods and volumes

Kubernetes resources, including Pods, are represented by objects that declare a desired state. Kubernetes continually works to match the actual state to the desired state. For a standalone Pod, the `kubelet` restarts failed containers according to the Pod's `restartPolicy`. Controllers such as Deployments create replacement Pods when necessary.

![bundle](assets/pod1.png)

Take a look at this simple nginx pod definition. The definition is present in a file in `~/resources/nginx-pod.yaml`:

```bash
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
export KUBECONFIG=~/.kube/myk8scluster_config
kubectl create -f ~/resources/nginx-pod.yaml
```

List and describe the newly created Pod. Review its status, configuration, and events, and ask the trainer about anything you do not understand:

```bash
kubectl get pods -o wide
```

```bash
kubectl describe pod nginx
```

Delete the pod:

```bash
kubectl delete pod nginx
```

Container writable layers are ephemeral. Volumes allow containers in a Pod to share data and can have different lifecycles. Data that must outlive a Pod generally requires a PersistentVolume backed by suitable storage.

This lab uses these local volume types:

`emptyDir` is created when a Pod is assigned to a node and lasts for the lifetime of that Pod on that node. It is initially empty and uses storage provided by the node.

`hostPath` mounts an existing path, such as `/var/logs`, from the node's file system. It ties the Pod to that node and has security implications, so use it with care.


Here is an example of how to define an `emptyDir` volume in a Pod:

```bash
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
export KUBECONFIG=~/.kube/myk8scluster_config
kubectl create -f ~/resources/redis-volume-pod.yaml
```

```bash
kubectl describe pod redis
```

A Pod can also contain multiple containers. Display the example definition:

```bash
cat ~/resources/multi-container-pod.yaml
```

The `debian-container` writes the index file to a shared volume, while `nginx-container` serves that file to clients.

Finally, delete the pod:

```bash
kubectl delete pod redis
```

![bundle](assets/pod2.png)
