# Terraform Modules

This repo aims to be a registry of useful terraform modules.

It contains the following modules:

## Autoscaling

Deploys an autoscaling group and the launch template, configured to allow SSM into the instances, inside the given subnets. We allow all outbound to VPC, the outbound on port 443 to anything (for SSM to work) and we also allow inbound port 80 (as the associated load balancer will terminate TLS and forward the request using that port). The autoscaling will be placed behind the Load Balancer passed as input.

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

# Run terraform commands on examples

## Pre-requisites

1. Check the `README.md` on the examples you wish to deploy to check how it works (in the `examples` folder);

1. The `Makefile` aims to contain userful targets to allow for an easy and fast deployment of the terraform code. In particular, the parameters that can be changed are:

   ```
   MODULE
   TERRAFORM_STATE_KEY
   SSM_PARAMETER_TERRAFORM_S3_BUCKET
   REGION
   TERRAFORM_VERSION
   ```

   The `REGION` parameter, if changed, should also be changed in the `provider.tf` of the terraform code.

   The SSM_PARAMETER_TERRAFORM_S3_BUCKET should contain an SSM parameter name which value is the S3 bucket containing the terraform statefiles. In fact, in the `Makefile` target `terraform/init`, there is a command to get the content of the parameter from AWS parameter store.

   Instead of getting the bucket name in this way, it could be just hard-coded in the `Makefile` like the TERRAFORM_STATE_KEY.

## Install Dependencies

There is a target, using the variable `TERRAFORM_VERSION`, which installs terraform (it downloads the zip, unzip it and move the binary to a path in PATH):

```sh
make install/terraform
```

## Deploy Terraform

By default, the `Makefile` will deploy the terraform code in `examples/complete`. In order to do that, just issue:

```sh
make terraform/init
```

And then

```sh
make terraform/plan
```

> Ensure that your AWS credentials are in your environment variables

Finally:

```sh
make terraform/apply
```
