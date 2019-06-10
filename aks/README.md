AKS
##
sample
```shell
az aks create --resource-group 1myResourceGroup --name myK8sCluster --node-count 2 --generate-ssh-keys
az aks list
az aks show --resource-group 1myResourceGroup --name myK8sCluster

az aks get-credentials --resource-group 1myResourceGroup --name myK8sCluster --overwrite

kubectl get nodes
az aks scale --resource-group 1myResourceGroup --name myK8sCluster --node-count 3

#az aks delete --resource-group 1myResourceGroup --name myK8sCluster
```
## Create cluster 
* https://github.com/fujute/m18h/blob/master/aks/01-aks.sh
## Ingress TLS with  Let's Encrypt certificates.
* https://docs.microsoft.com/en-us/azure/aks/ingress-tls
