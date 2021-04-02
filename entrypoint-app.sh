#!/bin/bash
sudo yum update -y && sudo yum install docker -y
sudo systemctl start docker
sudo usermod -aG docker ec2-user
sudo chmod 666 /var/run/docker.sock
docker run -itd --name nginx -p 80:80 -p 443:443 shashwot/nginx-more