# 2. Networking !heading

## 2.1 Exposing apps using Services and Labels

The pods/apps we've created so far were not accessible. Kubernetes does not follow the legacy networking architecture
because of a number of reasons:

  * pods are ephemeral
  * Kubernetes itself assigns IPs to pods after they are scheduled -> the user cannot assign or know the IP beforehand
  * scaling and load-balancing: users should not care how many pods are backing a service, what their IPs are, on which nodes the pods are scheduled

To solve these issues, Kubernetes provides the `Service` object resource type.

![service](assets/network1.png)

A `Service` is a single point of access to a group of pods that provide the same type of service. Each service has
an IP and a port that will never change during the lifetime of the service. Users will initiate connections to the IP
and port, and those connections are routed to one of the pods backing the service. This way, users don't have to care
about pod location and if a pod crashes.

![service](assets/service1.png)


There are three types of Services:
  * `ClusterIPs`: the purpose of this type of service is exposing groups of pods to other pods in the cluster
  * `NodePort`: allocates a static port on the Node on which the pod is running. Used to access Pod port from outside the cluster
  * `LoadBalancer`: exposes the service externally using a cloud provider’s load balancer. Used to access Pod's from outside the cluster
  * `ExternalName`: maps the Service to the contents of the externalName field (for example, to the hostname api.foo.bar.example). The mapping configures your cluster's DNS server to return a CNAME record with that external hostname value. No proxying of any kind is set up.

`Labels` and `Selectors` help in associating Services to Pods. `Labels` are key-value pairs that can be associated with pods in the pod
definition. Then, a Service will use label `Selectors` to know to which pods to redirect traffic to.

For example, given some pods running an app, we would specify in the pod definition of the app we specify a label `app: nginx` and we
scale the pods to 3. Then a service can be create with Selector `app: nginx`. This is how Services know where to route traffic
and load-balance between the 3 pods.

![labels and selectors](assets/labels_selectors.png)

Canonical Kubernetes deployed with CAPI comes with Cilium CNI and MetalLB. MetalLB needs some pool of IP addressess that can be used for `LoadBalancer` services. Let's configure that IPAddressPool:

Create a yaml file, called `metallb.yaml` with the following content:

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

Replace the first three groups with the IP address you get from:

```bash
ip add sh dev lxdbr0

# output
3: lxdbr0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc noqueue state UP group default qlen 1000
    link/ether 00:16:3e:d9:14:a7 brd ff:ff:ff:ff:ff:ff
    inet 10.219.64.1/24 scope global lxdbr0
       valid_lft forever preferred_lft forever
```

So, the file, in this case, should look like:

```yaml
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: lb-pool
  namespace: metallb-system
spec:
  addresses:
  - 10.219.64.10-10.219.64.40
```

Apply the configuration with:

```bash
kubectl apply -f metallb.yaml
```

Verify the configuration has been applied with:

```bash
kubectl get IPAddressPool -n metallb-system
kubectl describe IPAddressPool -n metallb-system lb-pool
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
kubectl apply -f metallb-l2advertisement.yaml
```

Also, cilium-ingress endpointslice will need a patch:

```bash
kubectl label endpointslice cilium-ingress \
  -n kube-system \
  kubernetes.io/service-name=cilium-ingress \
  --overwrite
```

Now, let's take a look at the existing services:

```bash
kubectl get svc --all-namespaces

# output
NAMESPACE        NAME                                TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
default          kubernetes                          ClusterIP      10.152.0.1       <none>        443/TCP                      68m
kube-system      cilium-ingress                      LoadBalancer   10.152.84.241    10.219.64.10  80:31695/TCP,443:31146/TCP   68m
kube-system      ck-storage-rawfile-csi-controller   ClusterIP      None             <none>        <none>                       68m
kube-system      ck-storage-rawfile-csi-node         ClusterIP      10.152.211.218   <none>        9100/TCP                     68m
kube-system      coredns                             ClusterIP      10.152.27.35     <none>        53/UDP,53/TCP                68m
kube-system      hubble-peer                         ClusterIP      10.152.17.16     <none>        443/TCP                      68m
kube-system      metrics-server                      ClusterIP      10.152.75.38     <none>        443/TCP                      68m
metallb-system   metallb-webhook-service             ClusterIP      10.152.195.15    <none>        443/TCP                      68m
```

Here we can see all the Services within the cluster. Control plane Kubernetes Pods talk to each other via the `ClusterIPs`. Only the `cilium-ingress` service is exposed to the outside world. If you add `-o wide` to the command above, you can see in the `Selector` field the association between a Service and Pods.
The `ClusterIPs` are internal, virtual IPs that only Kubernetes has knowledge of.

**NOTE**: The same Selector mechanism is used for other objects (resources) offered by Kubernetes. Other Kubernetes objects (Deployment,
ReplicaSets, etc,) which interact with Pods use the same mechanism.

Ok, let's redeploy `nginx` and use a label. Check the `~/resources/nginx-pod.yaml` pod definition to see and note the `label` part:

```bash
cat ~/resources/nginx-pod.yaml

# output
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
kubectl create -f ~/resources/nginx-pod.yaml
```

Now it's time to create the Service. The Service definition file should be found under `~/resources/nginx-service.yaml`. Let's
examine the contents and create the Service:

```bash
cat ~/resources/nginx-service.yaml

# output
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
kubectl create -f ~/resources/nginx-service.yaml
```

The service should now be visible:

```bash
kubectl get svc -o wide

# output
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE   SELECTOR
kubernetes   ClusterIP   10.152.0.1      <none>        443/TCP    70m   <none>
nginx        ClusterIP   10.152.95.221   <none>        8080/TCP   5s    app=nginx
```

Currently, the app can now be accessed from within the cluster, but not from outside of the cluster.

Actually, there are two ways to probe the web app, but both of them are just for demonstration purposes. In production
environments direct access to the apps is desired, we do not have that yet. This is just for demonstration purposes and to
understand the architecture.

One of the rules of Kubernetes networking is: all nodes can communicate with all containers without NAT. This means that if we `ssh` in
one of the Nodes, we should be able to `curl` the web app. For this two things are needed, the `ClusterIP` of the app and the
port on which the app is listening, both of which we can extract from the previous `kubectl get svc -o wide` command. We need to
log in one of the Nodes , doesn't matter which one, all the Nodes can reach the Pod. List the nodes:

```bash
lxc shell k8s-ctrl
apt install -y pandoc
curl -s 10.152.95.221:8080 | pandoc -f html -t plain

# output
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
# exit k8s-ctrl node
exit
```

This should also work from any other worker node:

```bash
lxc shell k8s-worker1
apt install -y pandoc
curl -s 10.152.95.221:8080 | pandoc -f html -t plain

# output
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
exit
```

## 2.2 Service discovery

Another rule of Kubernetes networking is: all containers can communicate with all the other containers without NAT. This means that
the web app can be probed from another pod with a `ClusterIP` associated with it. But for this we won't be using the `ClusterIP`,
but the DNS record of the Service.

Pods need to talk to each other. Kubernetes has multiple mechanisms to do this. One of them is to set the `ClusterIPs` as environment
variables inside the pods. In this way, when some frontend component needs to talk to the backend, for example, the IP and port can be
referenced from the environment variable. In the nginx example, it would look like this `NGINX_SERVICE_HOST=10.152.183.197`
and `NGINX_SERVICE_PORT=8080`. This is not the best approach, however. If you add a new Service, it will not be automatically
be set on already running pods.

Another method is to have a DNS server in a Pod. Canonical Kubernetes comes with this feature by default. All the pods in the cluster are automatically
configured to use the DNS server (`/etc/resolv.conf` file). In this way, any query performed by a process within a Pod will be handled
by DNS server in Kubernetes, which is accessible from the whole cluster.

The default DNS server in Kubernetes is CoreDNS. It runs as a pod in the `kube-system` namespace.More info can be found here https://coredns.io.

If the DNS server is present, when a Service is created for a Pod, a  `A record` is also associated with the Pod in the form of
`pod-ip-address.my-namespace.pod.cluster.local`. For example, if I have a Pod with the ClusterIP of `1.2.3.4` in the `default`
Namespace, the DNS entry will be `1.2.3.4.default.pod.cluster.local`.

Alongside the previous nginx pod and service, we'll create another pod and do a `curl` on the nginx record from there. Commands can
be ran directly inside a pod by using `kubectl exec`. You can also lunch an interactive bash shell inside a pod (granted if the
base container has the bash installed).

List the `CoreDNS` pod:

```bash
kubectl get pods -n kube-system | { head -n 1; grep "coredns"; }

# output
NAME                                  READY   STATUS    RESTARTS   AGE
coredns-7b7cc6b5fc-hbbbg              1/1     Running   0          63m
coredns-7b7cc6b5fc-nmrb6              1/1     Running   0          63m
```

The pod can be created without a pods definition file:

```bash
kubectl run shell -i --tty --image ubuntu -- /bin/bash
```

```bash
# exit pod
root@shell:/# exit
```

After which we can reconnect to the pod:

```bash
kubectl exec -it shell -- /bin/bash
```

```bash
root@shell:/# apt update
```

```bash
root@shell:/# apt install curl pandoc -y
```

```bash
root@shell:/# curl -s nginx:8080 | pandoc -f html -t plain

# output
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
# go back to the student machine
root@shell:/# exit
```

Here `nginx` is the name of the Service:

```bash
kubectl get svc -o wide

# output
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE   SELECTOR
kubernetes   ClusterIP   10.152.0.1      <none>        443/TCP    95m   <none>
nginx        ClusterIP   10.152.95.221   <none>        8080/TCP   25m   app=nginx
```

## 2.3 NodePort and LoadBalancer Services

Until now we made the web app available only inside the cluster. There are a couple of ways to allow outside access.

`NodePorts` are one way to do it. Kubernetes will open a port on all Nodes. That port is accessible via the Nodes IP address.

![nodeport](assets/nodeport.png)

This is a `NodePort` Service definition for nginx app:

```bash
cat ~/resources/nodeport-service.yaml

# output
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
kubectl create -f ~/resources/nodeport-service.yaml
```

Inspect the service:

```bash
kubectl get svc -o wide

# output
NAME             TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE   SELECTOR
kubernetes       ClusterIP   10.152.0.1      <none>        443/TCP          96m   <none>
nginx            ClusterIP   10.152.95.221   <none>        8080/TCP         25m   app=nginx
nginx-nodeport   NodePort    10.152.57.213   <none>        8080:30111/TCP   5s    app=nginx
```

`nodePort: 30111` is of utmost importance here. The connection would look like this `<NodeIP>:<30111>`:

First, install the required `pandoc` so you can interpret HTML output of `curl`:

```bash
sudo apt update && sudo apt install -y pandoc
```

Then, find out the IP address of your nodes, control plane and worker:

```bash
lxc list -c n,4

# output
+--------------+--------------------------+
|     NAME     |           IPV4           |
+--------------+--------------------------+
| cluster-ctrl | 10.219.64.21 (eth0)      |
|              | 10.1.0.177 (cilium_host) |
+--------------+--------------------------+
| k8s-ctrl     | 10.219.64.22 (eth0)      |
|              | 10.1.0.44 (cilium_host)  |
+--------------+--------------------------+
| k8s-worker1  | 10.219.64.23 (eth0)      |
|              | 10.1.1.202 (cilium_host) |
+--------------+--------------------------+
| k8s-worker2  | 10.219.64.24 (eth0)      |
|              | 10.1.2.3 (cilium_host)   |
+--------------+--------------------------+
```

Lastly, `curl` any of the nodes that start with `k8s-` to access the nginx service:

```bash
curl -s 10.219.64.24:30111 | pandoc -f html -t plain

# output
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

**NOTE**: This required that port `30111` is opened on the Node.

Using NodePorts in production has a number of limitations, including:
 * only possible to have 1 service per port
 * limited Ports Range 30000 to 32767
 * in case of node IP address change the Service becomes unavailable
 * in case the node goes down the Service becomes unavailable

`LoadBalancer` is another type of Service allowing connections from outside. Kubernetes clusters usually run on top of
Cloud providers like AWS, Azure and GCP. Clusters and Cloud providers know how to interact with each other. The Cloud provider
will associate a public IP with the app. In ca local deployment of Canonical Kubernetes, this is handled by `Cilium` and `MetalLB`.

![loadbalancer](assets/loadbalancer2.png)

**NOTE** the IPs and ports from the diagram differ from the exercise ones.

Create a `LoadBalancer` IP and associate it with the nginx app:

```bash
cat ~/resources/loadbalancer-service.yaml

# output
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
kubectl create -f ~/resources/loadbalancer-service.yaml
```

It will take a couple of seconds for `MetalLB` to allocate a Load Balancer. Take a look at services:

```bash
kubectl get svc

# output
NAME                 TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE     SELECTOR
kubernetes           ClusterIP      10.152.0.1       <none>        443/TCP          98m     <none>
nginx                ClusterIP      10.152.95.221    <none>        8080/TCP         28m     app=nginx
nginx-loadbalancer   LoadBalancer   10.152.170.223   10.219.64.11  8080:32294/TCP   4s      app=nginx
nginx-nodeport       NodePort       10.152.57.213    <none>        8080:30111/TCP   2m46s   app=nginx
```

`10.237.75.129:8080` is a "public" IP address allocated by `MetalLB`. Try to access it from a tunneled browser.
Also, from any of the nodes, including your host, you can run:

```bash
curl -s 10.219.64.11:8080 | pandoc -f html -t plain
```

Cleanup the resources created so far:

```bash
# run 'kubectl get svc' to get the services
kubectl delete svc nginx nginx-loadbalancer nginx-nodeport
```

```bash
# run 'kubectl get pods' to get the pods
kubectl delete pod nginx shell
```

## 2.4 Ingress controllers

Ingress resources are DNS mappings to your containers, routed through endpoints. They can manage external access to the services
in a cluster, providing load balancing, name-based virtual hosting and SSL termination.

![ingress](assets/ingress2.png)

Canonical Kubernetes comes with Cilium CNI. Cilium provides different type of services and use-cases to your Kubernetes cluster, including `ingresses`.

Check the Cilium pods are running on each node:

```bash
kubectl get pods -A -o wide | awk 'NR==1 || tolower($0) ~ /cilium/'

# output
NAMESPACE        NAME                                  READY   STATUS    RESTARTS      AGE    IP             NODE          NOMINATED NODE   READINESS GATES
kube-system      cilium-4v7dx                          1/1     Running   0             29m    10.219.64.23   k8s-worker1   <none>           <none>
kube-system      cilium-6glws                          1/1     Running   0             29m    10.219.64.22   k8s-ctrl      <none>           <none>
kube-system      cilium-m5mlm                          1/1     Running   0             29m    10.219.64.24   k8s-worker2   <none>           <none>
kube-system      cilium-operator-54487fb5d6-4bmvk      1/1     Running   0             29m    10.219.64.22   k8s-ctrl      <none>           <none>
```

```bash
kubectl get svc -A |  awk 'NR==1 || tolower($0) ~ /cilium/'

# output
NAMESPACE        NAME                                TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
kube-system      cilium-ingress                      LoadBalancer   10.152.84.241    10.219.64.5   80:31695/TCP,443:31146/TCP   144m
```

Let's imagine we have a web application with two microservices, red and blue. The microservices are just displaying some text, but from a design perspective, a real world application would work just the same.

Check the red microservice definition:

```bash
cat ~/resources/red-app.yaml

# output
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

Also, check the Ingress Controller definition:

```bash
cat ~/resources/ingress.yaml

# output
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

Each HTTP rule contains the following information:
1. An optional `host`. If no host is specified, the rule applies to all inbound HTTP traffic through the IP address specified.

2. A list of paths (`/red`, `/blue`), each of which has an associated backend defined with a service. Both the host and path must match
the content of an incoming request before the load balancer directs traffic to the referenced Service.

3. A backend - combination of Service and port names as described in the Service. Requests to the Ingress that matches the host and
path of the rule are sent to the listed backend.

Create the objects:

```bash
kubectl create -f ~/resources/blue-app.yaml
kubectl create -f ~/resources/red-app.yaml
kubectl create -f ~/resources/ingress.yaml
```

The Ingress Controller is created:

```bash
kubectl get ingress

# output 
NAME              CLASS    HOSTS   ADDRESS       PORTS   AGE
bluered-ingress   cilium   *       10.219.64.10   80      6s
```

`10.219.64.10` is the MetalLB IP address for this ingress. It's matching the IP address of the `cilium-ingress` service from above. Open your tunneled browser and navigate to `http://10.219.64.10/blue` and `http://10.219.64.10/red`.

**NOTE**: your LoadBalancer IP will be different.

After everything is tested, remove the Ingress and pods.

```bash
kubectl delete -f ~/resources/blue-app.yaml
kubectl delete -f ~/resources/red-app.yaml
kubectl delete -f ~/resources/ingress.yaml
```

For more Ingress related information regarding Canonical Kubernetes, please visit:

https://kubernetes.io/docs/concepts/services-networking/ingress/
https://docs.cilium.io/en/stable/network/servicemesh/ingress/

