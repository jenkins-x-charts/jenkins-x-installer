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

```bash
cat setup-sa.yaml | sed "s/{project_id}/$PROJECT_ID/" | kubectl create -f -
jx ns jx
```

Create GCP service accounts that we can link Kubernetes service accounts using workload identity

```bash
gcloud iam service-accounts create $CLUSTER_NAME-jb
gcloud iam service-accounts create $CLUSTER_NAME-ko
gcloud iam service-accounts create $CLUSTER_NAME-st
gcloud iam service-accounts create $CLUSTER_NAME-tk
gcloud iam service-accounts create $CLUSTER_NAME-vo
gcloud iam service-accounts create $CLUSTER_NAME-vt

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
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[jx/tekton-sa]" \
  $CLUSTER_NAME-tk@$PROJECT_ID.iam.gserviceaccount.com

gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[jx/velero-sa]" \
  $CLUSTER_NAME-vo@$PROJECT_ID.iam.gserviceaccount.com

gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[jx/vault-sa]" \
  $CLUSTER_NAME-vt@$PROJECT_ID.iam.gserviceaccount.com
```

## add the installer to your cluster

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
