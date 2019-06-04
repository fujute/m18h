# Perparing ubuntu-16-04 for docker 
## 1. Create new ubuntu-16-04 vm
ref: https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-cli
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
## 2. Install docker
```shell
sudo apt-get update && sudo apt-get upgrade -y
sudo apt-get install -y docker.io
sudo systemctl status docker
sudo usermod -aG docker ${USER}
```
or
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
## 3. Install .NET core
ref: https://dotnet.microsoft.com/download/linux-package-manager/ubuntu16-04/sdk-current
```shell
wget -q https://packages.microsoft.com/config/ubuntu/16.04/packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
sudo apt-get install apt-transport-https
sudo apt-get update
sudo apt-get install dotnet-sdk-2.2
```
## 4. Dockerize a simple PHP application
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
## 5.Dockerize a ASP.NET Core application
ref: 
* https://docs.docker.com/engine/examples/dotnetcore/ 
* Docker images for ASP.NET Core ( https://docs.microsoft.com/en-us/aspnet/core/host-and-deploy/docker/building-net-docker-images?view=aspnetcore-2.2 )

```shell
git clone https://github.com/dotnet/dotnet-docker
docker build -t aspnetapp .
docker run -it --rm -p 5000:80 --name aspnetcore_sample aspnetapp
#docker tag local-image:tagname new-repo:tagname
#docker push new-repo:tagname 
docker login 
docker tag aspnetapp fuju9w/m31appl:v1
docker push fuju9w/m31appl:v1
```


docker push fuju9w/m31appl:tagname

# Tips:
```shell
cat report.txt | clip.exe
```
