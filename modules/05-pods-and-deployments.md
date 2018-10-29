Pods and Deployments
===========

Deploy the sample app to Kubernetes
-----------------------------------

In this section, you will deploy the mysql database, `gceme` frontend and backend to Kubernetes using Kubernetes manifest files that describe the environment that the `gceme` binary/Docker image will be deployed to. They use the `gceme` Docker image that you've built in one of the previous modules.

1. First change directories to the sample-app:

    ```
    $ cd sample-app
    ```

1. Create secret with the MySQL administrator password

    ```
    $ kubectl create secret generic mysql --from-literal=password=root
    secret/mysql created
    ```

1. Create the manifest to deploy MySQL database as k8s/training/db.yml:

    ```yaml
    apiVersion: extensions/v1beta1 
    kind: Deployment
    metadata:
      name: mysql
      labels:
        app: mysql
        role: db
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: mysql
      template:
        metadata:
          labels:
            app: mysql
        spec:
          containers:
          - image: mysql:5.6
            name: mysql
            env:
            - name: MYSQL_ROOT_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: mysql
                  key: password
            ports:
            - containerPort: 3306
              name: mysql
    ```

1. Deploy MySQL to Kubernetes

    ```
    $ kubectl apply -f k8s/training/db.yml
    ```

1. List all pods and replica sets

    ```
    $ kubectl get rs
    NAME                           DESIRED   CURRENT   READY     AGE
    mysql-6bbbfb86d                1         1         1         30m

    $ kubectl get pod
    NAME                                 READY     STATUS             RESTARTS   AGE
    mysql-6bbbfb86d-vdq7m                1/1       Running            0          29m
    ```
    As you can see under the hood the deployment creates a replica set and a pod with random postfixes. Copy the name of the mysql pod

1. Find out the mysql pod IP address.

    ```
    $ kubectl describe pod mysql-6bbbfb86d-vdq7m | grep IP
    ```
    It is also useful to take a look at the full output of the `kubectl describe pod` command.

1. Create the manifest for the backend application, save it as `k8s/training/backend.yml` and deploy it to kubernetes using `kubectl apply` command.

    ```yaml
    kind: Deployment
    apiVersion: extensions/v1beta1
    metadata:
      name: gceme-backend-dev
    spec:
      replicas: 1
      template:
        metadata:
          name: backend
          labels:
            app: gceme
            role: backend
            env: dev
        spec:
          containers:
          - name: backend
            image: <REPLACE_WITH_YOUR_OWN_IMAGE>
            env:
              - name: MYSQL_ROOT_PASSWORD
                valueFrom:
                  secretKeyRef:
                    name: mysql
                    key: password
            resources:
              limits:
                memory: "500Mi"
                cpu: "100m"
            imagePullPolicy: Always
            readinessProbe:
              httpGet:
                path: /healthz
                port: 8080
            command: ["sh", "-c", "app -port=8080 -db-host=<REPLACE_WITH_MYSQL_IP> -db-password=$MYSQL_ROOT_PASSWORD" ]
            ports:
            - name: backend
              containerPort: 8080

    ```
    Don't forget to replace the image and the mysql ip address.

1. Find out the backend pod IP address in a similar way how we did it for mysql pod.

1. Create the manifest for the frontend application, save it as `k8s/training/frontend.yml` and deploy it to kubernetes using `kubectl apply` command.

    ```yaml
    kind: Deployment
    apiVersion: extensions/v1beta1
    metadata:
      name: gceme-frontend-dev
    spec:
      replicas: 1
      template:
        metadata:
          name: frontend
          labels:
            app: gceme
            role: frontend
            env: dev
        spec:
          containers:
          - name: frontend
            image: <REPLACE_WITH_YOUR_OWN_IMAGE>
            resources:
              limits:
                memory: "500Mi"
                cpu: "100m"
            imagePullPolicy: Always
            readinessProbe:
              httpGet:
                path: /healthz
                port: 80
            command: ["sh", "-c", "app -frontend=true -backend-service=http://<REPLACE_WITH_BACKEND_IP>:8080 -port=80"]
            ports:
            - name: frontend
              containerPort: 80
    ```

1. In the cloud console go to the 'Compute Engine' -> 'VM instances' page and ssh to any of the nodes. This is necessary because by default pods have only cluster-internal IP addresses and are not available from the outside.

1. From the node try to connect to the backend and frontend using curl
    ```
    curl <backend-ip>:8080
    curl <frontend-ip>
    ```

Optional Exercises
-------------------

1. Use `kubectl exec` command to get inside one of the pods and kill the main process. Observe how kubernetes restarts the pod.

1. Create nginx deployment

   Use one of the previously deployed manifests as an example and create a deployment that runs [nginx](https://hub.docker.com/_/nginx/) docker image. Ssh on a nod and make sure that nginx is running.
