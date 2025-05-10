# AWS Provider Setup
# Configures the AWS provider with the region defined by the `aws_region` variable
provider "aws" {
  region = var.aws_region # Ensure this variable is set correctly
}

# Create a Private VPC
# This resource creates a Virtual Private Cloud (VPC) with DNS support and hostnames enabled
resource "aws_vpc" "private_vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create a Public Subnet
# Defines a public subnet within the VPC, which will automatically assign public IPs to instances
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.private_vpc.id
  cidr_block              = "10.0.1.0/24"  # Subnet range within the VPC
  availability_zone       = var.aws_az      # Availability zone defined by the `aws_az` variable
}

# Create an Internet Gateway
# This resource creates an internet gateway for the public subnet to communicate with the internet
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.private_vpc.id
}

# Create a Route Table for the Public Subnet
# Defines the routing rules for the public subnet, allowing traffic to flow to/from the internet
resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.private_vpc.id

  route {
    cidr_block = "0.0.0.0/0"  # Default route to all destinations
    gateway_id = aws_internet_gateway.internet_gateway.id  # Directs traffic to the internet gateway
  }
}

# Associate the Public Route Table with the Public Subnet
# This resource associates the public route table with the public subnet
resource "aws_route_table_association" "public_subnet_association" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

# Security Group to Allow Inbound Traffic on Port 3000
# Creates a security group that allows inbound traffic on port 3000 for the web application
resource "aws_security_group" "web_app_sg" {
  vpc_id = aws_vpc.private_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"  # Allows all outbound traffic
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 3000   # Allows traffic on port 3000 (web app)
    to_port     = 3000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allows traffic from any IP address
  }
}

# IAM Role for ECS Task Execution
# Creates an IAM role that ECS tasks can assume to perform actions on AWS resources
resource "aws_iam_role" "ecs_task_role" {
  name = "ecsTaskRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

# ECS Cluster Setup
# Creates an ECS cluster for running ECS tasks
resource "aws_ecs_cluster" "web_app_cluster" {
  name = "web-app-cluster"
}

# CloudWatch Log Group for ECS Tasks
# Creates a CloudWatch log group to capture logs from ECS tasks
resource "aws_cloudwatch_log_group" "ecs_log_group" {
  name              = "/ecs/web-app-cluster"
  retention_in_days = 7 # Retention period for log data 
}

# IAM Role for ECS Task Execution (Task Role)
# This role is for ECS tasks to interact with services 
resource "aws_iam_role" "ecs_task_execution_role" {
  name = "ecsTaskExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

# IAM Policy for ECS Task Execution
# Defines the policy that grants permissions for ECS tasks to interact with CloudWatch Logs
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
# Defines the ECS task, which uses Fargate for serverless compute
resource "aws_ecs_task_definition" "web_app_task" {
  family                   = "web-app-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"   # Allocating 256 CPU units for the task
  memory                   = "512"   # Allocating 512 MiB memory for the task
  execution_role_arn       = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name      = "web-app-container"
    image     = var.docker_image  # Docker image from a variable
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
        "awslogs-group"         = "/ecs/web-app-cluster"
        "awslogs-region"        = "us-east-1"
        "awslogs-stream-prefix" = "ecs"
      }
    }
  }])
}

# ECS Service Setup (Fargate)
# Defines the ECS service that manages the running tasks
resource "aws_ecs_service" "web_app_service" {
  name            = "web-app-service"
  cluster         = aws_ecs_cluster.web_app_cluster.id
  task_definition = aws_ecs_task_definition.web_app_task.arn # Use the full ARN

  desired_count = 1 # Start with one task

  launch_type = "FARGATE"

  network_configuration {
    subnets = [aws_subnet.public_subnet.id] # Public subnet
    security_groups  = [aws_security_group.web_app_sg.id] # Security group for port 3000
    assign_public_ip = true               # Assign a public IP for external access
  }
  enable_execute_command = true

  depends_on = [
    aws_ecs_cluster.web_app_cluster,
    aws_ecs_task_definition.web_app_task
  ]
}
