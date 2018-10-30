Deploy Pipeline
------

Modify the pipeline to deploy the application.

1. Create `production` namespace
    ```
    $ kubectl create ns production
    ```

1. Create secret with the MySQL administrator password in the production namespace

    ```
    $ kubectl -n production create secret generic mysql --from-literal=password=root
    secret/mysql created
    ```

1. Add container image with `kubectl`

    ```yaml
    - name: kubectl
      image: gcr.io/cloud-builders/kubectl
      command:
      - cat
      tty: true
    ```

1. Add deployment stage after build stage

    ```java
    stage('Deploy Production') {
        // Production branch
        when { branch 'master' }
        steps{
          container('kubectl') {
          // Change deployed image in canary to the one we just built
            sh("sed -i.bak 's#REPLACE_WITH_IMAGE#${imageTag}#' ./k8s/production/*.yaml")
            sh("kubectl --namespace=production apply -f k8s/services/")
            sh("kubectl --namespace=production apply -f k8s/production/")
            sh("sleep 60 # Allowing IaaS time to respond")
            sh("echo http://`kubectl --namespace=production get service/${feSvcName} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'` > ${feSvcName}")
          }
        }
    }
    ```

1. Commit the changes to `master`

    ```
    git add .
    git commit -m "Add deployment"
    git push origin master
    ```

1. Watch the pipeline tests, builds and deploys the application.
