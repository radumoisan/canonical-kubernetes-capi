# 3. Keeping apps healthy !heading

## 3.1 ReplicaSets

A `ReplicaSet` enables us to achieve high availability by ensuring that a specified number of pod replicas are running at any one time.
In other words, a `ReplicaSet` makes sure that a pod or a homogeneous set of pods is always up and available.

If there are too many pods, the `ReplicaSet` terminates the additional pods. If there are too few, the `ReplicaSet` starts more pods.
Unlike manually created pods, the pods maintained by a `ReplicaSet` are automatically replaced if they fail, are deleted, or are terminated.

`ReplicaSet` is often abbreviated to `rs` as a shortcut in `kubectl` commands.

![service](assets/service1.png)

Now we'll create a `ReplicaSet` with this `~/resources/nginx-rs.yaml` definition:

```bash
cat ~/resources/nginx-rs.yaml

# output
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

The 3 most important things here are:
  * replica count: which specifies the desired number of pods that should be running
  * label selector: which determines what pods are in the ReplicaSets’s scope
  * pod template: which is used when creating new pod replicas

Create the `rs`:

```bash
kubectl create -f ~/resources/nginx-rs.yaml
```

Inspect the `rs`:

```bash
kubectl get rs nginx-rs -o wide

# output
NAME       DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES         SELECTOR
nginx-rs   3         3         3       9s    nginx        nginx:latest   app=nginx
```

```bash
kubectl describe rs nginx-rs

# output
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
  Normal  SuccessfulCreate  23s   replicaset-controller  Created pod: nginx-rs-b9s4g
  Normal  SuccessfulCreate  23s   replicaset-controller  Created pod: nginx-rs-6vldg
  Normal  SuccessfulCreate  23s   replicaset-controller  Created pod: nginx-rs-47z7s
```

```bash
kubectl get pods

# output
NAME             READY   STATUS    RESTARTS   AGE
nginx-rs-47z7s   1/1     Running   0          55s
nginx-rs-6vldg   1/1     Running   0          55s
nginx-rs-b9s4g   1/1     Running   0          55s
```

Now the application is highly available. They now need a Service to be accessed. We can recreate any type of Service that we
have used before. This is possible because of the Labels and Selectors. The newly create pods have the `app=nginx` label
and the Services we create before point to that label.

Recreate the `LoadBalancer` service:

```bash
kubectl create -f ~/resources/loadbalancer-service.yaml
```

Then, get the LoadBalancer IP address with:

```bash
kubectl get svc nginx-loadbalancer

# output
NAME                 TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
nginx-loadbalancer   LoadBalancer   10.152.188.44   10.219.64.11   8080:31731/TCP   21s
```

Then, try accessing the website a few times:

```bash
curl -s 10.219.64.11:8080 | pandoc -f html -t plain

#output
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

The traffic will now be load balanced between the 3 pods.

To verify that, we can go through the logs of each pod. To do that, run:

```bash
kubectl get pods

# output
NAME             READY   STATUS    RESTARTS   AGE
nginx-rs-47z7s   1/1     Running   0          33m
nginx-rs-6vldg   1/1     Running   0          33m
nginx-rs-b9s4g   1/1     Running   0          33m

kubectl logs nginx-rs-47z7s
kubectl logs nginx-rs-6vldg
kubectl logs nginx-rs-b9s4g
```

You can try to delete a Pod to see what happens. A new Pod should take its place in a few seconds. List the pods and
choose one to delete:

```bash
kubectl get pods
```

```bash
kubectl delete pod nginx-rs-47z7s
```

List the pods again, there is a new pod only some seconds old:

```bash
kubectl get pods

# output
NAME             READY   STATUS    RESTARTS   AGE
nginx-rs-6vldg   1/1     Running   0          34m
nginx-rs-b9s4g   1/1     Running   0          34m
nginx-rs-dgcn6   1/1     Running   0          11s
```

Delete the `rs` and the Service:

```bash
kubectl delete rs nginx-rs
```

```bash
kubectl delete svc nginx-loadbalancer
```

## 3.2 Deployments

All the functionality we have worked with so far can already cover a wide variety of app deployment use cases, but there is more
Kubernetes can do. It can also provide a clan way for applications that run in pods to be upgraded from version to version,
with NO downtime. This is provided through declarative updates for Pods and ReplicaSets.

Kubernetes provides the `Deployment` resource that sits on top of `ReplicaSets`, a declarative way to update Pods. You describe
a desired state in a Deployment object, and the Deployment controller changes the actual state to the desired state at a controlled rate.

![deployment](assets/deployment.png)


Let's take a look on how a Deployment definition looks like, the file is `~/resources/nginx-deploy.yaml`:

```bash
cat ~/resources/nginx-deploy.yaml

# output
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

Again, like in the case of `ReplicaSets`, the most important things are:
  * replica count: which specifies the desired number of pods that should be running
  * label selector: which determines what pods are in the ReplicaSets’s scope
  * pod template: which is used when creating new pod replicas


Create the Deployment:

```bash
kubectl create -f ~/resources/nginx-deploy.yaml
```

Inspect what was creates:

```bash
kubectl get deploy nginx-deploy -o wide

# output
NAME           READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES       SELECTOR
nginx-deploy   3/3     3            3           14s   nginx        nginx:1.28   app=nginx
```

```bash
kubectl describe deploy nginx-deploy

# output
Name:                   nginx-deploy
Namespace:              default
CreationTimestamp:      Wed, 18 Mar 2026 11:27:51 +0000
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
NewReplicaSet:   nginx-deploy-7f9c8bf8cd (3/3 replicas created)
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  24s   deployment-controller  Scaled up replica set nginx-deploy-7f9c8bf8cd from 0 to 3
```

```bash
kubectl get pods

# output
NAME                            READY   STATUS    RESTARTS   AGE
nginx-deploy-7f9c8bf8cd-5srlj   1/1     Running   0          39s
nginx-deploy-7f9c8bf8cd-nmw77   1/1     Running   0          39s
nginx-deploy-7f9c8bf8cd-tqx4m   1/1     Running   0          39s
...
```

So far everything looks similar to the  `ReplicaSets` case. The addition lies in how easily upgrades can be made. First, check the
rollout status. Initially, it should only tell that the deployment was created:

```bash
kubectl rollout status deploy nginx-deploy

# output
deployment "nginx-deploy" successfully rolled out
```

A Deployment `rollout` is a mechanism which allows performing application rolling upgrades. The rollout is triggered if and only if
the Deployment pod template is changed, for example if the image version is changed.

![deployment](assets/rolling_upgrade.png)

Suppose that we now want to update the nginx Pods to use the `nginx:1.29` image instead of the `nginx:1.28` image:

```bash
kubectl set image deploy nginx-deploy nginx=nginx:1.29

# output
deployment.extensions/nginx-deploy image updated
```

**NOTE**: Alternatively, the Deployment definition can be changed with `kubectl edit deploy nginx-deploy` in an interactive manner.
This stands true for all Kubernetes resource types.

Check Deployment status:

```bash
kubectl rollout status deploy nginx-deploy

# output
Waiting for deployment "nginx-deploy" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deploy" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deploy" rollout to finish: 1 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deploy" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deploy" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deploy" rollout to finish: 2 out of 3 new replicas have been updated...
Waiting for deployment "nginx-deploy" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "nginx-deploy" rollout to finish: 1 old replicas are pending termination...
deployment "nginx-deploy" successfully rolled out
#hit CTRL+C
```

```bash
kubectl get deploy -o wide

# output
NAME           READY   UP-TO-DATE   AVAILABLE   AGE    CONTAINERS   IMAGES       SELECTOR
nginx-deploy   3/3     3            3           105s   nginx        nginx:1.29   app=nginx
```

```bash
kubectl get pods

# output
NAME                            READY   STATUS    RESTARTS   AGE
nginx-deploy-578c8ff859-8t46m   1/1     Running   0          44s
nginx-deploy-578c8ff859-jrn9q   1/1     Running   0          45s
nginx-deploy-578c8ff859-spd85   1/1     Running   0          43s
...
```

```bash
kubectl describe deploy nginx-deploy

# output
Name:                   nginx-deploy
Namespace:              default
CreationTimestamp:      Wed, 18 Mar 2026 11:27:51 +0000
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
OldReplicaSets:  nginx-deploy-7f9c8bf8cd (0/0 replicas created)
NewReplicaSet:   nginx-deploy-578c8ff859 (3/3 replicas created)
Events:
  Type    Reason             Age    From                   Message
  ----    ------             ----   ----                   -------
  Normal  ScalingReplicaSet  2m19s  deployment-controller  Scaled up replica set nginx-deploy-7f9c8bf8cd from 0 to 3
  Normal  ScalingReplicaSet  62s    deployment-controller  Scaled up replica set nginx-deploy-578c8ff859 from 0 to 1
  Normal  ScalingReplicaSet  61s    deployment-controller  Scaled down replica set nginx-deploy-7f9c8bf8cd from 3 to 2
  Normal  ScalingReplicaSet  61s    deployment-controller  Scaled up replica set nginx-deploy-578c8ff859 from 1 to 2
  Normal  ScalingReplicaSet  60s    deployment-controller  Scaled down replica set nginx-deploy-7f9c8bf8cd from 2 to 1
  Normal  ScalingReplicaSet  60s    deployment-controller  Scaled up replica set nginx-deploy-578c8ff859 from 2 to 3
  Normal  ScalingReplicaSet  59s    deployment-controller  Scaled down replica set nginx-deploy-7f9c8bf8cd from 1 to 0
```

As can be seen everything is up-to-date and running. The image in use is `nginx:1.29`. The scaling process can also be viewed
on the deployment description `Events` section.

The same Services can be associated with the pods, same as before.

It's important to mention that there are two strategies for upgrading apps with Deployments:
  * `recreate` strategy: old pods are deleted before new ones are created
  * `RollingUpdate` strategy: replace pods step by step

The default one is `RollingUpdate`, the one we used in our case. This works if the application supports two versions of it running at
the same time, for a brief period. The major advantage of this strategy is that there is no downtime. With the `recreate` strategy
there is a downtime brief period between when then the last old version pod was deleted and the first new version pod comes up.

But let's say there is an issue with the current application version that was rolled out. Another powerful feature of `Deployments` is
that they can be rolled back to a previous revision if there are any issues.

Check and inspect the revision history:

```bash
kubectl rollout history deploy nginx-deploy

# output
deployment.apps/nginx-deploy
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

```bash
# this command does not do anything, it just inspects the revision
kubectl rollout history deploy nginx-deploy --revision=1

# output
deployment.apps/nginx-deploy with revision #1
Pod Template:
  Labels:	app=nginx
	pod-template-hash=7f9c8bf8cd
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
# this command does not do anything, it just inspects the revision
kubectl rollout history deploy nginx-deploy --revision=2

# output
deployment.apps/nginx-deploy with revision #2
Pod Template:
  Labels:	app=nginx
	pod-template-hash=578c8ff859
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

Rollback to the initial state:

```bash
kubectl rollout undo deploy nginx-deploy --to-revision=1

# output
deployment.extensions/nginx-deploy
```

Check how the Deployment looks like, it should have `nginx:1.28`, the old version:

```bash
kubectl describe deploy nginx-deploy

# output
Name:                   nginx-deploy
Namespace:              default
CreationTimestamp:      Wed, 18 Mar 2026 11:27:51 +0000
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
OldReplicaSets:  nginx-deploy-578c8ff859 (0/0 replicas created)
NewReplicaSet:   nginx-deploy-7f9c8bf8cd (3/3 replicas created)
Events:
  Type    Reason             Age                From                   Message
  ----    ------             ----               ----                   -------
  Normal  ScalingReplicaSet  3m48s              deployment-controller  Scaled up replica set nginx-deploy-7f9c8bf8cd from 0 to 3
  Normal  ScalingReplicaSet  2m31s              deployment-controller  Scaled up replica set nginx-deploy-578c8ff859 from 0 to 1
  Normal  ScalingReplicaSet  2m30s              deployment-controller  Scaled down replica set nginx-deploy-7f9c8bf8cd from 3 to 2
  Normal  ScalingReplicaSet  2m30s              deployment-controller  Scaled up replica set nginx-deploy-578c8ff859 from 1 to 2
  Normal  ScalingReplicaSet  2m29s              deployment-controller  Scaled down replica set nginx-deploy-7f9c8bf8cd from 2 to 1
  Normal  ScalingReplicaSet  2m29s              deployment-controller  Scaled up replica set nginx-deploy-578c8ff859 from 2 to 3
  Normal  ScalingReplicaSet  2m28s              deployment-controller  Scaled down replica set nginx-deploy-7f9c8bf8cd from 1 to 0
  Normal  ScalingReplicaSet  16s                deployment-controller  Scaled up replica set nginx-deploy-7f9c8bf8cd from 0 to 1
  Normal  ScalingReplicaSet  15s                deployment-controller  Scaled down replica set nginx-deploy-578c8ff859 from 3 to 2
  Normal  ScalingReplicaSet  13s (x4 over 15s)  deployment-controller  (combined from similar events): Scaled down replica set nginx-deploy-578c8ff859 from 1 to 0
```

If we check for `ReplicaSets`, we can see the `rs` that backs the `Deployment`:

```bash
kubectl get rs

# output
NAME                      DESIRED   CURRENT   READY   AGE
nginx-deploy-578c8ff859   0         0         0       2m55s
nginx-deploy-7f9c8bf8cd   3         3         3       4m12s
```

Concluding this chapter, we'll need to cleanup the whole deployment:

```bash
kubectl delete deploy nginx-deploy
```
