[cite from: vagrant-provisioning](https://github.com/justmeandopensource/kubernetes/tree/master/vagrant-provisioning)
> 这个是从上面的地址复制过来的，对里面的源做了改动，方便国内用户安装。

### 主机信息
| hostname | ip | box(os)| CPU | Memory |
| ---- | ---- | ---- | ---- | ---- |
| kmaster | 192.168.56.100 | [generic/ubuntu2004 3.3.0](https://app.vagrantup.com/generic/boxes/ubuntu2004/versions/3.3.0) | 2 cores | 2G |
| kworker1 | 192.168.56.101 | [generic/ubuntu2004 3.3.0](https://app.vagrantup.com/generic/boxes/ubuntu2004/versions/3.3.0) | 1 core | 1G |
| kworker2 | 192.168.56.102 | [generic/ubuntu2004 3.3.0](https://app.vagrantup.com/generic/boxes/ubuntu2004/versions/3.3.0) | 1 core | 1G |

### 版本信息
| name | version |
| ---- | ---- |
| docker/containerd | - |
| kubeadm | 1.22-00 |
| kubelet | 1.22-00 |
| kubectl | 1.22-00 |

### 使用

使用之前需要安装`Vagrant`和`VirtualBox`

```shell
# 进入根目录，执行，需要等待一段时间才能执行完成
$ vagrant up

# 安装成功成功之后，使用如下命令进入虚拟机
$ vagrant ssh kmaster
$ sudo -i
# 或者通过ssh，`root`密码在脚本已经配置好了`kubeadmin`
$ ssh root@192.168.56.100
# 登录进去之后，可以简单测试，显示如下信息说明集群成功了
root@kmaster:~/ # kubectl cluster-info
Kubernetes control plane is running at https://192.168.56.100:6443
CoreDNS is running at https://192.168.56.100:6443/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

# 如果出现下面的提示`The connection to the server localhost:8080 was refused - did you specify the right host or port?`，先执行以下命令做一下配置
root@kmaster:~/ # cp /etc/kubernetes/admin.conf ~/.kube/config
```

### 在宿主机上操作集群
如果不想每次登录到虚机上，想在本地宿主机上操作k8s集群，可以这样做：
1. 首先在本地安装`kubectl`
2. 创建配置文件目录
`$ mkdir -p ~/.kube`
3. 将虚机上的配置文件拷贝到本地
`$ scp root@192.168.56.100:/root/.kube/config ~/.kube/config`
4. 在宿主机上执行
```shell
$ kg pod -n kube-system -o wide
NAME                                       READY   STATUS    RESTARTS      AGE     IP               NODE       NOMINATED NODE   READINESS GATES
calico-kube-controllers-5bf6854bb9-9qx4l   1/1     Running   1 (36m ago)   3h4m    10.244.189.6     kmaster    <none>           <none>
calico-node-4gngw                          1/1     Running   1 (36m ago)   3h2m    192.168.56.101   kworker1   <none>           <none>
calico-node-5mwtc                          1/1     Running   1 (36m ago)   3h4m    192.168.56.100   kmaster    <none>           <none>
calico-node-vtkgl                          1/1     Running   3 (77s ago)   4m48s   192.168.56.102   kworker2   <none>           <none>
coredns-78fcd69978-sbzm9                   1/1     Running   1 (36m ago)   3h4m    10.244.189.5     kmaster    <none>           <none>
coredns-78fcd69978-tgp2p                   1/1     Running   1 (36m ago)   3h4m    10.244.189.4     kmaster    <none>           <none>
etcd-kmaster                               1/1     Running   1 (36m ago)   3h5m    192.168.56.100   kmaster    <none>           <none>
kube-apiserver-kmaster                     1/1     Running   1 (36m ago)   3h5m    192.168.56.100   kmaster    <none>           <none>
kube-controller-manager-kmaster            1/1     Running   1 (36m ago)   3h5m    192.168.56.100   kmaster    <none>           <none>
kube-proxy-kp6tm                           1/1     Running   1 (36m ago)   3h2m    192.168.56.101   kworker1   <none>           <none>
kube-proxy-v2gjd                           1/1     Running   0             4m30s   192.168.56.102   kworker2   <none>           <none>
kube-proxy-x59zv                           1/1     Running   1 (36m ago)   3h4m    192.168.56.100   kmaster    <none>           <none>
kube-scheduler-kmaster                     1/1     Running   1 (36m ago)   3h5m    192.168.56.100   kmaster    <none>           <none>
```

### vagrant snapshot
测试过程中经常碰到问题，有时难以排查，干脆从头再来，这时如果从新搭建会比较耗时，vagrant提供了snapshot功能，可以做一个快照，需要的时候恢复一下就可以了
```shell
$ vagrant halt
$ vagrant snapshot save k8s-clean-base
$ vagrant snapshot list
==> kmaster:
k8s-clean-base
==> kworker1:
k8s-clean-base
==> kworker2:
k8s-clean-base
```


### 常用的几个vagrant命令
```shell
$ vagrant up        # 启动虚拟机
$ vagrant halt      # 关闭虚拟机
$ vagrant reload    # 重启虚拟机
$ vagrant ssh       # SSH 至虚拟机
$ vagrant suspend   # 挂起虚拟机
$ vagrant resume    # 唤醒虚拟机
$ vagrant status    # 查看虚拟机运行状态
$ vagrant destroy   # 销毁当前虚拟机
 

#box管理命令
$ vagrant box list    # 查看本地box列表
$ vagrant box add     # 添加box到列表

$ vagrant box remove  # 从box列表移除 


# snapshot管理
$ vagrant snapshot save <snapshot name> # 生成快照
$ vagrant snapshot list
```

### 问题
1. ssh登录报错，如果出现如下的问题，使用`ssh-keygen -R 192.168.56.100`删除`known_hosts`中对应的的秘钥信息
```
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
```

2. 如果`vagrant up`没有执行成功，这个界面上看不到具体的日志，为了捕捉到出错信息，可以修改`bootstrap.sh`中的`>/dev/null`，改为输出到日志文件，然后登录虚机上，查看输出内容，针对解决。

3. 如果个虚机上的pod错误，可以尝试重启虚机，然后删除pod试试
