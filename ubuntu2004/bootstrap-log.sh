#!/bin/bash

## !IMPORTANT ##
#
## This script is tested only in the generic/ubuntu2004 Vagrant box
## If you use a different version of Ubuntu or a different Ubuntu Vagrant box test this again
#
BOOTSTRAP="bootstrap.log"
echo "[TASK 1] Disable and turn off SWAP"
sed -i '/swap/d' /etc/fstab
swapoff -a

echo "[TASK 2] Stop and Disable firewall"
systemctl disable --now ufw >>${BOOTSTRAP} 2>&1

echo "[TASK 3] Enable and Load Kernel modules"
cat >>/etc/modules-load.d/containerd.conf<<EOF
overlay
br_netfilter
EOF
modprobe overlay
modprobe br_netfilter

echo "[TASK 4] Add Kernel settings"
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
EOF
sysctl --system >>${BOOTSTRAP} 2>&1

echo "[TASK 5] Install containerd runtime"
apt update -qq >>${BOOTSTRAP} 2>&1
apt install -qq -y containerd apt-transport-https >>${BOOTSTRAP} 2>&1
mkdir /etc/containerd
containerd config default > /etc/containerd/config.toml
systemctl restart containerd
systemctl enable containerd >>${BOOTSTRAP} 2>&1

echo "[TASK 6] Add apt repo for kubernetes"
# curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - >>${BOOTSTRAP} 2>&1
curl -s https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add - >>${BOOTSTRAP} 2>&1 
# apt-add-repository "deb http://apt.kubernetes.io/ kubernetes-xenial main" >>${BOOTSTRAP} 2>&1
apt-add-repository "deb http://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-xenial main" >>${BOOTSTRAP} 2>&1

echo "[TASK 7] Install Kubernetes components (kubeadm, kubelet and kubectl)"
apt install -qq -y kubeadm=1.23.0-00 kubelet=1.23.0-00 kubectl=1.23.0-00 >>${BOOTSTRAP} 2>&1

echo "[TASK 8] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd

echo "[TASK 9] Set root password"
echo -e "kubeadmin\nkubeadmin" | passwd root >>${BOOTSTRAP} 2>&1
echo "export TERM=xterm" >> /etc/bash.bashrc

echo "[TASK 10] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
192.168.56.100   kmaster.example.com     kmaster
192.168.56.101   kworker1.example.com    kworker1
#192.168.56.102   kworker2.example.com    kworker2
EOF
