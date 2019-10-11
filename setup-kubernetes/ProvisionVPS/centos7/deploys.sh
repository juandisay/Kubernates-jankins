#!/bin/bash
# Author: juandisay


# Install yum update for latest for update system
#edit your hostname  
HOSTNAME=kworker3

echo "😹 Start update system"
yum update -y -q 

# Install required packages.
echo "😹 Install rq packer docker"
yum install -y -q yum-utils device-mapper-persistent-data lvm2 > /dev/null 2>&1

# Add Docker repository.
echo "😹 Docker repository add"
yum-config-manager \
  --add-repo \
  https://download.docker.com/linux/centos/docker-ce.repo > /dev/null 2>&1

# Install Docker CE.
echo "😹 Install docker machine" 
yum install -y -q docker-ce-18.06.2.ce > /dev/null 2>&1
systemctl start docker

# Create /etc/docker directory.
echo "😹 Try create dir /etc/docker"
mkdir /etc/docker

# Setup daemon.
echo "😹 Setup daemon"
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
echo "😹 Create path docker service"
mkdir -p /etc/systemd/system/docker.service.d

# reload and restart

echo "😹 Start reload daemon docker"
systemctl daemon-reload > /dev/null 2>&1
systemctl restart docker
systemctl enable docker

# Disable SELinux
echo "😹 Disable SElinux to false and symlink"
setenforce 0
sed -i --follow-symlinks 's/^SELINUX=enforcing/SELINUX=disabled/' /etc/sysconfig/selinux

echo "😹 Disable firewalld"
systemctl disable firewalld > /dev/null 2>&1

echo "😹 Stop firewalld"
systemctl stop firewalld

# Disable swap
sed -i '/swap/d' /etc/fstab

until swapoff -a > /dev/null 2>&1
do
  echo "swap memory off"
  sleep 1
done

# Update sysctl settings for Kubernetes networking
echo "😹 Update sysctl 4 k8s network"
cat >>/etc/sysctl.d/kubernetes.conf<<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

sysctl --system > /dev/null 2>&1

# Kubernetes Setup
# Add yum repository
echo "😹 Add repository and install Kubernates"
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

echo "😹 Install k8s"
yum -y -q install -y kubeadm kubelet kubectl > /dev/null 2>&1


# Enable and Start kubelet service
echo "😹 Enable kubelet"
systemctl enable kubelet > /dev/null 2>&1
systemctl start kubelet

until hostnamectl set-hostname $HOSTNAME 
do
  echo "hostname was change"
  sleep 5
done
echo "okey, system kubernates was installed! Mission complete!"

shutdown -r +1 "system was reboot in 1 minutes"
