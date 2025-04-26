provider "aws" {
  region = var.region
}

data "aws_availability_zones" "available" {}

locals {
  public_subnets = {
    "subnet-public-az1" = {
      cidr_block        = "10.0.10.0/24"
      availability_zone = data.aws_availability_zones.available.names[0]
    }
    "subnet-public-az2" = {
      cidr_block        = "10.0.11.0/24"
      availability_zone = data.aws_availability_zones.available.names[1]
    }
    "subnet-public-az3" = {
      cidr_block        = "10.0.12.0/24"
      availability_zone = data.aws_availability_zones.available.names[2]
    }
  }

  private_subnets = {
    "subnet-private-az1" = {
      cidr_block        = "10.0.110.0/24"
      availability_zone = data.aws_availability_zones.available.names[0]
    }
    "subnet-private-az2" = {
      cidr_block        = "10.0.111.0/24"
      availability_zone = data.aws_availability_zones.available.names[1]
    }
    "subnet-private-az3" = {
      cidr_block        = "10.0.112.0/24"
      availability_zone = data.aws_availability_zones.available.names[2]
    }
  }
}

# ============================
# VPC, Subnets, IGW, Route Tables
# ============================
resource "aws_vpc" "app_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.app_vpc.id
}

resource "aws_subnet" "public_subnets" {
  for_each = local.public_subnets

  vpc_id                  = aws_vpc.app_vpc.id
  cidr_block              = each.value.cidr_block
  availability_zone       = each.value.availability_zone
  map_public_ip_on_launch = true

  tags = {
    Name = each.key
  }
}

resource "aws_subnet" "private_subnets" {
  for_each = local.private_subnets

  vpc_id            = aws_vpc.app_vpc.id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone

  tags = {
    Name = each.key
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "public_assoc" {
  for_each = aws_subnet.public_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_route_table.id
}

# ============================
# NAT Gateway Setup (For Private Subnets)
# ============================
resource "aws_eip" "nat_eip" {
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnets["subnet-public-az1"].id
}

resource "aws_route_table" "private_route_table" {
  vpc_id = aws_vpc.app_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }
}

resource "aws_route_table_association" "private_assoc" {
  for_each = aws_subnet.private_subnets

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_route_table.id
}

# ============================
# Security Groups
# ============================
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = aws_vpc.app_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ecs_service_sg" {
  name   = "ecs-service-sg"
  vpc_id = aws_vpc.app_vpc.id

  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# ============================
# Load Balancer + Target Group
# ============================
resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = [for subnet in aws_subnet.public_subnets : subnet.id]

  enable_deletion_protection = false

  tags = {
    Name = "app-alb"
  }
}

resource "aws_lb_target_group" "app_tg" {
  name        = "app-tg"
  port        = 8080 # A porta do contêiner
  protocol    = "HTTP"
  vpc_id      = aws_vpc.app_vpc.id
  target_type = "ip"
  health_check {
    path                = "/"
    matcher             = "200"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80 # O ALB escuta na porta 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.app_tg.arn
  }
}

# ============================
# ECS Cluster
# ============================
resource "aws_ecs_cluster" "app_cluster" {
  name = "app-cluster"
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "ecs-tasks.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_task_execution_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Adicionar política para permitir acesso ao ECR
resource "aws_iam_role_policy_attachment" "ecs_ecr_access_attach" {
  role       = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# ============================
# ECS Task Definition
# ============================
resource "aws_ecs_task_definition" "app_task" {
  family                   = "app-task"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_execution_role.arn
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([{
    name      = "app"
    image     = "443370689665.dkr.ecr.us-east-1.amazonaws.com/jpmoraess:2ec51973e9713d2085bc1a22d0ea2e0dda119268"
    essential = true
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
      protocol      = "tcp"
    }]
    health_check = {
      command     = ["CMD-SHELL", "curl -f http://localhost:8080/actuator/health/ || exit 1"]
      interval    = 30
      timeout     = 5
      retries     = 3
      start_period = 0
    }
  }])
}

# ============================
# ECS Service
# ============================
resource "aws_ecs_service" "app_service" {
  name            = "app-service"
  cluster         = aws_ecs_cluster.app_cluster.id
  desired_count   = 1
  launch_type     = "FARGATE"
  task_definition = aws_ecs_task_definition.app_task.arn

  network_configuration {
    subnets          = [for subnet in aws_subnet.private_subnets : subnet.id]
    security_groups  = [aws_security_group.ecs_service_sg.id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.app_tg.arn
    container_name   = "app"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http_listener]
}
