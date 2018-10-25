Deploy a breaking change, then roll back
----------------------------------------

Make a breaking change to the `gceme` source, push it, and deploy it through the pipeline to production. Then pretend latency spiked after the deployment and you want to roll back. Do it! Faster!

```
$ kubectl rollout undo deployment/gceme-backend-production -n prod
deployment "gceme-backend-production"
$ kubectl rollout undo deployment/gceme-frontend-production -n prod
deployment "gceme-frontend-production"
$ kubectl rollout undo deployment/mysql -n prod
$ kubectl rollout status deployment/gceme-frontend-production -n prod
deployment "gceme-frontend-production" successfully rolled out
$ kubectl rollout history deployment/gceme-frontend-production -n prod
```

Optional exercises
------------------

1. Create pipeline that deploys app into two production namespaces, one after another. This emulates multi-datacenter scenario.
1. Say the management of the company decides to deploy automatically only to staging and deployment to prod now requires manual confirmation from the operator. How can you implement this scenario using Jenkins pipelines?
