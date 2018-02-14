# Istio is not just for microservices
Secure Kubernetes platform services by using Istio Service Mesh.  Typically, running live code helps users understand how to apply concepts to their own use cases.  This project centers around a basic Node.js application showing the power of Istio Service Mesh for persistence datastores such as etcd.

## Background on Istio
Istio is an open platform to connect, manage, and secure microservices. To learn more about Istio, please visit the [Intro page]( https://istio.io/about/intro.html).

## Setup
Getting started assumes an elementary understanding of Kubernetes.  In this project, there are a set of scripts that assume that installation of Docker, the Kubernetes CLI as well as jq for manipulating JSON objects returned from the various Kubernetes commands.  There is an assumption made about Node.js knowledge but this is not required. Here are some quick lines to the various tools below.

**Docker Install:** https://docs.docker.com/install/  
**Kubernetes Install:** https://kubernetes.io/docs/tasks/tools/install-kubectl/  
**jq Download:** https://stedolan.github.io/jq/download/  
**Node.js Download:** https://nodejs.org/en/download/  

## Kubernetes Providers
The code below should run on any Kubernetes compliant provider and has been tested on both Minikube and IBM Cloud Private. Depending upon which provider chosen, the instructions will vary slightly.

### Minikube
Minikube is available for download and installation instructions are located [here](https://kubernetes.io/docs/tasks/tools/install-minikube/). Minikube provides a simple and easy to use developer environment for learning about Kubernetes.

### IBM Cloud Private
IBM provides a Community Edition of their Kubernetes runtime free for development purposes and includes most of the same feature functions as their production version, Enterprise Edition, with the one exception being High Availabilty. To install, IBM Cloud Private, please refer to the [Installation Guide for 2.1.0](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0/installing/install_containers_CE.html)

## Istio Index Conf 2018 Application
To get started, clone the repo ```git clone git@github.com:todkap/istio-index-conf2018.git```

### Kubernetes Setup
- **Minikube:** Prior to deploying to Minikube, Minikube first needs to be started.   In the root directory of this project, there is a script ```createMinikubeEnv.sh``` that tears down the previous Minikube environment and initializes a new environment with the appropriate Kubernetes context.

- **IBM Cloud Private:** IBM Cloud Private has a [configure client](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0/manage_cluster/cfc_cli.html) step that will configure the Kubernetes CLI to point to a given IBM Cloud Private installation.  This context will be used each time the Kubectl CLI executes commands.

### Deploy
This project contains a script that will deploy Istio and the application to Kubernetes and is called ```deploy.sh```.  The script provide verbose output as it progresses through the various steps waiting for the entire systemt to be in ```Runninng``` state prior to exiting.

### Testing
This project contains two scripts for testing depending upon which Kubernetes provider that is used. The only difference in the two scripts is the setting of the ingress IP address for IBM Cloud Private.   To test choose either ```testICPEnv.sh``` or ```testMinikubeEnv.sh``` based upon your provider.

### Verification
To verify the success of the Istio integration, the script executes a set of tests.  

- The first test verifies a simple put test to the etcd service NodePort to validate connectivity to etcd.  
**Example output**
```
simple etcd test
*   Trying 192.168.64.20...
* TCP_NODELAY set
* Connected to 192.168.64.20 (192.168.64.20) port 32012 (#0)
> PUT /v2/keys/message HTTP/1.1
> Host: 192.168.64.20:32012
> User-Agent: curl/7.54.0
> Accept: */*
> Content-Length: 17
> Content-Type: application/x-www-form-urlencoded
> 
* upload completely sent off: 17 out of 17 bytes
< HTTP/1.1 201 Created
< content-type: application/json
< x-etcd-cluster-id: cdf818194e3a8c32
< x-etcd-index: 14
< x-raft-index: 15
< x-raft-term: 2
< date: Wed, 14 Feb 2018 19:45:24 GMT
< content-length: 102
< x-envoy-upstream-service-time: 1
< server: envoy
< x-envoy-decorator-operation: default-route
< 
{"action":"set","node":{"key":"/message","value":"Hello world","modifiedIndex":14,"createdIndex":14}}
* Connection #0 to host 192.168.64.20 left intact
```

- The second test verifies that the Node application can handle a simply ping request as well as proxy requests to etcd using the Node applications NodePort.  
**Example output**
```
-------------------------------
simple ping test
*   Trying 192.168.64.20...
* TCP_NODELAY set
* Connected to 192.168.64.20 (192.168.64.20) port 32380 (#0)
> GET / HTTP/1.1
> Host: 192.168.64.20:32380
> User-Agent: curl/7.54.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< x-powered-by: Express
< content-type: text/html; charset=utf-8
< content-length: 46
< etag: W/"2e-FL84XHNKKzHT+F1kbgSNIW2RslI"
< date: Wed, 14 Feb 2018 19:45:24 GMT
< x-envoy-upstream-service-time: 1
< server: envoy
< x-envoy-decorator-operation: default-route
< 
* Connection #0 to host 192.168.64.20 left intact
Simple test for liveliness of the application!
-------------------------------
test etcd service API call from node app
*   Trying 192.168.64.20...
* TCP_NODELAY set
* Connected to 192.168.64.20 (192.168.64.20) port 32380 (#0)
> PUT /storage HTTP/1.1
> Host: 192.168.64.20:32380
> User-Agent: curl/7.54.0
> Accept: */*
> Content-Type: application/json
> Content-Length: 60
> 
* upload completely sent off: 60 out of 60 bytes
< HTTP/1.1 201 Created
< x-powered-by: Express
< date: Wed, 14 Feb 2018 19:45:24 GMT
< x-envoy-upstream-service-time: 12
< server: envoy
< x-envoy-decorator-operation: default-route
< transfer-encoding: chunked
< 
* Connection #0 to host 192.168.64.20 left intact
nodeAppTesting created(etcd-service) ->{"key":"istioTest","value":"Testing Istio using NodePort"}:{"action":"set","node":{"key":"/istioTest","value":"Testing Istio using NodePort","modifiedIndex":15,"createdIndex":15},"prevNode":{"key":"/istioTest","value":"Testing Istio using Ingress","modifiedIndex":13,"createdIndex":13}}
*   Trying 192.168.64.20...
* TCP_NODELAY set
* Connected to 192.168.64.20 (192.168.64.20) port 32380 (#0)
> GET /storage/istioTest HTTP/1.1
> Host: 192.168.64.20:32380
> User-Agent: curl/7.54.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< x-powered-by: Express
< date: Wed, 14 Feb 2018 19:45:24 GMT
< x-envoy-upstream-service-time: 14
< server: envoy
< x-envoy-decorator-operation: default-route
< transfer-encoding: chunked
< 
* Connection #0 to host 192.168.64.20 left intact
nodeAppTesting(etcd-service) ->{"action":"get","node":{"key":"/istioTest","value":"Testing Istio using NodePort","modifiedIndex":15,"createdIndex":15}}
-------------------------------
```

- The next level of tests start to test Istio where traffic is routed through the Istio Ingress then to the Node application.  
**Example output**
```
simple hello test
*   Trying 192.168.64.20...
* TCP_NODELAY set
* Connected to 192.168.64.20 (192.168.64.20) port 32612 (#0)
> GET / HTTP/1.1
> Host: 192.168.64.20:32612
> User-Agent: curl/7.54.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< x-powered-by: Express
< content-type: text/html; charset=utf-8
< content-length: 46
< etag: W/"2e-FL84XHNKKzHT+F1kbgSNIW2RslI"
< date: Wed, 14 Feb 2018 19:45:24 GMT
< x-envoy-upstream-service-time: 6
< server: envoy
< 
* Connection #0 to host 192.168.64.20 left intact
Simple test for liveliness of the application!
-------------------------------
test etcd service API call from node app
*   Trying 192.168.64.20...
* TCP_NODELAY set
* Connected to 192.168.64.20 (192.168.64.20) port 32612 (#0)
> PUT /storage HTTP/1.1
> Host: 192.168.64.20:32612
> User-Agent: curl/7.54.0
> Accept: */*
> Content-Type: application/json
> Content-Length: 59
> 
* upload completely sent off: 59 out of 59 bytes
< HTTP/1.1 201 Created
< x-powered-by: Express
< date: Wed, 14 Feb 2018 19:45:24 GMT
< x-envoy-upstream-service-time: 15
< server: envoy
< transfer-encoding: chunked
< 
* Connection #0 to host 192.168.64.20 left intact
nodeAppTesting created(etcd-service) ->{"key":"istioTest","value":"Testing Istio using Ingress"}:{"action":"set","node":{"key":"/istioTest","value":"Testing Istio using Ingress","modifiedIndex":16,"createdIndex":16},"prevNode":{"key":"/istioTest","value":"Testing Istio using NodePort","modifiedIndex":15,"createdIndex":15}}
*   Trying 192.168.64.20...
* TCP_NODELAY set
* Connected to 192.168.64.20 (192.168.64.20) port 32612 (#0)
> GET /storage/istioTest HTTP/1.1
> Host: 192.168.64.20:32612
> User-Agent: curl/7.54.0
> Accept: */*
> 
< HTTP/1.1 200 OK
< x-powered-by: Express
< date: Wed, 14 Feb 2018 19:45:24 GMT
< x-envoy-upstream-service-time: 13
< server: envoy
< transfer-encoding: chunked
< 
* Connection #0 to host 192.168.64.20 left intact
nodeAppTesting(etcd-service) ->{"action":"get","node":{"key":"/istioTest","value":"Testing Istio using Ingress","modifiedIndex":16,"createdIndex":16}}
-------------------------------
```

- The final set of tests grep the istio-proxy logs searching for access logs for the client and server proxies to validate the traffic is routed through Istio.  
**Example output**
```
client logs from istio-proxy
[2018-02-14T16:28:24.640Z] "PUT /v2/keys/istioTest HTTP/1.1" 201 - 40 119 6 5 "-" "-" "45dd6431-49cf-9bcf-b611-1d319c56eb2e" "etcd-service:2379" "172.17.0.9:2379"
[2018-02-14T16:28:24.672Z] "GET /v2/keys/istioTest HTTP/1.1" 200 - 0 119 3 3 "-" "-" "8aa0f7d8-caac-9065-bb4c-d11c7af7d93f" "etcd-service:2379" "172.17.0.9:2379"
server logs from istio-proxy
[2018-02-14T16:28:24.640Z] "PUT /v2/keys/istioTest HTTP/1.1" 201 - 40 119 4 1 "-" "-" "45dd6431-49cf-9bcf-b611-1d319c56eb2e" "etcd-service:2379" "127.0.0.1:2379"
[2018-02-14T16:28:24.673Z] "GET /v2/keys/istioTest HTTP/1.1" 200 - 0 119 3 0 "-" "-" "8aa0f7d8-caac-9065-bb4c-d11c7af7d93f" "etcd-service:2379" "127.0.0.1:2379"
```


### Notes
- This project is based upon a Medium Article [Istio is not just for microservices](https://medium.com/ibm-cloud/istio-is-not-just-for-microservices-4ed199322bf4) written in 2017 and updated to support the latest version of Istio and Kubernetes.   As most of the content was embedded within the original Medium article, this project was created to allow developers to clone this repository and modify it to learn more about Kubernetes, Istio and etcd.
- The Node.js application source code is included in the nodejs subdirectory of the project and also includes the Dockerfile and build script for deploying to a Docker registry.   Some modifications would be required to publish the image to your own Docker registry and to have the deployment yaml reference the new image but should be relatively easy to figure out if necessary.
