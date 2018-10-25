Services
========

Module objectives
-----------------

Add a service to cover the backend, use the backend service from the frontend, add LoadBalancer service for the frontend. https://github.com/GoogleCloudPlatform/continuous-deployment-on-kubernetes/tree/master/sample-app/k8s/services 


A service is an abstraction for pods, providing a stable, virtual IP (VIP) address.

While pods may come and go, services allow clients to reliably connect to the containers running in the pods, using the VIP. The virtual in VIP means it’s not an actual IP address connected to a network interface but its purpose is purely to forward traffic to one or more pods.

Keeping the mapping between the VIP and the pods up-to-date is the job of kube-proxy, a process that runs on every node, which queries the API server to learn about new services in the cluster.

1. Create the canary and production services:

    ```shell
    $ kubectl --namespace=prod apply -f k8s/services
    ```

1.  Run `kubectl --namespace=prod get services` to list all services.

1. Retrieve the External IP for the production services: **This field may take a few minutes to appear as the load balancer is being provisioned**:

  ```shell
  $ kubectl --namespace=prod get service gceme-frontend
  NAME             TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)        AGE
  gceme-frontend   LoadBalancer   10.35.254.91   35.196.48.78   80:31088/TCP   1m
  ```

1. Confirm that both services are working by opening the frontend external IP in your browser

```shell
$ kubectl --namespace=prod get service gceme-frontend -o jsonpath='{"http://"}{.status.loadBalancer.ingress[].ip}{"\n"}'
http://35.196.48.78
```

1. In GCP Cloud Console, find and investigate the external IP address that the `LoadBalancer` service type created
    * VPC Network -> External IP addresses


Exercises
---------

1. Optional: Investigate source code of the sample

    Look at manifests in `k8s/services` folder
