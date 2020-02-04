# Jenkins X Experimental Installer

These installer docs helps you create a new cluster on Google Cloud Platform, prepare it and deploy an installer that will provision your cluster with Jenkins X, using Helm 3, GCP Workload Identity and a much easier way to add apps to the intial install.

__NOTE__: This installer is experimental so don't install into an existing Kubernetes cluster and if possible you should use a new GCP project so that any IAM, Bucket or Networking resources do not affect existing workloads.


# Prerequisits

This is experimental so for now this installer is aimed at:
- Google Cloud Platform Kubernetes (GKE)
- GitHub for GitOps environment repositories and creating new quickstarts or custom applications

Set some local environment varialbles
- `NAMESPACE` is the Kubernetes namespace the base Jenkins X installation will installed into, note optionl apps installed during the boot process can be installed into different namespaces

- `CLUSTER_NAME` provide a unique cluster name for the GCP project
- `PROJECT_ID` the GCP project the cluster and other cloud resources will be created into
- `ZONE` the GCP zone to create the new cluster
- `ENV_GIT_OWNER` the GitHub organisation the GitOps environments are created, these are the repos that contain the meta data for each Jenkins X environment.  _Note_ the pipline user env vars below must have permission to create repos in the GitHub organisation

```bash
export NAMESPACE=jx
export CLUSTER_NAME=
export PROJECT_ID=
export ZONE=
export ENV_GIT_OWNER=
```

# Create a new cluster on GCP with Googles workload identity enabled

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

# Provision

As this is still experimental there's no official helm chart yet so you will need to clone this repo to install

```bash
git clone https://github.com/jenkins-x-charts/jenkins-x-installer
cd jenkins-x-installer
```

Create GCP service accounts that we can link Kubernetes service accounts to, using workload identity

```bash
gcloud iam service-accounts create $CLUSTER_NAME-ex
gcloud iam service-accounts create $CLUSTER_NAME-jb
gcloud iam service-accounts create $CLUSTER_NAME-ko
gcloud iam service-accounts create $CLUSTER_NAME-st
gcloud iam service-accounts create $CLUSTER_NAME-tk
gcloud iam service-accounts create $CLUSTER_NAME-vo
gcloud iam service-accounts create $CLUSTER_NAME-vt

cat setup.yaml | sed "s/{namespace}/$NAMESPACE/" | sed "s/{project_id}/$PROJECT_ID/" | sed "s/{cluster_name}/$CLUSTER_NAME/" | kubectl apply -f -

# external dns
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/externaldns-sa]" \
  $CLUSTER_NAME-ex@$PROJECT_ID.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/dns.admin \
  --member "serviceAccount:$CLUSTER_NAME-ex@$PROJECT_ID.iam.gserviceaccount.com"

# jx boot
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/boot-sa]" \
  $CLUSTER_NAME-jb@$PROJECT_ID.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/dns.admin \
  --member "serviceAccount:$CLUSTER_NAME-jb@$PROJECT_ID.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/viewer \
  --member "serviceAccount:$CLUSTER_NAME-jb@$PROJECT_ID.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/iam.serviceAccountKeyAdmin \
  --member "serviceAccount:$CLUSTER_NAME-jb@$PROJECT_ID.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.admin \
  --member "serviceAccount:$CLUSTER_NAME-jb@$PROJECT_ID.iam.gserviceaccount.com"

# kaniko
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/kaniko-sa]" \
  $CLUSTER_NAME-ko@$PROJECT_ID.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.admin \
  --member "serviceAccount:$CLUSTER_NAME-ko@$PROJECT_ID.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.objectAdmin \
  --member "serviceAccount:$CLUSTER_NAME-ko@$PROJECT_ID.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.objectCreator \
  --member "serviceAccount:$CLUSTER_NAME-ko@$PROJECT_ID.iam.gserviceaccount.com"

# tekton
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/tekton-sa]" \
  $CLUSTER_NAME-tk@$PROJECT_ID.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/viewer \
  --member "serviceAccount:$CLUSTER_NAME-tk@$PROJECT_ID.iam.gserviceaccount.com"

# storage
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/storage-sa]" \
  $CLUSTER_NAME-st@$PROJECT_ID.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.admin \
  --member "serviceAccount:$CLUSTER_NAME-st@$PROJECT_ID.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.objectAdmin \
  --member "serviceAccount:$CLUSTER_NAME-st@$PROJECT_ID.iam.gserviceaccount.com"

# velero
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/velero-sa]" \
  $CLUSTER_NAME-vo@$PROJECT_ID.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.admin \
  --member "serviceAccount:$CLUSTER_NAME-vo@$PROJECT_ID.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.objectAdmin \
  --member "serviceAccount:$CLUSTER_NAME-vo@$PROJECT_ID.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.objectCreator \
  --member "serviceAccount:$CLUSTER_NAME-vo@$PROJECT_ID.iam.gserviceaccount.com"

# vault
gcloud iam service-accounts add-iam-policy-binding \
  --role roles/iam.workloadIdentityUser \
  --member "serviceAccount:$PROJECT_ID.svc.id.goog[$NAMESPACE/vault-sa]" \
  $CLUSTER_NAME-vt@$PROJECT_ID.iam.gserviceaccount.com

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/storage.objectAdmin \
  --member "serviceAccount:$CLUSTER_NAME-vt@$PROJECT_ID.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/cloudkms.admin \
  --member "serviceAccount:$CLUSTER_NAME-vt@$PROJECT_ID.iam.gserviceaccount.com"

gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/cloudkms.cryptoKeyEncrypterDecrypter \
  --member "serviceAccount:$CLUSTER_NAME-vt@$PROJECT_ID.iam.gserviceaccount.com"

# change to the new jx namespace
jx ns $NAMESPACE
```

## Verify workload identity

It can a little while for permissions to propogate when using workload identity so it's a good idea to validate auth is working before continuing to the next step.

run a temporary pod with one of our kubernetes service accounts

```bash
kubectl run --rm -it \
  --generator=run-pod/v1 \
  --image google/cloud-sdk:slim \
  --serviceaccount boot-sa \
  --namespace $NAMESPACE \
  workload-identity-test
```

use gcloud to verify you can auth, it make take a few tries over a few minutes

```bash
gcloud auth list
```

CTR-D to exit the pod and it is garbage collected so you don't need to clean it up

## Secrets
We now have a few options of injecting the required secrets into the boot installer.

### Google Secrets manager - preferred approach

This uses the new [Beta secrets manager](https://cloud.google.com/secret-manager)

You may need to upgrade your gcloud and it's components
```bash
gcloud components update
```

```bash
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --role roles/secretmanager.secretAccessor \
  --member "serviceAccount:$CLUSTER_NAME-jb@$PROJECT_ID.iam.gserviceaccount.com"
```

edit the `google-secrets-manager/secrets.yaml` file in this repo, add your secret values and run

```bash
gcloud beta secrets create boot-secret --replication-policy automatic --data-file ./google-secrets-manager/secrets.yaml

helm install jx-boot \
  --set boot.namespace=$NAMESPACE \
  --set boot.clusterName=$CLUSTER_NAME \
  --set boot.zone=$ZONE \
  --set boot.projectID=$PROJECT_ID \
  --set boot.environmentGitOwner=$ENV_GIT_OWNER \
  --set secrets.gsm.enabled=true \
  .
```

### Environment variables

```bash
export SECRET_ADMINUSER_USERNAME=
export SECRET_ADMINUSER_PASSWORD=
export SECRET_HMACTOKEN=
export SECRET_PIPELINEUSER_USERNAME=
export SECRET_PIPELINEUSER_EMAIL=
export SECRET_PIPELINEUSER_TOKEN=

helm install jx-boot \
  --set boot.namespace=$NAMESPACE \
  --set boot.clusterName=$CLUSTER_NAME \
  --set boot.zone=$ZONE \
  --set boot.projectID=$PROJECT_ID \
  --set boot.environmentGitOwner=$ENV_GIT_OWNER \
  --set secrets.env.enabled=true \
  --set secrets.env.adminUser.username=$SECRET_ADMINUSER_USERNAME \
  --set secrets.env.adminUser.password=$SECRET_ADMINUSER_PASSWORD \
  --set secrets.env.hmacToken=$SECRET_HMACTOKEN \
  --set secrets.env.pipelineUser.username=$SECRET_PIPELINEUSER_USERNAME \
  --set secrets.env.pipelineUser.email=$SECRET_PIPELINEUSER_EMAIL \
  --set secrets.env.pipelineUser.token=$SECRET_PIPELINEUSER_TOKEN \
  .
```

## Logs

Follow the logs of the `jx boot` kubernetes job, note is may take a minute or twp for the pod of the job to start as the node needs to download the image and start it.

```bash
kubectl logs job/jx-boot -f
```

# Cleanup
_Note this cleans up the resources associated with the installer and not the Jenkins X installation itself, see website docs for that_
```
helm uninstall jx-boot
```

```bash
kubectl delete sa externaldns-sa
kubectl delete sa boot-sa
kubectl delete sa kaniko-sa
kubectl delete sa tekton-sa
kubectl delete sa storage-sa
kubectl delete sa vault-sa
kubectl delete sa velero-sa
kubectl delete ns $NAMESPACE
kubectl delete ClusterRoleBinding jx-boot
```

```bash
gcloud iam service-accounts delete $CLUSTER_NAME-ex@$PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts delete $CLUSTER_NAME-jb@$PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts delete $CLUSTER_NAME-ko@$PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts delete $CLUSTER_NAME-st@$PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts delete $CLUSTER_NAME-tk@$PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts delete $CLUSTER_NAME-vo@$PROJECT_ID.iam.gserviceaccount.com
gcloud iam service-accounts delete $CLUSTER_NAME-vt@$PROJECT_ID.iam.gserviceaccount.com
```