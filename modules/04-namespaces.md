Namespaces
==========

Module objectives
-----------------

- Create/delete a namespace, examine system namespace

Namespaces
----------

Namespaces provide for a scope of Kubernetes objects. You can think of it as a workspace you're sharing with other users.

With namespaces one may have several virtual clusters backed by the same physical cluster. Names are unique within a namespace, but not across namespaces.

Cluster administrator can divide physical resources between namespaces using quotas.

Namespaces cannot be nested.

Low-level infrastructure resources like Nodes and PersistentVolumes are not associated with a particular namespace

---

1. List all namespaces in the system.
    ```
    kubectl get ns
    ```

1. Use `describe` to learn more about a particular namespace.
    ```
    kubectl describe ns default
    ```

1. Create a new namespace called test

    Save the following file as `ns.yaml`
    ```yaml
    apiVersion: v1
    kind: Namespace
    metadata:
      name: test
    ```

    Deploy new namespce

    ```
    kubectl create -f ns.yaml
    ```

1. List namespaces again.

    You should see namespace `test` in the list.

1. Delete namespace `test`

    ```
    $ kubectl delete ns test
    ```

1. List pods

    ```
    $ kubectl get pods
    ```

    The command shows pods from the `default` namespace. There no pods in this namespace so the list is empty.

1. List pods in the `kube-system` namespace

    ```
    $ kubectl get pods -n kube-system
    NAME                                                   READY   STATUS    RESTARTS   AGE
    event-exporter-v0.2.1-5f5b89fcc8-vdfmx                 2/2     Running   0          2h
    fluentd-gcp-scaler-7c5db745fc-xxv9x                    1/1     Running   0          2h
    fluentd-gcp-v3.1.0-5qxw7                               2/2     Running   0          2h
    fluentd-gcp-v3.1.0-lfjfz                               2/2     Running   0          2h
    heapster-v1.5.3-5559798554-94vpw                       3/3     Running   0          2h
    kube-dns-788979dc8f-7xhm8                              4/4     Running   0          2h
    kube-dns-788979dc8f-gwv55                              4/4     Running   0          2h
    kube-dns-autoscaler-79b4b844b9-s9lx8                   1/1     Running   0          2h
    kube-proxy-gke-jenkins-cd-default-pool-8f0e22f5-4zfk   1/1     Running   0          2h
    kube-proxy-gke-jenkins-cd-default-pool-8f0e22f5-zxzx   1/1     Running   0          2h
    l7-default-backend-5d5b9874d5-nvq84                    1/1     Running   0          2h
    metrics-server-v0.2.1-7486f5bd67-hr9ss                 2/2     Running   0          2h
    ```

    All Kubernetes services are running in the `kube-system` namespace.

Exercises
---------

1. Create production namespace

   Create a namespace called `prod` using command line without YAML file.
   Look at [Kubernetes documentation](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands#-em-namespace-em-) to find out exact syntax.
