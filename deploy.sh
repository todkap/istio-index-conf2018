
export PATH_TO_ISTIO_ADDONS=$PWD/istioaddons
export PATH_TO_ETCD=$PWD/etcd
export PATH_TO_NODE=$PWD/nodejs

if [ !  -d "istio-0.5.1" ]; then
	curl -L https://git.io/getLatestIstio | sh -
fi

cd istio-0.5.1
export PATH=$PWD/bin:$PATH

ACTION=apply

# echo "deploy the default istio platform with istio-auth"
# kubectl $ACTION -f install/kubernetes/istio-auth.yaml
echo "deploy the default istio platform with istio"
kubectl $ACTION -f install/kubernetes/istio.yaml


statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done

kubectl $ACTION -f install/kubernetes/addons/prometheus.yaml
kubectl $ACTION -f $PATH_TO_ISTIO_ADDONS/prometheus_telemetry.yaml
kubectl $ACTION -f install/kubernetes/addons/grafana.yaml


statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done

# echo "commenting out the etcd injection step"
# nodeAppTesting failed(example-etcd-cluster) ->
# {"errors":[{"server":"http://example-etcd-cluster:2379","httperror":{"code":"ENOTFOUND","errno":"ENOTFOUND","syscall":
# "getaddrinfo","hostname":"example-etcd-cluster","host":"example-etcd-cluster","port":"2379"},"timestamp":"2018-02-13T21:42:24.979Z"}],"retries":0}
kubectl $ACTION -f <(istioctl kube-inject -f $PATH_TO_ETCD/etcd-deployment.yaml)
kubectl $ACTION -f <(istioctl kube-inject -f $PATH_TO_ETCD/etcd-service.yaml)

statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done
kubectl $ACTION -f <(istioctl kube-inject -f $PATH_TO_ETCD/etcd-cluster.yaml)


echo "commenting out the etcd sans istio step"
# kubectl $ACTION -f $PATH_TO_ETCD/etcd-deployment.yaml
# kubectl $ACTION -f $PATH_TO_ETCD/etcd-service.yaml

# statusCheck="NOT_STARTED"
# while [ "$statusCheck" != "" ] ; do
# 	sleep 20
# 	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
# 	echo "Still starting pods $(date)"
# done
# kubectl $ACTION -f $PATH_TO_ETCD/etcd-cluster.yaml


statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done

echo "deploy Node application"
kubectl $ACTION  -f <(istioctl kube-inject -f $PATH_TO_NODE/all-in-one-deployment.yaml)
# kubectl $ACTION -f $PATH_TO_NODE/all-in-one-deployment.yaml

statusCheck="NOT_STARTED"
while [ "$statusCheck" != "" ] ; do
	sleep 20
	statusCheck=$(kubectl get pods  -o json | jq '.items[].status.phase' | grep -v "Running")
	echo "Still starting pods $(date)"
done