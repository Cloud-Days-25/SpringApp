variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Name of the application"
  type        = string
  default     = "spring-boot-app"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "production"
}

variable "app_count" {
  description = "Number of application containers to run"
  type        = number
  default     = 1
}

variable "container_port" {
  description = "Port the container exposes"
  type        = number
  default     = 8080
}

variable "container_cpu" {
  description = "CPU units for the container (1024 = 1 vCPU)"
  type        = number
  default     = 512
}

variable "container_memory" {
  description = "Memory for the container in MiB"
  type        = number
  default     = 1024
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {
    Project     = "SpringBootApp"
    Environment = "Test"
    ManagedBy   = "Terraform"
  }
}

variable "alarm_email" {
description = "Billing alarm email"
  type        = string
  default     = "marianferenc59@gmail.com"
}
