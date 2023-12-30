# DevOps Usecase for Numeracle
This repository contains three components:
- Java springboot source code from https://start.spring.io/
- Dockerfile to build the docker image of the demo application
- Terraform code to build the infrastructure and deploy demo application
- Jenkins pipeline to manage the whole flow

## How to use:
### Pre-requisite:
The build and deployment process is managed using Jenkins pipeline. 
Hence a Jenkins installation is required to use this.
Below configurations are needed to run the jenkins pipeline:
- Plugins:
  - [AWS Credentials Plugin](https://plugins.jenkins.io/aws-credentials)
  - [Pipeline](https://plugins.jenkins.io/workflow-aggregator)
  - [Pipeline - SCM step](https://plugins.jenkins.io/workflow-scm-step)
  - [Pipeline - AWS Steps](https://plugins.jenkins.io/pipeline-aws)
- Agent with below tools:
  - Java 17
  - Git
  - Docker
  - Terraform
- Access/Credentials:
  - AWS access with power user permission
  - Dockerhub login credential
 
### Steps to use:
- Create a Jenkins pipeline job using the [Jenkinsfile](https://github.com/bmohanty6/numeracle-task/blob/main/Jenkinsfile)
- Trigger the pipeline.
- After terraform pla stage, review the planned changes and approve to proceed for next step(apply)
- After terraform apply is complete, take the DNS name of AWS load balancer from build output
- Open the URL in browser.

### AWS components created via terraform:
- A new VPC with CIDR - 10.0.0.0/16
- 3 Public and 3 private subnets
- An EKS cluster with a node group deployed on private subnets
- Cloudwatch logs enabled for EKS cluster
- A namespace called `numeracle` is created with below resources
  - A deployment for the demo application with one replicaset and one pod
  - A loadbalancer srvice that creates a AWS loadbalancer in public subnet
- A cloudwatch Synthetics canary to monitor the demo application URL
- An S3 bucket to store the artifacts of Canary.
