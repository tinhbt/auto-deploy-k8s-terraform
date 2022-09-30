# module "vpc" {
#   source = "terraform-aws-modules/vpc/aws"

#   name = "vworkspace"
#   cidr = "10.0.0.0/16"

#   azs             = ["ap-southeast-1a", "ap-southeast-1b"]
#   private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
#   public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

#   enable_nat_gateway = false
#   enable_vpn_gateway = false

#   tags = {
#     Name = "vworkspace"
#   }
# }
# module "security-group-test" {
#   source = "terraform-aws-modules/security-group/aws"
#   name = "test-terraform"
#   description = "allow all traffic"
#   vpc_id = module.vpc.vpc_id

# }
# resource "aws_spot_instance_request" "test-vworkspace" {

#   for_each = toset(["APP-Instance", "DB-Instance"])
#   # name = each.key
#   ami                  = "ami-04ff9e9b51c1f62ca"
#   spot_type            = "one-time"
#   instance_type        = "t2.medium"
#   # subnet_id            = module.vpc.public_subnets[0]
#   key_name             = "windows"
#   tags = {
#     "Name" = each.key
#   }
#   user_data = file("init.sh")
# }

resource "aws_instance" "worker" {

  for_each = toset(["k8s-worker1"])
  launch_template {
    id      = "lt-017a1f9eab9eafa42"
    version = "1"
  }
  # user_data = file("init-docker.sh")
  tags = {
    "Name" = each.key
  }
}
