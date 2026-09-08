# :material-numeric-7-circle: 7. Helm

Helm is like a package manager for Kubernetes. It allows users to install simple or complex apps with `Charts`. Charts
are packages of pre-configured Kubernetes resources.

In this chapter we'll install a `wordpress` stack with a `mariaDB` database. This requires some Kubernetes resources such as:
pods, loadBalancer services, `PVCs` and `PVs`. All of this will be deployed from a chart.

## :material-book-open-page-variant-outline: 7.1 Deploy an app

Install helm client on the student machine:

```bash
# Install the Helm client.
sudo snap install helm --channel=latest/stable --classic
```
??? example "Expected result"
    Helm is installed.

Once you have Helm ready, you can add a chart repository. One popular starting location is the official Helm stable charts:

```bash
# Add the stable chart repository.
helm repo add stable https://charts.helm.sh/stable
```
??? example "Expected result"
    The `stable` chart repository is added.

```bash
# List configured chart repositories.
helm repo list
```
??? example "Expected result"
    The configured chart repositories are displayed.

Update the information of available charts locally from chart repositories:

```bash
# Update local chart repository information.
helm repo update
```
??? example "Expected result"
    Chart repository information is updated.

List the charts you can install from the stable repo:

```bash
# Search the stable chart repository.
helm search repo stable
```
??? example "Expected result"
    Charts available from the `stable` repository are displayed.

Search for the individual `Wordpress` chart:

```bash
# Search for the stable Wordpress chart.
helm search repo stable/wordpress
```
??? example "Expected result"
    The `Wordpress` chart search result is displayed.

The Wordpress chart from this repo is deprecated. We will install Wordpress from another repo. Add the `Bitnami` repo:

```bash
# Add the Bitnami chart repository.
helm repo add bitnami https://charts.bitnami.com/bitnami
```
??? example "Expected result"
    The `bitnami` chart repository is added.

```bash
# Update local chart repository information.
helm repo update
```
??? example "Expected result"
    Chart repository information is updated.

Search the new repo for the Wordpress chart:

```bash
# Search for the Bitnami Wordpress chart.
helm search repo bitnami/wordpress
```
??? example "Expected result"
    The `Wordpress` chart search result is displayed.

Inspect the chart:

```bash
# Show the Wordpress chart metadata.
helm show chart bitnami/wordpress
```
??? example "Expected result"
    The Wordpress chart metadata is displayed.

Get all the information of the chart:

```bash
# Show all Wordpress chart information.
helm show all bitnami/wordpress
```
??? example "Expected result"
    All Wordpress chart information is displayed.

Or, list only the variables of the chart:

```bash
# Show Wordpress chart values.
helm show values bitnami/wordpress
```
??? example "Expected result"
    The Wordpress chart values are displayed.

Those variables can be overridden on deploy time either by using `--set` (we will use this method for install), or by using a
YAML formatted file with the changed variables, e.g. `helm install -f config.yaml stable/wordpress`. More information on this
can be found here:

https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing

Here is a link to the Git repo of the chart. More information on installation and supported config options can be inspected:

https://github.com/bitnami/charts/tree/master/bitnami/wordpress/#installing-the-chart

Time to install the chart:

```bash
# Install the Wordpress chart.
helm install my-wordpress-blog \
  --set wordpressUsername=admin \
  --set wordpressPassword=password \
  --set mariadb.auth.rootPassword=secretpassword \
    bitnami/wordpress
```
??? example "Expected result"
    The `my-wordpress-blog` release is installed.

**NOTE**: if the `mariadb.auth.rootPassword` variable is not set, the `mariadb` pod will fail to start due to failing liveness probes

The installation output will show lots of useful information, like how to access the chart application and how to get
credentials for the app. This information can also be accessed with the `status` command:

```bash
# Show the Wordpress release status.
helm status my-wordpress-blog
```
??? example "Expected result"
    The Wordpress release status and access information are displayed.

List the installed charts:

```bash
# List installed Helm releases.
helm list
```
??? example "Expected result"
    The installed Helm releases are displayed.

List the pods:

```bash
# List pods.
kubectl get pods
```
??? example "Expected result"
    ```text
    NAME                                READY   STATUS    RESTARTS   AGE
    my-wordpress-blog-fc4665457-hb8jr   1/1     Running   0          91s
    my-wordpress-blog-mariadb-0         1/1     Running   0          91s
    ```

The chart created a loadBalancer service:

```bash
# List services.
kubectl get svc
```
??? example "Expected result"
    ```text
    NAME                                 TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)                      AGE
    kubernetes                           ClusterIP      10.152.183.1     <none>          443/TCP                      26h
    my-wordpress-blog                    LoadBalancer   10.152.183.62    10.237.75.129   80:31834/TCP,443:30894/TCP   119s
    my-wordpress-blog-mariadb            ClusterIP      10.152.183.159   <none>          3306/TCP                     119s
    my-wordpress-blog-mariadb-headless   ClusterIP      None             <none>          3306/TCP                     119s
    ```

Now the wordpress app should be available via `10.237.75.129`.

In this chapter we saw how easy it is to deploy simple or complex apps with Helm.

## :material-book-open-page-variant-outline: 7.2 Deployment Chart

First, the application code has to be built into a Docker image. Here you can find code for a simple `nodejs` web app plus
the `Dockerfile` for it:

https://github.com/cloudbase/kubernetes-tools

```bash
# Clone the Kubernetes tools repository.
cd ~ && git clone https://github.com/cloudbase/kubernetes-tools.git
```
??? example "Expected result"
    The `kubernetes-tools` repository is cloned.

There are two ways to get the image, either build it or pull it from `DockerHub`. I am going to demonstrate how to built it, you don't
have to do it because the image is going to be pulled from `DockerHub`.

!!! warning "Demonstration only"
    **NOTE**: do not run the commands in the following box, only for demonstration, the images are already on DockerHub. You
    can skip the next few commands until you see "Demonstration ends here".

```bash
# only for demonstration
cd ~/kubernetes-tools/web-app/
```
??? example "Expected result"
    The working directory changes to the web app directory.

```bash
# Build the web app image for demonstration.
docker build -t <username>/web-app .
```
??? example "Expected result"
    The web app image is built.

```bash
# Tag the web app image for demonstration.
docker tag <username>/web-app <username>/web-app:v1
```
??? example "Expected result"
    The web app image is tagged.

The image is already public on `DockerHub`. It will automatically get pulled on all Kubernetes Nodes upon Pod creation.

Because the image is used with a complex environment like Kubernetes, it's useful to test it beforehand on it's own:

```bash
# Run the web app container for demonstration.
docker run -p 80:80 <username>/web-app:v1
```
??? example "Expected result"
    The web app container runs and listens on port `80`.

Open another tab on your public machine and test the container:

```bash
# Test the web app container for demonstration.
curl localhost:80
```
??? example "Expected result"
    The web app response is displayed.

Go back on the first tab and kill the container with `CTRL+C`.

!!! warning "Demonstration ends here"
    **NOTE**: Demonstration ends here.

Create a helm chart template and modify `values.yaml` to point to the correct image (`repository` and `tag`) and `replicaCount`:

```bash
# Create the web app chart and enter its directory.
helm create ~/web-app; cd ~/web-app
```
??? example "Expected result"
    The web app chart is created and the working directory changes to `~/web-app`.

```bash
# Edit the chart values file.
vim values.yaml
```
??? example "Expected result"
    The `values.yaml` file opens in the editor.

do desired edits on `values.yaml`, for example specify
`<username>/web-app:v1` Docker image:

```yaml
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
# Package the web app chart.
helm package .
```
??? example "Expected result"
    The web app chart archive is created.

Dry install the chart:

```bash
# do a dry run to check that everything is ok
helm install --debug --dry-run web-app-0.1.0.tgz --generate-name
```
??? example "Expected result"
    The rendered chart resources are displayed without creating them.

Install it:

```bash
# Install the web app chart.
helm install web-app-stateless web-app-0.1.0.tgz
```
??? example "Expected result"
    The `web-app-stateless` release is installed.

More info on Helm templating:
https://docs.helm.sh/chart_template_guide/

Verify the pod is running:

```bash
# List pods.
kubectl get pods
```
??? example "Expected result"
    ```text
    NAME                                 READY   STATUS    RESTARTS   AGE
    web-app-stateless-5bd5fffc48-654wt   1/1     Running   0          62s
    web-app-stateless-5bd5fffc48-qrmkh   1/1     Running   0          62s
    web-app-stateless-5bd5fffc48-xwcnq   1/1     Running   0          62s
    ```

Also verify there's a service created:

```bash
# Get the web app service.
kubectl get svc web-app-stateless
```
??? example "Expected result"
    ```text
    NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
    web-app-stateless   ClusterIP   10.152.183.20   <none>        80/TCP    88s
    ```

Because the app now has a ClusterIP service, you can go on any of the Nodes and do a curl on it on port `80`.
Connect to the node `0` and do a few `curl` commands on the ClusterIP of the chart. What happends?

```bash
# Query the web app ClusterIP from k8s-worker2.
lxc exec k8s-worker2 -- sh -c "curl -s 10.152.183.20"
```
??? example "Expected result"
    ```text
    This app is running in pod web-app-stateless-5bd5fffc48-xwcnq
    ```

### :material-application-edit-outline: try again

```bash
# Query the web app ClusterIP from k8s-worker2 again.
lxc exec k8s-worker2 -- sh -c "curl -s 10.152.183.20"
```
??? example "Expected result"
    ```text
    This app is running in pod web-app-stateless-5bd5fffc48-654wt
    ```

### :material-application-edit-outline: try one more time

```bash
# Query the web app ClusterIP from k8s-worker2 one more time.
lxc exec k8s-worker2 -- sh -c "curl -s 10.152.183.20"
```
??? example "Expected result"
    ```text
    This app is running in pod web-app-stateless-5bd5fffc48-qrmkh
    ```

Delete the application:

```bash
# Delete the stateless web app release.
helm delete web-app-stateless
```
??? example "Expected result"
    The `web-app-stateless` release is deleted.

## :material-book-open-page-variant-outline: 7.3 StatefulSet Chart

The Docker image can be built as before. I will only demonstrate how to do this, the image is already public so no need for you
to to this:

!!! warning "Demonstration only"
    **NOTE**: do not run the commands in the following box, only for demonstration, the images are already on DockerHub. You
    can skip the next few commands until you see "Demonstration ends here".

```bash
# only for demonstration
cd ~/kubernetes-tools/web-app-stateful/image
```
??? example "Expected result"
    The working directory changes to the stateful web app image directory.

```bash
# Build the stateful web app image for demonstration.
docker build -t <username>/web-app-stateful .
```
??? example "Expected result"
    The stateful web app image is built.

```bash
# Tag the stateful web app image for demonstration.
docker tag <username>/web-app-stateful <username>/web-app-stateful:v1
```
??? example "Expected result"
    The stateful web app image is tagged.

!!! warning "Demonstration ends here"
    **NOTE**: Demonstration ends here.

The image is already public on `DockerHub`. It will automatically get pulled on all Kubernetes Nodes upon Pod creation.

Build the Chart:

```bash
# Create and enter the stateful web app chart directory.
mkdir ~/web-app-stateful && cd ~/web-app-stateful
```
??? example "Expected result"
    The stateful web app chart directory is created and becomes the working directory.

```bash
# Copy the stateful web app chart files.
cp -r ~/kubernetes-tools/web-app-stateful/chart/* ~/web-app-stateful/
```
??? example "Expected result"
    The stateful web app chart files are copied.

Package the app:

```bash
# Package the stateful web app chart.
helm package .
```
??? example "Expected result"
    The stateful web app chart archive is created.

Based on the archive that we now have, we can install the Helm chart anywhere:

```bash
# Install the stateful web app chart.
helm install web-app-stateful web-app-stateful-0.1.0.tgz
```
??? example "Expected result"
    The `web-app-stateful` release is installed.

The `StatefulSet` requires a `clusterIP` headless service, this means that the service will not have an IP. So how do we connect to the
app? There are two ways, create another `clusterIP` service or use the proxy. On the student host run the proxy service:

```bash
# Start the Kubernetes API proxy.
kubectl proxy
```
??? example "Expected result"
    ```text
    Starting to serve on 127.0.0.1:8001
    ```

Open another terminal tab on your student machine. List your apps to get the name of the `StatefulSet` and query the pods:

```bash
# List installed Helm releases.
helm list
```
??? example "Expected result"
    Partial output includes:

    ```text
    web-app-stateful
    ```

Verify helm installed a StatefulSet and check the pods:

```bash
# List StatefulSets.
kubectl get statefulsets.apps
```
??? example "Expected result"
    ```text
    NAME               READY   AGE
    web-app-stateful   2/2     2m32s
    ```

```bash
# List pods.
kubectl get pods
```
??? example "Expected result"
    ```text
    NAME                 READY   STATUS    RESTARTS   AGE
    web-app-stateful-0   1/1     Running   0          100s
    web-app-stateful-1   1/1     Running   0          95s
    ```

```bash
# Query the first stateful web app pod through the proxy.
curl localhost:8001/api/v1/namespaces/default/pods/web-app-stateful-0/proxy/
```
??? example "Expected result"
    ```text
    You hit web-app-stateful-0
    Data stored on this pod: No data posted yet
    ```

```bash
# Query the second stateful web app pod through the proxy.
curl localhost:8001/api/v1/namespaces/default/pods/web-app-stateful-1/proxy/
```
??? example "Expected result"
    ```text
    You hit web-app-stateful-1
    Data stored on this pod: No data posted yet
    ```

No persistent data in the pods yet -> `Data stored on this pod: No data posted yet`.

Write data to a pod and check to see if it was written:

```bash
# Write data to the second stateful web app pod.
curl -X POST -d "Hey there!" \
localhost:8001/api/v1/namespaces/default/pods/web-app-stateful-1/proxy/
```
??? example "Expected result"
    ```text
    Data stored on pod web-app-stateful-1
    ```

```bash
# Query the second stateful web app pod through the proxy.
curl localhost:8001/api/v1/namespaces/default/pods/web-app-stateful-1/proxy/
```
??? example "Expected result"
    ```text
    You hit web-app-stateful-1
    Data stored on this pod: Hey there!
    ```

Indeed, data was written -> `Data stored on this pod: Hey there!`.

Delete the pod that stores the data:

```bash
# Delete the second stateful web app pod.
kubectl delete pod web-app-stateful-1
```
??? example "Expected result"
    The `web-app-stateful-1` pod is deleted.

Right after the delete, list the pods to see when happened:

```bash
# List pods.
kubectl get pods
```
??? example "Expected result"
    ```text
    NAME                 READY   STATUS    RESTARTS   AGE
    web-app-stateful-0   1/1     Running   0          4m14s
    web-app-stateful-1   1/1     Running   0          8s
    ```

There is a new pod but with the same name as the one deleted, we know this because it's only `8s` old.

The pod should be recreated by the `StatefulSet` but should retain the stored information:

```bash
# Query the recreated stateful web app pod through the proxy.
curl localhost:8001/api/v1/namespaces/default/pods/web-app-stateful-1/proxy/
```
??? example "Expected result"
    ```text
    You hit web-app-stateful-1
    Data stored on this pod: Hey there!
    ```

Indeed, the data persisted -> `Data stored on this pod: Hey there!`

Data persisted also because the pods were using a PV/PVC:

```bash
# List persistent volumes.
kubectl get pv
```
??? example "Expected result"
    Persistent volumes are displayed.

```bash
# List persistent volume claims.
kubectl get pvc
```
??? example "Expected result"
    Persistent volume claims are displayed.

Do a cleanup:

```bash
# Delete the stateful web app release.
helm delete web-app-stateful
```
??? example "Expected result"
    The `web-app-stateful` release is deleted.

## :material-book-open-page-variant-outline: 7.4 Headlamp

Headlamp is a user-friendly Kubernetes UI focused on extensibility. Headlamp was created to blend the traditional feature set of other web UIs/dashboards (i.e., to list and view resources) with added functionality. A common use case for any Kubernetes web UI is to deploy it `in-cluster` and set up an `ingress server` for having it available to users. We're going to do an `in-cluster` deployment.

First, let's add the Headlamp chart repository:

```bash
# Add the Headlamp chart repository.
helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
```
??? example "Expected result"
    The `headlamp` chart repository is added.

Update the repository:

```bash
# Update local chart repository information.
helm repo update
```
??? example "Expected result"
    Chart repository information is updated.

Search for the Headlamp chart:

```bash
# Search for the Headlamp chart.
helm search repo headlamp
```
??? example "Expected result"
    The Headlamp chart search result is displayed.

Install Headlamp:

```bash
# Install Headlamp in the kube-system namespace.
helm install headlamp headlamp/headlamp --namespace kube-system \
  --set replicaCount=3 \
  --set service.type=LoadBalancer
```
??? example "Expected result"
    The `headlamp` release is installed.

As of chart version 0.40.1, there’s a known bug where the Helm chart passes a -session-ttl flag that the binary doesn't recognize. The pod will CrashLoopBackOff. Fix it by running:

```bash
# Remove the unsupported Headlamp session TTL argument.
kubectl get deploy headlamp -n kube-system -o json | \
  jq '.spec.template.spec.containers[0].args |= map(select(. != "-session-ttl=86400"))' | \
  kubectl apply -f -
```
??? example "Expected result"
    The Headlamp deployment is updated.

If the chart version is greater than 0.40.1, this step may not be needed.
Check the status of the installation:

```bash
# Show the Headlamp release status.
helm status headlamp -n kube-system
```
??? example "Expected result"
    The Headlamp release status is displayed.

Check the pods:

```bash
# List Headlamp pods.
kubectl get pods -n kube-system -l app.kubernetes.io/name=headlamp
```
??? example "Expected result"
    ```text
    NAME                        READY   STATUS    RESTARTS   AGE
    headlamp-7975f584c8-2j69s   1/1     Running   0          11m
    headlamp-7975f584c8-62vvr   1/1     Running   0          11m
    headlamp-7975f584c8-rtvng   1/1     Running   0          11m
    ```

Check the `LoadBalancer` service created:

```bash
# List Headlamp services.
kubectl get services -n kube-system -l app.kubernetes.io/name=headlamp
```
??? example "Expected result"
    ```text
    NAME       TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)        AGE
    headlamp   LoadBalancer   10.152.183.231   10.237.75.130   80:32126/TCP   11m
    ```

Headlamp will create a `ServiceAccount` once it is installed called `headlamp` in your `kube-system` namespace. You can create a token for the `ServiceAccount` by running:

```bash
# Create a token for the Headlamp ServiceAccount.
kubectl create token headlamp --namespace kube-system
```
??? example "Expected result"
    ```text
    eyJhbGciOiJSUzI1NiIsImtpZCI6Ik1...
    ```

You can now use this token to authenticate to Headlamp. Open a tunneled browser session to `http://10.237.75.130` (Loadbalancer IP). You will be asked for a token to authenticate.
