Create a Kubernetes Cluster
===========================

Module objectives
-----------------

- create a cluster using `gcloud` tool
- configure `kubectl` tool
- install Helm client
- deploy Tiller

---

In this module you will use Google Kubernetes Engine (GKE) managed service to deploy a Kubernetes cluster.

1. Create a cluster running two `n1-standard-2` worker nodes

    ```shell
    gcloud container clusters create jenkins-cd \
    --num-nodes 2 \
    --machine-type n1-standard-2 \
    --cluster-version 1.10.7-gke.6 \
    --labels=project=jenkins-workshop \
    --image-type COS \
    --enable-autorepair \
    --no-enable-basic-auth \
    --no-issue-client-certificate \
    --enable-ip-alias \
    --metadata disable-legacy-endpoints=true \
    --scopes "https://www.googleapis.com/auth/projecthosting,cloud-platform,compute-rw,storage-rw,service-control,service-management"
    ```

2. Get credentials for the cluster

    ```shell
    $ gcloud container clusters get-credentials jenkins-cd
    Fetching cluster endpoint and auth data.
    kubeconfig entry generated for jenkins-cd.
    ```

3. Verify that you can connect to the cluster

    ```shell
    $ kubectl get pods
    No resources found.
    ```

Cluster is up.

Install Helm
------------

Helm is a package manager for Kubernetes. You will use it to install Jenkins.

Helm packages called Charts contain application itself, metadata and deployment automation scripts. There is a [repository](https://github.com/helm/charts) with Charts for the most common products including Jenkins. 

Helm has two parts: `helm` CLI and Tiller Kubernetes service.

Install Helm into `$HOME` directory as Cloud Shell erases everything else on disk between restarts.

1. Download the Helm binary

    ```shell
    wget https://storage.googleapis.com/kubernetes-helm/helm-v2.11.0-linux-amd64.tar.gz
    ```

1. Extract Helm client

    ```shell
    tar zxfv helm-v2.11.0-linux-amd64.tar.gz
    cp linux-amd64/helm .
    ```

1. Grant `cluster-admin` role to your account
    
    ```shell
    kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)
    ```

1. Create `tiller` service account with the `cluster-admin` role

    ```shell
    kubectl create serviceaccount tiller --namespace kube-system
    kubectl create clusterrolebinding tiller-admin-binding --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    ```

1. Deploy Tiller

    ```shell
    ./helm init --service-account=tiller
    ./helm update
    ```

1. Verify that both parts of Helm are up and running

    ```shell
    ./helm version
    Client: &version.Version{SemVer:"v2.11.0", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
    Server: &version.Version{SemVer:"v2.11.0", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
    ```
    
Module summary
--------------

You created a GKE Kubernetes cluster, configured `kubectl` CLI and deployed Helm.

In the next module you will deploy Jenkins.

Optional Exercises
-------------------
 
### Resize node pool
 
The common operation when manging k8s clusters is to change the capacity of the cluster.
 
Try to add one node using command `gcloud beta container clusters resize`. You may always get help with the `--help` flag.
 
### Changing the scope
 
Sometimes you need to migrate your workloads to the different node pool. The example use cases include changing the scope of node permissions. In this exercise you will create a new node pool, migrate the workload and then delete the default node pool.

- create a new node pool. For simplicity, it should be identical to the default node poll you have created before when provisioning a cluster.
- cordon the nodes of the default pool so no pods are scheduled to them
- drain the nodes to trigger eviction of the running pods
- delete the default node pool when all the pods are running
