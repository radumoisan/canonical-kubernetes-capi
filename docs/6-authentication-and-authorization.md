# 6. Authentication and Authorization

Select the workload cluster kubeconfig:

```bash
# Select the workload cluster kubeconfig.
export KUBECONFIG=~/.kube/myk8scluster_config
```
??? example "Expected result"
    ```text
    No output.
    ```

Confirm that `kubectl` uses the workload cluster:

```bash
# Display the active Kubernetes context.
kubectl config current-context
```
??? example "Expected result"
    ```text
    myk8scluster-admin@myk8scluster
    ```

!!! abstract "Lab goals"
    In this lab, you will inspect ServiceAccount credentials, make authenticated requests from a Pod, create namespace-scoped RBAC
    permissions, and verify both an allowed request and an expected authorization denial.

## :material-book-open-page-variant-outline: 6.1 Users and ServiceAccounts

Kubernetes has no built-in `User` API object. Human identities are managed outside the cluster, while `ServiceAccount` (`SA`)
objects are namespaced identities for workloads.

Pods normally receive a projected volume containing a short-lived ServiceAccount token, the cluster CA certificate, and the Pod's
namespace. The token authenticates API requests; authorization rules determine which operations the Pod may perform.

Kubernetes distinguishes user accounts from service accounts for several reasons:

* User accounts represent people and are managed externally to the cluster.
* Service accounts represent Pods and the processes running in them.
* User identities are cluster-wide rather than namespaced.
* Service accounts are namespaced.
* Auditing requirements for people and workloads may differ.

Each namespace has a `default` ServiceAccount. Create separate ServiceAccounts for workloads that require API access so that each
workload receives only the permissions it needs.

### :material-application-edit-outline: Inspect ServiceAccounts

List the namespaces:

```bash
# List namespaces.
kubectl get namespace
```
??? example "Expected result"
    ```text
    NAME              STATUS   AGE
    cilium-secrets    Active   7h48m
    default           Active   7h48m
    kube-node-lease   Active   7h48m
    kube-public       Active   7h48m
    kube-system       Active   7h48m
    metallb-system    Active   7h48m
    ```

Namespace ages change over time.

List the ServiceAccounts in the default namespace:

```bash
# List ServiceAccounts in the default namespace.
kubectl get sa
```
??? example "Expected result"
    ```text
    NAME      AGE
    default   7h48m
    ```

List ServiceAccounts across the cluster:

```bash
# List ServiceAccounts in all namespaces.
kubectl get sa --all-namespaces
```
??? example "Expected result"
    ```text
    NAMESPACE         NAME                               AGE
    cilium-secrets    default                            7h48m
    default           default                            7h48m
    kube-system       coredns                            7h48m
    kube-system       metrics-server                     7h48m
    metallb-system    metallb-controller                 7h48m
    metallb-system    metallb-speaker                    7h48m
    ...
    ```

The exact ServiceAccounts and ages depend on the installed cluster components.

Inspect the default namespace's ServiceAccount:

```bash
# Describe the default ServiceAccount.
kubectl describe sa default
```
??? example "Expected result"
    ```text
    Name:                default
    Namespace:           default
    Labels:              <none>
    Annotations:         <none>
    Image pull secrets:  <none>
    Events:              <none>
    ```

### :material-application-edit-outline: Inspect ServiceAccount credentials

Since Kubernetes v1.24, ServiceAccounts no longer receive long-lived token Secrets automatically. Pods still receive short-lived,
projected tokens by default. The following manifest explicitly creates a legacy long-lived token Secret for the default
ServiceAccount:

```bash
# Display the token Secret definition.
cat ~/resources/service-account-token.yaml
```
??? example "Expected result"
    ```yaml
    apiVersion: v1
    kind: Secret
    metadata:
      name: default-serviceaccount-secret
      annotations:
        kubernetes.io/service-account.name: default
    type: kubernetes.io/service-account-token
    ```

Create the token Secret:

```bash
# Create the default ServiceAccount token Secret.
kubectl create -f ~/resources/service-account-token.yaml
```
??? example "Expected result"
    ```text
    secret/default-serviceaccount-secret created
    ```

Wait until the token controller populates the Secret:

```bash
# Wait for token data to be generated.
kubectl wait --for=jsonpath='{.data.token}' secret/default-serviceaccount-secret --timeout=120s
```
??? example "Expected result"
    ```text
    secret/default-serviceaccount-secret condition met
    ```

Inspect the Secret without displaying its credential data:

```bash
# Display the token Secret summary.
kubectl get secret default-serviceaccount-secret
```
??? example "Expected result"
    ```text
    NAME                            TYPE                                  DATA   AGE
    default-serviceaccount-secret   kubernetes.io/service-account-token   3      115s
    ```

Confirm that the Secret belongs to the default ServiceAccount:

```bash
# Display the ServiceAccount named by the Secret annotation.
kubectl get secret default-serviceaccount-secret -o jsonpath='{.metadata.annotations.kubernetes\.io/service-account\.name}{"\n"}'
```
??? example "Expected result"
    ```text
    default
    ```

!!! warning "Protect ServiceAccount tokens"
    A legacy ServiceAccount token is a bearer credential. Some Kubernetes versions display its complete value with
    `kubectl describe secret`. Do not expose or store that output. Delete the Secret when this exercise is complete.

### :material-application-edit-outline: Use projected credentials from a Pod

Display the Pod manifest:

```bash
# Display the curl Pod definition.
cat ~/resources/curl-pod.yaml
```
??? example "Expected result"
    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: curl
    spec:
      containers:
      - name: curl
        image: alpine
        command: ["sleep", "999999"]
    ```

Create the Pod:

```bash
# Create the curl Pod.
kubectl create -f ~/resources/curl-pod.yaml
```
??? example "Expected result"
    ```text
    pod/curl created
    ```

Wait for the Pod to become ready:

```bash
# Wait for the curl Pod.
kubectl wait --for=condition=Ready pod/curl --timeout=180s
```
??? example "Expected result"
    ```text
    pod/curl condition met
    ```

Because the manifest does not set `serviceAccountName`, Kubernetes assigns the default ServiceAccount:

```bash
# Display the Pod's ServiceAccount name.
kubectl get pod curl -o jsonpath='{.spec.serviceAccountName}{"\n"}'
```
??? example "Expected result"
    ```text
    default
    ```

Inspect the projected volume details:

```bash
# Describe the curl Pod.
kubectl describe pod curl
```
??? example "Expected result"
    ```text
    Service Account:  default
    ...
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-pn4fl (ro)
    ...
    Volumes:
      kube-api-access-pn4fl:
        Type:                    Projected (a volume that contains injected data from multiple sources)
        TokenExpirationSeconds:  3607
        ConfigMapName:           kube-root-ca.crt
        Optional:                false
        DownwardAPI:             true
    ```

The generated volume suffix varies.

List the projected files without opening an interactive shell:

```bash
# List the mounted ServiceAccount files.
timeout 30 kubectl exec curl -- ls -l /var/run/secrets/kubernetes.io/serviceaccount/
```
??? example "Expected result"
    ```text
    total 0
    lrwxrwxrwx    1 root     root            13 Sep  8 17:47 ca.crt -> ..data/ca.crt
    lrwxrwxrwx    1 root     root            16 Sep  8 17:47 namespace -> ..data/namespace
    lrwxrwxrwx    1 root     root            12 Sep  8 17:47 token -> ..data/token
    ```

Install curl with a three-minute execution limit:

```bash
# Install curl in the Pod.
timeout 180 kubectl exec curl -- apk add --no-cache curl
```
??? example "Expected result"
    ```text
    (1/9) Installing brotli-libs (1.2.0-r1)
    ...
    (9/9) Installing curl (8.22.0-r0)
    OK: 13.1 MiB in 25 packages
    ```

Package versions may change.

Use the projected token and CA certificate to query the API discovery endpoint. The token remains inside the Pod and is not printed:

```bash
# Verify authenticated API root discovery.
timeout 60 kubectl exec curl -- sh -ec '
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
code=$(curl --silent --show-error --connect-timeout 10 --max-time 30 \
  --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  -H "Authorization: Bearer $TOKEN" \
  -o /tmp/api.json -w "%{http_code}" https://kubernetes/api)
test "$code" = 200
grep -q APIVersions /tmp/api.json
printf "/api: HTTP %s (APIVersions)\n" "$code"
'
```
??? example "Expected result"
    ```text
    /api: HTTP 200 (APIVersions)
    ```

Query the core v1 API discovery endpoint:

```bash
# Verify authenticated core API discovery.
timeout 60 kubectl exec curl -- sh -ec '
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
code=$(curl --silent --show-error --connect-timeout 10 --max-time 30 \
  --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  -H "Authorization: Bearer $TOKEN" \
  -o /tmp/api-v1.json -w "%{http_code}" https://kubernetes/api/v1)
test "$code" = 200
grep -q APIResourceList /tmp/api-v1.json
printf "/api/v1: HTTP %s (APIResourceList)\n" "$code"
'
```
??? example "Expected result"
    ```text
    /api/v1: HTTP 200 (APIResourceList)
    ```

The CA certificate verifies the API server's identity, and the token authenticates the Pod as the default ServiceAccount.

!!! note "ServiceAccount assignment"
    A Pod's `serviceAccountName` is set when the Pod is created and cannot be changed later. Each Pod uses one ServiceAccount, but
    multiple Pods in a namespace can use the same ServiceAccount.

Delete the Pod:

```bash
# Delete the curl Pod.
kubectl delete pod curl --wait=true --timeout=180s
```
??? example "Expected result"
    ```text
    pod "curl" deleted from default namespace
    ```

Delete the legacy token Secret:

```bash
# Delete the token Secret.
kubectl delete secret default-serviceaccount-secret --wait=true --timeout=180s
```
??? example "Expected result"
    ```text
    secret "default-serviceaccount-secret" deleted from default namespace
    ```

## :material-book-open-page-variant-outline: 6.2 RBAC, Roles and ClusterRoles

Role-based access control (`RBAC`) authorizes Kubernetes API requests based on permissions granted to subjects such as users, groups,
and ServiceAccounts. RBAC uses four principal authorization resource kinds:

* `Role`: contains additive permission rules for resources in one namespace. RBAC has no deny rules.
* `ClusterRole`: contains rules that can cover cluster-scoped resources or be reused in any namespace.
* `RoleBinding`: grants a Role or ClusterRole to subjects within one namespace.
* `ClusterRoleBinding`: grants a ClusterRole to subjects across the cluster.

![Roles and bindings](assets/roles_bindings.png)

Verify that the API server uses `Node` and `RBAC` authorization modes:

```bash
# Display the API server authorization mode.
timeout 30 lxc exec k8s-ctrl -- sh -c 'ps auxww | grep "[k]ube-apiserver"' | grep -o -- '--authorization-mode=[^ ]*'
```
??? example "Expected result"
    ```text
    --authorization-mode=Node,RBAC
    ```

Kubernetes provides standard ClusterRoles for common access levels. Display the four roles discussed in this exercise:

```bash
# Display the standard access ClusterRoles.
kubectl get clusterroles admin edit view cluster-admin
```
??? example "Expected result"
    ```text
    NAME            CREATED AT
    admin           2026-09-08T09:57:34Z
    edit            2026-09-08T09:57:34Z
    view            2026-09-08T09:57:34Z
    cluster-admin   2026-09-08T09:57:34Z
    ```

Creation timestamps vary.

### :material-application-edit-outline: Create a ServiceAccount and grant permissions

In this exercise, a Role permits `get`, `watch`, and `list` operations on Pods in the default namespace. A RoleBinding grants those
permissions to `student-sa`.

Display the ServiceAccount manifest:

```bash
# Display the student ServiceAccount definition.
cat ~/resources/student-sa.yaml
```
??? example "Expected result"
    ```yaml
    apiVersion: v1
    kind: ServiceAccount
    metadata:
     name: student-sa
     namespace: default
    ```

Create the ServiceAccount:

```bash
# Create the student ServiceAccount.
kubectl create -f ~/resources/student-sa.yaml
```
??? example "Expected result"
    ```text
    serviceaccount/student-sa created
    ```

Display the Role manifest:

```bash
# Display the pod-reader Role definition.
cat ~/resources/pod-reader-role.yaml
```
??? example "Expected result"
    ```yaml
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

Create the Role:

```bash
# Create the pod-reader Role.
kubectl create -f ~/resources/pod-reader-role.yaml
```
??? example "Expected result"
    ```text
    role.rbac.authorization.k8s.io/pod-reader created
    ```

Display the RoleBinding manifest:

```bash
# Display the pod-reader RoleBinding definition.
cat ~/resources/pod-reader-rb.yaml
```
??? example "Expected result"
    ```yaml
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: read-pods
      namespace: default
    subjects:
    - kind: ServiceAccount
      name: student-sa
    roleRef:
      kind: Role
      name: pod-reader
      apiGroup: rbac.authorization.k8s.io
    ```

Create the RoleBinding:

```bash
# Create the pod-reader RoleBinding.
kubectl create -f ~/resources/pod-reader-rb.yaml
```
??? example "Expected result"
    ```text
    rolebinding.rbac.authorization.k8s.io/read-pods created
    ```

Confirm that the RoleBinding references `pod-reader` and `student-sa`:

```bash
# Describe the read-pods RoleBinding.
kubectl describe rolebinding read-pods
```
??? example "Expected result"
    ```text
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

Verify that `student-sa` can list Pods:

```bash
# Check the granted Pod permission.
kubectl auth can-i list pods --as=system:serviceaccount:default:student-sa -n default
```
??? example "Expected result"
    ```text
    yes
    ```

Verify that the same ServiceAccount cannot list Secrets. The compound command treats the expected `no` result as success while still
failing if any other value is returned:

```bash
# Check the denied Secret permission.
result=$(kubectl auth can-i list secrets --as=system:serviceaccount:default:student-sa -n default 2>/dev/null || true); test "$result" = no; printf '%s\n' "$result"
```
??? example "Expected result"
    ```text
    no
    ```

### :material-application-edit-outline: Test RBAC from a Pod

Display the Pod manifest that selects `student-sa`:

```bash
# Display the curl Pod definition with the student ServiceAccount.
cat ~/resources/curl-pod-with-sa.yaml
```
??? example "Expected result"
    ```yaml
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

Create the Pod:

```bash
# Create the curl Pod with the student ServiceAccount.
kubectl create -f ~/resources/curl-pod-with-sa.yaml
```
??? example "Expected result"
    ```text
    pod/curl created
    ```

Wait for the Pod to become ready:

```bash
# Wait for the curl Pod.
kubectl wait --for=condition=Ready pod/curl --timeout=180s
```
??? example "Expected result"
    ```text
    pod/curl condition met
    ```

Confirm the Pod's ServiceAccount assignment:

```bash
# Display the Pod's ServiceAccount name.
kubectl get pod curl -o jsonpath='{.spec.serviceAccountName}{"\n"}'
```
??? example "Expected result"
    ```text
    student-sa
    ```

Install curl with a bounded command:

```bash
# Install curl in the Pod.
timeout 180 kubectl exec curl -- apk add --no-cache curl
```
??? example "Expected result"
    ```text
    (1/9) Installing brotli-libs (1.2.0-r1)
    ...
    (9/9) Installing curl (8.22.0-r0)
    OK: 13.1 MiB in 25 packages
    ```

Query the Pods endpoint. The command asserts HTTP `200`, a `PodList` response, and the presence of the `curl` Pod:

```bash
# Verify the allowed Pod request.
timeout 60 kubectl exec curl -- sh -ec '
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
code=$(curl --silent --show-error --connect-timeout 10 --max-time 30 \
  --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  -H "Authorization: Bearer $TOKEN" \
  -o /tmp/pods.json -w "%{http_code}" https://kubernetes/api/v1/namespaces/default/pods)
test "$code" = 200
grep -q PodList /tmp/pods.json
grep -q curl /tmp/pods.json
printf "pods: HTTP %s (PodList includes curl)\n" "$code"
'
```
??? example "Expected result"
    ```text
    pods: HTTP 200 (PodList includes curl)
    ```

Query the Secrets endpoint. The command asserts the expected HTTP `403`, the `Forbidden` reason, and the authenticated identity:

```bash
# Verify the denied Secret request.
timeout 60 kubectl exec curl -- sh -ec '
TOKEN=$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
code=$(curl --silent --show-error --connect-timeout 10 --max-time 30 \
  --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt \
  -H "Authorization: Bearer $TOKEN" \
  -o /tmp/secrets.json -w "%{http_code}" https://kubernetes/api/v1/namespaces/default/secrets)
test "$code" = 403
grep -q Forbidden /tmp/secrets.json
grep -q system:serviceaccount:default:student-sa /tmp/secrets.json
printf "secrets: HTTP %s (Forbidden for system:serviceaccount:default:student-sa)\n" "$code"
'
```
??? example "Expected result"
    ```text
    secrets: HTTP 403 (Forbidden for system:serviceaccount:default:student-sa)
    ```

The ServiceAccount is authenticated successfully, but RBAC authorizes only the Pod request.

### :material-application-edit-outline: Clean up

Delete the Pod:

```bash
# Delete the curl Pod.
kubectl delete pod curl --ignore-not-found --wait=true --timeout=180s
```
??? example "Expected result"
    ```text
    pod "curl" deleted from default namespace
    ```

Delete the RoleBinding before the Role and ServiceAccount:

```bash
# Delete the read-pods RoleBinding.
kubectl delete rolebinding read-pods --ignore-not-found --wait=true --timeout=180s
```
??? example "Expected result"
    ```text
    rolebinding.rbac.authorization.k8s.io "read-pods" deleted from default namespace
    ```

Delete the Role:

```bash
# Delete the pod-reader Role.
kubectl delete role pod-reader --ignore-not-found --wait=true --timeout=180s
```
??? example "Expected result"
    ```text
    role.rbac.authorization.k8s.io "pod-reader" deleted from default namespace
    ```

Delete the ServiceAccount:

```bash
# Delete the student ServiceAccount.
kubectl delete serviceaccount student-sa --ignore-not-found --wait=true --timeout=180s
```
??? example "Expected result"
    ```text
    serviceaccount "student-sa" deleted from default namespace
    ```

Verify that no Chapter 6 resources remain:

```bash
# Check for remaining Chapter 6 resources.
kubectl get secret/default-serviceaccount-secret pod/curl serviceaccount/student-sa role.rbac.authorization.k8s.io/pod-reader rolebinding.rbac.authorization.k8s.io/read-pods -o name --ignore-not-found
```
??? example "Expected result"
    ```text
    No output.
    ```

Confirm that the namespace's built-in default ServiceAccount remains:

```bash
# Display the default ServiceAccount after cleanup.
kubectl get sa default
```
??? example "Expected result"
    ```text
    NAME      AGE
    default   7h59m
    ```

The ServiceAccount age changes over time.

Confirm that every cluster node remains Ready:

```bash
# Wait for all cluster nodes to remain ready.
kubectl wait --for=condition=Ready nodes --all --timeout=180s
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
    NAME          STATUS   ROLES                  AGE     VERSION
    k8s-ctrl      Ready    control-plane,worker   7h59m   v1.35.7
    k8s-worker1   Ready    worker                 7h48m   v1.35.7
    k8s-worker2   Ready    worker                 7h48m   v1.35.7
    ```

Node ages change over time.

For more information, see the
[Kubernetes ServiceAccounts documentation](https://kubernetes.io/docs/concepts/security/service-accounts/)
and the [Kubernetes RBAC documentation](https://kubernetes.io/docs/reference/access-authn-authz/rbac/).
