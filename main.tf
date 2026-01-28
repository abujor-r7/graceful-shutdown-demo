provider "aws" { 
  region = var.region 
}

data "aws_vpc" "selected" { 
  id = var.vpc_id 
}

data "aws_subnets" "selected" {
  filter { 
    name = "subnet-id"
    values = var.subnet_ids 
  }
}