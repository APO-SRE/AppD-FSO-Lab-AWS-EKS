# Terraform ----------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.1.7"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.4"
    }

    kubernetes = {
      version = "~> 2.8"
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
