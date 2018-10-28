Deploy Pipeline
------

Modify the pipeline to deploy the application.

1. Add container image with `kubectl`

  ```
  - name: kubectl
    image: gcr.io/cloud-builders/kubectl
    command:
    - cat
    tty: true
  ```

1. Add deployment stage

  ```
  stage('Deploy Production') {
      // Production branch
      when { branch 'master' }
      steps{
        container('kubectl') {
        // Change deployed image in canary to the one we just built
          sh("sed -i.bak 's#gcr.io/project-aleksey-zalesov/sample-k8s-app:1.0.0#${imageTag}#' ./k8s/production/*.yaml")
          sh("kubectl --namespace=production apply -f k8s/services/")
          sh("kubectl --namespace=production apply -f k8s/production/")
          sh("echo http://`kubectl --namespace=production get service/${feSvcName} -o jsonpath='{.status.loadBalancer.ingress[0].ip}'` > ${feSvcName}")
        }
      }
  }
  ```

1. Commit the changes to `master`

  ```
  git add .
  git commit "Add deployment"
  git push origin master
  ```

1. Watch the pipeline tests, builds and deploys the application.
