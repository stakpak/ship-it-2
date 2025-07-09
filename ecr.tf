# ECR Repository for voting-app
resource "aws_ecr_repository" "voting_app" {
  name                 = "voting-app"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "voting-app"
    Environment = "production"
    Project     = "voting-system"
    ManagedBy   = "terraform"
  }
}

# ECR Repository Policy to allow public read access
resource "aws_ecr_repository_policy" "voting_app_policy" {
  repository = aws_ecr_repository.voting_app.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowPublicPull"
        Effect = "Allow"
        Principal = "*"
        Action = [
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:BatchCheckLayerAvailability"
        ]
      }
    ]
  })
}

# Output the repository URL for reference
output "ecr_repository_url" {
  description = "URL of the ECR repository"
  value       = aws_ecr_repository.voting_app.repository_url
}

output "ecr_repository_arn" {
  description = "ARN of the ECR repository"
  value       = aws_ecr_repository.voting_app.arn
}