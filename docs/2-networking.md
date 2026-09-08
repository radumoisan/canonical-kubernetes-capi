# 2. Networking

Select the workload cluster kubeconfig before running this chapter's `kubectl` commands:

```bash
# Select the workload cluster kubeconfig.
export KUBECONFIG=~/.kube/myk8scluster_config
```
??? example "Expected result"
    ```text
    No output.
    ```

Verify that `kubectl` targets the workload cluster:

```bash
# Display the current Kubernetes context.
kubectl config current-context
```
??? example "Expected result"
    ```text
    myk8scluster-admin@myk8scluster
    ```

!!! info ""
    Generated resource names, IP addresses, ports, and ages in expected results come from the validated lab environment
    and may differ in your environment. Use the values reported by your commands.

## :material-book-open-page-variant-outline: 2.1 Exposing apps using Services and Labels

The applications created so far are not exposed outside the cluster. Directly addressing Pods is unreliable for several reasons:

* Pods are ephemeral.
* Kubernetes assigns IP addresses to Pods after they are scheduled, so clients should not rely on addresses known in advance.
* Applications can scale across multiple Pods, and clients should not need to track their addresses or locations.

Kubernetes provides the `Service` resource to give clients a stable way to reach these Pods.

![service](assets/network1.png)

A Service provides a stable access point for a group of Pods. Most Services receive a virtual IP address that remains stable for the lifetime of the Service. Connections to the Service are forwarded to eligible backend Pods, so clients do not need to track individual Pod addresses or locations. Headless and `ExternalName` Services do not use a virtual IP address.

![service](assets/service1.png)

There are four Service types:

* `ClusterIP`: exposes the Service on an internal virtual IP address.
* `NodePort`: exposes the Service on a static port on every node.
* `LoadBalancer`: requests an externally reachable address from the platform's load-balancer implementation.
* `ExternalName`: maps the Service to an external DNS name by returning a CNAME record. It does not configure proxying.

Labels are key-value metadata attached to objects such as Pods. A Service selector identifies the Pods that provide its endpoints.

For example, suppose three Pods running an application have the label `app: nginx`. A Service with the selector `app: nginx` sends traffic to eligible Pods with that label.

![labels and selectors](assets/labels_selectors.png)

The Canonical Kubernetes cluster deployed in this lab uses Cilium for networking and MetalLB to allocate addresses for `LoadBalancer` Services. Configure a MetalLB `IPAddressPool`:

Create a YAML file named `metallb.yaml` with the following content:

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: lb-pool
  namespace: metallb-system
spec:
  addresses:
  - XX.XX.XX.10-XX.XX.XX.40
```

For the validated `/24` LXD bridge network, replace `XX.XX.XX` with the first three octets of the bridge's IPv4 address
shown by:

```bash
# Display the LXD bridge address.
ip add sh dev lxdbr0
```
??? example "Expected result"
    ```text
    3: lxdbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
        link/ether 00:16:3e:47:9e:4b brd ff:ff:ff:ff:ff:ff
        inet 10.107.242.1/24 scope global lxdbr0
           valid_lft forever preferred_lft forever
    ```

In this case, the file should look like:

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

This pool is inside the `.1-.50` range reserved in Chapter 1, so MAAS does not allocate these addresses to cluster machines.

Apply the configuration with:

```bash
# Apply the MetalLB IP address pool.
kubectl apply -f metallb.yaml
```
??? example "Expected result"
    ```text
    ipaddresspool.metallb.io/lb-pool created
    ```

Verify the configuration has been applied with:

```bash
# List MetalLB IP address pools.
kubectl get IPAddressPool -n metallb-system
```
??? example "Expected result"
    ```text
    NAME      AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES
    lb-pool   true          false             ["10.107.242.10-10.107.242.40"]
    ```

```bash
# Describe the MetalLB IP address pool.
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

Also, create a L2Advertisement - `metallb-l2advertisement.yaml`:

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

Apply the configuration with:

```bash
# Apply the MetalLB L2 advertisement.
kubectl apply -f metallb-l2advertisement.yaml
```
??? example "Expected result"
    ```text
    l2advertisement.metallb.io/lb-pool created
    ```

The automatically managed `cilium-ingress` EndpointSlice should have the Service label. Verify it without relying on its generated name:

```bash
# Verify the cilium-ingress endpoint slice Service label.
kubectl get endpointslice -n kube-system \
  -l kubernetes.io/service-name=cilium-ingress \
  --show-labels
```
??? example "Expected result"
    ```text
    NAME                   ADDRESSTYPE   PORTS   ENDPOINTS         AGE     LABELS
    cilium-ingress-qwp8x   IPv4          9999    192.192.192.192   3h28m   app.kubernetes.io/managed-by=Helm,endpointslice.kubernetes.io/managed-by=endpointslicemirroring-controller.k8s.io,kubernetes.io/service-name=cilium-ingress
    ```

Now, let's take a look at the existing services:

```bash
# List services in all namespaces.
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

This output lists Services used by cluster components and applications. Only the `cilium-ingress` Service has the `LoadBalancer` type. A ClusterIP is an internal virtual address implemented by the cluster networking data plane and is normally reachable only from the cluster network. Adding `-o wide` displays each Service selector, when present.

!!! note "Selectors"
    Workload controllers such as Deployments and ReplicaSets also use selectors to associate with Pods.

Redeploy `nginx` with a label. Display `~/resources/nginx-pod.yaml` and note the `labels` field:

```bash
# Display the nginx pod definition.
cat ~/resources/nginx-pod.yaml
```
??? example "Expected result"
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

```bash
# Create the nginx pod.
kubectl create -f ~/resources/nginx-pod.yaml
```
??? example "Expected result"
    ```text
    pod/nginx created
    ```

```bash
# Wait for the nginx pod to become Ready.
kubectl wait --for=condition=Ready pod/nginx --timeout=180s
```
??? example "Expected result"
    ```text
    pod/nginx condition met
    ```

Now it's time to create the Service. The Service definition file should be found under `~/resources/nginx-service.yaml`. Let's
examine the contents and create the Service:

```bash
# Display the nginx service definition.
cat ~/resources/nginx-service.yaml
```
??? example "Expected result"
    ```yaml
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

```bash
# Create the nginx service.
kubectl create -f ~/resources/nginx-service.yaml
```
??? example "Expected result"
    ```text
    service/nginx created
    ```

The service should now be visible:

```bash
# List services with selectors.
kubectl get svc -o wide
```
??? example "Expected result"
    ```text
    NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE     SELECTOR
    kubernetes   ClusterIP   10.152.0.1      <none>        443/TCP    3h32m   <none>
    nginx        ClusterIP   10.152.46.161   <none>        8080/TCP   26s     app=nginx
    ```

The application can now be accessed through the Service from within the cluster, but it is not exposed to external
clients.

The following probes demonstrate internal Service connectivity. External access methods are introduced later in this chapter.

In the default Kubernetes network model, nodes can reach Pods without NAT unless network policies or infrastructure rules restrict that traffic. To probe the application from a node, use the Service's ClusterIP and port shown by `kubectl get svc -o wide`:

```bash
# Enter the k8s-ctrl node shell.
lxc shell k8s-ctrl
```
??? example "Expected result"
    ```shell
    root@k8s-ctrl:~#
    ```

```bash
# Install pandoc on the k8s-ctrl node.
apt install -y pandoc
```
??? example "Expected result"
    ```text
    Setting up pandoc (3.1.3+ds-2) ...
    ```

```bash
# Probe nginx from the k8s-ctrl node.
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

```bash
# Exit the k8s-ctrl node.
exit
```
??? example "Expected result"
    ```shell
    ubuntu@radumoisan:~$
    ```

Repeat the probe from another worker node:

```bash
# Enter the k8s-worker1 node shell.
lxc shell k8s-worker1
```
??? example "Expected result"
    ```shell
    root@k8s-worker1:~#
    ```

```bash
# Install pandoc on the k8s-worker1 node.
apt install -y pandoc
```
??? example "Expected result"
    ```text
    Setting up pandoc (3.1.3+ds-2) ...
    ```

```bash
# Probe nginx from the k8s-worker1 node.
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

Go back to the student machine:

```bash
# Exit the k8s-worker1 node.
exit
```
??? example "Expected result"
    ```shell
    ubuntu@radumoisan:~$
    ```

## :material-book-open-page-variant-outline: 2.2 Service discovery

In the default Kubernetes network model, Pods can communicate across nodes without NAT unless network policies or infrastructure rules restrict that traffic. Rather than use a Service's ClusterIP directly, clients can use its DNS name.

Kubernetes can inject environment variables for existing Services into newly created Pods, including `NGINX_SERVICE_HOST` and `NGINX_SERVICE_PORT` in this example. New Services are not added to already-running Pods, so DNS is the preferred discovery method.

Canonical Kubernetes uses CoreDNS for cluster DNS. Pods are configured through `/etc/resolv.conf` to send cluster-domain queries to the DNS Service.

CoreDNS runs in Pods in the `kube-system` namespace.

!!! info ""
    For more information, see the [CoreDNS documentation](https://coredns.io).

A Service receives a DNS record such as `service-name.namespace.svc.cluster.local`. For example, the `nginx` Service in the `default` namespace can be reached as `nginx.default.svc.cluster.local`, or simply as `nginx` from the same namespace.

Alongside the existing nginx Pod and Service, create another Pod and query the nginx DNS name from it. Commands can be run in a Pod with `kubectl exec`. You can also launch an interactive shell if the container image provides one.

List the CoreDNS Pods:

```bash
# List CoreDNS pods.
kubectl get pods -n kube-system | { head -n 1; grep "coredns"; }
```
??? example "Expected result"
    ```text
    NAME                                  READY   STATUS    RESTARTS   AGE
    coredns-c4fd9db5c-t5f84               1/1     Running   0          3h36m
    coredns-c4fd9db5c-ww2bj               1/1     Running   0          3h36m
    ```

The Pod can be created without a Pod definition file:

```bash
# Create and enter the shell pod.
kubectl run shell -i --tty --image ubuntu -- /bin/bash
```
??? example "Expected result"
    ```shell
    All commands and output from this session will be recorded in container logs, including credentials and sensitive information passed through the command prompt.
    If you don't see a command prompt, try pressing enter.
    root@shell:/#
    ```

```bash
# Exit the shell pod.
exit
```
??? example "Expected result"
    ```shell
    ubuntu@radumoisan:~$
    ```

Exiting stops the container's main shell, and the Pod restarts it. Wait for the Pod to become Ready again:

```bash
# Wait for the shell pod to become Ready again.
kubectl wait --for=condition=Ready pod/shell --timeout=180s
```
??? example "Expected result"
    ```text
    pod/shell condition met
    ```

After which we can reconnect to the pod:

```bash
# Reconnect to the shell pod.
kubectl exec -it shell -- /bin/bash
```
??? example "Expected result"
    ```shell
    root@shell:/#
    ```

```bash
# Update package information in the shell pod.
apt update
```
??? example "Expected result"
    ```text
    Fetched 26.0 MB in 4s (7026 kB/s)
    24 packages can be upgraded. Run 'apt list --upgradable' to see them.
    ```

```bash
# Install curl and pandoc in the shell pod.
apt install curl pandoc -y
```
??? example "Expected result"
    ```text
    Setting up pandoc (3.7.0.2+ds-1) ...
    Setting up curl (8.18.0-1ubuntu2.4) ...
    Processing triggers for ca-certificates (20260601~26.04.1) ...
    ```

```bash
# Probe nginx using service discovery.
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

```bash
# Exit the shell pod.
exit
```
??? example "Expected result"
    ```shell
    ubuntu@radumoisan:~$
    ```

Here `nginx` is the name of the Service:

```bash
# List services with selectors.
kubectl get svc -o wide
```
??? example "Expected result"
    ```text
    NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE   SELECTOR
    kubernetes   ClusterIP   10.152.0.1      <none>        443/TCP    4h    <none>
    nginx        ClusterIP   10.152.46.161   <none>        8080/TCP   27m   app=nginx
    ```

## :material-book-open-page-variant-outline: 2.3 NodePort and LoadBalancer Services

Until now we made the web app available only inside the cluster. There are a couple of ways to allow outside access.

A `NodePort` Service exposes the same port on every node. Clients connect through a reachable node IP address and that port, subject to routing and firewall rules.

![nodeport](assets/nodeport.png)

This is a `NodePort` Service definition for the nginx application:

```bash
# Display the NodePort service definition.
cat ~/resources/nodeport-service.yaml
```
??? example "Expected result"
    ```yaml
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

```bash
# Create the NodePort service.
kubectl create -f ~/resources/nodeport-service.yaml
```
??? example "Expected result"
    ```text
    service/nginx-nodeport created
    ```

Inspect the service:

```bash
# List services with selectors.
kubectl get svc -o wide
```
??? example "Expected result"
    ```text
    NAME             TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE    SELECTOR
    kubernetes       ClusterIP   10.152.0.1       <none>        443/TCP          4h3m   <none>
    nginx            ClusterIP   10.152.46.161    <none>        8080/TCP         31m    app=nginx
    nginx-nodeport   NodePort    10.152.132.179   <none>        8080:30111/TCP   29s    app=nginx
    ```

The `nodePort: 30111` field selects the port exposed on each node. A client connects to `<NodeIP>:30111`:

First, install `pandoc` to render the HTML output from `curl` as text:

```bash
# Install pandoc on the student machine.
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

Then, identify the IP addresses of the control plane and worker nodes:

```bash
# List node IP addresses.
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

Lastly, use the IP address of any reachable node whose name starts with `k8s-` to access the nginx Service:

```bash
# Probe nginx through the NodePort.
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

!!! warning "NodePort access"
    Firewall and routing rules must allow access to port `30111` on the selected node.

Consider these NodePort characteristics in production:

* Only one Service can use a given NodePort.
* The default NodePort range is 30000 to 32767, although it is configurable.
* Clients or an external load balancer must use reachable node addresses and handle node availability.

A `LoadBalancer` Service requests an externally reachable address from the platform's load-balancer implementation. Cloud providers commonly supply this integration. In this local deployment, Cilium and MetalLB provide it, and the allocated address is not necessarily public.

![loadbalancer](assets/loadbalancer2.png)

!!! warning ""
    The IP addresses and ports in the diagram differ from those used in the exercise.

Create a `LoadBalancer` Service for the nginx application:

```bash
# Display the LoadBalancer service definition.
cat ~/resources/loadbalancer-service.yaml
```
??? example "Expected result"
    ```yaml
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

```bash
# Create the LoadBalancer service.
kubectl create -f ~/resources/loadbalancer-service.yaml
```
??? example "Expected result"
    ```text
    service/nginx-loadbalancer created
    ```

MetalLB may take a few seconds to allocate an address. Repeat the following command until `nginx-loadbalancer` has an `EXTERNAL-IP` instead of `<pending>`:

```bash
# List services.
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

The `EXTERNAL-IP` column shows the address allocated by MetalLB. In this example, the endpoint is `10.107.242.11:8080`. If your cluster reports a different address, substitute it in the browser and the following command:

```bash
# Probe nginx through the LoadBalancer.
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

Clean up the resources created so far:

```bash
# Delete the nginx services.
kubectl delete svc nginx nginx-loadbalancer nginx-nodeport
```
??? example "Expected result"
    ```text
    service "nginx" deleted from default namespace
    service "nginx-loadbalancer" deleted from default namespace
    service "nginx-nodeport" deleted from default namespace
    ```

```bash
# Delete the nginx and shell pods.
kubectl delete pod nginx shell
```
??? example "Expected result"
    ```text
    pod "nginx" deleted from default namespace
    pod "shell" deleted from default namespace
    ```

## :material-book-open-page-variant-outline: 2.4 Ingress controllers

An Ingress defines HTTP(S) routing rules that expose Services. An Ingress controller implements those rules and can provide load balancing, name-based virtual hosting, and TLS termination.

![ingress](assets/ingress2.png)

This lab uses Cilium for container networking and Ingress support.

Check that the Cilium Pods are running on each node:

```bash
# List Cilium pods.
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

```bash
# List Cilium services.
kubectl get svc -A |  awk 'NR==1 || tolower($0) ~ /cilium/'
```
??? example "Expected result"
    ```text
    NAMESPACE        NAME                                TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                      AGE
    kube-system      cilium-ingress                      LoadBalancer   10.152.181.41    10.107.242.10   80:31285/TCP,443:30697/TCP   4h19m
    ```

Imagine a web application with two microservices, red and blue. These examples display only text, but the same routing pattern applies to real-world applications.

Check the red microservice definition:

```bash
# Display the red microservice definition.
cat ~/resources/red-app.yaml
```
??? example "Expected result"
    ```yaml
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

The blue microservice looks the same but instead of red, it displays blue.

Also, check the Ingress resource definition:

```bash
# Display the Ingress resource definition.
cat ~/resources/ingress.yaml
```
??? example "Expected result"
    ```yaml
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

The legacy `ingress.kubernetes.io/rewrite-target` annotation is not required by Cilium for these `Prefix` routes. This exercise validates path routing, not URL rewriting.

Each HTTP rule contains the following information:
1. An optional `host`. If no host is specified, the rule applies to inbound HTTP traffic that reaches the Ingress address.

2. A list of paths, such as `/red` and `/blue`, each associated with a backend Service. The Ingress controller evaluates the host and path before routing a request.

3. A backend that identifies a Service and one of its ports by name or number. Matching requests are sent to that Service.

Create the objects:

```bash
# Create the blue microservice objects.
kubectl create -f ~/resources/blue-app.yaml
```
??? example "Expected result"
    ```text
    pod/blue-app created
    service/blue-service created
    ```

```bash
# Wait for the blue microservice pod to become Ready.
kubectl wait --for=condition=Ready pod/blue-app --timeout=180s
```
??? example "Expected result"
    ```text
    pod/blue-app condition met
    ```

```bash
# Create the red microservice objects.
kubectl create -f ~/resources/red-app.yaml
```
??? example "Expected result"
    ```text
    pod/red-app created
    service/red-service created
    ```

```bash
# Wait for the red microservice pod to become Ready.
kubectl wait --for=condition=Ready pod/red-app --timeout=180s
```
??? example "Expected result"
    ```text
    pod/red-app condition met
    ```

```bash
# Create the Ingress object.
kubectl create -f ~/resources/ingress.yaml
```
??? example "Expected result"
    ```text
    ingress.networking.k8s.io/bluered-ingress created
    ```

Repeat the following command until the Ingress has an `ADDRESS` before testing its routes:

```bash
# List Ingress resources.
kubectl get ingress
```
??? example "Expected result"
    ```text
    NAME              CLASS    HOSTS   ADDRESS         PORTS   AGE
    bluered-ingress   cilium   *       10.107.242.10   80      28s
    ```

The `ADDRESS` column shows the address used to reach the Ingress. Open your tunneled browser and use that address for the `/blue` and `/red` paths. Replace `<ingress-address>` below with the reported address.

```bash
# Probe the blue microservice through the Ingress.
curl -s http://<ingress-address>/blue
```
??? example "Expected result"
    ```text
    blue-microservice
    ```

```bash
# Probe the red microservice through the Ingress.
curl -s http://<ingress-address>/red
```
??? example "Expected result"
    ```text
    red-microservice
    ```

!!! warning ""
    Your LoadBalancer IP address may differ from the example output.

After testing, remove the application Pods, Services, and Ingress.

```bash
# Delete the blue microservice objects.
kubectl delete -f ~/resources/blue-app.yaml
```
??? example "Expected result"
    ```text
    pod "blue-app" deleted from default namespace
    service "blue-service" deleted from default namespace
    ```

```bash
# Delete the red microservice objects.
kubectl delete -f ~/resources/red-app.yaml
```
??? example "Expected result"
    ```text
    pod "red-app" deleted from default namespace
    service "red-service" deleted from default namespace
    ```

```bash
# Delete the Ingress object.
kubectl delete -f ~/resources/ingress.yaml
```
??? example "Expected result"
    ```text
    ingress.networking.k8s.io "bluered-ingress" deleted from default namespace
    ```

!!! info ""
    For more information, see the [Kubernetes Ingress documentation](https://kubernetes.io/docs/concepts/services-networking/ingress/)
    and the [Cilium Ingress documentation](https://docs.cilium.io/en/stable/network/servicemesh/ingress/).
