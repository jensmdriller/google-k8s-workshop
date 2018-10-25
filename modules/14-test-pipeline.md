Test the application
--------------------

This version of pipeline does not run application tests. Let's fix it.

1. Add `golang` container to the agent

  ```
  - name: golang
    image: golang:1.10
    command:
    - cat
    tty: true
  ```

1. Create test stage righ before the build stage

  ```
  stage('Test') {
    steps {
      container('golang') {
        sh """
          ln -s `pwd` /go/src/sample-app
          cd /go/src/sample-app
          go test
        """
      }
    }
  }
  ```

1. Commit changes and push to `master`

  ```
  git add .
  git commit "Add tests"
  git push origin master
  ```

1. In Jenkins dashboard watch how Jenkins tests and builds the application.

1. Introduce syntax error into `main.go`, push this change to master. The pipeline should stop on the `Test` stage without running `Build` stage.

1. Revert the commit to restore clean `master` state

  ```
  git revert HEAD
  git push origin master
  ```
