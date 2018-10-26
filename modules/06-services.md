Services
========

Module objectives
-----------------

- create db, backend and frontend services
- examine Load Balancer IP in the Cloud Console

---

Theory
------

A service is an abstraction for pods, providing a stable, virtual IP (VIP) address.

While pods may come and go, services allow clients to reliably connect to the containers running in the pods, using the VIP. The virtual in VIP means it’s not an actual IP address connected to a network interface but its purpose is purely to forward traffic to one or more pods.

Keeping the mapping between the VIP and the pods up-to-date is the job of kube-proxy, a process that runs on every node, which queries the API server to learn about new services in the cluster.

Service types

- ClusterIP: Creates a VIP in a pod network, not accessible from outside
- NodePort: Allocates a port from dynamic range (30000-32767) for every node
- LoadBalancer: Creates a Cloud load balancer

Proxy modes

- userspace
- iptables
- ipvs

Applications can discover services using environment variables or DNS. DNS requires cluster addon like `kube-dns` or `coreDNS`.

More information about services: https://kubernetes.io/docs/concepts/services-networking/service/

---

1. Save the following file as `k8s/training/db-service.yml` and use `kubectl apply -f k8s/training/db-service.yml` command to create the db service:

  ```
  apiVersion: v1
  kind: Service
  metadata:
    name: db
    labels:
      app: mysql
  spec:
    type: ClusterIP
    ports:
      - port: 3306
    selector:
      app: mysql

  ```

1. Update the backend deployment manifest and configure backend to connect to the db pod using DNS name `db` rather than hardcoded IP address. Redeploy the backend.

1. Save the following file as `k8s/training/backend-service.yml` and use `kubectl apply -f k8s/training/backend-service.yml` command to create the backend service:

    ```
    kind: Service
    apiVersion: v1
    metadata:
      name: backend
    spec:
      ports:
      - name: http
        port: 8080
        targetPort: 8080
        protocol: TCP
      selector:
        role: backend
        app: gceme
    ```

1. Update the frontend deployment manifest and configure frontend to connect to the backend pod using DNS name `backend` rather than hardcoded IP address. Redeploy the frontend.

1. Save the following file as `k8s/training/frontend-service.yml` and use `kubectl apply -f k8s/training/frontend-service.yml` command to create the frontend service:

    ```
    kind: Service
    apiVersion: v1
    metadata:
      name: frontend
    spec:
      type: LoadBalancer
      ports:
      - name: http
        port: 80
        targetPort: 80
        protocol: TCP
      selector:
        app: gceme
        role: frontend
    ```

1.  Run `kubectl get services` to list all services.

1. Retrieve the External IP for the frontend service: **This field may take a few minutes to appear as the load balancer is being provisioned**:

  ```shell
  $ kubectl get service frontend
  NAME             TYPE           CLUSTER-IP     EXTERNAL-IP    PORT(S)        AGE
  frontend         LoadBalancer   10.35.254.91   35.196.48.78   80:31088/TCP   1m
  ```

1. Copy the external ip and open it in your browser. Make sure that the application is working correctly. 

1. In GCP Cloud Console, find and investigate the external IP address that the `LoadBalancer` service type created
    * VPC Network -> External IP addresses


Exercises
---------
1: Blue green deployment
    * Add the label "app=blue" to the frontend deployment.
    * Modify frontend service to use the same label 
    * Create a second deployment with label "app=green". The deployment should contain the same application. (in a real scenario this should be a different version of the app, but for this exercise, you can use exactly the same app)
    * Change service selector to "app=green" and make sure that now the service switched to the second deployment.
    * Delete the old deployment

