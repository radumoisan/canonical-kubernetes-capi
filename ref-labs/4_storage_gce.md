# 4. Storage and User Data !heading

Applications can read and write data in a container's filesystem, but that data is isolated from other containers and is lost
when the container is replaced. Pods often need to share data among containers or retain data beyond a container's lifetime.

## 4.1 Volumes

Kubernetes volumes make data available to containers in a Pod. A volume can be mounted by multiple containers in that Pod.
Some volume types are ephemeral and tied to the Pod's lifetime, while persistent storage can outlive individual Pods.

Kubernetes supports many volume types. Examples include:
  * `emptyDir`: starts empty when a Pod is assigned to a node and exists as long as that Pod remains on the node. Its data survives container restarts but is deleted when the Pod is removed. By default, it uses the storage medium that backs the node's ephemeral storage.
  * `hostPath`: mounts a file or directory from the host node's filesystem. It can provide access to host resources such as `/sys`, but it ties the Pod to a specific node and can introduce security risks.
  * `fc`: mounts an existing Fibre Channel block storage volume into a Pod.
  * `image`: makes an OCI object, such as a container image or artifact, available to a Pod as a read-only volume.
  * `nfs`: mounts an existing NFS share into a Pod.
  * `iscsi`: mounts an existing iSCSI volume into a Pod.

Let's create a Pod with two containers and a shared `emptyDir` volume. The manifest is available at
`~/resources/multi-container-pod.yaml`:

```bash
cat ~/resources/multi-container-pod.yaml

# output
apiVersion: v1
kind: Pod
metadata:
  name: two-containers
  labels:
    app: two-containers
spec:
  restartPolicy: Never
  volumes:
  - name: shared-data
    emptyDir: {}
  containers:
  - name: nginx-container
    image: nginx:latest
    volumeMounts:
    - name: shared-data
      mountPath: /usr/share/nginx/html
  - name: debian-container
    image: debian
    volumeMounts:
    - name: shared-data
      mountPath: /pod-data
    command: ["/bin/sh"]
    args: ["-c", "echo Hello from the debian container > /pod-data/index.html; sleep 900000"]
```

The volume is named `shared-data`. Each container references it by name in its `volumeMounts` entry. `mountPath` specifies where
the volume is available inside that container. The paths `/usr/share/nginx/html/index.html` and `/pod-data/index.html` therefore
refer to the same shared file. Review the manifest and discuss any questions with the trainer.

Create the Pod and a Service for it. The manifest files are already provisioned at `~/resources/multi-container-pod.yaml` and
`~/resources/multi-container-pod-service.yaml`:

```bash
kubectl create -f ~/resources/multi-container-pod.yaml
```

```bash
kubectl create -f ~/resources/multi-container-pod-service.yaml
```

Get the ClusterIP, open a shell on a node, and send a request from there:

```bash
kubectl get svc two-containers-svc

# output
NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
two-containers-svc   ClusterIP   10.152.183.236   <none>        8080/TCP   38s
```

Open a shell on one of the nodes:

```bash
lxc shell k8s-worker1
```

```bash
curl 10.152.183.236:8080

# output
Hello from the debian container
```

The two containers work together through the shared volume. More complex applications can use the same pattern.

Return to the student machine and delete the Service and Pod:

```bash
# exit back to student machine
exit
```

```bash
# on student machine
kubectl delete svc two-containers-svc
kubectl delete pod two-containers
```

## 4.2 ConfigMaps

`ConfigMaps` allow developers to decouple configuration options from the app source code or container image.

![roles](assets/config_map.png)

There are four ways to use a ConfigMap to configure a container in a Pod:
  * Set the container command and arguments.
  * Set environment variables for the container.
  * Mount ConfigMap keys as files in a read-only volume.
  * Run code in the Pod that uses the Kubernetes API to read the ConfigMap.

When a ConfigMap mounted as a volume is updated, its projected keys are eventually updated. The kubelet checks the mounted ConfigMap
during periodic synchronization. ConfigMaps consumed as environment variables are not updated automatically and require a Pod restart.

**NOTE**: A `ConfigMap` does not provide secrecy or encryption. For confidential data, use a `Secret` and configure appropriate
access controls and encryption at rest.

Create a `ConfigMap` with literal values:

```bash
kubectl create configmap test-configmap --from-literal=val1=dan \
--from-literal=val2=bill --from-literal=val3=ben
```

Inspect the `ConfigMap`:

```bash
kubectl describe configmap test-configmap

# output
Name:         test-configmap
Namespace:    default
Labels:       <none>
Annotations:  <none>

Data
====
val1:
----
dan
val2:
----
bill
val3:
----
ben
Events:  <none>
```

The following Pod manifest imports all entries from the `ConfigMap` as environment variables with the `CONFIG_DATA_` prefix:

```bash
apiVersion: v1
kind: Pod
metadata:
  name: configmap-pod
spec:
  containers:
  - name: pod-with-configmap
    image: alpine
    command: ["sleep", "999999"]
    envFrom:
    - prefix: CONFIG_DATA_
      configMapRef:
        name: test-configmap
```

```bash
kubectl create -f ~/resources/pod-with-configmap.yaml
```

Check whether the Pod received the values:

```bash
kubectl exec configmap-pod -- env | grep CONFIG_DATA

# output
...
CONFIG_DATA_val1=dan
CONFIG_DATA_val2=bill
CONFIG_DATA_val3=ben
...
```

Delete the pod:

```bash
kubectl delete pod configmap-pod
```

For more information on `ConfigMaps`, please visit:

https://kubernetes.io/docs/concepts/configuration/configmap/



## 4.3 Secrets

`Secrets` keep sensitive data such as credentials, encryption keys, and tokens separate from application code. Their API
representation contains base64-encoded values; base64 is encoding, not encryption. Protect Secrets with appropriate access controls
and encryption at rest.

Secrets can be created with `kubectl` or from a manifest. This lab uses the CLI method:

```bash
kubectl create secret generic bob-secret --from-literal=username='bob' \
--from-literal=password='Passw0rd'
```

**NOTE**: `kubectl create secret` encodes the supplied literal values. In a manifest, use `stringData` for unencoded strings or
`data` for base64-encoded values.

Inspect the Secret metadata:

```bash
kubectl get secret bob-secret

# output
NAME         TYPE     DATA   AGE
bob-secret   Opaque   2      10s
```

`type: Opaque` means that the Secret has no required structure and can contain arbitrary key-value pairs.
Other Secret types include `kubernetes.io/service-account-token`, `kubernetes.io/dockercfg`,
`kubernetes.io/dockerconfigjson`, `kubernetes.io/basic-auth`, `kubernetes.io/ssh-auth`, and `kubernetes.io/tls`.
For more information about Secret types, visit:

https://kubernetes.io/docs/concepts/configuration/secret/#secret-types

```bash
kubectl describe secret bob-secret

# output
Name:         bob-secret
Namespace:    default
Labels:       <none>
Annotations:  <none>

Type:  Opaque

Data
====
password:  8 bytes
username:  3 bytes
```

Display the Secret's YAML representation to see the base64-encoded data:

```bash
kubectl get secret bob-secret -o yaml
```

Now create a Pod that accesses the `Secret` through environment variables. The manifest is available at
`~/resources/pod-with-secrets.yaml`:

```bash
cat ~/resources/pod-with-secrets.yaml

# output
apiVersion: v1
kind: Pod
metadata:
  name: pod-with-secrets
spec:
  containers:
  - name: container-with-secrets
    image: nginx
    env:
    - name: SECRET_USERNAME
      valueFrom:
        secretKeyRef:
          name: bob-secret
          key: username
    - name: SECRET_PASSWORD
      valueFrom:
        secretKeyRef:
          name: bob-secret
          key: password
```

Create the Pod:

```bash
kubectl create -f ~/resources/pod-with-secrets.yaml
```

Wait for the Pod to become ready, open a shell in it, and verify that the Secret values were passed:

```bash
kubectl exec -it pod-with-secrets -- /bin/bash
```

```bash
root@pod-with-secrets:/# printenv | grep SECRET

# output
SECRET_PASSWORD=Passw0rd
SECRET_USERNAME=bob
```

An application, such as a database, can now read its credentials from these environment variables.

Exit the Pod and delete the resources you created:

```bash
root@pod-with-secrets:/# exit
```

```bash
kubectl delete pod pod-with-secrets
kubectl delete secret bob-secret
```


## 4.4 PersistentVolumes, PersistentVolumeClaims and StorageClasses

An `emptyDir` volume is limited to a Pod's lifetime, while `hostPath` ties a workload to storage on a specific node. Applications
that need durable storage should be able to request it without depending directly on backend details.

`PersistentVolumes`, `PersistentVolumeClaims`, and `StorageClasses` provide this abstraction. A `StorageClass` describes a class
of storage and its provisioner, while a `PersistentVolumeClaim` requests storage. The provisioner can then create a
`PersistentVolume` dynamically.

**NOTE**: This chapter abbreviates PersistentVolumes as `PVs`, PersistentVolumeClaims as `PVCs`, and StorageClasses as `SCs`.

`PVs` are cluster storage resources whose lifecycle is independent of any Pod. A workload requests storage through a `PVC`,
which Kubernetes binds to a suitable `PV`.

![roles](assets/pvc.png)

Administrators can create `PVs` statically when storage is pre-provisioned. Alternatively, an `SC` can provision a matching `PV`
dynamically when a workload makes a request through a `PVC`.

Your cluster uses the `csi-rawfile-default` StorageClass backed by node-local storage. Display the configured default StorageClass:

```bash
kubectl get sc

# output
NAME                            PROVISIONER              RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
csi-rawfile-default (default)   rawfile.csi.openebs.io   Delete          WaitForFirstConsumer   true                   48m
```

Display details about the StorageClass:

```bash
kubectl describe sc csi-rawfile-default

# output
Name:                  csi-rawfile-default
IsDefaultClass:        Yes
Annotations:           meta.helm.sh/release-name=ck-storage,meta.helm.sh/release-namespace=kube-system,storageclass.kubernetes.io/is-default-class=true
Provisioner:           rawfile.csi.openebs.io
Parameters:            <none>
AllowVolumeExpansion:  True
MountOptions:          <none>
ReclaimPolicy:         Delete
VolumeBindingMode:     WaitForFirstConsumer
Events:                <none>
```

For more info on storage classes please visit:

https://kubernetes.io/docs/concepts/storage/storage-classes/

https://documentation.ubuntu.com/canonical-kubernetes/latest/snap/howto/storage/

The cluster can now dynamically provision volumes in response to workload requests.

Create a `PVC` using this `SC`. The manifest is available at `~/resources/hostpath-pvc.yaml`:

```bash
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: hostpath-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 10Gi
  storageClassName: csi-rawfile-default
```

A `PVC` requests storage and is bound to a matching `PV`. Create the `PVC`:

```bash
kubectl create -f ~/resources/hostpath-pvc.yaml
```

```bash
kubectl get pvc

# output
NAME           STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS          VOLUMEATTRIBUTESCLASS   AGE
hostpath-pvc   Pending                                      csi-rawfile-default   <unset>                 10s
```

```bash
kubectl describe pvc hostpath-pvc

# output
Name:          hostpath-pvc
Namespace:     default
StorageClass:  csi-rawfile-default
Status:        Pending
Volume:
Labels:        <none>
Annotations:   <none>
Finalizers:    [kubernetes.io/pvc-protection]
Capacity:
Access Modes:
VolumeMode:    Filesystem
Used By:       <none>
Events:
  Type    Reason                Age               From                         Message
  ----    ------                ----              ----                         -------
  Normal  WaitForFirstConsumer  5s (x4 over 40s)  persistentvolume-controller  waiting for first consumer to be created before binding
```

Because the StorageClass uses `WaitForFirstConsumer`, the `PVC` remains pending until a Pod uses it.

```bash
kubectl get pv

# output
No resources found
```

The provisioner creates the volume after a Pod that uses the claim is created.

Create a Pod that uses the `PVC` with `~/resources/busybox-with-pv.yaml`:

```bash
apiVersion: v1
kind: Pod
metadata:
  name: busybox
  namespace: default
spec:
  containers:
    - image: busybox
      command:
        - sleep
        - "3600"
      imagePullPolicy: IfNotPresent
      name: busybox
      volumeMounts:
        - mountPath: "/pv"
          name: testvolume
  restartPolicy: Always
  volumes:
    - name: testvolume
      persistentVolumeClaim:
        claimName: hostpath-pvc
```

```bash
kubectl create -f ~/resources/busybox-with-pv.yaml
```

After the Pod is created, check the PersistentVolumeClaim status again:

```bash
kubectl get pvc

# output
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS          VOLUMEATTRIBUTESCLASS   AGE
hostpath-pvc   Bound    pvc-885f7ff8-8dbc-4f00-bd56-f92edbfa2e3c   10Gi       RWO            csi-rawfile-default   <unset>                 3m37s
```

Check inside the Pod to verify that the volume was mounted:

```bash
kubectl exec busybox -- mount | grep pv

# output
/dev/loop3 on /pv type ext4 (rw,relatime)
```

If the new device appears, the `PV` was successfully provisioned and mounted.

Write data to the `PV` by creating a file named `hello-world.txt`.

```bash
kubectl exec busybox --  touch /pv/hello-world.txt
```

Open a shell in the Pod and write text to the file.

```bash
kubectl exec -it busybox -- sh
```

```bash
echo "Hello world from busybox pod!" > /pv/hello-world.txt
```

```bash
cat /pv/hello-world.txt

# output
Hello world from busybox pod!
```

Exit the Pod shell and delete the Pod. Then verify that the `PV` data persists.

```bash
exit
```

```bash
kubectl delete pod busybox
```

Create a new Pod that uses the same `PVC`.

```bash
kubectl create -f ~/resources/nginx-with-pv.yaml
```

Open a shell in the Pod to verify that the data is still there.

```bash
kubectl exec -it nginx -- sh
```

```bash
ls /pv/hello-world.txt
```

```bash
cat /pv/hello-world.txt

# output
Hello world from busybox pod!
```

Everything is in order. Exit the Pod shell before cleaning up.

```bash
exit
```

Dynamic provisioning lets workloads request storage through `PVCs` without requiring administrators to create each `PV` in advance.
Clean up the remaining Pod and `PVC`:

```bash
kubectl delete pod nginx
kubectl delete pvc hostpath-pvc
```
