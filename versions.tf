# Terraform ----------------------------------------------------------------------------------------
terraform {
  required_version = ">= 1.2.7"

  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">= 4.26"
    }

    kubernetes = {
      version = "~> 2.12"
    }

    null = {
      source = "hashicorp/null"
      version = ">= 3.1"
    }

    random = {
      source = "hashicorp/random"
      version = ">= 3.3"
    }
  }
}
