variable "region" {
  default = "us-east-1"
}

variable "remote_state_key" {
}

variable "remote_state_bucket" {
}

#application variables for task
variable "nginx_app_name" {
  description = "Name of Application Container"
  default     = "nginx"
}
variable "nginx_app_image" {
  description = "Docker image to run in the ECS cluster"
  default     = "922079431449.dkr.ecr.us-east-1.amazonaws.com/react:latest"
}
variable "nginx_app_port" {
  description = "Port exposed by the Docker image to redirect traffic to"
  default     = 80
}
variable "nginx_app_count" {
  description = "Number of Docker containers to run"
  default     = 1
}
variable "nginx_fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default     = "256"
}
variable "nginx_fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default     = "512"
}

variable "desired_task_number" {
}
