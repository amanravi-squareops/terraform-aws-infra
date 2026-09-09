aws_region   = "ap-south-1"
project_name = "myapp"
environment  = "dev"

vpc_cidr             = "10.0.0.0/16"
azs                  = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs  = ["10.0.0.0/24", "10.0.1.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

app_port      = 8080
docker_image  = "ghcr.io/your-org/backend:latest"
instance_type = "t3.micro"

min_size         = 1
max_size         = 2
desired_capacity = 1
