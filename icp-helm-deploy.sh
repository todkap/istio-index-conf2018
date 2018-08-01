#!/bin/bash

export MASTER_IP=9.37.39.42

export PATH_TO_ETCD=$PWD/etcd
export PATH_TO_NODE=$PWD/nodejs
export SECURITY=$PWD/security
export GATEWAY=$PWD/gateway

function timer()
{
    if [[ $# -eq 0 ]]; then
        echo $(date '+%s')
    else
        local  stime=$1
        etime=$(date '+%s')

        if [[ -z "$stime" ]]; then stime=$etime; fi

        dt=$((etime - stime))
        ds=$((dt % 60))
        dm=$(((dt / 60) % 60))
        dh=$((dt / 3600))
        printf '%d:%02d:%02d' $dh $dm $ds
    fi
}
startTime=$(timer)

if [ !  -d "istio-1.0.0" ]; then
	curl -L https://git.io/getLatestIstio | ISTIO_VERSION=1.0.0 sh -
fi

cd istio-1.0.0
export PATH=$PWD/bin:$PATH

ACTION=apply

# install bx cli
curl -sL https://ibm.biz/idt-installer | bash

os=`uname`
case "$os" in
    Linux) os="linux" ;;
    Darwin) os="darwin" ;;
esac

curl -L  https://raw.githubusercontent.com/kubernetes/helm/master/scripts/get | bash -s -- --version v2.7.2  
export HELM_HOME=~/.helm

echo "helm version"
helm version

# install bx pr plugin
curl -ko icp-plugin https://$MASTER_IP:8443/api/cli/icp-$os-amd64
bx plugin install -f icp-plugin
rm -f icp-plugin
bx pr login -u admin -p admin --skip-ssl-validation -c id-mycluster-account -a https://$MASTER_IP:8443
bx pr cluster-config mycluster

helm init --client-only

echo "delete istio helm chart"
helm delete --purge istio --tls

echo "install istio CRDs"
## temporary install until helm can be updated on later release of ICP.
kubectl $ACTION -f https://raw.githubusercontent.com/IBM/charts/master/stable/ibm-istio/templates/crds.yaml

echo "deploy istio helm chart"
helm install https://raw.githubusercontent.com/IBM/charts/master/repo/stable/ibm-istio-1.0.0.tgz --name istio \
			--namespace istio-system --set sidecarInjectorWebhook.enabled=true \
			--set global.mtls.enabled=false --tls

statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods --namespace=istio-system -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done

export kcontext=$(kubectl config current-context)
export kns=$(kubectl config view $kcontext -o json | jq --raw-output '.contexts[] | select(.name=="'$kcontext'") | .context.namespace')
if [ "$kns" != "default" ]; then
	cat $SECURITY/permissions.yaml.tmpl | \
	sed -e "s/{NAMESPACE}/$kns/" > $SECURITY/permissions.yaml
	kubectl $ACTION -f $SECURITY/permissions.yaml
fi

kubectl label namespace $kns istio-injection=enabled --overwrite
kubectl get namespace -L istio-injection

statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done

echo "deploy Node application"
kubectl $ACTION  -f $PATH_TO_NODE/deployment.yaml


echo "deploy Istio Gateway and routing rule"
istioctl delete -f $ACTION -f $GATEWAY/http-gateway.yaml
istioctl delete -f $ACTION -f $GATEWAY/virtual-service.yaml

istioctl create -f $ACTION -f $GATEWAY/http-gateway.yaml
istioctl create -f $ACTION -f $GATEWAY/virtual-service.yaml

statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done

echo "deploy etcd"
kubectl $ACTION  -f $PATH_TO_ETCD/deployment.yaml

statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done

echo "deploy etcd operator"
kubectl $ACTION -f $PATH_TO_ETCD/etcd-operator-deployment.yaml

statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done

kubectl $ACTION -f "https://cloud.weave.works/k8s/scope.yaml?k8s-service-type=NodePort&k8s-version=$(kubectl version | base64 | tr -d '\n')"
kubectl $ACTION -f $SECURITY/permissions-weave.yaml

if [ "$ACTION" != "delete" ] ; then
	statusCheck="NOT_STARTED"
	while [ "$statusCheck" != "" ] ; do
		sleep 20
		statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
		echo "Still starting pods $(date)"
	done

	WEAVE_SCOPE_PORT=$(kubectl get service weave-scope-app --namespace=weave -o 'jsonpath={.spec.ports[0].nodePort}')
	echo "Weave Scope is available on port $WEAVE_SCOPE_PORT"
fi

	
endTime=$(timer startTime)
printf 'deploy Elapsed time: %s\n' $endTime 
