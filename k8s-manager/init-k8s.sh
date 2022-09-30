#!/bin/bash
sudo apt update -y
sudo apt install -y ansible

#Change /etc/hosts
hostname -I | sed "s/$/$(hostname)/" | tee /etc/hosts
echo "ip_worker worker1" | tee -a /etc/hosts

#Edit ansible config
mkdir -p /etc/ansible/
txt="[defaults]\nhost_key_checking=False\npipelining=True\nforks=100"
echo -e $txt > /etc/ansible/ansible.cfg

cd /home/ubuntu
#Edit host file
cat <<EOF > /home/ubuntu/hosts
[all:vars]
ansible_become=true
ansible_ssh_private_key_file=/home/ubuntu/windows.pem
ansible_user=ubuntu

[all]
$(hostname) kubernetes_role="master"
worker1 kubernetes_role="node"
EOF

#Edit key file
cat << EOF > /home/ubuntu/windows.pem
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAqdC1nIW2a1q8fFdtnJeGvK3rODJDkfhUb7v4y5BvcTT9V8rj
Csa6GutRZcdvVh9sIPsJ3zObP+0K3Hl4eqvBMEGs7zSLS7SWxFOMPbcxOewKifWj
oN725NGkoqse0dB5ALlj3hAb/RcjGTcxX/28GXG0+GjCD/0wgIwEDxiCnagXwZ1l
mC2Xn1J0TGh5IAnp9Vc7GYHPY6KfDEs9eSFA3uATOSDaCMISBvAmIywPR0jp/+hF
j77i+Y34K9iGAR7IILmPxfohTw0zXkMAOKgZFCICcwwN9gU4Bnm/la8pFsga1fqS
8EHeDHY1NUI2NcZ32w0Y8KmBRctYLnWp4eNknwIDAQABAoIBAELTTQShYd3xQQc1
aH8c6frJ/iyJKyoALUojEI8a8Z/9GE06HAqblZUOUWPaDag4iVaZM5NQPaH0aDfG
3XB4sneJAMLJTJ+oG0R7FE8dDhQbHTKZJaEi3MnC7iTNbj1m6pcsXW5/rGP2fOtp
WtbJhQIGSw8OOoAMRM/xSY+fN5dOcHNL34EskE5LhHzV+KBU8DU4Vm/E2mL/iKzV
NrF5l6DLEVUl4fW907y0gzNPVvPjxMPwGQvXQtdNNd4zZJbYnQ619Rsr4b/t0SE2
rsrEBwST0i1rUY0GX3JeC91N/fny8q45C6mERvx+JCYAxB+Ehe7lxv/7BmMJkIOM
uDSw18ECgYEA2nfu1H3FZ0AE+rXPJ1uoJ5hPoZ8fwrK04pTLbmuGfQlAEkfN0WC2
8bPzFfkne7m0Ebk6YbmlAajrlr+7RVYLgOENQgdM29KUfA0s2DdD0NXO3SkfwEUv
v1V9LuDgr4Z0WHO6VF7+qumON/SVwHkwVbxEPAqbdu/n6X+gab+zI3ECgYEAxv0M
JO98IE2OXZKanXttfJ6T5tKswOo+eu32DlEUtXooK/sowarD8JfVxpJ1FCqMmXcX
YJI4yLEtYJMSkGTncdHMYyyrrJAmW1RDzCcVcw9EAqxbhz19nmdwAZM3nyU7l6Y1
lazgzhQk/Xg2Wu7Jk7P67qtPgsLXG7o8bV0e4Q8CgYA/fyxDRmrhn5HS7JTQ86rk
FzjN2Nn6VMaONIEMDuR/4vhkV8pSWLHTfmHguRHovAjCPfvh+3siCF6w6fkcJe4h
/0dDMav9GC9f/tRR434qbHo7fYBk+bbu/YHs5h9n5MRcEQbPDu0l78wOJ2B/GLob
sSSD7vFQmFnnW9jb44PFgQKBgHXQSKptqF4vzQSV0jk/ZLmN4h+dyG6HwepijXY4
hzxTUQmJML5Jbq06GHXzLKJ99rS+D/c7W6dnT2iIa0tWkrmO76YgQpxu1GbqYyGy
Wj6/YRL8HUzbGU76CxTDpwDwuHG3FK7Dpm4c+zGfRP9dtbdfrkg04WSYG2ftQe22
Xpv9AoGBALe8B5YFZ0Adlj68k53B6oM4gPg0Xs6rRRJWhMxkND8QcWjh5TjLIuXn
UAP0e6YBgeIpNZ2JIWrHRpcWF3QJt6LY0rF9RetmyPLWV3ihkhSGCRvm9Oi/TWTw
j1cbe1aDydXgnbUeYRWO3hOUbSAPM5DYWwwuMalWe3BoGeviexK0
-----END RSA PRIVATE KEY-----
EOF
#change permission
chmod 0400 /home/ubuntu/windows.pem

#Edit playbook

cat <<EOF > /home/ubuntu/playbook.yaml
- hosts: all
  become: true
  become_method: sudo
  become_user: root
  vars:
    kubernetes_allow_pods_on_master: true
  pre_tasks:
    - name: Create containerd config file
      file:
        path: "/etc/modules-load.d/containerd.conf"
        state: "touch"

    - name: Add conf for containerd
      blockinfile:
        path: "/etc/modules-load.d/containerd.conf"
        block: |
              overlay
              br_netfilter

    - name: modprobe
      shell: |
              sudo modprobe overlay
              sudo modprobe br_netfilter


    - name: Set system configurations for Kubernetes networking
      file:
        path: "/etc/sysctl.d/99-kubernetes-cri.conf"
        state: "touch"

    - name: Add conf for containerd
      blockinfile:
        path: "/etc/sysctl.d/99-kubernetes-cri.conf"
        block: |
               net.bridge.bridge-nf-call-iptables = 1
               net.ipv4.ip_forward = 1
               net.bridge.bridge-nf-call-ip6tables = 1

    - name: Apply new settings
      command: sudo sysctl --system
    - name: Swap off
      shell: |
              sudo swapoff -a
              sudo sed -i '/swap/ s/^\(.*\)$/#\1/g' /etc/fstab
    - name: Update and upgrade apt packages
      apt:
        upgrade: no
        update_cache: yes
        cache_valid_time: 86400 #One day
  roles:
    - geerlingguy.containerd
    - geerlingguy.kubernetes
EOF
#Install ansible-role
sudo -H -u ubuntu bash -c 'ansible-galaxy install geerlingguy.containerd'
sudo -H -u ubuntu bash -c 'ansible-galaxy install geerlingguy.kubernetes'

#Edit role file to use k8s with containerd
##On master node file
line=("16" "25")
for n in "${line[@]}";
do
sed -i "${n}s/$/ --cri-socket \/run\/containerd\/containerd.sock/g" /home/ubuntu/.ansible/roles/geerlingguy.kubernetes/tasks/master-setup.yml
done

##On worker node file
sed -i "s/shell/command/g" /home/ubuntu/.ansible/roles/geerlingguy.kubernetes/tasks/node-setup.yml
sed -i "5s/$/ --cri-socket \/run\/containerd\/containerd.sock/g" /home/ubuntu/.ansible/roles/geerlingguy.kubernetes/tasks/node-setup.yml

#change permission
chown ubuntu:ubuntu /home/ubuntu/hosts
chown ubuntu:ubuntu /home/ubuntu/playbook.yaml
chown ubuntu:ubuntu /home/ubuntu/windows.pem
##Run playbook
sudo -H -u ubuntu bash -c 'ansible-playbook -i /home/ubuntu/hosts /home/ubuntu/playbook.yaml'

#Copy config file 
mkdir -p /home/ubuntu/.kube
cp /etc/kubernetes/admin.conf /home/ubuntu/.kube
mv /home/ubuntu/.kube/admin.conf  /home/ubuntu/.kube/config
sudo chown -R ubuntu:ubuntu /home/ubuntu/.kube