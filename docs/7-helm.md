# 7. Helm

Helm is a package manager for Kubernetes. A chart packages Kubernetes resource templates and default values. Installing a
chart creates a Helm release.

!!! abstract "Lab goals"
    - Install Helm and inspect chart repositories.
    - Deploy and inspect a WordPress release.
    - Build stateless and stateful application charts.
    - Verify StatefulSet data persistence.
    - Deploy Headlamp and handle its cluster-admin token safely.

!!! note "Validated versions"
    This workflow was validated with Helm `v4.2.4`, Kubernetes `v1.35.7`, WordPress chart `30.0.12`, Headlamp chart
    `0.45.0`, and `kubernetes-tools` commit `713c0fcbb51c4b31e65a0fce8a767c6ebd3c4b56`. Generated names, IP
    addresses, ages, and newer repository versions may differ. The required Snap command follows the moving
    `latest/stable` channel, so confirm `helm version` if the installed version differs from this snapshot.

!!! note "Expected results"
    Tabular results are representative excerpts and may omit dynamic columns that are not relevant to the check.

!!! note "Unattended execution"
    External downloads, release waits, token creation, and cleanup loops have explicit bounds. The workflow does not require
    an editor, a second terminal, `watch`, `kubectl proxy`, or manual interruption.

## :material-book-open-page-variant-outline: 7.1 Deploy an app

### :material-application-edit-outline: Prepare Helm

Select the workload cluster kubeconfig.

```bash
# Select the workload cluster kubeconfig.
export KUBECONFIG="$HOME/.kube/myk8scluster_config"
```

??? example "Expected result"
    ```text
    No output.
    ```

Confirm the active context before installing resources.

```bash
# Display the active workload cluster context.
kubectl config current-context
```

??? example "Expected result"
    ```text
    myk8scluster-admin@myk8scluster
    ```

Install the Helm client. Skip this command if the required version is already installed.

```bash
# Install the Helm client with a five-minute bound.
timeout 300s sudo snap install helm --channel=latest/stable --classic
```

??? example "Expected result"
    ```text
    helm 4.2.4 from Snapcrafters* installed
    ```

Display the installed version.

```bash
# Display the Helm client version.
helm version --short
```

??? example "Expected result"
    ```text
    v4.2.4+g3900f43
    ```

Stop before creating anything if release names, workload resources, or local working directories already exist. This guard
also establishes ownership of the directories removed at the end of the chapter.

```bash
# Reject Chapter 7 release, resource, and local-directory collisions.
timeout 60s sh -c '
  test -z "$(helm repo list -o json |
    jq -r ".[] | select(.name == \"stable\" or .name == \"bitnami\" or .name == \"headlamp\") | .name")" &&
  test -z "$(helm list --all-namespaces \
    --filter "^(my-wordpress-blog|web-app-stateless|web-app-stateful|headlamp)$" -q)" &&
  test -z "$(kubectl get deployment,statefulset,service,serviceaccount,secret,pvc \
    --all-namespaces -o name |
    grep -E "(my-wordpress-blog|web-app-stateless|web-app-stateful|headlamp)" || true)" &&
  test -z "$(kubectl get secret/oidc --namespace kube-system --ignore-not-found -o name)" &&
  test -z "$(kubectl get clusterrolebinding/headlamp-admin --ignore-not-found -o name)" &&
  for path in "$HOME/kubernetes-tools" "$HOME/web-app" "$HOME/web-app-stateful"; do
    test ! -e "$path" || {
      printf "Collision: %s\n" "$path"
      exit 1
    }
  done &&
  printf "No Chapter 7 collisions detected\n"
'
```

??? example "Expected result"
    ```text
    No Chapter 7 collisions detected
    ```

### :material-application-edit-outline: Explore chart repositories

Add the archived `stable` repository for comparison.

```bash
# Add the archived stable chart repository.
timeout 60s helm repo add stable https://charts.helm.sh/stable
```

??? example "Expected result"
    ```text
    "stable" has been added to your repositories
    ```

List the configured repositories.

```bash
# List configured chart repositories.
helm repo list
```

??? example "Expected result"
    ```text
    NAME     URL
    stable   https://charts.helm.sh/stable
    ```

Refresh the archived repository.

```bash
# Refresh the stable repository metadata.
timeout 180s helm repo update stable
```

??? example "Expected result"
    ```text
    ...Successfully got an update from the "stable" chart repository
    Update Complete.
    ```

Inspect its deprecated WordPress chart.

```bash
# Search for the deprecated WordPress chart.
helm search repo stable/wordpress
```

??? example "Expected result"
    ```text
    NAME               CHART VERSION   APP VERSION   DESCRIPTION
    stable/wordpress   9.0.3           5.3.2         DEPRECATED Web publishing platform...
    ```

Add the current Bitnami repository.

!!! warning "Limited Bitnami catalog"
    Since August 28, 2025, Bitnami provides only a limited free catalog under `docker.io/bitnami`. Older and versioned
    images moved to `docker.io/bitnamilegacy`, where they receive no updates. Do not replace the current image references
    with `bitnamilegacy` images. See the [Bitnami catalog announcement](https://github.com/bitnami/containers/issues/83267).

```bash
# Add the Bitnami chart repository.
timeout 60s helm repo add bitnami https://charts.bitnami.com/bitnami
```

??? example "Expected result"
    ```text
    "bitnami" has been added to your repositories
    ```

Refresh the repository.

```bash
# Refresh the Bitnami repository metadata.
timeout 180s helm repo update bitnami
```

??? example "Expected result"
    ```text
    ...Successfully got an update from the "bitnami" chart repository
    Update Complete.
    ```

Confirm the pinned WordPress version.

```bash
# Search for the pinned WordPress chart version.
helm search repo bitnami/wordpress --version 30.0.12
```

??? example "Expected result"
    ```text
    NAME                CHART VERSION   APP VERSION   DESCRIPTION
    bitnami/wordpress   30.0.12         6.9.4         WordPress is the world's most popular blogging...
    ```

Inspect the chart metadata.

```bash
# Display metadata for the pinned WordPress chart.
timeout 60s helm show chart bitnami/wordpress --version 30.0.12
```

??? example "Expected result"
    ```yaml
    apiVersion: v2
    appVersion: 6.9.4
    name: wordpress
    version: 30.0.12
    ```

Save the full chart information without sending thousands of lines to the terminal.

```bash
# Save all WordPress chart information and report its size.
timeout 60s helm show all bitnami/wordpress --version 30.0.12 >/tmp/wordpress-chart-all.txt && wc -l /tmp/wordpress-chart-all.txt
```

??? example "Expected result"
    ```text
    2429 /tmp/wordpress-chart-all.txt
    ```

Save the default values separately.

```bash
# Save the WordPress default values and report their size.
timeout 60s helm show values bitnami/wordpress --version 30.0.12 >/tmp/wordpress-values.yaml && wc -l /tmp/wordpress-values.yaml
```

??? example "Expected result"
    ```text
    1452 /tmp/wordpress-values.yaml
    ```

### :material-application-edit-outline: Deploy WordPress

Render the release locally before creating resources. The smaller claims keep the training deployment lightweight.

```bash
# Render the WordPress release and summarize its resource kinds.
timeout 120s helm template my-wordpress-blog bitnami/wordpress \
  --version 30.0.12 \
  --namespace default \
  --set wordpressUsername=admin \
  --set wordpressPassword=password \
  --set mariadb.auth.rootPassword=secretpassword \
  --set persistence.size=1Gi \
  --set mariadb.primary.persistence.size=1Gi \
  >/tmp/my-wordpress-blog.yaml &&
  grep '^kind:' /tmp/my-wordpress-blog.yaml |
  sort |
  uniq -c
```

??? example "Expected result"
    ```text
          1 kind: ConfigMap
          1 kind: Deployment
          2 kind: NetworkPolicy
          1 kind: PersistentVolumeClaim
          2 kind: PodDisruptionBudget
          2 kind: Secret
          3 kind: Service
          2 kind: ServiceAccount
          1 kind: StatefulSet
    ```

!!! warning "Training credentials only"
    These simple credentials are intentional training values. Do not use them outside the lab. Production credentials
    should come from an appropriate secret-management system.

!!! note "Pinned chart, rolling images"
    Chart `30.0.12` is pinned, but it currently references the limited Bitnami catalog through rolling
    `bitnami/wordpress:latest` and `bitnami/mariadb:latest` image tags. These images were available during validation, but
    their contents and availability can change independently of the chart version. This is accepted for the lab and is not
    a production recommendation. Production deployments should use a supported image source and immutable image digests.

Install the release with bounded readiness and rollback.

```bash
# Install the WordPress release with bounded readiness and rollback.
timeout 1800s helm install my-wordpress-blog bitnami/wordpress \
  --version 30.0.12 \
  --namespace default \
  --set wordpressUsername=admin \
  --set wordpressPassword=password \
  --set mariadb.auth.rootPassword=secretpassword \
  --set persistence.size=1Gi \
  --set mariadb.primary.persistence.size=1Gi \
  --wait \
  --wait-for-jobs \
  --timeout 15m \
  --rollback-on-failure
```

??? example "Expected result"
    ```text
    NAME: my-wordpress-blog
    NAMESPACE: default
    STATUS: deployed
    DESCRIPTION: Install complete
    CHART VERSION: 30.0.12
    APP VERSION: 6.9.4
    ```

### :material-application-edit-outline: Inspect the WordPress release

Inspect the release.

```bash
# Display WordPress release status.
helm status my-wordpress-blog --namespace default
```

??? example "Expected result"
    ```text
    NAME: my-wordpress-blog
    NAMESPACE: default
    STATUS: deployed
    my-wordpress-blog            Deployment 1/1
    my-wordpress-blog-mariadb   StatefulSet 1/1
    ```

List the release.

```bash
# List the WordPress release.
helm list --namespace default --filter "^my-wordpress-blog$"
```

??? example "Expected result"
    ```text
    NAME                NAMESPACE   REVISION   STATUS     CHART              APP VERSION
    my-wordpress-blog   default     1          deployed   wordpress-30.0.12   6.9.4
    ```

Wait for the WordPress and MariaDB Pods to become ready.

```bash
# Wait for the WordPress and MariaDB Pods.
kubectl wait --for=condition=Ready pod -l app.kubernetes.io/instance=my-wordpress-blog --timeout=600s
```

??? example "Expected result"
    ```text
    pod/my-wordpress-blog-8646dfbc9d-df5xg condition met
    pod/my-wordpress-blog-mariadb-0 condition met
    ```

Display the WordPress and MariaDB Pods:

```bash
# Display the WordPress release Pods.
kubectl get pods -l app.kubernetes.io/instance=my-wordpress-blog -o wide
```

??? example "Expected result"
    ```text
    NAME                                  READY   STATUS    NODE
    my-wordpress-blog-8646dfbc9d-df5xg   1/1     Running   k8s-worker1
    my-wordpress-blog-mariadb-0           1/1     Running   k8s-worker2
    ```

Display the Services created by the release:

```bash
# Display the WordPress release Services.
kubectl get service my-wordpress-blog my-wordpress-blog-mariadb my-wordpress-blog-mariadb-headless
```

??? example "Expected result"
    ```text
    NAME                                  TYPE           EXTERNAL-IP      PORT(S)
    my-wordpress-blog                     LoadBalancer   10.107.242.11   80:32232/TCP,443:30657/TCP
    my-wordpress-blog-mariadb             ClusterIP      <none>          3306/TCP
    my-wordpress-blog-mariadb-headless    ClusterIP      <none>          3306/TCP
    ```

Display the claims created by the release:

```bash
# Display the WordPress release claims.
kubectl get pvc -l app.kubernetes.io/instance=my-wordpress-blog
```

??? example "Expected result"
    ```text
    NAME                                  STATUS   CAPACITY   ACCESS MODES   STORAGECLASS
    data-my-wordpress-blog-mariadb-0      Bound    1Gi        RWO            csi-rawfile-default
    my-wordpress-blog                     Bound    1Gi        RWO            csi-rawfile-default
    ```

Verify the generated credential exists without decoding or printing it.

```bash
# Verify that the generated WordPress credential is present.
test -n "$(kubectl get secret my-wordpress-blog \
  -o jsonpath='{.data.wordpress-password}')" &&
  printf "WordPress credential is present\n"
```

??? example "Expected result"
    ```text
    WordPress credential is present
    ```

Wait for the external address:

```bash
# Wait for the WordPress LoadBalancer address.
kubectl wait --for=jsonpath='{.status.loadBalancer.ingress[0].ip}' service/my-wordpress-blog --timeout=180s
```

??? example "Expected result"
    ```text
    service/my-wordpress-blog condition met
    ```

Verify HTTP access through the LoadBalancer:

```bash
# Verify the WordPress LoadBalancer endpoint.
WORDPRESS_IP=$(kubectl get service my-wordpress-blog \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}') &&
  curl --silent --show-error --location \
    --output /dev/null \
    --write-out "HTTP %{http_code}\n" \
    --max-time 30 \
    "http://$WORDPRESS_IP/"
```

??? example "Expected result"
    ```text
    HTTP 200
    ```

### :material-application-edit-outline: Clean up WordPress

Remove the release and its retained StatefulSet claim.

```bash
# Uninstall the WordPress release with a bounded wait.
timeout 600s helm uninstall my-wordpress-blog --namespace default --wait --timeout 5m
```

??? example "Expected result"
    ```text
    release "my-wordpress-blog" uninstalled
    ```

Delete the retained WordPress claims:

```bash
# Delete retained WordPress release claims.
kubectl delete pvc -l app.kubernetes.io/instance=my-wordpress-blog --ignore-not-found --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    persistentvolumeclaim "data-my-wordpress-blog-mariadb-0" deleted from default namespace
    ```

Verify complete cleanup.

```bash
# Verify complete WordPress release cleanup.
test -z "$(helm list --namespace default --filter '^my-wordpress-blog$' -q)" &&
  test -z "$(kubectl get \
    deployment,statefulset,pod,service,serviceaccount,secret,configmap,networkpolicy,poddisruptionbudget,pvc \
    -l app.kubernetes.io/instance=my-wordpress-blog -o name)" &&
  test -z "$(kubectl get pv -o json |
    jq -r '.items[] | select(.spec.claimRef.namespace == "default" and
      (.spec.claimRef.name | contains("my-wordpress-blog"))) | .metadata.name')" &&
  printf "WordPress cleanup verified\n"
```

??? example "Expected result"
    ```text
    WordPress cleanup verified
    ```

## :material-book-open-page-variant-outline: 7.2 Deployment Chart

### :material-application-edit-outline: Prepare the stateless chart

Clone the application source and check out the exact validated commit.

```bash
# Clone and pin the Kubernetes tools source tree.
timeout 180s git clone \
  https://github.com/cloudbase/kubernetes-tools.git \
  "$HOME/kubernetes-tools" &&
  git -C "$HOME/kubernetes-tools" \
    checkout 713c0fcbb51c4b31e65a0fce8a767c6ebd3c4b56 &&
  git -C "$HOME/kubernetes-tools" rev-parse HEAD
```

??? example "Expected result"
    ```text
    Cloning into '/home/ubuntu/kubernetes-tools'...
    HEAD is now at 713c0fc Update values.yaml
    713c0fcbb51c4b31e65a0fce8a767c6ebd3c4b56
    ```

!!! note "Image build demonstration"
    The source tree contains `web-app/Dockerfile`. Building, tagging, and running an image is not required for this lab and
    would add an interactive foreground process. The validated chart uses the existing public `pvradu/web-app:v1` image.

Create a chart scaffold.

```bash
# Create the stateless web application chart.
helm create "$HOME/web-app"
```

??? example "Expected result"
    ```text
    Creating /home/ubuntu/web-app
    ```

Set the image and replica count without an editor.

```bash
# Set three replicas and the public application image non-interactively.
LC_ALL=C perl -0pi -e \
  's/^replicaCount: .*$/replicaCount: 3/m;
   s|^  repository: .*$|  repository: pvradu/web-app|m;
   s/^  tag: .*$/  tag: "v1"/m' \
  "$HOME/web-app/values.yaml" &&
  grep -A 8 '^replicaCount:' "$HOME/web-app/values.yaml"
```

??? example "Expected result"
    ```yaml
    replicaCount: 3

    image:
      repository: pvradu/web-app
      pullPolicy: IfNotPresent
      tag: "v1"
    ```

### :material-application-edit-outline: Validate and package the chart

Lint the chart:

```bash
# Lint the stateless web application chart.
helm lint "$HOME/web-app"
```

??? example "Expected result"
    ```text
    ==> Linting /home/ubuntu/web-app
    [INFO] Chart.yaml: icon is recommended

    1 chart(s) linted, 0 chart(s) failed
    ```

Render and summarize the chart resources:

```bash
# Render and summarize the stateless chart resources.
helm template web-app-stateless "$HOME/web-app" \
  --namespace default \
  >/tmp/web-app-stateless.yaml &&
  grep '^kind:' /tmp/web-app-stateless.yaml |
  sort |
  uniq -c
```

??? example "Expected result"
    ```text
          1 kind: Deployment
          1 kind: Pod
          1 kind: Service
          1 kind: ServiceAccount
    ```

Package the chart:

```bash
# Package the stateless chart in its working directory.
helm package "$HOME/web-app" --destination "$HOME/web-app"
```

??? example "Expected result"
    ```text
    Successfully packaged chart and saved it to: /home/ubuntu/web-app/web-app-0.1.0.tgz
    ```

### :material-application-edit-outline: Deploy and inspect the stateless release

Install the packaged chart:

```bash
# Install the stateless web application release.
timeout 1200s helm install \
  web-app-stateless \
  "$HOME/web-app/web-app-0.1.0.tgz" \
  --namespace default \
  --wait \
  --timeout 10m \
  --rollback-on-failure
```

??? example "Expected result"
    ```text
    NAME: web-app-stateless
    NAMESPACE: default
    STATUS: deployed
    DESCRIPTION: Install complete
    ```

Inspect the release.

```bash
# Display the stateless release status.
helm status web-app-stateless --namespace default
```

??? example "Expected result"
    ```text
    NAME: web-app-stateless
    NAMESPACE: default
    STATUS: deployed
    web-app-stateless   Deployment 3/3
    ```

Wait for all three replicas to become ready:

```bash
# Wait for all stateless application Pods.
kubectl wait \
  --for=condition=Ready \
  pod \
  -l app.kubernetes.io/instance=web-app-stateless \
  --timeout=300s
```

??? example "Expected result"
    ```text
    pod/web-app-stateless-5cc59678f-9j5wv condition met
    pod/web-app-stateless-5cc59678f-d8x9d condition met
    pod/web-app-stateless-5cc59678f-tfd8s condition met
    ```

Display the Pods' images and placement:

```bash
# Display the stateless application Pods.
kubectl get pods \
  -l app.kubernetes.io/instance=web-app-stateless \
  -o custom-columns=NAME:.metadata.name,READY:.status.containerStatuses[0].ready,IMAGE:.spec.containers[0].image,NODE:.spec.nodeName \
  --no-headers
```

??? example "Expected result"
    ```text
    web-app-stateless-5cc59678f-9j5wv   true   pvradu/web-app:v1   k8s-worker2
    web-app-stateless-5cc59678f-d8x9d   true   pvradu/web-app:v1   k8s-ctrl
    web-app-stateless-5cc59678f-tfd8s   true   pvradu/web-app:v1   k8s-worker1
    ```

Pod names and placement vary.

Display the Service:

```bash
# Display the stateless application Service.
kubectl get service web-app-stateless
```

??? example "Expected result"
    ```text
    NAME                  TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)
    web-app-stateless     ClusterIP   10.152.130.53   <none>        80/TCP
    ```

Display the Pods behind the Service:

```bash
# Display the Pods behind the stateless Service.
kubectl get endpointslice \
  -l kubernetes.io/service-name=web-app-stateless \
  -o jsonpath='{range .items[*].endpoints[*]}{.targetRef.name}{"\n"}{end}' |
  sort
```

??? example "Expected result"
    ```text
    web-app-stateless-5cc59678f-9j5wv
    web-app-stateless-5cc59678f-d8x9d
    web-app-stateless-5cc59678f-tfd8s
    ```

Query the Service through the Kubernetes API instead of using a fixed node or ClusterIP.

```bash
# Query the stateless Service through the Kubernetes API proxy endpoint.
timeout 30s kubectl get --raw /api/v1/namespaces/default/services/http:web-app-stateless:80/proxy/
```

??? example "Expected result"
    ```text
    This app is running in pod web-app-stateless-5cc59678f-9j5wv
    ```

### :material-application-edit-outline: Clean up the stateless release

Remove the release:

```bash
# Uninstall the stateless release with a bounded wait.
timeout 600s helm uninstall web-app-stateless --namespace default --wait --timeout 5m
```

??? example "Expected result"
    ```text
    release "web-app-stateless" uninstalled
    ```

Wait for the release resources to be removed:

```bash
# Verify stateless release cleanup.
timeout 180s sh -c '
  while test -n "$(kubectl get deployment,pod,service,serviceaccount \
    -l app.kubernetes.io/instance=web-app-stateless -o name)"; do
    sleep 3
  done
' && printf "Stateless release cleanup verified\n"
```

??? example "Expected result"
    ```text
    Stateless release cleanup verified
    ```

## :material-book-open-page-variant-outline: 7.3 StatefulSet Chart

### :material-application-edit-outline: Prepare the stateful chart

The source tree contains `web-app-stateful/image/Dockerfile`. The build is demonstration-only; the chart uses the existing
public `pvradu/web-app-stateful:v1` image.

Copy the chart from the pinned source tree.

```bash
# Assemble the stateful web application chart.
mkdir "$HOME/web-app-stateful" &&
  cp -R \
    "$HOME/kubernetes-tools/web-app-stateful/chart/." \
    "$HOME/web-app-stateful/"
```

??? example "Expected result"
    ```text
    No output.
    ```

### :material-application-edit-outline: Validate and package the chart

Lint the chart:

```bash
# Lint the stateful web application chart.
helm lint "$HOME/web-app-stateful"
```

??? example "Expected result"
    ```text
    ==> Linting /home/ubuntu/web-app-stateful
    [INFO] Chart.yaml: icon is recommended

    1 chart(s) linted, 0 chart(s) failed
    ```

Render and summarize the chart resources:

```bash
# Render and summarize the stateful chart resources.
helm template web-app-stateful "$HOME/web-app-stateful" \
  --namespace default \
  >/tmp/web-app-stateful.yaml &&
  grep '^kind:' /tmp/web-app-stateful.yaml |
  sort |
  uniq -c
```

??? example "Expected result"
    ```text
          1 kind: Service
          1 kind: StatefulSet
    ```

Package the chart:

```bash
# Package the stateful chart in its working directory.
helm package "$HOME/web-app-stateful" --destination "$HOME/web-app-stateful"
```

??? example "Expected result"
    ```text
    Successfully packaged chart and saved it to: /home/ubuntu/web-app-stateful/web-app-stateful-0.1.0.tgz
    ```

### :material-application-edit-outline: Deploy and inspect the stateful release

Install the packaged chart:

```bash
# Install the stateful web application release.
timeout 1200s helm install \
  web-app-stateful \
  "$HOME/web-app-stateful/web-app-stateful-0.1.0.tgz" \
  --namespace default \
  --wait \
  --timeout 10m \
  --rollback-on-failure
```

??? example "Expected result"
    ```text
    NAME: web-app-stateful
    NAMESPACE: default
    STATUS: deployed
    DESCRIPTION: Install complete
    ```

Inspect the release:

```bash
# Display the stateful release status.
helm status web-app-stateful --namespace default
```

??? example "Expected result"
    ```text
    NAME: web-app-stateful
    NAMESPACE: default
    STATUS: deployed
    web-app-stateful   StatefulSet 2/2
    ```

Display the StatefulSet:

```bash
# Display the stateful application controller.
kubectl get statefulset web-app-stateful
```

??? example "Expected result"
    ```text
    NAME                 READY   AGE
    web-app-stateful     2/2     50s
    ```

Display the Pods and their placement:

```bash
# Display the stateful application Pods.
kubectl get pods -l app=web-app-stateful -o wide
```

??? example "Expected result"
    ```text
    NAME                   READY   STATUS    NODE
    web-app-stateful-0     1/1     Running   k8s-worker1
    web-app-stateful-1     1/1     Running   k8s-worker2
    ```

Pod placement varies.

Display the headless Service that provides stable network identities:

```bash
# Display the stateful application's headless Service.
kubectl get service web-app-stateful
```

??? example "Expected result"
    ```text
    NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)
    web-app-stateful     ClusterIP   None         <none>        80/TCP
    ```

Display the two bound claims.

```bash
# Display stateful application claims and storage details.
kubectl get pvc -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,CAPACITY:.status.capacity.storage,ACCESS-MODES:.status.accessModes[*],STORAGECLASS:.spec.storageClassName --no-headers | grep '^data-web-app-stateful-'
```

??? example "Expected result"
    ```text
    data-web-app-stateful-0   Bound   1Gi   ReadWriteOnce   csi-rawfile-default
    data-web-app-stateful-1   Bound   1Gi   ReadWriteOnce   csi-rawfile-default
    ```

### :material-application-edit-outline: Verify data persistence

Query the first Pod directly through the API:

```bash
# Query the first stateful Pod through the API proxy.
timeout 30s kubectl get --raw /api/v1/namespaces/default/pods/web-app-stateful-0/proxy/
```

??? example "Expected result"
    ```text
    You've hit web-app-stateful-0
    Data stored on this pod: No data posted yet
    ```

Query the second Pod directly through the API:

```bash
# Query the second stateful Pod through the API proxy.
timeout 30s kubectl get --raw /api/v1/namespaces/default/pods/web-app-stateful-1/proxy/
```

??? example "Expected result"
    ```text
    You've hit web-app-stateful-1
    Data stored on this pod: No data posted yet
    ```

Write data to the second Pod:

```bash
# Store a training value in the second stateful Pod.
printf "Hey there!" | timeout 30s kubectl create --raw /api/v1/namespaces/default/pods/web-app-stateful-1/proxy/ -f -
```

??? example "Expected result"
    ```text
    Data stored on pod web-app-stateful-1
    ```

Verify the stored value:

```bash
# Verify the value stored by the second stateful Pod.
timeout 30s kubectl get --raw /api/v1/namespaces/default/pods/web-app-stateful-1/proxy/
```

??? example "Expected result"
    ```text
    You've hit web-app-stateful-1
    Data stored on this pod: Hey there!
    ```

Delete the Pod, wait for its replacement, and prove that its UID changed.

```bash
# Recreate the second Pod and verify that its UID changed.
OLD_UID=$(kubectl get pod web-app-stateful-1 \
  -o jsonpath='{.metadata.uid}') &&
  kubectl delete pod web-app-stateful-1 \
    --wait=true \
    --timeout=180s &&
  kubectl wait \
    --for=condition=Ready \
    pod/web-app-stateful-1 \
    --timeout=300s &&
  NEW_UID=$(kubectl get pod web-app-stateful-1 \
    -o jsonpath='{.metadata.uid}') &&
  test "$OLD_UID" != "$NEW_UID" &&
  printf "Pod recreated with a new UID\n"
```

??? example "Expected result"
    ```text
    pod "web-app-stateful-1" deleted from default namespace
    pod/web-app-stateful-1 condition met
    Pod recreated with a new UID
    ```

Verify that the replacement remounted the same data.

```bash
# Verify data persistence after Pod replacement.
timeout 30s kubectl get --raw /api/v1/namespaces/default/pods/web-app-stateful-1/proxy/
```

??? example "Expected result"
    ```text
    You've hit web-app-stateful-1
    Data stored on this pod: Hey there!
    ```

Display the claims and backing volumes.

```bash
# Display stateful claims and their associated persistent volumes.
kubectl get pvc \
  data-web-app-stateful-0 \
  data-web-app-stateful-1 &&
  kubectl get pv \
    -o custom-columns=NAME:.metadata.name,STATUS:.status.phase,CLAIM:.spec.claimRef.name,STORAGECLASS:.spec.storageClassName |
  grep 'data-web-app-stateful'
```

??? example "Expected result"
    ```text
    NAME                       STATUS   CAPACITY   STORAGECLASS
    data-web-app-stateful-0    Bound    1Gi        csi-rawfile-default
    data-web-app-stateful-1    Bound    1Gi        csi-rawfile-default
    pvc-92aa8221-...            Bound    data-web-app-stateful-1   csi-rawfile-default
    pvc-a44c36b2-...            Bound    data-web-app-stateful-0   csi-rawfile-default
    ```

### :material-application-edit-outline: Clean up the stateful release

Uninstall the release:

```bash
# Uninstall the stateful release with a bounded wait.
timeout 600s helm uninstall web-app-stateful --namespace default --wait --timeout 5m
```

??? example "Expected result"
    ```text
    release "web-app-stateful" uninstalled
    ```

Confirm that the StatefulSet claims remain:

```bash
# Display the retained StatefulSet claims.
kubectl get pvc data-web-app-stateful-0 data-web-app-stateful-1
```

??? example "Expected result"
    ```text
    NAME                       STATUS   CAPACITY   ACCESS MODES   STORAGECLASS
    data-web-app-stateful-0    Bound    1Gi        RWO            csi-rawfile-default
    data-web-app-stateful-1    Bound    1Gi        RWO            csi-rawfile-default
    ```

Delete the two retained claims:

```bash
# Delete the retained stateful application claims.
kubectl delete pvc data-web-app-stateful-0 data-web-app-stateful-1 --wait=true --timeout=180s
```

??? example "Expected result"
    ```text
    persistentvolumeclaim "data-web-app-stateful-0" deleted from default namespace
    persistentvolumeclaim "data-web-app-stateful-1" deleted from default namespace
    ```

Wait for PV reclamation and verify complete cleanup:

```bash
# Verify complete stateful release cleanup.
timeout 180s sh -c '
  while kubectl get pv \
    -o jsonpath="{range .items[*]}{.spec.claimRef.name}{\"\\n\"}{end}" |
    grep -q "^data-web-app-stateful-"; do
    sleep 3
  done
' &&
  test -z "$(kubectl get statefulset,pod,service \
    -l release=web-app-stateful -o name)" &&
  printf "Stateful release cleanup verified\n"
```

??? example "Expected result"
    ```text
    Stateful release cleanup verified
    ```

## :material-book-open-page-variant-outline: 7.4 Headlamp

### :material-application-edit-outline: Deploy Headlamp

Headlamp is a Kubernetes web interface. This lab deploys three replicas, exposes them through a LoadBalancer, and creates a
cluster-admin binding for its ServiceAccount.

!!! danger "Cluster-admin access"
    Use this configuration only for the lab. Do not print the token during unattended validation, and remove the release
    immediately after the exercise.

Add and refresh the Headlamp repository.

```bash
# Add the Headlamp chart repository.
timeout 60s helm repo add headlamp https://kubernetes-sigs.github.io/headlamp/
```

??? example "Expected result"
    ```text
    "headlamp" has been added to your repositories
    ```

Refresh the Headlamp repository:

```bash
# Refresh the Headlamp repository metadata.
timeout 180s helm repo update headlamp
```

??? example "Expected result"
    ```text
    ...Successfully got an update from the "headlamp" chart repository
    Update Complete.
    ```

Confirm the pinned version.

```bash
# Search for the pinned Headlamp chart version.
helm search repo headlamp/headlamp --version 0.45.0
```

??? example "Expected result"
    ```text
    NAME                CHART VERSION   APP VERSION   DESCRIPTION
    headlamp/headlamp   0.45.0          0.45.0        Headlamp is an easy-to-use and extensible Kubernetes web UI.
    ```

Validate the rendered resources against the API server.

```bash
# Run a server-side dry run of the Headlamp resources.
timeout 180s sh -c '
  helm template headlamp headlamp/headlamp \
    --version 0.45.0 \
    --namespace kube-system \
    --set replicaCount=3 \
    --set service.type=LoadBalancer |
    kubectl apply --request-timeout=60s --dry-run=server -f -
'
```

??? example "Expected result"
    ```text
    serviceaccount/headlamp created (server dry run)
    secret/oidc created (server dry run)
    clusterrolebinding.rbac.authorization.k8s.io/headlamp-admin created (server dry run)
    service/headlamp created (server dry run)
    deployment.apps/headlamp created (server dry run)
    ```

Install the pinned chart.

```bash
# Install Headlamp with three replicas and a LoadBalancer.
timeout 1200s helm install headlamp headlamp/headlamp \
  --version 0.45.0 \
  --namespace kube-system \
  --set replicaCount=3 \
  --set service.type=LoadBalancer \
  --wait \
  --timeout 10m \
  --rollback-on-failure
```

??? example "Expected result"
    ```text
    NAME: headlamp
    NAMESPACE: kube-system
    STATUS: deployed
    DESCRIPTION: Install complete
    ```

!!! note "Session TTL argument"
    Chart `0.40.1` could fail because its image did not support `-session-ttl=86400`. Pinned chart `0.45.0` renders this
    argument and starts successfully, so do not apply the old Deployment mutation.

### :material-application-edit-outline: Inspect the Headlamp release

Inspect the release:

```bash
# Display the Headlamp release status.
helm status headlamp --namespace kube-system
```

??? example "Expected result"
    ```text
    NAME: headlamp
    NAMESPACE: kube-system
    STATUS: deployed
    headlamp   Deployment 3/3
    headlamp   LoadBalancer 10.107.242.11
    ```

Wait for all three Pods to become ready:

```bash
# Wait for all Headlamp Pods.
kubectl wait \
  --for=condition=Ready \
  pod \
  -l app.kubernetes.io/name=headlamp \
  --namespace kube-system \
  --timeout=300s
```

??? example "Expected result"
    ```text
    pod/headlamp-78c9db77c6-68bzw condition met
    pod/headlamp-78c9db77c6-7phdk condition met
    pod/headlamp-78c9db77c6-flbv8 condition met
    ```

Display the Pods' images and placement:

```bash
# Display the Headlamp Pods.
kubectl get pods \
  -l app.kubernetes.io/name=headlamp \
  --namespace kube-system \
  -o custom-columns=NAME:.metadata.name,READY:.status.containerStatuses[0].ready,IMAGE:.spec.containers[0].image,NODE:.spec.nodeName \
  --no-headers
```

??? example "Expected result"
    ```text
    headlamp-78c9db77c6-68bzw   true   ghcr.io/headlamp-k8s/headlamp:v0.45.0   k8s-ctrl
    headlamp-78c9db77c6-7phdk   true   ghcr.io/headlamp-k8s/headlamp:v0.45.0   k8s-worker1
    headlamp-78c9db77c6-flbv8   true   ghcr.io/headlamp-k8s/headlamp:v0.45.0   k8s-worker2
    ```

Pod names and placement vary.

Wait for the external address:

```bash
# Wait for the Headlamp LoadBalancer address.
kubectl wait \
  --for=jsonpath='{.status.loadBalancer.ingress[0].ip}' \
  service/headlamp \
  --namespace kube-system \
  --timeout=180s
```

??? example "Expected result"
    ```text
    service/headlamp condition met
    ```

Display the LoadBalancer Service:

```bash
# Display the Headlamp LoadBalancer Service.
kubectl get service headlamp --namespace kube-system
```

??? example "Expected result"
    ```text
    NAME       TYPE           CLUSTER-IP      EXTERNAL-IP      PORT(S)
    headlamp   LoadBalancer   10.152.63.84   10.107.242.11   80:30764/TCP
    ```

Verify HTTP access through the LoadBalancer:

```bash
# Verify the Headlamp LoadBalancer endpoint.
HEADLAMP_IP=$(kubectl get service headlamp \
  --namespace kube-system \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}') &&
  curl --silent --show-error \
    --output /dev/null \
    --write-out "HTTP %{http_code}\n" \
    --max-time 30 \
    "http://$HEADLAMP_IP/"
```

??? example "Expected result"
    ```text
    HTTP 200
    ```

### :material-application-edit-outline: Verify Headlamp authorization

Confirm the intended authorization:

```bash
# Verify the Headlamp ServiceAccount cluster-admin authorization.
timeout 60s kubectl auth can-i "*" "*" --as=system:serviceaccount:kube-system:headlamp
```

??? example "Expected result"
    ```text
    yes
    ```

Validate a short-lived token without printing it:

```bash
# Validate a short-lived Headlamp token without exposing it.
HEADLAMP_TOKEN=$(timeout 60s kubectl create token headlamp \
  --namespace kube-system \
  --duration=10m) &&
  test "$(printf "%s" "$HEADLAMP_TOKEN" |
    awk -F. '{print NF}')" -eq 3 &&
  printf "Short-lived Headlamp token generated\n" &&
  unset HEADLAMP_TOKEN
```

??? example "Expected result"
    ```text
    Short-lived Headlamp token generated
    ```

!!! note "Browser login"
    Browser authentication is intentionally excluded from unattended validation. For an instructor-led demonstration,
    generate a new short-lived token immediately before login and do not save it in notes, shell history, or screenshots.

### :material-application-edit-outline: Clean up Headlamp

Remove Headlamp:

```bash
# Uninstall Headlamp with a bounded wait.
timeout 600s helm uninstall headlamp --namespace kube-system --wait --timeout 5m
```

??? example "Expected result"
    ```text
    release "headlamp" uninstalled
    ```

Verify that its namespaced resources and cluster-scoped binding are gone:

```bash
# Verify complete Headlamp cleanup.
timeout 180s sh -c '
  while test -n "$(kubectl get \
    deployment/headlamp \
    service/headlamp \
    serviceaccount/headlamp \
    secret/oidc \
    --namespace kube-system \
    --ignore-not-found \
    -o name)$(kubectl get clusterrolebinding/headlamp-admin \
    --ignore-not-found -o name)"; do
    sleep 3
  done
' && printf "Headlamp cleanup verified\n"
```

??? example "Expected result"
    ```text
    Headlamp cleanup verified
    ```

Remove the source tree, generated charts, packages, and temporary render files.

```bash
# Remove the Chapter 7 repository aliases created by this workflow.
helm repo remove stable bitnami headlamp
```

??? example "Expected result"
    ```text
    "stable" has been removed from your repositories
    "bitnami" has been removed from your repositories
    "headlamp" has been removed from your repositories
    ```

!!! danger "Delete only Chapter 7 artifacts"
    The next command permanently removes the listed Chapter 7 directories and temporary files. Do not add broader paths or
    remove the explicit path list.

```bash
# Remove Chapter 7 local artifacts.
rm -rf -- \
  "$HOME/kubernetes-tools" \
  "$HOME/web-app" \
  "$HOME/web-app-stateful" &&
  rm -f -- \
    /tmp/wordpress-chart-all.txt \
    /tmp/wordpress-values.yaml \
    /tmp/my-wordpress-blog.yaml \
    /tmp/web-app-stateless.yaml \
    /tmp/web-app-stateful.yaml \
    /tmp/headlamp.yaml
```

??? example "Expected result"
    ```text
    No output.
    ```

### :material-application-edit-outline: Verify final cleanup

Verify that no Chapter 7 resource or local directory remains:

```bash
# Verify final Chapter 7 cleanup.
test -z "$(helm repo list -o json |
  jq -r '.[] | select(.name == "stable" or .name == "bitnami" or .name == "headlamp") | .name')" &&
  test -z "$(helm list --all-namespaces \
    --filter '^(my-wordpress-blog|web-app-stateless|web-app-stateful|headlamp)$' -q)" &&
  test -z "$(kubectl get \
    deployment,statefulset,pod,service,serviceaccount,secret,configmap,networkpolicy,poddisruptionbudget,pvc \
    --all-namespaces -o name |
    grep -E '(my-wordpress-blog|web-app-stateless|web-app-stateful|headlamp)' || true)" &&
  test -z "$(kubectl get secret/oidc \
    --namespace kube-system --ignore-not-found -o name)" &&
  test -z "$(kubectl get clusterrolebinding/headlamp-admin \
    --ignore-not-found -o name)" &&
  test -z "$(kubectl get pv \
    -o jsonpath='{range .items[*]}{.spec.claimRef.name}{"\n"}{end}' |
    grep -E '(my-wordpress-blog|web-app-stateful)' || true)" &&
  test ! -e "$HOME/kubernetes-tools" &&
  test ! -e "$HOME/web-app" &&
  test ! -e "$HOME/web-app-stateful" &&
  printf "Chapter 7 cleanup verified\n"
```

??? example "Expected result"
    ```text
    Chapter 7 cleanup verified
    ```

Confirm final node readiness.

```bash
# Confirm final node readiness.
kubectl wait --for=condition=Ready nodes --all --timeout=300s
```

??? example "Expected result"
    ```text
    node/k8s-ctrl condition met
    node/k8s-worker1 condition met
    node/k8s-worker2 condition met
    ```

Display the final node status:

```bash
# Display the final cluster node status.
kubectl get nodes
```

??? example "Expected result"
    ```text
    NAME          STATUS   ROLES                  AGE   VERSION
    k8s-ctrl      Ready    control-plane,worker   19h   v1.35.7
    k8s-worker1   Ready    worker                 19h   v1.35.7
    k8s-worker2   Ready    worker                 19h   v1.35.7
    ```
