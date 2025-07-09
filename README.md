# Voting System Infrastructure

A production-ready AWS infrastructure deployment for a containerized voting application using Terraform, ECS Fargate, and Application Load Balancer.

## Architecture Overview

This project deploys a scalable, highly available voting system on AWS with the following components:

- **VPC**: Custom VPC with public and private subnets across multiple AZs
- **ECS Fargate**: Serverless container orchestration for the voting application
- **Application Load Balancer**: HTTP/HTTPS load balancing with health checks
- **ECR**: Private container registry for application images
- **Auto Scaling**: CPU and memory-based auto scaling (1-5 instances)
- **CloudWatch**: Centralized logging and monitoring
- **NAT Gateways**: Secure outbound internet access for private subnets

### Network Architecture

```
Internet Gateway
       |
   Public Subnets (2 AZs)
  /                    \
ALB                  NAT Gateways
 |                        |
 |                 Private Subnets (2 AZs)
 |                        |
 +----> ECS Fargate Tasks <----+
```

**Traffic Flow:**
- **Inbound**: Internet → Internet Gateway → ALB (Public Subnets) → ECS Tasks (Private Subnets)
- **Outbound**: ECS Tasks → NAT Gateway (Public Subnets) → Internet Gateway → Internet

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform >= 1.0
- Docker (for building and pushing container images)
- An existing container image in ECR or ability to push one

### Required AWS Permissions

The deployment requires permissions for:
- VPC, Subnet, Route Table, Internet Gateway, NAT Gateway management
- ECS Cluster, Service, Task Definition management
- ECR Repository management
- Application Load Balancer management
- IAM Role and Policy management
- CloudWatch Logs management
- Auto Scaling management

## Quick Start

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd ship-it-2
   ```

2. **Configure variables** (optional)
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your desired values
   ```

3. **Initialize Terraform**
   ```bash
   terraform init
   ```

4. **Plan the deployment**
   ```bash
   terraform plan
   ```

5. **Deploy the infrastructure**
   ```bash
   terraform apply
   ```

6. **Push your application image to ECR**
   ```bash
   # Get ECR login token
   aws ecr get-login-password --region eu-north-1 | docker login --username AWS --password-stdin <account-id>.dkr.ecr.eu-north-1.amazonaws.com

   # Build and tag your image
   docker build -t voting-app .
   docker tag voting-app:latest <ecr-repository-url>:latest

   # Push to ECR
   docker push <ecr-repository-url>:latest
   ```

## Configuration

### Variables

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `environment` | Environment name (dev, staging, prod) | `production` | No |
| `project_name` | Name of the project | `voting-system` | No |
| `vpc_cidr` | CIDR block for the VPC | `10.0.0.0/16` | No |
| `availability_zones` | List of availability zones | `["eu-north-1a", "eu-north-1b"]` | No |
| `public_subnet_cidrs` | CIDR blocks for public subnets | `["10.0.1.0/24", "10.0.2.0/24"]` | No |
| `private_subnet_cidrs` | CIDR blocks for private subnets | `["10.0.10.0/24", "10.0.20.0/24"]` | No |
| `cluster_name` | Name of the ECS cluster | `main-cluster` | No |
| `log_retention_days` | CloudWatch log retention in days | `7` | No |

### Application Configuration

The voting application is configured with the following defaults:
- **Port**: 8080
- **CPU**: 512 units (0.5 vCPU)
- **Memory**: 1024 MB (1 GB)
- **Desired Count**: 2 instances
- **Auto Scaling**: 1-5 instances based on CPU (70%) and Memory (80%) utilization

## Outputs

After successful deployment, Terraform provides the following outputs:

| Output | Description |
|--------|-------------|
| `alb_dns_name` | DNS name of the Application Load Balancer |
| `ecr_repository_url` | URL of the ECR repository |
| `ecs_cluster_name` | Name of the ECS cluster |
| `vpc_id` | ID of the created VPC |

Access your application at: `http://<alb_dns_name>`

## Module Structure

```
.
├── ecr.tf                    # ECR repository configuration
├── ecs-cluster.tf           # VPC, ALB, ECS cluster, and IAM roles
├── voting-app-service.tf    # Voting app service deployment
├── variables.tf             # Input variables
├── outputs.tf              # Output values
└── modules/
    └── ecs-service/        # Reusable ECS service module
        ├── main.tf         # ECS service, task definition, auto scaling
        ├── variables.tf    # Module variables
        └── outputs.tf      # Module outputs
```

## Monitoring and Operations

### CloudWatch Logs
- ECS cluster logs: `/aws/ecs/main-cluster`
- Application logs: `/aws/ecs/voting-app`

### Health Checks
- **ALB Health Check**: HTTP GET on `/` (port 8080)
- **Health Check Interval**: 30 seconds
- **Healthy Threshold**: 2 consecutive successes
- **Unhealthy Threshold**: 3 consecutive failures

### Auto Scaling
- **CPU Target**: 70% utilization
- **Memory Target**: 80% utilization
- **Scale Out**: Add instances when thresholds exceeded
- **Scale In**: Remove instances when utilization drops

## Security Features

- **Private Subnets**: Application runs in private subnets with no direct internet access
- **Security Groups**: Restrictive ingress rules (ALB → ECS tasks only)
- **IAM Roles**: Least privilege access for ECS tasks
- **ECR Image Scanning**: Automatic vulnerability scanning on push
- **VPC Flow Logs**: Network traffic monitoring (can be enabled)

## Cost Optimization

- **Fargate Spot**: Consider using Fargate Spot for non-production workloads
- **Right-sizing**: Monitor CPU/memory utilization and adjust task resources
- **Log Retention**: Configured for 7 days (adjustable via `log_retention_days`)
- **NAT Gateway**: Consider NAT instances for lower-cost environments

## Troubleshooting

### Common Issues

1. **Service fails to start**
   - Check CloudWatch logs: `/aws/ecs/voting-app`
   - Verify ECR image exists and is accessible
   - Check security group rules

2. **Health check failures**
   - Verify application responds on port 8080 at path `/`
   - Check application startup time vs health check timeout

3. **Auto scaling not working**
   - Verify CloudWatch metrics are being published
   - Check auto scaling policies and thresholds

### Useful Commands

```bash
# Check ECS service status
aws ecs describe-services --cluster main-cluster --services voting-app

# View recent logs
aws logs tail /aws/ecs/voting-app --follow

# Check ALB target health
aws elbv2 describe-target-health --target-group-arn <target-group-arn>
```

## Cleanup

To destroy all resources:

```bash
terraform destroy
```

**Warning**: This will permanently delete all resources including the ECR repository and any stored images.

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.
