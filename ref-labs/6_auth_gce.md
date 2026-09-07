# 6. Authentication and Authorization !heading

## 6.1 Users and ServiceAccounts

Kubernetes does NOT have a resource called `user`. It has the concept of `ServiceAccounts` which live inside `Namespaces`,
objects used for multi-tenancy. However, Kubernetes understands the concept of users as an external object.

`ServiceAccounts` are Kubernetes resource types that are associated with Pods to offer them the possibility to talk to the
API Server. They represent the identify of the app running inside Pods. Pods can make API calls against the Server to request
pod metadata such as: pod name, IP, namespace, labels, CPU and memory utilization. Usually, apps can make use of this kind of
information. Each `SA` contains a token, this token is mounted as a `secret` volume inside pods on creation. The token is then used
to authenticate and authorize the pod requests for the API Server.

Kubernetes distinguishes between the concept of a user account and a service account for a number of reasons:
  * user accounts are for humans, the intent is for user accounts to be managed externally to the Kubernetes cluster
  * service accounts are for Pods and processes that run in them
  * user accounts are global and unique across all namespaces of the cluster
  * service accounts are namespaced
  * auditing for humans and service accounts may differ

Each namespace has a `default` `SA`. Additional `SAs` can be created for security reasons, read-only `SAs` for pods
that only need to read API info, and separate `SAs` with write permissions for pods that need to modify API objects.

Each Pod is associated with a `SA` on creation. If no `SA` is specified in the Pod definition, the namespace default `SA`
is used. The `secret` volume contains the `default` token of the namespace in which the pod is running.

In this chapter we'll create a pod with `curl` binary installed and see how the secret volume is mounted in it. The last step would
be to send an API request to the API server.

First, let's check the default namespace and the `SAs`:

```bash
kubectl get namespace

# output
NAME              STATUS   AGE
cilium-secrets    Active   6h4m
default           Active   6h4m
kube-node-lease   Active   6h4m
kube-public       Active   6h4m
kube-system       Active   6h4m
metallb-system    Active   6h4m
```

Get the default namespace `SA`:

```bash
kubectl get sa
# output
# as mentioned, each Namespace has a default ServiceAccount within it.
NAME      SECRETS   AGE
default   0         25h
```

Get the `SA` for all the namespaces:

```bash
kubectl get sa --all-namespaces
```

Inspect the default namespace `SA`:

```bash
kubectl describe sa default

# output
Name:                default
Namespace:           default
Labels:              <none>
Annotations:         <none>
Image pull secrets:  <none>
Events:              <none>
```

Since Kubernetes v1.24 there are no tokens generated for service accounts by default. A `Secret` definition for the default service account looks like this:

```bash
cat ~/resources/service-account-token.yaml

# output
apiVersion: v1
kind: Secret
metadata:
  name: default-serviceaccount-secret
  annotations:
    kubernetes.io/service-account.name: default
type: kubernetes.io/service-account-token
```


To generate one, please run:

```bash
kubectl create -f ~/resources/service-account-token.yaml
```

To get details about the generated ServiceAccount secret, run:

```bash
kubectl describe secret default-serviceaccount-secret

# output
Name:         default-serviceaccount-secret
Namespace:    default
Labels:       <none>
Annotations:  kubernetes.io/service-account.name: default
              kubernetes.io/service-account.uid: a0c53e14-fd50-476c-a085-b013256ccf3c

Type:  kubernetes.io/service-account-token

Data
====
ca.crt:     1139 bytes
namespace:  7 bytes
token:      eyJhbGciOiJSUzI1NiIsImtpZCI6Ik....
```

Now create the `alpine` pod and see if the token is mounted:

```bash
kubectl create -f ~/resources/curl-pod.yaml
```

```bash
kubectl describe pod curl

# output
...
Volumes:
  kube-api-access-7qjdk:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
...
```

Kubernetes mounts the secret volume at `/var/run/secrets/kubernetes.io/serviceaccount/` inside the container. Based on the
certificate and token, the application can talk to the API Server when needed:

```bash
kubectl exec -it curl -- sh
```

```bash
ls -l /var/run/secrets/kubernetes.io/serviceaccount/

# output
lrwxrwxrwx    1 root     root            13 Jul 25 17:35 ca.crt -> ..data/ca.crt
lrwxrwxrwx    1 root     root            16 Jul 25 17:35 namespace -> ..data/namespace
lrwxrwxrwx    1 root     root            12 Jul 25 17:35 token -> ..data/token
```

Install `curl` inside the container:

```bash
apk add curl
```

Note that you can get the API cluster IP with `kubectl get svc` or the DNS record which is `kubernetes`.

```bash
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
-H "Authorization: Bearer $TOKEN" https://kubernetes/api

curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
-H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1
```

A long list of API should be listed and the available verbs for those APIs. If we would have not used the certificate and token, this request would have NOT been unauthorized.

**NOTE**: `ServiceAccounts` must be set when creating the pod. It can't be changed later. One pod is associated with only one `SA`, but
multiple pods can use the same `SA` in a namespace.

Get back to the host.

```bash
exit
```

Cleanup the pod:

```bash
kubectl delete pod curl
```

## 6.2 RBAC, Roles and ClusterRoles

All Kubernetes resources are objects which allow CRUD (create, read, update, delete) operations. Role-based access control (RBAC)
is a method of regulating access to resources based on the roles of individual users. RBAC works and understands 4 types of
Kubernetes resources:
  * `Role` and `ClusterRole`: contain rules that represent a set of permissions. Permissions are additive, no `deny` rules. `Roles` grant access to resources within a single namespace, while `ClusterRoles` are cluster-wide.
  * `RoleBinding` and `ClusterRoleBinding`: grant permissions defined in a `Role` to a user or set of users

![roles](assets/roles_bindings.png)


By default, Canonical Kubernetes comes with `RBAC` enabled. You can verify this by checking the authorization mode:

```bash
lxc exec k8s-ctrl -- sh -c 'ps aux | grep kube-apiserver'

# output
...
--authorization-mode=Node,RBAC
...
```

Users can create their own `Roles` and `ClusterRoles` - see the definitions, but Kubernetes clusters also come with a default set of `ClusterRoles`.
The “edit” role lets users perform basic actions like deploying pods; “view” lets a user observe non-sensitive resources; “admin”
allows a user to administer a namespace; and “cluster-admin” grants access to administer a cluster. Take a look:

```bash
kubectl get clusterroles
```

### Create a ServiceAccount and grant permissions

In this exercise we'll create a `ServiceAccount`, a `Role` and a `RoleBinding`. The `Role` will grant
read access to pod resources in the default namespace.

The `SA` definition looks like this in `~/resources/student-sa.yaml`:

```bash
cat ~/resources/student-sa.yaml

# output
apiVersion: v1
kind: ServiceAccount
metadata:
 name: student-sa
 namespace: default
```

Create the `SA`:

```bash
kubectl create -f ~/resources/student-sa.yaml
```

The `Role` definition looks like this in `~/resources/pod-reader-role.yaml`:

```bash
cat ~/resources/pod-reader-role.yaml

# output
kind: Role
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  namespace: default
  name: pod-reader
rules:
- apiGroups: [""]
  resources: ["pods"]
  verbs: ["get", "watch", "list"]
```

Create the `Role`:

```bash
kubectl create -f ~/resources/pod-reader-role.yaml
```

The `Role` has to be associated with the user, this is done with the `RoleBinding` resource in `~/resources/pod-reader-rb.yaml`:

```bash
cat ~/resources/pod-reader-rb.yaml

# output
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: read-pods
  namespace: default
subjects:
- kind: ServiceAccount
  name: student-sa
roleRef:
  kind: Role #this must be Role or ClusterRole
  name: pod-reader # this must match the name of the Role or ClusterRole you wish to bind to
  apiGroup: rbac.authorization.k8s.io
```

```bash
kubectl create -f ~/resources/pod-reader-rb.yaml
```

Inspect the `RoleBinding`, it should be associated with `student-sa`:

```bash
kubectl describe rolebinding read-pods

# output
Name:         read-pods
Labels:       <none>
Annotations:  <none>
Role:
  Kind:  Role
  Name:  pod-reader
Subjects:
  Kind            Name        Namespace
  ----            ----        ---------
  ServiceAccount  student-sa
```

Create a Pod with the newly created `SA`. The pod definition looks like this in `~/resources/curl-pod-with-sa.yaml`:

```bash
cat ~/resources/curl-pod-with-sa.yaml

# output
apiVersion: v1
kind: Pod
metadata:
  name: curl
spec:
  serviceAccountName: student-sa
  containers:
  - name: curl
    image: alpine
    command: ["sleep", "999999"]
```

The key field here is `serviceAccountName: student-sa`. Create the Pod:

```bash
kubectl create -f ~/resources/curl-pod-with-sa.yaml
```

Finally, start a bash process inside the container and attach to it.

```bash
kubectl exec -it curl -- sh
```

Install `curl` inside the container:

```bash
apk add curl
```

Query the API server for pods, this action should be allowed:

```bash
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)

curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
-H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/namespaces/default/pods

# output
{
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": {
    "resourceVersion": "98947"
  },
  "items": [
    {
      "metadata": {
        "name": "curl",
        "namespace": "default",
        "uid": "aed4abe5-490b-477b-a100-cec137cceb9f",
        "resourceVersion": "98907",
        "generation": 1,
        "creationTimestamp": "2026-03-19T10:50:58Z",
        "managedFields": [
          {
            "manager": "kubectl-create",
            "operation": "Update",
            "apiVersion": "v1",
            "time": "2026-03-19T10:50:58Z",
            "fieldsType": "FieldsV1",
            "fieldsV1": {
              "f:spec": {
                "f:containers": {
                  "k:{\"name\":\"curl\"}": {
                    ".": {},
                    "f:command": {},
                    "f:image": {},
                    "f:imagePullPolicy": {},
                    "f:name": {},
                    "f:resources": {},
                    "f:terminationMessagePath": {},
                    "f:terminationMessagePolicy": {}
                  }
...
```

Now let's try to read something we should not be allowed to see, like `Secrets`:

```bash
curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
-H "Authorization: Bearer $TOKEN" https://kubernetes/api/v1/namespaces/default/secrets

# output
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "secrets is forbidden: User \"system:serviceaccount:default:student-sa\" cannot list resource \"secrets\" in API group \"\" in the namespace \"default\"",
  "reason": "Forbidden",
  "details": {
    "kind": "secrets"
  },
  "code": 403
}
```

As expected, forbidden action.

Get back to the student host:

```bash
exit
```

Cleanup:

```bash
kubectl delete pod curl
kubectl delete rolebinding read-pods
kubectl delete role pod-reader
kubectl delete sa student-sa
```
