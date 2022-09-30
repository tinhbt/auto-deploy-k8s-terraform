#!/bin/bash
cd k8s-worker
terraform init
terraform apply -auto-approve

ip_worker1=$(grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])' terraform.tfstate | awk 'NR==1{print $1}')

echo $ip_worker1 
cd ../k8s-manager
sed -i "s/ip_worker/$ip_worker1/" init-k8s.sh

cat init-k8s.sh | grep worker1

terraform init
terraform apply -auto-approve
