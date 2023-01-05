# Terraform Modules

This repo aims to be a registry of useful terraform modules.

It contains the following modules:

## Autoscaling

Deploys and autoscaling group and the launch template, configured to allow SSM into the instances, inside the given subnets. We allow all outbound to VPC, the outbound on port 443 to anything (for SSM to work) and we also allow inbound port 80 (as the associated load balancer will terminate TLS and forward the request using that port). The autoscaling will be placed behind the Load Balancer passed as input.

## Codepipeline

A fully working Codepipeline setup with the following stages:

- Source -> Getting triggered via a github push using codestart connection;
- Build -> CodeBuild container running unit and integration tests for the code;
- Deploy -> CodeDeploy associated with the autoscaling group which deploys the new revision on the instances. The deploy mechanism is IN PLACE with TRAFFIC CONTROL.

## Document Db

Deploys a cluster of DocumentDB in High Availability. There will be three instances, one will be the Controller for both reads and writes while the other twos are for read-only loads. The Security groups of these DB instances will allow inbound and outbound only to and from the Autoscaling Group's Security group.

## Ec2

This will contain the user data for the ec2 instances in the autoscaling group. At this point it will install and setup the following services:

- Nginx
- CloudWatch Agent
- CodeDeploy Agent
- MongoShell

## Loadbalancer

Deploys a Load Balancer, creating an health check target at `/status/health`, creating a CNAME and an ACM certificate to associate for TLS encryption.

## Network

Deploys a VPC using either the specified Cidr block of using an AWS IPAM. It creates 3 public subnets and 3 private subnets. Internet gateway for public subnets, NAT gateway for private subnets. It is also possible to let the module create a private hosted zone associated with the VPC.
