Development branch
------------------

1. Add development stage to the pipeline after the production one

    ```java
    stage('Deploy Dev') {
      // Developer Branches
      when {
        not { branch 'master' }
        not { branch 'canary' }
      }
      steps {
        container('kubectl') {
          // Create namespace if it doesn't exist
          sh("kubectl get ns ${env.BRANCH_NAME} || kubectl create ns ${env.BRANCH_NAME}")
          sh "#!/bin/bash\n" +
            "if ! kubectl -n ${env.BRANCH_NAME} get secret mysql\n" +
            "then\n" +
            "  kubectl -n ${env.BRANCH_NAME} create secret generic mysql --from-literal=password=root\n" +
            "fi\n"
          // Don't use public load balancing for development branches
          sh("sed -i.bak 's#LoadBalancer#ClusterIP#' ./k8s/services/frontend.yaml")
          sh("sed -i.bak 's#REPLACE_WITH_IMAGE#${imageTag}#' ./k8s/dev/*.yaml")
          sh("kubectl --namespace=${env.BRANCH_NAME} apply -f k8s/services/")
          sh("kubectl --namespace=${env.BRANCH_NAME} apply -f k8s/dev/")
          echo 'To access your environment run `kubectl proxy`'
          echo "Then access your service via http://localhost:8001/api/v1/namespaces/${env.BRANCH_NAME}/services/${feSvcName}:http/proxy/"
          echo 'Or better yet use `port-forward`'
          echo "kubectl -n ${env.BRANCH_NAME} port-forward \$(kubectl -n new-feature get pods -l role=frontend -o jsonpath='{.items[].metadata.name}') 8080:80"
        }
      }     
    }
    ```

1. Commit changes to the `master` branch

    ```
    git add .
    git commit -m "Add development"
    git push origin master
    ```

    Often times, changes will not be so trivial that they can be pushed directly to the canary environment. In order to create a development environment from a long lived feature branch all you need to do is push it up to the Git server and let Jenkins deploy your environment. In this case you will not use a loadbalancer so you'll have to access your application using `kubectl proxy`, which authenticates itself with the Kubernetes API and proxies requests from your local machine to the service in the cluster without exposing your service to the internet.


#### Deploy the development branch

1. Create another branch and push it up to the Git server

    ```
    git checkout -b new-feature
    git push origin new-feature
    ```

1. Open Jenkins in your web browser and navigate to the sample-app job. You should see that a new job called "new-feature" has been created and your environment is being created.

1. Navigate to the console output of the first build of this new job by:

    * Click the `new-feature` link in the job list.
    * Click the `#1` link in the Build History list on the left of the page.
    * Finally click the `Console Output` link in the left navigation.

1. Scroll to the bottom of the console output of the job, and you will see instructions for accessing your environment:

    ```
    deployment "gceme-frontend-dev" created
    [Pipeline] echo
    To access your environment run `kubectl proxy`
    [Pipeline] echo
    Then access your service via http://localhost:8001/api/v1/namespaces/new-feature/services/gceme-frontend:http/proxy/
    [Pipeline] }
    ```

#### Access the development branch

1. Open a new Google Cloud Shell terminal by clicking the `+` button to the right of the current terminal's tab, and start the proxy:

    ```
    $ kubectl proxy
    ```

1. Return to the original shell, and access your application via localhost:

    ```
    $ curl http://localhost:8001/api/v1/namespaces/new-feature/services/gceme-frontend:http/proxy/
    ```

    You can also view your dev branch via cloud shells web preview, by updating the port to 8001. You will get a url like this `https://8001-dot-1111111-dot-devshell.appspot.com/?authuser=0#` replace `?authuser=0#` with `api/v1/namespaces/new-feature/services/gceme-frontend:http/proxy/`.

    If all that fails we can always use `port-forward`.

    ```
    kubectl -n new-feature port-forward $(kubectl -n new-feature get pods -l role=frontend -o jsonpath='{.items[].metadata.name}') 8080:80
    ```

1. You can now push code to the `new-feature` branch in order to update your development environment.

1. Once you are done, merge your `new-feature ` branch back into the  `canary` branch to deploy that code to the canary environment:

    ```
    git checkout canary
    git merge new-feature
    git push origin canary
    ```

1. When you are confident that your code won't wreak havoc in production, merge from the `canary` branch to the `master` branch. Your code will be automatically rolled out in the production environment:

    ```
    git checkout master
    git merge canary
    git push origin master
    ```

1. When you are done with your development branch, delete it from the server and delete the environment in Kubernetes:

    ```
    git push origin :new-feature
    kubectl delete ns new-feature
    ```
