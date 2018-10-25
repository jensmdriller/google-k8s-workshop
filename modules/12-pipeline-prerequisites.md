Create a pipeline
=================

Module objectives
-----------------

- create a repository for the sample app source 
- add your service account credentials

Create a repository for the sample app source
----------------------------------------------

Here you'll create your own copy of the `gceme` sample app in [Cloud Source Repository](https://cloud.google.com/source-repositories/docs/).

1. Change directories to `sample-app` of the repo you cloned previously, then initialize the git repository.

    ```shell
    # make sure you are still in sample-app directory
    $ git init
    $ git config credential.helper gcloud.sh
    $ gcloud source repos create gceme
    $ git remote add origin https://source.developers.google.com/p/$PROJECT_ID/r/gceme
    ```

1. Ensure git is able to identify you:

    ```shell
    $ git config --global user.email "YOUR-EMAIL-ADDRESS"
    $ git config --global user.name "YOUR-NAME"
    ```

1. Add, commit, and push all the files:

    ```shell
    $ git add .
    $ git commit -m "Initial commit"
    $ git push origin master
    ```
    
Now make a small change to the `Jenkinsfile` to make first build pass. You need to specify your project ID

```
# Open Jenkinsfile

# Find the line
def project = 'PROJECT_ID'

# Learn your project ID
$ echo $PROJECT_ID
cloud-training-4-211211

# Change the line and save file
def project = 'cloud-training-4-211211`

# Push you changes
$ git add Jenkinsfile
$ git commit -m "Change the project ID"
$ git push --set-upstream origin master
```

Add your service account credentials
------------------------------------

First, we will need to configure our GCP credentials in order for Jenkins to be able to access our code repository

1. In the Jenkins UI, click “Credentials” on the left
1. Click either of the “(global)” links (they both route to the same URL)
1. Click “Add Credentials” on the left
1. From the “Kind” dropdown, select “Google Service Account from metadata”
1. Click “OK”

You should now see 2 Global Credentials. Make a note of the name of the second credential as you will reference this in Phase 2:

![](docs/img/jenkins-credentials.png)
