#!/bin/bash
set -euxo pipefail

# --- basic setup ---
yum update -y
yum install -y docker
systemctl enable docker
systemctl start docker

# --- run the backend service ---
# Replace this with your real deploy step (docker login to ECR/GHCR first if private image)
docker pull ${docker_image}
docker run -d \
  --name backend-service \
  --restart unless-stopped \
  -p ${app_port}:${app_port} \
  -e ENVIRONMENT=${environment} \
  ${docker_image}
