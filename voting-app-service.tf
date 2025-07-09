# Data source to get the ECR repository information
data "aws_ecr_repository" "voting_app" {
  name = aws_ecr_repository.voting_app.name
}

# Data source to get the latest image from ECR
data "aws_ecr_image" "voting_app_latest" {
  repository_name = data.aws_ecr_repository.voting_app.name
  image_tag       = "latest"
}

# Create a dedicated target group for the voting-app service
resource "aws_lb_target_group" "voting_app" {
  name     = "voting-app-tg"
  port     = 8080
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  target_type = "ip"

  health_check {
    enabled             = true
    healthy_threshold   = 2
    interval            = 30
    matcher             = "200"
    path                = "/"
    port                = "traffic-port"
    protocol            = "HTTP"
    timeout             = 5
    unhealthy_threshold = 3
  }

  tags = {
    Name        = "voting-app-tg"
    Environment = var.environment
    Project     = var.project_name
    Service     = "voting-app"
    ManagedBy   = "terraform"
  }
}

# Create a listener rule to route traffic to the voting-app target group
resource "aws_lb_listener_rule" "voting_app" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.voting_app.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }

  tags = {
    Name        = "voting-app-listener-rule"
    Environment = var.environment
    Project     = var.project_name
    Service     = "voting-app"
    ManagedBy   = "terraform"
  }
}

# Deploy the voting-app service using the ecs-service module
module "voting_app_service" {
  source = "./modules/ecs-service"

  # Service configuration
  service_name    = "voting-app"
  cluster_id      = aws_ecs_cluster.main.id
  desired_count   = 2

  # Container configuration
  container_name = "voting-app"
  container_port = 8080
  image_uri      = "${data.aws_ecr_repository.voting_app.repository_url}:latest"

  # Resource allocation
  cpu    = 512
  memory = 1024

  # Network configuration
  subnet_ids         = aws_subnet.private[*].id
  security_group_ids = [aws_security_group.ecs_tasks.id]

  # Load balancer integration
  target_group_arn = aws_lb_target_group.voting_app.arn

  # IAM roles
  task_execution_role_arn = aws_iam_role.ecs_task_execution.arn
  task_role_arn          = aws_iam_role.ecs_task.arn

  # Auto scaling configuration
  enable_autoscaling = true
  min_capacity      = 1
  max_capacity      = 5
  cpu_target_value  = 70
  memory_target_value = 80

  # Environment variables
  environment_variables = [
    {
      name  = "APP_ENV"
      value = var.environment
    },
    {
      name  = "APP_NAME"
      value = "voting-app"
    },
    {
      name  = "PORT"
      value = "8080"
    }
  ]

  # Logging configuration
  log_retention_days = var.log_retention_days

  # Health check configuration
  health_check_path    = "/"
  health_check_matcher = "200"

  # Tags
  environment  = var.environment
  project_name = var.project_name
}