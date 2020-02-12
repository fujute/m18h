# AKS
## create cluster 
```shell
az aks create --resource-group 1myResourceGroup --name myK8sCluster --node-count 2 --generate-ssh-keys
az aks list
az aks show --resource-group 1myResourceGroup --name myK8sCluster

az aks get-credentials --resource-group 1myResourceGroup --name myK8sCluster --overwrite

kubectl get nodes
az aks scale --resource-group 1myResourceGroup --name myK8sCluster --node-count 3
```
## create deployment
Option #1
```shell
kubectl create deployment aspnetapp --image="fuju9w/m31appl:v1"
kubectl get events
kubectl get deployment aspnetapp --output yaml > aspnetapp01.yaml
kubectl replace -f aspnetapp01.yaml 
kubectl get svc aspnetapp 
kubectl get ep aspnetapp 
kubectl get deploy,pod,svc,ep

kubectl expose deployment aspnetapp --type=LoadBalancer
kubectl get service aspnetapp --watch

kubectl delete svc aspnetapp
kubectl delete deployment aspnetapp
```
Option #2
```shell
kubectl create deployment php-app --image=fuju9w/container-info -o yaml --dry-run=true
kubectl create deployment php-app --image=fuju9w/container-info -o yaml --dry-run=true > phpapp01.yaml
kubectl create -f phpapp01.php
kubectl get deploy,pod,svc,ep

kubectl get events
kubectl expose deployment  php-app --type=LoadBalancer
kubectl scale --replicas=2 -f phpapp01.yaml
kubectl get pods
kubectl delete deployment php-app
```
## browse
```shell
kubectl create clusterrolebinding kubernetes-dashboard \
--clusterrole=cluster-admin \
--serviceaccount=kube-system:kubernetes-dashboard

az aks browse --resource-group 1myResourceGroup --name myK8sCluster
```

## delete cluster
```shell
#az aks delete --resource-group 1myResourceGroup --name myK8sCluster
```

# Snippet
* dry-run
```shell
kubectl run --generator=deployment/v1beta1 php-app --image=fuju9w/php-app -o yaml --dry-run
```
* adding port in YAML file 

```shell
        ports:
        - containerPort: 80
          protocol: TCP
```
* with appID
```shell
az ad sp create-for-rbac --skip-assignment
az aks create \
 --name myK8sCluster \
 -- resource-group 1myResourceGroup \
 --node-count 2 \
 --generate-ssh-keys \
 --service-principal <<appId>>
 --client-secret <<password>>
 -- location southeastasia
```
* get services
```shell
kubectl get svc --namespace kube-system
```

# See Also:  
* https://github.com/fujute/m18h/blob/master/aks/01-aks.sh
* Ingress TLS with  Let's Encrypt certificates.:  https://docs.microsoft.com/en-us/azure/aks/ingress-tls
* https://kubernetes.io/docs/reference/kubectl/cheatsheet/

