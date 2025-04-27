# Cloud Days 25 - Spring Boot  Ap Deployment to AWS Fargate
This repository contains a Spring Boot application that is automatically deployed to AWS Fargate using GitHub Actions and Terraform for infrastructure as code.

## Architecture Overview

The application is deployed using the following AWS services:

- **Amazon ECR**: Stores the containerized application
- **AWS Fargate**: Runs the containers without server management
- **Amazon ECS**: Orchestrates the containers
- **Application Load Balancer**: Routes traffic to the application
- **VPC with public and private subnets**: Provides networking isolation
- **CloudWatch Logs**: Collects application logs

## Directory Structure

```
├── .github/
│   └── workflows/
│       └── deploy.yml     # GitHub Actions workflow for CI/CD
├── terraform/
│   ├── main.tf            # Main Terraform configuration
│   ├── variables.tf       # Variable definitions
│   ├── outputs.tf         # Output definitions
│   └── backend.tf         # Terraform state configuration
├── src/                   # Spring Boot application source code
├── Dockerfile             # Docker image definition
├── .dockerignore          # Files to exclude from Docker builds
├── build.gradle           # Gradle build configuration
├── settings.gradle        # Gradle settings
└── README.md              # This file
```

## Prerequisites

- AWS Account with appropriate permissions
- AWS credentials stored as GitHub secrets

## Initial Setup

### 1. Configure AWS Credentials

Store your AWS credentials as GitHub repository secrets:

- `AWS_ACCESS_KEY_ID`: Your AWS access key
- `AWS_SECRET_ACCESS_KEY`: Your AWS secret access key

These credentials should have permissions to:

- Create and manage ECR repositories
- Create and manage ECS clusters and services
- Create and manage IAM roles and policies
- Create and manage VPC resources
- Create and manage Load Balancers
- Create and manage CloudWatch logs

### 2. S3 Backend Setup (Optional but Recommended)

For the Terraform S3 backend, create an S3 bucket and DynamoDB table manually:

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket terraform-state-spring-boot-app \
  --region us-east-1

# Enable bucket versioning
aws s3api put-bucket-versioning \
  --bucket terraform-state-spring-boot-app \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

Alternatively, comment out the backend configuration in `terraform/backend.tf` for the first run, and Terraform will use local state.

### 3. Update Configuration

Review and update:

- Environment variables in `.github/workflows/deploy.yml`
- Default values in `terraform/variables.tf`

## Deployment Process

The CI/CD pipeline runs automatically when code is pushed to the main branch:

1. **Infrastructure Provisioning**: 
   - Terraform creates or updates AWS resources

2. **Application Build**:
   - Java application is built with Gradle
   - Docker image is created

3. **Container Publishing**:
   - Image is pushed to Amazon ECR

4. **Deployment**:
   - ECS task definition is updated
   - New containers are deployed to Fargate
   - Old containers are decommissioned

## Monitoring and Logging

- **CloudWatch**: Application logs are sent to CloudWatch
- **Health Checks**: Spring Boot actuator health endpoints are used for container health monitoring

## Local Development

### Access SwaggerUI
Open in your browser:

http://localhost:8080/swagger-ui/index.html

### Access via Curl
Execute in your terminal:

    curl -X 'GET' \
    'http://localhost:8080/rest/app/demo/v1/{name}?name=Marian' \
    -H 'accept: application/json'


### Building the application locally

```bash
./gradlew build
```

### Running with Docker locally

```bash
docker build -t spring-boot-app .
docker run -p 8080:8080 spring-boot-app
```

## Cleanup

To destroy all resources created by Terraform:

```bash
cd terraform
terraform destroy
```
