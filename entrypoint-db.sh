#!/bin/bash
sudo yum update -y && sudo yum install mysql-server -y
sudo systemctl start mysql