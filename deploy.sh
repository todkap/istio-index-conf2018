
export PATH_TO_ISTIO_ADDONS=$PWD/istioaddons
export PATH_TO_ETCD=$PWD/etcd
export PATH_TO_NODE=$PWD/nodejs

if [ !  -d "istio-0.5.0" ]; then
	curl -L https://git.io/getLatestIstio | sh -
fi

cd istio-0.5.0
export PATH=$PWD/bin:$PATH

echo "deploy the default istio platform with istio-auth"
kubectl apply -f install/kubernetes/istio-auth.yaml

statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done

kubectl apply -f install/kubernetes/addons/prometheus.yaml
kubectl apply -f $PATH_TO_ISTIO_ADDONS/prometheus_telemetry.yaml
kubectl apply -f install/kubernetes/addons/grafana.yaml


statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done

kubectl apply -f $PATH_TO_ETCD/etcd-deployment.yaml
kubectl apply -f $PATH_TO_ETCD/etcd-service.yaml

statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done
kubectl apply -f $PATH_TO_ETCD/etcd-cluster.yaml


statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done

echo "deploy Node application"
kubectl apply -f <(istioctl kube-inject -f $PATH_TO_NODE/all-in-one-deployment.yaml)
#kubectl apply -f $PATH_TO_NODE/all-in-one-deployment.yaml

statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done






