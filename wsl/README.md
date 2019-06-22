# Windows Subsystem for Linux
## install WSL
https://docs.microsoft.com/en-us/windows/wsl/install-win10

## install azure CLI
* Install : https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest
* Update:
```shell 
sudo apt-get update && sudo apt-get install --only-upgrade -y azure-cli
```


## Install Helm
```shell
wget https://get.helm.sh/helm-v2.14.1-linux-amd64.tar.gz
tar -xvf helm-v2.14.1-linux-amd64.tar.gz
sudo mv ./linux-amd64/helm /usr/local/bin
ls -l /usr/local/bin
```
check update version from " https://github.com/helm/helm/releases " 
