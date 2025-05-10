# Variables
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}
variable "aws_az" {
  description = "AZ to deploy resources"
  type        = string
  default     = "us-east-1a"
}

variable "docker_image" {
  description = "Docker image URL for the web application"
  type        = string
  default   = "docker.io/rawda123/node-hello:latest"
}
