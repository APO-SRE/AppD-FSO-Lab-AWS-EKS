# Terraform ----------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.2.0"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.14"
    }

    kubernetes = {
      version = "~> 2.11"
    }

    null = {
      source = "hashicorp/null"
      version = ">= 3.1"
    }

    random = {
      source = "hashicorp/random"
      version = ">= 3.2"
    }
  }
}
