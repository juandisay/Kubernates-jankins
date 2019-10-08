
## On kmaster
##### Initialize Kubernetes Cluster
```
kubeadm init --apiserver-advertise-address=192.168.99.100 --pod-network-cidr=192.168.0.0/16

# note
please check your network

```
##### Copy kube config
To be able to use kubectl command to connect and interact with the cluster, the user needs kube config file.

send to root configuration 
```
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

OR 

send to user / non root configuration 
```
mkdir -p /home/deploy/.kube
sudo cp /etc/kubernetes/admin.conf /home/deploy/.kube/config
sudo chown user:pwduser /home/deploy/.kube/config
export KUBECONFIG=/home/deploy/.kube/config
```

##### NOTES FOR LINUX PROVISION SERVER
please add 
```
export KUBECONFIG=<path/your/configuration>
```
to file ~/.bashrc

##### Deploy flannel network for binding network
github:
https://github.com/coreos/flannel
This has to be done as the user in the above step:
```
kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
```
>Important Note:
>
>If your virtual machine just has one network interface, the above flannel resource will work.
If you used Vagrant to provision the virtual machine (using VirtualBox provider), the default eth0 interface will have ip address like 10.0.2.15. This is vagrant specific. You won't be able to connect to the virtual machine using ssh if you have only this network interface. This interface is useful only for doing "vagrant ssh" to get into the machine.
>
>In your vagrant file you will have to add a public network with an IP address so that you can get to the machine from your host machine. This network interface will be added as eth1.
>
>If this is the case, we need to modify the flannel resource to make eth1 as the standard interface. Otherwise it will pick eth0 and pod to pod communication won't work.
>
>You can use the below command with the modified kube-flannel.yml (from my repo). I have added --iface eth1 option to the container.
```
kubectl apply -f https://raw.githubusercontent.com/justmeandopensource/kubernetes/master/vagrant-provisioning/kube-flannel.yml
```

##### Cluster join command
```
kubeadm token create --print-join-command
```
## On Kworker
##### Join the cluster
Use the output from __kubeadm token create__ command in previous step from the master server and run here.

## Verifying the cluster
##### Get Nodes status
```
kubectl get nodes
```
##### Get component status
```
kubectl get cs
```

##### More reference
```
1. https://kubernetes.io/docs/setup/production-environment/container-runtimes/#docker
2. https://www.tecmint.com/network-between-guest-vm-and-host-virtualbox/
3. https://kubernetes.io/docs/tasks/access-application-cluster/configure-access-multiple-clusters/#append-home-kube-config-to-your-kubeconfig-environment-variable
```


