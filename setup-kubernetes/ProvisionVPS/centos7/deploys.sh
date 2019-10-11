#!/bin/bash
# Author: juandisay


# Install yum update for latest for update system
#edit your hostname  
HOSTNAME=kworker

echo "start update system"
yum update

# Install required packages.
echo "Install rq packer docker"
until yum install yum-utils device-mapper-persistent-data lvm2
do
  echo "running installer persisten data"
  sleep 3
done

# Add Docker repository.
echo "docker repository add"
yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker CE. 
until yum update && yum install docker-ce-18.06.2.ce
do 
  echo "--docker run install--"
  sleep 5
done

# Create /etc/docker directory.
echo "create dir /etc/docker"
mkdir /etc/docker

# Setup daemon.
echo "setup daemon"
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2",
  "storage-opts": [
    "overlay2.override_kernel_check=true"
  ]
}
EOF


# docker service
echo "create path docker service"
mkdir -p /etc/systemd/system/docker.service.d

# reload and restart
until systemctl daemon-reload
do
  echo "docker reload"
  sleep 1
done

until systemctl restart docker
do
  echo "restart docker"
  sleep 3
done

# Disable SELinux
echo "disable SElinux to false"
setenforce 0
echo "follow symlink"
sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

echo "disable firewalld"
systemctl disable firewalld

echo "stop firewalld"
until systemctl stop firewalld
do 
  echo "firewalld stop it"
  sleep 3
done

# Disable swap
sed -i '/swap/d' /etc/fstab

until swapoff -a
do
  echo "swapof,finally, configuration was DOne! next Kubernates setup!"
  sleep 3
done

# Update sysctl settings for Kubernetes networking
echo "update sysctl 4 k8s network"
sleep 1
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

until sysctl --system
do
  echo "run system networking for k8s"
  sleep 3
done

# Kubernetes Setup
# Add yum repository
echo "add repository and install Kubernates"
echo "add repo"
sleep 1
cat >>/etc/yum.repos.d/kubernetes.repo<<EOF
[kubernetes]
name=Kubernetes
baseurl=https://packages.cloud.google.com/yum/repos/kubernetes-el7-x86_64
enabled=1
gpgcheck=1
repo_gpgcheck=1
gpgkey=https://packages.cloud.google.com/yum/doc/yum-key.gpg
        https://packages.cloud.google.com/yum/doc/rpm-package-key.gpg
EOF

echo "install k8s"
until yum install -y kubeadm kubelet kubectl
do
  echo "installing kubelet kubeadm kubectl"
  sleep 4
done

# Enable and Start kubelet service
echo "enable kubelet"
until systemctl enable kubelet
do
  echo "start kubelet"
  systemctl start kubelet
  sleep 2
done

until hostnamectl set-hostname $HOSTNAME
do
  echo "set hostname"
  sleep 3
done 

echo "okey, system kubernates was installed! Mission complete!"

shutdown -r +0.5 "system was reboot in 1 minutes"
