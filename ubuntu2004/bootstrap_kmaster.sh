#!/bin/bash

echo "[TASK 1] Pull required containers"
kubeadm config images pull --image-repository=registry.aliyuncs.com/google_containers >/dev/null 2>&1

echo "[TASK 2] Initialize Kubernetes Cluster"
kubeadm init --control-plane-endpoint=kmaster --pod-network-cidr=192.168.0.0/16 --image-repository=registry.aliyuncs.com/google_containers >> /root/kubeinit.log 2>/dev/null

echo "[TASK 3] Deploy Calico network"
kubectl --kubeconfig=/etc/kubernetes/admin.conf create -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml >/dev/null 2>&1

echo "[TASK 4] Generate and save cluster join command to /joincluster.sh"
kubeadm token create --print-join-command > /joincluster.sh 2>/dev/null