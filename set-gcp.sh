export PROJECT_ID=$(gcloud config get-value project)

export COMPUTE_REGION=us-west2
gcloud config set compute/region $COMPUTE_REGION

export COMPUTE_ZONE=us-west2-b
gcloud config set compute/zone $COMPUTE_ZONE
