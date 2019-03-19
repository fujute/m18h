Perparing ubuntu-16-04 for docker 
1. Create new ubuntu-16-04 vm
https://docs.microsoft.com/en-us/azure/virtual-machines/linux/quick-create-cli
2. docker install
ref: https://www.digitalocean.com/community/tutorials/how-to-install-and-use-docker-on-ubuntu-16-04
3. simple dodcker file 
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
