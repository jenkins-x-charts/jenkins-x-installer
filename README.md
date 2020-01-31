# installer


## prereqs

Set some local environment varialbles
```bash
export CLUSTER_NAME=
export PROJECT_ID=
export ZONE=
export SECRET_ADMINUSER_USERNAME=
export SECRET_ADMINUSER_PASSWORD=
export SECRET_HMACTOKEN=
export SECRET_PIPELINEUSER_USERNAME=
export SECRET_PIPELINEUSER_EMAIL=
export SECRET_PIPELINEUSER_TOKEN=
```


```bash
gcloud beta container clusters create $CLUSTER_NAME \
 --enable-autoscaling \
 --min-nodes=1 \
 --max-nodes=3 \
 --project=$PROJECT_ID \
 --identity-namespace=$PROJECT_ID.svc.id.goog \
 --region=europe-west1-b \
 --machine-type=n1-standard-4 \
 --num-nodes=2
```

Create GCP service accounts that we can link Kubernetes service accounts using workload identity

```bash
gcloud iam service-accounts create $CLUSTER_NAME-ex
gcloud iam service-accounts create $CLUSTER_NAME-jb
gcloud iam service-accounts create $CLUSTER_NAME-ko
gcloud iam service-accounts create $CLUSTER_NAME-st
gcloud iam service-accounts create $CLUSTER_NAME-vo
gcloud iam service-accounts create $CLUSTER_NAME-vt

```

## create base resources needed for the Jenkins X installation

```bash
kubectl create -f setup.yaml
cat setup-old.yaml | sed "s/{project_id}/$PROJECT_ID/" | sed "s/{cluster_name}/$CLUSTER_NAME/" | kubectl apply -f -
```

```bash

gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[jx/externaldns-sa]" \
  $CLUSTER_NAME-ex@$PROJECT_ID.iam.gserviceaccount.com

gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[jx/boot-sa]" \
  $CLUSTER_NAME-jb@$PROJECT_ID.iam.gserviceaccount.com

gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[jx/kaniko-sa]" \
  $CLUSTER_NAME-ko@$PROJECT_ID.iam.gserviceaccount.com

gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[jx/storage-sa]" \
  $CLUSTER_NAME-st@$PROJECT_ID.iam.gserviceaccount.com

gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[jx/velero-sa]" \
  $CLUSTER_NAME-vo@$PROJECT_ID.iam.gserviceaccount.com

gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[jx/vault-sa]" \
  $CLUSTER_NAME-vt@$PROJECT_ID.iam.gserviceaccount.com
```

## verify

it can a little while for permissions to propogate when using workload identity so it's a good idea to validate auth is working before continuing to the next step.

run a temporary pod with one of our kubernetes service accounts

```bash
kubectl run --rm -it \
  --generator=run-pod/v1 \
  --image google/cloud-sdk:slim \
  --serviceaccount boot-sa \
  --namespace jx \
  workload-identity-test
```

use gcloud to verify you can auth, it make take a few tries over a few minutes

```bash
gcloud auth list
```

## add the installer to your clusters
```
jx ns jx
```
```bash
helm install jx-boot \
  --set boot.clusterName=$CLUSTER_NAME \
  --set boot.zone=$ZONE \
  --set secrets.adminUser.username=$SECRET_ADMINUSER_USERNAME \
  --set secrets.adminUser.password=$SECRET_ADMINUSER_PASSWORD \
  --set secrets.hmacToken=$SECRET_HMACTOKEN \
  --set secrets.pipelineUser.username=$SECRET_PIPELINEUSER_USERNAME \
  --set secrets.pipelineUser.email=$SECRET_PIPELINEUSER_EMAIL \
  --set secrets.pipelineUser.token=$SECRET_PIPELINEUSER_TOKEN \
  .
```

# cleanup
_Note this cleans up the resources associated with the installer and not the Jenkins X installation itself, see website docs for that_
```
helm uninstall jx-boot
```

```bash
kubectl delete -f setup.yaml
```

```bash
gcloud iam service-accounts delete $CLUSTER_NAME-ex@$PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts delete $CLUSTER_NAME-jb@$PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts delete $CLUSTER_NAME-ko@$PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts delete $CLUSTER_NAME-st@$PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts delete $CLUSTER_NAME-vo@$PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts delete $CLUSTER_NAME-vt@$PROJECT_ID.iam.gserviceaccount.com
```