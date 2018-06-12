#!/bin/bash

export KIALI=$PWD/kiali
export GOPATH=$KIALI/source/kiali/kiali
export DOCKER_VERSION=latest
export SECURITY=$PWD/security

mkdir -p $GOPATH
cd $GOPATH
mkdir -p src/github.com/kiali	
cd src/github.com/kiali
git clone https://github.com/kiali/kiali.git
export PATH=${PATH}:${GOPATH}/bin

cd ${GOPATH}/src/github.com/kiali/kiali
make dep-install

echo $PWD
make build
make docker-build

make minikube-docker
make k8s-deploy

kubectl apply -f $SECURITY/kiala-cluster-role.yaml