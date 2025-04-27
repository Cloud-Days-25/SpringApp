# Note: You need to create the S3 bucket and DynamoDB table manually before using this backend,
# or comment this out for the first run and create these resources with Terraform

terraform {
  backend "s3" {
    bucket         = "terraform-state-spring-boot-app"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
  
  required_version = ">= 1.0"
}
