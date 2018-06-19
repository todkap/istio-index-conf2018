#!/bin/bash

export PATH_TO_ISTIO_ADDONS=$PWD/istioaddons
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



if [ !  -d "istio-0.8.0" ]; then
	curl -L https://git.io/getLatestIstio | ISTIO_VERSION=0.8.0 sh -
fi

cd istio-0.8.0
export PATH=$PWD/bin:$PATH

ACTION=apply

# echo "deploy the default istio platform with istio-auth"
# kubectl $ACTION -f install/kubernetes/istio-auth.yaml
echo "deploy the default istio platform with istio"
kubectl create namespace istio-system
kubectl $ACTION -f install/kubernetes/istio-demo.yaml


statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done

kubectl $ACTION -f install/kubernetes/addons/prometheus.yaml
kubectl $ACTION -f $PATH_TO_ISTIO_ADDONS/prometheus_telemetry.yaml
kubectl $ACTION -f install/kubernetes/addons/grafana.yaml


export kcontext=$(kubectl config current-context)
export kns=$(kubectl config view $kcontext -o json | jq --raw-output '.contexts[] | select(.name=="'$kcontext'") | .context.namespace')
if [ "$kns" != "default" ] ; then
	if [[ ! -z "$kns"  ]] ; then
		kns="default" 
	fi
	cat $SECURITY/permissions.yaml.tmpl | \
	sed -e "s/{NAMESPACE}/$kns/" > $SECURITY/permissions.yaml
	kubectl $ACTION -f $SECURITY/permissions.yaml
fi

statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done

echo "deploy Node application"
kubectl $ACTION  -f <(istioctl kube-inject -f $PATH_TO_NODE/deployment.yaml)

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
kubectl $ACTION  -f <(istioctl kube-inject -f $PATH_TO_ETCD/deployment.yaml)

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
