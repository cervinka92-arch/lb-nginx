variable "aws_region" {
  description = "AWS region where resources are deployed"
  type        = string
  default     = "eu-central-1"
}

variable "project_name" {
  description = "Prefix used for resource names"
  type        = string
  default     = "ecs-nginx-demo"
}
