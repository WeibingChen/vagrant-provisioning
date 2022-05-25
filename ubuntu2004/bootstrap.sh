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
systemctl disable --now ufw >/dev/null 2>&1

echo "[TASK 3] Enable and Load Kernel modules"
cat >>/etc/modules-load.d/k8s.conf<<EOF 
br_netfilter
EOF

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
sysctl --system >/dev/null 2>&1

echo "[TASK 5] Install containerd runtime"
apt-get remove docker docker-engine docker.io containerd runc >/dev/null 2>&1
apt update -qq >/dev/null 2>&1
apt-get install -qq -y apt-transport-https ca-certificates gnupg lsb-release >/dev/null 2>&1

curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg | sudo apt-key add -  >/dev/null 2>&1
add-apt-repository "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu $(lsb_release -cs) stable" >/dev/null 2>&1

apt-get update -qq >/dev/null 2>&1
apt-get install -y docker-ce docker-ce-cli containerd.io >>${BOOTSTRAP}  2>&1 

cat >>/etc/docker/daemon.json <<EOF 
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF
systemctl enable docker  >/dev/null 2>&1
systemctl daemon-reload  >/dev/null 2>&1  
systemctl restart docker  >/dev/null 2>&1 

echo "[TASK 6] Add apt repo for kubernetes"
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg >/dev/null 2>&1
#apt-add-repository "deb http://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-xenial main" >/dev/null 2>&1
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] http://mirrors.ustc.edu.cn/kubernetes/apt kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list >/dev/null 2>&1
apt-get update -qq >/dev/null 2>&1

echo "[TASK 7] Install Kubernetes components (kubeadm, kubelet and kubectl)"
apt-get install -qq -y kubeadm=1.22.0-00 kubelet=1.22.0-00 kubectl=1.22.0-00 >>${BOOTSTRAP}  2>&1
apt-mark hold kubelet kubeadm kubectl >>${BOOTSTRAP}  2>&1
systemctl enable kubelet >/dev/null 2>&1
systemctl daemon-reload >/dev/null 2>&1
systemctl restart kubelet >/dev/null 2>&1

echo "[TASK 8] Enable ssh password authentication"
sed -i 's/^PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config
echo 'PermitRootLogin yes' >> /etc/ssh/sshd_config
systemctl reload sshd

echo "[TASK 9] Set root password"
echo -e "kubeadmin\nkubeadmin" | passwd root >/dev/null 2>&1
echo "export TERM=xterm" >> /etc/bash.bashrc

echo "[TASK 10] Update /etc/hosts file"
cat >>/etc/hosts<<EOF
172.16.16.100    kmaster    kmaster.example.com
172.16.16.101    kworker1   kworker1.example.com
172.16.16.102    kworker2   kworker2.example.com
EOF