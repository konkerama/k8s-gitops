#!/bin/bash

GIT_USERNAME="konkerama"
echo "Provide git token:"
read GIT_TOKEN

# initilize argo cd
kubectl apply -f system/namespaces.yaml
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl rollout status deployment argocd-applicationset-controller -n argocd
kubectl rollout status deployment argocd-dex-server -n argocd
kubectl rollout status deployment argocd-notifications-controller -n argocd
kubectl rollout status deployment argocd-redis -n argocd
kubectl rollout status deployment argocd-repo-server -n argocd
kubectl rollout status deployment argocd-server -n argocd

kubectl port-forward svc/argocd-server -n argocd 8080:443 > /dev/null 2>&1 &

pid=$!
echo pid: $pid

# kill the port-forward regardless of how this script exits
trap '{
    # echo killing $pid
    kill $pid
}' EXIT

# wait for $localport to become available
while ! nc -vz localhost 8080 > /dev/null 2>&1 ; do
    # echo sleeping
    sleep 0.1
done

# Get password and login to argocd
argocd admin initial-password -n argocd
argocd login localhost:8080

# Configure ArgoCD Repos
kubectl config set-context --current --namespace=argocd
argocd cluster add minikube
# this will create a secret with the repo credentials
argocd repo add https://github.com/konkerama/k8s-project.git --username $GIT_USERNAME --password $GIT_TOKEN

kubectl config set-context --current --namespace=default

# set up dockerhub credentials
kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=$HOME/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson \
    -n orders

# create ssm parameter in AWS and point to it from k8s
aws ssm put-parameter   --name /k8s-project/secrets \
                        --value file://init/secrets.json \
                        --type SecureString \
                        --overwrite

kubectl apply -f init/aws-secret.yaml

# deploy argocd applications 
kubectl apply -f argocd/system.yaml
kubectl apply -f argocd/sec-ext-secrets-op.yaml
kubectl apply -f argocd/orders-secrets.yaml
kubectl apply -f argocd/orders-postgres.yaml
kubectl apply -f argocd/orders-mongo.yaml
kubectl apply -f argocd/db-mgmt.yaml
# kubectl apply -f argocd/orders-app.yaml
