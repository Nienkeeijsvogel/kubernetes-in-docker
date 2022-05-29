#!/bin/bash

# Create network
docker network create kafka

# Create control-plane
docker run -d --privileged --network kafka --name master icebert/kubernetes-in-docker

docker exec master kubeadm init --ignore-preflight-errors all \
                                --pod-network-cidr 10.244.0.0/16 \
                                --token dzsner.a8tyt63f4hbs2ukz \
                                 
docker exec master sh -c "kubectl get configmap -n kube-system coredns -o yaml | sed '/loop/d' | kubectl replace -f -"

# Create pod network
docker exec master kubectl apply -f https://raw.githubusercontent.com/cloudnativelabs/kube-router/master/daemonset/kubeadm-kuberouter-all-features.yaml
docker exec master kubectl -n kube-system delete ds kube-proxy

# Create worker nodes
docker run -d --privileged --network kafka --name zookeeper icebert/kubernetes-in-docker
docker run -d --privileged --network kafka --name kafka icebert/kubernetes-in-docker
docker run -d --privileged --network kafka --name producer icebert/kubernetes-in-docker
docker run -d --privileged --network kafka --name consumer icebert/kubernetes-in-docker
 
docker exec zookeeper kubeadm join master:6443 --token dzsner.a8tyt63f4hbs2ukz \
                                             --discovery-token-unsafe-skip-ca-verification \
                                             --ignore-preflight-errors all
docker exec kafka kubeadm join master:6443 --token dzsner.a8tyt63f4hbs2ukz \
                                             --discovery-token-unsafe-skip-ca-verification \
                                             --ignore-preflight-errors all
docker exec producer kubeadm join master:6443 --token dzsner.a8tyt63f4hbs2ukz \
                                             --discovery-token-unsafe-skip-ca-verification \
                                             --ignore-preflight-errors all
docker exec consumer kubeadm join master:6443 --token dzsner.a8tyt63f4hbs2ukz \
                                             --discovery-token-unsafe-skip-ca-verification \
                                             --ignore-preflight-errors all




