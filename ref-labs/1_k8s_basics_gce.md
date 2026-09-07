# 1. Kubernetes Basics !heading

Kubernetes is an open-source infrastructure for automating deployment, scaling, and management of containerized
applications. Originally built by Google, it is currently maintained by the Cloud Native Computing Foundation.

The upstream Kubernetes version is comprised of:
  * control plane components:
    * etcd distributed key-value store
    * the API server
    * the Scheduler
    * the Controller Manager
  * worker nodes components:
    * the kubelet
    * the service proxy called kube-proxy
    * the container runtime - containerd

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

We will be using `MAAS` and `CAPI` to deploy and manage a Kubernetes cluster on MAAS cloud provider using LXD VMs.

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

Then, let's disable IPv6 system wide:

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

Now that both LXD and MAAS are installed, let's do the initial MAAS setup and integrate it with LXD. Your local host will be registered as a LXD host inside MAAS:

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

LXD has it's own network and but DNS and DHCP will be handled by MAAS. To configure MAAS to work with LXD's network, run:

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

VMs are created and commissioned automatically. Before we can proceed, we need to tag those machines:

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

Next, let's deploy an operating system to your management machine. On `cluster-ctrl` we'll be running our Kubernetes management cluster that can further provision other clusters.

```bash
CLUSTERCTL_SYSTEM_ID=$(maas "$PROFILE" machines read \
  | jq -r '.[] | select(.tag_names[] == "cluster-ctrl") | .system_id')

maas "$PROFILE" machine deploy "$CLUSTERCTL_SYSTEM_ID" distro_series="ubuntu/noble"
```

After the machine gets deployed with Ubuntu Noble (24.04), we will need to install the necessary tools to have Cluster API up and running:

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

Last step before actually creating the cluster is to generate a Cluster API manifest that will be used by plain `kubectl` to create our cluster:

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

Now that the cluster template is generated, we can apply it to create the cluster:

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

After the cluster is deployed you may assume control over the Kubernetes
cluster from any k8s node.

`kubectl` is the command line tool for Kubernetes. It controls the Kubernetes cluster manager.

`config` are files used to organize information about clusters, users, namespaces, and authentication mechanisms.
The `kubectl` command-line tool uses `config` files to find the information it needs to choose a cluster and communicate
with the API server of a cluster. By default, the config files are created on the `k8s` nodes. Create
the `kubectl` config directory and copy the cluster `config` file to the default location:

```bash
mkdir -p ~/.kube && cd ~/.kube
```

Once the cluster is done being installed, you'll need the configuration file `kubectl` uses to connect to the cluster. To get it:

```bash
ssh $CLUSTERCTL_IP
clusterctl get kubeconfig myk8scluster > ~/.kube/myk8scluster_config
exit
```

`myk8scluster_config` file gets created inside `.kube` folder. Also, you'll need the `kubectl` CLI installed, so:

```bash
sudo snap install kubectl --channel=1.35/stable --classic
```

Then, check `kubectl` has access to the cluster:

```bash
export KUBECONFIG=~/.kube/myk8scluster_config
kubectl get nodes -A -o wide
kubectl get pods -A -o wide
exit
```

Now that config files have been tested, they can be copied on your lab environment:

```bash
mkdir -p ~/.kube
scp $CLUSTERCTL_IP:~/.kube/myk8scluster_config ~/.kube/
scp $CLUSTERCTL_IP:~/.kube/config ~/.kube/
sudo snap install kubectl --channel=1.35/stable --classic
```

Once you have both config files and `kubectl` client, you can inspect both management and deployed clusters.

```bash
# inspect management cluster
kubectl get nodes

# output
NAME           STATUS   ROLES                  AGE   VERSION
cluster-ctrl   Ready    control-plane,worker   54m   v1.35.7
```

Also, you can inspect the deployed cluster:

```bash
# inspect deployed cluster
export KUBECONFIG=~/.kube/myk8scluster_config
kubectl get nodes

# output
NAME          STATUS   ROLES                  AGE   VERSION
k8s-ctrl      Ready    control-plane,worker   45m   v1.35.7
k8s-worker1   Ready    worker                 37m   v1.35.7
k8s-worker2   Ready    worker                 37m   v1.35.7
```

Multiple clusters can be managed with the help of `config` file. Users can switch between different clusters. For more information on
this please visit:

https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters


**Note**: A file that is used to configure access to a cluster is also sometimes called a `kubeconfig` file. This is just a
generic way of referring to configuration files. It does not mean that there is a file named `kubeconfig`.


For information on how to install `kubectl` on other systems, please visit the links:

https://kubernetes.io/docs/tasks/tools/


Good documentation on `kubectl` can be found here:

https://kubernetes.io/docs/reference/kubectl/

Also, let's add command autocompletion for `kubectl`:

```bash
kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
sudo chmod a+r /etc/bash_completion.d/kubectl
```

After that, let's logout and re-login:

```bash
exit

ssh ubuntu@<public IP address of your lab>
```

Query the cluster:

```bash
export KUBECONFIG=~/.kube/myk8scluster_config
kubectl cluster-info

#output
Kubernetes control plane is running at https://myk8scluster-d02f62.maas:6443
CoreDNS is running at https://myk8scluster-d02f62.maas:6443/api/v1/namespaces/kube-system/services/coredns:udp-53/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.
```

Kubernetes components like the scheduler or the distributed database can be checked to ensure cluster functionality:

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

In Kubernetes terminology, the workers which run the `kubelet` service are called `nodes`. This cluster is modeled
with two purely worker `nodes` and one control plane `node` that also runs `kubelet`, but more can be added at any time:

```bash
kubectl get nodes

# output
NAME          STATUS   ROLES                  AGE   VERSION
k8s-ctrl      Ready    control-plane,worker   50m   v1.36.4
k8s-worker1   Ready    worker                 42m   v1.36.4
k8s-worker2   Ready    worker                 42m   v1.36.4
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

A `pod` is smallest deployment unit that a user can create. It is an encapsulation of one or more containers
with a shared network and storage scope. The shared context of a pod is implemented with Linux namespaces,
cgroups, among others, the same used for Docker or Containerd containers isolation.

Containers within a pod share an IP address and a port space, of the pod. They communicate with each other inside pods
using standard IPC. Containers in different pods have distinct IPs and communicate on that IP.

Using pods, applications can be designed in a highly distributed manner. Microservice architectures are common for
applications that run on Kubernetes.

Pods are considerate to have ephemeral life and should be treated like cattle. Another important mention is that pods alone
do not offer application high availability. For that, kubernetes has mechanism that make use of pods, but more of that later.

List the pods:

```bash
kubectl get pods -o wide --all-namespaces
```

Multiple pods can be seen, buy why? Kubernetes itself runs it's services (api server, dashboard, etc.) inside
pods. Those pods run in a special namespace called `kube-system`, a system reserved namespace. `Namespaces` are a way
to create scopes for different projects. For example, the development team can work in their `dev` namespace, and the
support team can work in their `support` namespace. The two can be considered different projects, resources are not shared
and the two namespaces are isolated from each other.

By default, a `default` namespace is created along with the kube-system one. List all the namespaces:

```bash
kubectl get namespaces
```

## 1.4 Work with pods and volumes

Kubernetes treats everything as objects, including pods, and each object has a definition. A definition is a declaration of
a desired state. Kubernetes ensures that the current state matches the desired state. For example, when you create a Pod and
declare that the containers in it to be running. If the containers are not running due to an app failure, kubernetes will
recreate the pod in order to drive the pod to desired state.

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

List the pods and describe the newly created pod, try to understand what is in there and talk with the trainer on the bits
that you do not understand:

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

That's good for a simple web server, but what if persistent storage is needed? The container file system only lives as
long as the container does. Volumes should be used for any persistent storage needs.

There are many volume types available, with some being cloud platform specific (e.g. `azureDisk`, `gcePersistentDisk`,
`azureDisk`, `awsElasticBlockStore`). The standard types include:

`EmptyDir`: is first created when a Pod is assigned to a Node, and exists as long as that Pod is running on that node.
It is initially empty and is stored on whatever medium is backing the node - that might be disk or HDD/SSD or network storage,
depending on your environment.

`HostPath`: Mounts an existing directory on the node’s file system. For example `/var/logs`.


Here is an example of how volumes will look like in a pod definition:

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

Create the pod in `~/resources/redis-volume-pod.yaml` and run the `describe pod` command on it afterwards to see
the volumes attached. Delete the pod once done.

```bash
export KUBECONFIG=~/.kube/myk8scluster_config
kubectl create -f ~/resources/redis-volume-pod.yaml
```

```bash
kubectl describe pod redis
```

Multiple containers can also exist in one pod. Take a look at this example:

```bash
cat ~/resources/multi-container-pod.yaml
```

There are two containers, `nginx-container` and `debian-container`. The `debian-container` is responsible for generating the index file, while `nginx-container` serves it to the clients.

Finally, delete the pod:

```bash
kubectl delete pod redis
```

![bundle](assets/pod2.png)
