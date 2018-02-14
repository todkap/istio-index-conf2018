# Istio is not just for microservices
Secure your Kubernetes platform services by using Istio Service Mesh. Since I find that writing an application helps users understand how to apply concepts to their own use cases, I wrote a basic Node.js application to show the interaction between Istio and etcd.

## Background on Istio
Istio is an open platform to connect, manage, and secure microservices. To learn more about Istio, I would suggest you visit the [Intro page]( https://istio.io/about/intro.html).

## Setup
To get started, you should have an elementary understanding of Kubernetes.  In this project, I provide a set of scripts that assume that you have already installed Docker, the Kubernetes CLI as well as jq for manipulating JSON objects returned from the various Kubernetes commands.   I also assume that you know Node.js but this is not required. I have provided quick lines to the various tools below.

**Docker Install:** https://docs.docker.com/install/
**Kubernetes Install:** https://kubernetes.io/docs/tasks/tools/install-kubectl/
**jq Download:** https://stedolan.github.io/jq/download/
**Node.js Download:** https://nodejs.org/en/download/

## Kubernetes Providers
The code below should run on any Kubernetes compliant provider. I have tested on both Minikube and IBM Cloud Private. Depending upon which option you choose, the instructions will vary slightly.

### Minikube
Minikube is available for download and installation instructions are located [here](https://kubernetes.io/docs/tasks/tools/install-minikube/). Minikube provides a simple and easy to use developer environment for learning about Kubernetes.

### IBM Cloud Private
IBM provides a Community Edition of their Kubernetes runtime free for development purposes and includes most of the same feature functions as their production version, Enterprise Edition, with the one exception being High Availabilty. To install, IBM Cloud Private, please refer to the [Installation Guide for 2.1.0] (https://www.ibm.com/support/knowledgecenter/en/SSBS6K_2.1.0/installing/install_containers_CE.html)




### Side Note
This project is a updated version of a Medium Article [Istio is not just for microservices](https://medium.com/ibm-cloud/istio-is-not-just-for-microservices-4ed199322bf4) written in 2017 and has been updated to make the scenario work with latest version of Istio and Kubernetes.   As most of the content was embedded with the Medium article, I felt it would be better to include the entire project and allow readers to clone this repository and modify it to learn more about Kubernetes, Istio and etcd.
