Containers
==========

Module objectives
-----------------

1. Build application Docker image
1. Run application locally

Build application Docker image
------------------------------

1. Open the GCP console from your browser. [GCP Console](https://console.cloud.google.com/)

1. Clone the application GitHub repository

    ```
    $ git clone git@github.com:s-matyukevich/sample-k8s-app.git
    $ cd sample-k8s-app
    ```

1. Build the Docker image

    ```
    export IMAGE=gcr.io/$PROJECT_ID/sample-k8s-app:1.0.0
    docker build . -t $IMAGE
    ```

    `gcr.io` is the repository hostname.

    `$PROJECT_ID` is id of your GCP project

    `sample-k8s-app` is the name of the application image

    `1.0.0` is image tag


Run application locally
----------------------

1. Launch three terminals

1. In each terminal set the `IMAGE` variable

    ```
    export IMAGE=gcr.io/$PROJECT_ID/sample-k8s-app:1.0.0
    ```

1. T1: Run database container

    ```
    $ docker run --rm \
      --name db \
      -e MYSQL_ROOT_PASSWORD=root \
      -d mysql
    ```

    `-d mysql` tells Docker to use `library/mysql:latest` image for the database from the `hub.docker.io` repository

    `-e MYSQL_ROOT_PASSWORD=root` sets database administrator password to `root`

    `--name db` sets the name of the container which you can refer to in other commands

1. T2: Run backend container

    ```
    $ docker run --rm \
      --name backend \
      --link db:mysql \
      -p 8081:8081 \
      -d $IMAGE \
      app -port=8081 -db-host=db -db-password=root
    ```

    `--link db:mysql` [links](https://docs.docker.com/network/links/) the backend container to the database container

    `-p 8081:8081` expose port 8081 from container as port `8081` on the host

    `-d $IMAGE` use image we build earlier for the sample app

    `app -port=8081 -db-host=db -db-password=root` application start command

1. T3: Run frontend container

    ```
    $ docker run --rm \
      --name frontend \
      --link backend \
      -p 8080:8080 \
      -d $IMAGE \
      app  -frontend=true -backend-service=http://backend:8081
    ```

1. Verify that all containers are running

    ```
    $ docker ps
    CONTAINER ID        IMAGE                     COMMAND                  CREATED              STATUS              PORTS                    NAMES
    594fec987c57        lexsys27/sample-k8s-app   "app -frontend=true …"   8 seconds ago        Up 6 seconds        0.0.0.0:8080->8080/tcp   frontend
    684113a1910f        lexsys27/sample-k8s-app   "app -port=8081 -db-…"   21 seconds ago       Up 19 seconds       0.0.0.0:8081->8081/tcp   backend
    dd3bacf6e0f0        mysql                     "docker-entrypoint.s…"   About a minute ago   Up About a minute   3306/tcp, 33060/tcp      db
    ```

1. Open in your browser 'http://localhost:8080' and check that the app is working

    Application will show no configuration data as it is running outside of GCP.

    You should be able to add notes in the bottom box.

1. Clean up

    ```
    $ docker stop $(docker ps -aq)
    $ docker rm $(docker ps -aq)
    ```
