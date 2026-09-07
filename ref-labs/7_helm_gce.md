# 7. Helm !heading

Helm is like a package manager for Kubernetes. It allows users to install simple or complex apps with `Charts`. Charts
are packages of pre-configured Kubernetes resources.

In this chapter we'll install a `wordpress` stack with a `mariaDB` database. This requires some Kubernetes resources such as:
pods, loadBalancer services, `PVCs` and `PVs`. All of this will be deployed from a chart.


## 7.1 Deploy an app

Install helm client on the student machine:

```bash
sudo snap install helm --channel=latest/stable --classic
```

Once you have Helm ready, you can add a chart repository. One popular starting location is the official Helm stable charts:

```bash
helm repo add stable https://charts.helm.sh/stable
```

```bash
helm repo list
```

Update the information of available charts locally from chart repositories:

```bash
helm repo update
```

List the charts you can install from the stable repo:

```bash
helm search repo stable
```

Search for the individual `Wordpress` chart:

```bash
helm search repo stable/wordpress
```

The Wordpress chart from this repo is deprecated. We will install Wordpress from another repo. Add the `Bitnami` repo:

```bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
```

Search the new repo for the Wordpress chart:

```bash
helm search repo bitnami/wordpress
```

Inspect the chart:

```bash
helm show chart bitnami/wordpress
```

Get all the information of the chart:

```bash
helm show all bitnami/wordpress
```

Or, list only the variables of the chart:

```bash
helm show values bitnami/wordpress
```

Those variables can be overridden on deploy time either by using `--set` (we will use this method for install), or by using a
YAML formatted file with the changed variables, e.g. `helm install -f config.yaml stable/wordpress`. More information on this
can be found here:

https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing


Here is a link to the Git repo of the chart. More information on installation and supported config options can be inspected:

https://github.com/bitnami/charts/tree/master/bitnami/wordpress/#installing-the-chart

Time to install the chart:

```bash
helm install my-wordpress-blog \
  --set wordpressUsername=admin \
  --set wordpressPassword=password \
  --set mariadb.auth.rootPassword=secretpassword \
    bitnami/wordpress
```

**NOTE**: if the `mariadb.auth.rootPassword` variable is not set, the `mariadb` pod will fail to start due to failing liveness probes

The installation output will show lots of useful information, like how to access the chart application and how to get
credentials for the app. This information can also be accessed with the `status` command:

```bash
helm status my-wordpress-blog
```

List the installed charts:

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

The chart created a loadBalancer service:

```bash
kubectl get svc

# output
NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                      AGE
kubernetes                           ClusterIP      10.152.183.1     <none>          443/TCP                      26h
my-wordpress-blog                    LoadBalancer   10.152.183.62    10.237.75.129   80:31834/TCP,443:30894/TCP   119s
my-wordpress-blog-mariadb            ClusterIP      10.152.183.159   <none>          3306/TCP                     119s
my-wordpress-blog-mariadb-headless   ClusterIP      None             <none>          3306/TCP                     119s
```

Now the wordpress app should be available via `10.237.75.129`.

In this chapter we saw how easy it is to deploy simple or complex apps with Helm.

## 7.2 Deployment Chart

First, the application code has to be built into a Docker image. Here you can find code for a simple `nodejs` web app plus
the `Dockerfile` for it:

https://github.com/cloudbase/kubernetes-tools

```bash
cd ~ && git clone https://github.com/cloudbase/kubernetes-tools.git
```

There are two ways to get the image, either build it or pull it from `DockerHub`. I am going to demonstrate how to built it, you don't
have to do it because the image is going to be pulled from `DockerHub`.

**NOTE**: do not run the commands in the following box, only for demonstration, the images are already on DockerHub. You
can skip the next few commands until you see "Demonstration ends here".

<em>
```bash
# only for demonstration
cd ~/kubernetes-tools/web-app/
docker build -t <username>/web-app .
docker tag <username>/web-app <username>/web-app:v1
```
</em>

The image is already public on `DockerHub`. It will automatically get pulled on all Kubernetes Nodes upon Pod creation.

Because the image is used with a complex environment like Kubernetes, it's useful to test it beforehand on it's own:

<em>
```bash
docker run -p 80:80 <username>/web-app:v1
```
</em>

Open another tab on your public machine and test the container:

<em>
```bash
curl localhost:80
```
</em>

Go back on the first tab and kill the container with `CTRL+C`.

**NOTE**: Demonstration ends here.

Create a helm chart template and modify `values.yaml` to point to the correct image (`repository` and `tag`) and `replicaCount`:

```bash
helm create ~/web-app; cd ~/web-app
```

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

Package the app:

```bash
helm package .
```

Dry install the chart:

```bash
# do a dry run to check that everything is ok
helm install --debug --dry-run web-app-0.1.0.tgz --generate-name
```

Install it:

```bash
helm install web-app-stateless web-app-0.1.0.tgz
```

More info on Helm templating:
https://docs.helm.sh/chart_template_guide/

Verify the pod is running:

```bash
kubectl get pods

# output
NAME                                 READY   STATUS    RESTARTS   AGE
web-app-stateless-5bd5fffc48-654wt   1/1     Running   0          62s
web-app-stateless-5bd5fffc48-qrmkh   1/1     Running   0          62s
web-app-stateless-5bd5fffc48-xwcnq   1/1     Running   0          62s
```

Also verify there's a service created:

```bash
kubectl get svc web-app-stateless

# output
NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
web-app-stateless   ClusterIP   10.152.183.20   <none>        80/TCP    88s
```

Because the app now has a ClusterIP service, you can go on any of the Nodes and do a curl on it on port `80`.
Connect to the node `0` and do a few `curl` commands on the ClusterIP of the chart. What happends?

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

The Docker image can be built as before. I will only demonstrate how to do this, the image is already public so no need for you
to to this:

**NOTE**: do not run the commands in the following box, only for demonstration, the images are already on DockerHub. You
can skip the next few commands until you see "Demonstration ends here".

<em>
```bash
# only for demonstration
cd ~/kubernetes-tools/web-app-stateful/image
docker build -t <username>/web-app-stateful .
docker tag <username>/web-app-stateful <username>/web-app-stateful:v1
```
</em>
**NOTE**: Demonstration ends here.

The image is already public on `DockerHub`. It will automatically get pulled on all Kubernetes Nodes upon Pod creation.

Build the Chart:


```bash
mkdir ~/web-app-stateful && cd ~/web-app-stateful
cp -r ~/kubernetes-tools/web-app-stateful/chart/* ~/web-app-stateful/
```

Package the app:

```bash
helm package .
```

Based on the archive that we now have, we can install the Helm chart anywhere:

```bash
helm install web-app-stateful web-app-stateful-0.1.0.tgz
```

The `StatefulSet` requires a `clusterIP` headless service, this means that the service will not have an IP. So how do we connect to the
app? There are two ways, create another `clusterIP` service or use the proxy. On the student host run the proxy service:

```bash
kubectl proxy

# output
Starting to serve on 127.0.0.1:8001
```

Open another terminal tab on your student machine. List your apps to get the name of the `StatefulSet` and query the pods:

```bash
helm list

# output
web-app-stateful
```

Verify helm installed a StatefulSet and check the pods:

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

No persistent data in the pods yet -> `Data stored on this pod: No data posted yet`.

Write data to a pod and check to see if it was written:

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

Indeed, data was written -> `Data stored on this pod: Hey there!`.

Delete the pod that stores the data:

```bash
kubectl delete pod web-app-stateful-1
```

Right after the delete, list the pods to see when happened:

```bash
kubectl get pods

# output
NAME                 READY   STATUS    RESTARTS   AGE
web-app-stateful-0   1/1     Running   0          4m14s
web-app-stateful-1   1/1     Running   0          8s
```

There is a new pod but with the same name as the one deleted, we know this because it's only `8s` old.

The pod should be recreated by the `StatefulSet` but should retain the stored information:

```bash
curl localhost:8001/api/v1/namespaces/default/pods/web-app-stateful-1/proxy/

# output
You hit web-app-stateful-1
Data stored on this pod: Hey there!
```

Indeed, the data persisted -> `Data stored on this pod: Hey there!`

Data persisted also because the pods were using a PV/PVC:

```bash
kubectl get pv
kubectl get pvc
```

Do a cleanup:

```bash
helm delete web-app-stateful
```

# 7.4 Headlamp

Headlamp is a user-friendly Kubernetes UI focused on extensibility. Headlamp was created to blend the traditional feature set of other web UIs/dashboards (i.e., to list and view resources) with added functionality. A common use case for any Kubernetes web UI is to deploy it `in-cluster` and set up an `ingress server` for having it available to users. We're going to do an `in-cluster` deployment.

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

As of chart version 0.40.1, there’s a known bug where the Helm chart passes a -session-ttl flag that the binary doesn't recognize. The pod will CrashLoopBackOff. Fix it by running:

```bash
kubectl get deploy headlamp -n kube-system -o json | \
  jq '.spec.template.spec.containers[0].args |= map(select(. != "-session-ttl=86400"))' | \
  kubectl apply -f -
```

If the chart version is greater than 0.40.1, this step may not be needed.
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

Headlamp will create a `ServiceAccount` once it is installed called `headlamp` in your `kube-system` namespace. You can create a token for the `ServiceAccount` by running:

```bash
kubectl create token headlamp --namespace kube-system

# output
eyJhbGciOiJSUzI1NiIsImtpZCI6Ik1...
```

You can now use this token to authenticate to Headlamp. Open a tunneled browser session to `http://10.237.75.130` (Loadbalancer IP). You will be asked for a token to authenticate.
