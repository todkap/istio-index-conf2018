
#!/bin/bash

ingressIP=$(minikube ip)
ingressPort=$(kubectl -n istio-system get svc istio-ingress -o 'jsonpath={.spec.ports[0].nodePort}'); echo ""

echo "simple etcd test"
curl -v http://$ingressIP:32012/v2/keys/message -XPUT -d value="Hello world"; echo ""
echo "-------------------------------"

echo "simple ping test"
curl -v http://$ingressIP:32380/; echo ""
echo "-------------------------------"

echo "test etcd service API call from node app"
curl -v http://$ingressIP:32380/storage -H "Content-Type: application/json" -XPUT -d '{"key": "istioTest", "value":"Testing Istio using NodePort"}'; echo ""
curl -v http://$ingressIP:32380/storage/istioTest; echo ""
echo "-------------------------------"

echo "simple hello test"
curl -v http://$ingressIP:$ingressPort/; echo ""
echo "-------------------------------"

echo "test etcd service API call from node app"
curl -v http://$ingressIP:$ingressPort/storage -H "Content-Type: application/json" -XPUT -d '{"key": "istioTest", "value":"Testing Istio using Ingress"}'; echo ""
curl -v http://$ingressIP:$ingressPort/storage/istioTest; echo ""
echo "-------------------------------"

CLIENT=$(kubectl get pod -l app=proxy-etcd-storage -o jsonpath='{.items[0].metadata.name}')
SERVER=$(kubectl get pod -l app=etcd -o jsonpath='{.items[0].metadata.name}')
#Search the client logs for the API calls to etcd. 

echo "client logs from istio-proxy"
kubectl logs $CLIENT istio-proxy | grep /v2/keys
echo "server logs from istio-proxy"
kubectl logs $SERVER istio-proxy | grep /v2/keys


## Simple load test using loadtest (https://www.npmjs.com/package/loadtest)
if [ -x "$(command -v loadtest)" ]; then
	loadtest -n 4000 -c 10 --rps 50 http://$ingressIP:$ingressPort/storage/istioTest
	loadtest -n 4000 -c 10 --rps 50 http://$ingressIP:$ingressPort/storage/istioTest
	loadtest -n 4000 -c 10 --rps 50 http://$ingressIP:$ingressPort/storage/istioTest
fi


