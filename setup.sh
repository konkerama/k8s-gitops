#!/bin/bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add opentelemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo add jaegertracing https://jaegertracing.github.io/helm-charts


kubectl apply -f namespaces.yaml
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.9.0/cert-manager.yaml
kubectl rollout status deployment cert-manager -n cert-manager
kubectl rollout status deployment cert-manager-webhook -n cert-manager
kubectl rollout status deployment cert-manager-cainjector -n cert-manager
sleep 10
kubectl create -f https://github.com/jaegertracing/jaeger-operator/releases/download/v1.46.0/jaeger-operator.yaml -n observability
kubectl rollout status deployment jaeger-operator -n observability
# kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl apply -f monitoring/metrics-server.yaml


# monitoring 
helm upgrade --install prom prometheus-community/kube-prometheus-stack -n monitoring --values monitoring/prom.yaml
helm upgrade --install loki grafana/loki -n monitoring --values monitoring/loki.yaml
helm upgrade --install promtail grafana/promtail -n monitoring --values monitoring/promtail.yaml

kubectl apply -f monitoring/jaeger.yaml -n monitoring
helm upgrade --install opentelemetry-collector open-telemetry/opentelemetry-collector -f monitoring/otel-collector-values.yaml -n monitoring

# networking
# istioctl install -y 
# kubectl apply -f networking/

k kustomize --enable-helm | k apply -f -

# minio set up 
# set up krew
#https://krew.sigs.k8s.io/docs/user-guide/setup/install/
# install kubectl minio plugin
# kubectl krew install minio
# kubectl minio init
# kubectl minio tenant create tenant1 --servers 1 --volumes 1 --capacity 5Gi --namespace customer-product
# tenant1 credentials exist in a k8s secret