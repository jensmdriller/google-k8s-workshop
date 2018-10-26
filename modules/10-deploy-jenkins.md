Deploy Jenkins to GKE
=====================

In this module you will deploy Jenkins on GKE to create and execute CI/CD pipelines.

---

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

Configure Jenkins
-----------------
   
Look at possible configuration options: https://github.com/helm/charts/blob/master/stable/jenkins/README.md#configuration

1. Start with empty `jenkins/values.yaml`

1. Add five sections

    - `Master`: configuration for Jenkins master
    - `Agent`: configuration for Jenkins agent
    - `Persistence`: configure Jenkins master disk
    - `NetworkPolicy`: limit network communications
    - `RBAC`: account and permissions configuration

    ```file: jenkins/values.yaml
    Master:
    Agent:
    Persistence:
    NetworkPolicy:
    rbac:
    ```
1. Set disk size to `100Gi`

    ```
    Persistence:
        Size: 100Gi
    ```
1. Disable network policy for now. You will enable it later while doing the Security module.

    ```
    NetworkPolicy:
        Enabled: false
    ```
1. Set the API version for the NetworkPolicy

    ```
    NetworkPolicy:
        Enabled: false
        ApiVersion: networking.k8s.io/v1
    ```

1. Install Default RBAC roles and bindings

    ```
    rbac:
        install: true
        serviceAccountName: cd-jenkins
    ```

1. Enable Kubernetes plugin jnlp-agent podTemplate

    ```
    Agent:
        Enabled: false
    ```
1. Set master resource limits (or requests?). 1 CPU and 3.5 Gb of memory.

    ```
    Master:
        requests:
            cpu: "1"
            memory: "3500Mi"
        limits:
            cpu: "1"
            memory: "3500Mi"
    ```

1. Tell Jenkins to use all the memory available because it is a single process in container

    ```
    Master:
        JavaOpts: "-Xms3500m -Xmx3500m"
    ```

1. Expose Jenkins UI using Cloud Load Balancer

    ```
    Master:
        ServiceType: LoadBalancer
    ```

    Another option is `ClusterIP` which creates virtual IP inside the cluster. You may proxy this IP with `kubeproxy` to your local worstation and access it as if Jenkins was running on `localhost`.

1. Plugins extend Jenkins functionality. We will use several

    - __kubernetes__: launch builds in k8s containers
    - __workflow-aggregator__: A suite of plugins that lets you orchestrate automation, simple or complex
    - __workflow-job__: Defines a new job type for pipelines and provides their generic user interface
    - __credentials-binding__: Allows credentials to be bound to environment variables for use from miscellaneous build steps
    - __git__: check out application code from the repo
    - __google-oauth-plugin__: use credentials from the virtual machine metadata to access GCP services
    - __google-source-plugin__: credential provider to use GCP OAuth Credentials to access source code from Google Source Repositories

    ```
    Master:
        InstallPlugins:
            - kubernetes:1.12.2
            - workflow-aggregator:2.5
            - workflow-job:2.24
            - credentials-binding:1.16
            - git:3.9.1
            - google-oauth-plugin:0.6
            - google-source-plugin:0.3
    ```

    You can find Jenkins plugins at URL: https://plugins.jenkins.io/

1. Now the `jenkins/values.yaml` file should look like

    ```
    Master:
    InstallPlugins:
        - kubernetes:1.12.2
        - workflow-aggregator:2.5
        - workflow-job:2.24
        - credentials-binding:1.16
        - git:3.9.1
        - google-oauth-plugin:0.6
        - google-source-plugin:0.3
    requests:
        cpu: "1"
        memory: "3500Mi"
    limits:
        cpu: "1"
        memory: "3500Mi"
    JavaOpts: "-Xms3500m -Xmx3500m"
    ServiceType: LoadBalancer
    Agent:
    Enabled: false
    Persistence:
    Size: 100Gi
    NetworkPolicy:
    Enabled: false
    ApiVersion: networking.k8s.io/v1
    rbac:
    install: true
    serviceAccountName: cd-jenkins
    ```

Deploy Jenkins
--------------

1. Deploy Jenkins chart using Helm

    ```shell
    helm install --name cd \
        -f jenkins/values.yaml \
        --version 0.16.6 \
        stable/jenkins \
        --wait
    ```

    `--name` sets the name of Jenkins deployment called _release_. Using this name you can update and delete release in future.

    `-f jenkins/values.yaml` tells Helm to override default chart configuration values with the values from `jenkins/values.yaml`.

    With `--version` flag you choose specific versions of Jenkins chart to install. Note that chart version differs from the Jenkins version.

    `stable/jenkins` is the name of Helm chart

    By default `helm install` does not wait until deployment complete. `--wait` flag tells it to wait until Kubernetes creates all of Jenkins resources. It still takes time for Jenkins to boot so dashboard will not be available immediately after the install completes.

1. Wait until Jenkins pod goes to the `Running` state and the container is in the `READY` state:

    ```shell
    $ kubectl get pods --watch
    NAME                          READY     STATUS    RESTARTS   AGE
    cd-jenkins-7c786475dd-vbhg4   1/1       Running   0          1m
    ```

1. Run the following command to get the URL of the Jenkins service

    ```shell
    export SERVICE_IP=$(kubectl get svc --namespace cd cd-jenkins --template "{{ range (index .status.loadBalancer.ingress 0) }}{{ . }}{{ end }}")
    echo http://$SERVICE_IP:8080/login
    ```

    `--watch` streams events from Kubernetes and contantly updates the Pod status

1. Now, check that the Jenkins Service was created properly:

    ```shell
    $ kubectl get svc -n cd
    NAME               TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)          AGE
    cd-jenkins         LoadBalancer   10.47.255.13    35.236.21.7   8080:31027/TCP   3m
    cd-jenkins-agent   ClusterIP      10.47.246.125   <none>        50000/TCP        3m
    kubernetes         ClusterIP      10.47.240.1     <none>        443/TCP          12m
    ```

We installed Jenkins with [Kubernetes Plugin](https://wiki.jenkins-ci.org/display/JENKINS/Kubernetes+Plugin). This plugin launches Pods with executors each time Jenkins master requests them. After Jenkins executor completed the task Jenkins Kubernetes plugin disposes the Pod and frees the resources.

Note that this service exposes ports `8080` and `50000` for any pods that match the `selector`. This will expose the Jenkins web UI and builder/agent registration ports within the Kubernetes cluster.

Additionally the `cd-jenkins` services is exposed using a LoadBalancer so that it is accessible from outside the cluster.

Connect to Jenkins
------------------

Jenkins requires username and password. `admin` is default username. Helm generates admin password and stores in the Kubernetes secret `cd-jenkins`.

1. Get an admin password

    ```shell
    printf $(kubectl get secret cd-jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
    ```

1. Log in with username `admin` and your auto generated password.

![](docs/img/jenkins-login.png)

Module summary
--------------

You deployed Jenkins to GKE Kubernetes cluster. Now you can build continuous deployment pipeline. But before let's take a look at the sample application this pipeline will deploy.

Optional exercises
------------------

1. What resources were created during Jenkins deployment?
1. If the service was exposed internally using `ClusterIP` how can you access it?
