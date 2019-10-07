#!/bin/bash
# Author: juandisay


# Install yum update for latest for update system
echo "start update system"
yum update

# Install required packages.
echo "Install rq packer docker"
yum install yum-utils device-mapper-persistent-data lvm2

# Add Docker repository.
echo "docker repository add"
yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo

# Install Docker CE. 
echo "install docker"
yum update && yum install docker-ce-18.06.2.ce

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
echo "reload and restart docker"
echo "reload daemon"
systemctl daemon-reload
echo "restart"
systemctl restart docker
echo "finally, docker setup done!"

echo "configuration extend environtment system"

# Disable SELinux
echo "disable SElinux to false"
setenforce 0
echo "follow symlink"
sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

echo "disable firewalld"
systemctl disable firewalld

echo "stop firewalld"
systemctl stop firewalld

# Disable swap
sed -i '/swap/d' /etc/fstab
echo "swapoff"
swapoff -a

echo "finally, configuration DOne! next Kubernates setup!"

# Update sysctl settings for Kubernetes networking
echo "update sysctl 4 k8s network"
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
echo "run"
sysctl --system

# Kubernetes Setup
# Add yum repository
echo "add repository and install Kubernates"
echo "add repo"
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
yum install -y kubeadm kubelet kubectl

# Enable and Start kubelet service
echo "enable kubelet"
systemctl enable kubelet

echo "start kubelet"
systemctl start kubelet

