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
    kubectl create namespace quota
    ```

2. Create template quota-pod.yaml

    ```
    apiVersion: v1
    kind: ResourceQuota
    metadata:
      name: pod-demo
    spec:
      hard:
        pods: "2"
    ```

3. Create the resource quota

    ```
    kubectl apply -f quota-pod.yaml`
    ```

4. Get information about created quota

    ```
    kubectl get resourcequota pod-demo --namespace=quota --output=yaml
    ```

5. Create a deployment with three replicas

    ```
    apiVersion: apps/v1
    kind: Deployment
    metadata:
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
    kubectl apply -f quota-deployment.yaml
    ```

6. Now check the status of the Deployment

    ```
    kubectl get deployment pod-quota-demo --namespace=quota --output=yaml
    ```

    You will see that there were only 2 replicas out of 3 created

    ```
    spec:
      replicas: 3
    status:
      availableReplicas: 2
    ```

7. Delete the deployment

    ```
    kubectl delete deployment pod-quota-demo
    ```

## Exercise 02: limit the CPU & memory available for a namespace

1. Create ResourceQuota template in quota-mem-cpu.yaml

    ```
    apiVersion: v1
    kind: ResourceQuota
    metadata:
      name: mem-cpu-demo
    spec:
      hard:
        requests.cpu: "1"
        requests.memory: 1Gi
        limits.cpu: "2"
        limits.memory: 2Gi
    ```

    ```
    kubectl apply quota-mem-cpu.yaml
    ```

2. Every container must have a memory request, memory limit, cpu request, and cpu limit. Try to create a pod without these specs and see the error.

    ```file=quota-pod.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: quota-mem-cpu-demo
    spec:
      containers:
      - name: quota-mem-cpu-demo-ctr
        image: nginx
    ```

    ```
    kubectl apply -f quota-pod.yaml
    ```

3. Now let's specify the limits for the pod and try to create it again

    ```file=quota-pod.yaml
    apiVersion: v1
    kind: Pod
    metadata:
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
    kubectl apply -f quota-pod.yaml
    ```

    The pod is created.

4. See the resource usage in the namespace

    ```
    kubectl get resourcequota mem-cpu-demo --namespace=quota --output=yaml

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

5. Try to create the second pod replicas. This will exceed memory quota and throw an error.

    ```file=quota-pod2.yaml
    apiVersion: v1
    kind: Pod
    metadata:
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
    kubectl apply -f quota-pod2.yaml
    ```

6. Delete all running pods in the namespace

## Exercise 03 (optional): set the default request and limit for a namespace

1. Create LimitRange object

    ```file=limit-range.yaml
    apiVersion: v1
    kind: LimitRange
    metadata:
      name: limit-range
    spec:
      limits:
      - default:
          cpu: 1
          memory: "800Mi"
        defaultRequest:
          cpu: 0.5
          memory: "600Mi"
        type: Container
    ```

    ```
    kubectl apply -f limit-range.yaml
    ```

1. Create a pod without specifying limits and requests

    ```file=pod.yaml
    apiVersion: v1
    kind: Pod
    metadata:
      name: default-demo
    spec:
      containers:
      - name: default-demo-ctr
        image: nginx
    ```

    ```
    kubectl apply -f pod.yaml
    ```

1. Check the limits for created pod

    ```
    kubectl get pod default-demo --output=yaml --namespace=quota-01
    ```

Clean up
--------

1. Delete the namespace `quota`

    ```
    $ kubectl delete ns quota
    ```
