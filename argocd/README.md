# ArgoCD

Steps required to configure cluster

``` bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
kubectl rollout status deployment argocd-applicationset-controller -n argocd
kubectl rollout status deployment argocd-dex-server -n argocd
kubectl rollout status deployment argocd-notifications-controller -n argocd
kubectl rollout status deployment argocd-redis -n argocd
kubectl rollout status deployment argocd-repo-server -n argocd
kubectl rollout status deployment argocd-server -n argocd

# In another terminal run:
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Get password and login to argocd
argocd admin initial-password -n argocd
argocd login localhost:8080

# Configure ArgoCD Repos
kubectl config set-context --current --namespace=argocd
argocd cluster add minikube
# this will create a secret with the repo credentials
argocd repo add https://github.com/konkerama/k8s-project.git --username $GIT_USERNAME --password $GIT_TOKEN
argocd repo add https://github.com/konkerama/k8s-application.git --username $GIT_USERNAME --password $GIT_TOKEN

kubectl config set-context --current --namespace=default

kubectl create secret generic regcred \
    --from-file=.dockerconfigjson=$HOME/.docker/config.json \
    --type=kubernetes.io/dockerconfigjson \
    -n orders
```

In case we need to call a db on another namespace

``` bash
# https://github.com/argoproj/argo-cd/issues/1373
kubectl annotate secret postgresql argocd.argoproj.io/sync-wave="0" -n customer-product
kubectl annotate secret postgresql argocd.argoproj.io/hook=PostSync -n customer-product
kubectl annotate secret postgresql argocd.argoproj.io/hook-delete-policy=HookSucceeded -n customer-product
kubectl get secret postgresql --namespace=customer-product -o yaml | sed 's/namespace: .*/namespace: orders/' | kubectl apply -f -
```
