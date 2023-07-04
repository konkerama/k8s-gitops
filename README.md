# K8s Project

## DB Set up

### Postgres

https://blog.devgenius.io/how-to-deploy-postgresql-db-server-and-pgadmin-in-kubernetes-a-how-to-guide-57952b4e29a8

``` bash 
kubectl port-forward svc/pgadmin 8080:80 -n curstomer-product
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