# 3. Keeping apps healthy

This chapter builds on [Chapter 2](2-networking.md). Complete it first so MetalLB is configured, the LoadBalancer Service
manifest is available, and `pandoc` is installed on the student machine.

Select the workload cluster kubeconfig before running this chapter:

```bash
# Select the workload cluster kubeconfig.
export KUBECONFIG=~/.kube/myk8scluster_config
```
??? example "Expected result"
    ```text
    No output.
    ```

Confirm that `kubectl` targets the workload cluster:

```bash
# Display the active Kubernetes context.
kubectl config current-context
```
??? example "Expected result"
    ```text
    myk8scluster-admin@myk8scluster
    ```

!!! info ""
    Generated resource names, IP addresses, ports, hashes, timestamps, and ages in expected results come from the
    validated lab environment and may differ in your environment. Use the values reported by your commands.

## :material-book-open-page-variant-outline: 3.1 ReplicaSets

A ReplicaSet maintains a specified number of Pod replicas. This helps an application tolerate Pod deletion or failure, but availability also depends on scheduling and application health.

If there are too many Pods, the ReplicaSet terminates the excess Pods. If there are too few, it creates replacements. Container failures are normally handled by the `kubelet`, which restarts containers within the existing Pod according to its restart policy.

ReplicaSets and Deployments maintain Pod count; they do not determine whether application code is healthy. Readiness probes control whether a Pod receives Service traffic, while liveness probes can cause an unresponsive container to restart.

`ReplicaSet` is often abbreviated as `rs` in `kubectl` commands.

![Service routing traffic to ReplicaSet Pods](assets/service1.png)

Display the ReplicaSet definition in `~/resources/nginx-rs.yaml`:

```bash
# Display the ReplicaSet definition.
cat ~/resources/nginx-rs.yaml
```
??? example "Expected result"
    ```yaml
    apiVersion: apps/v1
    kind: ReplicaSet
    metadata:
      name: nginx-rs
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - name: nginx
            image: nginx:latest
            ports:
            - containerPort: 80
    ```

The three most important fields are:

* replica count: the desired number of Pod replicas
* label selector: identifies the Pods managed by the ReplicaSet
* Pod template: defines the new Pod replicas

Create the `rs`:

```bash
# Create the ReplicaSet.
kubectl create -f ~/resources/nginx-rs.yaml
```
??? example "Expected result"
    ```text
    replicaset.apps/nginx-rs created
    ```

Wait for all three replicas to become Ready:

```bash
# Wait for the ReplicaSet to report three Ready replicas.
kubectl wait --for=jsonpath='{.status.readyReplicas}'=3 replicaset/nginx-rs --timeout=180s
```
??? example "Expected result"
    ```text
    replicaset.apps/nginx-rs condition met
    ```

Inspect the `rs`:

```bash
# List the ReplicaSet.
kubectl get rs nginx-rs -o wide
```
??? example "Expected result"
    ```text
    NAME       DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES         SELECTOR
    nginx-rs   3         3         3       55s   nginx        nginx:latest   app=nginx
    ```

```bash
# Describe the ReplicaSet.
kubectl describe rs nginx-rs
```
??? example "Expected result"
    ```text
    Name:         nginx-rs
    Namespace:    default
    Selector:     app=nginx
    Labels:       <none>
    Annotations:  <none>
    Replicas:     3 current / 3 desired
    Pods Status:  3 Running / 0 Waiting / 0 Succeeded / 0 Failed
    Pod Template:
      Labels:  app=nginx
      Containers:
       nginx:
        Image:         nginx:latest
        Port:          80/TCP
        Host Port:     0/TCP
        Environment:   <none>
        Mounts:        <none>
      Volumes:         <none>
      Node-Selectors:  <none>
      Tolerations:     <none>
    Events:
      Type    Reason            Age   From                   Message
      ----    ------            ----  ----                   -------
      Normal  SuccessfulCreate  79s   replicaset-controller  Created pod: nginx-rs-vgmmg
      Normal  SuccessfulCreate  79s   replicaset-controller  Created pod: nginx-rs-t98pg
      Normal  SuccessfulCreate  79s   replicaset-controller  Created pod: nginx-rs-qd655
    ```

```bash
# List the ReplicaSet pods.
kubectl get pods
```
??? example "Expected result"
    ```text
    NAME             READY   STATUS    RESTARTS   AGE
    nginx-rs-qd655   1/1     Running   0          119s
    nginx-rs-t98pg   1/1     Running   0          119s
    nginx-rs-vgmmg   1/1     Running   0          119s
    ```

The ReplicaSet now maintains three replicas. To access them consistently, recreate the LoadBalancer Service from
[Chapter 2](2-networking.md). Its selector matches the `app=nginx` label and routes traffic to eligible Ready endpoints.

Recreate the `LoadBalancer` service:

```bash
# Create the LoadBalancer service.
kubectl create -f ~/resources/loadbalancer-service.yaml
```
??? example "Expected result"
    ```text
    service/nginx-loadbalancer created
    ```

Wait for MetalLB to assign an external address:

```bash
# Wait for the LoadBalancer service to receive an IP address.
kubectl wait --for=jsonpath='{.status.loadBalancer.ingress[0].ip}' service/nginx-loadbalancer --timeout=180s
```
??? example "Expected result"
    ```text
    service/nginx-loadbalancer condition met
    ```

Get the LoadBalancer address:

```bash
# List the LoadBalancer service.
kubectl get svc nginx-loadbalancer
```
??? example "Expected result"
    ```text
    NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)          AGE
    nginx-loadbalancer   LoadBalancer   10.152.159.80   10.107.242.11   8080:30600/TCP   57s
    ```

Use the `EXTERNAL-IP` reported by your cluster to access the website.

!!! warning ""
    The LoadBalancer IP address may differ from the example output. Replace `<external-ip>` in the following command with
    the address reported by your cluster.

```bash
# Probe nginx through the LoadBalancer.
curl -s "http://<external-ip>:8080" | pandoc -f html -t plain
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

The Service can now distribute connections across the three eligible Pods.

Inspect the Pod logs to see which Pods received requests. Repeated requests may not reach every Pod:

```bash
# List the ReplicaSet pods.
kubectl get pods
```
??? example "Expected result"
    ```text
    NAME             READY   STATUS    RESTARTS   AGE
    nginx-rs-qd655   1/1     Running   0          4m27s
    nginx-rs-t98pg   1/1     Running   0          4m27s
    nginx-rs-vgmmg   1/1     Running   0          4m27s
    ```

```bash
# View prefixed logs from all ReplicaSet pods.
kubectl logs -l app=nginx --prefix=true
```
??? example "Expected result"
    ```text
    [pod/nginx-rs-qd655/nginx] 10.1.0.173 - - [08/Sep/2026:15:33:46 +0000] "GET / HTTP/1.1" 200 896 "-" "curl/8.5.0" "-"
    [pod/nginx-rs-t98pg/nginx] 2026/09/08 15:29:58 [notice] 1#1: nginx/1.31.5
    [pod/nginx-rs-vgmmg/nginx] 2026/09/08 15:29:51 [notice] 1#1: nginx/1.31.5
    ```

Delete a Pod to observe the ReplicaSet restore its desired replica count. First, list the Pods and choose one to delete:

```bash
# List the ReplicaSet pods.
kubectl get pods
```
??? example "Expected result"
    ```text
    NAME             READY   STATUS    RESTARTS   AGE
    nginx-rs-qd655   1/1     Running   0          6m9s
    nginx-rs-t98pg   1/1     Running   0          6m9s
    nginx-rs-vgmmg   1/1     Running   0          6m9s
    ```

```bash
# Delete a ReplicaSet pod.
kubectl delete pod <pod-name>
```
??? example "Expected result"
    ```text
    pod "nginx-rs-qd655" deleted from default namespace
    ```

Wait for the ReplicaSet to restore three Ready replicas:

```bash
# Wait for the replacement pod to become Ready.
kubectl wait --for=jsonpath='{.status.readyReplicas}'=3 replicaset/nginx-rs --timeout=180s
```
??? example "Expected result"
    ```text
    replicaset.apps/nginx-rs condition met
    ```

List the Pods again. A replacement Pod should appear with a recent age:

```bash
# List the ReplicaSet pods.
kubectl get pods
```
??? example "Expected result"
    ```text
    NAME             READY   STATUS    RESTARTS   AGE
    nginx-rs-t98pg   1/1     Running   0          7m30s
    nginx-rs-vgmmg   1/1     Running   0          7m30s
    nginx-rs-x26xp   1/1     Running   0          52s
    ```

Delete the `rs` and the Service:

```bash
# Delete the ReplicaSet.
kubectl delete rs nginx-rs
```
??? example "Expected result"
    ```text
    replicaset.apps "nginx-rs" deleted from default namespace
    ```

```bash
# Delete the LoadBalancer service.
kubectl delete svc nginx-loadbalancer
```
??? example "Expected result"
    ```text
    service "nginx-loadbalancer" deleted from default namespace
    ```

Confirm that the ReplicaSet and its Pods are gone:

```bash
# Check for remaining nginx ReplicaSets and Pods.
kubectl get rs,pod -l app=nginx -o name
```
??? example "Expected result"
    ```text
    No output.
    ```

Confirm that the LoadBalancer Service is gone:

```bash
# Check for the deleted LoadBalancer service.
kubectl get svc nginx-loadbalancer -o name --ignore-not-found
```
??? example "Expected result"
    ```text
    No output.
    ```

## :material-book-open-page-variant-outline: 3.2 Deployments

ReplicaSets cover many application deployment use cases, while Deployments add controlled, declarative updates. A Deployment can update an application from one version to another, often without downtime when the application and update settings support it.

The Deployment controller manages ReplicaSets, which manage Pods, and changes the observed state toward the desired state described in the Deployment.

![Deployment managing a ReplicaSet and Pods](assets/deployment.png)

Display the Deployment definition in `~/resources/nginx-deploy.yaml`:

```bash
# Display the Deployment definition.
cat ~/resources/nginx-deploy.yaml
```
??? example "Expected result"
    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-deploy
      labels:
        app: nginx
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: nginx
      template:
        metadata:
          labels:
            app: nginx
        spec:
          containers:
          - name: nginx
            image: nginx:1.28
            ports:
            - containerPort: 80
    ```

As with a ReplicaSet, the most important fields are:

* replica count: the desired number of Pod replicas
* label selector: identifies the Pods managed by the Deployment
* Pod template: defines the new Pod replicas

Create the Deployment:

```bash
# Create the Deployment.
kubectl create -f ~/resources/nginx-deploy.yaml
```
??? example "Expected result"
    ```text
    deployment.apps/nginx-deploy created
    ```

Wait for the initial rollout to complete:

```bash
# Wait for the Deployment rollout to complete.
kubectl rollout status deploy nginx-deploy --timeout=180s
```
??? example "Expected result"
    ```text
    deployment "nginx-deploy" successfully rolled out
    ```

Inspect what was created:

```bash
# List the Deployment.
kubectl get deploy nginx-deploy -o wide
```
??? example "Expected result"
    ```text
    NAME           READY   UP-TO-DATE   AVAILABLE   AGE    CONTAINERS   IMAGES       SELECTOR
    nginx-deploy   3/3     3            3           101s   nginx        nginx:1.28   app=nginx
    ```

```bash
# Describe the Deployment.
kubectl describe deploy nginx-deploy
```
??? example "Expected result"
    ```text
    Name:                   nginx-deploy
    Namespace:              default
    CreationTimestamp:      Tue, 08 Sep 2026 15:42:35 +0000
    Labels:                 app=nginx
    Annotations:            deployment.kubernetes.io/revision: 1
    Selector:               app=nginx
    Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
    StrategyType:           RollingUpdate
    MinReadySeconds:        0
    RollingUpdateStrategy:  25% max unavailable, 25% max surge
    Pod Template:
      Labels:  app=nginx
      Containers:
       nginx:
        Image:         nginx:1.28
        Port:          80/TCP
        Host Port:     0/TCP
        Environment:   <none>
        Mounts:        <none>
      Volumes:         <none>
      Node-Selectors:  <none>
      Tolerations:     <none>
    Conditions:
      Type           Status  Reason
      ----           ------  ------
      Available      True    MinimumReplicasAvailable
      Progressing    True    NewReplicaSetAvailable
    OldReplicaSets:  <none>
    NewReplicaSet:   nginx-deploy-65dfbbb4d7 (3/3 replicas created)
    Events:
      Type    Reason             Age   From                   Message
      ----    ------             ----  ----                   -------
      Normal  ScalingReplicaSet  2m8s  deployment-controller  Scaled up replica set nginx-deploy-65dfbbb4d7 from 0 to 3
    ```

```bash
# List the Deployment pods.
kubectl get pods
```
??? example "Expected result"
    ```text
    NAME                            READY   STATUS    RESTARTS   AGE
    nginx-deploy-65dfbbb4d7-2l7ss   1/1     Running   0          2m57s
    nginx-deploy-65dfbbb4d7-8l7dt   1/1     Running   0          2m57s
    nginx-deploy-65dfbbb4d7-ctln7   1/1     Running   0          2m57s
    ```

So far, the result resembles a ReplicaSet. A Deployment also provides controlled rollouts and revision history.

A Deployment rollout is triggered when its Pod template changes, such as when the container image changes. Scaling a Deployment changes its replica count but does not create a new revision.

![Deployment rolling update between ReplicaSet versions](assets/rolling_upgrade.png)

Suppose that we now want to update the nginx Pods to use the `nginx:1.29` image instead of the `nginx:1.28` image:

```bash
# Update the Deployment nginx image.
kubectl set image deploy nginx-deploy nginx=nginx:1.29
```
??? example "Expected result"
    ```text
    deployment.apps/nginx-deploy image updated
    ```

!!! tip "Alternative editing method"
    You can also edit the Deployment interactively with `kubectl edit deploy nginx-deploy`; the command supports many
    Kubernetes resource types.

Check Deployment status:

```bash
# Check the Deployment rollout status.
kubectl rollout status deploy nginx-deploy --timeout=180s
```
??? example "Expected result"
    ```text
    Waiting for deployment "nginx-deploy" rollout to finish: 1 old replicas are pending termination...
    Waiting for deployment "nginx-deploy" rollout to finish: 1 old replicas are pending termination...
    deployment "nginx-deploy" successfully rolled out
    ```

```bash
# List Deployments.
kubectl get deploy -o wide
```
??? example "Expected result"
    ```text
    NAME           READY   UP-TO-DATE   AVAILABLE   AGE     CONTAINERS   IMAGES       SELECTOR
    nginx-deploy   3/3     3            3           4m36s   nginx        nginx:1.29   app=nginx
    ```

```bash
# List the Deployment pods.
kubectl get pods
```
??? example "Expected result"
    ```text
    NAME                            READY   STATUS    RESTARTS   AGE
    nginx-deploy-86c8cd48f6-9s9q7   1/1     Running   0          73s
    nginx-deploy-86c8cd48f6-mk992   1/1     Running   0          91s
    nginx-deploy-86c8cd48f6-xxzgj   1/1     Running   0          82s
    ```

```bash
# Describe the Deployment.
kubectl describe deploy nginx-deploy
```
??? example "Expected result"
    ```text
    Name:                   nginx-deploy
    Namespace:              default
    CreationTimestamp:      Tue, 08 Sep 2026 15:42:35 +0000
    Labels:                 app=nginx
    Annotations:            deployment.kubernetes.io/revision: 2
    Selector:               app=nginx
    Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
    StrategyType:           RollingUpdate
    MinReadySeconds:        0
    RollingUpdateStrategy:  25% max unavailable, 25% max surge
    Pod Template:
      Labels:  app=nginx
      Containers:
       nginx:
        Image:         nginx:1.29
        Port:          80/TCP
        Host Port:     0/TCP
        Environment:   <none>
        Mounts:        <none>
      Volumes:         <none>
      Node-Selectors:  <none>
      Tolerations:     <none>
    Conditions:
      Type           Status  Reason
      ----           ------  ------
      Available      True    MinimumReplicasAvailable
      Progressing    True    NewReplicaSetAvailable
    OldReplicaSets:  nginx-deploy-65dfbbb4d7 (0/0 replicas created)
    NewReplicaSet:   nginx-deploy-86c8cd48f6 (3/3 replicas created)
    Events:
      Type    Reason             Age    From                   Message
      ----    ------             ----   ----                   -------
      Normal  ScalingReplicaSet  5m41s  deployment-controller  Scaled up replica set nginx-deploy-65dfbbb4d7 from 0 to 3
      Normal  ScalingReplicaSet  2m6s   deployment-controller  Scaled up replica set nginx-deploy-86c8cd48f6 from 0 to 1
      Normal  ScalingReplicaSet  117s   deployment-controller  Scaled down replica set nginx-deploy-65dfbbb4d7 from 3 to 2
      Normal  ScalingReplicaSet  117s   deployment-controller  Scaled up replica set nginx-deploy-86c8cd48f6 from 1 to 2
      Normal  ScalingReplicaSet  108s   deployment-controller  Scaled down replica set nginx-deploy-65dfbbb4d7 from 2 to 1
      Normal  ScalingReplicaSet  108s   deployment-controller  Scaled up replica set nginx-deploy-86c8cd48f6 from 2 to 3
      Normal  ScalingReplicaSet  98s    deployment-controller  Scaled down replica set nginx-deploy-65dfbbb4d7 from 1 to 0
    ```

The Deployment is up to date and uses the `nginx:1.29` image. The rollout process is also recorded in the `Events` section of the Deployment description.

The same Services continue to select these Pods because the `app=nginx` label is unchanged.

Deployments support two update strategies:

* `Recreate`: terminates all old Pods before creating new Pods
* `RollingUpdate`: gradually replaces old Pods with new Pods according to the rollout settings

`RollingUpdate` is the default strategy and allows old and new versions to overlap. It can avoid downtime when the application supports mixed versions and the readiness checks, capacity, and rollout settings are appropriate. `Recreate` normally causes a period without available Pods.

If an update causes problems, a Deployment can be manually rolled back to a previous revision.

Check and inspect the revision history:

```bash
# List the Deployment revision history.
kubectl rollout history deploy nginx-deploy
```
??? example "Expected result"
    ```text
    deployment.apps/nginx-deploy
    REVISION  CHANGE-CAUSE
    1         <none>
    2         <none>
    ```

```bash
# Inspect Deployment revision 1.
kubectl rollout history deploy nginx-deploy --revision=1
```
??? example "Expected result"
    ```text
    deployment.apps/nginx-deploy with revision #1
    Pod Template:
      Labels:	app=nginx
      pod-template-hash=65dfbbb4d7
      Containers:
       nginx:
        Image:	nginx:1.28
        Port:	80/TCP
        Host Port:	0/TCP
        Environment:	<none>
        Mounts:	<none>
      Volumes:	<none>
      Node-Selectors:	<none>
      Tolerations:	<none>
    ```

```bash
# Inspect Deployment revision 2.
kubectl rollout history deploy nginx-deploy --revision=2
```
??? example "Expected result"
    ```text
    deployment.apps/nginx-deploy with revision #2
    Pod Template:
      Labels:	app=nginx
      pod-template-hash=86c8cd48f6
      Containers:
       nginx:
        Image:	nginx:1.29
        Port:	80/TCP
        Host Port:	0/TCP
        Environment:	<none>
        Mounts:	<none>
      Volumes:	<none>
      Node-Selectors:	<none>
      Tolerations:	<none>
    ```

Revision `1` is the initial deployment version. Revision `2` is the upgraded version.

Roll back to the Pod template recorded in revision `1`. This creates a new revision rather than deleting the revision history:

```bash
# Roll back the Deployment to revision 1.
kubectl rollout undo deploy nginx-deploy --to-revision=1
```
??? example "Expected result"
    ```text
    deployment.apps/nginx-deploy rolled back
    ```

Wait for the rollback to complete:

```bash
# Wait for the rolled-back Deployment to become available.
kubectl rollout status deploy nginx-deploy --timeout=180s
```
??? example "Expected result"
    ```text
    deployment "nginx-deploy" successfully rolled out
    ```

Check the Deployment. It should now use the previous `nginx:1.28` image:

```bash
# Describe the Deployment.
kubectl describe deploy nginx-deploy
```
??? example "Expected result"
    ```text
    Name:                   nginx-deploy
    Namespace:              default
    CreationTimestamp:      Tue, 08 Sep 2026 15:42:35 +0000
    Labels:                 app=nginx
    Annotations:            deployment.kubernetes.io/revision: 3
    Selector:               app=nginx
    Replicas:               3 desired | 3 updated | 3 total | 3 available | 0 unavailable
    StrategyType:           RollingUpdate
    MinReadySeconds:        0
    RollingUpdateStrategy:  25% max unavailable, 25% max surge
    Pod Template:
      Labels:  app=nginx
      Containers:
       nginx:
        Image:         nginx:1.28
        Port:          80/TCP
        Host Port:     0/TCP
        Environment:   <none>
        Mounts:        <none>
      Volumes:         <none>
      Node-Selectors:  <none>
      Tolerations:     <none>
    Conditions:
      Type           Status  Reason
      ----           ------  ------
      Available      True    MinimumReplicasAvailable
      Progressing    True    NewReplicaSetAvailable
    OldReplicaSets:  nginx-deploy-86c8cd48f6 (0/0 replicas created)
    NewReplicaSet:   nginx-deploy-65dfbbb4d7 (3/3 replicas created)
    Events:
      Type    Reason             Age                From                   Message
      ----    ------             ----               ----                   -------
      Normal  ScalingReplicaSet  9m54s              deployment-controller  Scaled up replica set nginx-deploy-65dfbbb4d7 from 0 to 3
      Normal  ScalingReplicaSet  6m19s              deployment-controller  Scaled up replica set nginx-deploy-86c8cd48f6 from 0 to 1
      Normal  ScalingReplicaSet  6m10s              deployment-controller  Scaled down replica set nginx-deploy-65dfbbb4d7 from 3 to 2
      Normal  ScalingReplicaSet  6m10s              deployment-controller  Scaled up replica set nginx-deploy-86c8cd48f6 from 1 to 2
      Normal  ScalingReplicaSet  6m1s               deployment-controller  Scaled down replica set nginx-deploy-65dfbbb4d7 from 2 to 1
      Normal  ScalingReplicaSet  6m1s               deployment-controller  Scaled up replica set nginx-deploy-86c8cd48f6 from 2 to 3
      Normal  ScalingReplicaSet  5m51s              deployment-controller  Scaled down replica set nginx-deploy-65dfbbb4d7 from 1 to 0
      Normal  ScalingReplicaSet  52s                deployment-controller  Scaled up replica set nginx-deploy-65dfbbb4d7 from 0 to 1
      Normal  ScalingReplicaSet  50s                deployment-controller  Scaled down replica set nginx-deploy-86c8cd48f6 from 3 to 2
      Normal  ScalingReplicaSet  46s (x4 over 50s)  deployment-controller  (combined from similar events): Scaled down replica set nginx-deploy-86c8cd48f6 from 1 to 0
    ```

List the ReplicaSets managed by the Deployment. The current ReplicaSet has three replicas, while the previous one remains at zero for revision history:

```bash
# List ReplicaSets.
kubectl get rs
```
??? example "Expected result"
    ```text
    NAME                      DESIRED   CURRENT   READY   AGE
    nginx-deploy-65dfbbb4d7   3         3         3       11m
    nginx-deploy-86c8cd48f6   0         0         0       8m12s
    ```

To conclude the chapter, clean up the Deployment:

```bash
# Delete the Deployment.
kubectl delete deploy nginx-deploy
```
??? example "Expected result"
    ```text
    deployment.apps "nginx-deploy" deleted from default namespace
    ```

Confirm that the Deployment and its managed resources are gone:

```bash
# Check for remaining nginx Deployments, ReplicaSets, and Pods.
kubectl get deploy,rs,pod -l app=nginx -o name
```
??? example "Expected result"
    ```text
    No output.
    ```
