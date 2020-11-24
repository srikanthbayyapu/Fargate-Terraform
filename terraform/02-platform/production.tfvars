# remote state
remote_state_key    = "prd/infrastructure.tfstate"
remote_state_bucket = "ecs.fargate.terraform.remote.state3"

ecs_cluster_name     = "Production-ECS-Cluster"
internet_cidr_blocks = "0.0.0.0/0"
