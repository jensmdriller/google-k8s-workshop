Workshop log
============

Get account

- using the work account

Enable APIs

- Compute Engine
- Kubernetes Engine 
- Cloud Container Builder

There are two ways: web console and cloud SKD.

```
$ git clone git@github.com:lexsys27/google-k8s-workshop.git
```

gcloud is already set up

Create Jenkins cluster
----------------------

```
gcloud config set container/new_scopes_behavior true

gcloud container clusters create jenkins-cd \
--num-nodes 2 \
--machine-type n1-standard-2 \
--cluster-version 1.10.5-gke.3 \
--labels=owner=lexsys,project=jenkins-workshop \
--image-type UBUNTU \
--enable-autorepair \
--scopes "https://www.googleapis.com/auth/projecthosting,cloud-platform"
```

How do authorization scopes work?

To learn available cluster versions:

```
gcloud container get-server-config
..
validImageTypes: UBUNTU
validMasterVersions: 1.10.5-gke.3
validNodeVersions: 1.10.5-gke.3
```

What is `COS`? Containet Optimised OS by Google - see the [docs](https://cloud.google.com/container-optimized-os/docs/)

Warnings while creating the cluster:

```
WARNING: Currently node auto repairs are disabled by default. In the future this will change and they will be enabled by default. Use `--[no-]enable-autorepair` flag  to suppress this warning.
WARNING: The behavior of --scopes will change in a future gcloud release: service-control and service-management scopes will no longer be added to what is specified in --scopes. To use these scopes, add them explicitly to --scopes. To use the new behavior, set container/new_scopes_behavior property (gcloud config set container/new_scopes_behavior true).
WARNING: Starting in Kubernetes v1.10, new clusters will no longer get compute-rw and storage-ro scopes added to what is specified in --scopes (though the latter will remain included in the default --scopes). To use these scopes, add them explicitly to --scopes. To use the new behavior, set container/new_scopes_behavior property (gcloud config set container/new_scopes_behavior true).
```

Time: 130s

```
$ gcloud container clusters get-credentials jenkins-cd
Fetching cluster endpoint and auth data.
kubeconfig entry generated for jenkins-cd.

$ kubectl get pods
No resources found.
```

Install Helm
------------

Different instructions for Mac and Linux.

```
helm version
Client: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
```

How to ask only for the client version?

```
kubectl create clusterrolebinding cluster-admin-binding --clusterrole=cluster-admin --user=$(gcloud config get-value account)
```

How Kubernetes authentication system on Google Cloud works?

```
kubectl create serviceaccount tiller --namespace kube-system
kubectl create clusterrolebinding tiller-admin-binding --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
```

```
helm init --service-account=tiller
helm update
```

Configure and Install Jenkins
-----------------------------

`values.yaml` - are the plugin versions up-to-date?

```
helm install --name cd stable/jenkins -f jenkins/values.yaml --version 0.16.6 --wait
```

https://github.com/jenkinsci/kubernetes-plugin

Read the documentation for the Helm chart: helm inspect stable/jenkins

What was created:

```
NAME:   cd
LAST DEPLOYED: Tue Jul 24 13:15:21 2018
NAMESPACE: default
STATUS: DEPLOYED

RESOURCES:
==> v1/Secret
NAME        TYPE    DATA  AGE
cd-jenkins  Opaque  2     6s

==> v1/ConfigMap
NAME              DATA  AGE
cd-jenkins        4     6s
cd-jenkins-tests  1     6s

==> v1/PersistentVolumeClaim
NAME        STATUS  VOLUME                                    CAPACITY  ACCESS MODES  STORAGECLASS  AGE
cd-jenkins  Bound   pvc-78b8512d-8f2a-11e8-ba20-42010a9c01b2  108G      RWO           standard      6s

==> v1/ServiceAccount
NAME        SECRETS  AGE
cd-jenkins  1        6s

==> v1beta1/ClusterRoleBinding
NAME                     AGE
cd-jenkins-role-binding  6s

==> v1/Service
NAME              TYPE       CLUSTER-IP     EXTERNAL-IP  PORT(S)    AGE
cd-jenkins-agent  ClusterIP  10.23.242.141  <none>       50000/TCP  6s
cd-jenkins        ClusterIP  10.23.252.204  <none>       8080/TCP   6s

==> v1beta1/Deployment
NAME        DESIRED  CURRENT  UP-TO-DATE  AVAILABLE  AGE
cd-jenkins  1        1        1           0          6s

==> v1/Pod(related)
NAME                         READY  STATUS   RESTARTS  AGE
cd-jenkins-666ddbb8fd-9n7kx  0/1    Pending  0         6s
```

When the command finishes the pod is not ready yet.

```
kubectl logs cd-jenkins-666ddbb8fd-9n7kx --follow=true
kubectl get pods --watch
```

Set up port forwarding

```
export POD_NAME=$(kubectl get pods -l "component=cd-jenkins-master" -o jsonpath="{.items[0].metadata.name}")
kubectl port-forward $POD_NAME 8080:8080 >> /dev/null &
```

```
$ kubectl get svc
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)     AGE
cd-jenkins         ClusterIP   10.23.252.204   <none>        8080/TCP    4m
cd-jenkins-agent   ClusterIP   10.23.242.141   <none>        50000/TCP   4m
kubernetes         ClusterIP   10.23.240.1     <none>        443/TCP     27m
```

Connect to Jenkins
------------------

```
printf $(kubectl get secret cd-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
```

Goto `localhost:8080` and login as `admin`

You've got a Kubernetes cluster managed by Google Container Engine. You've deployed:

- a Jenkins Deployment
- a (non-public) service that exposes Jenkins to its agent containers

Manually deploy an application
------------------------------

Go through the application code.

forgot to create Jenkins namespace.

```
kubectl create namespace production

cd sample-app

$ kubectl --namespace=production apply -f k8s/production
$ kubectl --namespace=production apply -f k8s/canary
$ kubectl --namespace=production apply -f k8s/services

kubectl --namespace=production scale deployment gceme-frontend-production --replicas=4

$ kubectl --namespace=production get service gceme-frontend --watch
NAME             TYPE           CLUSTER-IP      EXTERNAL-IP     PORT(S)        AGE
gceme-frontend   LoadBalancer   10.23.248.173   35.234.85.143   80:32357/TCP   1m
```

no address in the proxy field of the app

```
export FRONTEND_SERVICE_IP=$(kubectl get -o jsonpath="{.status.loadBalancer.ingress[0].ip}"  --namespace=production services gceme-frontend)
while true; do curl http://$FRONTEND_SERVICE_IP/version; sleep 1;  done
```

Create a repository for the sample app source
---------------------------------------------

- should export the project name as a variable

```
$ git init
$ git config credential.helper gcloud.sh
$ gcloud source repos create gceme
$ git remote add origin https://source.developers.google.com/p/project-aleksey-zalesov/r/gceme

# Identify yourself
$ git config --global user.email "YOUR-EMAIL-ADDRESS"
$ git config --global user.name "YOUR-NAME"

$ git add .
$ git commit -m "Initial commit"
$ git push origin master
```

Create a pipeline
-----------------

Add service account credentials
-------------------------------

Very downting to see the versions in the terminal

`master` is not deployable. Modify `Jenkinsfile` prior to the push?

Rollback:

```
kubectl rollout undo deployment/gceme-frontend-production -n production
```

Deploy a development branch
---------------------------



