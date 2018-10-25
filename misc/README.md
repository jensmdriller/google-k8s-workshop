Google Kubernetes Workshop
==========================

Materials for the preparation of Kubernetes workshop to Google.

- [Program](https://drive.google.com/open?id=1JhvaIF-0yBhE8sHT6Xs-LTDgBl0KZQBNNKphu6wydEk)
- [Slides](https://drive.google.com/open?id=1sr4_JQPitT-PjRvlgEG_yT9cbVl3sjBJ)
- Landing page
- Practice
- [Original lab](https://github.com/GoogleCloudPlatform/continuous-deployment-on-kubernetes)

Day 01
------

- Introduction
- [Setting up pre-requisites](modules/01-pre-requisites.md)
- [Create a Kubernetes Cluster](modules/02-create-cluster.md)
- [Deploy Jenkins to GKE](modules/03-deploy-jenkins.md)

Day 02
------

- [Deploy sample app to Kubernetes](modules/04-deploy-app.md)
- [Create a pipeline](modules/05-create-pipeline.md)
- [Monitoring & Logging](modules/06-monitoring-logging.md)
- [Security](modules/07-security.md)
- Summary

Instructor notes
----------------

To distribute accounts between the participants use pieces of paper printed in advance. All other information including links to the course materials will be available in read-only Google Doc accessible via short link.

Short link (print it): https://tinyurl.com/workshop-altoros

- link to this repo
- link to slides in the pdf format
- link to the exercises exported to HTML and packed as zip archive
- Google Cloud Console
- e-mails of instructors

TODO: idea is to create a single channel for communication between participants during the training and right after the training

Room for improvement
--------------------

```
$ grep TODO modules/*.md --count
modules/01-pre-requisites.md:3
modules/02-create-cluster.md:10
modules/03-deploy-jenkins.md:15
modules/04-deploy-app.md:5
modules/05-create-pipeline.md:6
modules/06-monitoring-logging.md:11
modules/07-security.md:9
```