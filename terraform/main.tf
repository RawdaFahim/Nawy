# AWS Provider Setup
provider "aws" {
  region = var.aws_region  # Ensure this variable is set correctly
}

# Reference the Default VPC
data "aws_vpc" "default_vpc" {
  default = true
}

# Reference the Default Public Subnet
data "aws_subnet" "default_public_subnet" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default_vpc.id]
  }

  filter {
    name   = "availabilityZone"
    values = [var.aws_az]  
  }

  filter {
    name   = "mapPublicIpOnLaunch"
    values = ["true"]
  }
}

# Security Group to allow inbound traffic on port 3000
resource "aws_security_group" "web_app_sg" {
  vpc_id = data.aws_vpc.default_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow traffic from anywhere
  }
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      },
    ]
  })
}

# ECS Cluster Setup
resource "aws_ecs_cluster" "web_app_cluster" {
  name = "web-app-cluster"
}

resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/web-app-cluster"
  retention_in_days = 7  # Optional: Adjust the retention period as needed
}

# IAM Role for ECS Task Execution
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect    = "Allow"
        Sid       = ""
      },
    ]
  })
}

resource "aws_iam_role_policy" "ecs_task_execution_policy" {
  name = "ecsTaskExecutionPolicy"
  role = aws_iam_role.ecs_task_execution_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetRepositoryPolicy",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

# ECS Task Definition (Fargate) Setup
resource "aws_ecs_task_definition" "web_app_task" {
  family                   = "web-app-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn  

  container_definitions = jsonencode([{
    name      = "web-app-container"
    image     = var.docker_image
    cpu       = 256
    memory    = 512
    essential = true
    portMappings = [
      {
        containerPort = 3000
        protocol      = "tcp"
      }
    ]
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"       = "/ecs/web-app-cluster"
        "awslogs-region"      = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# ECS Service Setup (Fargate)
resource "aws_ecs_service" "web_app_service" {
  name            = "web-app-service"
  cluster         = aws_ecs_cluster.web_app_cluster.id
  task_definition = aws_ecs_task_definition.web_app_task.arn  # Use the full ARN

  desired_count   = 1  # One task for now

  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [data.aws_subnet.default_public_subnet.id]  # Public subnet
    security_groups = [aws_security_group.web_app_sg.id]  # Security group allowing port 3000
    assign_public_ip = true  # Assign public IP to the Fargate task for external access
  }
  enable_execute_command = true

  depends_on = [
    aws_ecs_cluster.web_app_cluster,
    aws_ecs_task_definition.web_app_task
  ]
}

# Output the ECS service URL (public IP)
output "ecs_service_url" {
  value = aws_ecs_service.web_app_service.network_configuration[0].assign_public_ip
}
