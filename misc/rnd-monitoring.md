Objectives
----------

- enable monitoring for an existing Kubernetes cluster
- examine metrics in the Stackdriver console
- build custom Stackdriver dashboard for CI/CD pipeline and service
- enable Stackdriver logging
- view Jenkins logs in the Stackdriver console

Enable montoring
----------------

```
gcloud beta container clusters update jenkins-cd \
  --monitoring-service monitoring.googleapis.com
```

Note that if you initially created your cluster without monitoring, and want to enable it later, the cluster's node pools might not have the necessary GCP scope to interact with Stackdriver Monitoring. As a workaround, you can create a new node pool with the same number of nodes and the necessary scope as follows:

```
gcloud container node-pools create nodes-03 \
    --cluster jenkins-cd \
    --num-nodes 2 \
    --machine-type n1-standard-2 \
    --node-labels=owner=lexsys,project=jenkins-workshop \
    --image-type COS \
    --enable-autorepair \
    --scopes "https://www.googleapis.com/auth/monitoring,cloud-platform"
 
 $ gcloud container node-pools list --cluster jenkins-cd
NAME          MACHINE_TYPE   DISK_SIZE_GB  NODE_VERSION
default-pool  n1-standard-2  100           1.10.5-gke.3

$ gcloud container node-pools delete default-pool --cluster jenkins-cd
```

It takes pretty long to create a new node pool in the existing cluster.

Optional exercises: Extending infrastructure metrics with cAdvisor

Stackdriver Monitoring is enabled by default when you create a new cluster using the gcloud command-line tool or the GCP Console. - OK

Is Stackdriver monitoring agent already installed on the virtual machines of the cluster?

Does Stackdriver monitoring enabled on the API level when I create cluster?

```
$ gcloud beta container operations list

$ gcloud beta container operations cancel operation-1533028657521-59a1c255
Are you sure you want to cancel operation
operation-1533028657521-59a1c255?

Do you want to continue (Y/n)?  y

ERROR: (gcloud.beta.container.operations.cancel) INVALID_ARGUMENT: Only node upgrade operations can be cancelled.
```

How to cancel the operation that is running forever?

How to show cluster memory allocation?

Optional exercise: create Jenkins check policy. Challenge: Jenkins is not publicly exposed on the external IP.

Optional exercise: create uptime check for the application. Maybe not very exciting?

Custom Jenkins metrics need several pieces to work with GCP.

```
kubectl cordon gke-jenkins-cd-default-pool-778ba61d-m6rw
kubectl drain gke-jenkins-cd-default-pool-778ba61d-m6rw --ignore-daemonsets

kubectl cordon gke-jenkins-cd-default-pool-778ba61d-kqzn
kubectl drain gke-jenkins-cd-default-pool-778ba61d-kqzn --ignore-daemonsets --delete-local-data
WARNING: Deleting pods with local storage: cd-jenkins-666ddbb8fd-nsf7l; Ignoring DaemonSet-managed pods: fluentd-gcp-v3.0.0-7h4dp

kubectl get pods -o wide --all-namespaces

Still some pods are running on the default node pool

gcloud container node-pools delete default-pool --cluster jenkins-cd
```

Some credentials lost when moving to another pool.

Configuring logging
-------------------

System logs are collected from the cluster's components, such as docker and kubelet. Events are logs about activity in the cluster, such as the scheduling of Pods.

get logs for:

- cluster operations
- pods
- node pool operations

goto advanced mode

```
resource.labels.namespace_id="default"
resource.labels.zone="europe-west3-c"
resource.labels.pod_id="cd-jenkins-666ddbb8fd-fbhkj"
resource.labels.project_id="project-aleksey-zalesov"
resource.labels.cluster_name="jenkins-cd"
resource.labels.container_name="cd-jenkins"
```

build custom Stackdriver dashboard for CI/CD pipeline and service - not done yet

Clean Up
--------

```
gcloud container clusters delete jenkins-cd

# delete source code repo
# how to delete Stackdriver account or stop charges?
```
