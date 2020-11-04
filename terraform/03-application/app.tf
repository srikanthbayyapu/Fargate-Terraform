provider "aws" {
  region  = var.region
  version = "~> 3.0"
  profile = "default"
}

terraform {
  backend "s3" {
    bucket = "ecs.fargate.terraform.remote.state1"
    key    = "prd/nginx.tfstate"
    region = "us-east-1"
  }
}

data "terraform_remote_state" "platform" {
  backend = "s3"

  config = {
    key    = var.remote_state_key
    bucket = var.remote_state_bucket
    region = var.region
  }
}

data "template_file" "nginx_app" {
  template = file("task_definition.json")

  vars = {
    app_name       = var.nginx_app_name
    app_image      = var.nginx_app_image
  }
}

resource "aws_ecs_task_definition" "nginx_app" {
  container_definitions    = data.template_file.nginx_app.rendered
  family                   = var.nginx_app_name
  cpu                      = var.nginx_fargate_cpu
  memory                   = var.nginx_fargate_memory
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = data.terraform_remote_state.platform.outputs.ecs_cluster_role_arn
  task_role_arn            = data.terraform_remote_state.platform.outputs.ecs_cluster_role_arn
}

resource "aws_security_group" "app_security_group" {
  name        = "${var.nginx_app_name}-SG"
  description = "Security group for nginx to communicate in and out"
  vpc_id      = data.terraform_remote_state.platform.outputs.vpc_id

  ingress {
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = [data.terraform_remote_state.platform.outputs.vpc_cidr_block]
  }

  ingress {
    from_port   = 80
    protocol    = "TCP"
    to_port     = 80
    cidr_blocks = ["49.207.203.108/32"]
  }

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.nginx_app_name}-SG"
  }
}

resource "aws_ecs_service" "ecs_service" {
  name            = var.nginx_app_name
  task_definition = var.nginx_app_name
  desired_count   = var.desired_task_number
  cluster         = data.terraform_remote_state.platform.outputs.ecs_cluster_name
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.terraform_remote_state.platform.outputs.ecs_public_subnets
    security_groups  = [aws_security_group.app_security_group.id]
    assign_public_ip = true
  }

  load_balancer {
    container_name   = var.nginx_app_name
    container_port   = var.nginx_app_port
    target_group_arn = data.terraform_remote_state.platform.outputs.ecs_alb_target_group
  }
}

resource "aws_cloudwatch_log_group" "nginxapp_log_group" {
  name = "${var.nginx_app_name}-LogGroup"
}

resource "aws_appautoscaling_target" "nginx_fargate_target" {
  max_capacity       = 3
  min_capacity       = 1
  resource_id        = "service/${data.terraform_remote_state.platform.outputs.ecs_cluster_name}/${aws_ecs_service.ecs_service.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "app_scaling" {
  name = "app_scaling"
  policy_type = "TargetTrackingScaling"
  resource_id = aws_appautoscaling_target.nginx_fargate_target.resource_id
  scalable_dimension = aws_appautoscaling_target.nginx_fargate_target.scalable_dimension
  service_namespace = aws_appautoscaling_target.nginx_fargate_target.service_namespace

  target_tracking_scaling_policy_configuration {
    predefined_metric_specification {
      predefined_metric_type = "ECSServiceAverageCPUUtilization"
    }

    target_value = 10
  }

  depends_on = [aws_appautoscaling_target.nginx_fargate_target]
}
