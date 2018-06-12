#!/bin/bash

export MASTER_IP=9.37.39.99

export PATH_TO_ETCD=$PWD/etcd
export PATH_TO_NODE=$PWD/nodejs
export SECURITY=$PWD/security

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

export PATH=$PWD/istio-0.7.1/bin:$PATH

# install bx pr plugin
curl -ko icp-plugin https://$MASTER_IP:8443/api/cli/icp-$os-amd64
bx plugin install -f icp-plugin
rm -f icp-plugin
bx pr login -u admin -p admin --skip-ssl-validation -c id-mycluster-account -a https://$MASTER_IP:8443
bx pr cluster-config mycluster

helm init --client-only

echo "deploy istio helm chart"
helm delete --purge istio --tls

helm install https://raw.githubusercontent.com/IBM/charts/master/repo/stable/ibm-istio-0.7.1.tgz --name istio --namespace istio-system --set sidecar-injector.enabled=true,global.mtls.enabled=false --tls

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
