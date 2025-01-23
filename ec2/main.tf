terraform {
  required_providers {
    aws = {
        source = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name = "name"
    values = [ "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" ]
  }

  filter {
    name = "virtualization-type"
    values = [ "hvm" ]
  }

  owners = [ "099720109477" ] #Canonical
}

resource "aws_security_group" "jpmoraess_security_group" {
  name = "jpmoraess_security_group"
  description = "Grupo configurado para fazer SSH e HTTP"
  tags = {
    "Ambiente" = "PRD"
  }
  ingress = [ {
    cidr_blocks = [ "0.0.0.0/0" ]
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
    description = ""
    from_port = 80
    protocol = "tcp"
    self = true
    to_port = 80
  },
  {
    cidr_blocks = [ "0.0.0.0/0" ]
    description = ""
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    security_groups = []
    from_port = 22
    to_port = 22
    protocol = "tcp"
    self = false
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

resource "aws_vpc" "jpmoraess_vpc" {
  cidr_block = "172.31.0.0/16"
}

resource "aws_subnet" "jpmoraess_subnet" {
  vpc_id = aws_vpc.jpmoraess_vpc.id
  cidr_block = "172.31.32.0/20"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true
}

resource "aws_key_pair" "jpmoraess_key_pair" {
  key_name = "jpmoraess_key_pair"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQChi2el+59NZGaJoQ5QKd0hs0rIv9o+GbD8JqBijmo6QvrmIR9hSu3MX+aoldGi55/0Eyxx9LmguqCLId8FHZSpPcg1xMjETySuRKqO97NeDJOysdFpPTovYyfcSlspCtPIRnabOFXK6FKczkTJd+H79v2I9vu/bmCD+TVxMFZkZFtBvi0fcGtZ8JI5tAU+7k3b4jBIgMuD0C2JiTJRjgkCvO2saCmVClqm+ryxg4EhOG6KFDO4fzn2efztIZzkeLap0yIMzJpcoC3+vkadGUR9fKWZPSbOWw6s+76Zl3/uDQ9634QfqjmFMbnB8Xo7Efk/gC7CpVlgbPpzxsiICMkH jpmoraess@Joaos-iMac-Pro"
}

resource "aws_instance" "jpmoraess_vm" {
  ami = data.aws_ami.ubuntu.id
  instance_type = "t3.micro"
  key_name = "jpmoraess_key_pair"
  vpc_security_group_ids = [ aws_security_group.jpmoraess_security_group.id ]
  #subnet_id = aws_subnet.jpmoraess_subnet.id
  connection {
    type = "ssh"
    user = "ec2-user"
    private_key = file("/Users/jpmoraess/.ssh/id_rsa")
    host = self.public_ip
  }
  root_block_device {
    volume_size = "20"
    volume_type = "standard"
    delete_on_termination = true
  }
}