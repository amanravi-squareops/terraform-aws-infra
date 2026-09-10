variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "force_destroy" {
  description = "Allow bucket deletion even if it has objects (true for dev, false for prod)"
  type        = bool
  default     = false
}
