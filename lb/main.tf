terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region
}

resource "aws_security_group" "jpmoraess_security_group_lb" {
  name = "jpmoraess_security_group_lb"
  description = "allow TLS inbound traffic"
  vpc_id = var.vpc_id
  tags = {
    Name = "lb security group"
  }
  ingress = [ {
    description = ""
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
    from_port = 443
    to_port = 443
    protocol = "tcp"
    self = true
    cidr_blocks = [ "0.0.0.0/0" ]
  },
  {
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
    description = ""
    from_port = 80
    protocol = "tcp"
    self = true
    to_port = 80
  } ]
  egress = [ {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = ""
    from_port = 0
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    protocol = "-1"
    security_groups = []
    self = false
    to_port = 0
  } ]
}

resource "aws_lb" "jpmoraess_lb" {
  name = "jpmoraess-lb"
  internal = false
  load_balancer_type = "application"
  security_groups = [ aws_security_group.jpmoraess_security_group_lb.id ]
  subnets = [var.subnets[0], var.subnets[1]]
  tags = {
    "loadbalancer" = "PRD"
  }
}

resource "aws_lb_target_group" "jpmoraess_target_group" {
  name = "jpmoraess-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id
}

resource "aws_lb_target_group_attachment" "jpmoraess_target_group_attachment" {
  target_id = var.instance_id
  port = 80
  target_group_arn = aws_lb_target_group.jpmoraess_target_group.arn
}

resource "aws_lb_listener" "jpmoraess_front_end" {
  load_balancer_arn = aws_lb.jpmoraess_lb.arn
  port = 80
  protocol = "HTTP"
  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.jpmoraess_target_group.arn
  }
}
