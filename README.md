# k8s-gitops

Project to configure a kubernetes cluster using Gitops. ArgoCD is used to deploy components. 

Currently has been tested only for minikube, testing on EKS is planned.

For the application containers the following repos are used:

- https://github.com/konkerama/rust-crud-api
- https://github.com/konkerama/python-crud-api

The following technologies are used:

- Python & Rust custom application containers
- MongoDB and PostgresDB as databases using their respective helm charts
- MongoExpress and PGAdmin for db management
- ArgoCD for deployment
- Prometheus for monitoring of metrics
- Loki & Promtail for logging
- Opentelemetry & Jaeger for tracing
- External Secrets using AWS Systems Manager Parameter Store as a secret management solution

## Setup

## minikube config

Before starting ensure minikube has at least the following allocated resources to avoid potential performance issues.

``` bash
minikube config set memory 4096
minikube config set cpus 4
```

Configure secret management solution
Create files for AWS Credentials and AWS Systems Manager Parameter store value

1. Create yaml for aws credentials

``` bash
cp init/aws-secret.yaml.template init/aws-secret.yaml
```

modify the fields of `access-key` & `secret-access-key` values using the equivalent base64 encoded values of the aws credentials.

2. Create json for db passwords

``` bash
cp init/secrets.json.template init/secrets.json
```

modify all the values according to your preferred database password.

For more information see the [secrets management](#secret-management) section.

Run the following script to perform the initial set up of the k8s envrionment

``` bash

./init/setup.sh

```

The script will create the necessary initial configuration of ArgoCD and then deploys all the components via ArgoCD.

ArgoCD then monitors all the files in this repository in case there are changes and modifies all the resources accordingly.

## Secret Management

This implementation utilizes Kubernetes External Secrets for management of sensitive values.

Initially an encrypted parameter in AWS Systems Manager Parameter Store is created. Later, Kubernetes External Secrets will point to this parameter and create "local" Kubernetes secrets based on those values. Those local secrets are then references by all the K8s components. K8s External Secrets is responsible for keeping the local secrets in sync based the source parameter in AWS Systems Manager Parameter Store.

In order for Kubernetes to have the necessary permissions to communicate to AWS a secret is create in Kubernetes in the `init/setup.sh`

## TODO:

- test on EKS
- add istio service mesh
