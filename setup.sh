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



# monitoring 
helm upgrade --install prom prometheus-community/kube-prometheus-stack -n monitoring --values monitoring/prom.yaml
helm upgrade --install loki grafana/loki -n monitoring --values monitoring/loki.yaml
helm upgrade --install promtail grafana/promtail -n monitoring --values monitoring/promtail.yaml

kubectl apply -f monitoring/jaeger.yaml -n monitoring
helm upgrade --install opentelemetry-collector open-telemetry/opentelemetry-collector -f monitoring/otel-collector-values.yaml -n monitoring

# networking
istioctl install -y --set meshConfig.defaultConfig.tracing.zipkin.address=simplest-collector.monitoring.svc.cluster.local:9411 
kubectl apply -f networking/kiali.yaml

k kustomize --enable-helm | k apply -f -