Volumes
=======

Module objectives
-----------------

Add a volume to the deployment 

In this lab you will add persistent storage volume to the MySQL pod.

1. Run the following command to make sure that your kubernetes installation has default storage class

    ```
    $ kubectl get storageclass
    ```

    For GCE default storage class should have `kubernetes.io/gce-pd` provisioner. This provisioner creates GCE persistent disks for any requested persistent volume.

1. Add Persistent Volume Claim definition to `k8s/training/data-volume.yaml`

    ```
    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      name: mysql-volumeclaim
    spec:
      accessModes:
        - ReadWriteOnce
      resources:
        requests:
          storage: 200Gi
    ```
 
1. Add mysql deployment definition to `k8s/training/db-persistent.yaml`

    ```
    apiVersion: extensions/v1beta1
    kind: Deployment
    metadata:
      name: mysql
      labels:
        app: mysql
        role: db
        env: production
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
              volumeMounts:
                - name: mysql-persistent-storage
                  mountPath: /var/lib/mysql
          volumes:
            - name: mysql-persistent-storage
              persistentVolumeClaim:
                claimName: mysql-volumeclaim
    ```

1. Delete the previous deployment

    ```
    $ kubectl delete deployment/mysql
    deployment.extensions "mysql" deleted
    ```

1. Create first persistent volume claim and then database using it

    ```
    $ kubectl apply -f k8s/training/data-volume.yaml
    $ kubectl apply -f k8s/training/db-persistent.yaml
    ```

1. Verify that a PersistentVolume got dynamically provisioned

    ```
    $ kubectl get pvc
    ```

    It can take up to a few minutes for the PVs to be provisioned and bound.

1. Verify that the Pod is running by running the following command

    ```
    $ kubectl get pods
    ```

Now you have MySQL database running inside Kubernetes cluster on GCP that stores data persistently on the volume.

Exercise 2 (Optional): Static persistent volume provisioning
------------------------------------------------------------

1. Delete mysql deployment and persistent volume claim. 
1. Manually create a persistent disk in GCE. (Compute engine -> Disks -> Create disk, use `source type = none` to create an empty disk) or use the following command

    ```
    gcloud compute disks create --size=200GB --zone=us-west1-c my-data-disk
    ```

1. Change mysql deployment to use your persistent disk instead of persistent volume claim. Find `gcePersistentDisk` section in [this](https://kubernetes.io/docs/concepts/storage/volumes/) document for reference.

### Exercise 3 (Optional): Observe how persistent volume is reattached 

1. Open gcme application, enter some notes.
1. Exec inside mysql pod and kill mysql process.
1. Wait for kubernetes to restart the pod.
1. Make sure that persistend data isn't lost.
