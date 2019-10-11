#!/bin/bash
# Author: juandisay


# Install yum update for latest for update system
#edit your hostname  
HOSTNAME=kworker3

echo "start update system"
yum update -y -q > /dev/null/ 2>&1

# Install required packages.
echo "Install rq packer docker"
yum install -y -q yum-utils device-mapper-persistent-data lvm2 > /dev/null 2>&1

# Add Docker repository.
echo "docker repository add"
yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1

# Install Docker CE.
echo "install docker machine" 
yum install -y -q docker-ce-18.06.2.ce > /dev/null 2>&1

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

echo "start reload daemon docker"
systemctl start docker&&systemctl daemon-reload > /dev/null 2>&1
systemctl restart docker

# Disable SELinux
echo "disable SElinux to false and symlink"
setenforce 0
sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

echo "disable firewalld"
systemctl disable firewalld > /dev/null 2>&1

echo "stop firewalld"
systemctl stop firewalld

# Disable swap
sed -i '/swap/d' /etc/fstab

until swapoff -a > /dev/null 2>&1
do
  echo "swap memory off"
  sleep 3
done

# Update sysctl settings for Kubernetes networking
echo "update sysctl 4 k8s network"
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system >/dev/null 2>&1

# Kubernetes Setup
# Add yum repository
echo "add repository and install Kubernates"
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
yum -y -q install -y kubeadm kubelet kubectl > /dev/null 2>&1


# Enable and Start kubelet service
echo "enable kubelet"
systemctl enable kubelet > /dev/null 2>&1
systemctl start kubelet

until hostnamectl set-hostname $HOSTNAME 
do
  echo "hostname was change"
  echo "okey, system kubernates was installed! Mission complete!"
  sleep 5
done 

shutdown -r +1 "system was reboot in 1 minutes"
