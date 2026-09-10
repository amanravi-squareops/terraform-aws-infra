variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "ec2_sg_id" {
  type = string
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "app_port" {
  type    = number
  default = 8080
}

variable "docker_image" {
  description = "Backend service image, e.g. ghcr.io/you/backend:latest or an ECR URI"
  type        = string
}

variable "min_size" {
  type    = number
  default = 1
}

variable "max_size" {
  type    = number
  default = 3
}

variable "desired_capacity" {
  type    = number
  default = 1
}

variable "key_name" {
  description = "EC2 key pair name for emergency SSH access (optional, leave null to skip)"
  type        = string
  default     = null
}

variable "app_data_bucket_arn" {
  description = "ARN of the S3 bucket the backend service is allowed to read/write"
  type        = string
}

variable "app_data_bucket_name" {
  description = "Name of the S3 bucket, passed into the container as an env var"
  type        = string
}

variable "aws_region" {
  description = "Region, passed into the container so its AWS SDK client knows where the bucket lives"
  type        = string
}
