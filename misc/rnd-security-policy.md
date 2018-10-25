Cluster security policies provide a framework to ensure that pods and containers run only with the appropriate privileges and access only a finite set of resources. Security policies also provide a way for cluster administrators to control resource creation, by limiting the capabilities available to specific roles, groups or namespaces.

The PodSecurityPolicy defines a set of conditions that Pods must meet to be accepted by the cluster; when a request to create or update a Pod does not meet the conditions in the PodSecurityPolicy, that request is rejected and an error is returned.

To use PodSecurityPolicy, you must first create and define policies that new and updated Pods must meet. Then, you must enable the PodSecurityPolicy admission controller, which validates requests to create and update Pods against the defined policies.

## Prevent pods from running with root privileges

```
apiVersion: extensions/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restrict-root
spec:
  privileged: false
  runAsUser:
    rule: MustRunAsNonRoot
  seLinux:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  volumes:
  - '*'
```

## Prevent pods from accessing certain volume types

restrict container to NFS volumes only

```
apiVersion: extensions/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restrict-volumes
spec:
  privileged: false
  runAsUser:
    rule: RunAsAny
  seLinux:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  volumes:
  - 'nfs'
```

## Prevent pods from accessing host ports

```
apiVersion: extensions/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restrict-ports
spec:
  privileged: false
  runAsUser:
    rule: RunAsAny
  seLinux:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  volumes:
  - '*'
  hostPorts:
  - min: 0
    max: 0
```

Enabling
--------

1. Define policies
1. Auth service accounts
1. Enable admission controller

```
# for a new cluster
$ gcloud beta container clusters create [CLUSTER_NAME] --enable-pod-security-policy

# for existing cluster
$ gcloud beta container clusters update [CLUSTER_NAME] --enable-pod-security-policy
```

Reference: https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.11/#podsecuritypolicyspec-v1beta1-extensions

## Practice

```
# create gke cluster with enabled pod security policy

gcloud beta container clusters create psp-gke \
--num-nodes 2 \
--machine-type n1-standard-1 \
--cluster-version 1.10.5-gke.3 \
--labels=owner=lexsys,project=jenkins-workshop \
--image-type UBUNTU \
--enable-pod-security-policy

gcloud container clusters get-credentials psp-gke

kubectl get nodes

# edit psp

apiVersion: extensions/v1beta1
kind: PodSecurityPolicy
metadata:
  name: my-psp
spec:
  privileged: false  # Prevents creation of privileged Pods
  seLinux:
    rule: RunAsAny
  supplementalGroups:
    rule: RunAsAny
  runAsUser:
    rule: RunAsAny
  fsGroup:
    rule: RunAsAny
  volumes:
  - '*'

kubectl apply -f psp.yaml

kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: my-clusterrole
rules:
- apiGroups:
  - extensions
  resources:
  - podsecuritypolicies
  resourceNames:
  - my-psp
  verbs:
  - use
```

Issue
-----

```
Error from server (Forbidden): error when creating "cluster-role.yaml": clusterroles.rbac.authorization.k8s.io "my-clusterrole" is forbidden: attempt to grant extra privileges: [PolicyRule{APIGroups:["extensions"], Resources:["podsecuritypolicies"], ResourceNames:["my-psp"], Verbs:["use"]}] user=&{aleksey.zalesov@altoros.com  [system:authenticated] map[]} ownerrules=[PolicyRule{APIGroups:["authorization.k8s.io"], Resources:["selfsubjectaccessreviews" "selfsubjectrulesreviews"], Verbs:["create"]} PolicyRule{NonResourceURLs:["/api" "/api/*" "/apis" "/apis/*" "/healthz" "/openapi" "/openapi/*" "/swagger-2.0.0.pb-v1" "/swagger.json" "/swaggerapi" "/swaggerapi/*" "/version" "/version/"], Verbs:["get"]}] ruleResolutionErrors=[]
```

    Because of the way Container Engine checks permissions when you create a Role or ClusterRole, you must first create a RoleBinding that grants you all of the permissions included in the role you want to create.

    An example workaround is to create a RoleBinding that gives your Google identity a cluster-admin role before attempting to create additional Role or ClusterRole permissions.

    This is a known issue in the Beta release of Role-Based Access Control in Kubernetes and Container Engine version 1.6.

```
kubectl create clusterrolebinding lx-admin \
  --clusterrole=cluster-admin \
  --user=aleksey.zalesov@altoros.com
```

---

```
cat binding.yaml
# Bind the ClusterRole to the desired set of service accounts.
# Policies should typically be bound to service accounts in a namespace.
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: my-rolebinding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: my-clusterrole
subjects:
# A specific service account in my-namespace
- kind: ServiceAccount # Omit apiGroup
  name: default
  namespace: default

$ kubectl apply -f binding.yaml
```

```
kubectl-user create -f- <<EOF
apiVersion: v1
kind: Pod
metadata:
  name:      pause
spec:
  containers:
    - name:  pause
      image: k8s.gcr.io/pause
EOF

kubectl-admin create role psp:unprivileged01 \
    --verb=use \
    --resource=podsecuritypolicy \
    --resource-name=my-psp
role.rbac.authorization.k8s.io/psp:unprivileged created

kubectl-admin create rolebinding fake-user:psp:unprivileged01 \
    --role=psp:unprivileged01 \
    --serviceaccount=psp-example:fake-user
rolebinding.rbac.authorization.k8s.io/fake-user:psp:unprivileged created

kubectl-user auth can-i use podsecuritypolicy/example
yes

kubectl-user create -f- <<EOF
apiVersion: v1
kind: Pod
metadata:
  name:      pause
spec:
  containers:
    - name:  pause
      image: k8s.gcr.io/pause
EOF

$ kubectl-user create -f- <<EOF
apiVersion: v1
kind: Pod
metadata:
  name:      privileged
spec:
  containers:
    - name:  pause
      image: k8s.gcr.io/pause
      securityContext:
        privileged: true
EOF
Error from server (Forbidden): error when creating "STDIN": pods "privileged" is forbidden: unable to validate against any pod security policy: [spec.containers[0].securityContext.privileged: Invalid value: true: Privileged containers are not allowed]

$ kubectl-user delete pod pause
```

```
kubectl-user run pause --image=k8s.gcr.io/pause
deployment.apps/pause created

kubectl-user get pods

kubectl-admin create rolebinding default:psp:unprivileged \
    --role=psp:unprivileged01 \
    --serviceaccount=psp-example:default

kubectl-user get pods --watch

kubectl-admin delete ns psp-example
```


```
policy/restricted-psp.yaml 

apiVersion: policy/v1beta1
kind: PodSecurityPolicy
metadata:
  name: restricted
  annotations:
    seccomp.security.alpha.kubernetes.io/allowedProfileNames: 'docker/default'
    apparmor.security.beta.kubernetes.io/allowedProfileNames: 'runtime/default'
    seccomp.security.alpha.kubernetes.io/defaultProfileName:  'docker/default'
    apparmor.security.beta.kubernetes.io/defaultProfileName:  'runtime/default'
spec:
  privileged: false
  # Required to prevent escalations to root.
  allowPrivilegeEscalation: false
  # This is redundant with non-root + disallow privilege escalation,
  # but we can provide it for defense in depth.
  requiredDropCapabilities:
    - ALL
  # Allow core volume types.
  volumes:
    - 'configMap'
    - 'emptyDir'
    - 'projected'
    - 'secret'
    - 'downwardAPI'
    # Assume that persistentVolumes set up by the cluster admin are safe to use.
    - 'persistentVolumeClaim'
  hostNetwork: false
  hostIPC: false
  hostPID: false
  runAsUser:
    # Require the container to run without root privileges.
    rule: 'MustRunAsNonRoot'
  seLinux:
    # This policy assumes the nodes are using AppArmor rather than SELinux.
    rule: 'RunAsAny'
  supplementalGroups:
    rule: 'MustRunAs'
    ranges:
      # Forbid adding the root group.
      - min: 1
        max: 65535
  fsGroup:
    rule: 'MustRunAs'
    ranges:
      # Forbid adding the root group.
      - min: 1
        max: 65535
  readOnlyRootFilesystem: false
```
