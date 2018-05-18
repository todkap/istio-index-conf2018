export KIALI=$PWD/kiali
export GOPATH=$KIALI/source/kiali/kiali

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

# make minikube-docker
make docker-push
make k8s-deploy