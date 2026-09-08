# 5. Autoscaling !heading

Kubernetes can automatically adjust an application's replica count based on observed load. Resource metrics such as CPU and memory
can drive this scaling. For CPU utilization, Kubernetes compares measured usage with the containers' CPU requests.

The `HorizontalPodAutoscaler` can retrieve metrics from aggregated APIs such as `metrics.k8s.io`, `custom.metrics.k8s.io`, and
`external.metrics.k8s.io`. The `metrics.k8s.io` API is commonly provided by Metrics Server, an add-on installed in the cluster.

![roles](assets/hpa1.png)

Resource metrics, such as container CPU and memory usage, are available through the Metrics API. Users can query these metrics with
`kubectl top`, and controllers such as the `HorizontalPodAutoscaler` can use them to make scaling decisions.

Metrics Server collects resource metrics from kubelets and exposes them through the Kubernetes API server. It supports resource
autoscaling and `kubectl top`, but it is not designed for long-term monitoring or alerting. Use a dedicated monitoring system such as
Prometheus for those purposes.

The `HorizontalPodAutoscaler`, abbreviated as `HPA`, adjusts the desired replica count of a `Deployment` or another workload that
supports the scale subresource. Its control loop periodically reads Pod metrics, calculates the replica count required to meet the
configured target, and updates the target workload.

The autoscaling process has three main steps:
  * Collect metrics for the Pods managed by the target workload.
  * Calculate the replica count required to meet the configured target.
  * Update the desired replica count of the target workload.


![roles](assets/hpa2.png)


For more information about the resource metrics pipeline, visit:

https://kubernetes.io/docs/tasks/debug-application-cluster/resource-metrics-pipeline/


## 5.1 Autoscale a Deployment resource

Create an nginx Deployment as the application to scale:

```bash
kubectl create deployment nginx-hpa --image=nginx
```

Expose the Deployment through a Service:

```bash
kubectl expose deployment nginx-hpa --port=80
```

Set a CPU request because the utilization target is calculated as a percentage of requested CPU:

```bash
kubectl set resources deployment nginx-hpa --requests=cpu=100m
```

Create an `HPA` with a target average CPU utilization of 30% of requested CPU. Keep the Deployment between one and five replicas;
the `HPA` will not scale it above five replicas even when utilization remains above the target:

```bash
kubectl autoscale deployment nginx-hpa --cpu 30% --min=1 --max=5
```

Run a load-generator Pod that continuously sends requests to the nginx Service:

```bash
kubectl run -i --tty load-generator --image=busybox /bin/sh
```

```bash
# inside loadgenerator container
while true; do wget -q -O- http://nginx-hpa; done
```

Open a second terminal and connect to the student machine again. Watch the `HPA` status and wait a minute or two for the load to increase:

```bash
watch kubectl get hpa
NAME        REFERENCE              TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   Deployment/nginx-hpa   36%/30%   1         5         2          4m
```

The current average CPU utilization is 36% of requested CPU, which is above the 30% target, so the `HPA` increased the replica count
to two. The utilization and resulting replica count may differ in your environment.

Confirm that additional nginx Pods were created:

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

Return to the first terminal and stop the `wget` command. As CPU utilization falls below the target, the `HPA` eventually scales the
Deployment down to its minimum of one replica. The default scale-down stabilization window is 300 seconds, so this is not immediate.

```bash
kubectl get hpa

# output
NAME        REFERENCE              TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
nginx-hpa   Deployment/nginx-hpa   cpu: 0%/30%   1         5         1          10m
```

Inspect the `HPA` details and discuss any questions with the trainer:

```bash
kubectl describe hpa nginx-hpa
```

View recent scaling decisions in the `HPA` events:

```bash
kubectl events --for hpa/nginx-hpa

# output
LAST SEEN   TYPE      REASON                         OBJECT                              MESSAGE
9m23s       Normal    SuccessfulRescale              HorizontalPodAutoscaler/nginx-hpa   New size: 3; reason: cpu resource utilization (percentage of request) above target
2m8s        Normal    SuccessfulRescale              HorizontalPodAutoscaler/nginx-hpa   New size: 2; reason: All metrics below target
113s        Normal    SuccessfulRescale              HorizontalPodAutoscaler/nginx-hpa   New size: 1; reason: All metrics below target
```

The default scaling behavior of the `HorizontalPodAutoscaler` is equivalent to this configuration:

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

Delete the resources created in this exercise:

```bash
kubectl delete deploy nginx-hpa
kubectl delete svc nginx-hpa
kubectl delete pod load-generator
kubectl delete hpa nginx-hpa
```

For more information on HPAs, please visit:

https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/
https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/
