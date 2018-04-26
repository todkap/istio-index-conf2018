
export MASTER_IP=9.37.39.12

export PATH_TO_ISTIO_ADDONS=$PWD/istioaddons
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

# install helm cli
curl -ko helm https://$MASTER_IP:8443/helm-api/cli/$os-amd64/helm
mv helm /usr/local/bin
export PATH=/usr/local/bin:$PATH
chmod 755 /usr/local/bin/helm

if [ !  -d "istio-0.6.0" ]; then
	curl -L https://git.io/getLatestIstio | sh -
fi

export PATH=$PWD/istio-0.6.0/bin:$PATH

# install bx pr plugin
curl -ko icp-plugin https://$MASTER_IP:8443/api/cli/icp-$os-amd64
bx plugin install -f icp-plugin
rm -f icp-plugin
bx pr login -u admin -p admin --skip-ssl-validation -c id-mycluster-account -a https://$MASTER_IP:8443
bx pr cluster-config mycluster

helm init --client-only

kubectl delete services,deployment --all --namespace=istio-system
kubectl delete services,deployment --all --namespace=default

echo "deploy istio helm chart"
helm delete istio --purge --tls

rm -rf ./istio-chart
git clone git@github.ibm.com:IBMPrivateCloud/istio-chart.git istio-chart

helm install ./istio-chart --name istio --namespace istio-system --set sidecar-injector.enabled=true --set global.securityEnabled=false  --tls

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
