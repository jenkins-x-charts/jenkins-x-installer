#!/bin/bash

set -e

NAMESPACE=${NAMESPACE:-jx}

if [ -z $PROJECT_ID ]
then
  echo "Please supply the 'PROJECT_ID' environment variable for your GCP Project ID"
  echo "e.g."
  echo "export PROJECT_ID=myproject"
  exit 1
fi

if [ -z $CLUSTER_NAME ]
then
  echo "Please supply the 'CLUSTER_NAME' environment variable for your GKE cluster name"
  echo "e.g."
  echo "export CLUSTER_NAME=mycluster"
  exit 1
fi


echo "setting up the cloud resources for ecluster $CLUSTER_NAME in project $PROJECT_ID"

export SLEEP="sleep 2"
gcloud config set project $PROJECT_ID

gcloud iam service-accounts create $CLUSTER_NAME-ex
gcloud iam service-accounts create $CLUSTER_NAME-jb
gcloud iam service-accounts create $CLUSTER_NAME-ko
gcloud iam service-accounts create $CLUSTER_NAME-st
gcloud iam service-accounts create $CLUSTER_NAME-tk
gcloud iam service-accounts create $CLUSTER_NAME-vo
gcloud iam service-accounts create $CLUSTER_NAME-vt

cat `dirname "$0"`/setup.yaml | sed "s/{namespace}/$NAMESPACE/" | sed "s/{project_id}/$PROJECT_ID/" | sed "s/{cluster_name}/$CLUSTER_NAME/" | kubectl apply -f -

# external dns
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/externaldns-sa]" \
  $CLUSTER_NAME-ex@$PROJECT_ID.iam.gserviceaccount.com

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/dns.admin \
  --member "serviceAccount:$CLUSTER_NAME-ex@$PROJECT_ID.iam.gserviceaccount.com"

$SLEEP

# jx boot
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/boot-sa]" \
  $CLUSTER_NAME-jb@$PROJECT_ID.iam.gserviceaccount.com

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/dns.admin \
  --member "serviceAccount:$CLUSTER_NAME-jb@$PROJECT_ID.iam.gserviceaccount.com"

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/viewer \
  --member "serviceAccount:$CLUSTER_NAME-jb@$PROJECT_ID.iam.gserviceaccount.com"

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/iam.serviceAccountKeyAdmin \
  --member "serviceAccount:$CLUSTER_NAME-jb@$PROJECT_ID.iam.gserviceaccount.com"

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.admin \
  --member "serviceAccount:$CLUSTER_NAME-jb@$PROJECT_ID.iam.gserviceaccount.com"

$SLEEP

# kaniko
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/kaniko-sa]" \
  $CLUSTER_NAME-ko@$PROJECT_ID.iam.gserviceaccount.com

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.admin \
  --member "serviceAccount:$CLUSTER_NAME-ko@$PROJECT_ID.iam.gserviceaccount.com"

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.objectAdmin \
  --member "serviceAccount:$CLUSTER_NAME-ko@$PROJECT_ID.iam.gserviceaccount.com"

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.objectCreator \
  --member "serviceAccount:$CLUSTER_NAME-ko@$PROJECT_ID.iam.gserviceaccount.com"

$SLEEP

# tekton
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/tekton-sa]" \
  $CLUSTER_NAME-tk@$PROJECT_ID.iam.gserviceaccount.com

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/viewer \
  --member "serviceAccount:$CLUSTER_NAME-tk@$PROJECT_ID.iam.gserviceaccount.com"

$SLEEP

# storage
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/storage-sa]" \
  $CLUSTER_NAME-st@$PROJECT_ID.iam.gserviceaccount.com

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.admin \
  --member "serviceAccount:$CLUSTER_NAME-st@$PROJECT_ID.iam.gserviceaccount.com"

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.objectAdmin \
  --member "serviceAccount:$CLUSTER_NAME-st@$PROJECT_ID.iam.gserviceaccount.com"

$SLEEP

# velero
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/velero-sa]" \
  $CLUSTER_NAME-vo@$PROJECT_ID.iam.gserviceaccount.com

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.admin \
  --member "serviceAccount:$CLUSTER_NAME-vo@$PROJECT_ID.iam.gserviceaccount.com"

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.objectAdmin \
  --member "serviceAccount:$CLUSTER_NAME-vo@$PROJECT_ID.iam.gserviceaccount.com"

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.objectCreator \
  --member "serviceAccount:$CLUSTER_NAME-vo@$PROJECT_ID.iam.gserviceaccount.com"

$SLEEP

# vault
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/vault-sa]" \
  $CLUSTER_NAME-vt@$PROJECT_ID.iam.gserviceaccount.com

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.objectAdmin \
  --member "serviceAccount:$CLUSTER_NAME-vt@$PROJECT_ID.iam.gserviceaccount.com"

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/cloudkms.admin \
  --member "serviceAccount:$CLUSTER_NAME-vt@$PROJECT_ID.iam.gserviceaccount.com"

$SLEEP

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/cloudkms.cryptoKeyEncrypterDecrypter \
  --member "serviceAccount:$CLUSTER_NAME-vt@$PROJECT_ID.iam.gserviceaccount.com"

# change to the new jx namespace
jx ns $NAMESPACE