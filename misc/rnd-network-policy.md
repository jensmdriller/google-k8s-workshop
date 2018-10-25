```
# create nginx deployment and export it on port 80
$ kubectl run nginx --image=nginx --replicas=2
$ kubectl expose deployment nginx --port=80
$ kubectl get svc,pod
NAME         TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
kubernetes   ClusterIP   10.96.0.1        <none>        443/TCP   30m
nginx        ClusterIP   10.111.178.142   <none>        80/TCP    18s
NAME                     READY     STATUS    RESTARTS   AGE
nginx-65899c769f-5ftp5   1/1       Running   0          43s
nginx-65899c769f-fz5tg   1/1       Running   0          43s

# connect to the service without network policy

$ kubectl run busybox --rm -ti --image=busybox /bin/sh
$ wget --spider --timeout=1 nginx
Connecting to nginx (10.111.178.142:80)

# now enable the network policy that allows access only for pods with a label access=true

$ cat network-policy.yaml
kind: NetworkPolicy
apiVersion: networking.k8s.io/v1
metadata:
  name: access-nginx
spec:
  podSelector:
    matchLabels:
      run: nginx
  ingress:
  - from:
    - podSelector:
        matchLabels:
          access: "true"

$ kubectl apply -f network-policy.yaml
networkpolicy.networking.k8s.io "access-nginx" created

# try again
$ wget --spider --timeout=1 nginx
Connecting to nginx (10.111.178.142:80)
wget: download timed out

# restart container with the appropriate label
$ kubectl run busybox --rm -ti --image=busybox --labels="access=true" /bin/sh
$ wget --spider --timeout=1 nginx
Connecting to nginx (10.111.178.142:80)
```

Enable on cluster level
-----------------------

```
# on the new cluster
$ gcloud container clusters create [CLUSTER_NAME] --enable-network-policy

# on existing cluster
$ gcloud container clusters update [CLUSTER_NAME] --update-addons=NetworkPolicy=ENABLED
$ gcloud container clusters update [CLUSTER_NAME] --enable-network-policy
```

Theory
------

A network policy is a specification of how groups of pods are allowed to communicate with each other and other network endpoints.

NetworkPolicy resources use labels to select pods and define rules which specify what traffic is allowed to the selected pods.

By default, pods are non-isolated; they accept traffic from any source.

Pods become isolated by having a NetworkPolicy that selects them. Once there is any NetworkPolicy in a namespace selecting a particular pod, that pod will reject any connections that are not allowed by any NetworkPolicy.

- ipBlock
- namespaceSelector
- podSelector

You can create a “default” isolation policy for a namespace by creating a NetworkPolicy that selects all pods but does not allow any ingress traffic to those pods.
