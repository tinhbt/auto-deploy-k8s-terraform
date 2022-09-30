# output "worker_ip" {
#   value = aws_instance.worker["k8s-worker1"].private_ip
# #   value = { for k, v in aws_instance.worker : k => v.private_ip }
# }