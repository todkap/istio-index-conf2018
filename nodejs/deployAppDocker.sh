#!/bin/sh
set -e

export DOCKER_ID_USER="todkap"
docker login

docker build --no-cache=true -t todkap/proxy-etcd-storage:v1 .

docker push todkap/proxy-etcd-storage:v1