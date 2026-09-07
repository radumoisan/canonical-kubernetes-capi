# 4. Storage and User Data !heading

Applications can write and read data directly on and from the container filesystem. This approach can have many drawbacks,
one is when two container of the same pod need to access the same piece of data. Also, Kubernetes works on pod level, so
something new had to be done to address this.

## 4.1 Volumes

`Volumes` are a Kubernetes resource type that solves this. A Volume can be shared between containers of the same pod.
There are different types of volumes, some are ephemeral, meaning that they live as long as the pods do, and some are persistent
on pod deletion.

There are many volume types, but some of the most used are:
  * `emptyDir`: exists as long as that pod does, it is initially empty. By default, emptyDir volumes are stored on whatever medium is backing the node - that might be disk or SSD or network storage, depending on your environment. Privileged containers are required for this type of volume.
  * `hostPath`: mounts a directory from the host Node's filesystem. Useful in some situations: e.g. containers need to access Docker internals or host's `/sys` special filesystem
  * `fc`: allows an existing fibre channel block storage volume to be mounted in a Pod
  * `image`: An image volume source represents an OCI object (a container image or artifact) which is available on the kubelet's host machine.
  * `nfs`: mounts NFS shared into pods
  * `iscsi`: mounts iSCSI volumes into pods

Let's create a Pod with two running containers and a shared `emptyDir` volume. This is how the pod definition
`~/resources/multi-container-pod.yaml` looks like:

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

The volume is called `shared-data`. Containers reference the volume by name in the `volumeMounts` of the container template.
`mountPath` is from where the volume is accessible from inside the container. As you can see, the first container sees the html file
in `/usr/share/nginx/html/index.html` and the second container in  `/pod-data/index.html`, but it's the same file. Try to understand
the definition file, discuss any interesting details with the trainer.

Create the pod and a service for it, the definition files are already provisioned in `~/resources/multi-container-pod.yaml` and
`~/resources/multi-container-pod-service.yaml`:

```bash
kubectl create -f ~/resources/multi-container-pod.yaml
```

```bash
kubectl create -f ~/resources/multi-container-pod-service.yaml
```

Get the ClusterIP, connect to a Node and `curl` from there:

```bash
kubectl get svc two-containers-svc

# output
NAME                 TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)    AGE
two-containers-svc   ClusterIP   10.152.183.236   <none>        8080/TCP   38s
```

SSH into one of the nodes:

```bash
lxc shell k8s-worker1
```

```bash
curl 10.152.183.236:8080

# output
Hello from the debian container
```

As you can see the two containers work together in this scenario with the help of the volume. This is a simple example,
but complex scenarios can be built on the presented concepts.

Go back to the student machine and delete the pods:

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

There are four different ways that you can use a ConfigMap to configure a container inside a Pod:
 * Inside a container command and args
 * Environment variables for a container
 * Add a file in read-only volume, for the application to read
 * Write code to run inside the Pod that uses the Kubernetes API to read a ConfigMap

When a `ConfigMap` currently consumed in a volume is updated, projected keys are eventually updated as well. The kubelet checks whether
the mounted `ConfigMap` is fresh on every periodic sync.
`ConfigMaps` consumed as environment variables are not updated automatically and require a pod restart.

**NOTE**: `ConfigMap` does not provide secrecy or encryption. If the data you want to store is confidential, use a `Secret`
rather than a `ConfigMap`, or use additional (third party) tools to keep your data private.

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

Create a Pod that references the `ConfigMap`.

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

Check if the Pod sees the values:

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

`Secrets` are a way to securely inject sensitive data into Pods. By sensitive data is meant: credentials, encryption keys,
tokens, etc. The data is represented as key-values pairs and are encoded in base64.

There are two ways to create secrets, from CLI using `kubectl` or from a file definition, we'll use the CLI method:

```bash
kubectl create secret generic bob-secret --from-literal=username='bob' \
--from-literal=password='Passw0rd'
```

**NOTE**: If the CLI method is used, the values will automatically be encoded for the user. If the file definition is used,
the user will have to input the already encoded values in the definition.

Observe the secret and node the encoded value:

```bash
kubectl get secret bob-secret

# output
NAME         TYPE     DATA   AGE
bob-secret   Opaque   2      10s
```

`type: Opaque` means that contents of this Secret is unstructured, it can contain arbitrary key-value pairs.
Other types of secrets can be `service-account-token`, `dockercfg`, `dockerconfigjson`, `ssh-auth`, `tls`.
For more info on Secret types please visit:

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

```bash
kubectl get secret bob-secret -o yaml
```

Now create a pod that has access to the `Secret` via environment variables. Here is the pod definition `~/resources/pod-with-secrets.yaml`:

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

Create the pod:

```bash
kubectl create -f ~/resources/pod-with-secrets.yaml
```

Wait for the pod to come up. Connect to it afterwards and see if the secrets were passed:

```bash
kubectl exec -it pod-with-secrets -- /bin/bash
```

```bash
root@pod-with-secrets:/# printenv | grep SECRET

# output
SECRET_PASSWORD=Passw0rd
SECRET_USERNAME=bob
```

Now, a database, for example, can directly reference the environment variables for credentials.

Exit the pod and delete the resources you've created:

```bash
root@pod-with-secrets:/# exit
```

```bash
kubectl delete pod pod-with-secrets
kubectl delete secret bob-secret
```


## 4.4 PersistentVolumes, PersistentVolumeClaims and StorageClasses

This works great but volume types such as `emptyDir` and `hostPath` have the drawback that developers need to have knowledge of
the storage and network infrastructure. Storage should be provisioned in a transparent manner and fully abstracted of the backend solution.

`PersistentVolumes`, `PersistentVolumeClaims` and `StorageClasses` can be used. A storage backend is represented by
the `StorageClass`. It dynamically provisions `PVs` with the help of `PVCs`.

**NOTE**: PersistentVolumes will be referenced with `PVs`, `PersistentVolumeClaims` with `PVCs` and `StorageClasses`
with `SCs`.

`PVs` are like volumes, but it's lifecycle does not depend on the pods lifecycle. A user or pod can request a `PV` with a `PVC`.

![roles](assets/pvc.png)

Administrators can also create `PVs` statically, meaning that the PVs will pe pre-provisioned. This is bad because it's not automated, and may require manual(
intervention later on. `SCs` are allow for `PVs` to be provisioned dynamically.

Your cluster is using `hostPath` storage. To get the current configured (and `default`) storage class:

```bash
kubectl get sc

# output
NAME                            PROVISIONER              RECLAIMPOLICY   VOLUMEBINDINGMODE      ALLOWVOLUMEEXPANSION   AGE
csi-rawfile-default (default)   rawfile.csi.openebs.io   Delete          WaitForFirstConsumer   true                   48m
```

Also, you can get details about your storage class:

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

Great now we can dynamically allocate volumes for containers, the way workflows are intended to be.

Create a `PVC` using the `SC` from `~/resources/gce-pvc.yaml`:

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

`PVCs` are the way to bind to `PVs`. Create the `PVC`:

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

The `PVC` is bound to a `Persistent Volume`.

```bash
kubectl get pv

# output
No resources found
```

The volume will be created upon pod creation.

Create a pod that will make use of the new `PV` with `~/resources/busybox-with-pv.yaml`:

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

After the pod gets created, let's check again the PersistentVolumeClaim status:

```bash
kubectl get pvc

# output
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS          VOLUMEATTRIBUTESCLASS   AGE
hostpath-pvc   Bound    pvc-885f7ff8-8dbc-4f00-bd56-f92edbfa2e3c   10Gi       RWO            csi-rawfile-default   <unset>                 3m37s
```

Check inside the pod to see if the volume was mounted:

```bash
kubectl exec busybox -- mount | grep pv

# output
/dev/loop3 on /pv type ext4 (rw,relatime)
```

If the new device shows up, we have successfully configured and provisioned an hostPath-backed PV.

Let's write some data on the PV. Create a file called `hello-world.txt`.

```bash
kubectl exec busybox --  touch /pv/hello-world.txt
```

Connect to the pod and write some text in the file.

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

Exit the pods and delete it. Let's see if the `PV` and data will be persistent.

```bash
exit
```

```bash
kubectl delete pod busybox
```

Create a new pod but use the same `PVC`.

```bash
kubectl create -f ~/resources/nginx-with-pv.yaml
```

Connect to the pod to see of the data is still there.

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

All is order. Now we can exit and delete the pod.

```bash
exit
```

Dynamically allocated PVs is the most flexible and reliable way to allocate storage for applications running in Kubernetes.
Cleanup the pods we've created in this chapter:

```bash
kubectl delete pod nginx
kubectl delete pvc hostpath-pvc
```
