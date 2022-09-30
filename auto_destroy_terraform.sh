#!/bin/bash
## Re-assign variable
ip_worker1=$(grep -oE '((1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])\.){3}(1?[0-9][0-9]?|2[0-4][0-9]|25[0-5])' k8s-worker/terraform.tfstate | awk 'NR==1{print $1}')
sed -i "s/$ip_worker1/ip_worker/g" k8s-manager/init-k8s.sh

cd k8s-manager

terraform destroy -auto-approve

cd ../k8s-worker

terraform destroy -auto-approve

