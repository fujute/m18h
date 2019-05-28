Perparing ubuntu-16-04 for docker 
1. Create new ubuntu-16-04 vm
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-cli
```shell
az group create --name 1myResourceGroup --location southeastasia
az vm image list --location southeastasia --publisher Canonical \
  --offer UbuntuServer --sku 16.04-LTS --all --output table
az vm create \
  --resource-group 1myResourceGroup \
  --name myDockerVM \
  --image Canonical:UbuntuServer:16.04-LTS:latest \
  --admin-username azadmin \
  --generate-ssh-keys
```
2. docker install
ref: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04
```shell
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt-get update
apt-cache policy docker-ce
sudo apt-get install -y docker-ce
sudo systemctl status docker
sudo usermod -aG docker ${USER}
```

3. Simple docker file with PHP
ref: https://hub.docker.com/_/php
```shell
$mkdir php-docker-app  
$cat Dockerfile
Dockefile
FROM php:7.2-apache
COPY src/ /var/www/html/
$docker build -t php-app .  
$docker run -p 8080:80 php-app 
```
4.Dockerize a .NET Core application
https://docs.docker.com/engine/examples/dotnetcore/
