# Network

This module aims to create the base network for the majority of AWS workloads.

In particular it deploys a VPC by either specifying the CIDR block or specifying an AWS Ipam pool and the network mask. Then, it extracts three subnets (with size specified in its inputs, one for each availability zone), creates public subnets, network interface, route tables, NAT gateway and a private hosted zone associated with the VPC.
