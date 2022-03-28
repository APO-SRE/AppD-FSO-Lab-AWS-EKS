# Terraform ----------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.1.7"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.8"
    }

    kubernetes = {
      version = "~> 2.9"
    }

    null = {
      source = "hashicorp/null"
      version = ">= 3.1"
    }

    random = {
      source = "hashicorp/random"
      version = ">= 3.1"
    }
  }
}
