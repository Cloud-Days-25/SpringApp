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

NOTE: Before doing any changes to this repository, fork it first!

## Prerequisites
- AWS Account with appropriate permissions
- AWS credentials stored as GitHub secrets

## Initial Setup

Before you can deploy your Spring Boot application to AWS using Terraform and GitHub Actions, you need to complete several prerequisite steps. This guide walks you through setting up all required resources and permissions.

## Install CLI tools:
 
- AWS v2 CLI - https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html#getting-started-install-instructions
- Git CLI

## 1. AWS Account Setup

### Create an AWS Account (if you don't have one)
1. Go to [AWS Console](https://aws.amazon.com/)
2. Click "Create an AWS Account" and follow the registration process
3. Set up Multi-Factor Authentication (MFA) for the root account for security
4. Apply Voucher - steps TODO

### Enable Billing Alerts
1. Log in to AWS Console with your root account
2. Go to your account name in the top right corner → "My Account"
3. Scroll to "Billing preferences" and check:
   - "Receive Billing Alerts"
   - "Receive PDF Invoice By Email"
4. Click "Save preferences"


### Create Your Admin User
Recommended to use for everything (except billing) instead of your root user.
Assign to new group: admins.
Set permission `AdministratorAccess` to group.

### Relogin using your admin user
Perform everything via this user.

### Create an IAM User for Deployment
1. Log in to AWS Console
2. Navigate to IAM (Identity and Access Management)
3. Create a new IAM user:
   ```
   Name: terraform-deployer
   Access type: Programmatic access
   Group: iac
   ```
4. Attach the following policies to group iac:
   - `AmazonECS_FullAccess`
   - `AmazonEC2ContainerRegistryFullAccess`
   - `AmazonVPCFullAccess`
   - `AmazonS3FullAccess` (for Terraform state)
   - `AmazonDynamoDBFullAccess` (for Terraform state locking)
   - `AmazonSNSFullAccess` (for billing alarms)
   - `CloudWatchFullAccess`
   - `IAMFullAccess`
   - `ElasticLoadBalancingFullAccess`

5. After creating the user, save the Access Key ID and Secret Access Key securely in GitHub and also download csv file with them.


## 2. Create S3 Bucket and DynamoDB Table for Terraform State

### Set Up S3 Bucket
```bash
# Login to AWS account using your ACCESS_KEY_ID and SECRET_KEY
aws configure

# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket terraform-state-spring-boot-app \
  --region us-east-1

# Enable bucket versioning
aws s3api put-bucket-versioning \
  --bucket terraform-state-spring-boot-app \
  --versioning-configuration Status=Enabled

# Enable default encryption
aws s3api put-bucket-encryption \
  --bucket terraform-state-spring-boot-app \
  --server-side-encryption-configuration '{
    "Rules": [
      {
        "ApplyServerSideEncryptionByDefault": {
          "SSEAlgorithm": "AES256"
        }
      }
    ]
  }'
```

### Set Up DynamoDB Table for State Locking
```bash
# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

## 3. Get the Latest ECS-Optimized AMI ID

```bash
# Get the latest ECS-optimized AMI ID for Amazon Linux 2
aws ssm get-parameters \
  --names /aws/service/ecs/optimized-ami/amazon-linux-2/recommended \
  --region us-east-1

# Look for the "image_id" in the output and use it in your variables.tf file
```

## 4. GitHub Repository Setup

### Create a New Repository
1. Go to [GitHub](https://github.com/)
2. Click "New" to create a new repository
3. Give it a name and description, choose visibility options
4. Initialize with a README if desired
5. Click "Create repository"

### Add AWS Credentials as Secrets
1. Go to your repository on GitHub
2. Click on "Settings" → "Secrets and variables" → "Actions"
3. Add the following secrets:
   - `AWS_ACCESS_KEY_ID`: Your IAM user's access key
   - `AWS_SECRET_ACCESS_KEY`: Your IAM user's secret key
   - `AWS_REGION`: Your preferred AWS region (e.g., `us-east-1`)

### Enable GitHub Actions
1. Click on the "Actions" tab in your repository
2. Confirm that you want to enable GitHub Actions

## 5. Clone Your Repository and Add Configuration Files

```bash
# Clone your repository
git clone https://github.com/yourusername/your-repo-name.git
cd your-repo-name

# Create necessary directories
mkdir -p .github/workflows
mkdir -p terraform

# Copy all the provided files from this guide into these directories
# (Terraform configs, GitHub Actions workflow, Docker file, etc.)

# Update variables.tf with your specific values
# - Update the AMI ID
# - Update the alarm email
# - Adjust any other variables as needed

# Commit and push your changes
git add .
git commit -m "Add deployment configuration"
git push origin main
```

## 6. Spring Boot Application Setup

Ensure your Spring Boot application:

1. Has proper health checks at `/actuator/health`
2. Uses environment variables for configuration
3. Can run as a non-root user (for security)
4. Has proper logging configuration

Add these dependencies to your build.gradle:

```gradle
implementation 'org.springframework.boot:spring-boot-starter-actuator'
implementation 'org.springframework.boot:spring-boot-starter-web'
```

## 7. Initial Deployment

1. Push your code to the main branch
2. Go to the "Actions" tab in your GitHub repository and trigger "Deploy Spring Boot App" action
3. Watch as your first deployment runs
4. Troubleshoot any issues by checking the workflow logs

## 8. Verify Setup 

After deployment, verify:

1. The application is running by visiting the ALB DNS name
2. Logs are being properly sent to CloudWatch
3. The billing alarm is properly configured
4. You received an email to confirm the SNS subscription for billing alerts

## 9. Cleanup When No Longer Needed

To avoid incurring any costs, you can destroy all resources when they're no longer needed:

```bash
cd terraform
terraform destroy
```

or you can trigger GitHub action called Terraform destroy manually, which will do the same thing.

### 10. Update Configuration if needed

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

