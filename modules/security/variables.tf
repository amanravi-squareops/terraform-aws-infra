variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "app_port" {
  description = "Port the backend service listens on"
  type        = number
  default     = 8080
}

variable "ssh_allowed_cidrs" {
  description = "CIDRs allowed to SSH into instances (empty list = no SSH access opened, use SSM instead)"
  type        = list(string)
  default     = []
}
