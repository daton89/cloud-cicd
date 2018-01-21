#!/usr/bin/bash

sudo yum update -y

curl -fsSL https://get.docker.com/ | sh

sudo systemctl start docker

sudo systemctl status docker

sudo systemctl enable docker
