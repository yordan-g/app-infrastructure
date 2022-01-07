terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 3.27"
    }
  }

  required_version = ">= 0.14.9"

  backend "s3" {
    bucket = "yordan-terraform-state"
    region         = "eu-west-3"

    dynamodb_table = "terraform-up-and-running-locks"
    encrypt        = true
  }
}

provider "aws" {
  region  = "eu-west-3"
}

module "ec2" {
  source = "../modules/ec2"

  env = var.env
}

module "vpc" {
  source = "../modules/vpc"

  env = var.env
}
