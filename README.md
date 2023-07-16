# K8s Project

## TODO:
- cleanup files and README
- add app.yaml on this repo

## DB Set up

### Postgres

https://blog.devgenius.io/how-to-deploy-postgresql-db-server-and-pgadmin-in-kubernetes-a-how-to-guide-57952b4e29a8

``` bash 
kubectl port-forward svc/pgadmin 8080:80 -n customer-product
```

### MongoDB

https://anuradha.hashnode.dev/kubernetes-with-mongo-express-app

``` bash 
kubectl port-forward svc/mongo-express-service 8081:8081 -n orders
```

todo: 
make istio tracing and monitoring work with the deployed monitoring solutions

minikube config set memory 4096
minikube config set cpus 4

for performance reasons temporarily disabling istio

## DB Backup 
``` bash
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.6.0 \
    --bucket kostas-test-bucket-eu-west-1 \
    --backup-location-config region=eu-west-1 \
    --snapshot-location-config region=eu-west-1 \
    --secret-file ./credentials-velero
velero backup create orders --include-namespaces orders --csi-snapshot-timeout=20m
velero backup create customer-product --include-namespaces customer-product --csi-snapshot-timeout=20m
# kubectl delete namespaces nginx-example
velero restore create --from-backup orders
velero restore create --from-backup customer-product

```

velero backup create pgb --include-resources pvc,pv --include-namespaces customer-product --selector app.kubernetes.io/component=postgresql
velero restore create --from-backup pgb


# todo:
deploy postgres and mongo using bitnami helm charts and test backup/restore and autosclaling
- https://github.com/bitnami/charts/blob/main/bitnami/postgresql/README.md
  - https://docs.bitnami.com/kubernetes/infrastructure/postgresql/administration/backup-restore/
  - https://docs.bitnami.com/tutorials/migrate-data-bitnami-velero/
  - https://docs.replicated.com/vendor/snapshots-hooks
    - https://velero.io/docs/v1.11/backup-hooks/
    - https://velero.io/docs/v1.11/restore-hooks/
  - todo enable metrics for postgres
- https://github.com/bitnami/charts/tree/main/bitnami/mongodb
- 


velero postgres: https://www.civo.com/learn/automate-postgresql-backup-with-velero

# postgres
## HA
``` bash
helm install mypostgres bitnami/postgresql-ha -n customer-product --values postgres-values.yaml

# copy secret to orders namespace
# ha
kubectl get secret postgresql --namespace=customer-product -o yaml | sed 's/namespace: .*/namespace: orders/' | kubectl apply -f -
```
# single

``` bash
# cleanup
helm install mypostgres -n customer-product
# add pvc cleanup
# ...
```

if reusing the same pvcs in new deployment it works fine
todo now is try to back them up using velero, delete them and restore them to see if data is there.

``` bash
velero backup create pgb --include-resources pvc,pv --namespace customer-product --selector app.kubernetes.io/component=postgresql

# delete pvc & pv

velero restore create --from-backup pgb3

# modify existingClaim in values.yaml and do:
helm upgrade --install mypostgres bitnami/postgresql-ha -n customer-product --values postgres-values.yaml
```

## delete pvc & pv
 Plain postgres

``` bash
helm upgrade --install mypostgres bitnami/postgresql -n customer-product --values postgres.yaml

velero backup create pgb3 --include-resources pvc,pv --include-namespaces customer-product --selector app.kubernetes.io/name=postgresql

# delete pvc & pv

velero restore create --from-backup pgb3

helm upgrade --install mypostgres bitnami/postgresql -n customer-product --values postgres.yaml
```


## Single Postgres backup/restore 

minikube addons enable volumesnapshots && minikube addons enable csi-hostpath-driver
kubectl label volumesnapshotclasses csi-hostpath-snapclass velero.io/csi-volumesnapshot-class=true

install minikube addons

``` bash
# create postgres db
helm upgrade --install mypostgres bitnami/postgresql -n customer-product --values postgres.yaml

velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.7.0 \
    --bucket kostas-test-bucket-eu-west-1 \
    --backup-location-config region=eu-west-1 \
    --snapshot-location-config region=eu-west-1 \
    --secret-file ./db-backup/credentials-velero \
    
velero install \
    --provider aws \
    --plugins velero/velero-plugin-for-aws:v1.7.0 \
    --bucket kostas-test-bucket-eu-west-1 \
    --backup-location-config region=eu-west-1 \
    --secret-file ./db-backup/credentials-velero \
    --use-node-agent \
    --default-volumes-to-fs-backup \
    --use-volume-snapshots=false

# csi
velero install \
    --provider aws \
    --plugins "velero/velero-plugin-for-aws:v1.7.0,velero/velero-plugin-for-csi:v0.5.0" \
    --bucket kostas-test-bucket-eu-west-1 \
    --backup-location-config region=eu-west-1 \
    --secret-file ./db-backup/credentials-velero \
    --features=EnableCSI \
    --uploader-type "restic" \
    --use-node-agent \

velero backup create pgb5 --include-resources pvc --include-namespaces customer-product --default-volumes-to-fs-backup

velero install --use-node-agent --default-volumes-to-fs-backup --use-volume-snapshots=false --provider aws --plugins velero/velero-plugin-for-aws:v1.6.0 --secret-file creds --bucket velero --backup-location-config region=minio,s3ForcePathStyle="true",s3Url=http://192.168.1.190:9000

velero backup create pgb1 --include-resources pvc,pv --include-namespaces customer-product --default-volumes-to-fs-backup --snapshot-volumes 


```

# Velero backup/restore status:
velero is having trouble backing up volume snapshot of minikube using csi,
tried also with restic
https://github.com/vmware-tanzu/velero/issues/6286
todo: try on an actual cloud k8s cluster (EKS)
pausing it for now


## add/remove replica
https://docs.bitnami.com/kubernetes/infrastructure/postgresql-ha/administration/scale-deployment/
make sure you add the passwords on either the values.yaml or the helm install command
set `replicaCount` to 4 and run
``` bash
helm upgrade --install mypostgres bitnami/postgresql-ha -n customer-product --values postgres-values.yaml
```


# mongo
helm upgrade --install mymongo bitnami/mongodb -n orders --values mongo-replicaset.yaml

## update replicaset
update the field `replicaCount` and deploy again the helm chart

todo: 
test this solution for autosclaling
https://github.com/bitnami/charts/issues/9585

# autoscaling
``` bash
minikube addons enable metrics-server
k apply -f cust-product/pg-hpa.yaml
k apply -f orders/mongo-hpa.yaml
```
