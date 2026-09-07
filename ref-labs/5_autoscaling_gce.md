# 5. Autoscaling !heading

Kubernetes can autoscale your application based on load. Numeric based resources like `CPU` and `Memory` can be used for this.
For example, when the CPU reaches a certain threshold, the application can be scaled without human interaction, in an automated manner.

The `HorizontalPodAutoscaler` normally fetches metrics from a series of aggregated APIs (metrics.k8s.io, custom.metrics.k8s.io,
and external.metrics.k8s.io). The `metrics.k8s.io` API is usually provided by `metrics-server`, which needs to be launched separately.

![roles](assets/hpa1.png)

Resource usage metrics, such as container CPU and memory usage, are available in Kubernetes through the `Metrics API`. These metrics can be
accessed either directly by the user with the `kubectl top` command, or by a controller in the cluster, for example `HorizontalPodAutoscaler`,
to make decisions. Provided by the `metrics-server`.

`Metrics Server` collects resource metrics from Kubelets and exposes them in Kubernetes API Server through `Metrics API` for use by
`Horizontal Pod Autoscaler` and `VerticalPodAutoscaler`. Metrics Server is not meant for non-autoscaling purposes. For example, don't
use it to forward metrics to monitoring solutions, or as a source of monitoring solution metrics. For this Prometheus can be used.

The `HorizontalPodAutoscaler` is the Kubernetes object that scales a `Deployment` or `ReplicaSet`. It is a control loop that periodically
checks pod metrics from the `metrics-server`, calculates the number of replicas required to meet the target metric value configured by the user in
the `HPA` resource, and updates the `REPLICAS` field in the target Deployment resource.

So the autoscaling process works in 3 steps:
  * collect metrics from all the pods managed by the resource object (deployment, replicaSet) : via `metrics-server`
  * calculate the number of pods needed to match the specified target value
  * update the replicas field in the resource object


![roles](assets/hpa2.png)


More information on the Resource metrics pipeline can be found here:

https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/


## 5.1 Autoscale a Deployment resource

Create an nginx deployment, this will be the scaled application:

```bash
kubectl create deployment nginx-hpa --image=nginx
```

```bash
kubectl expose deployment nginx-hpa --port=80
```

```bash
kubectl set resources deployment nginx-hpa --requests=cpu=100m
```

Create a `HPA` that will autoscale when the pod `CPU` load reaches 30%, but keep the pods between 1 pod minimum and 5 pods
at max. In this case the pod replicas will not exeed 5 even if the `CPU` is above 30%:

```bash
kubectl autoscale deployment nginx-hpa --cpu 30% --min=1 --max=5
```

Run a load generator that will do `wget` continuously on the nginx app:

```bash
kubectl run -i --tty load-generator --image=busybox /bin/sh
```

```bash
# inside loadgenerator container
while true; do wget -q -O- http://nginx-hpa; done
```

Open a new tab and log in the public machine again. Do a watch getting the `HPA` status. Wait a minute or two for the load to increase:

```bash
watch kubectl get hpa
NAME        REFERENCE              TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   Deployment/nginx-hpa   36%/30%   1         5         2          4m
```

Because the CPU utilization went over 30%, it's 36% now, a new replica was added and there are 2 now. Please note that in your case the
load can be higher, and the replica count can be higher.

A new nginx pod was added and the app was autoscaled:

```bash
kubectl get pods

# output
NAME                        READY   STATUS    RESTARTS   AGE
load-generator              1/1     Running   0          2m12s
nginx-hpa-998cbd759-2zzng   1/1     Running   0          3m14s
nginx-hpa-998cbd759-gsxbl   1/1     Running   0          82s
nginx-hpa-998cbd759-rjs8n   1/1     Running   0          82s
...
```

If you go back on the first tab and stop the `wget` command, the CPU utilization will drop below 30% and the `REPLICAS` field will be set to 1.
The scale down operation is performed every five minutes, so you may not see this right away.

```bash
kubectl get hpa

# output
NAME        REFERENCE              TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   Deployment/nginx-hpa   cpu: 0%/30%   1         5         1          10m
```

Inspect the `HPA` for a minute, if you find something interesting don't hesitate to talk with the trainer about it:

```bash
kubectl describe hpa nginx-hpa
```

You can check what happened to the HorizontalPodAutoscaler using:

```bash
kubectl events --for hpa/nginx-hpa

# output
LAST SEEN   TYPE      REASON                         OBJECT                              MESSAGE
9m23s       Normal    SuccessfulRescale              HorizontalPodAutoscaler/nginx-hpa   New size: 3; reason: cpu resource utilization (percentage of request) above target
2m8s        Normal    SuccessfulRescale              HorizontalPodAutoscaler/nginx-hpa   New size: 2; reason: All metrics below target
113s        Normal    SuccessfulRescale              HorizontalPodAutoscaler/nginx-hpa   New size: 1; reason: All metrics below target
```

Default behavior of the `HorizontalPodAutoscaler` is desribed here:

```bash
behavior:
  scaleDown:
    stabilizationWindowSeconds: 300
    policies:
    - type: Percent
      value: 100
      periodSeconds: 15
  scaleUp:
    stabilizationWindowSeconds: 0
    policies:
    - type: Percent
      value: 100
      periodSeconds: 15
    - type: Pods
      value: 4
      periodSeconds: 15
    selectPolicy: Max
```

Do a cleanup on the created resources:

```bash
kubectl delete deploy nginx-hpa
kubectl delete svc nginx-hpa
kubectl delete pod load-generator
kubectl delete hpa nginx-hpa
```

For more information on HPAs, please visit:

https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
