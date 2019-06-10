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
```shell
kubectl create deployment aspnetapp --image="fuju9w/m31appl:v1"
kubectl get events
kubectl get deployment aspnetapp --output yaml > aspnetapp01.yaml
kubectl replace -f aspnetapp01.yaml 
kubectl get svc aspnetapp 
kubectl get ep aspnetapp 
kubectl get deploy,pod,svc,ep

kubectl expose deployment aspnetapp --type=LoadBalancer
kubectl delete svc aspnetapp
kubectl delete deployment aspnetapp
```
## delete cluster
```shell
#az aks delete --resource-group 1myResourceGroup --name myK8sCluster
```
# See Also:  
* https://github.com/fujute/m18h/blob/master/aks/01-aks.sh
* Ingress TLS with  Let's Encrypt certificates.:  https://docs.microsoft.com/en-us/azure/aks/ingress-tls


# appendix
```shell
        ports:
        - containerPort: 80
          protocol: TCP
```
