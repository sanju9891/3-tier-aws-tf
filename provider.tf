terraform {
    required_providers {
        aws = {
            source = "hashicorp/aws"
            version = "=>5.10.1"
        }
    }
}

provider "aws" {
    region = "ap-southeast-1"
  
}