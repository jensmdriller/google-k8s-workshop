Quotas
======

Module objectives
-----------------

- Limit number of pods running in the namespace
- Limit the CPU & memory available for a namespace
- Set the default request and limit for a namespace

---

Theory
------

Some resources like CPU and network may be throttled - they are called compressible resources. Other like memory and storage are incompressible.

To enable for the cluster pass `ResourceQuota` flag as an argument for API server option `--enable-admission-plugins=`

Resource Request

- The Kubernetes scheduler will place a pod on the node that has specified amount of resources
- A pod is guaranteed the amount of resources it has requested
- Scheduling will fail for a pod that has requested more resources than is available in the cluster or has exceeded the quota

Resource Limit

- A pod that exceeds its limit of incompressible resource will be terminated
- A pod that exceeded limit of compressible resource will be throttled
- A pod restart policy defines the behavior of the terminated pod

Always Set Limits on Your Pods! QoS levels:

- Guaranteed: top-priority, may be killed only when exceed their limits
- Burstable: guaranteed minimum resource amount and can use more resources when available
- Best-effort: first to be killed under pressure

To give pods maximum QoS level, set request and limit to the same value.

Quota measures usage if a resource matches the intersection of enumerated scopes

- Terminating - Match pods where .spec.activeDeadlineSeconds >= 0
- NotTerminating - Match pods where .spec.activeDeadlineSeconds is nil
- BestEffort - Match pods that have best effort quality of service.
- NotBestEffort - Match pods that do not have best effort quality of service.

`ResourceQuota` constraint to limit aggregated resource consumption per namespace

One can limit these resource types:

- compute (cpu and memory)
- extended resources (GPU) (v1.10)
- storage
- object count (v1.9)

Compute resource quota constrains these resource types:

- limits.cpu
- limits.memory
- requests.cpu
- requests.memory

Storage Resource Quota constrains these resource types:

- requests.storage
- persistentvolumeclaims

Also one can limit consumption based on `StorageClass`

One needs to specify requests or limits for each incoming container if quota has value specified for one of those. LimitRange object specifies minimum and maximum for incoming objects. If incoming object does not specify the value it gets default value from the LimitRange.

Further reading:

1. [Resource quality of service implementation details](https://github.com/kubernetes/community/blob/master/contributors/design-proposals/node/resource-qos.md)
1. [Specifying CPU limits for a pod](https://kubernetes.io/docs/tasks/configure-pod-container/assign-cpu-resource/)
1. [Resource types in Kubernetes](https://kubernetes.io/docs/concepts/configuration/manage-compute-resources-container/)
1. [Quota reference documentation](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
1. [Setting storage limits](https://kubernetes.io/docs/tasks/administer-cluster/quota-api-object/)
1. [Setting memory limits( https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/quota-memory-cpu-namespace/)]
1. [LimitRange usage example](https://kubernetes.io/docs/tasks/administer-cluster/limit-storage-consumption/)


---

## Exercise 01: limit the number of pods running in the namespace

You can limit the number of objects user can create in the namespace. For instance, in this excercise you will limit the number of running pods to 2.

We will use a separate namespace for this exercise.

1. Create test namespace for this excercise

    ```
    $ kubectl create namespace quota
    ```

1. Create template quota-pod.yaml

    ```yaml
    apiVersion: v1
    kind: ResourceQuota
    metadata:
      namespace: quota
      name: pod-demo
    spec:
      hard:
        pods: "2"
    ```

1. Create the resource quota

    ```
    $ kubectl apply -f quota-pod.yaml
    ```

1. Get information about created quota

    ```
    $ kubectl get resourcequota pod-demo --namespace=quota --output=yaml
    ```

1. Create a deployment with three replicas

    ```yaml
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      namespace: quota
      name: pod-quota-demo
    spec:
      selector:
        matchLabels:
          purpose: quota-demo
      replicas: 3
      template:
        metadata:
          labels:
            purpose: quota-demo
        spec:
          containers:
          - name: pod-quota-demo
            image: nginx
    ```

    ```
    $ kubectl apply -f quota-deployment.yaml
    ```

1. Now check the status of the Deployment

    ```
    $ kubectl get deployment pod-quota-demo --namespace=quota --output=yaml
    ```

    You will see that there were only 2 replicas out of 3 created

    ```yaml
    spec:
      replicas: 3
    status:
      availableReplicas: 2
    ```

1. Delete the deployment

    ```
    $ kubectl delete deployment pod-quota-demo --namespace=quota
    ```

## Exercise 02: limit the CPU & memory available for a namespace
---------

1. Create ResourceQuota template in quota-mem-cpu.yaml

    ```yaml
    apiVersion: v1
    kind: ResourceQuota
    metadata:
      namespace: quota
      name: mem-cpu-demo
    spec:
      hard:
        requests.cpu: "1"
        requests.memory: 1Gi
        limits.cpu: "2"
        limits.memory: 2Gi
    ```

    ```
    $ kubectl apply -f quota-mem-cpu.yaml
    ```

1. Now every container in the quote namespace must have a memory request, memory limit, cpu request, and cpu limit. Try to create a pod without these specs and see the error. Create quota-pod.yaml.

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      namespace: quota
      name: quota-mem-cpu-demo
    spec:
      containers:
      - name: quota-mem-cpu-demo-ctr
        image: nginx
    ```

    ```
    $ kubectl apply -f quota-pod.yaml
    ```

1. Now let's specify the limits for the pod and try to create it again, modify quota-pod.yaml.

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      namespace: quota
      name: quota-mem-cpu-demo
    spec:
      containers:
      - name: quota-mem-cpu-demo-ctr
        image: nginx
        resources:
          limits:
            memory: "800Mi"
            cpu: "800m"
          requests:
            memory: "600Mi"
            cpu: "400m"
    ```

    ```
    $ kubectl apply -f quota-pod.yaml
    ```

    The pod is created.

1. See the resource usage in the namespace

    ```
    $ kubectl get resourcequota mem-cpu-demo --namespace=quota --output=yaml

    status:
      hard:
        limits.cpu: "2"
        limits.memory: 2Gi
        requests.cpu: "1"
        requests.memory: 1Gi
      used:
        limits.cpu: 800m
        limits.memory: 800Mi
        requests.cpu: 400m
        requests.memory: 600Mi
    ```

1. Try to create the second pod replicas. This will exceed memory quota and throw an error. Create quota-pod2.yaml.

    ```yaml
    apiVersion: v1
    kind: Pod
    metadata:
      namespace: quota
      name: quota-mem-cpu-demo-2
    spec:
      containers:
      - name: quota-mem-cpu-demo-ctr
        image: nginx
        resources:
          limits:
            memory: "800Mi"
            cpu: "800m"
          requests:
            memory: "600Mi"
            cpu: "400m"
    ```

    ```
    $ kubectl apply -f quota-pod2.yaml
    ```

1. Delete all running pods in the namespace

## Exercise 03 (optional): set the default request and limit for a namespace
---------

1. Create [LimitRange](https://kubernetes.io/docs/tasks/administer-cluster/manage-resources/memory-default-namespace/) object
1. Create a pod without specifying limits and requests
1. Use 'kubectl describe' command to check the limits for created pod

Clean up
--------

1. Delete the namespace `quota`

    ```
    $ kubectl delete ns quota
    ```
