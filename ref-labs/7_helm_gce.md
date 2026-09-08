# 7. Helm !heading

Helm is a package manager for Kubernetes. A chart packages Kubernetes resource templates and default values. Installing
a chart creates a Helm release.

In this chapter, you will install a WordPress stack with a MariaDB database. The deployment uses Pods and LoadBalancer
Services, with persistent storage supplied through persistent volume claims (PVCs) and persistent volumes (PVs).


## 7.1 Deploy an app

Install the Helm client on the student machine:

```bash
sudo snap install helm --channel=latest/stable --classic
```

Add the archived `stable` chart repository. Its charts are deprecated, so use it only for comparison in this exercise:

```bash
helm repo add stable https://charts.helm.sh/stable
```

```bash
helm repo list
```

Refresh the local chart information from the configured repositories:

```bash
helm repo update
```

List the charts you can install from the stable repo:

```bash
helm search repo stable
```

Search for the WordPress chart:

```bash
helm search repo stable/wordpress
```

The WordPress chart in this repository is deprecated. Add the Bitnami repository to use its chart instead:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

Search the new repository for the WordPress chart:

```bash
helm search repo bitnami/wordpress
```

Inspect the chart metadata:

```bash
helm show chart bitnami/wordpress
```

Display all available chart information:

```bash
helm show all bitnami/wordpress
```

Display only the chart's default values:

```bash
helm show values bitnami/wordpress
```

Chart values can be overridden at install time with `--set`, as used below, or with a YAML values file supplied through `-f`
or `--values`, e.g. `helm install -f config.yaml stable/wordpress`. The Helm documentation explains both methods:

https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing


The chart repository documents its installation and supported configuration options:

https://github.com/bitnami/charts/tree/master/bitnami/wordpress/#installing-the-chart

Install the chart as a release named `my-wordpress-blog`:

```bash
helm install my-wordpress-blog \
  --set wordpressUsername=admin \
  --set wordpressPassword=password \
  --set mariadb.auth.rootPassword=secretpassword \
    bitnami/wordpress
```

The explicit `mariadb.auth.rootPassword` gives this exercise a predictable database credential. These simple passwords are
for training only. In real deployments, use securely generated credentials managed through Secrets and avoid passing them
on the command line.

The installation output includes useful information about accessing the application and retrieving its credentials. Display
this information again with the `status` command:

```bash
helm status my-wordpress-blog
```

List the installed Helm releases:

```bash
helm list
```

List the pods:

```bash
kubectl get pods

# output
NAME                                READY   STATUS    RESTARTS   AGE
my-wordpress-blog-fc4665457-hb8jr   1/1     Running   0          91s
my-wordpress-blog-mariadb-0         1/1     Running   0          91s
```

The chart created a LoadBalancer Service:

```bash
kubectl get svc

# output
NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                      AGE
kubernetes                           ClusterIP      10.152.183.1     <none>          443/TCP                      26h
my-wordpress-blog                    LoadBalancer   10.152.183.62    10.237.75.129   80:31834/TCP,443:30894/TCP   119s
my-wordpress-blog-mariadb            ClusterIP      10.152.183.159   <none>          3306/TCP                     119s
my-wordpress-blog-mariadb-headless   ClusterIP      None             <none>          3306/TCP                     119s
```

The WordPress application should now be reachable over HTTP at the LoadBalancer `EXTERNAL-IP` shown above.

This section demonstrated how a chart installs a complete application stack as one Helm release.

## 7.2 Deployment Chart

Kubernetes deploys container images rather than application source code. This repository contains a simple Node.js web app
and its `Dockerfile`:

https://github.com/cloudbase/kubernetes-tools

```bash
cd ~ && git clone https://github.com/cloudbase/kubernetes-tools.git
```

The application image can be built from the source or pulled from Docker Hub. This exercise uses the existing public image;
the following steps only demonstrate how it was built.

**NOTE**: Do not run the following demonstration commands. The image is already available on Docker Hub. Skip ahead to
"Demonstration ends here."

<em>
```bash
# only for demonstration
cd ~/kubernetes-tools/web-app/
docker build -t <username>/web-app .
docker tag <username>/web-app <username>/web-app:v1
```
</em>

The image is public on Docker Hub. When a Pod is scheduled, the kubelet pulls the image onto that node if it is not already
cached there.

Before deploying an image to Kubernetes, it is useful to test the container locally:

<em>
```bash
docker run -p 80:80 <username>/web-app:v1
```
</em>

Open another terminal on the student machine and test the container:

<em>
```bash
curl localhost:80
```
</em>

Return to the first terminal and stop the container with `CTRL+C`.

**NOTE**: Demonstration ends here.

Create a Helm chart scaffold, then configure its image repository, image tag, and replica count in `values.yaml`:

```bash
helm create ~/web-app; cd ~/web-app
```

Update `values.yaml` to use the public `pvradu/web-app:v1` image and three replicas:

```bash
vim values.yaml
# do desired edits on values.yaml, for example specify
# <username>/web-app:v1 Docker image

...
replicaCount: 3

image:
  repository: pvradu/web-app
  pullPolicy: IfNotPresent
  # Overrides the image tag whose default is the chart appVersion.
  tag: "v1"
...
```

Package the chart:

```bash
helm package .
```

Perform a dry run to inspect the rendered resources without creating them:

```bash
# do a dry run to check that everything is ok
helm install --debug --dry-run web-app-0.1.0.tgz --generate-name
```

Install the packaged chart as the `web-app-stateless` release:

```bash
helm install web-app-stateless web-app-0.1.0.tgz
```

For more information about Helm templates, see:
https://docs.helm.sh/chart_template_guide/

Verify the web app Pods are running. Other Pods in the namespace may also appear:

```bash
kubectl get pods

# output
NAME                                 READY   STATUS    RESTARTS   AGE
web-app-stateless-5bd5fffc48-654wt   1/1     Running   0          62s
web-app-stateless-5bd5fffc48-qrmkh   1/1     Running   0          62s
web-app-stateless-5bd5fffc48-xwcnq   1/1     Running   0          62s
```

Verify that the chart also created a Service:

```bash
kubectl get svc web-app-stateless

# output
NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
web-app-stateless   ClusterIP   10.152.183.20   <none>        80/TCP    88s
```

Because a ClusterIP is reachable from within the cluster network, query the Service on port `80` from a worker node. Repeat
the request to observe that the Service can route traffic to different ready Pod endpoints; the exact sequence is not guaranteed.

```bash
lxc exec k8s-worker2 -- sh -c "curl -s 10.152.183.20"

# output
This app is running in pod web-app-stateless-5bd5fffc48-xwcnq

### try again
lxc exec k8s-worker2 -- sh -c "curl -s 10.152.183.20"

# output
This app is running in pod web-app-stateless-5bd5fffc48-654wt

### try one more time
lxc exec k8s-worker2 -- sh -c "curl -s 10.152.183.20"

# output
This app is running in pod web-app-stateless-5bd5fffc48-qrmkh
```
Delete the application:

```bash
helm delete web-app-stateless
```

## 7.3 StatefulSet Chart

The stateful application image can be built in the same way. It is already public, so the following build steps are only a
demonstration:

**NOTE**: Do not run the following demonstration commands. The image is already available on Docker Hub. Skip ahead to
"Demonstration ends here."

<em>
```bash
# only for demonstration
cd ~/kubernetes-tools/web-app-stateful/image
docker build -t <username>/web-app-stateful .
docker tag <username>/web-app-stateful <username>/web-app-stateful:v1
```
</em>
**NOTE**: Demonstration ends here.

When a Pod is scheduled, the kubelet pulls the public image onto that node if it is not already cached there.

Assemble the chart from the provided files:


```bash
mkdir ~/web-app-stateful && cd ~/web-app-stateful
cp -r ~/kubernetes-tools/web-app-stateful/chart/* ~/web-app-stateful/
```

Package the chart:

```bash
helm package .
```

Install the packaged chart as the `web-app-stateful` release:

```bash
helm install web-app-stateful web-app-stateful-0.1.0.tgz
```

This chart uses a headless Service (`clusterIP: None`) as the StatefulSet's governing Service. It has no virtual ClusterIP;
instead, cluster DNS resolves the individual Pod endpoints. A separate regular Service could expose the application, but this
exercise uses the Kubernetes API proxy. Start the proxy on the student machine:

```bash
kubectl proxy

# output
Starting to serve on 127.0.0.1:8001
```

Open another terminal on the student machine and confirm that the Helm release is installed:

```bash
helm list

# output
web-app-stateful
```

Verify that Helm created a StatefulSet, then inspect its Pods:

```bash
kubectl get statefulsets.apps

# output
NAME               READY   AGE
web-app-stateful   2/2     2m32s
```

```bash
kubectl get pods

# output
NAME                 READY   STATUS    RESTARTS   AGE
web-app-stateful-0   1/1     Running   0          100s
web-app-stateful-1   1/1     Running   0          95s
```

```bash
curl localhost:8001/api/v1/namespaces/default/pods/web-app-stateful-0/proxy/

# output
You hit web-app-stateful-0
Data stored on this pod: No data posted yet
```

```bash
curl localhost:8001/api/v1/namespaces/default/pods/web-app-stateful-1/proxy/

# output
You hit web-app-stateful-1
Data stored on this pod: No data posted yet
```

The application reports that neither Pod has stored data yet.

Write data to one Pod and verify that it was stored:

```bash
curl -X POST -d "Hey there!" \
localhost:8001/api/v1/namespaces/default/pods/web-app-stateful-1/proxy/

# output
Data stored on pod web-app-stateful-1
```

```bash
curl localhost:8001/api/v1/namespaces/default/pods/web-app-stateful-1/proxy/

# output
You hit web-app-stateful-1
Data stored on this pod: Hey there!
```

The response confirms that the data was written: `Data stored on this pod: Hey there!`.

Delete the pod that stores the data:

```bash
kubectl delete pod web-app-stateful-1
```

Immediately list the Pods to observe what happened:

```bash
kubectl get pods

# output
NAME                 READY   STATUS    RESTARTS   AGE
web-app-stateful-0   1/1     Running   0          4m14s
web-app-stateful-1   1/1     Running   0          8s
```

The StatefulSet created a replacement Pod with the same stable ordinal name. Its age shows that it is a new Pod.

The replacement Pod should retain the data because it remounts the same persistent volume claim:

```bash
curl localhost:8001/api/v1/namespaces/default/pods/web-app-stateful-1/proxy/

# output
You hit web-app-stateful-1
Data stored on this pod: Hey there!
```

The response confirms that the data persisted: `Data stored on this pod: Hey there!`.

The StatefulSet alone does not persist data. Each Pod uses a stable PVC backed by a PV, allowing its replacement to remount
the same storage. Inspect these resources:

```bash
kubectl get pv
kubectl get pvc
```

Delete the Helm release. PVCs created for StatefulSet Pods are normally retained and may require separate cleanup:

```bash
helm delete web-app-stateful
```

# 7.4 Headlamp

Headlamp is an extensible Kubernetes web interface for viewing and managing cluster resources. This exercise deploys it
inside the cluster and exposes it through a LoadBalancer Service. An Ingress is another exposure option, but is not configured here.

First, let's add the Headlamp chart repository:

```bash
helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
```

Update the repository:

```bash
helm repo update
```

Search for the Headlamp chart:

```bash
helm search repo headlamp
```

Install Headlamp:

```bash
helm install headlamp headlamp/headlamp --namespace kube-system \
  --set replicaCount=3 \
  --set service.type=LoadBalancer
```

Chart version `0.40.1` has a known issue in which it passes an unsupported `-session-ttl` argument. If the Headlamp Pods enter
`CrashLoopBackOff` and their logs report this argument, remove it with:

```bash
kubectl get deploy headlamp -n kube-system -o json | \
  jq '.spec.template.spec.containers[0].args |= map(select(. != "-session-ttl=86400"))' | \
  kubectl apply -f -
```

Skip this workaround if the installed chart does not include the unsupported argument.
Check the status of the installation:

```bash
helm status headlamp -n kube-system
```

Check the pods:

```bash
kubectl get pods -n kube-system -l app.kubernetes.io/name=headlamp

# output
NAME                        READY   STATUS    RESTARTS   AGE
headlamp-7975f584c8-2j69s   1/1     Running   0          11m
headlamp-7975f584c8-62vvr   1/1     Running   0          11m
headlamp-7975f584c8-rtvng   1/1     Running   0          11m
```

Check the `LoadBalancer` service created:

```bash
kubectl get services -n kube-system -l app.kubernetes.io/name=headlamp

# output
NAME       TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)        AGE
headlamp   LoadBalancer   10.152.183.231   10.237.75.130   80:32126/TCP   11m
```

The chart creates a `headlamp` ServiceAccount in the `kube-system` namespace. With the chart defaults used here, it is bound
to the `cluster-admin` ClusterRole. Request a short-lived bearer token for this ServiceAccount:

```bash
kubectl create token headlamp --namespace kube-system

# output
eyJhbGciOiJSUzI1NiIsImtpZCI6Ik1...
```

Enter this token when Headlamp prompts for authentication. It grants full control of the cluster, so treat it as a sensitive
credential and use this configuration only for the lab. Open a tunneled browser session to `http://<EXTERNAL-IP>`, replacing
the placeholder with the LoadBalancer address reported above.
