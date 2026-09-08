# 7. Helm

Helm is a package manager for Kubernetes. A chart packages Kubernetes resource templates and default values. Installing
a chart creates a Helm release.

In this chapter, you will install a WordPress stack with a MariaDB database. The deployment uses Pods and LoadBalancer
Services, with persistent storage supplied through persistent volume claims (PVCs) and persistent volumes (PVs).

## :material-book-open-page-variant-outline: 7.1 Deploy an app

Install the Helm client on the student machine:

```bash
# Install the Helm client.
sudo snap install helm --channel=latest/stable --classic
```
??? example "Expected result"
    Helm is installed.

Add the archived `stable` chart repository. Its charts are deprecated, so use it only for comparison in this exercise:

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

Refresh the local chart information from the configured repositories:

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

Search for the WordPress chart:

```bash
# Search for the stable Wordpress chart.
helm search repo stable/wordpress
```
??? example "Expected result"
    The `Wordpress` chart search result is displayed.

The WordPress chart in this repository is deprecated. Add the Bitnami repository to use its chart instead:

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

Search the new repository for the WordPress chart:

```bash
# Search for the Bitnami Wordpress chart.
helm search repo bitnami/wordpress
```
??? example "Expected result"
    The `Wordpress` chart search result is displayed.

Inspect the chart metadata:

```bash
# Show the Wordpress chart metadata.
helm show chart bitnami/wordpress
```
??? example "Expected result"
    The Wordpress chart metadata is displayed.

Display all available chart information:

```bash
# Show all Wordpress chart information.
helm show all bitnami/wordpress
```
??? example "Expected result"
    All Wordpress chart information is displayed.

Display only the chart's default values:

```bash
# Show Wordpress chart values.
helm show values bitnami/wordpress
```
??? example "Expected result"
    The Wordpress chart values are displayed.

Chart values can be overridden at install time with `--set`, as used below, or with a YAML values file supplied through `-f`
or `--values`, e.g. `helm install -f config.yaml stable/wordpress`. For details, see the
[Helm chart customization documentation](https://helm.sh/docs/intro/using_helm/#customizing-the-chart-before-installing).

See the
[Bitnami WordPress chart documentation](https://github.com/bitnami/charts/tree/master/bitnami/wordpress/#installing-the-chart)
for installation and supported configuration options.

Install the chart as a release named `my-wordpress-blog`:

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

!!! warning "Training credentials only"
    The explicit `mariadb.auth.rootPassword` gives this exercise a predictable database credential. These simple passwords
    are for training only. In real deployments, use securely generated credentials managed through Secrets and avoid
    passing them on the command line.

The installation output includes useful information about accessing the application and retrieving its credentials. Display
this information again with the `status` command:

```bash
# Show the Wordpress release status.
helm status my-wordpress-blog
```
??? example "Expected result"
    The Wordpress release status and access information are displayed.

List the installed Helm releases:

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

The chart created a LoadBalancer Service:

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

The WordPress application should now be reachable over HTTP at the LoadBalancer `EXTERNAL-IP` shown above.

This section demonstrated how a chart installs a complete application stack as one Helm release.

## :material-book-open-page-variant-outline: 7.2 Deployment Chart

Kubernetes deploys container images rather than application source code. The
[Kubernetes tools repository](https://github.com/cloudbase/kubernetes-tools) contains a simple Node.js web app and its
`Dockerfile`:

```bash
# Clone the Kubernetes tools repository.
cd ~ && git clone https://github.com/cloudbase/kubernetes-tools.git
```
??? example "Expected result"
    The `kubernetes-tools` repository is cloned.

The application image can be built from the source or pulled from Docker Hub. This exercise uses the existing public image;
the following steps only demonstrate how it was built.

!!! warning "Demonstration only"
    Do not run the following demonstration commands. The image is already available on Docker Hub. Skip ahead to
    "Demonstration ends here."

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

The image is public on Docker Hub. When a Pod is scheduled, the kubelet pulls the image onto that node if it is not already
cached there.

Before deploying an image to Kubernetes, it is useful to test the container locally:

```bash
# Run the web app container for demonstration.
docker run -p 80:80 <username>/web-app:v1
```
??? example "Expected result"
    The web app container runs and listens on port `80`.

Open another terminal on the student machine and test the container:

```bash
# Test the web app container for demonstration.
curl localhost:80
```
??? example "Expected result"
    The web app response is displayed.

Return to the first terminal and stop the container with `CTRL+C`.

!!! warning "Demonstration ends here"
    Resume the exercise with the next step.

Create a Helm chart scaffold, then configure its image repository, image tag, and replica count in `values.yaml`:

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

Update `values.yaml` to use the public `pvradu/web-app:v1` image and three replicas:

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

Package the chart:

```bash
# Package the web app chart.
helm package .
```
??? example "Expected result"
    The web app chart archive is created.

Perform a dry run to inspect the rendered resources without creating them:

```bash
# do a dry run to check that everything is ok
helm install --debug --dry-run web-app-0.1.0.tgz --generate-name
```
??? example "Expected result"
    The rendered chart resources are displayed without creating them.

Install the packaged chart as the `web-app-stateless` release:

```bash
# Install the web app chart.
helm install web-app-stateless web-app-0.1.0.tgz
```
??? example "Expected result"
    The `web-app-stateless` release is installed.

For more information, see the [Helm chart template guide](https://docs.helm.sh/chart_template_guide/).

Verify the web app Pods are running. Other Pods in the namespace may also appear:

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

Verify that the chart also created a Service:

```bash
# Get the web app service.
kubectl get svc web-app-stateless
```
??? example "Expected result"
    ```text
    NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
    web-app-stateless   ClusterIP   10.152.183.20   <none>        80/TCP    88s
    ```

Because a ClusterIP is reachable from within the cluster network, query the Service on port `80` from a worker node. Repeat
the request to observe that the Service can route traffic to different ready Pod endpoints; the exact sequence is not guaranteed.

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

The stateful application image can be built in the same way. It is already public, so the following build steps are only a
demonstration:

!!! warning "Demonstration only"
    Do not run the following demonstration commands. The image is already available on Docker Hub. Skip ahead to
    "Demonstration ends here."

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
    Resume the exercise with the next step.

When a Pod is scheduled, the kubelet pulls the public image onto that node if it is not already cached there.

Assemble the chart from the provided files:

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

Package the chart:

```bash
# Package the stateful web app chart.
helm package .
```
??? example "Expected result"
    The stateful web app chart archive is created.

Install the packaged chart as the `web-app-stateful` release:

```bash
# Install the stateful web app chart.
helm install web-app-stateful web-app-stateful-0.1.0.tgz
```
??? example "Expected result"
    The `web-app-stateful` release is installed.

This chart uses a headless Service (`clusterIP: None`) as the StatefulSet's governing Service. It has no virtual ClusterIP;
instead, cluster DNS resolves the individual Pod endpoints. A separate regular Service could expose the application, but this
exercise uses the Kubernetes API proxy. Start the proxy on the student machine:

```bash
# Start the Kubernetes API proxy.
kubectl proxy
```
??? example "Expected result"
    ```text
    Starting to serve on 127.0.0.1:8001
    ```

Open another terminal on the student machine and confirm that the Helm release is installed:

```bash
# List installed Helm releases.
helm list
```
??? example "Expected result"
    Partial output includes:

    ```text
    web-app-stateful
    ```

Verify that Helm created a StatefulSet, then inspect its Pods:

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

The application reports that neither Pod has stored data yet.

Write data to one Pod and verify that it was stored:

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

The response confirms that the data was written: `Data stored on this pod: Hey there!`.

Delete the pod that stores the data:

```bash
# Delete the second stateful web app pod.
kubectl delete pod web-app-stateful-1
```
??? example "Expected result"
    The `web-app-stateful-1` pod is deleted.

Immediately list the Pods to observe what happened:

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

The StatefulSet created a replacement Pod with the same stable ordinal name. Its age shows that it is a new Pod.

The replacement Pod should retain the data because it remounts the same persistent volume claim:

```bash
# Query the recreated stateful web app pod through the proxy.
curl localhost:8001/api/v1/namespaces/default/pods/web-app-stateful-1/proxy/
```
??? example "Expected result"
    ```text
    You hit web-app-stateful-1
    Data stored on this pod: Hey there!
    ```

The response confirms that the data persisted: `Data stored on this pod: Hey there!`.

The StatefulSet alone does not persist data. Each Pod uses a stable PVC backed by a PV, allowing its replacement to remount
the same storage. Inspect these resources:

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

Delete the Helm release. PVCs created for StatefulSet Pods are normally retained and may require separate cleanup:

```bash
# Delete the stateful web app release.
helm delete web-app-stateful
```
??? example "Expected result"
    The `web-app-stateful` release is deleted.

## :material-book-open-page-variant-outline: 7.4 Headlamp

Headlamp is an extensible Kubernetes web interface for viewing and managing cluster resources. This exercise deploys it
inside the cluster and exposes it through a LoadBalancer Service. An Ingress is another exposure option, but is not configured here.

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

Chart version `0.40.1` has a known issue in which it passes an unsupported `-session-ttl` argument. If the Headlamp Pods enter
`CrashLoopBackOff` and their logs report this argument, remove it with:

```bash
# Remove the unsupported Headlamp session TTL argument.
kubectl get deploy headlamp -n kube-system -o json | \
  jq '.spec.template.spec.containers[0].args |= map(select(. != "-session-ttl=86400"))' | \
  kubectl apply -f -
```
??? example "Expected result"
    The Headlamp deployment is updated.

Skip this workaround if the installed chart does not include the unsupported argument.
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

The chart creates a `headlamp` ServiceAccount in the `kube-system` namespace. With the chart defaults used here, it is bound
to the `cluster-admin` ClusterRole. Request a short-lived bearer token for this ServiceAccount:

```bash
# Create a token for the Headlamp ServiceAccount.
kubectl create token headlamp --namespace kube-system
```
??? example "Expected result"
    ```text
    eyJhbGciOiJSUzI1NiIsImtpZCI6Ik1...
    ```

Enter this token when Headlamp prompts for authentication.

!!! danger "Cluster-admin token"
    The token grants full control of the cluster, so treat it as a sensitive credential and use this configuration only for
    the lab.

Open a tunneled browser session to `http://<EXTERNAL-IP>`, replacing the placeholder with the LoadBalancer address reported
above.
