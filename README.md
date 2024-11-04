This repository contains Terraform code to deploy a secure, highly available, and scalable infrastructure for an application on AWS. It provisions a Virtual Private Cloud (VPC), subnets, NAT gateways, security groups, application load balancer, auto-scaling groups, and related resources.

Table of Contents
Overview
Architecture
Prerequisites
Getting Started
Usage
Resources Created
Security Considerations
Troubleshooting

Overview
This Terraform configuration deploys a web application in a secure, scalable manner using AWS resources. It includes a VPC with public and private subnets across multiple availability zones (AZs) to ensure high availability. The application is fronted by an Application Load Balancer (ALB) and automatically scales using Auto Scaling Groups (ASGs).

Architecture
The infrastructure includes the following components:

VPC with public and private subnets across two availability zones.
NAT Gateways for outbound internet access in private subnets.
Application Load Balancer (ALB) for routing traffic to the application instances.
Auto Scaling Groups (ASG) for horizontal scaling based on application load.
EC2 Instances launched using a Launch Template, configured to host the application.
Security Groups for controlled access to resources.

Prerequisites
AWS Account with permissions to create resources.
Terraform CLI version 1.0 or higher.
AWS CLI (optional but recommended for initial setup and verification).
Before running this configuration, set up your AWS credentials. Terraform will use them to deploy resources on AWS.

Getting Started
Clone the repository:
git clone https://github.com/Rohit-Chavan29/Terraform_Secure_Scalable_Infra.git

cd Terraform_Secure_Scalable_Infra
Set up AWS credentials:

You can configure AWS credentials using the aws configure command or by setting AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY as environment variables.

Initialize Terraform:

terraform init

Plan the infrastructure:
terraform plan

This will show the resources that Terraform will create.

Apply the configuration:

terraform apply
Type yes when prompted to confirm.

Usage
The infrastructure is set up with the following defaults, which can be modified in main.tf or other resource files as needed:

Region: ap-south-1
Instance Type: t2.micro
Key Pair: Update with your own key pair to allow SSH access.
After deploying, you can access the application via the load balancer's DNS name, which is outputted after a successful deployment.

Resources Created
This Terraform configuration creates the following resources:

VPC with CIDR 10.0.0.0/16.
Subnets:
Public subnets for ALB and NAT gateways.
Private subnets for application instances.
NAT Gateways in each public subnet.
Internet Gateway for public subnet internet access.
Route Tables for managing traffic routing.
Security Groups for application and database access.
Application Load Balancer (ALB) for traffic distribution.
Auto Scaling Groups (ASG) for scaling EC2 instances.
Launch Template for instance configuration.
Elastic IPs (EIPs) for NAT Gateways.
Security Considerations
NAT Gateway is used to secure private instances while allowing them to access the internet.
Security Groups restrict access to only necessary ports (e.g., 80 for HTTP, 22 for SSH).
IAM Permissions: Make sure that only limited users have access to deploy this infrastructure, as it can modify sensitive network configurations.
Sensitive files, such as terraform.tfstate and .terraform/, are ignored in .gitignore to prevent accidental exposure.
Troubleshooting
Authentication Errors: Ensure that AWS credentials are correctly configured.
Permissions: Verify that your AWS IAM role has permission to create the necessary resources.
Resource Limits: Make sure you have not hit any AWS resource limits (e.g., EC2 instance limits).
