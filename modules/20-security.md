Security
========

Objectives
----------

- enable pod security policies (PSP)
- implement PSP to limit container capabilities
- implement network policy to limit interactions between pods
- implement image security scanning to prevent using outdated versions of the base image

Enable PSPs
-----------

To enable PSP for the new cluster, use `--enable-pod-security-policy` flag while creating

We have already created the cluster so we will use the update command.

```
$ gcloud beta container clusters update jenkins-cd \
  --enable-pod-security-policy
```

It will take some time for updating the cluster during which you won't be able to access API.

Create a PSP file called `psp.yaml`:

```
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

```
$ kubectl apply -f psp.yaml
```

Typically `Pods` are created by `Deployments`, `ReplicaSets`, not by the user directly. We need to grant permissions for using this policy to the default account.

```
role.yaml:

kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: pod-starter
rules:
- apiGroups:
  - extensions
  resources:
  - podsecuritypolicies
  resourceNames:
  - restricted
  verbs:
  - use

$ kubectl apply -f role.yaml

bind.yaml:

apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: pod-starter-binding
  namespace: default
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: pod-starter
subjects:
# A specific service account in my-namespace
- kind: ServiceAccount # Omit apiGroup
  name: default
  namespace: default
  
$ kubectl apply -f binding.yaml
```

Now try to create a priviledged container:

```
$ kubectl create -f- <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: privileged
  labels:
    app: privileged
spec:
  replicas: 1
  selector:
    matchLabels:
      app: privileged
  template:
    metadata:
      labels:
        app: privileged
    spec:
      containers:
        - name:  pause
          image: k8s.gcr.io/pause
          securityContext:
            privileged: true
EOF
```

`Deployment` creates `ReplicaSet` that in turn creates `Pod`. Let' see the `ReplicaSet` state.

```
$ kubectl get rs -l=app=privileged
NAME                    DESIRED   CURRENT   READY     AGE
privileged-6c96db7488   1         0         0         5m
```

No pods created. Why?

```
$ kubectl describe rs -l=app=privileged
..
Error creating: pods "privileged-6c96db7488-" is forbidden: unable to validate against any pod security policy: [spec.containers[0].securityContext.privileged: Invalid value: true: Privileged containers are not allowed]
```

Admission controller forbids creating priviledged container as the applied policy states.

What happens if you create pod directly?

```
$ kubectl create -f- <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: privileged
spec:
  containers:
    - name:  pause
      image: k8s.gcr.io/pause
      securityContext:
        privileged: true
EOF
```

Try it and explain the result.

Network policy
--------------

First let's enable network policy enforcement on the GKE cluster.

It is a two-step process.

```
$ gcloud container clusters update jenkins-cd \
   --update-addons=NetworkPolicy=ENABLED
$ gcloud container clusters update jenkins-cd \
   --enable-network-policy
```

Watch how your k8s cluster is updated one worker at a time:

```
$ kubectl get nodes --watch
```

When all the nodes are in `Ready` state you may proceed to the next step.

Let's see how to use network policy for blocking the external traffic for a `Pod`

Create file called `deny-egress.yaml`:

```
deny-egress.yaml:

apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: foo-deny-egress
spec:
  podSelector:
    matchLabels:
      app: foo
  policyTypes:
  - Egress
  egress:
  # allow DNS resolution
  - ports:
    - port: 53
      protocol: UDP
    - port: 53
      protocol: TCP

$ kubectl apply -f deny-egress.yaml
```

This file blocks all the outgoing traffic except DNS resolution.

Now start the pod that matches label `app=foo`

```
$ kubectl run --rm --restart=Never --image=alpine -i -t -l app=foo test -- ash

/ # wget --timeout 1 -O- http://www.example.com
Connecting to www.example.com (93.184.216.34:80)
wget: download timed out
```

You see the name resolution works fine but external connections are dropped.

Jenkins Network Policy
----------------------

There is already network policy inside the Jenkins Helm chart. In this exercise you will examine it and understand restrictions applied to the traffic.

1. Enable network policy in the Jenkins chart configuration

  Go to `jenkins/values.yaml` and add line `Enabled: true` in the `NetworkPolicy` section.

1. Update the Helm chart

  `./helm upgrade cd stable/jenkins -f jenkins/values.yaml --wait`

1. Get the policy specification and look through it

```
$ kubectl get NetworkPolicy cd-jenkins-master -n cd -o yaml
apiVersion: extensions/v1beta1
kind: NetworkPolicy
metadata:
  creationTimestamp: 2018-08-12T16:28:12Z
  generation: 1
  name: cd-jenkins-master
  namespace: default
  resourceVersion: "6384"
  selfLink: /apis/extensions/v1beta1/namespaces/default/networkpolicies/cd-jenkins-master
  uid: b51f5973-9e4c-11e8-9212-42010aa8002b
spec:
  ingress:
  - ports:
    - port: 8080
      protocol: TCP
  - from:
    - podSelector:
        matchLabels:
          jenkins/cd-jenkins-slave: "true"
    ports:
    - port: 50000
      protocol: TCP
  podSelector:
    matchLabels:
      component: cd-jenkins-master
  policyTypes:
  - Ingress
```

Verify you still have access to the Jenkins UI and can run builds. If not, figure out why.

Image security scanning
-----------------------

1. Deploy Clair to Kubernetes

  ```
  git clone https://github.com/coreos/clair
  cd clair/contrib/helm
  cp clair/values.yaml ~/my_custom_values.yaml
  vi ~/my_custom_values.yaml
  helm dependency update clair
  helm install clair -f ~/my_custom_values.yaml
  ```

1. Install `calirctl` - see https://github.com/jgsqware/clairctl

1. Check out wordpress image that is two months old

1. Check if clair finds any vulnerabilities in the image

1. Generate the HTML report on found vulnerabilities

Optional Exercises
------------------

### Scanning images in pipeline

Your pipeline is a good place to put code that scans images for vulnerabilities. Let's integrate Clair image vulnerability scanning into the Jenins pipeline. 

Use may use https://github.com/protacon/ci-image-vulnerability-scan as a reference. 

Build the `sample-app` using the latest golang image. The build should pass.

Now use the golang Docker image that is two months old. Does the build succeeds this time? How can you view the generated report?
